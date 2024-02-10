// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.4;

contract UncheckedBank {
    mapping (address => uint256) public balanceOf;    // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 提取msg.sender的全部ether
    function withdraw() external {
        // 获取余额
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        balanceOf[msg.sender] = 0;
        // Unchecked low-level call
        bool success = payable(msg.sender).send(balance);
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    UncheckedBank public bank; // Bank合约地址

    // 初始化Bank合约地址
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }
    
    // 回调函数，转账ETH时会失败
    receive() external payable {
        revert();
    }

    // 存款函数，调用时 msg.value 设为存款数量
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // 取款函数，虽然调用成功，但实际上取款失败
    function withdraw() external payable {
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
