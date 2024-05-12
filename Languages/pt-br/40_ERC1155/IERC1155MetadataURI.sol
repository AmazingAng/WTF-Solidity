// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface opcional para ERC1155, que adiciona a função uri() para consultar metadados.
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Retorna o URI do token da categoria `id`
     */
    function uri(uint256 id) external view returns (string memory);
}