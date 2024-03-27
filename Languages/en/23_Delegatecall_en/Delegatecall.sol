// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// delegatecall is similar to call, is a low level function
// call: B call C, the execution context is C (msg.sender = B, the state variables of C are affected)
// delegatecall: B delegatecall C, the execution context is B (msg.sender = A, the state variables of B are affeted)
// be noted the data storage layout of B and C must be the same! Variable type, the order needs to remain same, otherwise the contract will be screwed up.

// target contract C
contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}

// contract B which uses both call and delegatecall to call contract C
contract B {
    uint public num;
    address public sender;

    // call setVars() of C with call, the state variables of contract C will be changed
    function callSetVars(address _addr, uint _num) external payable{
        // call setVars()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
    // call setVars() with delegatecall, the state variables of contract B will be changed
    function delegatecallSetVars(address _addr, uint _num) external payable{
        // delegatecall setVars()
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
