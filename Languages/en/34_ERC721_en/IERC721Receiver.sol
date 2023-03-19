// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC721 receiver interface: Contracts must implement this interface to receive ERC721 tokens via safe transfers.
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}