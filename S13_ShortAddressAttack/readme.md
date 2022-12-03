---
title: S13. 短地址攻击
tags:
  - solidity
  - security
---

# WTF Solidity 合约安全: S13. 短地址攻击

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍短地址攻击（Short Address Attack）。

## 什么是短地址攻击？

短地址攻击的原理是利用 EVM 在参数长度不够时自动在右方补 0 的特性，通过去除钱包地址末位的 0，达到将转账金额左移放大的效果。

一般ERC-20 TOKEN (令牌) 标准的代币都会实现 transfer (转移) 方法，这个方法在ERC-20标签中的定义为： 

```solidity
function transfer(address to, uint tokens) public returns (bool success);
```

第一参数是发送代币的目的地址，第二个参数是发送 token (令牌) 的数量。

当我们调用 transfer (转移) 函数向某个地址发送N个ERC-20代币的时候，交易的input数据分为3个部分：

4 字节，是方法名的哈希：a9059cbb

32字节，放以太坊地址，目前以太坊地址是20个字节，高危补0

```solidity
000000000000000000000000abcabcabcabcabcabcabcabcabcabcabcabcabca
```

32字节，是需要传输的代币数量，这里是1*10^18 GNT

```solidity
0000000000000000000000000000000000000000000000000de0b6b3a7640000
```

所有这些加在一起就是交易数据：

```solidity
a9059cbb000000000000000000000000abcabcabcabcabcabcabcabcabcabcabcabcabca0000000000000000000000000000000000000000000000000de0b6b3a7640000
```

当调用 transfer (转移) 方法提币时，如果允许用户输入了一个短地址，这里通常是交易所这里没有做处理，比如没有校验用户输入的地址长度是否合法。

如果一个以太坊地址如下，注意到结尾为0：

```solidity
0x1234567890123456789012345678901234567800
```

当我们将后面的00省略时，EVM会从下一个参数的高位拿到00来补充，这就会导致一些问题了。

这时， token (令牌) 数量参数其实就会少了1个字节，即token数量左移了一个字节，使得合约多发送很多代币出来。

## 漏洞合约例子

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Coin {
    address owner;
    mapping (address => uint256) public balances;

    modifier OwnerOnly() { 
        require(msg.sender == owner); _; 
    }

    function ICoin() public { 
        owner = msg.sender; 
    }

    function approve(address _to, uint256 _amount) public OwnerOnly { 
        balances[_to] += _amount; 
    }
    
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] > _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
}
```

具体代币功能的合约 Coin (硬币) ，当 A 账户向 B 账户转代币时调用 transfer() 函数，例如 A 账户（`0x14723a09acff6d2a60dcdf7aa4aff308fddc160c`）向 B 账户（`0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db`）转 8 个 Coin (硬币) ，msg.data 数据为：

```
0xa9059cbb  -> bytes4(keccak256("transfer(address,uint256)")) 函数签名
0000000000000000000000004b0897b0513fdc7c541b6d9d7e929c4e5364d2db  -> B 账户地址（前补 0 补齐 32 字节）
0000000000000000000000000000000000000000000000000000000000000008  -> 0x8（前补 0 补齐 32 字节）
```

那么短地址攻击是怎么做的呢，攻击者找到一个末尾是 00 账户地址，假设为 `0x4b0897b0513fdc7c541b6d9d7e929c4e5364d200`，那么正常情况下整个调用的 msg.data 应该为：

```
0xa9059cbb  -> bytes4(keccak256("transfer(address,uint256)")) 函数签名
0000000000000000000000004b0897b0513fdc7c541b6d9d7e929c4e5364d200  -> B 账户地址（注意末尾 00）
0000000000000000000000000000000000000000000000000000000000000008  -> 0x8（前补 0 补齐 32 字节）
```

但是如果我们将 B 地址的 00 吃掉，不进行传递，也就是说我们少传递 1 个字节变成 4+31+32：

```
0xa9059cbb  -> bytes4(keccak256("transfer(address,uint256)")) 函数签名
0000000000000000000000004b0897b0513fdc7c541b6d9d7e929c4e5364d2  -> B 地址（31 字节）
0000000000000000000000000000000000000000000000000000000000000008  -> 0x8（前补 0 补齐 32 字节）
```

当上面数据进入 EVM 进行处理时，对参数进行编码对齐后补 00 变为：

```
0xa9059cbb
0000000000000000000000004b0897b0513fdc7c541b6d9d7e929c4e5364d200
0000000000000000000000000000000000000000000000000000000000000800
```

也就是说，恶意构造的 msg.data 通过 EVM 解析补 0 操作，导致原本 0x8 = 8 变为了 0x800 = 2048。

## `Remix` 复现

因为客户端会检查地址长度，目前不能通过 Remix 复现；也不能通过 sendTransaction()，因为 web3 中也加了保护， 不过可以使用 geth 搭建私链，使用 sendRawTransaction() 发送交易复现。

## 预防办法

1. 目前主要依靠客户端主动检查地址长度来避免该问题，另外 web3 层面也增加了参数格式校验。

## 总结

这一讲，我们介绍了以太坊短地址攻击，由于目前普遍拥有地址检查，虽然 EVM 层仍然可以复现，但是在实际应用场景中基本没有问题。
