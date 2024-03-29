// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Nós estamos tentando frontrun uma transação de mint grátis.
contract FreeMint is ERC721 {
    uint256 totalSupply;

    // Construtor, inicializa o nome e o código da coleção NFT
    constructor() ERC721("Free Mint NFT", "FreeMint"){}

    // Função de construção
    function mint() external {
        // mint
        totalSupply++;
    }
}