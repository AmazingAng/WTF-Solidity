---
title: S05. 整型溢出
tags:
  - solidity
  - security
---

# WTF Solidity 合约安全: S05. 整型溢出

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍整型溢出漏洞（Arithmetic Over/Under Flows）。这是一个比较经典的漏洞，Solidity 0.8版本后内置了Safemath库，因此很少发生。

## 整型溢出

以太坊虚拟机（EVM）为整型设置了固定大小，因此它只能表示特定范围的数字。例如 `uint8`，只能表示 [0,255] 范围内的数字。如果给 `uint8` 类型变量的赋值 `257`，则会上溢（overflow）变为 `1`；如果给它赋值`-1`，则会下溢（underflow）变为`255`。

攻击者可以利用这个漏洞进行攻击：想象一下，黑客余额为`0`，他凭空花 `$1` 之后，余额突然变成了 `$2^256-1`。2018年的土狗项目 `PoWHC` 因为这个漏洞被盗了 `866 ETH`。

![](./img/S05-1.png)

## 漏洞合约例子

下面这个例子是一个简单的代币合约，参考了 `Ethernaut` 中的合约。它有 `2` 个状态变量：`balances` 记录了每个地址的余额，`totalSupply` 记录了代币总供给。

它有 `3` 个函数：

- 构造函数：初始化代币总供给。
- `transfer()`：转账函数。
- `balnceOf()`：查询余额函数。

由于solidity `0.8.0` 版本之后会自动检查整型溢出错误，溢出时会报错。如果我们要重现这种漏洞，需要使用 `unchecked` 关键字，在代码块中临时关掉溢出检查，就像我们在 `transfer()` 函数中做的那样。

这个例子中的漏洞就出现在`transfer()` 函数中，`require(balances[msg.sender] - _value >= 0);` 这个检查由于整型溢出，永远都会通过。因此用户可以无限转账。

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

## `Remix` 复现

1. 部署 `Token` 合约，将总供给设为 `100`。
2. 向另一个账户转账 `1000` 个代币，可以转账成功。
3. 查询自己账户的余额，发现是一个非常大的数字，约为`2^256`。

## 预防办法

1. Solidity `0.8.0` 之前的版本，在合约中引用 [Safemath 库](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol)，在整型溢出时报错。

2. Solidity `0.8.0` 之后的版本内置了 `Safemath`，因此几乎不存在这类问题。开发者有时会为了节省gas使用 `unchecked` 关键字在代码块中临时关闭整型溢出检测，这时要确保不存在整型溢出漏洞。

## 总结

这一讲，我们介绍了经典的整型溢出漏洞，由于solidity 0.8.0 版本后内置 `Safemath` 的整型溢出检查，这类漏洞已经很少见了。