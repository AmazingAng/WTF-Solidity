// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Lesson10の継承について使ったYeyeコントラクトをimport
contract Yeye {
    event Log(string msg);

    // 3つのfunction: hip(), pop(), yeye()を定義し、Logの値はYeye。
    function hip() public virtual {
        emit Log("Yeye");
    }

    function pop() public virtual {
        emit Log("Yeye");
    }

    function yeye() public virtual {
        emit Log("Yeye");
    }
}
