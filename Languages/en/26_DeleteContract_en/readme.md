---
Ethereum communitytitle: 26. DeleteContract
tags:
  - solidity
  - advanced
  - wtfacademy
  - selfdestruct
  - delete contract
---
# WTF Solidity Tutorial: 26. DeleteContract

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)
---

## `selfdestruct`

The `selfdestruct` operation is the only way to delete a smart contract and the remaining Ether stored at that address is sent to a designated target. The `selfdestruct` operation is designed to deal with the extreme case of contract errors. Originally the opcode was named `suicide` but the Ethereum community decided to rename it as `selfdestruct` because suicide is a heavy subject and we should make every effort possible not to be insensitive to programmers who suffer from depression.

### How to use `selfdestruct`

It's simple to use `selfdestruct`：

```solidity
selfdestruct(_addr);
```

 `_addr` is the address to store the remaining `ETH` in the contract.

### Example:

```solidity
contract DeleteContract {

    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // use selfdestruct to delete the contract and send the remaining ETH to msg.sender
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns(uint balance){
        balance = address(this).balance;
    }
}
```

In `DeleteContract`， we define a public state variable named `value` and two functions：`getBalance()` which is used to get the ETH balance of the contract，`deleteContract()` which is used to delete the contract and transfer the remaining ETH to the sender of the message.

After the contract is deployed， we send 1 ETH to the contract. The result should be 1 ETH while we call `getBalance()` and the `value` should be 10.

Then we call `deleteContract().` The contract will self-destruct and all variables will be cleared. At this time, `value` is equal to  `0` which is the default value, and `getBalance()` also returns an empty value.

### Attention

1. When providing the contract destruction function externally, it is best to declare the function to only be called by the contract owner such as using the  function modifier `onlyOwner`.
2. When the contract is destroyed, the interaction with the smart contract can also succeed and return `0`.
3. Security and trust issues often arise when a contract includes a `selfdestruct` function. This feature opens up attack vectors for potential attackers. For instance, attackers might exploit `selfdestruct` to frequently transfer tokens to a contract, significantly reducing the cost of gas for attacking. Although this tactic is not commonly employed, it remains a concern. Furthermore, the presence of the `selfdestruct` feature can diminish users' confidence in the contract.

### Example from Remix

1. Deploy the contract and send 1 ETH to the contract. Check the status of the contract.

![deployContract.png](./img/26-2.png)

2. Delete the contract and check the status of the contract.

![deleteContract.png](./img/26-1.png)

By checking the contract state, we know that ETH is sent to the specified address after the contract is destroyed. After the contract is deleted, we can still interact with the contract. So we cannot confirm whether the contract has been destroyed based on this condition.

## Summary

`selfdestruct` is the emergency button for smart contracts. It will delete the contract and transfer the remaining `ETH` to the designated account. When the famous `The DAO` hack happened, the founders of Ethereum must have regretted not adding `selfdestruct` to the contract to stop the hacker attack.
