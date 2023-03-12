---
title: 43. Linear Release
tags:
  - solidity
  - application
  - ERC20

---

# WTF Simplified Solidity: 43. Linear Release

I am currently re-learning Solidity to consolidate my understanding of the details and to create a "Simplified Solidity for Beginners" guide for newbies (programming experts can find other tutorials). I update this guide with 1-3 lessons per week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[wtf.academy](https://wtf.academy)

All code and tutorials are open-sourced on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lesson, we will introduce token vesting clauses and write a contract for linearly releasing ERC20 tokens. The code is simplified from OpenZeppelin's VestingWallet contract.

## Token Vesting Clauses

In traditional finance, some companies provide equity to employees and management. However, a large amount of equity released at the same time can create selling pressure in the short term, dragging down the stock price. Therefore, companies typically introduce a vesting period to delay ownership of committed assets. Similarly, in the blockchain field, Web3 startups allocate tokens to their teams and also sell tokens at a low price to venture capital and private equity. If they simultaneously bring these low-cost tokens to the exchange for liquidity, the token price will be crushed, making retail investors the bag holders.

So, project teams generally agree on token vesting clauses, gradually releasing tokens during the vesting period to reduce selling pressure and prevent teams and capital parties from going out too early.

## Linear Release

Linear release refers to the constant release of tokens during the vesting period. For example, if a private equity holds 365,000 ICU tokens with a vesting period of 1 year (365 days), 1,000 tokens will be released every day.

Now, let's write a contract TokenVesting for locking and linearly releasing ERC20 tokens. Its logic is simple:

- The project team specifies the start time, vesting period, and beneficiary of the linear release.
- The project team transfers the ERC20 tokens to be locked to the TokenVesting contract.
- The beneficiary can call the release function to withdraw the released tokens from the contract.

### Events

There is `1` event in the Linear Release contract.
- `ERC20Released`: withdrawal event, triggered when the beneficiary withdraws the released tokens.

```solidity

contract TokenVesting {
    // 事件
    event ERC20Released(address indexed token, uint256 amount); // 提币事件
```

### State Variables 
There are `4` state variables in the linear release contract.
- `beneficiary`: the beneficiary address.
- `start`: the starting timestamp of the vesting period.
- `duration`: the duration of the vesting period in seconds.
- `erc20Released`: a mapping of token address to the amount released, which records the amount of tokens the beneficiary has already claimed.

```solidity
    // 状态变量
    mapping(address => uint256) public erc20Released; // 代币地址->释放数量的映射，记录已经释放的代币
    address public immutable beneficiary; // 受益人地址
    uint256 public immutable start; // 起始时间戳
    uint256 public immutable duration; // 归属期
```

### Functions
There are `3` functions in the LinearVesting contract.

- Constructor: initializes the beneficiary address, duration in seconds and starting timestamp. The constructor takes `beneficiaryAddress` and `durationSeconds` as input parameters. The starting timestamp is set to the deployment blockchain timestamp `block.timestamp` for convenience.
- `release()`: transfers the vested tokens to the beneficiary address. This function calls `vestedAmount()` to calculate the amount of vested tokens, emits the `ERC20Released` event, and then calls the `transfer` function to transfer tokens to the beneficiary. The token address is passed as an input parameter `token`.
- `vestedAmount()`: calculates the number of vested tokens based on the linear vesting formula. Developers can modify this function to implement a customized vesting schedule. The function takes `token` and `timestamp` as input parameters.

```solidity
    /**
     * @dev 初始化受益人地址，释放周期(秒), 起始时间戳(当前区块链时间戳)
     */
    constructor(
        address beneficiaryAddress,
        uint256 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    /**
     * @dev 受益人提取已释放的代币。
     * 调用vestedAmount()函数计算可提取的代币数量，然后transfer给受益人。
     * 释放 {ERC20Released} 事件.
     */
    function release(address token) public {
        // 调用vestedAmount()函数计算可提取的代币数量
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        // 更新已释放代币数量   
        erc20Released[token] += releasable; 
        // 转代币给受益人
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    /**
     * @dev 根据线性释放公式，计算已经释放的数量。开发者可以通过修改这个函数，自定义释放方式。
     * @param token: 代币地址
     * @param timestamp: 查询的时间戳
     */
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        // 合约里总共收到了多少代币（当前余额 + 已经提取）
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        // 根据线性释放公式，计算已经释放的数量
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
```

## `Remix` Demo

### 1. Deploy the `ERC20` contract in [Lesson 31](../31_ERC20/readme.md), and mint yourself `10000` tokens.

![Deploy ERC20](./img/43-2.png)

![Mint 10000 tokens](./img/43-3.png)

### 2. Deploy the `TokenVesting` contract for linear release, set yourself as the beneficiary, and set the vesting period to `100` seconds.

![Deploy TokenVesting](./img/43-4.png)

### 3. Transfer `10000` `ERC20` tokens to the linear release contract.

![Transfer tokens](./img/43-5.png)

### 4. Call the `release()` function to extract the tokens.

![Release tokens](./img/43-6.png)

## Summary

A large amount of token unlocking in the short term can cause huge pressure on the token price, while agreed-upon token ownership terms can alleviate selling pressure and prevent the team and capital parties from exiting too early. In this lesson, we introduced token ownership terms and wrote a contract for linear release of ERC20 tokens.