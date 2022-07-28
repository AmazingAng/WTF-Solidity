// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract FunctionTypes{
    uint256 public number = 5;
    
    constructor() payable {}

    // function type
    // function (<parameter types>) {internal|external} [pure|view|payable] [returns (<return types>)]
    // default function
    function add() external{
        number = number + 1;
    }

    // pure: not only does the function not save any data to the blockchain, but it also doesn't read any data from the blockchain.
    function addPure(uint256 _number) external pure returns(uint256 new_number){
        new_number = _number+1;
    }
    
    // view: no data will be changed
    function addView() external view returns(uint256 new_number) {
        new_number = number + 1;
    }

    // internal: the function can only be called within the contract itself and any derived contracts
    function minus() internal {
        number = number - 1;
    }

    // external: function can be called by other contract
    function minusCall() external {
        minus();
    }

    // payable: ensure that money(eth) is being sent to the contract and out of the contract as well
    function minusPayable() external payable returns(uint256 balance) {
        minus();    
        balance = address(this).balance;
    }
}