---
title: S15. tx.origin钓鱼攻击
tags:
  - solidity
  - security
  - tx.origin
---

# WTF Solidity 合约安全: S15. tx.origin钓鱼攻击

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍智能合约的`tx.origin`钓鱼攻击和预防方法。

## `tx.origin`钓鱼攻击

笔者上初中的时候特别喜欢玩游戏，但是项目方为了防止未成年人沉迷，规定只有身份证号显示已满十八岁的玩家才不受防沉迷限制。这该怎么办呢？后来笔者使用家长的身份证号进行年龄验证，并成功绕过了防沉迷系统。这个案例与`tx.origin`钓鱼攻击有着异曲同工之妙。

在`solidity`中，使用`tx.origin`可以获得启动交易的原始地址，它与`msg.sender`十分相似，下面我们用一个例子来区分它们之间不同的地方。

如果用户A调用了B合约，再通过B合约调用了C合约，那么在C合约看来，`msg.sender`就是B合约，而`tx.origin`就是用户A。如果你不了解`call`，可以阅读[WTF Solidity极简教程第22讲：Call](https://github.com/AmazingAng/WTF-Solidity/blob/main/22_Call/readme.md)。

![](./img/S15_1.jpg)

因此如果一个银行合约使用了`tx.origin`做身份认证，那么黑客就有可能先部署一个攻击合约，然后再诱导银行合约的拥有者调用，即使`msg.sender`是攻击合约地址，但`tx.origin`是银行合约拥有者地址，那么转账就有可能成功。

## 漏洞合约例子

### 银行合约

我们先看银行合约，它非常简单，包含一个`owner`状态变量用于记录合约的拥有者，包含一个构造函数和一个`public`函数：

- 构造函数: 在创建合约时给`owner`变量赋值.
- `transfer()`: 该函数会获得两个参数`_to`和`_amount`，先检查`tx.origin == owner`，无误后再给`_to`转账`_amount`数量的ETH。**注意：这个函数有被钓鱼攻击的风险！**

```solidity
contract Bank {
    address public owner;//记录合约的拥有者

    //在创建合约时给 owner 变量赋值
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        //检查消息来源 ！！！ 可能owner会被诱导调用该函数，有钓鱼风险！
        require(tx.origin == owner, "Not owner");
        //转账ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}
```

### 攻击合约

然后是攻击合约，它的攻击逻辑非常简单，就是构造出一个将`address(bank).balance`全部转账给`hacker`的`attack()`函数。它有`2`个状态变量`hacker`和`bank`，分别用来记录黑客地址和要攻击的银行合约地址。它包含`2`个函数：

- 构造函数:初始化`bank`合约地址.
- `attack()`：攻击函数，该函数需要银行合约的`owner`地址调用，`owner`调用攻击合约，攻击合约再调用银行合约的`transfer()`函数，确认`tx.origin == owner`后，将银行合约内的余额全部转移到黑客地址中。

```solidity
contract Attack {
    // 受益者地址
    address payable public hacker;
    // Bank合约地址
    Bank bank;

    constructor(Bank _bank) {
        //强制将address类型的_bank转换为Bank类型
        bank = Bank(_bank);
        //将受益者地址赋值为部署者地址
        hacker = payable(msg.sender);
    }

    function attack() public {
        //诱导bank合约的owner调用，于是bank合约内的余额就全部转移到黑客地址中
        bank.transfer(hacker, address(bank).balance);
    }
}
```

## `Remix` 复现

**1.** 先将`value`设置为10ETH，再部署 `Bank` 合约，拥有者地址 `owner` 被初始化为部署合约地址。

![](./img/S15-2.jpg)

**2.** 切换到另一个钱包作为黑客钱包，填入要攻击的银行合约地址，再部署 `Attack` 合约，黑客地址 `hacker` 被初始化为部署合约地址。

![](./img/S15-3.jpg)

**3.** 切换回`owner`地址，此时我们被诱导调用了`Attack`合约的`attack()`函数，可以看到`Bank`合约余额被掏空了，同时黑客地址多了10ETH.

![](./img/S15-4.jpg)

## 预防办法

目前主要有两种办法来预防可能的`tx.origin`钓鱼攻击。

### 使用`msg.sender`代替`tx.origin`

`msg.sender`能够获取直接调用当前合约的调用发送者地址，通过对`msg.sender`的检验，就可以避免整个调用过程中混入外部攻击合约对当前合约的调用

```solidity
function transfer(address payable _to, uint256 _amount) public {
  require(msg.sender == owner, "Not owner");

  (bool sent, ) = _to.call{value: _amount}("");
  require(sent, "Failed to send Ether");
}
```

### 检验`tx.origin == msg.sender`

如果一定要使用`tx.origin`，那么可以再检验`tx.origin`是否等于`msg.sender`，这样也可以避免整个调用过程中混入外部攻击合约对当前合约的调用

```solidity
    function transfer(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");
        require(tx.origin == msg.sender, "can't call by external contract");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
```

## 总结

这一讲，我们介绍了智能合约中的`tx.origin`钓鱼攻击，目前有两种方法可以预防它：一种是使用`msg.sender`代替`tx.origin`；另一种是同时检验`tx.origin == msg.sender`。这一合约漏洞比较难以察觉，在实际开发中也容易被忽略。