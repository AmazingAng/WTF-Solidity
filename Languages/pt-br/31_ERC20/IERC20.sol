// SPDX-License-Identifier: MIT
// WTF Solidity por 0xAA

pragma solidity ^0.8.21;

/**
 * @dev Contrato de interface ERC20.
 */
interface IERC20 {
    /**
     * @dev Condição de liberação: quando a moeda em unidades `value` é transferida de uma conta (`from`) para outra conta (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Condição de liberação: quando a moeda em unidades `value` é transferida da conta (`owner`) para outra conta (`spender`).
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Retorna o fornecimento total de tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Retorna a quantidade de tokens que a conta `account` possui.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Transferir `amount` unidades de token da conta do chamador para a conta `to`.
     *
     * Se for bem-sucedido, retorna `true`.
     *
     * Emite o evento {Transfer}.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Retorna a quantidade de tokens que o titular da conta `owner` autorizou o titular da conta `spender` a gastar, que por padrão é 0.
     *
     * A permissão de gasto é alterada quando {approve} ou {transferFrom} são chamados.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev O chamador da conta autoriza a conta `spender` a gastar `amount` tokens.
     *
     * Retorna `true` se for bem sucedido.
     *
     * Emite o evento {Approval}.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Transfere `amount` de tokens da conta `from` para a conta `to`, utilizando o mecanismo de autorização. A quantidade transferida será deduzida da permissão do chamador.
     *
     * Retorna `true` se a transferência for bem-sucedida.
     *
     * Emite o evento {Transfer}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}