// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Fornece informações sobre o contexto de execução atual, incluindo o
 * remetente da transação e seus dados. Embora essas informações estejam geralmente disponíveis
 * através de msg.sender e msg.data, elas não devem ser acessadas de forma direta
 * pois, ao lidar com meta-transações, a conta que envia e
 * paga pela execução pode não ser o remetente real (do ponto de vista de um aplicativo).
 *
 * Este contrato é necessário apenas para contratos intermediários semelhantes a bibliotecas.
 */
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
