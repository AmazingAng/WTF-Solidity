// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contrato de herança
contract Yeye {
    event Log(string msg);

    // Definir 3 funções: hip(), pop() e man(), com o valor de Log como Yeye.
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

contract Baba is Yeye{
    // class Baba extends hip() {
    pop() {
        co console.log("Baba")
    }
 }
    function pop() public virtual override{
        emit Log("Baba");
    }

    function baba() public virtual{
        emit Log("Baba");
    }
}

contract Erzi is Yeye, Baba{
    // Herda duas funções: hip() e pop(), e altera a saída para "Erzi".
    function hip() public virtual override(Yeye, Baba){
        emit Log("Erzi");
    }

    function pop() public virtual override(Yeye, Baba) {
        emit Log("Erzi");
    }

    function callParent() public{
        Yeye.pop();
    }

    function callParentSuper() public{
        super.pop();
    }
}

// Herança de construtores
abstract contract A {
    uint public a;

    constructor(uint _a) {
        a = _a;
    }
}

contract B is A(1) {
}

contract C is A {
    constructor(uint _c) A(_c * _c) {}
}
