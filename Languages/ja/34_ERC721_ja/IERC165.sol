// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ERC165標準インターフェース, 詳細は
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * コントラクトはサポートするインターフェースを宣言し、他のコントラクトが確認できます
 *
 */
interface IERC165 {
    /**
     * @dev コントラクトがクエリされた`interfaceId`を実装している場合はtrueを返します
     * ルールの詳細：https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     *
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}