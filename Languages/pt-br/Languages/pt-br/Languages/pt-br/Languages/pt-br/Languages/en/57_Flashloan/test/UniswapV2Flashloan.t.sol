// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapV2Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
     IWETH private weth = IWETH(WETH);

     UniswapV2Flashloan private flashloan;

     function setUp() public {
         flashloan = new UniswapV2Flashloan();
     }

     function testFlashloan() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e18);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         flashloan.flashloan(amountToBorrow);
     }

     // If the handling fee is insufficient, it will be reverted.
     function testFlashloanFail() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 3e17);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         // Insufficient handling fee
         vm.expectRevert();
         flashloan.flashloan(amountToBorrow);
     }
}
