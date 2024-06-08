// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OtherContract {
    uint256 private _x = 0; // Variable de estado x
    // Recibir evento ETH, registrar la cantidad y el gas
    event Log(uint amount, uint gas);

    fallback() external payable{}

    // obtener el saldo del contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // Asignar el valor de x, así como recibir ETH (pagable)
    function setX(uint256 x) external payable{
        _x = x;
        // Emitir evento Log al recibir ETH
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // Leer el valor de x
    function getX() external view returns(uint x){
        x = _x;
    }
}

contract Call{
    // Declarar evento de respuesta, con parámetros de éxito y datos
    event Response(bool success, bytes data);

    function callSetX(address payable _addr, uint256 x) public payable {
        // Llamar a setX() y enviar ETH
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("setX(uint256)", x)
        );

        emit Response(success, data); //emitir evento
    }

    function callGetX(address _addr) external returns(uint256){
        // Llamar a getX()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("getX()")
        );

        emit Response(success, data); //emitir evento
        return abi.decode(data, (uint256));
    }

    function callNonExist(address _addr) external{
        // Llamar getX()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("foo(uint256)")
        );

        emit Response(success, data); //emitir evento
    }
}
