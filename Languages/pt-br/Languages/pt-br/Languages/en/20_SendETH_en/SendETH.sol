// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 3 ways to send ETH
// transfer: 2300 gas, revert
// send: 2300 gas, return bool
// call: all gas, return (bool, data)

error SendFailed(); // error when sending with Send
error CallFailed(); // error when seding with Call

contract SendETH {
    // Constructor, make it payable so we can transfer ETH at depolyment
    constructor() payable{}
    // receive function, called when receiving ETH
    receive() external payable{}

    // sending ETH with transfer()
    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    // sending ETH with send()
    function sendETH(address payable _to, uint256 amount) external payable{
        // check result of send()，revert with error when failed
        bool success = _to.send(amount);
        if(!success){
            revert SendFailed();
        }
    }

    // sending ETH with call()
    function callETH(address payable _to, uint256 amount) external payable{
        // check result of call()，revert with error when failed
        (bool success,) = _to.call{value: amount}("");
        if(!success){
            revert CallFailed();
        }
    }
}

contract ReceiveETH {
    // Receiving ETH event, log the amount and gas
    event Log(uint amount, uint gas);

    // receive is executed when receiving ETH
    receive() external payable{
        emit Log(msg.value, gasleft());
    }
    
    // return the balance of the contract
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }
}
