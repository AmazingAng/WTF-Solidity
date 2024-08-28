// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

/**
 * @dev ERC20 のインターフェースコントラクト
 */
interface IERC20 {
    /**
     * @dev 放出条件： `value` 数量のトークンが (`from`)アカウントから (`to`)アカウントへ移動した時
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 放出条件： `value` 数量のトークンが  (`owner`) アカウントからもう一個のアカウント(`spender`)へ権限委任された時
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev トークンの総供給量を返却
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev `account`所持のトークン数量を返却
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev  `amount` の数量のトークンをトランザクションのcallerから`to`アカウントへ転送
     *
     * もし成功した場合、`true`を返却
     *
     * ｛Transfer｝イベントを放出
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev `owner`アカウントが`spender`アカウントに委任した権限数量を返却
     *
     * {approve} または {transferFrom} が呼ばれると，`allowance`が変化する
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev callerが`spender`に`amount`数量のトークンを委任する
     *
     * もし成功した場合、`true`を返却
     *
     * {Approval} イベントを放出
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev アプルーブのメカニズムを通じて、`from`アカウントから`to`アカウントへ`amount`数量のトークンを転送する。転送された部分は呼び出し者の`allowance`から差し引かれる。
     *
     * もし成功した場合、`true`を返却
     *
     * {Transfer} イベントを放出
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
