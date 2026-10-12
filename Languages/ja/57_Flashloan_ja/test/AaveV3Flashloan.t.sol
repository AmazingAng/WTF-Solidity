// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AaveV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract AaveV3FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    AaveV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new AaveV3Flashloan();
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
        weth.transfer(address(flashloan), 4e16);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        // 手数料不足
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}