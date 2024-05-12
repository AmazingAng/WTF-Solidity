// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../34_ERC721/IERC165.sol";

/**
 * @dev Contrato de interface padrão ERC1155, que implementa as funcionalidades do EIP1155
 * Veja mais em: https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Evento de transferência de token de uma única classe
     * É acionado quando `operator` transfere `value` tokens da classe `id` de `from` para `to`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Evento de transferência de tokens de várias classes
     * ids e values são arrays de tipos e quantidades de tokens transferidos
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Evento de autorização em lote
     * Disparado quando `account` concede autorização de todos os tokens para `operator`
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Quando o URI do token da categoria `id` é alterado, libera, `value` é o novo URI
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Consulta de posição, retorna a quantidade de tokens detidos por `account` do tipo `id`
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Consulta de posição em lote, o comprimento dos arrays `accounts` e `ids` deve ser igual.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Autorização em lote, concede ao chamador a permissão de transferir tokens para o endereço do `operador`.
     * Emite o evento {ApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Consulta de autorização em lote, retorna `true` se o endereço de autorização `operator` estiver autorizado por `account`
     * Veja a função {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transferência segura, transfere `amount` unidades do token de tipo `id` de `from` para `to`.
     * Emite o evento {TransferSingle}.
     * Requisitos:
     * - Se o chamador não for o endereço `from`, mas sim um endereço autorizado, é necessário obter autorização de `from`.
     * - O endereço `from` deve ter saldo suficiente.
     * - Se o destinatário for um contrato, ele deve implementar o método `onERC1155Received` do `IERC1155Receiver` e retornar o valor correspondente.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Transferência segura em lote
     * Dispara o evento {TransferBatch}
     * Requisitos:
     * - Os arrays `ids` e `amounts` devem ter o mesmo tamanho
     * - Se o destinatário for um contrato, ele deve implementar o método `onERC1155BatchReceived` da interface `IERC1155Receiver` e retornar o valor correspondente
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
