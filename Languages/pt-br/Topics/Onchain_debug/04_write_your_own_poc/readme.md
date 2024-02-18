# Depuração de Transações OnChain: 4. Escreva seu próprio POC - MEV Bot

Autor: [Sun](https://twitter.com/1nf0s3cpt)

## Passo a passo para escrever um POC - Exemplo com MEV Bot (BNB48)
- Contexto
    - Em 13 de setembro de 2022, um MEV Bot foi atacado e os atacantes exploraram uma vulnerabilidade para transferir os ativos do contrato, resultando em uma perda de cerca de $140 mil.

    - Os atacantes enviaram transações privadas através do nó de validação BNB48, semelhante ao Flashbot, que não coloca as transações na mempool pública para evitar ataques de front-running.
    
- Análise
    - O ataque foi realizado através desta [TXID](https://bscscan.com/tx/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2). O contrato do MEV Bot não é de código aberto, então como isso foi explorado?
    - Analisando através do [phalcon](https://phalcon.blocksec.com/tx/bsc/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2), podemos ver que nesta transação, o MEV Bot transferiu 6 tipos de ativos para a carteira do atacante. Como isso foi possível?
![Imagem](https://user-images.githubusercontent.com/52526645/211201079-e7c5cc3b-64f8-4146-ab0e-7dd46b535cc9.png)
    - Vamos analisar o fluxo de chamadas de função, onde podemos ver que a função `pancakeCall` foi chamada 6 vezes.
        - De: `0xee286554f8b315f0560a15b6f085ddad616d0601`
        - Contrato do atacante: `0x5cb11ce550a2e6c24ebfc8df86c5757b596e69c1`
        - Contrato do MEV Bot: `0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d`
 ![Imagem](https://user-images.githubusercontent.com/52526645/211201456-8b6f7bca-677d-40a2-b81b-fd6af18f94fd.png)
    - Vamos analisar uma das chamadas de `pancakeCall`. Podemos ver que o contrato do atacante leu o valor de `token0()` como BSC-USD e, em seguida, transferiu BSC-USD para a carteira do atacante. Com isso, podemos concluir que o atacante tinha permissão ou explorou uma vulnerabilidade para transferir os ativos do contrato do MEV Bot. Agora, precisamos descobrir como o atacante fez isso.
    ![Imagem](https://user-images.githubusercontent.com/52526645/211201744-9895803a-5f72-4f14-b147-b67b204bee75.png)
    - Como mencionado anteriormente, o contrato do MEV Bot não é de código aberto. Portanto, podemos usar a ferramenta de descompilação [Dedaub](https://library.dedaub.com/decompile), mencionada na [primeira aula](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools), para analisar o contrato e ver se encontramos algo. Primeiro, vamos colar os bytecodes do contrato no Dedaub para descompilá-lo. Na imagem abaixo, podemos ver que a função `pancakeCall` tem permissão pública, o que significa que qualquer pessoa pode chamá-la. É normal que a função de callback em um empréstimo relâmpago seja pública e não deve ser um problema. No entanto, podemos ver que, na parte destacada em vermelho, há uma chamada para a função `0x10a`. Vamos continuar analisando.
    ![Imagem](https://user-images.githubusercontent.com/52526645/211202573-b4a4847d-a617-42c8-84d0-0f2dbd38a632.png)
   - A lógica da função `0x10a` é mostrada na imagem abaixo. Podemos ver que, na parte destacada em vermelho, o contrato lê o token0 do contrato do atacante e, em seguida, o utiliza como parâmetro na função de transferência `transfer`. O primeiro parâmetro da função é o endereço do destinatário `address(MEM[varg0.data])`, que é controlado pelo `varg3 (_data)` do `pancakeCall`. Portanto, o problema crítico da vulnerabilidade está aqui.
   
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204177-fbebe377-23b0-4b0c-bb3e-dcb64dba2afc.png" alt="Capa" width="80%"/>
</div>

   - Vamos voltar e analisar o payload da chamada `pancakeCall`. Os primeiros 32 bytes do `_data` são o endereço da carteira do destinatário.

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211453390-502db65b-cf82-4805-a463-04fc5c7e0dce.png" alt="Capa" width="80%"/>
</div>

- Desenvolvendo o POC
    - Com base na análise do fluxo de ataque acima, o desenvolvimento do contrato POC envolve chamar a função `pancakeCall` do contrato do MEV Bot e fornecer os parâmetros corretos. A chave está no `_data`, onde especificamos o endereço da carteira do destinatário. Além disso, o contrato deve ter as funções `token0` e `token1` para atender à lógica do contrato. Você pode tentar escrever o contrato por conta própria. 
    - Resposta: [POC](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/BNB48MEVBot_exp.sol) para referência.
    
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204852-4fa65835-17f7-4c91-80ab-79f5b46125df.png" alt="Capa" width="80%"/>
</div>

## Estudo Avançado
- Rastreamento Foundry
    - O Foundry também pode listar os rastros de função dessa transação, usando o seguinte método:
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211562868-12fde773-948c-47a9-acaf-6f744438925e.png" alt="Capa" width="80%"/>
</div>

- Depuração Foundry
    - Também é possível usar o Foundry para depurar a transação, seguindo o método abaixo:  
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --debug  --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211565713-fdf3784f-da54-42e8-ad60-591ecac38c15.png" alt="Capa" width="80%"/>
</div>

## Recursos de aprendizado

[Flashbots: Kings of The Mempool](https://noxx.substack.com/p/flashbots-kings-of-the-mempool?utm_source=profile&utm_medium=reader2)

[MEV Markets Part 1: Proof of Work](https://mirror.xyz/0xshittrader.eth/WiV8DM3I6abNMVsXf-DqioYb2NglnfjmM-zSsw2ruG8)

[MEV Markets Part 2: Proof of Stake](https://mirror.xyz/0xshittrader.eth/c6J_PCK87K3joTWmLEtG6qVN6BFXLBZxQniReYSEjLI)

[MEV Markets Part 3: Payment for Order Flow](https://mirror.xyz/0xshittrader.eth/f2VSuoZ91vAbCv82MtWM-Gosyf_DeUXfPlDx3EYV3RM)

[Ethers极简入门: 25. Flashbots](https://github.com/WTFAcademy/WTF-Ethers/tree/main/25_Flashbots)

