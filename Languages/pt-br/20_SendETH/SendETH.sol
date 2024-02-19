// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 3 formas de enviar ETH
// transferir: 2300 gás, reverter
// enviar: 2300 gás, retornar bool
// chamar: todo gás, retornar (bool, dados)

// Falha ao enviar ETH usando o comando send
// Falha ao enviar ETH usando a função call

contract SendETH {
    // Construtor, payable permite transferir ETH durante a implantação
    constructor() payable{}
    // Método receive, acionado ao receber eth
    receive() external payable{}

    // Enviar ETH usando transfer()
    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    // enviar() enviar ETH
    function sendETH(address payable _to, uint256 amount) external payable{
        // Tratando o valor de retorno do 'send', se falhar, reverta a transação e envie um erro.
        bool success = _to.send(amount);
        if(!success){
            revert SendFailed();
        }
    }

    // call() enviar ETH
    function callETH(address payable _to, uint256 amount) external payable{
        // Tratando o valor de retorno da chamada, se falhar, reverta a transação e envie um erro
        (bool success,) = _to.call{value: amount}("");
        if(!success){
            revert CallFailed();
        }
    }
}

contract ReceiveETH {
    // Recebendo evento eth, registrando amount e gas
    event Log(uint amount, uint gas);

    // Método receive, acionado ao receber eth
    receive() external payable{
        emit Log(msg.value, gasleft());
    }
    
    // Retorna o saldo de ETH do contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }
}
