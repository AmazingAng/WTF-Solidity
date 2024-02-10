// SPDX-License-Identifier: MIT
// By 0xAA
// English translation by 22X
pragma solidity ^0.8.4;
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // Constructor: Initialize the name and symbol of the NFT collection
    constructor() ERC721("", ""){}

    // Mint function: Only mint when the block timestamp is divisible by 170
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}