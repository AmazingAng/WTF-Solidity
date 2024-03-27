// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Base1 {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}

contract Identifier is Base1 {

    //Calcular el valor de un número dividido por 2 y dividido por 3, respectivamente, pero los parámetros pasados deben ser múltiplos de 2 y 3
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    //Calcular del valor de un número devidido por 2 y dividido por 3, respectivamente
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }


    // Reescribir el modificador: cuando no se reescribe, se ingresa 9 para llamar a getExactDividedBy2And3, se revertirá por que no puede pasar la verificación. 
    // Eliminar las siguientes tres lineas de comentarios y reescribir la función del modificador. En este momento, se ingresa 9 para llamar a getExactDividedBy2And3, y la llamada será exitosa.
    // modifier exactDividedBy2And3(uint _a) override {
    //     _;
    // }
}

