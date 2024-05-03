// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 3 Formas de enviar ETH
// transfer: 2300 gas, revertir
// send: 2300 gas, retorna bool
// call: all gas, returnar (bool, data)

error SendFailed(); // error cuando se envía con Send 
error CallFailed(); // error cuando se envía con Call

contract SendETH {
    // Constructor, hacerlo pagable para poder transferir ETH al despliegue
    constructor() payable{}
    // receive function, llamada al recibir ETH
    receive() external payable{}

    // enviar ETH con transfer()
    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    // enviar ETH con send()
    function sendETH(address payable _to, uint256 amount) external payable{
        // verificar el resultado de send(), revertir con error cuando falla
        bool success = _to.send(amount);
        if(!success){
            revert SendFailed();
        }
    }

    // enviar ETH con call()
    function callETH(address payable _to, uint256 amount) external payable{
        // verificar el resultado de call(), revertir con error cuando falla
        (bool success,) = _to.call{value: amount}("");
        if(!success){
            revert CallFailed();
        }
    }
}

contract ReceiveETH {
    // Recibir evento ETH, registrar la cantidad y el gas
    event Log(uint amount, uint gas);

    // receive se ejecuta al recibir ETH
    receive() external payable{
        emit Log(msg.value, gasleft());
    }
    
    // retorna el balance del contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }
}
