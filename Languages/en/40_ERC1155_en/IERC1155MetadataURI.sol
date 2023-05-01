// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * Optional interface of @dev ERC1155, added uri() function to query metadata
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI of the `id` type token
     */
    function uri(uint256 id) external view returns (string memory);
}
