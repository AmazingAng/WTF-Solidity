// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
contract Mapping {
      mapping(uint => address) public idToAddress; // id maps to address
      mapping(address => address) public swapPair; // Mapping of token pairs, from address to address


      //Rule 1. _KeyType cannot be custom. The following example will throw an error
      //Define a struct
      //struct Student{
      //    uint256 id;
      //    uint256 score;
      //}
      //mapping(struct => uint) public testVar;

      function writeMap (uint _Key, address _Value) public {
        idToAddress[_Key] = _Value;
      }
}