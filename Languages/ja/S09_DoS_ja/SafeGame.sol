// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// プルペイメントパターンを使用した安全なゲームコントラクト
// DoS攻撃を防ぐため、ユーザーが個別に返金を請求する方式を採用
contract SafeGame {
    bool public gameFinished;  // ゲーム終了フラグ
    mapping(address => uint256) public balanceOf;  // 各プレイヤーの預金額
    mapping(address => bool) public refunded;  // 返金済みフラグ
    address[] public players;  // プレイヤーアドレスの配列
    address public owner;  // ゲーム管理者

    // イベント定義
    event Deposit(address indexed player, uint256 amount);
    event GameEnded();
    event RefundClaimed(address indexed player, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // プレイヤーがETHを預ける
    function deposit() external payable {
        require(!gameFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");

        // 初回預金の場合、プレイヤーリストに追加
        if(balanceOf[msg.sender] == 0) {
            players.push(msg.sender);
        }
        // 預金額を累積
        balanceOf[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // ゲーム終了を宣言（管理者のみ）
    function endGame() external onlyOwner {
        require(!gameFinished, "Game already finished");
        gameFinished = true;
        emit GameEnded();
    }

    // プレイヤーが個別に返金を請求（プルペイメントパターン）
    // 重要: この方式により、一人の返金失敗が他に影響しない
    function claimRefund() external {
        require(gameFinished, "Game not finished");
        require(balanceOf[msg.sender] > 0, "No balance to refund");
        require(!refunded[msg.sender], "Already refunded");

        uint256 refundAmount = balanceOf[msg.sender];

        // 再入攻撃を防ぐため、状態を先に更新
        refunded[msg.sender] = true;
        balanceOf[msg.sender] = 0;

        // 返金実行
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        if (!success) {
            // 送金失敗の場合、状態を戻す
            refunded[msg.sender] = false;
            balanceOf[msg.sender] = refundAmount;
            revert("Refund failed");
        }

        emit RefundClaimed(msg.sender, refundAmount);
    }

    // 緊急時の一括返金機能（管理者のみ）
    // 注意: この関数も潜在的にDoS攻撃の対象となる可能性がある
    function emergencyRefundAll() external onlyOwner {
        require(gameFinished, "Game not finished");

        uint256 pLength = players.length;
        for(uint256 i = 0; i < pLength; i++){
            address player = players[i];
            if(!refunded[player] && balanceOf[player] > 0) {
                uint256 refundETH = balanceOf[player];
                refunded[player] = true;
                balanceOf[player] = 0;

                // 個別の失敗時も処理を続行
                (bool success, ) = player.call{value: refundETH}("");
                if(!success) {
                    // 失敗時はログを残して処理継続
                    // プレイヤーは後でclaimRefundを使用可能
                    refunded[player] = false;
                    balanceOf[player] = refundETH;
                }
            }
        }
    }

    // コントラクト残高を確認
    function balance() external view returns(uint256){
        return address(this).balance;
    }

    // プレイヤー数を取得
    function getPlayerCount() external view returns(uint256) {
        return players.length;
    }

    // 特定のプレイヤーの返金状況を確認
    function getRefundStatus(address player) external view returns(bool hasBalance, bool isRefunded, uint256 amount) {
        hasBalance = balanceOf[player] > 0;
        isRefunded = refunded[player];
        amount = balanceOf[player];
    }
}