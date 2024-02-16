# Depuração de Transações OnChain: 5. Escreva seu próprio PoC (Reentrância)

Autor: [gbaleeee](https://twitter.com/gbaleeeee)

Neste tutorial, vamos analisar um caso real de ataque de reentrância e guiá-lo passo a passo na criação de um PoC de reprodução usando o framework Foundry.

## Conhecimentos prévios necessários antes de escrever um PoC de reprodução

1. Familiaridade com os tipos comuns de vulnerabilidades em contratos inteligentes. Você pode praticar usando o [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs) como referência.
2. Compreensão de como a infraestrutura básica do DeFi funciona e como os contratos inteligentes interagem entre si.

## Introdução aos conceitos relacionados a ataques de reentrância

Um artigo da Consensys sobre ataques de reentrância: [Reentrancy](https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/)

Os ataques de reentrância são amplamente conhecidos no mundo das criptomoedas e ocorrem com frequência nos contratos DeFi. Você pode encontrar vários casos de ataques de reentrância no repositório DeFiHackLabs. Além disso, há um projeto interessante no GitHub chamado [reentrancy-attacks](https://github.com/pcaversaccio/reentrancy-attacks), que reúne casos reais de ataques de reentrância.

Em resumo, um ataque de reentrância ocorre quando uma função chama um contrato não confiável externo.

Atualmente, os ataques de reentrância podem ser divididos em três tipos:
1. Reentrância em uma única função (Single Function Reentrancy)
2. Reentrância entre funções (Cross-Function Reentrancy)
3. Reentrância entre contratos (Cross-Contract Reentrancy)

## Passo a passo para escrever um PoC - Usando o DFX Finance como exemplo

- Fonte de informação
  Em 11 de novembro de 2022, de acordo com um tweet da Peckshield, o pool DEX do DFX Finance foi atacado e sofreu uma perda de cerca de $4 milhões devido à falta de proteção contra reentrância. Uma das transações relacionadas ao ataque pode ser encontrada [aqui](https://etherscan.io/tx/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7).

- Visão geral da transação
  Ao analisar a transação no Etherscan, podemos obter algumas informações limitadas, como o remetente da transação, o contrato chamado e os eventos emitidos durante a transferência de tokens. No entanto, é importante observar que essa transação foi marcada como uma transação MEV (Miner Extractable Value) e Flashbots, o que indica que o atacante tomou medidas para evitar que sua transação de ataque fosse "front-run" por bots.  
  
  ![image](https://user-images.githubusercontent.com/53768199/215320542-a7798698-3fd4-4acf-90bf-263d37379795.png)  
  
  
- Análise da transação
  Para uma análise mais aprofundada dessa transação de ataque, podemos usar a ferramenta de análise [Phalcon](https://phalcon.blocksec.com/tx/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7) da equipe BlockSec.

- Análise de saldo
  Na seção "Balance Changes", podemos ver as mudanças de saldo resultantes dessa transação. O contrato atacado recebeu uma grande quantidade de tokens USDC e XIDR, enquanto o contrato "dfx-xidr-v2" do DFX Finance perdeu uma grande quantidade desses tokens. Além disso, um endereço começando com "0x27e8" também recebeu alguns tokens USDC e XIDR. Após investigar esse endereço, descobrimos que ele é o endereço da carteira multiassinatura do projeto DFX Finance.
  
  ![image](https://user-images.githubusercontent.com/53768199/215320922-72207a7f-cfac-457d-b69e-3fddc043206b.png)  
  
  Com base nas mudanças de saldo, podemos concluir que o ataque foi direcionado ao contrato "dfx-xidr-v2" do DFX Finance, onde os tokens USDC e XIDR foram roubados. Além disso, o endereço da carteira multiassinatura do DFX Finance também recebeu alguns tokens USDC e XIDR durante o ataque, o que provavelmente ocorreu devido à cobrança de taxas durante a interação entre os contratos.
  
- Fluxo de fundos
  Antes de analisar a transação em mais detalhes, podemos usar outra ferramenta da equipe BlockSec, o [metasleuth](https://metasleuth.io/result/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7), para analisar o fluxo de tokens nessa transação de ataque.
  ![image](https://user-images.githubusercontent.com/53768199/215321213-7ead5043-1410-4ab6-b247-1e710d931fe8.png)
  Com base nas informações mostradas no gráfico, o endereço marcado como "exploiter" emitiu uma grande quantidade de tokens USDC e XIDR no passo 1 e 2, retirou esses tokens do contrato atacado e, em seguida, no passo 3 e 4, enviou os tokens USDC e XIDR de volta para o contrato atacado. Em seguida, o contrato "dfx-xidr-v2" emitiu tokens para o endereço do atacante (0x27e8...) e a carteira multiassinatura do DFX Finance também recebeu tokens USDC e XIDR. Por fim, os tokens "dfx-xidr-v2" foram enviados para o endereço 0x0 para serem destruídos.  
  Podemos resumir o fluxo de tokens durante o ataque da seguinte forma:
  
  1. Retirada de tokens USDC e XIDR do contrato atacado
  2. Envio dos tokens USDC e XIDR de volta para o contrato atacado
  3. Emissão de tokens "dfx-xidr-v2" para o atacante
  4. Recebimento de tokens USDC e XIDR pela carteira multiassinatura do DFX Finance
  5. Envio dos tokens "dfx-xidr-v2" para o endereço 0x0 para destruição
  
  Essas informações serão analisadas e verificadas na próxima etapa, a análise do rastreamento de chamadas.
  
- Análise do rastreamento de chamadas
  Com o nível de detalhe definido como 2, podemos observar o fluxo de chamadas de função dessa transação.
  
  ![image](https://user-images.githubusercontent.com/53768199/215321768-6aa93999-9a77-4af5-b758-dd91f7dc3973.png)
  
  Podemos ver que o fluxo de execução das funções nessa transação de ataque é o seguinte:
  1. O atacante chama a função com o seletor de função hash 0xb727281f no contrato de ataque e executa o ataque nessa função.
  2. É feita uma chamada de staticcall para a função viewDeposit no contrato "dfx-xidr-v2".
  3. É feita uma chamada de call para a função flash no contrato "dfx-xidr-v2". Vale ressaltar que essa chamada de função inclui uma chamada de retorno para uma função com o seletor de função hash 0xc3924ed6 no contrato de ataque.

  ![image](https://user-images.githubusercontent.com/53768199/215322039-59a46e1f-c8c5-449f-9cdd-5bebbdf28796.png)
  
  4. É feita uma chamada de call para a função withdraw no contrato "dfx-xidr-v2".

- Análise detalhada
  Para entender a intenção por trás da primeira chamada da função viewDeposit pelo atacante, podemos examinar o código e os comentários dessa função. O atacante está tentando obter a quantidade necessária de dois tokens para depositar 200.000 * 1e18 tokens da stablecoin (no caso do DFX Finance, o token é o "dfx-xidr-v2").
  
  ![image](https://user-images.githubusercontent.com/53768199/215324532-b441691f-dae4-4bb2-aadb-7bd93d284270.png)
  
  Podemos ver no próximo passo, quando o atacante chama a função flash, que ele passa valores aproximados dos retornos da função viewDeposit como argumentos (explicaremos o motivo posteriormente).
  
  ![image](https://user-images.githubusercontent.com/53768199/215329296-97b6af11-32aa-4d0a-a7c4-019f355be04d.png)
  
  Em relação à segunda chamada da função flash no contrato atacado, podemos entender sua função e implementação olhando o código.
  
  ![image](https://user-images.githubusercontent.com/53768199/215329457-3a48399c-e2e1-43a8-ab63-a89375fbc239.png)
  
  Podemos ver que a função flash é uma implementação semelhante à funcionalidade de empréstimo relâmpago do Uniswap v2. Os usuários podem usar essa função para obter empréstimos instantâneos do contrato. Além disso, podemos ver que a função flash inclui uma chamada de retorno para a função do chamador, que é a chamada de retorno mencionada anteriormente no rastreamento de chamadas.
  ```solidity
  IFlashCallback(msg.sender).flashCallback(fee0, fee1, data);
  ```
  Essa chamada externa de função corresponde à chamada de retorno para a função do contrato de ataque mencionada anteriormente, que pode ser verificada calculando o hash de 4 bytes dessa função, que é exatamente 0xc3924ed6.
  
  ![image](https://user-images.githubusercontent.com/53768199/215329899-a6f2cc00-f2ac-49c8-b4df-38bb24663f37.png)
  
  ![image](https://user-images.githubusercontent.com/53768199/215329919-bbeb557d-41d0-47fb-bdf8-321e5217854e.png)
  
  Em relação à última chamada da função withdraw, podemos entender sua função e implementação olhando o código e os comentários do contrato atacado.
  
  ![image](https://user-images.githubusercontent.com/53768199/215330132-7b54bf35-3787-495a-992d-ac2bcabb97d9.png)
  
- Escrita do PoC
  Agora podemos escrever o esqueleto do código do PoC:
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
  Nesse ponto, surge a pergunta: como o atacante conseguiu chamar a função withdraw do contrato atacado apenas com a execução da função flash? A resposta é simples: o único local em que o atacante pode interagir é na chamada de retorno da função flash. Vamos analisar essa chamada de retorno em mais detalhes.
  
  ![image](https://user-images.githubusercontent.com/53768199/215330695-1b1fa612-4f01-4c6a-a5be-7324f464ecb1.png)
  
  Podemos ver que o atacante chama a função deposit do contrato atacado nessa etapa. Analisando o código e os comentários dessa função, podemos ver que ela realiza uma operação em que os tokens de ativos necessários para emitir a stablecoin são enviados para o contrato e, em troca, os tokens de curva são recebidos. Combinando isso com a chamada da função transferFrom dos tokens USDC e XIDR mostrada no gráfico, podemos concluir que os tokens USDC e XIDR foram enviados de volta para o contrato atacado por meio da função deposit.
  
  ![image](https://user-images.githubusercontent.com/53768199/215330576-d15642f7-5819-4e83-a8c8-1d3a48ad8c6d.png)
  
  Nesse ponto, combinando com a verificação da condição de conclusão da função flash, podemos ver que ela verifica se os saldos dos tokens correspondentes no contrato são maiores ou iguais aos saldos antes da execução da chamada de retorno.
  ```solidity
  require(balance0Before.add(fee0) <= balance0After, 'Curve/insufficient-token0-returned');
  require(balance1Before.add(fee1) <= balance1After, 'Curve/insufficient-token1-returned');
  ```
  É importante observar que, para atender aos requisitos relacionados às taxas na função flash, o atacante depositou uma quantidade ligeiramente maior de tokens USDC e XIDR do que a quantidade obtida na função flash. Essa quantidade adicional de tokens será enviada para a carteira multiassinatura do DFX Finance nas etapas subsequentes da função flash. O atacante preparou alguns tokens USDC e XIDR como taxa de flash antes de iniciar o ataque. A quantidade de tokens enviados para a função deposit é a soma dos tokens obtidos na função flash e das taxas de flash. Dessa forma, o atacante pode atender aos requisitos da função flash e, ao mesmo tempo, registrar o estado após a função deposit no contrato atacado para poder executar a função withdraw posteriormente.
  
  Portanto, o atacante conseguiu realizar o ataque de reentrância chamando a função deposit do contrato atacado durante a chamada de retorno da função flash, atendendo aos requisitos da função flash e registrando o estado após a função deposit no contrato atacado para poder executar a função withdraw posteriormente.
  
  Com base nessa análise do fluxo de ataque, podemos resumir as etapas do ataque da seguinte forma:
  1. Preparar alguns tokens USDC e XIDR antecipadamente.
  2. Chamar a função viewDeposit para obter a quantidade necessária de tokens para a função deposit.
  3. Com base nos valores obtidos na etapa anterior, chamar a função flash do contrato atacado para obter os tokens USDC e XIDR.
  4. Na chamada de retorno da função flash, chamar a função deposit do contrato atacado para enviar de volta os tokens USDC e XIDR, realizando a reentrância.
  5. Como a função deposit foi executada, chamar diretamente a função withdraw do contrato atacado para retirar os tokens.

  O código completo do PoC pode ser encontrado no repositório DeFiHackLabs: [DFX_exp.sol](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/DFX_exp.sol)
  
- Verificação do fluxo de fundos
  Agora podemos verificar o fluxo de fundos com base nos eventos emitidos pelos tokens na transação de ataque.
  
  ![image](https://user-images.githubusercontent.com/53768199/215331469-e1edd9b4-5147-4f82-9e38-64edce3cc91f.png)

  O evento emitido durante a execução da função deposit verifica que os tokens "dfx-xidr-v2" foram emitidos para o endereço do atacante.
  
  ![image](https://user-images.githubusercontent.com/53768199/215331545-9730e5b0-564d-45d8-b169-3b7c8651962f.png)

  O evento de transferência dos tokens USDC e XIDR durante a execução da função flash corresponde ao recebimento de alguns tokens USDC e XIDR pela carteira multiassinatura do DFX Finance.
  
  ![image](https://user-images.githubusercontent.com/53768199/215331819-d80a1775-4056-4ddd-9083-6f5241d07213.png)

  O evento emitido durante a execução da função withdraw verifica que os tokens "dfx-xidr-v2" foram enviados para o endereço 0x0 para serem destruídos.
  
- Conclusão
O ataque de reentrância no DFX Finance é um exemplo clássico de reentrância entre funções. O atacante conseguiu realizar a reentrância chamando a função deposit durante a chamada de retorno da função flash. É importante mencionar que esse tipo de ataque é semelhante ao desafio "Side Entrance" do CTF Damn Vulnerable DeFi. Se os desenvolvedores do projeto tivessem feito esse desafio anteriormente, talvez esse ataque não tivesse ocorrido. Além disso, em dezembro do mesmo ano, o projeto Defrost também foi atacado usando a mesma técnica de reentrância.

## Recursos de aprendizado
[Reentrancy Attacks on Smart Contracts Distilled](https://blog.pessimistic.io/reentrancy-attacks-on-smart-contracts-distilled-7fed3b04f4b6)  
[C.R.E.A.M. Finance Post Mortem: AMP Exploit](https://medium.com/cream-finance/c-r-e-a-m-finance-post-mortem-amp-exploit-6ceb20a630c5)  
[Cross-Contract Reentrancy Attack](https://inspexco.medium.com/cross-contract-reentrancy-attack-402d27a02a15)  
[Sherlock Yield Strategy Bug Bounty Post-Mortem](https://mirror.xyz/0xE400820f3D60d77a3EC8018d44366ed0d334f93C/LOZF1YBcH1eBdxlC6HP223cAMeTpNgQ-Kc4EjQuxmGA)  
[Decoding $220K Read-only Reentrancy Exploit | QuillAudits](https://quillaudits.medium.com/decoding-220k-read-only-reentrancy-exploit-quillaudits-30871d728ad5)

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->