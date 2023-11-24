---
title: 56. Decentralized Exchange
tags:
   - solidity
   - erc20
   - Defi
---

# WTF A simple introduction to Solidity: 56. Decentralized exchange

I'm recently re-learning solidity, consolidating the details, and writing a "WTF Solidity Minimalist Introduction" for novices (programming experts can find another tutorial), updating 1-3 lectures every week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) |[Official website wtf.academy](https://wtf.academy)

All codes and tutorials are open source on github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)
-----

In this lecture, we will introduce the Constant Product Automated Market Maker (CPAMM), which is the core mechanism of decentralized exchanges and is used by a series of DEXs such as Uniswap and PancakeSwap. The teaching contract is simplified from the [Uniswap-v2](https://github.com/Uniswap/v2-core) contract and includes the core functions of CPAMM.

## Automatic market maker

An Automated Market Maker (AMM) is an algorithm, or a smart contract that runs on the blockchain, which allows decentralized transactions between digital assets. The introduction of AMM has created a new trading method that does not require traditional buyers and sellers to match orders. Instead, a liquidity pool is created through a preset mathematical formula (such as a constant product formula), allowing users to trade at any time. Trading.

![](./img/56-1.png)

Next, we will introduce AMM to you, taking the markets of Coke ($COLA) and US Dollar ($USD) as examples. For convenience, we specify the symbols: $x$ and $y$ respectively represent the total amount of cola and dollars in the market, $\Delta x$ and $\Delta y$ respectively represent the changes in cola and dollars in a transaction, $L$ and $\Delta L$ represent total liquidity and changes in liquidity.

### Constant Sum Automated Market Maker

The Constant Sum Automated Market Maker (CSAMM) is the simplest automated market maker model, and we will start with it. Its constraints during transactions are:

$$k=x+y$$

where $k$ is a constant. That is, the sum of the quantities of colas and dollars in the market remains the same before and after the trade. For example, there are 10 bottles of Coke and $10 in the market. At this time, $k=20$, and the price of Coke is $1/bottle. I was thirsty and wanted to exchange my $2 for a Coke. The total number of dollars in the post-trade market becomes 12. According to the constraint $k=20$, there are 8 bottles of Coke in the post-trade market at a price of $1/bottle. I got 2 bottles of coke in the deal for $1/bottle.

The advantage of CSAMM is that it can ensure that the relative price of tokens remains unchanged. This is very important in stable currency exchange. Everyone hopes that 1 USDT can always be exchanged for 1 USDC. But its shortcomings are also obvious. Its liquidity is easily exhausted: I only need $10 to exhaust the liquidity of Coke in the market, and other users who want to drink Coke will not be able to trade.

Below we introduce the constant product automatic market maker with "unlimited" liquidity.

### Constant product automatic market maker

Constant Product Automatic Market Maker (CPAMM) is the most popular automatic market maker model and was first adopted by Uniswap. Its constraints during transactions are:

$$k=x*y$$

where $k$ is a constant. That is, the product of the quantities of colas and dollars in the market remains the same before and after the trade. In the same example, there are 10 bottles of Coke and $10 in the market. At this time, $k=100$, and the price of Coke is $1/bottle. I was thirsty and wanted to exchange $10 for a Coke. If it were in CSAMM, my transaction would be in exchange for 10 bottles of Coke and deplete the liquidity of Cokes in the market. But in CPAMM, the total amount of dollars in the post-trade market becomes 20. According to the constraint $k=100$, there are 5 bottles of Coke in the post-trade market with a price of $20/5 = 4$ dollars/bottle. I got 5 bottles of Coke in the deal at a price of $10/5 = $2$ per bottle.

The advantage of CPAMM is that it has "unlimited" liquidity: the relative price of tokens will change with buying and selling, and the scarcer tokens will have a higher relative price to avoid exhaustion of liquidity. In the example above, the transaction increases the price of Coke from $1/bottle to $4/bottle, thus preventing Coke on the market from being bought out.

Next, let us build a minimalist decentralized exchange based on CPAMM.

## Decentralized exchange

Next, we use smart contracts to write a decentralized exchange `SimpleSwap` to support users to trade a pair of tokens.

`SimpleSwap` inherits the ERC20 token standard and facilitates recording of liquidity provided by liquidity providers. In the constructor, we specify a pair of token addresses `token0` and `token1`. The exchange only supports this pair of tokens. `reserve0` and `reserve1` record the reserve amount of tokens in the contract.

```solidity
contract SimpleSwap is ERC20 {
     //Token contract
     IERC20 public token0;
     IERC20 public token1;

     //Token reserve amount
     uint public reserve0;
     uint public reserve1;
    
     //Constructor, initialize token address
     constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
         token0 = _token0;
         token1 = _token1;
    }
}
```

There are two main types of participants in the exchange: Liquidity Provider (LP) and Trader. Below we implement the functions of these two parts respectively.

### Liquidity Provision

Liquidity providers provide liquidity to the market, allowing traders to obtain better quotes and liquidity, and charge a certain fee.

First, we need to implement the functionality to add liquidity. When a user adds liquidity to the token pool, the contract records the added LP share. According to Uniswap V2, LP share is calculated as follows:

1. When liquidity is added to the token pool for the first time, the LP share $\Delta{L}$ is determined by the square root of the product of the number of added tokens:

     $$\Delta{L}=\sqrt{\Delta{x} *\Delta{y}}$$

1. When liquidity is not added for the first time, the LP share is determined by the ratio of the number of added tokens to the pool’s token reserves (the smaller of the two tokens):

     $$\Delta{L}=L*\min{(\frac{\Delta{x}}{x}, \frac{\Delta{y}}{y})}$$

Because the `SimpleSwap` contract inherits the ERC20 token standard, after calculating the LP share, the share can be minted to the user in the form of tokens.

The following `addLiquidity()` function implements the function of adding liquidity. The main steps are as follows:

1. To transfer the tokens added by the user to the contract, the user needs to authorize the contract in advance.
2. Calculate the added liquidity share according to the formula and check the number of minted LPs.
3. Update the token reserve of the contract.
4. Mint LP tokens for liquidity providers.
5. Release the `Mint` event.

```solidity
event Mint(address indexed sender, uint amount0, uint amount1);

// Add liquidity, transfer tokens, and mint LP
// @param amount0Desired The amount of token0 added
// @param amount1Desired The amount of token1 added
function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
     // To transfer the added liquidity to the Swap contract, you need to give the Swap contract authorization in advance.
     token0.transferFrom(msg.sender, address(this), amount0Desired);
     token1.transferFrom(msg.sender, address(this), amount1Desired);
     // Calculate added liquidity
     uint _totalSupply = totalSupply();
     if (_totalSupply == 0) {
         // If liquidity is added for the first time, mint L = sqrt(x * y) units of LP (liquidity provider) tokens
         liquidity = sqrt(amount0Desired * amount1Desired);
     } else {
         // If it is not the first time to add liquidity, LP will be minted in proportion to the number of added tokens, and the smaller ratio of the two tokens will be used.
         liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);

   // Check the amount of LP minted
     require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

     // Update reserve
     reserve0 = token0.balanceOf(address(this));
     reserve1 = token1.balanceOf(address(this));

     // Mint LP tokens for liquidity providers to represent the liquidity they provide
     _mint(msg.sender, liquidity);
    
     emit Mint(msg.sender, amount0Desired, amount1Desired);
}
```

Next, we need to implement the functionality to remove liquidity. When a user removes liquidity $\Delta{L}$ from the pool, the contract must destroy the LP share tokens and return the tokens to the user in proportion. The calculation formula for returning tokens is as follows:

$$\Delta{x}={\frac{\Delta{L}}{L} * x}$$
$$\Delta{y}={\frac{\Delta{L}}{L} * y}$$

The following `removeLiquidity()` function implements the function of removing liquidity. The main steps are as follows:

1. Get the token balance in the contract.
2. Calculate the number of tokens to be transferred according to the proportion of LP.
3. Check the number of tokens.
4. Destroy LP shares.
5. Transfer the corresponding tokens to the user.
6. Update reserves.
5. Release the `Burn` event.

```solidity
// Remove liquidity, destroy LP, and transfer tokens
// Transfer quantity = (liquidity / totalSupply_LP) * reserve
// @param liquidity The amount of liquidity removed
function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
     // Get balance
     uint balance0 = token0.balanceOf(address(this));
     uint balance1 = token1.balanceOf(address(this));
     // Calculate the number of tokens to be transferred according to the proportion of LP
     uint _totalSupply = totalSupply();
     amount0 = liquidity * balance0 / _totalSupply;
     amount1 = liquidity * balance1 / _totalSupply;
     // Check the number of tokens
     require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
     // Destroy LP
_burn(msg.sender, liquidity);
     // Transfer tokens
     token0.transfer(msg.sender, amount0);
     token1.transfer(msg.sender, amount1);
     // Update reserve
     reserve0 = token0.balanceOf(address(this));
     reserve1 = token1.balanceOf(address(this));

     emit Burn(msg.sender, amount0, amount1);
}
```

At this point, the functions related to the liquidity provider in the contract are completed, and the next step is the transaction part.

### trade

In a Swap contract, users can trade one token for another. So how many units of token1 can I exchange for $\Delta{x}$ units of token0? Let us briefly derive it below.

According to the constant product formula, before trading:

$$k=x*y$$

After the transaction, there are:

$$k=(x+\Delta{x})*(y+\Delta{y})$$

The value of $k$ remains unchanged before and after the transaction. Combining the above equations, we can get:

$$\Delta{y}=-\frac{\Delta{x}*y}{x+\Delta{x}}$$

Therefore, the number of tokens $\Delta{y}$ that can be exchanged is determined by $\Delta{x}$, $x$, and $y$. Note that $\Delta{x}$ and $\Delta{y}$ have opposite signs, as transferring in increases the token reserve, while transferring out decreases it.

The `getAmountOut()` below implements, given the amount of an asset and the reserve of a token pair, calculates the amount to exchange for another token.

```solidity
// Given the amount of an asset and the reserve of a token pair, calculate the amount to exchange for another token
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
    require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
    amountOut = amountIn * reserveOut / (reserveIn + amountIn);
}
```

With this core formula in place, we can start implementing the trading function. The following `swap()` function implements the function of trading tokens. The main steps are as follows:

1. When calling the function, the user specifies the number of tokens for exchange, the address of the exchanged token, and the minimum amount for swapping out another token.
2. Determine whether token0 is exchanged for token1, or token1 is exchanged for token0.
3. Use the above formula to calculate the number of tokens exchanged.
4. Determine whether the exchanged tokens have reached the minimum number specified by the user, which is similar to the slippage of the transaction.
5. Transfer the user’s tokens to the contract.
6. Transfer the exchanged tokens from the contract to the user.
7. Update the token reserve of the contract.
8. Release the `Swap` event.

```solidity
// swap tokens
// @param amountIn the number of tokens used for exchange
// @param tokenIn token contract address used for exchange
// @param amountOutMin the minimum amount to exchange for another token
function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
    require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
    require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
    
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));

    if(tokenIn == token0){
// If token0 is exchanged for token1
         tokenOut = token1;
         // Calculate the number of token1 that can be exchanged
         amountOut = getAmountOut(amountIn, balance0, balance1);
         require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
         //Exchange
         tokenIn.transferFrom(msg.sender, address(this), amountIn);
         tokenOut.transfer(msg.sender, amountOut);
     }else{
         // If token1 is exchanged for token0
         tokenOut = token0;
         // Calculate the number of token1 that can be exchanged
        amountOut = getAmountOut(amountIn, balance1, balance0);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        //Exchange
         tokenIn.transferFrom(msg.sender, address(this), amountIn);
         tokenOut.transfer(msg.sender, amountOut);
     }

     // Update reserve
     reserve0 = token0.balanceOf(address(this));
     reserve1 = token1.balanceOf(address(this));

    emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
}
```

## Swap Contract

The complete code of `SimpleSwap` is as follows:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {
    //Token contract
     IERC20 public token0;
     IERC20 public token1;

     //Token reserve amount
    uint public reserve0;
    uint public reserve1;
    
    // event
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    // Constructor, initialize token address
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    // Find the minimum of two numbers
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // Calculate square roots babylonian method
(https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

  // Add liquidity, transfer tokens, and mint LP
     // If added for the first time, the amount of LP minted = sqrt(amount0 * amount1)
     // If it is not the first time, the amount of LP minted = min(amount0/reserve0, amount1/reserve1)* totalSupply_LP
     // @param amount0Desired The amount of token0 added
     // @param amount1Desired The amount of token1 added
     function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
         // To transfer the added liquidity to the Swap contract, you need to give the Swap contract authorization in advance.
         token0.transferFrom(msg.sender, address(this), amount0Desired);
         token1.transferFrom(msg.sender, address(this), amount1Desired);
         // Calculate added liquidity
         uint _totalSupply = totalSupply();
         if (_totalSupply == 0) {
             // If liquidity is added for the first time, mint L = sqrt(x * y) units of LP (liquidity provider) tokens
             liquidity = sqrt(amount0Desired * amount1Desired);
         } else {
             // If it is not the first time to add liquidity, LP will be minted in proportion to the number of added tokens, and the smaller ratio of the two tokens will be used.
             liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

// Check the amount of LP minted
         require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

         // Update reserve
         reserve0 = token0.balanceOf(address(this));
         reserve1 = token1.balanceOf(address(this));

         // Mint LP tokens for liquidity providers to represent the liquidity they provide
         _mint(msg.sender, liquidity);
        
         emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

// Remove liquidity, destroy LP, and transfer tokens
     // Transfer quantity = (liquidity / totalSupply_LP) * reserve
     // @param liquidity The amount of liquidity removed
     function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
         // Get balance
         uint balance0 = token0.balanceOf(address(this));
         uint balance1 = token1.balanceOf(address(this));
         // Calculate the number of tokens to be transferred according to the proportion of LP
         uint _totalSupply = totalSupply();
         amount0 = liquidity * balance0 / _totalSupply;
         amount1 = liquidity * balance1 / _totalSupply;
         // Check the number of tokens
         require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
         // Destroy LP
         _burn(msg.sender, liquidity);
         // Transfer tokens
         token0.transfer(msg.sender, amount0);
         token1.transfer(msg.sender, amount1);
         // Update reserve
         reserve0 = token0.balanceOf(address(this));
         reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

// Given the amount of an asset and the reserve of a token pair, calculate the amount to exchange for another token
     // Since the product is constant
     // Before swapping: k = x * y
     // After swapping: k = (x + delta_x) * (y + delta_y)
     // Available delta_y = - delta_x * y / (x + delta_x)
     // Positive/negative signs represent transfer in/out
     function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
         require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
         require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
         amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

// swap tokens
     // @param amountIn the number of tokens used for exchange
     // @param tokenIn token contract address used for exchange
     // @param amountOutMin the minimum amount to exchange for another token
    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

if(tokenIn == token0){
             // If token0 is exchanged for token1
             tokenOut = token1;
             // Calculate the number of token1 that can be exchanged
             amountOut = getAmountOut(amountIn, balance0, balance1);
             require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
             //Exchange
             tokenIn.transferFrom(msg.sender, address(this), amountIn);
             tokenOut.transfer(msg.sender, amountOut);
         }else{
             // If token1 is exchanged for token0
             tokenOut = token0;
             // Calculate the number of token1 that can be exchanged
             amountOut = getAmountOut(amountIn, balance1, balance0);
             require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
             //Exchange
             tokenIn.transferFrom(msg.sender, address(this), amountIn);
             tokenOut.transfer(msg.sender, amountOut);
         }

         // Update reserve
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}
```

## Remix Reappearance

1. Deploy two ERC20 token contracts (token0 and token1) and record their contract addresses.

2. Deploy the `SimpleSwap` contract and fill in the token address above.

3. Call the `approve()` function of the two ERC20 tokens to authorize 1000 units of tokens to the `SimpleSwap` contract respectively.

4. Call the `addLiquidity()` function of the `SimpleSwap` contract to add liquidity to the exchange, and add 100 units to token0 and token1 respectively.

5. Call the `balanceOf()` function of the `SimpleSwap` contract to view the user’s LP share, which should be 100. ($\sqrt{100*100}=100$)

6. Call the `swap()` function of the `SimpleSwap` contract to trade tokens, using 100 units of token0.

7. Call the `reserve0` and `reserve1` functions of the `SimpleSwap` contract to view the token reserves in the contract, which should be 200 and 50. In the previous step, we used 100 units of token0 to exchange 50 units of token 1 ($\frac{100*100}{100+100}=50$).

## Summary

In this lecture, we introduced the constant product automatic market maker and wrote a minimalist decentralized exchange. In the minimalist Swap contract, we have many parts that we have not considered, such as transaction fees and governance parts. If you are interested in decentralized exchanges, it is recommended that you read [Programming DeFi: Uniswap V2](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) and [Uniswap v3 book](https: //y1cunhui.github.io/uniswapV3-book-zh-cn/) for more in-depth learning.
