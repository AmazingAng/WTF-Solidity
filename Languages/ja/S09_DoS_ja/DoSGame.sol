// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// DoS脆弱性を持つゲームコントラクト
// プレイヤーが最初に資金を預け、ゲーム終了後にrefundで返金される
contract DoSGame {
    bool public refundFinished;  // 返金完了フラグ
    mapping(address => uint256) public balanceOf;  // 各プレイヤーの預金額
    address[] public players;  // プレイヤーアドレスの配列

    // すべてのプレイヤーがETHをコントラクトに預ける
    function deposit() external payable {
        require(!refundFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");
        // 預金額を記録
        balanceOf[msg.sender] = msg.value;
        // プレイヤーアドレスを記録
        players.push(msg.sender);
    }

    // ゲーム終了、返金開始、すべてのプレイヤーが順次返金を受ける
    // 脆弱性: 外部callが失敗するとrevertし、全体の返金処理が停止する
    function refund() external {
        require(!refundFinished, "Game Over");
        uint256 pLength = players.length;
        // ループですべてのプレイヤーに返金
        // 問題: 一人でも返金に失敗すると全体が停止する
        for(uint256 i; i < pLength; i++){
            address player = players[i];
            uint256 refundETH = balanceOf[player];
            // 外部callを使用 - 攻撃ベクターになり得る
            (bool success, ) = player.call{value: refundETH}("");
            require(success, "Refund Fail!");  // 脆弱性: 失敗時に全体が停止
            balanceOf[player] = 0;
        }
        refundFinished = true;
    }

    // コントラクトの残高を確認
    function balance() external view returns(uint256){
        return address(this).balance;
    }
}