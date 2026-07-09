// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev ERC1155のオプションインターフェース、uri()関数でメタデータを照会
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev 第`id`種類トークンのURIを返す
     */
    function uri(uint256 id) external view returns (string memory);
}