// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../34_ERC721_en/IERC165.sol";

/**
 * @dev ERC1155 standard interface contract, realizes the function of EIP1155
 * See: https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev single-type token transfer event
     * Released when `value` tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev multi-type token transfer event
     * ids and values are arrays of token types and quantities transferred
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev volume authorization event
     * Released when `account` authorizes all tokens to `operator`
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Released when the URI of the token of type `id` changes, `value` is the new URI
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Position query, returns the position of the token of `id` type owned by `account`
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev Batch position query, the length of `accounts` and `ids` arrays have to wait.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Batch authorization, authorize the caller's tokens to the `operator` address.
     * Release the {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Batch authorization query, if the authorization address `operator` is authorized by `account`, return `true`
     * See {setApprovalForAll} function.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @dev Secure transfer, transfer `amount` unit `id` type token from `from` to `to`.
     * Release {TransferSingle} event.
     * Require:
     * - If the caller is not a `from` address but an authorized address, it needs to be authorized by `from`
     * - `from` address must have enough open positions
     * - If the receiver is a contract, it needs to implement the `onERC1155Received` method of `IERC1155Receiver` and return the corresponding value
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Batch security transfer
     * Release {TransferBatch} event
     * Require:
     * - `ids` and `amounts` are of equal length
     * - If the receiver is a contract, it needs to implement the `onERC1155BatchReceived` method of `IERC1155Receiver` and return the corresponding value
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
