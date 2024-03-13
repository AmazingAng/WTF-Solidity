// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

/**
 * @dev ERC20 interface contract.
 */
interface IERC20 {
    /**
     * @dev Triggered when `value` tokens are transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Triggered whenever `value` tokens are approved by `owner` to be spent by `spender`.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the total amount of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Transfers `amount` tokens from the caller's account to the recipient `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded or not.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount authorized by the `owner` account to the `spender` account, default is 0.
     *
     * When {approve} or {transferFrom} is invoked，`allowance` will be changed.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Allows `spender` to spend `amount` tokens from caller's account.
     *
     * Returns a boolean value indicating whether the operation succeeded or not.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Transfer `amount` of tokens from `from` account to `to` account, subject to the caller's allowance.
     * The caller must have allowance for `from` account balance.
     *
     * Returns `true` if the operation is successful.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}