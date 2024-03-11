---
title: 56. 去中心化交易所
tags:
  - solidity
  - erc20
  - defi
---

# WTF Solidity极简入门: 56. 去中心化交易所

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity 极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们将介绍恒定乘积自动做市商（Constant Product Automated Market Maker, CPAMM），它是去中心化交易所的核心机制，被Uniswap，PancakeSwap等一系列DEX采用。教学合约由[Uniswap-v2](https://github.com/Uniswap/v2-core)合约简化而来，包括了CPAMM最核心的功能。

## 自动做市商

自动做市商（Automated Market Maker，简称 AMM）是一种算法，或者说是一种在区块链上运行的智能合约，它允许数字资产之间的去中心化交易。AMM 的引入开创了一种全新的交易方式，无需传统的买家和卖家进行订单匹配，而是通过一种预设的数学公式（比如，常数乘积公式）创建一个流动性池，使得用户可以随时进行交易。

![](./img/56-1.png)

接下来，我们以可乐（$COLA）和美元（$USD）的市场为例，给大家介绍 AMM。为了方便，我们规定一下符号: $x$ 和 $y$ 分别表示市场中可乐和美元的总量，$\Delta x$ 和 $\Delta y$ 分别表示一笔交易中可乐和美元的变化量，$L$ 和 $\Delta L$ 表示总流动性和流动性的变化量。

### 恒定总和自动做市商

恒定总和自动做市商（Constant Sum Automated Market Maker, CSAMM）是最简单的自动做市商模型，我们从它开始。它在交易时的约束为:

$$k=x+y$$

其中 $k$ 为常数。也就是说，在交易前后市场中可乐和美元数量的总和保持不变。举个例子，市场中流动性有 10 瓶可乐和 10 美元，此时 $k=20$，可乐的价格为 1 美元/瓶。我很渴，想拿出 2 美元来换可乐。交易后市场中的美元总量变为 12，根据约束$k=20$，交易后市场中有 8 瓶可乐，价格为 1 美元/瓶。我在交易中得到了 2 瓶可乐，价格为 1 美元/瓶。

CSAMM 的优点是可以保证代币的相对价格不变，这点在稳定币兑换中很重要，大家都希望 1 USDT 总能兑换出 1 USDC。但它的缺点也很明显，它的流动性很容易耗尽：我只需要 10 美元，就可以把市场上可乐的流动性耗尽，其他想喝可乐的用户就没法交易了。

下面我们介绍拥有”无限“流动性的恒定乘积自动做市商。

### 恒定乘积自动做市商

恒定乘积自动做市商（CPAMM）是最流行的自动做市商模型，最早被 Uniswap 采用。它在交易时的约束为:

$$k=x*y$$

其中 $k$ 为常数。也就是说，在交易前后市场中可乐和美元数量的乘积保持不变。同样的例子，市场中流动性有 10 瓶可乐和 10 美元，此时 $k=100$，可乐的价格为 1 美元/瓶。我很渴，想拿出 10 美元来换可乐。如果在 CSAMM 中，我的交易会换来 10 瓶可乐，并耗尽市场上可乐的流动性。但在 CPAMM 中，交易后市场中的美元总量变为 20，根据约束 $k=100$，交易后市场中有 5 瓶可乐，价格为 $20/5 = 4$ 美元/瓶。我在交易中得到了 5 瓶可乐，价格为 $10/5 = 2$ 美元/瓶。

CPAMM 的优点是拥有“无限”流动性：代币的相对价格会随着买卖而变化，越稀缺的代币相对价格会越高，避免流动性被耗尽。上面的例子中，交易让可乐从 1 美元/瓶 上涨到 4 美元/瓶，从而避免市场上的可乐被买断。

下面，让我们建立一个基于 CPAMM 的极简的去中心化交易所。

## 去中心化交易所

下面，我们用智能合约写一个去中心化交易所 `SimpleSwap`，支持用户交易一对代币。

`SimpleSwap` 继承了 ERC20 代币标准，方便记录流动性提供者提供的流动性。在构造器中，我们指定一对代币地址 `token0` 和 `token1`，交易所仅支持这对代币。`reserve0` 和 `reserve1` 记录了合约中代币的储备量。

```solidity
contract SimpleSwap is ERC20 {
    // 代币合约
    IERC20 public token0;
    IERC20 public token1;

    // 代币储备量
    uint public reserve0;
    uint public reserve1;
    
    // 构造器，初始化代币地址
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }
}
```

交易所主要有两类参与者：流动性提供者（Liquidity Provider，LP）和交易者（Trader）。下面我们分别实现这两部分的功能。

### 流动性提供

流动性提供者给市场提供流动性，让交易者获得更好的报价和流动性，并收取一定费用。

首先，我们需要实现添加流动性的功能。当用户向代币池添加流动性时，合约要记录添加的LP份额。根据 Uniswap V2，LP份额如下计算：

1. 代币池被首次添加流动性时，LP份额 $\Delta{L}$ 由添加代币数量乘积的平方根决定:

    $$\Delta{L}=\sqrt{\Delta{x} *\Delta{y}}$$

1. 非首次添加流动性时，LP份额由添加代币数量占池子代币储备量的比例决定（两个代币的比例取更小的那个）:

    $$\Delta{L}=L*\min{(\frac{\Delta{x}}{x}, \frac{\Delta{y}}{y})}$$

因为 `SimpleSwap` 合约继承了 ERC20 代币标准，在计算好LP份额后，可以将份额以代币形式铸造给用户。

下面的 `addLiquidity()` 函数实现了添加流动性的功能，主要步骤如下：

1. 将用户添加的代币转入合约，需要用户事先给合约授权。
2. 根据公式计算添加的流动性份额，并检查铸造的LP数量。
3. 更新合约的代币储备量。
4. 给流动性提供者铸造LP代币。
5. 释放 `Mint` 事件。

```solidity
event Mint(address indexed sender, uint amount0, uint amount1);

// 添加流动性，转进代币，铸造LP
// @param amount0Desired 添加的token0数量
// @param amount1Desired 添加的token1数量
function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
    // 将添加的流动性转入Swap合约，需事先给Swap合约授权
    token0.transferFrom(msg.sender, address(this), amount0Desired);
    token1.transferFrom(msg.sender, address(this), amount1Desired);
    // 计算添加的流动性
    uint _totalSupply = totalSupply();
    if (_totalSupply == 0) {
        // 如果是第一次添加流动性，铸造 L = sqrt(x * y) 单位的LP（流动性提供者）代币
        liquidity = sqrt(amount0Desired * amount1Desired);
    } else {
        // 如果不是第一次添加流动性，按添加代币的数量比例铸造LP，取两个代币更小的那个比例
        liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
    }

    // 检查铸造的LP数量
    require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

    // 更新储备量
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    // 给流动性提供者铸造LP代币，代表他们提供的流动性
    _mint(msg.sender, liquidity);
    
    emit Mint(msg.sender, amount0Desired, amount1Desired);
}
```

接下来，我们需要实现移除流动性的功能。当用户从池子中移除流动性 $\Delta{L}$ 时，合约要销毁LP份额代币，并按比例将代币返还给用户。返还代币的计算公式如下:

$$\Delta{x}={\frac{\Delta{L}}{L} * x}$$ 
$$\Delta{y}={\frac{\Delta{L}}{L} * y}$$ 

下面的 `removeLiquidity()` 函数实现移除流动性的功能，主要步骤如下：

1. 获取合约中的代币余额。
2. 按LP的比例计算要转出的代币数量。
3. 检查代币数量。
4. 销毁LP份额。
5. 将相应的代币转账给用户。
6. 更新储备量。
5. 释放 `Burn` 事件。

```solidity
// 移除流动性，销毁LP，转出代币
// 转出数量 = (liquidity / totalSupply_LP) * reserve
// @param liquidity 移除的流动性数量
function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
    // 获取余额
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));
    // 按LP的比例计算要转出的代币数量
    uint _totalSupply = totalSupply();
    amount0 = liquidity * balance0 / _totalSupply;
    amount1 = liquidity * balance1 / _totalSupply;
    // 检查代币数量
    require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
    // 销毁LP
    _burn(msg.sender, liquidity);
    // 转出代币
    token0.transfer(msg.sender, amount0);
    token1.transfer(msg.sender, amount1);
    // 更新储备量
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    emit Burn(msg.sender, amount0, amount1);
}
```

至此，合约中与流动性提供者相关的功能完成了，接下来是交易的部分。

### 交易

在Swap合约中，用户可以使用一种代币交易另一种。那么我用 $\Delta{x}$单位的 token0，可以交换多少单位的 token1 呢？下面我们来简单推导一下。

根据恒定乘积公式，交易前：

$$k=x*y$$

交易后，有：

$$k=(x+\Delta{x})*(y+\Delta{y})$$

交易前后 $k$ 值不变，联立上面等式，可以得到：

$$\Delta{y}=-\frac{\Delta{x}*y}{x+\Delta{x}}$$

因此，可以交换到的代币数量 $\Delta{y}$ 由 $\Delta{x}$，$x$，和 $y$ 决定。注意 $\Delta{x}$ 和 $\Delta{y}$ 的符号相反，因为转入会增加代币储备量，而转出会减少。

下面的 `getAmountOut()` 实现了给定一个资产的数量和代币对的储备，计算交换另一个代币的数量。

```solidity
// 给定一个资产的数量和代币对的储备，计算交换另一个代币的数量
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
    require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
    amountOut = amountIn * reserveOut / (reserveIn + amountIn);
}
```

有了这一核心公式后，我们可以着手实现交易功能了。下面的 `swap()` 函数实现了交易代币的功能，主要步骤如下：

1. 用户在调用函数时指定用于交换的代币数量，交换的代币地址，以及换出另一种代币的最低数量。
2. 判断是 token0 交换 token1，还是 token1 交换 token0。
3. 利用上面的公式，计算交换出代币的数量。
4. 判断交换出的代币是否达到了用户指定的最低数量，这里类似于交易的滑点。
5. 将用户的代币转入合约。
6. 将交换的代币从合约转给用户。
7. 更新合约的代币储备量。
8. 释放 `Swap` 事件。

```solidity
// swap代币
// @param amountIn 用于交换的代币数量
// @param tokenIn 用于交换的代币合约地址
// @param amountOutMin 交换出另一种代币的最低数量
function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
    require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
    require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
    
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));

    if(tokenIn == token0){
        // 如果是token0交换token1
        tokenOut = token1;
        // 计算能交换出的token1数量
        amountOut = getAmountOut(amountIn, balance0, balance1);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        // 进行交换
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }else{
        // 如果是token1交换token0
        tokenOut = token0;
        // 计算能交换出的token1数量
        amountOut = getAmountOut(amountIn, balance1, balance0);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        // 进行交换
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }

    // 更新储备量
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
}
```

## Swap 合约

`SimpleSwap` 的完整代码如下：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {
    // 代币合约
    IERC20 public token0;
    IERC20 public token1;

    // 代币储备量
    uint public reserve0;
    uint public reserve1;
    
    // 事件 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    // 构造器，初始化代币地址
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    // 取两个数的最小值
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // 计算平方根 babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // 添加流动性，转进代币，铸造LP
    // 如果首次添加，铸造的LP数量 = sqrt(amount0 * amount1)
    // 如果非首次，铸造的LP数量 = min(amount0/reserve0, amount1/reserve1)* totalSupply_LP
    // @param amount0Desired 添加的token0数量
    // @param amount1Desired 添加的token1数量
    function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
        // 将添加的流动性转入Swap合约，需事先给Swap合约授权
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        // 计算添加的流动性
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // 如果是第一次添加流动性，铸造 L = sqrt(x * y) 单位的LP（流动性提供者）代币
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            // 如果不是第一次添加流动性，按添加代币的数量比例铸造LP，取两个代币更小的那个比例
            liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

        // 检查铸造的LP数量
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // 更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // 给流动性提供者铸造LP代币，代表他们提供的流动性
        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    // 移除流动性，销毁LP，转出代币
    // 转出数量 = (liquidity / totalSupply_LP) * reserve
    // @param liquidity 移除的流动性数量
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        // 获取余额
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        // 按LP的比例计算要转出的代币数量
        uint _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        // 检查代币数量
        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        // 销毁LP
        _burn(msg.sender, liquidity);
        // 转出代币
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        // 更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    // 给定一个资产的数量和代币对的储备，计算交换另一个代币的数量
    // 由于乘积恒定
    // 交换前: k = x * y
    // 交换后: k = (x + delta_x) * (y + delta_y)
    // 可得 delta_y = - delta_x * y / (x + delta_x)
    // 正/负号代表转入/转出
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    // swap代币
    // @param amountIn 用于交换的代币数量
    // @param tokenIn 用于交换的代币合约地址
    // @param amountOutMin 交换出另一种代币的最低数量
    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if(tokenIn == token0){
            // 如果是token0交换token1
            tokenOut = token1;
            // 计算能交换出的token1数量
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // 进行交换
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            // 如果是token1交换token0
            tokenOut = token0;
            // 计算能交换出的token1数量
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // 进行交换
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        // 更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}
```

## Remix 复现

1. 部署两个ERC20代币合约（token0 和 token1），并记录它们的合约地址。

2. 部署 `SimpleSwap` 合约，并将上面的代币地址填入。

3. 调用两个ERC20代币的`approve()`函数，分别给 `SimpleSwap` 合约授权 1000 单位代币。

4. 调用 `SimpleSwap` 合约的 `addLiquidity()` 函数给交易所添加流动性，token0 和 token1 分别添加 100 单位。

5. 调用 `SimpleSwap` 合约的 `balanceOf()` 函数查看用户的LP份额，这里应该为 100。（$\sqrt{100*100}=100$）

6. 调用 `SimpleSwap` 合约的 `swap()` 函数进行代币交易，用 100 单位的 token0。

7. 调用 `SimpleSwap` 合约的 `reserve0` 和 `reserve1` 函数查看合约中的代币储备粮，应为 200 和 50。上一步我们利用 100 单位的 token0 交换了 50 单位的 token 1（$\frac{100*100}{100+100}=50$）。

## 总结

这一讲，我们介绍了恒定乘积自动做市商，并写了一个极简的去中心化交易所。在极简Swap合约中，我们有很多没有考虑的部分，例如交易费用以及治理部分。如果你对去中心化交易所感兴趣，推荐你阅读 [Programming DeFi: Uniswap V2](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) 和 [Uniswap v3 book](https://y1cunhui.github.io/uniswapV3-book-zh-cn/) ，更深入的学习。