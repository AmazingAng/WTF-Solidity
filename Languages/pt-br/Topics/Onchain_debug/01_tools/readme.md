# Depuração de Transações OnChain: 1. Ferramentas

Autor: [SunSec](https://twitter.com/1nf0s3cpt)

Quando comecei a estudar análise de transações OnChain, havia poucos artigos educacionais relacionados, então tive que coletar informações por conta própria para descobrir como analisar e testar. Estamos lançando uma série de artigos de segurança Web3 para ajudar mais pessoas a se juntarem à segurança Web3 e criar uma rede segura.

Nesta primeira série, vamos apresentar como realizar análises OnChain e escrever reproduções de ataques. Essa habilidade ajudará você a analisar o processo de ataque, as razões das vulnerabilidades e até mesmo como os robôs de arbitragem funcionam!

## Primeiro, as ferramentas certas
Antes de começar a análise, vou apresentar algumas ferramentas comumente usadas. As ferramentas corretas podem ajudá-lo a ser mais eficiente em sua pesquisa.
### Ferramentas de depuração de transações
[Phalcon](https://phalcon.blocksec.com/) | [Tx.viewer](https://tx.eth.samczsun.com/) | [Cruise](https://cruise.supremacy.team/) | [Ethtx](https://ethtx.info/) | [Tenderly](https://dashboard.tenderly.co/explorer)

Ferramentas como o Transaction Viewer são as mais comumente usadas e podem nos ajudar a visualizar o fluxo de chamadas de função e os parâmetros passados para cada função em uma transação que queremos analisar.
Cada ferramenta é semelhante, diferindo apenas no suporte a diferentes blockchains e recursos auxiliares. Eu pessoalmente uso principalmente o Phalcon e o Transaction Viewer do Sam. Se encontrar uma blockchain não suportada, uso o Tenderly, que suporta a maioria das blockchains, mas não é tão conveniente em termos de legibilidade, exigindo uma análise mais lenta. No entanto, quando comecei a estudar análise OnChain, aprendi primeiro com o Ethtx e o Tenderly.

#### Comparação de suporte a blockchains

Phalcon: `Ethereum, BSC, Cronos, Avalanche C-Chain, Polygon`

Transaction Viewer do Sam: `Ethereum, Polygon, BSC, Avalanche C-Chain, Fantom, Arbitrum, Optimism`

Cruise: `Ethereum, BSC, Polygon, Arbitrum, Fantom, Optimism, Avalanche, Celo, Gnosis`

Ethtx: `Ethereum, Goerli testnet`

Tenderly: `Ethereum, Polygon, BSC, Sepolia, Goerli, Gnosis, POA, RSK, Avalanche C-Chain, Arbitrum, Optimism, Fantom, Moonbeam, Moonriver`

#### Operações práticas
Vamos usar o exemplo do evento JayPeggers - Insufficient validation + Reentrancy [link](https://github.com/SunWeb3Sec/DeFiHackLabs/#20221229---jay---insufficient-validation--reentrancy) e o [TXID](https://phalcon.blocksec.com/tx/eth/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6) para ilustrar o uso da ferramenta Phalcon desenvolvida pela Blocksec. Na imagem abaixo, você pode ver as informações básicas da transação e as mudanças no saldo. A partir das mudanças no saldo, você pode rapidamente ter uma ideia de quanto o atacante lucrou. Neste exemplo, o atacante lucrou 15,32 ETH.

![210571234-402d96aa-fe5e-4bc4-becc-190bd5a78e68-2](https://user-images.githubusercontent.com/107249780/210686382-cc02cc6a-b8ec-4cb7-ac19-402cd8ff86f6.png)

Invocation Flow: visualiza o fluxo de chamadas de função da transação, permitindo que saibamos quais transações foram chamadas, quais projetos estão envolvidos, quais funções foram chamadas e quais parâmetros e dados brutos foram passados.

![图片](https://user-images.githubusercontent.com/52526645/210572053-eafdf62a-7ebe-4caa-a905-045e792add2b.png)

O Phalcon 2.0 adicionou recursos de análise de fluxo de fundos, depuração e análise de código-fonte, permitindo que você veja trechos de código, parâmetros e valores de retorno durante o processo de rastreamento, facilitando a análise.

![image](https://user-images.githubusercontent.com/107249780/210821062-d1da8d1a-9615-4f1f-838d-34f27b9c3f41.png)

Vamos agora usar o Transaction Viewer do Sam para ver o [TXID](https://tx.eth.samczsun.com/ethereum/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6). É semelhante ao Phalcon, mas o Sam integrou muitas ferramentas menores nele. Ao clicar no ícone de olho, você pode ver as alterações no armazenamento e o gás consumido por cada chamada.

![210574290-790f6129-aa82-4152-b3e1-d21820524a0a-2](https://user-images.githubusercontent.com/107249780/210686653-f964a682-d2a7-4b49-bafc-c9a2b0fa2c55.png)

Clicando na chamada mais à esquerda, você pode tentar decodificar os dados brutos de entrada.

![图片](https://user-images.githubusercontent.com/52526645/210575619-89c8e8de-e2f9-4243-9646-0661b9483913.png)

Agora, vamos usar o Tenderly para ver o [TXID](https://dashboard.tenderly.co/tx/mainnet/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6). Na interface do Tenderly, você também pode ver as informações básicas, mas a parte de depuração não é visual, exigindo uma análise passo a passo. No entanto, a vantagem é que você pode depurar e ver o código-fonte e o processo de conversão dos dados brutos de entrada.

![图片](https://user-images.githubusercontent.com/52526645/210577802-c455545c-80d7-4f35-974a-dadbe59c626e.png)

Até aqui, podemos ter uma ideia geral do que essa transação está fazendo. Antes de começar a escrever um PoC, você pode se perguntar se é possível reproduzir rapidamente o ataque? Sim, é possível! Você pode usar o Tenderly ou o Phalcon, que suportam a reprodução de transações simuladas. Na parte superior direita da imagem acima, há um botão "Re-Simulate", que preencherá automaticamente os parâmetros da transação. A partir dos campos na imagem, você pode alterar qualquer coisa, como o número do bloco, o remetente, o valor, os dados brutos de entrada, etc.

![图片](https://user-images.githubusercontent.com/52526645/210580340-f2abf864-e540-4881-8482-f28030e5e35b.png)

### Banco de dados de assinaturas Ethereum

[4byte](https://www.4byte.directory/) | [sig.eth](https://sig.eth.samczsun.com/) | [etherface](https://www.etherface.io/hash)

Nos dados brutos de entrada, os primeiros 4 bytes são a assinatura da função. Às vezes, quando o Etherscan ou outras ferramentas de análise não conseguem decodificar, você pode usar o Banco de Dados de Assinaturas para verificar qual função pode ser.

Aqui está um exemplo em que não sabemos o que é `0xac9650d8` como função.
![图片](https://user-images.githubusercontent.com/52526645/210582149-61a6d973-b458-432f-b586-250c94c3ae24.png)

Ao consultar o sig.eth, podemos ver que a assinatura de 4 bytes é `multicall(bytes[])`.
![图片](https://user-images.githubusercontent.com/52526645/210583416-c31bbe07-fa03-4701-880d-0ae485b171f7.png)

### Ferramentas úteis

[ABI to interface](https://gnidan.github.io/abi-to-sol/) | [Get ABI for unverified contracts](https://abi.w1nt3r.xyz/) | [ETH Calldata Decoder](https://apoorvlathey.com/eth-calldata-decoder/) | [ETHCMD - Guess ABI](https://www.ethcmd.com/)

ABI to interface: ao desenvolver um PoC e precisar chamar outros contratos, você precisa de uma interface. Essa ferramenta pode ajudá-lo a gerar rapidamente a interface desejada. Basta copiar o ABI do Etherscan e colá-lo na ferramenta para obter a interface gerada.
[Exemplo](https://etherscan.io/address/0xb3da8d6da3ede239ccbf576ca0eaa74d86f0e9d3#code)

![图片](https://user-images.githubusercontent.com/52526645/210587442-e7853d8b-0613-426e-8a27-d70c80e2a42d.png)
![图片](https://user-images.githubusercontent.com/52526645/210587682-5fb07a01-2b21-41fa-9ed5-e7f45baa0b3e.png)

ETH Calldata Decoder: às vezes, quando você não tem o ABI, mas deseja ver os dados brutos de entrada, pode experimentar o ETH Calldata Decoder. Como mencionado anteriormente, a ferramenta do Sam também suporta a decodificação dos dados brutos de entrada.

![图片](https://user-images.githubusercontent.com/52526645/210585761-efd8b6f1-b901-485f-ae66-efaf9c84869c.png)

Get ABI for unverified contracts: se você encontrar um contrato não verificado, pode usar essa ferramenta para listar as assinaturas de função existentes nesse contrato.
[Exemplo](https://abi.w1nt3r.xyz/mainnet/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704)

![图片](https://user-images.githubusercontent.com/52526645/210588945-701b0e22-7390-4539-9d2f-e13479b52824.png)

### Ferramentas de descompilação
[Etherscan-decompile bytecode](https://etherscan.io/address/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704#code) | [Dedaub](https://library.dedaub.com/decompile) | [heimdall-rs](https://github.com/Jon-Becker/heimdall-rs)

O Etherscan possui uma função de descompilação embutida, mas a legibilidade é um pouco comprometida. Eu pessoalmente uso o Dedaub com mais frequência, pois é mais legível. Muitas pessoas me perguntam qual ferramenta eu uso para descompilar.
Vamos usar o exemplo de um MEV Bot que foi atacado [link](https://twitter.com/1nf0s3cpt/status/1577594615104172033)
Você pode tentar descompilar você mesmo [exemplo](https://bscscan.com/address/0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d#code)

Primeiro, copie o bytecode do contrato não verificado e cole-o no Dedaub. Em seguida, clique em "Decompile".
![截图 2023-01-05 上午10 33 15](https://user-images.githubusercontent.com/107249780/210688395-927c6126-b6c1-4c6d-a0c7-a3fea3db9cdb.png)

![图片](https://user-images.githubusercontent.com/52526645/210591478-6fa928f3-455d-42b5-a1ac-6694f97386c2.png)

Por enquanto, é isso para a primeira lição. Se você quiser aprender mais, pode consultar os recursos de aprendizado abaixo.
---
## Recursos de aprendizado
[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/
.

