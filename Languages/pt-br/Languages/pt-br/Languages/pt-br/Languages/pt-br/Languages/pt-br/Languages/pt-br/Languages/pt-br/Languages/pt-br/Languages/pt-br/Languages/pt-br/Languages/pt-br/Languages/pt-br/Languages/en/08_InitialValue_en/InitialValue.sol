// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract InitialValue {
    // Value Types
    bool public _bool; // false
    string public _string; // ""
    int public _int; // 0
    uint public _uint; // 0
    address public _address; // 0x0000000000000000000000000000000000000000

    enum ActionSet { Buy, Hold, Sell}
    ActionSet public _enum; // first element 0

    function fi() internal{} // internal blank equation 
    function fe() external{} // external blank equation 

    // Reference Types
    uint[8] public _staticArray; // A static array which all members set to their default values[0,0,0,0,0,0,0,0]
    uint[] public _dynamicArray; // `[]`
    mapping(uint => address) public _mapping; // A mapping which all members set to their default values
    // A struct which all members set to their default values 0, 0
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student public student;

    // delete operator
    bool public _bool2 = true; 
    function d() external {
        delete _bool2; // delete will make _bool2 change to default(false)
    }
}