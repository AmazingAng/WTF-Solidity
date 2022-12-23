---
title: S15. 操纵预言机
tags:
- solidity
- security
- oracle

---

# WTF Solidity 合约安全: S15. 操纵预言机

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍智能合约的操纵预言机攻击，并使用 Foundry 复现。

## 预言机



## 

## 漏洞例子

```solidity
  function getPrice() public returns (uint256) {
        // pair 交易对中储备
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        emit Log("reserve0", reserve0 / 1e18);
        emit Log("reserve1", reserve1 / 1e18);
        // lp 总量
        uint256 lptotalSupply = pair.totalSupply();
        emit Log("lptotalSupply", lptotalSupply / 1e18);
        //  ！！容易被操控的计算方式
        return (lptotalSupply * 1e5) / (reserve0 + reserve1);
       
    }

```

## Foundry复现攻击

### 环境变量

.env 环境变量中添加主网rpc

```
MAINNET_RPC_URL= https://rpc.ankr.com/eth
```



### 说明

依赖某一数值瞬时数据的价格预言机很容易被闪电贷攻击。 攻击者只需要通过 :robot: 闪电贷借贷大量代币，添加到计算涉及的币种，会引起预言机价格的迅速变化。从而提供套利空间

代码大致逻辑

1. 闪电贷借贷大量WETH和DAI
2. 一部分金额购买目标币种提前埋伏，此时该币种价格较低
3. 为uniswap中WETH-DAI-LP添加流动性 根据getPrice()方法，瞬时价格巨幅上升
4. 卖出埋伏的币种，获利
5. 归还闪电贷

代码：

```solidity

```

在安装好 Foundry 之后，在命令行输入下列命令启动新项目，并安装 openzeppelin 库：

```shell
forge init Oracle
cd Oracle
forge install Openzeppelin/openzeppelin-contracts
```

将这一讲的代码分别复制到`src`和`test`目录下，然后使用下列命令启动测试用例：

```shell
forge test -vv --match-test testOracleAttack
```

输出如下：

```shell
Running 1 test for test/wtf_safe_amm_v3/Oracle.t.sol:wtfsolidity_safe
[PASS] testOracleAttack() (gas: 346643)
Logs:
  before: price: 1615
  tokenAsent: 1958275  e18, tokenBsent 6164770 e18 ,lpget 1952159 e18 
  after: price: 24032

Test result: ok. 1 passed; 0 failed; finished in 294.12ms
```

 可以看到价格由 1615 飙升到24032



## 总结



