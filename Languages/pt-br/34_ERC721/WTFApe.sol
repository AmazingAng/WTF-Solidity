// SPDX-License-Identifier: MIT
// por 0xAA
pragma solidity ^0.8.4;

import "./ERC721.sol";

contract WTFApe is ERC721{
    // Total

    // Construtor
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){
    }

    //O baseURI do BAYC é ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns (string memory) {
        //QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    }
    
    // Função de construção
    function mint(address to, uint tokenId) external {
        require(tokenId >= 0 && tokenId < MAX_APES, "tokenId out of range");
        _mint(to, tokenId);
    }
}