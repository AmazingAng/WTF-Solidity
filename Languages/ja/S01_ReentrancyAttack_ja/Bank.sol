// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

/**
 * @title Bank - 脆弱性のある銀行コントラクト
 * @notice リエントランシー攻撃の脆弱性を持つサンプルコントラクト
 * @dev このコントラクトは教育目的のみで、実際の使用は推奨されません
 */
contract Bank {
    mapping (address => uint256) public balanceOf;    // ユーザー残高のマッピング

    // イベント定義
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice etherを預け、残高を更新する
     * @dev ユーザーの残高を増加させる安全な関数
     */
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice msg.senderの全てのetherを引き出す
     * @dev 【警告】この関数にはリエントランシー脆弱性があります！
     * 問題点：
     * 1. 残高チェック後に外部送金を実行
     * 2. 送金後に残高を更新（遅延更新）
     * 3. 外部コントラクトのfallback/receive関数が呼ばれる可能性
     */
    function withdraw() external {
        // ステップ1: 残高を取得
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        // ステップ2: ether送金
        // 【危険】悪意のあるコントラクトのfallback/receive関数を起動する可能性があり、
        // リエントランシーリスクがある！
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        // ステップ3: 残高を更新（この時点で攻撃者は既に再入済み）
        balanceOf[msg.sender] = 0;
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice 銀行コントラクトの総残高を取得
     * @return このコントラクトが保有するETHの総額
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 特定ユーザーの残高を取得
     * @param user 残高を確認したいユーザーのアドレス
     * @return ユーザーの残高
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}