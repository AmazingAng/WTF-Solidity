// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// selfdestruct: Exclui o contrato e força a transferência de qualquer ETH restante no contrato para uma conta especificada.

contract DeleteContract {

    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // Chamar selfdestruct para destruir o contrato e transferir os ETH restantes para msg.sender
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns(uint balance){
        balance = address(this).balance;
    }
}
