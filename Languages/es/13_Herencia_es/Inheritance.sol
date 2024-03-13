// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Contrato de herencia
contract Grandfather {
    event Log(string msg);

    // Aplicar herencia a las siguientes 3 funciones: hip(), pop(), man()，luego registrar "Grandfather".
    function hip() public virtual{
        emit Log("Grandfather");
    }

    function pop() public virtual{
        emit Log("Grandfather");
    }

    function grandfather() public virtual {
        emit Log("Grandfather");
    }
}

contract Father is Grandfather{
    // Aplicamos herencia a las siguientes 2 funciones: hip() y pop(), luego cambiamos el valor del registro a `Father`.
    function hip() public virtual override{
        emit Log("Father");
    }

    function pop() public virtual override{
        emit Log("Father");
    }

    function father() public virtual{
        emit Log("Father");
    }
}

contract Son is Grandfather, Father{
    // Aplicamos herencia a las siguientes 2 funciones: hip() y pop(), luego cambiamos el valor del registro a "Son".
    function hip() public virtual override(Grandfather, Father){
        emit Log("Son");
    }

    function pop() public virtual override(Grandfather, Father) {
        emit Log("Son");
    }

    function callParent() public{
        Grandfather.pop();
    }

    function callParentSuper() public{
        super.pop();
    }
}

