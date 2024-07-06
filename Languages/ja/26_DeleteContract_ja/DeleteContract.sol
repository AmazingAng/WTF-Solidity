// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// selfdestruct: コントラクトを削除し、残りのETHを指定したアドレスに送金

contract DeleteContract {
    uint256 public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // コントラクトを削除し、コントラクトの残りETHをmsg.senderに送金
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }
}
