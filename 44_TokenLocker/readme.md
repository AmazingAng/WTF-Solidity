---
title: 44. 代币锁
tags:
  - solidity
  - application
  - ERC20

---

# Solidity极简入门: 44. 代币锁

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们介绍什么是流动性提供者`LP`代币，为什么要锁定流动性，并写一个简单的`ERC20`代币锁合约。

## 代币锁

![代币锁](./img/44-1.webp)

代币锁(Token Locker)是一种简单的时间锁合约，它可以把合约中的代币锁仓一段时间，受益人在锁仓期满后可以取走代币。代币锁一般是用来锁仓流动性提供者`LP`代币的。

### 什么是`LP`代币？

区块链中，用户在去中心化交易所`DEX`上交易代币，例如`Uniswap`交易所。`DEX`和中心化交易所不同，中心化交易所使用自动做市商机制，需要用户或项目方提供资金池，以使得其他用户能够即时买卖。简单来说，用户/项目方需要质押相应的币对（比如`ETH/DAI`）到资金池中，作为补偿，`DEX`会给他们铸造相应的流动性提供者`LP`代币凭证，证明他们质押了相应的份额，供他们收取手续费。


### 为什么要锁定流动性？

如果项目方毫无征兆的撤出流动性池中的`LP`代币，那么投资者手中的代币就无法变现，直接归零了。这种行为也叫`rug-pull`，仅2021年，各种`rug-pull`骗局从投资者那里骗取了价值超过28亿美元的加密货币。

但是如果`LP`代币是锁仓在代币锁合约中，在锁仓期结束以前，项目方无法撤出流动性池，也没办法`rug pull`。因此代币锁可以防止项目方过早跑路（要小心锁仓期满跑路的情况）。

## 代币锁合约

下面，我们就写一个锁仓`ERC20`代币的合约`TokenLocker`。它的逻辑很简单：

- 开发者在部署合约时规定锁仓的时间，受益人地址，以及代币合约。
- 开发者将代币转入`TokenLocker`合约。
- 在锁仓期满，受益人可以取走合约里的代币。

### 事件

`TokenLocker`合约中共有`2`个事件。

- `TokenLockStart`：锁仓开始事件，在合约部署时释放，记录受益人地址，代币地址，锁仓起始时间，和结束时间。
- `Release`：代币释放事件，在受益人取出代币时释放，记录记录受益人地址，代币地址，释放代币时间，和代币数量。

```solidity
    // 事件
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);
```

### 状态变量

`TokenLocker`合约中共有`4`个状态变量。

- `token`：锁仓代币地址。
- `beneficiary`：受益人地址。
- `locktime`：锁仓时间(秒)。
- `startTime`：锁仓起始时间戳(秒)。

```solidity
    // 被锁仓的ERC20代币合约
    IERC20 public immutable token;
    // 受益人地址
    address public immutable beneficiary;
    // 锁仓时间(秒)
    uint256 public immutable lockTime;
    // 锁仓起始时间戳(秒)
    uint256 public immutable startTime;
```
### 函数

`TokenLocker`合约中共有`2`个函数。

- 构造函数：初始化代币合约，受益人地址，以及锁仓时间。
- `release()`：在锁仓期满后，将代币释放给受益人。需要受益人主动调用`release()`函数提取代币。

```solidity
    /**
     * @dev 部署时间锁合约，初始化代币合约地址，受益人地址和锁仓时间。
     * @param token_: 被锁仓的ERC20代币合约
     * @param beneficiary_: 受益人地址
     * @param lockTime_: 锁仓时间(秒)
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 lockTime_
    ) {
        require(lockTime_ > 0, "TokenLock: lock time should greater than 0");
        token = token_;
        beneficiary = beneficiary_;
        lockTime = lockTime_;
        startTime = block.timestamp;

        emit TokenLockStart(beneficiary_, address(token_), block.timestamp, lockTime_);
    }

    /**
     * @dev 在锁仓时间过后，将代币释放给受益人。
     */
    function release() public {
        require(block.timestamp >= startTime+lockTime, "TokenLock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");

        token.transfer(beneficiary, amount);

        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
```

## `Remix`演示

### 1. 部署[第31讲](../31_ERC20/readme.md)中的`ERC20`合约，并给自己铸造`10000`枚代币。

### 2. 部署`ToeknLocker`合约，代币地址为`ERC20`合约地址，受益人为自己，锁仓期填`180`秒。

### 3. 将`10000`枚代币转入合约。

### 4. 在锁仓期`180`秒内调用`release()`函数，无法取出代币。

### 5. 在锁仓期后调用`release()`函数，成功取出代币。

## 总结

这一讲，我们介绍了代币锁合约。项目方一般在`DEX`上提供流动性，供投资者交易。项目方突然撤出`LP`会造成`rug-pull`，而将`LP`锁在在代币锁合约中可以避免这种情况。