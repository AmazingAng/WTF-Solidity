// SPDX-License-Identifier: MIT
// por 0xAA
pragma solidity ^0.8.4;

contract UncheckedBank {
    // Mapeamento de saldo

    // Depositar ether e atualizar o saldo
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Extrair todos os ether do msg.sender
    function withdraw() external {
        // Obter saldo
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        balanceOf[msg.sender] = 0;
        // Chamada de baixo nível não verificada
        bool success = payable(msg.sender).send(balance);
    }

    // Obter o saldo do contrato bancário
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    // Endereço do contrato Bank

    // Inicializando o endereço do contrato Bank
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }
    
    // Função de retorno, a transferência de ETH falhará
    receive() external payable {
        revert();
    }

    // Função de depósito, quando chamada, defina msg.value como a quantidade a ser depositada
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // Função de saque, embora a chamada tenha sido bem-sucedida, na realidade o saque falhou
    function withdraw() external payable {
        bank.withdraw();
    }

    // Obter o saldo deste contrato
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
