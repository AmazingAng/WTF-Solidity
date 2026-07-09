// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV2フラッシュローンコールバックインターフェース
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// UniswapV2フラッシュローンコントラクト
contract UniswapV2Flashloan is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
    }

    // フラッシュローン関数
    function flashloan(uint wethAmount) external {
        // calldataの長さが1より大きい場合にフラッシュローンコールバック関数をトリガー
        bytes memory data = abi.encode(WETH, wethAmount);

        // amount0Outは借りるDAI、amount1Outは借りるWETH
        pair.swap(0, wethAmount, address(this), data);
    }

    // フラッシュローンコールバック関数、DAI/WETH pairコントラクトのみが呼び出し可能
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // DAI/WETH pairコントラクトからの呼び出しであることを確認
        address token0 = IUniswapV2Pair(msg.sender).token0(); // token0アドレスを取得
        address token1 = IUniswapV2Pair(msg.sender).token1(); // token1アドレスを取得
        assert(msg.sender == factory.getPair(token0, token1)); // msg.senderがV2ペアであることを確認

        // calldataをデコード
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // フラッシュローンロジック、ここでは省略
        require(tokenBorrow == WETH, "token borrow != WETH");

        // フラッシュローン手数料を計算
        // fee / (amount + fee) = 3/1000
        // 切り上げ
        uint fee = (amount1 * 3) / 997 + 1;
        uint amountToRepay = amount1 + fee;

        // フラッシュローンを返済
        weth.transfer(address(pair), amountToRepay);
    }
}