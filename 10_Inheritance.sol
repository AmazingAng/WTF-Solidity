// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 合约继承
contract Yeye {
    // 定义3个function: hip(), pop(), man()，返回值设为A。
    function hip() public pure virtual returns (string memory){
        return("Yeye");
    }

    function pop() public pure virtual returns (string memory){
        return("Yeye");
    }

    function yeye() public pure virtual returns (string memory){
        return("Yeye");
    }
}

contract Baba is Yeye{
    // 继承两个function: hip()和pop()，返回值改为B。
    function hip() public pure virtual override returns (string memory){
        return("Baba");
    }

    function pop() public pure virtual override returns (string memory){
        return("Baba");
    }

    function baba() public pure virtual returns (string memory){
        return("Baba");
    }
}

contract Erzi is Yeye, Baba{
    // 继承两个function: hip()和pop()，返回值改为B。
    function hip() public pure virtual override(Yeye, Baba) returns (string memory){
        return("Erzi");
    }

    function pop() public pure virtual override(Yeye, Baba) returns (string memory){
        return("Erzi");
    }
}

// 构造函数的继承
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
