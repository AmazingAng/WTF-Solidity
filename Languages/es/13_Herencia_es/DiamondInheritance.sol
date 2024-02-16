// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* Árbol de herencia visualizado:
  God
 /  \
Adam Eve
 \  /
people
*/

contract God {
    event Log(string message);

    function foo() public virtual {
        emit Log("God.foo llamado");
    }

    function bar() public virtual {
        emit Log("God.bar llamado");
    }
}

contract Adam is God {
    function foo() public virtual override {
        emit Log("Adam.foo llamado");
    }

    function bar() public virtual override {
        emit Log("Adam.bar llamado");
        super.bar();
    }
}

contract Eve is God {
    function foo() public virtual override {
        emit Log("Eve.foo llamado");
    }

    function bar() public virtual override {
        emit Log("Eve.bar llamado");
        super.bar();
    }
}

contract people is Adam, Eve {
    function foo() public override(Adam, Eve) {
        super.foo();
    }

    function bar() public override(Adam, Eve) {
        super.bar();
    }
}
