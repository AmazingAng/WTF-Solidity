---
title: 39. Números Aleatórios na Cadeia
tags:
  - solidity
  - aplicação
  - wtfacademy
  - ERC721
  - aleatório
  - chainlink
---

# WTF Introdução Simples ao Solidity: 39. Números Aleatórios na Cadeia

Recentemente, estou revisitando o Solidity para consolidar alguns detalhes e estou escrevendo uma série "WTF Introdução Simples ao Solidity" para ser utilizada por iniciantes (programadores experientes podem procurar por tutoriais mais avançados), com novas lições semanais.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Discord: [WTF Academy](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

Muitos aplicativos na Ethereum precisam de números aleatórios, como sorteio de tokens em NFTs, aberturas de packs, jogos de luta em GameFi, entre outros. No entanto, devido ao fato de que todos os dados na Ethereum são públicos e determinísticos, não há uma maneira direta de gerar números aleatórios como em outras linguagens de programação. Nesta lição, vamos abordar dois métodos de geração de números aleatórios na cadeia (usando funções de hash) e fora da cadeia (usando o oráculo Chainlink), e usá-los para criar um NFT com tokens ID aleatórios.

## Geração de Números Aleatórios na Cadeia

Podemos utilizar algumas variáveis globais na cadeia como sementes, e usar a função de hash `keccak256()` para obter um número pseudoaleatório. Isso ocorre porque as funções de hash possuem sensibilidade e uniformidade, permitindo a obtenção de resultados "aleatórios". A função `getRandomOnchain()` a seguir utiliza as variáveis globais `block.timestamp`, `msg.sender` e `blockhash(block.number-1)` como sementes para gerar o número aleatório:

```solidity
    /** 
    * Geração de números pseudorandômicos na cadeia
    * Utiliza o keccak256() para combinar algumas variáveis globais/personalizadas na cadeia
    * Retorna um tipo uint256
    */
    function getRandomOnchain() public view returns(uint256){
        // O remix apresentará um erro ao usar blockhash
        bytes32 randomBytes = keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number-1)));
        
        return uint256(randomBytes);
    }
```

**Atenção:** Este método não é seguro:
- Primeiramente, as variáveis `block.timestamp`, `msg.sender` e `blockhash(block.number-1)` são públicas, permitindo que os usuários prevejam o número aleatório gerado com essas sementes e escolham o número que desejam antes de realizar a transação.
- Em segundo lugar, os mineradores podem manipular o `blockhash` e o `block.timestamp`, resultando em um número aleatório que favoreça seus interesses.

Apesar disso, esse método é o mais simples e rápido para gerar números aleatórios na cadeia, e muitos projetos o utilizam mesmo sendo inseguro, incluindo projetos conhecidos como `meebits` e `loots`. No entanto, esses projetos foram todos [atacados](https://forum.openzeppelin.com/t/understanding-the-meebits-exploit/8281): os atacantes puderam criar qualquer token NFT raro que desejavam, em vez de realizar um sorteio.

## Geração de Números Aleatórios Fora da Cadeia

Podemos gerar números aleatórios fora da cadeia e, em seguida, enviar esses números para a cadeia usando um oráculo, como o `Chainlink VRF`. O `Chainlink` fornece o serviço `VRF` (Função de Verificação Aleatória), no qual os desenvolvedores podem pagar com tokens `LINK` para obter números aleatórios. O `Chainlink VRF` tem duas versões, e a segunda versão requer registro no site oficial e pré-pagamento. Embora a segunda versão exija mais operações e gaste mais gás, após cancelar a assinatura, é possível reaver os LINKs restantes. Aqui, vamos apresentar a segunda versão do `Chainlink VRF`, conhecido como `Chainlink VRF V2`.

### Passos para Utilizar o `Chainlink VRF`
![Chainlink VRF](./img/39-1.png)

Vamos utilizar um contrato simples para demonstrar os passos para utilizar o `Chainlink VRF`. O contrato `RandomNumberConsumer` pode solicitar um número aleatório ao `VRF` e armazená-lo na variável de estado `randomWords`.

**1. Inscrever-se e Transferir `LINK` para a `Subscription`**

Registre-se no site do Chainlink VRF [aqui](https://vrf.chain.link/) e insira alguns detalhes (como e-mail e nome do projeto). Em seguida, transfira alguns tokens `LINK` para a `Subscription`. Os tokens `LINK` de teste podem ser obtidos do [LINK Faucet](https://faucets.chain.link/).

**2. Contrato do Consumidor Herda de `VRFConsumerBaseV2`**

Para usar o `VRF` e obter números aleatórios, o contrato deve herdar do contrato `VRFConsumerBaseV2` e inicializar o `VRFCoordinatorV2Interface` e o `Subscription Id` no construtor.

**Atenção:** Os parâmetros podem variar de acordo com a rede. Consulte [aqui](https://docs.chain.link/vrf/v2/subscription/supported-networks) para obter informações.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RandomNumberConsumer is VRFConsumerBaseV2{

    // Need to call VRFCoordinatorV2Interface for generate a RandomNumber
    VRFCoordinatorV2Interface COORDINATOR;
    
    // Define Subscription ID
    uint64 subId;

    // Store requestId and randomWords
    uint256 public requestId;
    uint256[] public randomWords;
    
    /**
     * Use Chainlink VRF, constructor needs to inherit from VRFConsumerBaseV2
     * Parameters vary by network
     * See: https://docs.chain.link/vrf/v2/subscription/supported-networks
     * Network: Sepolia Testnet
     * Chainlink VRF Coordinator Address: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     * LINK Token Address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * 30 gwei Key Hash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
     * Minimum Confirmations: 3 (Consider a higher number for more security, usually 12)
     * Callback Gas Limit: Maximum 2,500,000
     * Maximum Random Values: 500 per request                    
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
```

**2. Consumidor do Contrato Solicita um Número Aleatório**

Os usuários podem chamar a função `requestRandomWords` da interface do contrato `VRFCoordinatorV2Interface` para solicitar um número aleatório e receber um identificador de solicitação `requestId`. Esta solicitação será enviada para o contrato `VRF`.

```solidity
    /** 
     * Requesting a random number from VRF
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
```

**3. Geração do NFT com o Número Aleatório**

Após a solicitação do número aleatório, o consumidor pode usar a função de hacheamento do número retornado no contrato `fulfillRandomWords` para realizar a lógica necessária (neste caso, a geração do NFT).

```solidity
    /**
     * VRF Callback function, called when the random number is returned from VRF Coordinator
     * Consume the random number logic here
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory s_randomWords) internal override {
        randomWords = s_randomWords;
    }
```

## Mint de um NFT com Token ID Aleatório

Nesta seção, vamos usar números aleatórios na cadeia e fora da cadeia para criar um NFT com tokens ID aleatórios. O contrato `Random` herda os contratos `ERC721` e `VRFConsumerBaseV2`.

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "https://github.com/AmazingAng/WTF-Solidity/blob/main/34_ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Random is ERC721, VRFConsumerBaseV2{
```

### Variáveis de Estado

- Relacionadas ao NFT
    - `totalSupply`: fornecimento total de NFTs.
    - `ids`: array utilizado para calcular os tokens ID que podem ser criados, conforme a função `pickRandomUniqueId()`.
    - `mintCount`: quantidade de tokens já criados.
- Relacionadas ao Chainlink VRF
    - `COORDINATOR`: para chamar a interface `VRFCoordinatorV2Interface`.
    - `vrfCoordinator`: endereço do contrato `VRF`.
    - `keyHash`: identificação única do `VRF`.
    - `requestConfirmations`: número de blocos de confirmação.
    - `callbackGasLimit`: taxa para a transação `VRF`.
    - `numWords`: quantidade de números aleatórios a solicitar.
    - `subId`: ID da `Subscription`.
    - `requestId`: identificador da solicitação.
    - `requestToSender`: mapeamento do identificador de solicitação do `VRF` para o endereço do usuário solicitante.

```solidity
    // Variáveis relacionadas ao NFT
    uint256 public totalSupply = 100; // Fornecimento total
    uint256[100] public ids; // Utilizado para calcular os tokens ID que podem ser mintados
    uint256 public mintCount; // Quantidade de tokens mintados

    // Parâmetros Chainlink VRF
    
    // VRFCoordinatorV2Interface
    VRFCoordinatorV2Interface COORDINATOR;
    
    /**
     * Usar Chainlink VRF, o construtor necessita herdar de VRFConsumerBaseV2
     * Parâmetros variam de acordo com a rede
     * Consulte: https://docs.chain.link/vrf/v2/subscription/supported-networks
     * Rede: Testnet de Sepolia
     * Endereço do Chainlink VRF Coordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     * Endereço do Token LINK: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Hash de Chave de 30 gwei: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
     * Mínimo de Confirmações: 3 (Considere um número maior para mais segurança, geralmente 12)
     * Limite de Gás de Retorno de Chamada: Máximo de 2.500.000
     * Máximo de Valores Aleatórios: 500 por solicitação          
     */
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 1_000_000;
    uint32 numWords = 1;
    uint64 subId;
    uint256 public requestId;
    
    // Mapear o endereço do usuário que solicita o VRF para o identificador de solicitação
    mapping(uint256 => address) public requestToSender;
```

### Construtor
Inicializa as variáveis herdadas do contrato `VRFConsumerBaseV2` e `ERC721`.

```solidity
    constructor(uint64 s_subId) 
        VRFConsumerBaseV2(vrfCoordinator)
        ERC721("WTF Random", "WTF"){
            COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
            subId = s_subId;
    }
```

### Outras Funções
Além do construtor, o contrato define 5 outras funções.

- `pickRandomUniqueId()`: recebe um número aleatório e retorna um token ID que pode ser mintado.
- `getRandomOnchain()`: obtém um número aleatório na cadeia (não seguro).
- `mintRandomOnchain()`: utiliza um número aleatório na cadeia para criar um NFT, chamando as funções `getRandomOnchain()` e `pickRandomUniqueId()`.
- `mintRandomVRF()`: solicita um número ao `Chainlink VRF` para criar um NFT. Como a lógica de consumo do número aleatório está na função de retorno `fulfillRandomWords()`, chamada pelo contrato `VRF`, e não pelo usuário, é necessário armazenar o endereço do usuário que solicitou o VRF no mapeamento `requestToSender`.
- `fulfillRandomWords()`: função de retorno do `VRF`, chamada automaticamente pelo contrato `VRF` após verificar a autenticidade do número aleatório, utilizada para criar o NFT.

```solidity
    /** 
    * Recebe um uint256 e retorna um token ID que pode ser mintado
    */
    function pickRandomUniqueId(uint256 random) private returns (uint256 tokenId) {
        uint256 len = totalSupply - mintCount++; // Calcula a quantidade de tokens disponíveis para mintar
        require(len > 0, "mint close"); // Todos os tokens foram mintados
        uint256 randomIndex = random % len; // Obtém o número aleatório na cadeia

        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex; // Obtém o token ID
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1]; // Atualiza a lista de tokens
        ids[len - 1] = 0; // Remove o último elemento para economizar gás
    }

    /** 
    * Gera um número aleatório na cadeia
    * Utiliza blockhash(), msg.sender e block.timestamp
    * Retorna um uint256
    */
    function getRandomOnchain() public view returns(uint256){
        bytes32 randomBytes = keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender, block.timestamp));
        return uint256(randomBytes);
    }

    // Mint de um NFT utilizando um número aleatório na cadeia
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain()); // Gera um token ID usando um número aleatório na cadeia
        _mint(msg.sender, _tokenId);
    }

    /** 
     * Chama o VRF para obter um número aleatório e mintar um NFT
     */
    function mintRandomVRF() public {
        // Solicita um número aleatório ao VRF
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
     * Função de retorno do VRF, chamada pelo VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory s_randomWords) internal override{
        address sender = requestToSender[requestId]; // Obtém o endereço do usuário que solicitou o VRF
        uint256 tokenId = pickRandomUniqueId(s_randomWords[0]); // Gera um token ID utilizando o número aleatório retornado pelo VRF
        _mint(sender, tokenId);
    }
