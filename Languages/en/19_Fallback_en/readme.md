---
title:  19. Receive ETH
tags: 
  - solidity
  - advanced
  - wtfacademy
  - receive
  - fallback
---

# WTF Solidity Tutorial:  19. Receive ETH,  receive and fallback

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`Solidity` has two special functions,  `receive()` and `fallback()`, they are primarily used in two circumstances.
1. Receive Ether
2. Handle calls to contract if none of the other functions match the given function signature (e.g. proxy contract)

Note⚠️: Prior to solidity 0.6.x, only `fallback()` was available, for receiving Ether and as a fallback function.  
After version 0.6,  `fallback()` was separated to `receive()` and `fallback()`. 

In this tutorial, we focus on receiving Ether. 

## Receiving ETH Function: receive()
The `receive()` function is solely used for receiving `ETH`. A contract can have at most one `receive()` function, declared not like others, no `function` keyword is needed: `receive() external payable { ... }`. This function cannot have arguments, cannot return anything and must have `external` visibility and `payable` state mutability. 

`receive()` is executed on plain Ether transfers to a contract. You should not perform too many operations in `receive()` when sending Ether with `send` or `transfer`, only 2300 `gas` is available, and complicated operations will trigger an `Out of Gas` error; instead, you should use `call` function which can specify `gas` limit. (We will cover all three ways of sending Ether later）. 

We can send an `event` in the `receive()` function, for example: 
```solidity
    // Declare event
    event Received(address Sender,  uint Value); 
    // Emit Received event
    receive() external payable {
        emit Received(msg.sender,  msg.value); 
    }
```

Some malicious contracts intentionally add codes in `receive()` (`fallback()` prior to Solidity 0.6.x), which consume massive `gas` or cause the transaction to get reverted. So that will make some refund or transfer functions fail, pay attention to such risks when writing such operations.

## Fallback Function: fallback()
The `fallback()` function is executed on a call to the contract if none of the other functions match the given function signature, or if no data was supplied at all and there is no receive Ether function. It can be used to receive Ether or in `proxy contract`. `fallback()` is declared without the `function` keyword, and must have `external` visibility, it often has `payable` state mutability, which is used to receive Ether: `fallback() external payable { ... }`. 

Let's declare a `fallback()` function, which will send a `fallbackCalled` event, with `msg.sender`, `msg.value` and `msg.data` as parameters: 

```solidity
    event fallbackCalled(address Sender,  uint Value,  bytes Data); 

    // fallback
    fallback() external payable{
        emit fallbackCalled(msg.sender,  msg.value,  msg.data); 
    }
```

## Difference between receive and fallback
Both `receive` and `fallback` can receive `ETH`, they are triggered in such orders: 
```
Execute fallback() or receive()?
         Receive ETH
              |
      msg.data is empty?
            /  \
          Yes   No
          /      \
Has receive()?   fallback()
        / \
      Yes  No
      /     \
receive()   fallback()
```
To put it simply, when a contract receives `ETH`, `receive()` will be executed if `msg.data` is empty and the `receive()` function is present; on the other hand, `fallback()` will be executed if `msg.data` is not empty or there is no `receive()` declared, in such case `fallback()` must be `payable`. 

If neither `receive()` or `payable fallback()` is declared in the contract, receiving `ETH` will fail. 


## Test on Remix
1. First deploy "Fallback.sol" on Remix. 
2. Put the value (in Wei) you want to send to the contract in "VALUE", then click "Transact". 
    ![](img/19-1.jpg)

3. The transaction succeeded, and the "receivedCalled" event emitted. 
    ![](img/19-2.jpg)

4. Put the value you want to send to the contract in "VALUE", and put any valid `msg.data` in "CALLDATA", and click "Transact". 
    ![](img/19-3.jpg)
    
5. The transaction succeeded, and the "fallbackCalled" event emitted. "fallbackCalled". 
    ![](img/19-4.jpg)


## Summary
In this tutorial, we talked about two special functions in `Solidity`, `receive()` and `fallback()`, they are mostly used in receiving `ETH`, and `proxy contract`. 

