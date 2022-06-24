// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// selfdestruct: 删除合约，并强制将合约剩余的ETH转入指定账户

contract DeleteContract {

    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // 调用selfdestruct销毁合约，并把剩余的ETH转给msg.sender
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns(uint balance){
        balance = address(this).balance;
    }
}
