// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract ValueTypes{
    // Booleanos
    bool public _bool = true;
    // Operatores booleanos
    bool public _bool1 = !_bool; // NOT lógico
    bool public _bool2 = _bool && _bool1; // AND lógico
    bool public _bool3 = _bool || _bool1; // OR lógico
    bool public _bool4 = _bool == _bool1; // igualdad
    bool public _bool5 = _bool != _bool1; // desigualdad


    // Enteros
    int public _int = -1;
    uint public _uint = 1;
    uint256 public _number = 20220330;
    // Operatores para variables de tipo entero
    uint256 public _number1 = _number + 1; // +，-，*，/
    uint256 public _number2 = 2**2; // exponente
    uint256 public _number3 = 7 % 2; // módulo
    bool public _numberbool = _number2 > _number3; // mayor que


    // Tipo de datos para variables de tipo address
    address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    address payable public _address1 = payable(_address); // payable address (puede transferir fondos y verificar el saldo) 
    // Atributos de las variables de tipo address
    uint256 public balance = _address1.balance; // saldo en la dirección
    
    
    // Arreglos de bytes de tamaño fijo
    bytes32 public _byte32 = "MiniSolidity"; // bytes32: 0x4d696e69536f6c69646974790000000000000000000000000000000000000000
    bytes1 public _byte = _byte32[0]; // bytes1: 0x4d
    
    
    // Enumeración
    // Let uint 0， 1， 2 Representa Buy, Hold, Sell
    enum ActionSet { Buy, Hold, Sell }
    // Crea una variable de tipo enum llamada action
    ActionSet action = ActionSet.Buy;

    // Enum puede ser convertido a uint
    function enumToUint() external view returns(uint){
        return uint(action);
    }
}

