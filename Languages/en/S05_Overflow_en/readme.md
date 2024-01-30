---
title: S05. Integer Overflow
tags:
  - solidity
  - security
---

# WTF Solidity S05. Integer Overflow

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

-----

In this lesson, we will introduce the integer overflow vulnerability (Arithmetic Over/Under Flows). This is a relatively common vulnerability, but it has become less prevalent since Solidity version 0.8, which includes the Safemath library.

## Integer Overflow

The Ethereum Virtual Machine (EVM) has fixed-size integers, which means it can only represent a specific range of numbers. For example, a `uint8` can only represent numbers in the range of [0, 255]. If a `uint8` variable is assigned the value `257`, it will overflow and become `1`; if it is assigned `-1`, it will underflow and become `255`.

Attackers can exploit this vulnerability: imagine a hacker with a balance of `0` who magically increases their balance by `$1`, and suddenly their balance becomes `$2^256-1`. In 2018, the "PoWHC" project lost `866 ETH` due to this vulnerability.

![](./img/S05-1.png)

## Vulnerable Contract Example

The following example is a simple token contract inspired by the "Ethernaut" contract. It has `2` state variables: `balances`, which records the balance of each address, and `totalSupply`, which records the total token supply.

It has `3` functions:

- Constructor: Initializes the total token supply.
- `transfer()`: Transfer function.
- `balanceOf()`: Balance query function.

Since Solidity version `0.8.0`, integer overflow errors are automatically checked, and an error is thrown if an overflow occurs. To reproduce this vulnerability, we need to use the `unchecked` keyword to temporarily disable the overflow check within a code block, as we did in the `transfer()` function.

The vulnerability in this example lies in the `transfer()` function, specifically the line `require(balances[msg.sender] - _value >= 0);`. Due to integer overflow, this check will always pass. Therefore, users can transfer an unlimited amount of tokens.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Token {
  mapping(address => uint) balances;
  uint public totalSupply;

  constructor(uint _initialSupply) {
    balances[msg.sender] = totalSupply = _initialSupply;
  }
  
  function transfer(address _to, uint _value) public returns (bool) {
    unchecked{
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    return true;
  }
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}
```

## Reproduce on `Remix`

1. Deploy the `Token` contract and set the total supply to `100`.
2. Transfer `1000` tokens to another account, which can be done successfully.
3. Check the balance of your own account and find a very large number, approximately `2^256`.

## How to Prevent

1. For versions of Solidity before `0.8.0`, include the [Safemath library](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol) in the contract to throw an error in case of integer overflow.

2. For versions of Solidity after `0.8.0`, `Safemath` is built-in, so this type of issue is almost non-existent. However, developers may temporarily disable integer overflow checks within a code block using the `unchecked` keyword to save gas. In such cases, it is important to ensure that no integer overflow vulnerabilities exist.

## Summary

In this lesson, we introduced the classic integer overflow vulnerability. Due to the built-in `Safemath` integer overflow check in Solidity version `0.8.0` and later, this type of vulnerability has become rare.
