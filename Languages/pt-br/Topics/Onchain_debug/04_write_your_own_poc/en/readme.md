# Depuração de Transações OnChain: 4. Escreva seu próprio POC - Bot MEV

Autor: [Sun](https://twitter.com/1nf0s3cpt)

## Escreva o POC passo a passo - Tome o Bot MEV (BNB48) como exemplo

- Recapitulação
    - Em 20220913, um Bot MEV foi explorado por um atacante e todos os ativos no contrato foram transferidos, resultando em uma perda total de cerca de $140 mil.
    - O atacante envia uma transação privada através do nó validador BNB48, semelhante ao Flashbot, não colocando a transação na mempool pública para evitar ser Front-running.
- Análise
    - [TXID](https://bscscan.com/tx/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2) do atacante, podemos ver que o contrato do Bot MEV não foi verificado e não era de código aberto. Como o atacante o explorou?
    - Usando [phalcon](https://phalcon.blocksec.com/tx/bsc/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2) para verificar, a partir da parte do fluxo de funções dentro desta transação, o Bot MEV transferiu 6 tipos de ativos para a carteira do atacante. Como o atacante o explorou?
![Imagem](https://user-images.githubusercontent.com/52526645/211201079-e7c5cc3b-64f8-4146-ab0e-7dd46b535cc9.png)
    - Vamos olhar o processo de invocação da chamada de função e ver que a função `pancakeCall` foi chamada exatamente 6 vezes.
        - De: `0xee286554f8b315f0560a15b6f085ddad616d0601`
        - Contrato do atacante: `0x5cb11ce550a2e6c24ebfc8df86c5757b596e69c1`
        - Contrato do Bot MEV: `0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d`
 ![Imagem](https://user-images.githubusercontent.com/52526645/211201456-8b6f7bca-677d-40a2-b81b-fd6af18f94fd.png)
    - Vamos expandir uma das chamadas `pancakeCall` para ver, podemos ver que a chamada de retorno para o contrato do atacante lê o valor de token0() como BSC-USD e, em seguida, transfere BSC-USD para a carteira do atacante. Com isso, podemos saber que o atacante pode ter a permissão ou usar uma vulnerabilidade para mover todos os ativos no contrato do Bot MEV. O próximo passo é descobrir como o atacante o utiliza?
    ![Imagem](https://user-images.githubusercontent.com/52526645/211201744-9895803a-5f72-4f14-b147-b67b204bee75.png)
    - Por ter sido mencionado anteriormente que o contrato do Bot MEV não é de código aberto, então aqui podemos usar [Lição 1](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools) para introduzir a ferramenta de descompilação [Dedaub](https://library.dedaub.com/decompile). Vamos analisar e ver se podemos encontrar algo. Primeiro, copie os bytecodes do contrato do [Bscscan](https://bscscan.com/address/0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d#code) e cole no Dedaub para descompilá-lo. Como mostrado na figura abaixo, podemos ver que a permissão da função `pancakeCall` é definida como pública e qualquer um pode chamá-la. Isso é normal e não deve ser um grande problema na chamada de retorno do Flash Loan, mas podemos ver o local destacado em vermelho, executando uma função `0x10a`, e então vamos olhar para baixo.
    ![Imagem](https://user-images.githubusercontent.com/52526645/211202573-b4a4847d-a617-42c8-84d0-0f2dbd38a632.png)
   - A lógica da função `0x10a` é mostrada na figura abaixo. Podemos ver o ponto chave no local destacado em vermelho. Primeiro, leia qual token está em token0 no contrato do atacante e, em seguida, traga-o para a função de transferência `transfer`. Na função, o primeiro parâmetro, endereço do receptor `address(MEM[varg0.data])`, está em `pancakeCall` `varg3 (_data)`, que pode ser controlado, então o problema de vulnerabilidade chave está aqui.
          
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204177-fbebe377-23b0-4b0c-bb3e-dcb64dba2afc.png" alt="Capa" width="80%"/>
</div>

   - Olhando para a carga útil da chamada do atacante `pancakeCall`, os primeiros 32 bytes do valor de entrada em `_data` é o endereço da carteira do beneficiário.

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211453390-502db65b-cf82-4805-a463-04fc5c7e0dce.png" alt="Capa" width="80%"/>
</div>

- Escrevendo o POC
   - Após analisar o processo de ataque acima, a lógica de escrever o POC é chamar o `pancakeCall` do contrato do Bot MEV e, em seguida, trazer os parâmetros correspondentes. A chave é o `_data` para especificar o endereço da carteira de recebimento e, em seguida, o contrato deve ter as funções token0 e token1 para satisfazer a lógica do contrato. Você pode tentar escrevê-lo você mesmo.
    - Resposta: [POC](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/BNB48MEVBot_exp.sol).
    
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204852-4fa65835-17f7-4c91-80ab-79f5b46125df.png" alt="Capa" width="80%"/>
</div>

## Aprendizado estendido
- Rastreamento do Foundry
    - As funções de rastreamento da transação também podem ser listadas usando o Foundry, como segue:
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211562868-12fde773-948c-47a9-acaf-6f744438925e.png" alt="Capa" width="80%"/>
</div>

- Depuração do Foundry
    - Você também pode usar o Foundry para depurar a transação, como segue:
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --debug  --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211565713-fdf3784f-da54-42e8-ad60-591ecac38c15.png" alt="Capa" width="80%"/>
</div>

## Recursos

[Flashbots: Kings of The Mempool](https://noxx.substack.com/p/flashbots-kings-of-the-mempool?utm_source=profile&utm_medium=reader2)

[MEV Markets Part 1: Proof of Work](https://mirror.xyz/0xshittrader.eth/WiV8DM3I6abNMVsXf-DqioYb2NglnfjmM-zSsw2ruG8)

[MEV Markets Part 2: Proof of Stake](https://mirror.xyz/0xshittrader.eth/c6J_PCK87K3joTWmLEtG6qVN6BFXLBZxQniReYSEjLI)

[MEV Markets Part 3: Payment for Order Flow](https://mirror.xyz/0xshittrader.eth/f2VSuoZ91vAbCv82MtWM-Gosyf_DeUXfPlDx3EYV3RM)
.

