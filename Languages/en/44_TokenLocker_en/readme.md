---
tags:
  - solidity
  - application
  - ERC20
---

# WTF Solidity Crash Course: 44. Token Lock

I have been relearning Solidity recently to solidify my understanding of the language and to create a "WTF Solidity Crash Course" for beginners (advanced programmers can find other tutorials). I will update it weekly with 1-3 lessons.

Feel free to follow me on Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

You are also welcome to join the WTF Scientists community and find information on how to join the WeChat group: [link](https://discord.gg/5akcruXrsk)

All of the code and tutorials are open source and can be found on Github (I will provide a course certification for 1024 stars and a community NFT for 2048 stars): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

### Token Lock

A Token Lock is a simple time-based smart contract that allows one to lock a number of tokens for a certain period of time. After the lock-up period is over, the beneficiary can then withdraw the tokens. A Token Lock is commonly used to lock LP tokens.

### What are LP Tokens?

In decentralized exchanges (DEX), users trade tokens, such as in the case of Uniswap. Unlike centralized exchanges (CEX), decentralized exchanges use Automated Market Maker (AMM) mechanisms. Users or projects provide a liquidity pool, so that other users can buy and sell tokens instantly. To compensate the user or project for providing the liquidity pool, the DEX will mint corresponding LP tokens, which represent their contribution and entitle them to transaction fees.

### Why Lock Liquidity?

If a project suddenly withdraws LP tokens from a liquidity pool without warning, the investors' tokens would become worthless. This act is commonly referred to as a "rug-pull." In 2021 alone, different "rug-pull" scams have defrauded investors of more than $2.8 billion in cryptocurrency.

However, by locking LP tokens into a Token Lock smart contract, the project cannot withdraw the tokens from the liquidity pool before the lock-up period expires, preventing them from committing a "rug-pull". A Token Lock can, therefore, prevent projects from running away with investors' tokens prematurely (though one should still be wary of projects "running away" once the lock-up period ends).

## Token Lock Contract

Below is a contract `TokenLocker` for locking `ERC20` tokens. Its logic is simple:

- The developer specifies the locking time, beneficiary address, and token contract when deploying the contract.
- The developer transfers the tokens to the `TokenLocker` contract.
- After the lockup period expires, the beneficiary can withdraw the tokens from the contract.

### Events

There are two events in the `TokenLocker` contract.

- `TokenLockStart`: This event is triggered when the lockup starts, which occurs when the contract is deployed. It records the beneficiary address, token address, lockup start time, and end time.
- `Release`: This event is triggered when the beneficiary withdraws the tokens. It records the beneficiary address, token address, release time, and token amount.

```solidity
    // 事件
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);
```

### State Variables

There are a total of 4 state variables in the `TokenLocker` contract:

- `token`: the address of the locked token.
- `beneficiary`: the address of the beneficiary.
- `locktime`: the lock-up period in seconds.
- `startTime`: the timestamp when the lock-up period starts (in seconds).

```solidity
    // The ERC20 token contract which is being locked
    IERC20 public immutable token;
    // The beneficiary's address
    address public immutable beneficiary;
    // Lock time (in seconds)
    uint256 public immutable lockTime;
    // Start timestamp of the lock (in seconds)
    uint256 public immutable startTime;
```

### Functions

There are `2` functions in the `TokenLocker` contract.

- Constructor: Initializes the contract with the token contract, beneficiary address, and lock-up period.
- `release()`: Releases the tokens to the beneficiary after the lock-up period. The beneficiary needs to call the `release()` function to extract the tokens.

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

## `Remix` Demonstration

### 1. Deploy the `ERC20` contract in [Lesson 31](../31_ERC20/readme.md), and mint `10000` tokens for yourself.

![`Remix` Demonstration](./img/44-2.jpg)

### 2. Deploy the `TokenLocker` contract with the `ERC20` contract address, set yourself as the beneficiary, and set the lock-up period to `180` seconds.

![`Remix` Demonstration](./img/44-3.jpg)

### 3. Transfer `10000` tokens to the contract.

![`Remix` Demonstration](./img/44-4.jpg)

### 4. Within the lock-up period of `180` seconds, call the `release()` function, but you won't be able to withdraw the tokens.

![`Remix` Demonstration](./img/44-5.jpg)

### 5. After the lock-up period, call the `release()` function again, and successfully withdraw the tokens.

![`Remix` Demo](./img/44-6.jpg)

## Summary

In this lesson, we introduced the token lock contract. Project parties generally provide liquidity on `DEX` for investors to trade. If the project suddenly withdraws the `LP`, it will cause a `rug-pull`. However, locking the `LP` in the token lock contract can avoid this situation.