```

## Verificação no `remix`

### 1. Solicitar `Subscription` no `Chainlink VRF`
![Solicitar Subscription](./img/39-2.png)

### 2. Obter Tokens de Teste `LINK` e `ETH` na `Chainlink` Faucet
![Obter LINK e ETH na Testnet Sepolia](./img/39-3.png)

### 3. Transferir `LINK` para a `Subscription`
![Transferir LINK para a Subscription](./img/39-4.png)

### 4. Criar NFTs usando números aleatórios onchain

Na interface do `remix`, clique na função laranja `mintRandomOnchain` no lado esquerdo ![mintOnchain](./img/39-5-1.png), em seguida, clique em confirmar na janela pop-up do `Metamask` para iniciar a transação de criação usando números aleatórios onchain.

![Criar NFTs usando números aleatórios onchain](./img/39-5.png)

### 5. Criar NFTs usando números aleatórios offchain do `Chainlink VRF`

Da mesma forma, na interface do `remix`, clique na função laranja `mintRandomVRF` no lado esquerdo e clique em confirmar na janela pop-up da carteira little fox. A transação de criação de um `NFT` usando um número aleatório offchain do `Chainlink VRF` foi iniciada.

Observação: ao usar o `VRF` para criar um `NFT`, a iniciação da transação e o sucesso da criação não estão no mesmo bloco.

![Início da transação para criação usando VRF](./img/39-6.png)
![Sucesso da transação para criação usando VRF](./img/39-7.png)

### 6. Verificar que o `NFT` foi criado

Pelos screenshots acima, pode-se ver que neste exemplo, o `NFT` com `tokenId=87` foi criado aleatoriamente onchain, e o `NFT` com `tokenId=77` foi criado usando o `VRF`.

## Conclusão

Gerar um número aleatório em `Solidity` não é tão simples como em outras linguagens de programação. Neste tutorial, apresentamos dois métodos de geração de números aleatórios onchain (usando funções de hash) e offchain (oráculo `Chainlink`), e os usamos para criar um `NFT` com um `tokenId` atribuído aleatoriamente. Ambos os métodos têm suas vantagens e desvantagens: usar números aleatórios onchain é eficiente, mas inseguro, enquanto gerar números aleatórios offchain depende de serviços de oráculo de terceiros, o que é relativamente seguro, mas não tão fácil e econômico. As equipes de projeto devem escolher o método apropriado de acordo com suas necessidades específicas.

Além desses métodos, existem outras organizações que estão tentando novas formas de RNG (Random Number Generation), como o [randao](https://github.com/randao/randao), que propõe fornecer um serviço de aleatoriedade verdadeiramente onchain em um padrão DAO.

