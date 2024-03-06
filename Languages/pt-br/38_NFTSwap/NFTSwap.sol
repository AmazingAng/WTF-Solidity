// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../34_ERC721/IERC721.sol";
import "../34_ERC721/IERC721Receiver.sol";
import "../34_ERC721/WTFApe.sol";

contract NFTSwap is IERC721Receiver {
    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Purchase(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Revoke(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );
    event Update(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    // Definindo a estrutura 'order'
    struct Order {
        address owner;
        uint256 price;
    }
    // Mapeamento de Pedido NFT
    mapping(address => mapping(uint256 => Order)) public nftList;

    fallback() external payable {}

    // Venda pendente: O vendedor listou um NFT, com o endereço do contrato _nftAddr, tokenId _tokenId e preço _price em Ethereum (unidade wei).
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        // Declaring variable for IERC721 interface contract
        // Contrato autorizado
        // Preço maior que 0

        //Definir o detentor e o preço do NF
        _order.owner = msg.sender;
        _order.price = _price;
        // Transferir NFT para um contrato.
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Liberar evento de List
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    // Compra: O comprador adquire um NFT, com contrato _nftAddr e tokenId _tokenId, ao chamar a função, é necessário fornecer ETH.
    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        // Obter Pedido
        // O preço do NFT é maior que 0
        // O preço de compra é maior do que o preço de etiqueta
        // Declaring variable for IERC721 interface contract
        IERC721 _nft = IERC721(_nftAddr);
        // NFT está presente no contrato.

        // Transferir o NFT para o comprador
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // Transferir ETH para o vendedor e reembolsar o comprador com o ETH excedente
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value - _order.price);

        // Remover pedido

        // Liberar evento de compra
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);
    }

    // Cancelar pedido: O vendedor cancela a ordem.
    function revoke(address _nftAddr, uint256 _tokenId) public {
        // Obter Pedido
        // Deve ser iniciado pelo titular
        // Declaring variable for IERC721 interface contract
        IERC721 _nft = IERC721(_nftAddr);
        // NFT está presente no contrato.

        // Transferir o NFT para o vendedor.
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // Remover pedido

        // Liberar o evento Revoke
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    // Ajuste de preço: o vendedor ajusta o preço do pedido pendente
    function update(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _newPrice
    ) public {
        // O preço do NFT é maior que 0
        // Obter Pedido
        // Deve ser iniciado pelo titular
        // Declaring variable for IERC721 interface contract
        IERC721 _nft = IERC721(_nftAddr);
        // NFT está presente no contrato.

        // Ajustar o preço do NFT
        _order.price = _newPrice;

        // Liberar evento de atualização
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    // Implemente o onERC721Received do {IERC721Receiver} para receber tokens ERC721
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
