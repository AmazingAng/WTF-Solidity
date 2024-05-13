// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 3种方法发送ETH
// transfer: 2300 gas, revert
// send: 2300 gas, return bool
// call: all gas, return (bool, data)

error SendFailed(); // 用send发送ETH失败error
error CallFailed(); // 用call发送ETH失败error

contract SendETH {
    // 构造函数，payable使得部署的时候可以转eth进去
    constructor() payable{}
    // receive方法，接收eth时被触发
    receive() external payable{}

    // 用transfer()发送ETH
    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    // send()发送ETH
    function sendETH(address payable _to, uint256 amount) external payable{
        // 处理下send的返回值，如果失败，revert交易并发送error
        bool success = _to.send(amount);
        if(!success){
            revert SendFailed();
        }
    }

    // call()发送ETH
    function callETH(address payable _to, uint256 amount) external payable{
        // 处理下call的返回值，如果失败，revert交易并发送error
        (bool success,) = _to.call{value: amount}("");
        if(!success){
            revert CallFailed();
        }
    }
}

contract ReceiveETH {
    // 收到eth事件，记录amount和gas
    event Log(uint amount, uint gas);

    // receive方法，接收eth时被触发
    receive() external payable{
        emit Log(msg.value, gasleft());
    }
    
    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }
}
