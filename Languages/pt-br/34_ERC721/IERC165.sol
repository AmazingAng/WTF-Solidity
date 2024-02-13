// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface padrão ERC165, consulte
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Contratos podem declarar interfaces suportadas para que outros contratos possam verificar.
 *
 */
interface IERC165 {
    /**
     * @dev Se o contrato implementar o `interfaceId` de consulta, retorna verdadeiro
     * Regras detalhadas em: https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[Seção EIP]
     *
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}