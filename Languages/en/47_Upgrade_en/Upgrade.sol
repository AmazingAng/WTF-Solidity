// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// simple upgradeable contract, the admin could change the logic contract's address by calling upgrade function, thus change the contract logic
// FOR TEACHING PURPOSE ONLY, DO NOT USE IN PRODUCTION
contract SimpleUpgrade {
    // logic contract's address
    address public implementation; 

    // admin address
    address public admin;

    // string variable, could be changed by logic contract's function
    string public words; 

    // constructor, initializing admin address and logic contract's address
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback function, delegates function call to logic contract
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // upgrade function, changes the logic contract's address, can only by called by admin
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// first logic contract
contract Logic1 {
    // State variables consistent with Proxy contract to prevent slot conflicts
    address public implementation; 
    address public admin;
    // String that can be changed through the function of the logic contract  
    string public words; 

    // Change state variables in Proxy contract, selector: 0xc2985578
    function foo() public {
        words = "old";
    }
}

// second logic contract
contract Logic2 {
    // State variables consistent with proxy contract to prevent slot collisions
    address public implementation; 
    address public admin;
    // String that can be changed through the function of the logic contract  
    string public words; 

    // Change state variables in Proxy contract, selector: 0xc2985578
    function foo() public{
        words = "new";
    }
}