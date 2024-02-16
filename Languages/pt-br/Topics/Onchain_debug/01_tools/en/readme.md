# Depuração de Transações OnChain: 1. Ferramentas

Autor: [SunSec](https://twitter.com/1nf0s3cpt)

Os recursos online eram escassos quando comecei a aprender análise de transações OnChain. Embora lentamente, consegui reunir informações fragmentadas para realizar testes e análises.

A partir dos meus estudos, lançaremos uma série de artigos de segurança Web3 para incentivar mais pessoas a ingressarem na segurança Web3 e criar uma rede segura juntos.

Na primeira série, vamos apresentar como realizar uma análise OnChain e, em seguida, reproduziremos ataque(s) OnChain. Essa habilidade nos ajudará a entender o processo de ataque, a causa raiz da vulnerabilidade e até mesmo como o robô de arbitragem faz arbitragem!

## Ferramentas podem melhorar muito a eficiência
Antes de entrar na análise, permita-me apresentar algumas ferramentas comuns. As ferramentas certas podem ajudá-lo a fazer pesquisas de forma mais eficiente.

### Ferramentas de depuração de transações
[Phalcon](https://phalcon.blocksec.com/) | [Tx.viewer](https://tx.eth.samczsun.com/) | [Cruise](https://cruise.supremacy.team/) | [Ethtx](https://ethtx.info/) | [Tenderly](https://dashboard.tenderly.co/explorer)

O Transaction Viewer é a ferramenta mais comumente usada, ele é capaz de listar o rastreamento de chamadas de função e os dados de entrada em cada função durante a transação. As ferramentas de visualização de transações são todas semelhantes; a diferença principal é o suporte de cadeia e o suporte de funções auxiliares. Eu pessoalmente uso o Phalcon e o Transaction Viewer do Sam. Se eu encontrar cadeias não suportadas, usarei o Tenderly. O Tenderly suporta a maioria das cadeias, mas a legibilidade é limitada e a análise pode ser lenta usando sua função de depuração. No entanto, é uma das primeiras ferramentas que aprendi junto com o Ethtx.

#### Comparação de suporte de cadeia

Phalcon: `Ethereum, BSC, Cronos, Avalanche C-Chain, Polygon`

Transaction viewer do Sam: `Ethereum, Polygon, BSC, Avalanche C-Chain, Fantom, Arbitrum, Optimism`

Cruise: `Ethereum, BSC, Polygon, Arbitrum, Fantom, Optimism, Avalanche, Celo, Gnosis`

Ethtx: `Ethereum, Goerli testnet`

Tendery: `Ethereum, Polygon, BSC, Sepolia, Goerli, Gnosis, POA, RSK, Avalanche C-Chain, Arbitrum, Optimism, Fantom, Moonbeam, Moonriver`

#### Laboratório
Vamos analisar o incidente JayPeggers - Validação Insuficiente + Reentrância como exemplo de transação [TXID](https://phalcon.blocksec.com/tx/eth/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6) para dissecar.

Primeiro, uso a ferramenta Phalcon desenvolvida pela Blocksec para ilustrar. As informações básicas e as alterações de saldo da transação podem ser vistas na figura abaixo. A partir das alterações de saldo, podemos ver rapidamente quanto lucro o atacante obteve. Neste exemplo, o atacante obteve um lucro de 15,32 ETH.

![210571234-402d96aa-fe5e-4bc4-becc-190bd5a78e68-2](https://user-images.githubusercontent.com/107249780/210686382-cc02cc6a-b8ec-4cb7-ac19-402cd8ff86f6.png)

Visualização do Fluxo de Chamadas - É uma invocação de função com informações de rastreamento e logs de eventos. Ele nos mostra a invocação da chamada, o nível de chamada de função desta transação, se foi usado um flash loan, quais projetos estão envolvidos, quais funções são chamadas e quais parâmetros e dados brutos são trazidos, etc.

![圖片](https://user-images.githubusercontent.com/52526645/210572053-eafdf62a-7ebe-4caa-a905-045e792add2b.png)

O Phalcon 2.0 adicionou fluxo de fundos, e a análise de código-fonte + depuração mostra diretamente o código-fonte, os parâmetros e os valores de retorno juntamente com o rastreamento, o que é mais conveniente para análise.

![image](https://user-images.githubusercontent.com/107249780/210821062-d1da8d1a-9615-4f1f-838d-34f27b9c3f41.png)

Agora vamos experimentar o Transaction Viewer do Sam na mesma [TXID](https://tx.eth.samczsun.com/ethereum/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6). O Sam integra muitas ferramentas nele, como mostrado na imagem abaixo, você pode ver a alteração no Storage e o Gás consumido por cada chamada.

![210574290-790f6129-aa82-4152-b3e1-d21820524a0a-2](https://user-images.githubusercontent.com/107249780/210686653-f964a682-d2a7-4b49-bafc-c9a2b0fa2c55.png)

Clique em Call à esquerda para decodificar os dados de entrada brutos.

![圖片](https://user-images.githubusercontent.com/52526645/210575619-89c8e8de-e2f9-4243-9646-0661b9483913.png)

Agora vamos mudar para o Tendery para analisar a mesma [TXID](https://dashboard.tenderly.co/tx/mainnet/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6), você pode ver as informações básicas como outras ferramentas. Mas usando a função de depuração, não é visualizado e precisa ser analisado passo a passo. No entanto, a vantagem é que você pode visualizar o código e o processo de conversão dos dados de entrada durante a depuração.

![圖片](https://user-images.githubusercontent.com/52526645/210577802-c455545c-80d7-4f35-974a-dadbe59c626e.png)

Isso pode nos ajudar a esclarecer todas as coisas que essa transação fez. Antes de escrever o POC, podemos executar um ataque de replay? Sim! Tanto o Tendery quanto o Phalcon suportam transações simuladas, você pode encontrar um botão Re-Simulate no canto superior direito na figura acima. A ferramenta preencherá automaticamente os valores dos parâmetros da transação para você, como mostrado na figura abaixo. Os parâmetros podem ser alterados arbitrariamente de acordo com as necessidades de simulação, como alterar o número do bloco, From, Gas, dados de entrada, etc.

![圖片](https://user-images.githubusercontent.com/52526645/210580340-f2abf864-e540-4881-8482-f28030e5e35b.png)

### Banco de Dados de Assinaturas Ethereum

[4byte](https://www.4byte.directory/) | [sig.eth](https://sig.eth.samczsun.com/) | [etherface](https://www.etherface.io/hash)

Nos dados de entrada brutos, os primeiros 4 bytes são Assinaturas de Função. Às vezes, se o Etherscan ou as ferramentas de análise não conseguem identificar a função, podemos verificar as possíveis Funções por meio do Banco de Dados de Assinaturas.

O exemplo a seguir assume que não sabemos qual é a Função `0xac9650d8`

![圖片](https://user-images.githubusercontent.com/52526645/210582149-61a6d973-b458-432f-b586-250c94c3ae24.png)

Através de uma consulta no sig.eth, descobrimos que a assinatura de 4 bytes é `multicall(bytes[])`

![圖片](https://user-images.githubusercontent.com/52526645/210583416-c31bbe07-fa03-4701-880d-0ae485b171f7.png)

### Ferramentas úteis

[ABI para interface](https://gnidan.github.io/abi-to-sol/) | [Obter ABI para contratos não verificados](https://abi.w1nt3r.xyz/) | [Decodificador de Calldata ETH](https://apoorvlathey.com/eth-calldata-decoder/) | [ETHCMD - Adivinhar ABI](https://www.ethcmd.com/)

ABI para interface: Ao desenvolver um POC, você precisa chamar outros contratos, mas precisa de uma interface. Podemos usar essa ferramenta para ajudá-lo a gerar rapidamente as interfaces. Vá para o Etherscan para copiar o ABI e cole-o na ferramenta para ver a Interface gerada. [Exemplo](https://etherscan.io/address/0xb3da8d6da3ede239ccbf576ca0eaa74d86f0e9d3#code).

![圖片](https://user-images.githubusercontent.com/52526645/210587442-e7853d8b-0613-426e-8a27-d70c80e2a42d.png)
![圖片](https://user-images.githubusercontent.com/52526645/210587682-5fb07a01-2b21-41fa-9ed5-e7f45baa0b3e.png)

Decodificador de Calldata ETH: Se você deseja decodificar dados de entrada sem o ABI, esta é a ferramenta que você precisa. O Transaction Viewer do Sam que mencionei anteriormente também suporta a decodificação de dados de entrada.

![圖片](https://user-images.githubusercontent.com/52526645/210585761-efd8b6f1-b901-485f-ae66-efaf9c84869c.png)

Obter ABI para contratos não verificados: Se você encontrar um contrato que não foi verificado, pode usar essa ferramenta para tentar descobrir as assinaturas de função. [Exemplo](https://abi.w1nt3r.xyz/mainnet/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704)

![圖片](https://user-images.githubusercontent.com/52526645/210588945-701b0e22-7390-4539-9d2f-e13479b52824.png)

### Ferramentas de descompilação
[Etherscan - descompilar bytecode](https://etherscan.io/address/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704#code) | [Dedaub](https://library.dedaub.com/decompile) | [heimdall-rs](https://github.com/Jon-Becker/heimdall-rs)

O Etherscan possui um recurso de descompilação embutido, mas a legibilidade do resultado geralmente é ruim. Pessoalmente, costumo usar o Dedaub, que produz um código descompilado melhor. É o meu descompilador recomendado. Vamos usar um MEV Bot sendo atacado como exemplo. Você pode tentar descompilá-lo por conta própria usando este [contrato](https://twitter.com/1nf0s3cpt/status/1577594615104172033).

Primeiro, copie os Bytecodes do contrato não verificado e cole-os no Dedaub, e clique em Decompile.

![截圖 2023-01-05 上午10 33 15](https://user-images.githubusercontent.com/107249780/210688395-927c6126-b6c1-4c6d-a0c7-a3fea3db9cdb.png)

![圖片](https://user-images.githubusercontent.com/52526645/210591478-6fa928f3-455d-42b5-a1ac-6694f97386c2.png)

Se você quiser aprender mais, pode consultar os seguintes vídeos.

## Recursos
[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/

.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->