---
title: 32. Token Faucet
tags:
  - solidity
  - application
  - wtfacademy
  - ERC20
  - faucet
---

# Solidity Minimalist Tutorial: 32. Token Faucet

Recently, I have been relearning Solidity, consolidating the finer details, and also writing a "WTF Solidity Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly.

Everyone is welcomed to follow my Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord, where you can find the way to join WeChat group：[链接](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

We learned the 'ERC20' token standard in Lesson 31. In this chapter, we will learn about the smart contract of the 'ERC20' faucet. In this contract, users can get free ERC20 tokens.

## Token faucet

When people are thirsty, they have to go to the faucet to get water; when people want free tokens, they have to go to the token faucet. A token faucet is a website/app that allows users to receive tokens for free.

The earliest token faucet is the Bitcoin (BTC) faucet: now a BTC costs \$30,000, but in 2010, the price of BTC was less than $0.1, and there were very few holders. In order to expand its influence, Gavin Andresen of the Bitcoin community developed a BTC faucet, allowing others to receive BTC for free. Everyone likes to get the best deal. At that time, many people did it, and some of them became believers in BTC. A total of more than 19,700 BTC have been sent out by the BTC faucet, which is now worth about 600 million US dollars!

## The contract of ERC20 faucet

Here, we implement a simplified version of the ERC20 faucet. The logic is very simple: we transfer some ERC20 tokens to the faucet contract, and the user can receive 100 units of tokens through the requestToken() function of the contract. Each address can only receive once.

### State variables

We define 3 state variables in the faucet contract

- `amountAllowed` to set the number of tokens that can be received each time (the default is `100`, not a hundred, because tokens have decimal places).
- `tokenContract` to record the issued `ERC20` token contract address.
- `requestedAddress` to record the address where the token was received.

```solidity
uint256 public amountAllowed = 100; // to collect 100 units token each time
address public tokenContract;   // the address of token contract
mapping(address => bool) public requestedAddress;   // to record the address where the token was received
```

### Event

A `SendToken` event is defined in the faucet contract, which records the address and amount of tokens received each time, and is released when the `requestTokens()` function is called.

```solidity
// SendToken event   
event SendToken(address indexed Receiver, uint256 indexed Amount); 
```

### Function

There are only two functions in the contract：

- Constructor: initialize the `tokenContract` state variable, and determine the issued `ERC20` token address.
```solidity
// Set the ERC20 token contract when deploying
constructor(address _tokenContract) {
	tokenContract = _tokenContract; // set token contract
}
```

- `requestTokens()` function，users call it to receive `ERC20` tokens。

```solidity
// function for users to claim tokens
function requestTokens() external {
    require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!"); // Each address can only receive tokens once
    IERC20 token = IERC20(tokenContract); // Create IERC20 contract object
    require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); // Faucet is empty

    token.transfer(msg.sender, amountAllowed); // transfer token
    requestedAddress[msg.sender] = true; // to record the address where the token was received 
    
    emit SendToken(msg.sender, amountAllowed); // emit SendToken event
}
```

## Remix Demo

1. First, deploy the `ERC20` token contract with the name and symbol `WTF`, and give yourself `mint` 10000 unit tokens.
    ![deploy`ERC20`](./img/32-1.png)

2. Deploy the `Faucet` faucet contract, and fill in the contract address of the `ERC20` token above for the initialization parameters.
    ![deploy`Faucet`faucet contract](./img/32-2.png)

3. Use the `transfer()` function of the `ERC20` token contract to transfer 10,000 units of tokens to the `Faucet` contract address.
    ![transfer funds to the `Faucet` faucet contract](./img/32-3.png)

4. Change to a new account, call the `Faucet` contract `requestTokens()` function, and receive tokens. You can see the `SendToken` event being released in the terminal.
    ![switch account](./img/32-4.png)

    ![requestToken](./img/32-5.png)

5. Use `balanceOf` on the `ERC20` token contract to query the account balance of the faucet, and you can see that the balance has changed to `100`, and the claim is successful!
    ![the claim is successful](./img/32-6.png)

## Summary

In this chapter, we introduced the history of the token faucet and the `ERC20` faucet contract. Where do you think the next `BTC` faucet will be?