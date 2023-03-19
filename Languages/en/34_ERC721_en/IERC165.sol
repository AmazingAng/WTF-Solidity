// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev The standard interface of ERC165, see
 * https://eips.ethereum.org/EIPS/eip-165[EIP] for more details.
 *
 * Smart contracts can declare the interfaces they support, for other contracts to check.
 *
 */
interface IERC165 {
    /**
     * @dev Returns true if contract implements the `interfaceId` for querying.
     * See https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section] for the definition of what an interface is.
     *
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}