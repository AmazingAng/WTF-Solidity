// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.0;

import "../31_ERC20/ERC20.sol";

/**
 * @title Liberação linear de tokens ERC20
 * @dev Este contrato libera tokens ERC20 de forma linear para o beneficiário `_beneficiary`.
 * Os tokens liberados podem ser de um único tipo ou de vários tipos. O período de liberação é definido pelo tempo inicial `_start` e pela duração `_duration`.
 * Todos os tokens transferidos para este contrato seguirão o mesmo período de liberação linear e o beneficiário precisará chamar a função `release()` para resgatá-los.
 * O contrato é uma simplificação da VestingWallet da OpenZeppelin.
 */
contract TokenVesting {
    // Eventos
    // Evento de retirada de moedas

    // Variável de estado
    // Mapeamento do endereço do token para a quantidade liberada, registrando a quantidade de tokens que o beneficiário já recebeu
    // Endereço do beneficiário
    // Data de início do período de pertencimento
    // Período de Atribuição (em segundos)

    /**
     * @dev Inicializa o endereço do beneficiário, o período de liberação (em segundos) e o carimbo de data/hora de início (carimbo de data/hora atual da blockchain)
     */
    constructor(
        address beneficiaryAddress,
        uint256 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    /**
     * @dev Beneficiário retira tokens liberados.
     * Chama a função vestedAmount() para calcular a quantidade de tokens que podem ser retirados e, em seguida, transfere para o beneficiário.
     * Emite o evento {ERC20Released}.
     */
    function release(address token) public {
        // Chame a função vestedAmount() para calcular a quantidade de tokens que podem ser retirados
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        // Atualizando a quantidade de tokens liberados
        erc20Released[token] += releasable; 
        // Transferir tokens para o beneficiário
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    /**
     * @dev De acordo com a fórmula de liberação linear, calcula a quantidade já liberada. Os desenvolvedores podem personalizar o método de liberação modificando esta função.
     * @param token: endereço do token
     * @param timestamp: timestamp consultado
     */
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        // Quantos tokens foram recebidos no contrato (saldo atual + já retirados)
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        // De acordo com a fórmula de liberação linear, calcule a quantidade já liberada
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}