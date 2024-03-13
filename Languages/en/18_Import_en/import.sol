// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Import via relative location of file
import './Yeye.sol';
// Import specific contracts via `global symbols`
import {Yeye} from './Yeye.sol';
// Import by URL
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
// Import "OpenZeppelin" contract
import '@openzeppelin/contracts/access/Ownable.sol';

contract Import {
    // Successfully import the Address library
    using Address for address;
    // declare variable "yeye"
    Yeye yeye = new Yeye();

    // Test whether the function of "yeye" can be called
    function test() external{
        yeye.hip();
    }
}
