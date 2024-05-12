# Depuração de Transações OnChain: 2. Aquecimento

Autor: [Sun](https://twitter.com/1nf0s3cpt)

As transações on-chain incluem transferências simples de uma única transação, interações de contratos DeFi, interações de vários contratos DeFi, arbitragem de empréstimo relâmpago, propostas de governança, transações cross-chain, etc. Nesta seção, vamos começar com um aquecimento, começando com algo simples. Vou explicar quais informações do explorador de blockchain Etherscan geralmente são relevantes para nós e, em seguida, usaremos a ferramenta de análise de transações [Phalcon](https://phalcon.blocksec.com/) para analisar essas transações, desde transferências simples, swaps na UniSWAP, adição de liquidez no Curve 3pool, propostas de governança no Compound e diferenças nas chamadas de empréstimo relâmpago.

## Começando com o aquecimento
- Primeiro, você precisa instalar o [Foundry](https://github.com/foundry-rs/foundry) no ambiente. Consulte as [instruções](https://book.getfoundry.sh/getting-started/installation.html) para saber como instalar.
    - O teste principal será feito com o [Forge test](https://book.getfoundry.sh/reference/forge/forge-test). Se você estiver usando o Foundry pela primeira vez, consulte o [Foundry book](https://book.getfoundry.sh/), [Foundry @EthCC](https://www.youtube.com/watch?v=wJnywGB33O4) e [WTF Solidity - Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)
- Cada blockchain tem seu próprio explorador de blockchain. Nesta seção, usaremos a rede principal Ethereum como exemplo e faremos a análise através do Etherscan.
- Geralmente, os campos que eu gostaria de ver incluem:
    - Transaction Action: Como as transferências de tokens ERC-20 podem ser complicadas em transações complexas e de difícil leitura, podemos usar a Transaction Action para ver as ações-chave, mas nem todas as transações têm esse campo.
    - From: O endereço da carteira de origem que executou a transação (msg.sender)
    - Interacted With (To): O contrato com o qual houve interação
    - ERC-20 Tokens Transferred: O processo de transferência de tokens
    - Input Data: Os dados de entrada originais da transação, que mostram qual função foi chamada e quais valores foram passados
- Se você ainda não sabe quais ferramentas comumente usadas, pode revisar a primeira aula sobre [ferramentas de análise de transações](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools)

## Transferência on-chain
![Imagem](https://user-images.githubusercontent.com/52526645/211021954-6c5828be-7293-452b-8ef6-a268db54b932.png)
A partir do [exemplo](https://etherscan.io/tx/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) acima, podemos interpretar da seguinte forma:

From: Endereço da carteira de origem que enviou a transação

Interacted With (To): Contrato Tether USD (USDT)

ERC-20 Tokens Transferred: Transferência de 651,13 USDT da carteira do usuário A para a carteira do usuário B

Input Data: Chamada da função transfer

Podemos usar o [phalcon](https://phalcon.blocksec.com/tx/eth/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) para ver que há apenas uma chamada `Call USDT.transfer` no fluxo de chamadas. É importante observar o valor. Como a EVM não suporta operações com números de ponto flutuante, a precisão é usada para representar os valores. Cada token tem sua própria precisão, e é importante prestar atenção ao tamanho da precisão. O padrão ERC-20 tem uma precisão de 18, mas há exceções, como o USDT, que tem uma precisão de 6. Portanto, o valor passado é 651130000. Se a precisão não for tratada corretamente, podem ocorrer problemas. Você pode verificar a precisão consultando o contrato do token no [Etherscan](https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7).

![Imagem](https://user-images.githubusercontent.com/52526645/211123692-d7224ced-bc0b-47a1-a876-2af086e2fce9.png)

![Imagem](https://user-images.githubusercontent.com/52526645/211022964-f819b35c-d442-488c-9645-7733af219d1c.png)

## Swap na Uniswap

![Imagem](https://user-images.githubusercontent.com/52526645/211029091-c24963c7-d2f8-44f4-ad6a-a9185f98ec85.png)

A partir do [exemplo](https://etherscan.io/tx/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) acima, podemos interpretar da seguinte forma:

Transaction Action: É óbvio que o usuário está fazendo um swap na Uniswap, trocando 12.716 USDT por 7.118 UNDEAD.

From: Endereço da carteira de origem que enviou a transação

Interacted With (To): Neste exemplo, é um contrato MEV Bot que chama o contrato Uniswap

ERC-20 Tokens Transferred: O processo de troca de tokens

Podemos usar o [phalcon](https://phalcon.blocksec.com/tx/eth/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) para ver que o MEV Bot chama o contrato do par de negociação Uniswap V2 USDT/UNDEAD e chama a função [swap](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/pair#swap-1) para trocar os tokens.

![Imagem](https://user-images.githubusercontent.com/52526645/211029737-4a606d32-2c96-41e9-aef7-82fe1fb4b21d.png)

Usamos o Foundry para simular a operação de trocar 1 BTC por DAI na Uniswap. Consulte o [código de exemplo](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2.sol) e execute o seguinte comando:
```sh
forge test --contracts ./src/test/Uniswapv2.sol -vvvv
```

Como mostrado na imagem abaixo, usamos a função Uniswap_v2_router.[swapExactTokensForTokens](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#swapexacttokensfortokens) para trocar 1 BTC por 16.788 DAI.

![Imagem](https://user-images.githubusercontent.com/52526645/211143644-6ed295f0-e0d8-458b-a6a7-71b2da8a5baa.png)

## Curve 3pool - DAI/USDC/USDT

![Imagem](https://user-images.githubusercontent.com/52526645/211030934-14fccba9-5239-480c-b431-21de393a6308.png)

A partir do [exemplo](https://etherscan.io/tx/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) acima, podemos interpretar da seguinte forma:

Adicionando liquidez no Curve 3pool

From: Endereço da carteira de origem que enviou a transação

Interacted With (To): Pool DAI/USDC/USDT do Curve.fi

ERC-20 Tokens Transferred: O usuário A depositou 3.524.968,44 USDT no Curve 3pool e o Curve emitiu 3.447.897,54 tokens 3Crv para o usuário A.

Podemos usar o [phalcon](https://phalcon.blocksec.com/tx/eth/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) para ver que foram executadas três etapas: 1. add_liquidity 2. transferFrom 3. mint

![Imagem](https://user-images.githubusercontent.com/52526645/211032540-b8ad83af-44cf-48ea-b22c-6c79d4dac1af.png)

## Proposta no Compound

![Imagem](https://user-images.githubusercontent.com/52526645/211033609-60713c9d-1760-45d4-957f-a74e08abf9a5.png)

A partir do [exemplo](https://etherscan.io/tx/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) acima, podemos interpretar da seguinte forma: O usuário enviou uma proposta para o contrato de governança do Compound e você pode ver o conteúdo da proposta clicando em "Decode Input Data" no Etherscan.

![Imagem](https://user-images.githubusercontent.com/52526645/211033906-e3446f69-404e-4347-a0c6-e1b622039c5a.png)

Podemos usar o [phalcon](https://phalcon.blocksec.com/tx/eth/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) para ver que a proposta foi enviada chamando a função propose e obteve o número da proposta 44.

![Imagem](https://user-images.githubusercontent.com/52526645/211034346-a600cbf4-eed9-47ca-8b5a-88232808f3a3.png)

## Flashswap na Uniswap

Aqui, usamos o Foundry para simular como usar um flashswap na Uniswap. Consulte a [introdução oficial ao Flash swap](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps) e o [código de exemplo](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2_flashswap.sol).

![Imagem](https://user-images.githubusercontent.com/52526645/211125357-695c3fd0-4a56-4a70-9c98-80bac65586b8.png)

```sh
forge test --contracts ./src/test/Uniswapv2_flashswap.sol -vv
```
Neste exemplo, usamos um flashswap na Uniswap para emprestar 100 WETH e depois devolvê-lo à Uniswap. Observe que uma taxa de 0,3% deve ser paga ao devolver.

A partir do fluxo de chamadas abaixo, podemos ver que a função swap é chamada para fazer o flashswap e, em seguida, a função de retorno uniswapV2Call é usada para devolver o empréstimo.

![Imagem](https://user-images.githubusercontent.com/52526645/211038895-a1bc681a-41cd-4900-a745-3d3ddd0237d4.png)

Vamos diferenciar brevemente a diferença entre Flashloan e Flashswap. Ambos permitem emprestar tokens sem a necessidade de garantia e devolvê-los na mesma transação, caso contrário, a transação falhará. No caso de um flashloan, se você emprestar token0 usando token1, precisará devolver token0. No caso de um flashswap, se você emprestar token0, poderá devolver token0 ou token1. É mais flexível.

Para mais operações básicas de DeFi, consulte [DeFiLabs](https://github.com/SunWeb3Sec/DeFiLabs)


## Cheatcodes do Foundry

Os cheatcodes do Foundry são essenciais para análise on-chain. Aqui, vou apresentar algumas funções comumente usadas. Para mais informações, consulte a [Referência de Cheatcodes](https://book.getfoundry.sh/cheatcodes/)

- createSelectFork: Especifica qual rede e altura do bloco devem ser copiadas para o teste. Observe que o RPC de cada blockchain deve ser definido no arquivo [foundry.toml](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/foundry.toml)
- deal: Define o saldo da carteira de teste
    - Define o saldo de ETH `deal(address(this), 3 ether);`
    - Define o saldo de tokens `deal(address(USDC), address(this), 1 * 1e18);`
- prank: Simula a identidade de uma carteira específica. Somente a próxima chamada será afetada. O próximo msg.sender será o endereço da carteira especificada. Por exemplo, simular uma transferência usando uma carteira de baleia.
- startPrank: Simula a identidade de uma carteira específica. Até que `stopPrank()` seja executado, todos os msg.sender serão o endereço da carteira especificada.
- label: Rotula um endereço de carteira para facilitar a leitura durante a depuração com o Foundry
- roll: Ajusta a altura do bloco
- warp: Ajusta o block.timestamp

Obrigado por assistir, estamos prontos para a próxima aula.

## Recursos
[Foundry book](https://book.getfoundry.sh/)

[Awesome-foundry](https://github.com/crisgarner/awesome-foundry)

[Foundry @EthCC](https://www.youtube.com/watch?v=wJnywGB33O4) | [Slides](https://docs.google.com/presentation/d/1AuQojnFMkozOiR8kDu5LlWT7vv1EfPytmVEeq1XMtM0/edit#slide=id.g13d8bd167cb_0_0)

[WTF Solidity - Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)

[Flashloan vs Flashswap](https://blog.infura.io/post/build-a-flash-loan-arbitrage-bot-on-infura-part-i)
.

