// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// selfdestruct: Elimina el contrato y transfiere por la fuerza el ETH restante del contrato a la cuenta designada

contract DeleteContract {
    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // Llame a selfdestruct para destruir el contrato y transferir el ETH restante a msg.sender.
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns (uint balance) {
        balance = address(this).balance;
    }
}


Revisar el balance del contrato después del despliegue
Check the balance of contract after deployed
