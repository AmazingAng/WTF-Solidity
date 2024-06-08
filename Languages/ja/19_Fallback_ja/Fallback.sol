// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Fallback {
    /* fallback() or receive()?
           ETHを受け取る
              |
         msg.dataがemptyか？
            /  \
         はい   いいえ
          /      \
    receive()あるか?   fallback()
        / \
      はい いいえ
      /     \
     /       \
    receive()   fallback()
    */

    // eventを定義
    event receivedCalled(address Sender, uint256 Value);
    event fallbackCalled(address Sender, uint256 Value, bytes Data);

    // ETHを受け取るときにイベントを発生
    receive() external payable {
        emit receivedCalled(msg.sender, msg.value);
    }

    // fallback
    fallback() external payable {
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }
}
