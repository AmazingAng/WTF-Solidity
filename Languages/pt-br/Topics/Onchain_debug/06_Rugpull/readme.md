# Depuração de Transações OnChain: 6. Análise do Projeto CirculateBUSD Rugpull, Perda de $2,27 Milhões!

Autor: [Numen Cyber Technology](https://twitter.com/numencyber)

## Introdução
De acordo com o monitoramento OnChain da NUMEN, em 12 de janeiro de 2023 às 14:22:39 (horário de Singapura), o projeto CirculateBUSD realizou um rugpull, resultando em uma perda de $2,27 milhões. A transferência de fundos do projeto foi principalmente realizada pelo administrador através da chamada da função `CirculateBUSD.startTrading`, onde o principal parâmetro de verificação é o valor retornado pela função não open-source `SwapHelper.TradingInfo`. Em seguida, os fundos foram transferidos através da chamada da função `SwapHelper.swaptoToken`.

<div align=center>
<img src="https://user-images.githubusercontent.com/107821372/212806617-33a2e763-754b-4682-baef-d78bccdbcbaa.png" alt="Cover" width="80%"/>
</div>

### Análise do Evento

* Primeiro, a função `startTrading` do contrato foi chamada, e dentro dessa função foi chamada a função `TradingInfo` do contrato [SwapHelper](https://bscscan.com/address/0x9639d76092b2ae074a7e2d13ac030b4b6a0313ff), como mostrado no código abaixo.

 <div align=center>
 <img src="https://user-images.githubusercontent.com/107821372/212807067-c3dfccde-6a26-4bb0-96e8-9a1141b88fc6.png" alt="Cover" width="80%"/>
 </div>

---
 <div align=center>
 <img src="https://user-images.githubusercontent.com/107821372/212807682-d99be725-a9a9-41a9-a380-329413af4b2f.png" alt="Cover" width="80%"/>
 </div>

  A imagem acima mostra a pilha de chamadas da transação, e combinando com o código, podemos ver que `TradingInfo` é apenas uma chamada estática, e o problema chave não está nessa função. Continuando a análise, encontramos as operações `approve` e `safeapprove` na pilha de chamadas. Em seguida, a função `swaptoToken` do contrato SwapHelper é chamada, e combinando com a pilha de chamadas, percebemos que essa é uma função chave onde a transferência de fundos é executada. Através das informações na blockchain, descobrimos que o contrato SwapHelper não é open-source, e o endereço específico é: https://bscscan.com/address/0x112f8834cd3db8d2dded90be6ba924a88f56eb4b#code

* Vamos tentar fazer uma análise reversa.
  1. Primeiro, localizamos a assinatura da função `0x63437561`.
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212841887-76fcfd50-81a4-4929-98f4-855dee1ec7ea.png" alt="Cover" width="80%"/>
  </div>
 
 
  2. Localizamos a função descompilada, e como vimos que a transferência foi acionada na pilha de chamadas, tentamos procurar palavras-chave como `transfer`.
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212847664-c7b75363-38c1-422b-81f9-3ecdd669e9f8.png" alt="Cover" width="80%"/>
  </div>
  
  
  3. Localizamos esse trecho do código da função, começando com `stor_6_0_19`, e o extraímos.
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848157-38e7cb71-cf37-48c1-82b3-97122293f935.png" alt="Cover" width="80%"/>
  </div>
  
  
  4. Agora temos o endereço de transferência `to`, `0x0000000000000000000000005695ef5f2e997b2e142b38837132a6c3ddc463b7`, que é o mesmo endereço de transferência na pilha de chamadas.
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848482-fcc3cc17-8719-4f58-ab3d-c26ffd256b45.png" alt="Cover" width="80%"/>
  </div>
  
  
  5. Analisando cuidadosamente o fluxo de controle do if e else dessa função, percebemos que se o if for verdadeiro, é uma troca normal. Porque através do slot, sabemos que `stor5` é `0x00000000000000000000000010ed43c718714eb63d5aa57b78b54704e256024e`, que é o contrato `pancakerouter`. A função de backdoor está no else, e basta passar um parâmetro igual ao valor armazenado no slot7 `stor7` para acioná-la.
  
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848758-b9590cc6-e750-4208-9a92-b000af150e99.png" alt="Cover" width="80%"/>
  </div> 
  
  
  6. Essa função é responsável por modificar o valor armazenado no slot7, e só pode ser acionada pelo owner do contrato.
  
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848982-42624cef-df94-4f10-bf51-4b8816b6c452.png" alt="Cover" width="80%"/>
  </div> 
  
  Todas as análises acima são suficientes para concluir que se trata de um caso de rugpull por parte do projeto.

## Conclusão
O laboratório NUMEN lembra aos usuários que ao investir, é necessário realizar uma auditoria de segurança nos contratos dos projetos. Contratos não verificados podem conter funcionalidades que dão ao projeto permissões excessivas ou afetam diretamente a segurança dos ativos dos usuários. Os problemas encontrados neste projeto são apenas a ponta do iceberg no ecossistema blockchain como um todo. Ao investir e desenvolver projetos, é essencial realizar uma auditoria de segurança no código. A NUMEN está focada em garantir a segurança do ecossistema web3.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->