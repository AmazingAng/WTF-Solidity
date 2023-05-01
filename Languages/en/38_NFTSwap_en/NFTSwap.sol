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

    // define the order structure
    struct Order {
        address owner;
        uint256 price;
    }
    // NFT Order mapping
    mapping(address => mapping(uint256 => Order)) public nftList;

    fallback() external payable {}

    // Pending order: The seller puts NFT on the shelf, the contract address is _nftAddr, the tokenId is _tokenId, and the price _price is Ethereum (the unit is wei)
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr); // Declare IERC721 interface contract variables
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval"); // The contract is authorized
        require(_price > 0); // price is greater than 0

        Order storage _order = nftList[_nftAddr][_tokenId]; //Set NF holder and price
        _order.owner = msg.sender;
        _order.price = _price;
        // Transfer NFT to contract
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Release the List event
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    // Purchase: The buyer purchases NFT, the contract is _nftAddr, the tokenId is _tokenId, and ETH is required when calling the function
    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        Order storage _order = nftList[_nftAddr][_tokenId]; // get Order
        require(_order.price > 0, "Invalid Price"); // NFT price is greater than 0
        require(msg.value >= _order.price, "Increase price"); // The purchase price is greater than the list price
        // Declare IERC721 interface contract variables
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT is in the contract

        // Transfer NFT to buyer
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // Transfer ETH to the seller, and refund the excess ETH to the buyer
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value - _order.price);

        delete nftList[_nftAddr][_tokenId]; // delete order

        // Release the Purchase event
        emit Purchase(msg.sender, _nftAddr, _tokenId, msg.value);
    }

    // Cancellation: The seller cancels the pending order
    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // get Order
        require(_order.owner == msg.sender, "Not Owner"); // must be initiated by the owner
        // Declare IERC721 interface contract variables
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT is in the contract

        // Transfer NFT to seller
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; // delete order

        // Release the Revoke event
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    // Adjust price: The seller adjusts the pending order price
    function update(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _newPrice
    ) public {
        require(_newPrice > 0, "Invalid Price"); // NFT price is greater than 0
        Order storage _order = nftList[_nftAddr][_tokenId]; // get Order
        require(_order.owner == msg.sender, "Not Owner"); // must be initiated by the owner
        // Declare IERC721 interface contract variables
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT is in the contract

        // Adjust NFT price
        _order.price = _newPrice;

        // Release the Update event
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    // Implement onERC721Received of {IERC721Receiver}, able to receive ERC721 tokens
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
