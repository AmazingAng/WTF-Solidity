// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
contract Mapping {
      mapping(uint => address) public idToAddress; // id es mapeado a la dirección
      mapping(address => address) public swapPair; // mapeo de tokens, de dirección a dirección



      //Rule 1. _KeyType cannot be custom types. The following example will throw an error
      // Regla 1. _KeyType no puede usar tipos de variables personalizadas como struct. El siguiente ejemplo lanzará un error
      //Definir un struct
      //struct Student{
      //    uint256 id;
      //    uint256 score;
      //}
      //mapping(struct => uint) public testVar;

      function writeMap (uint _Key, address _Value) public {
        idToAddress[_Key] = _Value;
      }
}
