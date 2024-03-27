// SPDX-License-Identifier: MIT
// By 0xAA
// english translation by 22X
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// We attempt to frontrun a Free mint transaction
contract FreeMint is ERC721 {
    uint256 totalSupply;

    // Constructor, initializes the name and symbol of the NFT collection
    constructor() ERC721("Free Mint NFT", "FreeMint"){}

    // Mint function
    function mint() external {
        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}