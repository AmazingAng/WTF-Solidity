// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface extension for ERC20 Permit, allowing approvals to be made via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change the allowance of an account's ERC20 balance by a signed message. This allows token holders to approve without the need to send a transaction, and therefore without the need to hold Ether.
 */
interface IERC20Permit {
    /**
     * @dev Autoriza o saldo de ERC20 do `owner` para o `spender`, com quantidade `value`, com base na assinatura do `owner`.
     *
     * Emite o evento {Approval}.
     *
     * Requisitos:
     *
     * - O `spender` não pode ser um endereço zero.
     * - O `deadline` deve ser um timestamp futuro.
     * - O `v`, `r` e `s` devem ser uma assinatura `secp256k1` válida do `owner` nos parâmetros da função no formato EIP712.
     * - A assinatura deve usar o nonce atual do `owner` (consulte {nonces}).
     *
     * Para mais informações sobre o formato de assinatura, consulte
     * https://eips.ethereum.org/EIPS/eip-2612#specification.
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
     * @dev Retorna o nonce atual do `owner`. Este valor deve ser incluído sempre que gerar uma assinatura para {permit}.
     *
     * Cada chamada bem-sucedida para {permit} aumentará o nonce do `owner` em 1. Isso evita o uso de assinaturas múltiplas.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Retorna o separador de domínio (domain separator) usado para codificar a assinatura do {permit}, conforme definido pelo {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}