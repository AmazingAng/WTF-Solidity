// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract Owner {
   address public owner;

   constructor() {
      owner = msg.sender;
   }

   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   function changeOwner(address _newOwner) external onlyOwner {
      owner = _newOwner;
   }
}
