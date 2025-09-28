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
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e18);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        flashloan.flashloan(amountToBorrow);
    }

    // 手数料が不足している場合、リバートする
    function testFlashloanFail() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 3e17);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        // 手数料不足
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}