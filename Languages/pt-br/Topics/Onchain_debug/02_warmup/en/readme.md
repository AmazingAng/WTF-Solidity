# Depuração de Transações OnChain: 2. Aquecimento

Autor: [Sun](https://twitter.com/1nf0s3cpt)

Tradução: Helen

Comunidade [Discord](https://discord.gg/3y3d9DMQ)

Este artigo é publicado na XREX e na [WTF Academy](https://github.com/AmazingAng/WTF-Solidity#%E9%93%BE%E4%B8%8A%E5%A8%81%E8%83%81%E5%88%86%E6%9E%90)

Os dados on-chain podem incluir transferências simples únicas, interações com um contrato DeFi ou vários contratos DeFi, arbitragem de empréstimo flash, propostas de governança, transações entre cadeias e muito mais. Nesta seção, vamos começar com um começo simples.
Vou apresentar no BlockChain Explorer - Etherscan o que nos interessa e, em seguida, usar [Phalcon](https://phalcon.blocksec.com/) para comparar as diferenças entre essas chamadas de função de transação: transferência de ativos, troca na UniSWAP, aumento de liquidez no Curve 3pool, propostas do Compound, Flashswap do Uniswap.

## Comece a aquecer

- O primeiro passo é instalar o [Foundry](https://github.com/foundry-rs/foundry) no ambiente. Siga as [instruções de instalação](https://book.getfoundry.sh/getting-started/installation).
  - Forge é uma ferramenta de teste importante na plataforma Foundry. Se for a primeira vez que você usa o Foundry, você pode consultar o [livro do Foundry](https://book.getfoundry.sh/), [Foundry @EthCC](https://www.youtube.com/watch?v=wJnywGB33O4), [WTF Solidity - Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md).
- Cada cadeia tem seu próprio explorador de blockchain. Nesta seção, usaremos a rede blockchain Ethereum como estudo de caso.
- As informações típicas às quais geralmente me refiro incluem:
  - Ação da transação: como a transferência de tokens ERC-20 complexos pode ser difícil de discernir, a Ação da Transação pode fornecer o comportamento chave da transferência. No entanto, nem todas as transações incluem essas informações.
  - De: msg.sender, o endereço da carteira de origem que executa esta transação.
  - Interagiu com (Para): Com qual contrato interagir
  - Transferência de Token ERC-20: Processo de Transferência de Token
  - Dados de Entrada: Os dados brutos de entrada da transação. Você pode ver qual função foi chamada e qual valor foi trazido.
- Se você não sabe quais ferramentas são comumente usadas, você pode ver as ferramentas de análise de transações na [primeira lição](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools/en).

## Transferência de ativos

![圖片](https://user-images.githubusercontent.com/52526645/211021954-6c5828be-7293-452b-8ef6-a268db54b932.png)
O seguinte pode ser derivado do exemplo do [Etherscan](https://etherscan.io/tx/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) acima:

- De: Endereço da carteira EOA de origem desta transação
- Interagiu com (Para): Contrato Tether USD (USDT)
- Tokens ERC-20 Transferidos: Transferência de 651,13 USDT da carteira do usuário A para o usuário B
- Dados de Entrada: Chamada da função de transferência

De acordo com o [Phalcon](https://phalcon.blocksec.com/tx/eth/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) "Fluxo de Invocação":

- Há apenas uma ''Chamada USDT.transfer''. No entanto, você deve prestar atenção ao "Valor". Como a Máquina Virtual Ethereum (EVM) não suporta operações de ponto flutuante, é usada uma representação decimal.
- Cada token tem sua própria precisão, o número de casas decimais usadas para representar o valor do token. Nos tokens ERC-20, as casas decimais geralmente têm 18 dígitos, enquanto o USDT tem 6 dígitos. Se a precisão do token não for tratada corretamente, problemas surgirão.
- Você pode consultar isso no contrato de token do Etherscan [token contract](https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7).

![圖片](https://user-images.githubusercontent.com/52526645/211123692-d7224ced-bc0b-47a1-a876-2af086e2fce9.png)

![圖片](https://user-images.githubusercontent.com/52526645/211022964-f819b35c-d442-488c-9645-7733af219d1c.png)

## Troca na Uniswap

![圖片](https://user-images.githubusercontent.com/52526645/211029091-c24963c7-d2f8-44f4-ad6a-a9185f98ec85.png)

O seguinte pode ser derivado do exemplo do [Etherscan](https://etherscan.io/tx/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) acima:

- Ação da Transação: Um usuário realiza uma troca na Uniswap V2, trocando 12.716 USDT por 7.118 UNDEAD.
- De: Endereço da carteira de origem desta transação
- Interagiu com (Para): Um contrato de Bot MEV chamado contrato Uniswap para troca.
- Tokens ERC-20 Transferidos: Processo de troca de tokens

De acordo com o [Phalcon](https://phalcon.blocksec.com/tx/eth/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) "Fluxo de Invocação":

- O Bot MEV chama o contrato de par de negociação Uniswap V2 USDT/UNDEAD para chamar a função de troca para realizar a troca de tokens.

![圖片](https://user-images.githubusercontent.com/52526645/211029737-4a606d32-2c96-41e9-aef7-82fe1fb4b21d.png)

### Foundry

Usamos o Foundry para simular a operação de trocar 1BTC por DAI na Uniswap.

- [Referência de código de exemplo](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2.sol), execute o seguinte comando:
```sh
forge test --contracts ./src/test/Uniswapv2.sol -vvvv
```
- De acordo com a figura - trocamos 1 BTC por 16.788 DAI chamando a função [swapExactTokensForTokens](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#swapexacttokensfortokens) do Uniswap\_v2\_router.

![圖片](https://user-images.githubusercontent.com/52526645/211143644-6ed295f0-e0d8-458b-a6a7-71b2da8a5baa.png)

## Curve 3pool - DAI/USDC/USDT

![圖片](https://user-images.githubusercontent.com/52526645/211030934-14fccba9-5239-480c-b431-21de393a6308.png)

O seguinte pode ser derivado do exemplo do [Etherscan](https://etherscan.io/tx/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) acima:

- O objetivo desta transação é adicionar liquidez às três pools do Curve.
- De: Endereço da carteira de origem desta transação
- Interagiu com (Para): Curve.fi: Pool DAI/USDC/USDT
- Tokens ERC-20 Transferidos: O usuário A transferiu 3.524.968,44 USDT para as três pools do Curve, e então o Curve emitiu 3.447.897,54 tokens 3Crv para o usuário A.

De acordo com o [Phalcon](https://phalcon.blocksec.com/tx/eth/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) "Fluxo de Invocação":

- Com base na sequência de chamadas, foram executadas três etapas:
1. add\_liquidity 2. transferFrom 3. mint.

![圖片](https://user-images.githubusercontent.com/52526645/211032540-b8ad83af-44cf-48ea-b22c-6c79d4dac1af.png)


## Proposta do Compound

![圖片](https://user-images.githubusercontent.com/52526645/211033609-60713c9d-1760-45d4-957f-a74e08abf9a5.png)

O seguinte pode ser derivado do exemplo do [Etherscan](https://etherscan.io/tx/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) acima:

- O usuário enviou uma proposta no Compound. O conteúdo da proposta pode ser visualizado clicando em "Decode Input Data" no Etherscan.

![圖片](https://user-images.githubusercontent.com/52526645/211033906-e3446f69-404e-4347-a0c6-e1b622039c5a.png)

De acordo com o [Phalcon](https://phalcon.blocksec.com/tx/eth/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) "Fluxo de Invocação":

- Enviar uma proposta através da função propose resulta na proposta número 44.

![圖片](https://user-images.githubusercontent.com/52526645/211034346-a600cbf4-eed9-47ca-8b5a-88232808f3a3.png)

## Uniswap Flashswap

Aqui usamos o Foundry para simular operações - como usar empréstimos flash na Uniswap. [Introdução oficial ao Flash swap](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)

- [Código de exemplo](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2_flashswap.sol) de referência, execute o seguinte comando:

```sh
forge test --contracts ./src/test/Uniswapv2_flashswap.sol -vv
```

![圖片](https://user-images.githubusercontent.com/52526645/211125357-695c3fd0-4a56-4a70-9c98-80bac65586b8.png)

- Neste exemplo, um empréstimo flash de 100 WETH é tomado emprestado através da troca Uniswap UNI/WETH. Observe que uma taxa de 0,3% deve ser paga nas devoluções.
- De acordo com a figura - fluxo de chamadas, o flashswap chama swap e depois paga chamando de volta uniswapV2Call.

![圖片](https://user-images.githubusercontent.com/52526645/211038895-a1bc681a-41cd-4900-a745-3d3ddd0237d4.png)

- Mais Introdução ao Flashloan e Flashswap:

  - A. Pontos comuns:
Ambos podem emprestar Tokens sem garantir ativos, e eles precisam ser devolvidos no mesmo bloco, caso contrário a transação falha.

  - B. A diferença:
Se o token0 for emprestado através do flashloan token0/token1, o token0 deve ser devolvido. O flashswap empresta o token0, e você pode devolver o token0 ou o token1, o que é mais flexível.

Para mais operações básicas de DeFi, consulte [DeFiLab](https://github.com/SunWeb3Sec/DeFiLabs).

## Cheatcodes do Foundry

Os cheatcodes do Foundry são essenciais para realizar análises de cadeia. Aqui, vou apresentar algumas funções comumente usadas. Mais informações podem ser encontradas no [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/).

- createSelectFork: Especifica uma rede e uma altura de bloco para copiar para testes. Deve incluir o RPC para cada cadeia em [foundry.toml](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/foundry.toml).
- deal: Define o saldo de uma carteira de teste.
  - Definir saldo de ETH:  `deal(address(this), 3 ether);`
  - Definir saldo de Token: `deal(address(USDC), address(this), 1 * 1e18);`
- prank: Simula a identidade de uma carteira especificada. É eficaz apenas para a próxima chamada e definirá o msg.sender para o endereço da carteira especificada. Por exemplo, simular uma transferência de uma carteira de baleia.
- startPrank: Simula a identidade de uma carteira especificada. Definirá o msg.sender para o endereço da carteira especificada para todas as chamadas até que `stopPrank()` seja executado.
- label: Rotula um endereço de carteira para melhorar a legibilidade ao usar o debug do Foundry.
- roll: Ajusta a altura do bloco.
- warp: Ajusta o timestamp do bloco.

Obrigado por acompanhar! Hora de avançar para a próxima lição.

## Recursos

[Livro do Foundry](https://book.getfoundry.sh/)

[Awesome-foundry](https://github.com/crisgarner/awesome-foundry)

[Flashloan vs Flashswap](https://blog.infura.io/post/build-a-flash-loan-arbitrage-bot-on-infura-part-i)
.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->