// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// UUPS proxy looks like a regular proxy
// upgrade function is inside logic contract, the admin is able to upgrade the logic contract's address by calling upgrade function, thus change the logic of the contract
// FOR TEACHING PURPOSE ONLY, DO NOT USE IN PRODUCTION
contract UUPSProxy {
    // Address of the logic contract
    address public implementation; 
    // Address of admin
    address public admin;
    // A string, which can be changed by the function of the logic contract 
    string public words; 

    // Constructor function, initialize admin and logic contract addresses
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // Fallback function delegates the call to the logic contract
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
}

// UUPS logic contract(upgrade function inside logic contract)
contract UUPS1{
    // consistent with the proxy contract and prevent slot conflicts
    address public implementation; 
    address public admin; 
    // A string, which can be changed by the function of the logic contract 
    string public words;

    // change state variable in proxy, selector: 0xc2985578
    function foo() public{
        words = "old";
    }

    // upgrade function, change logic contract's address, only admin is permitted to call. selector: 0x0900f010
    // in UUPS, logic contract HAS TO include a upgrade function, otherwise it cannot be upgraded any more.
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

contract UUPS2{
    // consistent with the proxy contract and prevent slot conflicts
    address public implementation; 
    address public admin; 
    // A string, which can be changed by the function of the logic contract 
    string public words; 

    // change state variable in proxy, selector: 0xc2985578
    function foo() public{
        words = "new";
    }

    // upgrade function, change logic contract's address, only admin is permitted to call. selector: 0x0900f010
    // in UUPS, logic contract HAS TO include a upgrade function, otherwise it cannot be upgraded any more.。
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
