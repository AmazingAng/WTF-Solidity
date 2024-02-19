// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RandomNumberConsumer is VRFConsumerBaseV2{

    //A solicitação de um número aleatório requer a chamada da interface VRFCoordinatorV2Interface.
    VRFCoordinatorV2Interface COORDINATOR;
    
    // ID de submissão após a aplicação
    uint64 subId;

    // Armazenar o requestId e o número aleatório obtidos
    uint256 public requestId;
    uint256[] public randomWords;
    
    /**
     * Usando o Chainlink VRF, o construtor precisa herdar de VRFConsumerBaseV2
     * Os parâmetros da cadeia são diferentes
     * Você pode ver mais detalhes em: https://docs.chain.link/vrf/v2/subscription/supported-networks
     * Rede: Testnet Sepolia
     * Endereço do Chainlink VRF Coordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     * Endereço do token LINK: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash de 30 gwei: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
     * Confirmações mínimas: 3 (quanto maior o número, maior a segurança, geralmente preencha com 12)
     * Limite de gas callbackGasLimit: máximo de 2.500.000
     * Valores aleatórios máximos: 500 por vez
     */
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 200_000;
    uint32 numWords = 3;
    
    constructor(uint64 s_subId) VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subId = s_subId;
    }

    /** 
     * Solicitar um número aleatório ao contrato VRF 
     */
    function requestRandomWords() external {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /**
     * Função de retorno do contrato VRF, será chamada automaticamente após a validação do número aleatório
     * A lógica de consumo do número aleatório deve ser escrita aqui
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory s_randomWords) internal override {
        randomWords = s_randomWords;
    }

}