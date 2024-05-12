// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title Padrão de Token Não-Fungível ERC-721, extensão opcional de metadados
 * @dev Veja https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Retorna o nome da coleção de tokens.
     */
    function name() external view returns (string memory);

    /**
     * @dev Retorna o símbolo da coleção de tokens.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Retorna o Identificador de Recurso Uniforme (URI) para o token `tokenId`.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
