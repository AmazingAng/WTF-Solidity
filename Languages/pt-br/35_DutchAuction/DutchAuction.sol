// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../34_ERC721/ERC721.sol";

contract DutchAuction is Ownable, ERC721 {
    // Número total de NFTs
    // Preço inicial
    // Preço de fechamento (preço mínimo)
    // Tempo do leilão, definido como 10 minutos para facilitar os testes.
    // A cada quanto tempo o preço diminui?
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        // Cada vez que o preço diminui em um passo
    
    // Horário de início do leilão
    // metadata URI
    // Registre todos os tokenId existentes

    //Definir o horário de início do leilão: Vamos declarar o horário do bloco atual como o horário de início no construtor. O projeto também pode ajustar o horário de início através da função `setAuctionStartTime(uint32)`.
    constructor() Ownable(msg.sender) ERC721("WTF Dutch Auction", "WTF Dutch Auction") {
        auctionStartTime = block.timestamp;
    }

    /**
     * Implementação da função totalSupply em ERC721Enumerable
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * Função privada, adiciona um novo token em _allTokens
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokens.push(tokenId);
    }

    // Função de mint para leilão
    function auctionMint(uint256 quantity) external payable{
        // Criar uma variável local para reduzir os custos de gas
        require(
        _saleStartTime != 0 && block.timestamp >= _saleStartTime,
        "sale has not started yet"
        // Verificando se o horário de início do leilão foi definido e se o leilão já começou
        require(
        totalSupply() + quantity <= COLLECTION_SIZE,
        "not enough remaining reserved for auction to support desired mint amount"
        // Verificar se excede o limite de NFTs

        // Calcular o custo de produção do mint
        // Verificar se o usuário pagou ETH suficiente
        
        // Mintar NFT
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }
        // Reembolso ETH em excesso
        if (msg.value > totalCost) {
            //Atenção se há risco de reentrada aqui
        }
    }

    // Obter preço em tempo real do leilão
    function getAuctionPrice()
        public
        view
        returns (uint256)
    {
        if (block.timestamp < auctionStartTime) {
        return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
        return AUCTION_END_PRICE;
        } else {
        uint256 steps = (block.timestamp - auctionStartTime) /
            AUCTION_DROP_INTERVAL;
        return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    // função setter auctionStartTime, apenasProprietário
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    // BaseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    // Função setter de BaseURI, apenasOwner
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    // Função de saque, apenasProprietário
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
