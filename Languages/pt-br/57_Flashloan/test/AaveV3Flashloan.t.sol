// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AaveV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    AaveV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new AaveV3Flashloan();
    }

    function testFlashloan() public {
        // Trocar weth e transferir para o contrato flashloan como taxa de transação
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e18);
        // Empréstimo de valor do empréstimo relâmpago
        uint amountToBorrow = 100 * 1e18;
        flashloan.flashloan(amountToBorrow);
    }

    // Taxa insuficiente, será revertido
    function testFlashloanFail() public {
        // Trocar weth e transferir para o contrato flashloan como taxa de transação
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 4e16);
        // Empréstimo de valor do empréstimo relâmpago
        uint amountToBorrow = 100 * 1e18;
        // Taxa insuficiente
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}
