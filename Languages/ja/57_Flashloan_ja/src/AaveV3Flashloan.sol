// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

interface IFlashLoanSimpleReceiver {
    /**
    * @notice フラッシュローン資産受信後の操作実行
    * @dev コントラクトが債務＋追加手数料を返済できることを確認してください。
    *      例：十分な資金を持ち、プールから総額を引き出すための承認を行っている
    * @param asset フラッシュローン資産のアドレス
    * @param amount フラッシュローン資産の数量
    * @param premium フラッシュローン資産の手数料
    * @param initiator フラッシュローンを開始したアドレス
    * @param params フラッシュローン初期化時に渡されたバイトエンコードパラメータ
    * @return 操作実行が成功した場合はTrue、失敗した場合はFalseを返す
    */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// AAVE V3フラッシュローンコントラクト
contract AaveV3Flashloan {
    address private constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILendingPool public aave;

    constructor() {
        aave = ILendingPool(AAVE_V3_POOL);
    }

    // フラッシュローン関数
    function flashloan(uint256 wethAmount) external {
        aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
    }

    // フラッシュローンコールバック関数、poolコントラクトのみが呼び出し可能
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
        external
        returns (bool)
    {
        // poolコントラクトからの呼び出しであることを確認
        require(msg.sender == AAVE_V3_POOL, "not authorized");
        // フラッシュローン開始者がこのコントラクトであることを確認
        require(initiator == address(this), "invalid initiator");

        // フラッシュローンロジック、ここでは省略

        // フラッシュローン手数料を計算
        // fee = 5/1000 * amount
        uint fee = (amount * 5) / 10000 + 1;
        uint amountToRepay = amount + fee;

        // フラッシュローンを返済
        IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

        return true;
    }
}