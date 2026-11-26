// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../34_ERC721/IERC165.sol";

/**
 * @dev ERC1155標準のインターフェースコントラクト、EIP1155の機能を実装
 * 詳細：https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev 単一種類トークン転送イベント
     * `value`個の`id`種類のトークンが`operator`によって`from`から`to`に転送されたときに発行
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev マルチ種類トークン転送イベント
     * idsとvaluesは転送されるトークン種類と数量の配列
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev バッチ承認イベント
     * `account`がすべてのトークンを`operator`に承認したときに発行
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev `id`種類のトークンのURIが変更されたときに発行、`value`は新しいURI
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev 残高照会、`account`が所有する`id`種類のトークンの残高を返す
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev バッチ残高照会、`accounts`と`ids`配列の長さは等しくなければならない
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev バッチ承認、呼び出し元のトークンを`operator`アドレスに承認
     * {ApprovalForAll}イベントを発行
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev バッチ承認照会、承認アドレス`operator`が`account`によって承認されている場合`true`を返す
     * {setApprovalForAll}関数を参照
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev 安全転送、`amount`単位の`id`種類のトークンを`from`から`to`に転送
     * {TransferSingle}イベントを発行
     * 要件:
     * - 呼び出し元が`from`アドレスでない場合、`from`の承認が必要
     * - `from`アドレスは十分な残高を持つ必要がある
     * - 受信者がコントラクトの場合、`IERC1155Receiver`の`onERC1155Received`メソッドを実装し、対応する値を返す必要がある
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev バッチ安全転送
     * {TransferBatch}イベントを発行
     * 要件：
     * - `ids`と`amounts`の長さが等しい
     * - 受信者がコントラクトの場合、`IERC1155Receiver`の`onERC1155BatchReceived`メソッドを実装し、対応する値を返す必要がある
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}