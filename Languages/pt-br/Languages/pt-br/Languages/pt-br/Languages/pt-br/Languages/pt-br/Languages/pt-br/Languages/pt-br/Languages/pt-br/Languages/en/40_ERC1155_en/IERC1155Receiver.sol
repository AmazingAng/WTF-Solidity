// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../34_ERC721_en/IERC165.sol";

/**
 * @dev ERC1155 receiving contract, to accept the secure transfer of ERC1155, this contract needs to be implemented
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev accept ERC1155 safe transfer `safeTransferFrom`
     * Need to return 0xf23a6e61 or `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev accept ERC1155 batch safe transfer `safeBatchTransferFrom`
     * Need to return 0xbc197c81 or `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
