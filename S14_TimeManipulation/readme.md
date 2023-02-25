---
title: S14. 操纵区块时间
tags:
- solidity
- security
- timestamp
---

# WTF Solidity 合约安全: S14. 操纵区块时间

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍智能合约的操纵区块时间攻击，并使用 Foundry 复现。在合并（The Merge）之前，以太坊矿工可以操纵区块时间，如果抽奖合约的伪随机数依赖于区块时间，则可能被攻击。

## 区块时间

区块时间（block timestamp）是包含在以太坊区块头中的一个 `uint64` 值，代表此区块创建的 UTC 时间戳（单位：秒），在合并（The Merge）之前，以太坊会根据算力调整区块难度，因此出块时间不定，平均 14.5s 出一个区块，矿工可以操纵区块时间；合并之后，改为固定 12s 一个区块，验证节点不能操纵区块时间。

在 Solidity 中，开发者可以通过全局变量 `block.timestamp` 获取当前区块的时间戳，类型为 `uint256`。

## 漏洞例子

此例子由[WTF Solidity合约安全: S07. 坏随机数](https://github.com/AmazingAng/WTF-Solidity/tree/main/32_Faucet)中的合约改写而成。我们改变了 `mint()` 铸造函数的条件：当区块时间能被 170 整除时才能成功铸造：

```solidity
contract TimeMnipulation is ERC721 {
    uint256 totalSupply;

    // 构造函数，初始化NFT合集的名称、代号
    constructor() ERC721("", ""){}

    // 铸造函数：当区块时间能被7整除时才能mint成功
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}
```

## Foundry复现攻击

攻击者只需操纵区块时间，将它设为能被 170 整除的数字，就可以成功铸造 NFT。我们选择 Foundry 来复现这个攻击，因为它提供了修改区块时间的作弊码（cheatcodes）。如果你不了解 Foundry/作弊码，可以阅读 [Foundry教程](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md) 和 [Foundry Book](https://book.getfoundry.sh/forge/cheatcodes)。

代码大致逻辑

1. 创建一个 `TimeManipulation` 合约变量 `nft`。
2. 创建一个钱包地址 `alice`。
3. 使用作弊码 `vm.warp()` 将区块时间改为 169，由于不能被170整除，铸造失败。
4. 使用作弊码 `vm.warp()` 将区块时间改为 17000，由于可以被170整除，铸造成功。

代码：

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeManipulation.sol";

contract TimeManipulationTest is Test {
    TimeManipulation public nft;

    // Computes address for a given private key
    address alice = vm.addr(1);

    function setUp() public {
        nft = new TimeManipulation();
    }

    // forge test -vv --match-test  testMint
    function testMint() public {
        console.log("Condition 1: block.timestamp % 170 != 0");
        // Set block.timestamp to 169
        vm.warp(169);
        console.log("block.timestamp: %s", block.timestamp);
        // Sets all subsequent calls' msg.sender to be the input address
        // until `stopPrank` is called
        vm.startPrank(alice);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));

        // Set block.timestamp to 17000
        console.log("Condition 2: block.timestamp % 170 == 0");
        vm.warp(17000);
        console.log("block.timestamp: %s", block.timestamp);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));
        vm.stopPrank();
    }
}

```

在安装好 Foundry 之后，在命令行输入下列命令启动新项目，并安装 openzeppelin 库：

```shell
forge init TimeMnipulation
cd TimeMnipulation
forge install Openzeppelin/openzeppelin-contracts
```

将这一讲的代码分别复制到`src`和`test`目录下，然后使用下列命令启动测试用例：

```shell
forge test -vv --match-test testMint
```

输出如下：

```shell
Running 1 test for test/TimeManipulation.t.sol:TimeManipulationTest
[PASS] testMint() (gas: 94666)
Logs:
  Condition 1: block.timestamp % 170 != 0
  block.timestamp: 169
  alice balance before mint: 0
  alice balance after mint: 0
  Condition 2: block.timestamp % 170 == 0
  block.timestamp: 17000
  alice balance before mint: 0
  alice balance after mint: 1

Test result: ok. 1 passed; 0 failed; finished in 7.64ms
```

我们可以看到，当我们将` block.timestamp` 修改为 17000时，铸造成功。

## 总结

这一讲，我们介绍了智能合约的操纵区块时间攻击，并使用 Foundry 复现了它。在合并（The Merge）之前，以太坊矿工可以操纵区块时间，如果抽奖合约的伪随机数依赖于区块时间，则可能被攻击。合并之后，以太坊改为固定 12s 一个区块，并且验证节点不能操纵区块时间。因此这类攻击不会在以太坊上发生，但仍可能在其他公链中遇到。