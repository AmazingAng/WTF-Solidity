// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract InitialValue {
    // Tipos de valores
    bool public _bool; // false
    string public _string; // ""
    int public _int; // 0
    uint public _uint; // 0
    address public _address; // 0x0000000000000000000000000000000000000000

    enum ActionSet { Buy, Hold, Sell}
    ActionSet public _enum; // primer elemento 0

    function fi() internal{} // Función interna en blanco 
    function fe() external{} // Función externa vacía 

    // Tipos de valores de referencia
    uint[8] public _staticArray; //Un arreglo estático donde todos los miembros se configuran con su valor por defecto[0,0,0,0,0,0,0,0]
    uint[] public _dynamicArray; // `[]`
    mapping(uint => address) public _mapping; // Un mapeo donde todos los miembros se configuran con su valor por defecto
     // Una estructura donde todos los miembros se configuran con su valor por defecto 0, 0
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student public student;

    // Operador 'delete'
    bool public _bool2 = true; 
    function d() external {
        delete _bool2; // delete hará que _bool2 cambie a su valor por defecto (falso)
    }
}