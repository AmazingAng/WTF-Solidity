// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../../../34_ERC721/IERC721.sol";
import "../../../34_ERC721/IERC721Receiver.sol";
import "../../../34_ERC721/WTFApe.sol";

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

    struct Order {
        address owner;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Order)) public nftList;

    fallback() external payable {}

    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        require(_price > 0, "Price must be greater than 0");

        IERC721 _nft = IERC721(_nftAddr);
        require(
            _nft.ownerOf(_tokenId) == msg.sender,
            "Only the owner can list the NFT"
        );
        require(
            _nft.getApproved(_tokenId) == address(this),
            "Contract is not approved to transfer this NFT"
        );

        nftList[_nftAddr][_tokenId] = Order(msg.sender, _price);
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        Order memory order = nftList[_nftAddr][_tokenId];
        require(order.price > 0, "NFT is not listed for sale");
        require(msg.value >= order.price, "Insufficient ETH to purchase NFT");

        IERC721 _nft = IERC721(_nftAddr);
        require(
            _nft.ownerOf(_tokenId) == address(this),
            "NFT is not in the contract"
        );

        delete nftList[_nftAddr][_tokenId];

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        payable(order.owner).transfer(order.price);

        if (msg.value > order.price) {
            payable(msg.sender).transfer(msg.value - order.price);
        }

        emit Purchase(msg.sender, _nftAddr, _tokenId, order.price);
    }

    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order memory order = nftList[_nftAddr][_tokenId];
        require(order.owner == msg.sender, "You are not the owner of this NFT");

        IERC721 _nft = IERC721(_nftAddr);
        require(
            _nft.ownerOf(_tokenId) == address(this),
            "NFT is not in the contract"
        );

        delete nftList[_nftAddr][_tokenId];

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    function update(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _newPrice
    ) public {
        require(_newPrice > 0, "Price must be greater than 0");

        Order storage order = nftList[_nftAddr][_tokenId];
        require(order.owner == msg.sender, "You are not the owner of this NFT");

        order.price = _newPrice;

        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
