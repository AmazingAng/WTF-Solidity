// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC20 Permit extended interface that allows approval via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
* Added {permit} method to change an account's ERC20 balance via a message signed by the account (see {IERC20-allowance}). By not relying on {IERC20-approve}, token holders' accounts do not need to send transactions and therefore do not need to hold Ether at all.
  */
interface IERC20Permit {
     /**
      * @dev Authorizes `owenr`’s ERC20 balance to `spender` based on the owner’s signature, the amount is `value`
      *
      * Release the {Approval} event.
      *
      * Require:
      *
      * - `spender` cannot be a zero address.
      * - `deadline` must be a timestamp in the future.
      * - `v`, `r` and `s` must be valid `secp256k1` signatures of the `owner` on function arguments in EIP712 format.
      * - The signature must use the `owner`'s current nonce (see {nonces}).
      *
      *For more information on signature format, see:
     * https://eips.ethereum.org/EIPS/eip-2612#specification。
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
    * @dev Returns the current nonce of `owner`. This value must be included every time you generate a signature for {permit}.
      *
      * Each successful call to {permit} will increase the `owner`'s nonce by 1. This prevents the signature from being used multiple times.
      */
     function nonces(address owner) external view returns (uint256);

     /**
      * @dev Returns the domain separator used to encode the signature of {permit}, as defined by {EIP712}.
      */
     // solhint-disable-next-line func-name-mixedcase
     function DOMAIN_SEPARATOR() external view returns (bytes32);
}
