// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Inheritance contract（継承コントラクト）
contract Grandfather {
    event Log(string msg);

    // Apply inheritance to the following 3 functions: hip(), pop(), Grandfather()，then log "Grandfather".
    //（継承を次の3つの関数に対して適用します: hip()、pop()、Grandfather()、そしてログは"Grandfather"です。）
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
    // Apply inheritance to the following 2 functions: hip() and pop()， then change the log value to "Father".
    //（継承を次の2つの関数に対して適用します: hip()、pop()、そしてログの値を"Father"に変更します。）
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
    // Apply inheritance to the following 2 functions: hip() and pop()， then change the log value to "Son".
    //（継承を次の2つの関数に対して適用します: hip()、pop()、そしてログの値を"Son"に変更します。）
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

// Applying inheritance to the constructor functions
//（コンストラクター関数に対して継承を適用します）
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
