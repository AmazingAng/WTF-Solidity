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

Recently,  I have been relearning Solidity,  consolidating the finer details,  and also writing a "WTF Solidity Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter:  [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord,  where you can find the way to join WeChat group:  [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars,  course certification is unlocked. At 2048 repo stars,  community NFT is unlocked.):  [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`Solidity` has two special functions,  `receive()` and `fallback()`, they are primarily used in two circumstances.
1. Receive Ether
2. Handle calls to contract if none of the other functions match the given function signature (e.g. proxy contract)

Note⚠️: Prior to solidity 0.6.x, only `fallback()` was available, for receiving Ether and as a fallback function.  
After version 0.6,  `fallback()` was separated to `receive()` and `fallback()`. 

In this tutorial we focus on receiving Ether. 

## Receiving ETH Function: receive()
The `receive()` function is solely used for receiving `ETH`. A contract can have at most one `receive()` function, declared not like others, no `function` keyword is needed: `receive() external payable { ... }`. This function cannot have arguments, cannot return anything and must have `external` visibility and `payable` state mutability. 

`receive()` is executed on plain Ether transfers to a contract. You should not perform too much operations in `receive()`, when sending Ether with `send` or `transfer`, only 2300 `gas` is available, complicated operations will trigger `Out of Gas` error; instead you should use `call` function which can specifiy `gas` limit. (We will cover all three ways of sending Ether later）. 

We can send an `event` in `receive()` function, for example: 
```solidity
    // Declare event
    event Received(address Sender,  uint Value); 
    // Emit Received event
    receive() external payable {
        emit Received(msg.sender,  msg.value); 
    }
```

Some malicious contracts intentionally add codes in `receive()` (`fallback()` prior to Solidity 0.6.x), which consume massive `gas` or cause the transaction get reverted. So that will make some refund or transfer function fail, pay attention to such risks when writing such operations.

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

## Deffirence between receive and fallback
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
To put it simply, when a contract receives `ETH`, `receive()` will be executed if `msg.data` is empty and `receive()` function presents; on the other hand, `fallback()` will be executed if `msg.data` is not empty or there is no `receive()` declared, in such case `fallback()` must be `payable`. 

If neither `receive()` or `payable fallback()` is declared in the contract, receiving `ETH` will fail. 


## Test on Remix
1. First deploy "Fallback.sol" on Remix. 
2. Put the value (in Wei) you want to send to the contract in "VALUE", then click "Transact". 
    ![](img/19-1.jpg)

3. The transaction succeeded, and "receivedCalled" event emitted. 
    ![](img/19-2.jpg)

4. Put the value you want to send to the contract in "VALUE", and put any valid `msg.data` in "CALLDATA", click "Transact". 
    ![](img/19-3.jpg)
    
5. The transaction succeeded, and "fallbackCalled" event emitted. "fallbackCalled". 
    ![](img/19-4.jpg)


## Summary
In this tutorial, we talked about two special functions in `Solidity`, `receive()` and `fallback()`, they are mostly used in receiving `ETH`, and `proxy contract`. 

