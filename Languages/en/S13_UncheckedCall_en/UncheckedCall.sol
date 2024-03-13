// SPDX-License-Identifier: MIT
// by 0xAA
// english translation by 22X
pragma solidity ^0.8.21;

contract UncheckedBank {
    mapping (address => uint256) public balanceOf;    // Balance mapping

    // Deposit ether and update balance
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Withdraw all ether from msg.sender
    function withdraw() external {
        // Get the balance
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        balanceOf[msg.sender] = 0;
        // Unchecked low-level call
        bool success = payable(msg.sender).send(balance);
    }

    // Get the balance of the bank contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    UncheckedBank public bank; // Bank contract address

    // Initialize the Bank contract address
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }
    
    // Callback function, transfer will fail
    receive() external payable {
        revert();
    }

    // Deposit function, set msg.value as the deposit amount
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // Withdraw function, although the call is successful, the withdrawal actually fails
    function withdraw() external payable {
        bank.withdraw();
    }

    // Get the balance of this contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
