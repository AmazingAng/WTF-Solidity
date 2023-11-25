// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV2 flash loan callback interface
interface IUniswapV2Callee {
     function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// UniswapV2 flash loan contract
contract UniswapV2Flashloan is IUniswapV2Callee {
     address private constant UNISWAP_V2_FACTORY =
         0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

     address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
     address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

     IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

     IERC20 private constant weth = IERC20(WETH);

     IUniswapV2Pair private immutable pair;

     constructor() {
         pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
     }

     // Flash loan function
     function flashloan(uint wethAmount) external {
         //The calldata length is greater than 1 to trigger the flash loan callback function
         bytes memory data = abi.encode(WETH, wethAmount);

         // amount0Out is the DAI to be borrowed, amount1Out is the WETH to be borrowed
         pair.swap(0, wethAmount, address(this), data);
     }

     // Flash loan callback function can only be called by the DAI/WETH pair contract
     function uniswapV2Call(
         address sender,
         uint amount0,
         uint amount1,
         bytes calldata data
     ) external {
         // Confirm that the call is DAI/WETH pair contract
         address token0 = IUniswapV2Pair(msg.sender).token0(); // Get token0 address
         address token1 = IUniswapV2Pair(msg.sender).token1(); // Get token1 address
         assert(msg.sender == factory.getPair(token0, token1)); // ensure that msg.sender is a V2 pair

         //Decode calldata
         (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

         // flashloan logic, omitted here
         require(tokenBorrow == WETH, "token borrow != WETH");

         // Calculate flashloan fees
         // fee / (amount + fee) = 3/1000
         // Rounded up
         uint fee = (amount1 * 3) / 997 + 1;
         uint amountToRepay = amount1 + fee;

         //Repay flash loan
         weth.transfer(address(pair), amountToRepay);
     }
}
