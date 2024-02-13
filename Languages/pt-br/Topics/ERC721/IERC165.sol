// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface do padrão ERC165, conforme definido no
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementadores podem declarar suporte a interfaces de contratos, que podem então ser
 * consultadas por outros ({ERC165Checker}).
 *
 * Para uma implementação, veja {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Retorna verdadeiro se este contrato implementa a interface definida por
     * `interfaceId`. Consulte a seção correspondente
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP]
     * para saber mais sobre como esses ids são criados.
     *
     * Esta chamada de função deve usar menos de 30.000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
