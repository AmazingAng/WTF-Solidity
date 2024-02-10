// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Owner {
   address public owner; // define owner variable

   // constructor
   constructor() {
      owner = msg.sender; // set owner to the address of deployer when contract is being deployed
   }

   // define modifier
   modifier onlyOwner {
      require(msg.sender == owner); // check whether caller is address of owner
      _; // if true，continue to run the body of function；otherwise throw an error and revert transaction
   }

   // define a function with onlyOwner modifier
   function changeOwner(address _newOwner) external onlyOwner{
      owner = _newOwner; // only owner address can run this function and change owner
   }
}