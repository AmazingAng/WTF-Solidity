// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV3 flash loan callback interface
//Need to implement and rewrite the uniswapV3FlashCallback() function
interface IUniswapV3FlashCallback {
     /// In the implementation, you must repay the pool for the tokens sent by flash and the calculated fee amount.
     /// The contract calling this method must be checked by the UniswapV3Pool deployed by the official UniswapV3Factory.
     /// @param fee0 The fee amount of token0 that should be paid to the pool when the flash loan ends
     /// @param fee1 The fee amount of token1 that should be paid to the pool when the flash loan ends
     /// @param data Any data passed by the caller is called via IUniswapV3PoolActions#flash
     function uniswapV3FlashCallback(
         uint256 fee0,
         uint256 fee1,
         bytes calldata data
     ) external;
}

// UniswapV3 flash loan contract
contract UniswapV3Flashloan is IUniswapV3FlashCallback {
     address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

     address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
     address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
     uint24 private constant poolFee = 3000;

     IERC20 private constant weth = IERC20(WETH);
     IUniswapV3Pool private immutable pool;

     constructor() {
         pool = IUniswapV3Pool(getPool(DAI, WETH, poolFee));
     }

     function getPool(
         address _token0,
         address_token1,
         uint24_fee
     ) public pure returns (address) {
         PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
             _token0,
             _token1,
             _fee
         );
         return PoolAddress.computeAddress(UNISWAP_V3_FACTORY, poolKey);
     }

     // Flash loan function
     function flashloan(uint wethAmount) external {
         bytes memory data = abi.encode(WETH, wethAmount);
         IUniswapV3Pool(pool).flash(address(this), 0, wethAmount, data);
     }

     // Flash loan callback function can only be called by the DAI/WETH pair contract
     function uniswapV3FlashCallback(
         uint fee0,
         uint fee1,
         bytes calldata data
     ) external {
         // Confirm that the call is DAI/WETH pair contract
         require(msg.sender == address(pool), "not authorized");
        
         //Decode calldata
         (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

         // flashloan logic, omitted here
         require(tokenBorrow == WETH, "token borrow != WETH");

         //Repay flash loan
         weth.transfer(address(pool), wethAmount + fee1);
     }
}
