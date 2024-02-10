// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface Base {
    function getFirstName() external pure returns(string memory);
    function getLastName() external pure returns(string memory);
}
contract BaseImpl is Base{
    function getFirstName() external pure override returns(string memory){
        return "Amazing";
    }
    function getLastName() external pure override returns(string memory){
        return  "Ang";
    }
}
