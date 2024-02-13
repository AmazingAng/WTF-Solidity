// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface do receptor ERC721: o contrato deve implementar esta interface para receber transferências seguras de ERC721
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}