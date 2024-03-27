// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//  Contract "Yeye" in Lecture 10--Contract Inheritance
contract Yeye {
    event Log(string msg);

    // Define 3 functions: hip(), pop(), yeye()， with log "Yeye"。
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
