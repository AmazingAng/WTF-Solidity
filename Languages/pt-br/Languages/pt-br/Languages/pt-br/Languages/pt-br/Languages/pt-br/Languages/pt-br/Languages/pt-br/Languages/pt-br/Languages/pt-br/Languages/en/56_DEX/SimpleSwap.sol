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
     eventSwap(
         address indexed sender,
         uint amountIn,
         address tokenIn,
         uint amountOut,
         address tokenOut
         );

     //Constructor, initialize token address
     constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
         token0 = _token0;
         token1 = _token1;
     }

     // Get the minimum of two numbers
     function min(uint x, uint y) internal pure returns (uint z) {
         z = x < y ? x : y;
     }

     // Compute square roots babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
