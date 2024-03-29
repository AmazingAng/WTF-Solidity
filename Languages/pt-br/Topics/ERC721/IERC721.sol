// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface necessária de um contrato compatível com ERC721.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitido quando o token `tokenId` é transferido de `from` para `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitido quando `owner` permite que `approved` gerencie o token `tokenId`.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitido quando `owner` habilita ou desabilita (`approved`) `operator` para gerenciar todos os seus ativos.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Retorna o número de tokens na conta do ``owner``.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Retorna o proprietário do token `tokenId`.
     *
     * Requisitos:
     *
     * - `tokenId` deve existir.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfere com segurança o token `tokenId` de `from` para `to`, verificando primeiro se os destinatários do contrato
     * estão cientes do protocolo ERC721 para evitar que os tokens fiquem bloqueados para sempre.
     *
     * Requisitos:
     *
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve existir e ser de propriedade de `from`.
     * - Se o chamador não for `from`, ele deve ter sido autorizado a mover este token por meio de {approve} ou {setApprovalForAll}.
     * - Se `to` se referir a um contrato inteligente, ele deve implementar {IERC721Receiver-onERC721Received}, que é chamado durante uma transferência segura.
     *
     * Emite um evento {Transfer}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfere o token `tokenId` de `from` para `to`.
     *
     * AVISO: O uso deste método é desencorajado, use {safeTransferFrom} sempre que possível.
     *
     * Requisitos:
     *
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve ser de propriedade de `from`.
     * - Se o chamador não for `from`, ele deve ser aprovado para mover este token por meio de {approve} ou {setApprovalForAll}.
     *
     * Emite um evento {Transfer}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Concede permissão para `to` transferir o token `tokenId` para outra conta.
     * A aprovação é removida quando o token é transferido.
     *
     * Apenas uma única conta pode ser aprovada por vez, portanto, aprovar o endereço zero remove aprovações anteriores.
     *
     * Requisitos:
     *
     * - O chamador deve ser o proprietário do token ou um operador aprovado.
     * - `tokenId` deve existir.
     *
     * Emite um evento {Approval}.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Retorna a conta aprovada para o token `tokenId`.
     *
     * Requisitos:
     *
     * - `tokenId` deve existir.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Aprova ou remove `operador` como um operador para o chamador.
     * Operadores podem chamar {transferFrom} ou {safeTransferFrom} para qualquer token de propriedade do chamador.
     *
     * Requisitos:
     *
     * - O `operador` não pode ser o chamador.
     *
     * Emite um evento {ApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Retorna se o `operador` está autorizado a gerenciar todos os ativos do `proprietário`.
     *
     * Veja {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Transfere com segurança o token `tokenId` de `from` para `to`.
     *
     * Requisitos:
     *
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve existir e ser de propriedade de `from`.
     * - Se o chamador não for `from`, ele deve ser aprovado para mover este token por meio de {approve} ou {setApprovalForAll}.
     * - Se `to` se referir a um contrato inteligente, ele deve implementar {IERC721Receiver-onERC721Received}, que é chamado durante uma transferência segura.
     *
     * Emite um evento {Transfer}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
