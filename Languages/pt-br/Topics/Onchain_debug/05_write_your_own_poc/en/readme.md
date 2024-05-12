# Depuração de Transações OnChain: 5. Escreva sua própria PoC (Reentrancy)

Autor: [gbaleeee](https://twitter.com/gbaleeeee)

Tradução: [Spark](https://twitter.com/SparkToday00)

Neste artigo, aprenderemos sobre reentrancy, demonstrando um ataque do mundo real e usando o Foundry para realizar testes e reproduzir o ataque.

## Pré-requisitos
1. Entender os vetores de ataque comuns nos contratos inteligentes. [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs) é um ótimo recurso para começar.
2. Saber como funciona o modelo básico de DeFi e como os contratos inteligentes interagem entre si.

## O que é um Ataque de Reentrancy

Fonte: [Reentrancy](https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/) por Consensys.

O Ataque de Reentrancy é um vetor de ataque popular. Acontece quase todos os meses se olharmos para o banco de dados do [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs). Para mais informações, há outro ótimo repositório que mantém uma coleção de [reentrancy-attacks](https://github.com/pcaversaccio/reentrancy-attacks).

Em resumo, se uma função invoca uma chamada externa não confiável, pode haver um risco de ataque de reentrancy.

Os Ataques de Reentrancy podem ser identificados principalmente em três tipos:
1. Reentrancy de Função Única
2. Reentrancy entre Funções
3. Reentrancy entre Contratos

## PoC Prática - DFX Finance

- Fonte: [Alerta Pckshield 11/11/2022](https://twitter.com/peckshield/status/1590831589004816384)
  > Parece que o pool DEX (chamado Curve) da @DFXFinance foi hackeado (com perda de 3000 ETH ou $~4M) devido à falta de proteção adequada contra reentrancy. Aqui está uma transação de exemplo: https://etherscan.io/tx/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7. Os fundos roubados estão sendo depositados no @TornadoCash.

- Visão Geral da Transação

  Com base na transação acima, podemos observar informações limitadas no etherscan. Isso inclui informações sobre o remetente (atacante), o contrato do atacante, eventos durante a transação, etc. A transação é rotulada como uma "Transação MEV" e "Flashbots", indicando que o atacante tentou evitar o impacto dos bots de front-run.

  ![image](https://user-images.githubusercontent.com/53768199/215320542-a7798698-3fd4-4acf-90bf-263d37379795.png)

- Análise da Transação
  Podemos usar o [Phalcon da Blocksec](https://phalcon.blocksec.com/tx/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7) para fazer uma investigação mais aprofundada.

- Análise de Saldo
  Na seção *Mudanças de Saldo*, podemos ver a alteração nos fundos com esta transação. O contrato de ataque (destinatário) coletou uma grande quantidade de tokens `USDC` e `XIDR` como lucro, e o contrato chamado `dfx-xidr-v2` perdeu uma grande quantidade de tokens `USDC` e `XIDR`. Ao mesmo tempo, o endereço começando com `0x27e8` também obteve alguns tokens `USDC` e `XIDR`. De acordo com a investigação deste endereço, este é o endereço da carteira de assinatura múltipla de governança da DFX Finance.

  ![image](https://user-images.githubusercontent.com/53768199/215320922-72207a7f-cfac-457d-b69e-3fddc043206b.png)

  Com base nas observações mencionadas acima, a vítima é o contrato `dfx-xidr-v2` da DFX Finance e os ativos perdidos são os tokens `USDC` e `XIDR`. O endereço de assinatura múltipla da DFX também recebe alguns tokens durante o processo. Com base em nossa experiência, isso deve estar relacionado à lógica de taxas.

- Análise do Fluxo de Ativos
  Podemos usar outra ferramenta da Blocksec chamada [metasleuth](https://metasleuth.io/result/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7) para analisar o fluxo de ativos.

  ![image](https://user-images.githubusercontent.com/53768199/215321213-7ead5043-1410-4ab6-b247-1e710d931fe8.png)

  Com base no gráfico acima, o atacante pegou emprestado uma grande quantidade de tokens `USDC` e `XIDR` do contrato vítima nos passos [1] e [2]. Nos passos [3] e [4], os ativos emprestados foram enviados de volta para o contrato vítima. Depois disso, tokens `dfx-xidr-v2` são criados para o atacante no passo [5] e a carteira de assinatura múltipla da DFX recebe a taxa tanto em `USDC` quanto em `XIDR` nos passos [6] e [7]. No final, os tokens `dfx-xidr-v2` são queimados do endereço do atacante.

  Em resumo, o fluxo de ativos é:
  1. O atacante pegou emprestado tokens `USDC` e `XIDR` do contrato vítima.
  2. O atacante enviou os tokens `USDC` e `XIDR` de volta para o contrato vítima.
  3. O atacante criou tokens `dfx-xidr-v2`.
  4. A carteira de assinatura múltipla da DFX recebeu tokens `USDC` e `XIDR`.
  5. O atacante queimou tokens `dfx-xidr-v2`.

  Essas informações podem ser verificadas com a análise de rastreamento a seguir.

- Análise de Rastreamento

  Vamos observar a transação no nível de expansão 2.

  ![image](https://user-images.githubusercontent.com/53768199/215321768-6aa93999-9a77-4af5-b758-dd91f7dc3973.png)

  O fluxo de execução completo da transação de ataque pode ser visualizado como:

  1. O atacante invocou a função `0xb727281f` para o ataque.
  2. O atacante chamou `viewDeposit` no contrato `dfx-xidr-v2` via `staticcall`.
  3. O atacante acionou a função `flash` no contrato `dfx-xidr-v2` com `call`. Vale ressaltar que neste rastreamento, a função `0xc3924ed6` no contrato de ataque foi usada como um retorno de chamada.

  ![image](https://user-images.githubusercontent.com/53768199/215322039-59a46e1f-c8c5-449f-9cdd-5bebbdf28796.png)

  4. O atacante chamou a função `withdraw` no contrato `dfx-xidr-v2`.

- Análise Detalhada

  A intenção do atacante ao chamar a função viewDeposit no primeiro passo pode ser encontrada no comentário da função `viewDeposit`. O atacante deseja obter o número de tokens `USDC` e `XIDR` para criar 200_000 * 1e18 tokens `dfx-xidr-v2`.

  ![image](https://user-images.githubusercontent.com/53768199/215324532-b441691f-dae4-4bb2-aadb-7bd93d284270.png)

  E no próximo passo, o ataque usa o valor de retorno da função `viewDeposit` como um valor semelhante para a entrada da invocação da função `flash` (o valor não é exatamente o mesmo, mais detalhes depois).

  ![image](https://user-images.githubusercontent.com/53768199/215329296-97b6af11-32aa-4d0a-a7c4-019f355be04d.png)

  O atacante invoca a função `flash` no contrato vítima como o segundo passo. Podemos obter algumas informações do código:

  ![image](https://user-images.githubusercontent.com/53768199/215329457-3a48399c-e2e1-43a8-ab63-a89375fbc239.png)

  Como você pode ver, a função `flash` é semelhante ao empréstimo flash no Uniswap V2. O usuário pode pegar emprestado ativos por meio dessa função. E a função `flash` tem uma função de retorno de chamada para o usuário. O código é:
  ```solidity
  IFlashCallback(msg.sender).flashCallback(fee0, fee1, data);
  ```
  Essa invocação corresponde à função de retorno de chamada no contrato do atacante na seção de análise de rastreamento anterior. Se fizermos a verificação de hash de 4 bytes, é `0xc3924ed6`.

  ![image](https://user-images.githubusercontent.com/53768199/215329899-a6f2cc00-f2ac-49c8-b4df-38bb24663f37.png)

  ![image](https://user-images.githubusercontent.com/53768199/215329919-bbeb557d-41d0-47fb-bdf8-321e5217854e.png)

  O último passo é chamar a função `withdraw`, que irá queimar o token estável (`dfx-xidr-v2`) e retirar os ativos emparelhados (`USDC` e `XIDR`).

  ![image](https://user-images.githubusercontent.com/53768199/215330132-7b54bf35-3787-495a-992d-ac2bcabb97d9.png)

- Implementação da PoC

  Com base na análise acima, podemos implementar o esqueleto da PoC abaixo:

  ```solidity
  contract EXP {
      uint256 amount;
      function testExploit() public{
        uint[] memory XIDR_USDC = new uint[](2);
        XIDR_USDC[0] = 0;
        XIDR_USDC[1] = 0;
        ( , XIDR_USDC) = dfx.viewDeposit(200_000 * 1e18);
        dfx.flash(address(this), XIDR_USDC[0] * 995 / 1000, XIDR_USDC[1] * 995 / 1000, new bytes(1)); // 5% fee
        dfx.withdraw(amount, block.timestamp + 60);
    }
  
    function flashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external{
        /*
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        */
    }
  }
  ```
  É provável que surja a pergunta de como um atacante rouba ativos com a função `withdraw` em um empréstimo flash. Obviamente, esta é a única parte em que o atacante pode trabalhar. Agora vamos mergulhar na função de retorno de chamada:

  ![image](https://user-images.githubusercontent.com/53768199/215330695-1b1fa612-4f01-4c6a-a5be-7324f464ecb1.png)

  Como você pode ver, o atacante chamou a função `deposit` no contrato vítima e receberá os ativos numeraire que o pool suporta e criará tokens de curva. Como mencionado no gráfico acima, `USDC` e `XIDR` são enviados para a vítima via `transferFrom`.

  ![image](https://user-images.githubusercontent.com/53768199/215330576-d15642f7-5819-4e83-a8c8-1d3a48ad8c6d.png)

  Neste ponto, sabe-se que a conclusão do empréstimo flash é determinada verificando se os ativos de token correspondentes no contrato são maiores ou iguais ao estado antes da execução da função de retorno de chamada do empréstimo flash. E a função `deposit` fará essa validação completa.

  ```solidity
  require(balance0Before.add(fee0) <= balance0After, 'Curve/insufficient-token0-returned');
  require(balance1Before.add(fee1) <= balance1After, 'Curve/insufficient-token1-returned');
  ```

  Deve-se notar que o atacante preparou alguns tokens `USDC` e `XIDR` para o mecanismo de taxa de empréstimo flash antes do ataque. É por isso que o depósito do atacante é relativamente maior do que o valor emprestado. Portanto, o valor total para a invocação de `deposit` é o valor emprestado com o empréstimo flash mais a taxa. A validação na função `flash` pode ser passada com isso.

  Como resultado, o atacante invocou `deposit` na função de retorno de chamada do empréstimo flash, contornou a validação no empréstimo flash e deixou o registro para o depósito. Após todas essas operações, o atacante retirou os tokens.

  Em resumo, todo o fluxo de ataque é:
  1. Prepare alguns tokens `USDC` e `XIDR` com antecedência.
  2. Use `viewDeposit()` para obter o número de ativos para posterior `deposit()`.
  3. Faça um flash de tokens `USDC` e `XIDR` com base no valor de retorno no passo 2.
  4. Invoque a função `deposit()` na função de retorno de chamada do empréstimo flash.
  5. Como temos um registro de depósito no passo anterior, agora retire os tokens.

  A implementação completa da PoC:
  ```solidity
  contract EXP {
      uint256 amount;
      function testExploit() public{
        uint[] memory XIDR_USDC = new uint[](2);
        XIDR_USDC[0] = 0;
        XIDR_USDC[1] = 0;
        ( , XIDR_USDC) = dfx.viewDeposit(200_000 * 1e18);
        dfx.flash(address(this), XIDR_USDC[0] * 995 / 1000, XIDR_USDC[1] * 995 / 1000, new bytes(1)); // 5% fee
        dfx.withdraw(amount, block.timestamp + 60);
    }

      function flashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external{
        (amount, ) = dfx.deposit(200_000 * 1e18, block.timestamp + 60);
    }
  }
  ```

  O código mais detalhado pode ser encontrado no repositório DefiHackLabs: [DFX_exp.sol](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/DFX_exp.sol)

- Verificar Fluxo de Fundos

  Agora, podemos verificar o gráfico de fluxo de ativos com os eventos de token durante a transação.

  ![image](https://user-images.githubusercontent.com/53768199/215331469-e1edd9b4-5147-4f82-9e38-64edce3cc91f.png)

  No final da função `deposit`, tokens `dfx-xidr-v2` foram criados para o atacante.

  ![image](https://user-images.githubusercontent.com/53768199/215331545-9730e5b0-564d-45d8-b169-3b7c8651962f.png)

  Na função `flash`, o evento de transferência mostra a coleta de taxa (`USDC` e `XIDR`) para a carteira de assinatura múltipla da DFX.

  ![image](https://user-images.githubusercontent.com/53768199/215331819-d80a1775-4056-4ddd-9083-6f5241d07213.png)

  A função `withdraw` queimou os tokens `dfx-xidr-v2` que foram criados nos passos anteriores.

- Resumo

  O ataque de reentrancy na DFX Finance é um típico ataque de reentrancy entre funções, onde o atacante completa a reentrancy chamando a função `deposit` na função de retorno de chamada do empréstimo flash.

Vale mencionar que a técnica deste ataque corresponde exatamente à quarta pergunta no CTF damnvulnerabledefi [Side Entrance. Se os desenvolvedores do projeto tivessem feito isso com cuidado antes, talvez esse ataque não tivesse acontecido 🤣. Em dezembro do mesmo ano, o projeto [Defrost](https://github.com/SunWeb3Sec/DeFiHackLabs#20221223---defrost---reentrancy) também foi atacado devido a um problema semelhante.

