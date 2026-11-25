// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
contract Mapping {
    mapping(uint => address) public idToAddress; // Mapeia o ID para o endereço
    mapping(address => address) public swapPair; // Mapeia pares de moedas
    
    // Regra 1. _KeyType não pode ser personalizado. O exemplo abaixo resultará em um erro.
    // Definimos uma estrutura Struct
    // struct Aluno{
    //    uint256 id;
    //    uint256 score;
    //
    // mapping(Struct => uint) public testVar;

    function writeMap (uint _Key, address _Value) public{
        idToAddress[_Key] = _Value;
    }
}
