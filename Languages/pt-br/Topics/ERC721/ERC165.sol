// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementação da interface {IERC165}.
 *
 * Contratos que desejam implementar o ERC165 devem herdar deste contrato e substituir {supportsInterface} para verificar
 * o ID de interface adicional que será suportado. Por exemplo:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternativamente, {ERC165Storage} fornece uma implementação mais fácil de usar, mas mais cara.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev Veja {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
