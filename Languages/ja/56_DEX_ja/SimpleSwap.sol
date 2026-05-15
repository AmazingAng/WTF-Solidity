// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {
    // トークンコントラクト
    IERC20 public token0;
    IERC20 public token1;

    // トークン準備金
    uint public reserve0;
    uint public reserve1;

    // イベント
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    // コンストラクタ、トークンアドレスを初期化
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    // 2つの数の最小値を取得
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // 平方根を計算 babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // 流動性を追加、トークンを転送、LPをミント
    // 初回追加の場合、ミントされるLP数量 = sqrt(amount0 * amount1)
    // 初回以外の場合、ミントされるLP数量 = min(amount0/reserve0, amount1/reserve1)* totalSupply_LP
    // @param amount0Desired 追加するtoken0の数量
    // @param amount1Desired 追加するtoken1の数量
    function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
        // 追加する流動性をSwapコントラクトに転送、事前にSwapコントラクトに承認が必要
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        // 追加する流動性を計算
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // 初回流動性追加の場合、L = sqrt(x * y) 単位のLP（流動性プロバイダー）トークンをミント
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            // 初回以外の場合、追加するトークン数量の比率でLPをミント、2つのトークンのうち小さい方の比率を取る
            liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

        // ミントされるLP数量をチェック
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // 準備金を更新
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // 流動性プロバイダーにLPトークンをミント、提供した流動性を表す
        _mint(msg.sender, liquidity);

        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    // 流動性を除去、LPを焼却、トークンを転送
    // 転送数量 = (liquidity / totalSupply_LP) * reserve
    // @param liquidity 除去する流動性数量
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        // 残高を取得
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        // LPの比率に応じて転送するトークン数量を計算
        uint _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        // トークン数量をチェック
        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        // LPを焼却
        _burn(msg.sender, liquidity);
        // トークンを転送
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        // 準備金を更新
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    // アセットの数量とトークンペアの準備金が与えられた場合、交換する他のトークンの数量を計算
    // 積が一定のため
    // 交換前: k = x * y
    // 交換後: k = (x + delta_x) * (y + delta_y)
    // delta_y = - delta_x * y / (x + delta_x) が得られる
    // 正/負号は転入/転出を表す
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    // トークンをswap
    // @param amountIn 交換に使用するトークン数量
    // @param tokenIn 交換に使用するトークンコントラクトアドレス
    // @param amountOutMin 交換して得られる他のトークンの最小数量
    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');

        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if(tokenIn == token0){
            // token0をtoken1に交換する場合
            tokenOut = token1;
            // 交換できるtoken1数量を計算
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // 交換を実行
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            // token1をtoken0に交換する場合
            tokenOut = token0;
            // 交換できるtoken1数量を計算
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // 交換を実行
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        // 準備金を更新
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}