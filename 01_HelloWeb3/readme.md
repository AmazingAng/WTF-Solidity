---
title: 1. Hello Web3 (三行代码)
tags:
  - solidity
  - basic
  - wtfacademy
---

# WTF Solidity极简入门: 1. Hello Web3 (三行代码)

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

## Solidity 简介

`Solidity` 是一种用于编写以太坊虚拟机（`EVM`）智能合约的编程语言。我认为掌握 `Solidity` 是参与链上项目的必备技能：区块链项目大部分是开源的，如果你能读懂代码，就可以规避很多亏钱项目。

`Solidity` 具有两个特点：

1. "基于对象"：学会 `Solidity` 之后，可以助你在区块链领域找到好工作，挣钱找对象。
2. "高级"：不会 `Solidity`，在币圈会显得很 low。

## 开发工具：Remix

本教程中，我们将使用 `Remix` 运行 `Solidity` 合约。`Remix` 是以太坊官方推荐的智能合约集成开发环境（IDE），适合新手，可以在浏览器中快速开发和部署合约，无需在本地安装任何程序。

网址：[https://remix.ethereum.org](https://remix.ethereum.org)

在 `Remix` 中，左侧菜单有三个按钮，分别对应文件（编写代码）、编译（运行代码）和部署（将合约部署到链上）。点击“创建新文件”（`Create New File`）按钮，即可创建一个空白的 `Solidity` 合约。

![Remix 面板](./img/1-1.png)

## 第一个 Solidity 程序

这个简单的程序只有 1 行注释和 3 行代码：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract HelloWeb3{
    string public _string = "Hello Web3!";
}
```

我们拆解程序，学习 Solidity 代码源文件的结构：

1. 第 1 行是注释，说明代码所使用的软件许可（license），这里使用的是 MIT 许可。如果不写许可，编译时会出现警告（warning），但程序仍可运行。Solidity 注释以“//”开头，后面跟注释内容，注释不会被程序执行。

   ```solidity
   // SPDX-License-Identifier: MIT
   ```

2. 第 2 行声明源文件所使用的 Solidity 版本，因为不同版本的语法有差异。这行代码表示源文件将不允许小于 0.8.4 版本或大于等于 0.9.0 的编译器编译（第二个条件由 `^` 提供）。Solidity 语句以分号（;）结尾。

   ```solidity
   pragma solidity ^0.8.4;
   ```

3. 第 3-4 行是合约部分。第 3 行创建合约（contract），并声明合约名为 `HelloWeb3`。第 4 行是合约内容，声明了一个 string（字符串）变量 `_string`，并赋值为 "Hello Web3!"。

   ```solidity
   contract HelloWeb3 {
       string public _string = "Hello Web3!";
   }
   ```

后续我们会更详细地介绍 Solidity 中的变量。

## 编译并部署代码

在 Remix 编辑代码的页面，按 Ctrl + S 即可编译代码，非常方便。

编译完成后，点击左侧菜单的“部署”按钮，进入部署页面。

![Deploy配图](./img/1-2.png)

默认情况下，`Remix` 会使用 `Remix` 虚拟机（以前称为 JavaScript 虚拟机）来模拟以太坊链，运行智能合约，类似在浏览器里运行一条测试链。`Remix` 还会为你分配一些测试账户，每个账户里有 100 ETH（测试代币），随意使用。点击 `Deploy`（黄色按钮），即可部署我们编写的合约。

![_string配图](./img/1-3.png)

部署成功后，在下方会看到名为 `HelloWeb3` 的合约。点击 `_string`，即可看到 "Hello Web3!"。

## 总结

本节课程中，我们简要介绍了 `Solidity` 和 `Remix` 工具，并完成了第一个 `Solidity` 程序 —— `HelloWeb3`。接下来，我们将继续深入学习 `Solidity`！

### 中文 Solidity 资料推荐

1. [Solidity中文文档](https://docs.soliditylang.org/zh/v0.8.19/index.html)（官方文档的中文翻译）
2. [崔棉大师solidity教程](https://space.bilibili.com/286084162) web3技术教学博主，我看他视频学到了很多
