// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC721受信者インターフェース：コントラクトはこのインターフェースを実装して安全転送でERC721を受信する必要があります
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}