// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Random is ERC721, VRFConsumerBaseV2{
    // NFT relacionado
    // Oferta total
    // Usado para calcular o tokenId disponível para mintar
    // Quantidade já mintada

    // Parâmetros do Chainlink VRF
    
    //VRFCoordinatorV2Interface
    VRFCoordinatorV2Interface COORDINATOR;
    
    /**
     * Usando o Chainlink VRF, o construtor precisa herdar de VRFConsumerBaseV2
     * Os parâmetros da cadeia são diferentes
     * Rede: Sepolia Testnet
     * Endereço do Chainlink VRF Coordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     * Endereço do token LINK: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * 30 gwei Key Hash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
     * Confirmações mínimas: 3 (um número maior aumenta a segurança, geralmente preencha com 12)
     * Limite de gás para callback: máximo de 2.500.000
     * Valores aleatórios máximos: até 500 por vez
     */
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 1_000_000;
    uint32 numWords = 1;
    uint64 subId;
    uint256 public requestId;
    
    // Registre o endereço mint correspondente à identificação da solicitação VRF.
    mapping(uint256 => address) public requestToSender;

    constructor(uint64 s_subId) 
        VRFConsumerBaseV2(vrfCoordinator)
        ERC721("WTF Random", "WTF"){
            COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
            subId = s_subId;
    }

    /** 
    * Insira um número uint256 e receba um tokenId que pode ser mintado
    */
    function pickRandomUniqueId(uint256 random) private returns (uint256 tokenId) {
        // Primeiro, faça a subtração e depois calcule o incremento. Preste atenção na diferença entre (a++, ++a).
        // Quantidade mintável
        // Todos os tokenId foram mintados completamente.
        // Obter um número aleatório na cadeia

        //Gerando um número aleatório e obtendo o tokenId através do módulo, que será usado como índice do array. Ao mesmo tempo, o valor é registrado como len-1. Se o valor obtido pelo módulo já existir, o tokenId será obtido do valor do índice do array.
        // Obter tokenId
        // Atualizar lista de ids
        // Remover o último elemento e retornar o gas
    }

    /**
    * Geração de números pseudoaleatórios na cadeia
    * Preencha keccak256(abi.encodePacked() com algumas variáveis globais/variáveis personalizadas na cadeia
    * Converta para o tipo uint256 ao retornar
    */
    function getRandomOnchain() public view returns(uint256){
        /*
         * Neste exemplo, a aleatoriedade na cadeia depende apenas do hash do bloco, do endereço do chamador e do tempo do bloco.
         * Para aumentar a aleatoriedade, pode-se adicionar mais atributos, como nonce, mas isso não resolve fundamentalmente o problema de segurança.
         */
        bytes32 randomBytes = keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender, block.timestamp));
        return uint256(randomBytes);
    }

    // Usando números pseudoaleatórios na cadeia para criar NFTs
    function mintRandomOnchain() public {
        // Usando números aleatórios na cadeia para gerar um tokenId
        _mint(msg.sender, _tokenId);
    }

    /**
     * Chame a função VRF para obter um número aleatório e mintNFT
     * Para chamar a função requestRandomness(), a lógica de consumo do número aleatório deve ser escrita na função de retorno fulfillRandomness() do VRF
     * Antes de chamar, é necessário financiar Link suficiente na Subscriptions
     */
    function mintRandomVRF() public {
        // Chamar requestRandomness para obter um número aleatório
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestToSender[requestId] = msg.sender;
    }

    /**
     * Função de retorno do VRF, chamada pelo Coordenador do VRF
     * A lógica de consumo de números aleatórios é escrita nesta função
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory s_randomWords) internal override{
        // Obter o endereço do usuário minter de requestToSender
        // Usando o número aleatório retornado pelo VRF para gerar o tokenId
        _mint(sender, tokenId);
    }
}