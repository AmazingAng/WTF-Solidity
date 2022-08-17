---
title: 46. 代理合约
tags:
  - solidity
  - proxy

---

# Solidity极简入门: 46. 代理合约


普通合约部署在链上之后，函数逻辑不能改变。
- 好处：用户永远知道会发生什么（大部分时候）。
- 坏处：如果有bug，不能修改，只能再部署新合约
Proxy Contract