// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Contrato "Yeye" en la Clase 10--Herencia de Contratos
contract Yeye {
    event Log(string msg);

    // Definir 3 funciones: hip(), pop(), yeye()， con log "Yeye"。
    function hip() public virtual{
        emit Log("Yeye");
    }

    function pop() public virtual{
        emit Log("Yeye");
    }

    function yeye() public virtual {
        emit Log("Yeye"); }
}
