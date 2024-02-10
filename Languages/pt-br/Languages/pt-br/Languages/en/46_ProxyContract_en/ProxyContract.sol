// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.4;

/**
 * @dev all invocations through Proxy contract are delegated to another contract, which is called logic contract(Implementation), by `delegatecall` opcode. 
 *
 * the return value of delegation call is directly returned to the caller of proxy
 */
contract Proxy {
    // Address of the logic contract. The data type of the implementation contract has to be the same as that of the Proxy contract at the same position or an error will occur.
    address public implementation; 

    /**
     * @dev Initializes the address of the logic contract.
     */
    constructor(address implementation_) {
        implementation = implementation_;
    }

    /**
     * @dev fallback function, delegates invocations of current contract to `implementation` contract
     * with inline assembly, it gives fallback function a return value
     */
    fallback() external payable {
        address _implementation = implementation;
        assembly {
            // copy msg.data to memory
            // the parameters of opcode calldatacopy: start position of memory, start position of calldata, length of calldata
            calldatacopy(0, 0, calldatasize())

            // use delegatecall to call implementation contract
            // the parameters of opcode delegatecall: gas, target contract address, start position of input memory, length of input memory, start position of output memory, length of output memory
            // set start position of output memory and length of output memory to 0
            // delegatecall returns 1 if success, 0 if fail
            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // copy returndata to memory
            // the parameters of opcode returndata: start position of memory, start position of returndata, length of retundata
            returndatacopy(0, 0, returndatasize())

            switch result
            // if delegate call fails, then revert
            case 0 {
                revert(0, returndatasize())
            }
            // if delegate call succeeds, then return memory data(as bytes format) starting from 0 with length of returndatasize()
            default {
                return(0, returndatasize())
            }
        }
    }
}

/**
 * @dev Logic contract, executes delegated calls
 */
contract Logic {
    address public implementation; // Keep consistency with the Proxy to prevent slot collision
    uint public x = 99;
    event CallSuccess(); // Event emitted on successful function call

    // This function emits CallSuccess event and returns a uint
    // Function selector: 0xd09de08a
    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
    }
}

/**
 * @dev Caller contract, call the proxy contract and get the result of execution
 */
contract Caller{
    address public proxy; // proxy contract address

    constructor(address proxy_){
        proxy = proxy_;
    }

    // Call the increment() function using the proxy contract
    function increment() external returns(uint) {
        ( , bytes memory data) = proxy.call(abi.encodeWithSignature("increment()"));
        return abi.decode(data,(uint));
    }
}
