// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.21;
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // Construtor, inicializa o nome e o código da coleção NFT
    constructor() ERC721("", ""){}

    // Função de fundição: só é possível criar uma nova unidade quando o tempo do bloco é divisível por 7.
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}