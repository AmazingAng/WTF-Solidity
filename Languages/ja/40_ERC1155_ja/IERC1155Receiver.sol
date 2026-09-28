// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../34_ERC721/IERC165.sol";

/**
 * @dev ERC1155受信コントラクト、ERC1155の安全転送を受け入れるためにはこのコントラクトを実装する必要がある
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev ERC1155安全転送`safeTransferFrom`を受け入れる
     * 0xf23a6e61 または `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`を返す必要がある
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev ERC1155バッチ安全転送`safeBatchTransferFrom`を受け入れる
     * 0xbc197c81 または `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`を返す必要がある
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}