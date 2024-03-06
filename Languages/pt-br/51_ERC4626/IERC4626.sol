// SPDX-License-Identifier: MIT
// Autor: 0xAA da WTF Academy

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Contrato de interface para o padrão "Tesouraria Tokenizada" ERC4626
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    //////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    // Acionado ao fazer um depósito
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    // Ao fazer um saque
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    //////////////////////////////////////////////////////////////
                            元数据
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Retorna o endereço do token de ativo base do cofre (para depósito e retirada)
     * - Deve ser um endereço de contrato de token ERC20.
     * - Não pode reverter.
     */
    function asset() external view returns (address assetTokenAddress);

    //////////////////////////////////////////////////////////////
                        存款/提款逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Função de depósito: o usuário deposita ativos básicos na tesouraria na quantidade de 'assets' unidades e o contrato emite 'shares' unidades de crédito da tesouraria para o endereço do destinatário.
     *
     * - Deve emitir o evento Deposit.
     * - Se os ativos não puderem ser depositados, deve reverter, por exemplo, se o valor do depósito for muito maior que o limite.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Função de cunhagem: o usuário precisa depositar ativos na unidade de base, e então o contrato cunha a quantidade de ações do cofre para o endereço do receptor
     * - Deve emitir o evento Deposit.
     * - Se não for possível cunhar todo o valor do cofre, deve reverter, por exemplo, se a quantidade a ser cunhada for maior que o limite.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Função de saque: o endereço do proprietário destrói a quantidade de compartilhamento do cofre e, em seguida, o contrato envia a quantidade de ativos básicos para o endereço do receptor
     * - Dispara o evento Withdraw
     * - Se não for possível sacar todos os ativos básicos, ocorrerá um revert
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Função de resgate: o endereço do proprietário destrói a quantidade de ações do cofre e, em seguida, o contrato envia os ativos de base na quantidade de ativos para o endereço do receptor
     * - Dispara o evento de retirada (Withdraw)
     * - Se não for possível destruir todo o saldo do cofre, reverte a transação
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    //////////////////////////////////////////////////////////////
                            会计逻辑
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Retorna o total de tokens de ativos básicos gerenciados pelo cofre
     * - Deve incluir juros
     * - Deve incluir taxas
     * - Não deve reverter
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Retorna o limite do cofre que pode ser obtido trocando uma certa quantidade de ativos básicos
     * - Não inclui taxas
     * - Não inclui deslizamento
     * - Não pode reverter
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Retorna os ativos básicos que podem ser trocados por uma determinada quantidade de saldo do cofre.
     * - Não inclui taxas
     * - Não inclui deslizamento
     * - Não pode reverter
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Função para simular o valor do cofre que os usuários podem obter ao depositar uma certa quantidade de ativos básicos, tanto on-chain quanto off-chain, no ambiente atual da cadeia.
     * - O valor retornado deve ser próximo e não maior do que o valor do cofre obtido ao fazer o depósito na mesma transação.
     * - Não leve em consideração restrições como maxDeposit, suponha que a transação de depósito do usuário seja bem-sucedida.
     * - Leve em consideração as taxas.
     * - Não deve reverter.
     * OBS: É possível calcular o slippage usando a diferença entre o valor retornado pela função convertToAssets e o valor retornado pela função previewDeposit.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Usado para simular a quantidade de ativos básicos que os usuários on-chain e off-chain precisam depositar para simular a criação de uma quantidade de ações no cofre nesta cadeia.
     * - O valor de retorno deve ser próximo e não menor do que a quantidade de depósito necessária para criar uma certa quantidade de ações no cofre na mesma transação.
     * - Não leve em consideração restrições como maxMint, suponha que a transação de depósito do usuário seja bem-sucedida.
     * - Leve em consideração as taxas.
     * - Não pode reverter.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Função para simular a quantidade de cotas do cofre que precisam ser resgatadas para um determinado valor de ativos básicos, tanto para usuários on-chain quanto off-chain, no ambiente atual da cadeia.
     * - O valor retornado deve ser próximo e não maior do que a quantidade de cotas do cofre necessárias para resgatar um determinado valor de ativos básicos na mesma transação de resgate.
     * - Não leve em consideração restrições como maxWithdraw, suponha que a transação de resgate do usuário será bem-sucedida.
     * - Leve em consideração as taxas.
     * - Não deve reverter.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Função para simular a quantidade de ativos básicos que podem ser resgatados com base na quantidade de ações destruídas pelo usuário na cadeia e fora dela no ambiente atual da cadeia.
     * - O valor de retorno deve ser próximo e não menor do que a quantidade de ativos básicos que podem ser resgatados com base na destruição de uma certa quantidade de ações na mesma transação.
     * - Não leve em consideração restrições como maxRedeem, suponha que a transação de resgate do usuário seja bem-sucedida.
     * - Leve em consideração as taxas.
     * - Não pode reverter.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    //////////////////////////////////////////////////////////////
                     存款/提款限额逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Retorna o valor máximo de ativos básicos que um endereço de usuário pode depositar de uma só vez.
     * - Se houver um limite de depósito, o valor retornado deve ser um valor finito.
     * - O valor retornado não pode exceder 2 ** 256 - 1.
     * - Não pode reverter.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Retorna o limite máximo de tesouro que um endereço de usuário pode criar em uma única cunhagem
     * - Se houver um limite de cunhagem, o valor retornado deve ser um valor finito
     * - O valor retornado não pode exceder 2 ** 256 - 1
     * - Não pode reverter
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Retorna o valor máximo de ativos básicos que um usuário pode sacar de uma só vez em um determinado endereço
     * - O valor retornado deve ser um valor finito
     * - Não deve reverter
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Retorna o limite máximo do tesouro que um endereço de usuário pode destruir em um único resgate.
     * - O valor retornado deve ser um valor finito.
     * - Se não houver outras restrições, o valor retornado deve ser balanceOf(owner).
     * - Não pode reverter.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);
}