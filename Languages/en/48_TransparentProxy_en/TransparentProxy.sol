// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.4;

// selector clash example
// uncomment the two lines of code, the contract fails to compile, because the selector of these two functions are identical
contract Foo {
    bytes4 public selector1 = bytes4(keccak256("burn(uint256)"));
    bytes4 public selector2 = bytes4(keccak256("collate_propagate_storage(bytes16)"));
    // function burn(uint256) external {}
    // function collate_propagate_storage(bytes16) external {}
}


// FOR TEACHING PURPOSE ONLY, DO NOT UES IN PRODUCTION
contract TransparentProxy {
    // logic contract's address
    address implementation; 
    // admin address
    address admin; 
    // string variable, can be modified by calling loginc contract's function
    string public words;

    // constructor, initializing the admin address and logic contract's address
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback function, delegates function call to logic contract
    // can not be called by admin, to avoid causing unexpected beahvior due to selector clash
    fallback() external payable {
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // upgrade function, change logic contract's address, can only be called by admin
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
}

// old logic contract
contract Logic1 {
    // state variable should be the same as proxy contract, in case of slot clash
    address public implementation; 
    address public admin; 
    // string variable, can be modified by calling loginc contract's function
    string public words; 

    // to change state variable in proxy contract, selector 0xc2985578
    function foo() public{
        words = "old";
    }
}

// new logic contract
contract Logic2 {
    // state variable should be the same as proxy contract, in case of slot clash
    address public implementation; 
    address public admin; 
    // string variable, can be modified by calling loginc contract's function
    string public words;

    // to change state variable in proxy contract, selector 0xc2985578
    function foo() public{
        words = "new";
    }
}