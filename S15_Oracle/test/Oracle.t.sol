// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Oracle.sol";

contract wtfsolidity_safe is Test {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router router;
    IWETH private weth = IWETH(WETH);
    IDAI private dai = IDAI(DAI);
    string MAINNET_RPC_URL;
    Oracle  oracle;

    function setUp() public {
        MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        // fork当前区块
        // vm.selectFork(mainnetFork);
        // fork指定区块
        vm.createSelectFork(MAINNET_RPC_URL,16060405);
        router = IUniswapV2Router(Router);
        oracle = new Oracle();
    }

    //forge test --match-test  testOracleAttack  -vv
    function testOracleAttack() public {
        // 添加流动性之前的价格
        uint256 price = oracle.getPrice();
        console.log("before: price: %s", price);

        uint256 amountA = 1e7 * 1e18;
        uint256 amountB = 1e5 * 1e18;
        // 获取代币并授权
        uint256 tokenbOut = swapToken(amountA, amountB);
        // 添加流动性
         weth.approve(address(oracle), amountA);
         dai.approve(address(oracle), tokenbOut);
       (uint amountAr, uint amountBr, uint liquidityr) = oracle.addLiquidity(WETH,DAI,amountA, tokenbOut);
       //   添加流动性成功的代币 
       console.log("tokenAsent: %s  e18, tokenBsent %s e18 ,lpget %s e18 ",amountAr / 1e18, amountBr / 1e18, liquidityr / 1e18);
        // 添加流动性之后的价格
        uint256 priceAfter =  oracle.getPrice();
        console.log("after: price: %s", priceAfter);  
    }

    function swapToken(uint256 amountAIn, uint256 amountBIn)
        public
        returns (uint256 amountout)
    {
        //  币种A兑换
        weth.deposit{value: amountAIn+amountBIn}();
        weth.approve(address(this), amountAIn+amountBIn);
        
        //  币种B兑换
        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        // 经router调用，所以要给router approve
        weth.approve(address(router), amountBIn);   
        uint[] memory amounts = router.swapExactTokensForTokens(
            amountBIn,
            1e18,
            path,
            address(this),
            block.timestamp
        );

        // amounts[0] = WETH amount, amounts[1] = DAI amount,
        return amounts[1];
    }
}



interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IDAI is IERC20 {
    function balanceOf(address account) external view returns (uint);
}
