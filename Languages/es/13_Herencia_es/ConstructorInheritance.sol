// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
