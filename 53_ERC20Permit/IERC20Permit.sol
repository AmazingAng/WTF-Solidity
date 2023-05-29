// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC20 Permit 扩展的接口，允许通过签名进行批准，如 https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]中定义。
 *
 * 添加了 {permit} 方法，可以通过帐户签名的消息更改帐户的 ERC20 余额（参见 {IERC20-allowance}）。通过不依赖 {IERC20-approve}，代币持有者的帐户无需发送交易，因此完全不需要持有 Ether。
 */
interface IERC20Permit {
    /**
     * @dev 根据owner的签名, 将 `owenr` 的ERC20余额授权给 `spender`，数量为 `value`
     *
     * 释放 {Approval} 事件。
     *
     * 要求：
     *
     * - `spender` 不能是零地址。
     * - `deadline` 必须是未来的时间戳。
     * - `v`，`r` 和 `s` 必须是 `owner` 对 EIP712 格式的函数参数的有效 `secp256k1` 签名。
     * - 签名必须使用 `owner` 当前的 nonce（参见 {nonces}）。
     *
     * 有关签名格式的更多信息，请参阅
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
     * @dev 返回 `owner` 的当前 nonce。每次为 {permit} 生成签名时，都必须包括此值。
     *
     * 每次成功调用 {permit} 都会将 `owner` 的 nonce 增加 1。这防止多次使用签名。
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev 返回用于编码 {permit} 的签名的域分隔符（domain seperator），如 {EIP712} 所定义。
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}