// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Aula 10: Contrato Yeye na herança de contratos
contract Yeye {
    event Log(string msg);

    // Definir 3 funções: hip(), pop(), yeye(), com o valor de Log sendo Yeye.
    function hip() public virtual{
        emit Log("Yeye");
    }

    function pop() public virtual{
        emit Log("Yeye");
    }

    function yeye() public virtual {
        emit Log("Yeye");
    }
}
