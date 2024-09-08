// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

/**
 * @dev ERC20 インターフェース契約.
 */
interface IERC20 {
    /**
     * @dev 発行条件：`value` 単位の通貨がアカウント (`from`) から別のアカウント (`to`) に転送されたとき.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 発行条件：`value` 単位の通貨がアカウント (`owner`) から別のアカウント (`spender`) に承認されたとき.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev トークンの総供給量を返す.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev アカウント`account`が保有するトークン数を返す.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 呼び出し元のアカウントから別のアカウント `to` に `amount` 単位のトークンを転送する.
     *
     * 成功した場合は `true` を返す.
     *
     * {Transfer} イベントを発行する.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev `owner`アカウントが`spender`アカウントに承認した額を返す。デフォルトは0.
     *
     * {approve} または {transferFrom} が呼び出されると、`allowance`は変更される.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev 呼び出し元のアカウントが`spender`アカウントに `amount` 数量のトークンを承認する.
     *
     * 成功した場合は `true` を返す.
     *
     * {Approval} イベントを発行する.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev 承認メカニズムを通じて、`from`アカウントから`to`アカウントに`amount`数量のトークンを転送する。転送された部分は呼び出し元の`allowance`から差し引かれる.
     *
     * 成功した場合は `true` を返す.
     *
     * {Transfer} イベントを発行する.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
