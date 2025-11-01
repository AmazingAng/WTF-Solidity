// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV3フラッシュローンコールバックインターフェース
// uniswapV3FlashCallback()関数を実装・オーバーライドする必要があります
interface IUniswapV3FlashCallback {
    /// 実装では、flashで送信されたトークンと計算された手数料を
    /// プールに返済する必要があります。
    /// このメソッドを呼び出すコントラクトは、公式UniswapV3Factoryで
    /// デプロイされたUniswapV3Poolによってチェックされる必要があります。
    /// @param fee0 フラッシュローン終了時にプールに支払うtoken0の手数料
    /// @param fee1 フラッシュローン終了時にプールに支払うtoken1の手数料
    /// @param data IUniswapV3PoolActions#flash呼び出しで呼び出し元から渡された任意のデータ
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// UniswapV3フラッシュローンコントラクト
contract UniswapV3Flashloan is IUniswapV3FlashCallback {
    address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant poolFee = 3000;

    IERC20 private constant weth = IERC20(WETH);
    IUniswapV3Pool private immutable pool;

    constructor() {
        pool = IUniswapV3Pool(getPool(DAI, WETH, poolFee));
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) public pure returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return PoolAddress.computeAddress(UNISWAP_V3_FACTORY, poolKey);
    }

    // フラッシュローン関数
    function flashloan(uint wethAmount) external {
        bytes memory data = abi.encode(WETH, wethAmount);
        IUniswapV3Pool(pool).flash(address(this), 0, wethAmount, data);
    }

    // フラッシュローンコールバック関数、DAI/WETH pairコントラクトのみが呼び出し可能
    function uniswapV3FlashCallback(
        uint fee0,
        uint fee1,
        bytes calldata data
    ) external {
        // DAI/WETH pairコントラクトからの呼び出しであることを確認
        require(msg.sender == address(pool), "not authorized");

        // calldataをデコード
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // フラッシュローンロジック、ここでは省略
        require(tokenBorrow == WETH, "token borrow != WETH");

        // フラッシュローンを返済
        weth.transfer(address(pool), wethAmount + fee1);
    }
}