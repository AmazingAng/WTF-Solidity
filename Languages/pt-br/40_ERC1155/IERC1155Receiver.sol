// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../34_ERC721/IERC165.sol";

/**
 * @dev Contrato receptor de ERC1155. Para receber transferências seguras de ERC1155, é necessário implementar este contrato.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Aceita transferência segura de ERC1155 `safeTransferFrom`
     * Deve retornar 0xf23a6e61 ou `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Aceita transferências seguras em lote de ERC1155 `safeBatchTransferFrom`
     * Precisa retornar 0xbc197c81 ou `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
