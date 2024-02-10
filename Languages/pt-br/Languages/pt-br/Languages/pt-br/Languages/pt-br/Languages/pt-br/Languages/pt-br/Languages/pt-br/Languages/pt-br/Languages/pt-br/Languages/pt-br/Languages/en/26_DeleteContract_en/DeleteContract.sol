// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// selfdestruct: Delete the contract and forcibly transfer the remaining ETH of the contract to the designated account

contract DeleteContract {
    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // Call selfdestruct to destroy the contract and transfer the remaining ETH to msg.sender.
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns (uint balance) {
        balance = address(this).balance;
    }
}
