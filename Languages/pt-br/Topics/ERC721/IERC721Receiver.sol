// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title Interface do receptor de tokens ERC721
 * @dev Interface para qualquer contrato que deseje suportar transferências seguras
 * de contratos de ativos ERC721.
 */
interface IERC721Receiver {
    /**
     * @dev Sempre que um token {IERC721} `tokenId` for transferido para este contrato via {IERC721-safeTransferFrom}
     * por `operador` de `de`, esta função é chamada.
     *
     * Ela deve retornar o seletor Solidity para confirmar a transferência do token.
     * Se qualquer outro valor for retornado ou a interface não for implementada pelo destinatário, a transferência será revertida.
     *
     * O seletor pode ser obtido em Solidity com `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
