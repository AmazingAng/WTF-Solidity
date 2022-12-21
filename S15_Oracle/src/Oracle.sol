// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Oracle {
    address private constant FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant Router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IUniswapV2Router router = IUniswapV2Router(Router);
    IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
    IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(WETH, DAI));
    IERC20 private weth = IERC20(WETH);
    IERC20 private dai = IERC20(DAI);
    event Log(string message, uint256 val);

    function getPrice() public returns (uint256) {
        // pair 交易对中储备
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        emit Log("reserve0", reserve0 / 1e18);
        emit Log("reserve1", reserve1 / 1e18);
        // lp 总量
        uint256 lptotalSupply = pair.totalSupply();
        emit Log("lptotalSupply", lptotalSupply / 1e18);
        return (lptotalSupply * 1e5) / (reserve0 + reserve1);

        // 其他公式
        // return  (reserve0*reserve1)/lptotalSupply;          overflow 溢出了
        // return  (reserve0+reserve1)/lptotalSupply;          lp越大，价格越低
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        IERC20(_tokenA).approve(Router, _amountA);
        IERC20(_tokenB).approve(Router, _amountB);

        emit Log(
            "amm a balance",
            IERC20(_tokenA).balanceOf(address(this)) / 1e18
        );
        // 添加流动性
        // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-01#addliquidity
        (uint amountAr, uint amountBr, uint liquidityr) = router.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            0,
            0,
            address(this),
            block.timestamp
        );

        return (amountAr, amountBr, liquidityr);
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
}

interface IUniswapV2Router {
    //  swap相关
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //  流动性相关
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function factory() external view returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}
