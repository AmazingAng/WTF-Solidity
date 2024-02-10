# 54. Ponte Interchain

Recentemente, tenho revisitado o estudo do Solidity para reforçar alguns detalhes e escrever um "Guia Simplificado do Solidity" para iniciantes (os programadores mais avançados podem buscar outras fontes de ensino). Atualizo o guia com 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial da wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, introduziremos o conceito de Ponte Interchain, uma infraestrutura que permite a transferência de ativos digitais e informações entre duas ou mais blockchains, e construiremos uma ponte interchain simples.

## 1. O que é uma Ponte Interchain

Uma Ponte Interchain é um protocolo blockchain que permite mover ativos digitais e informações entre duas ou mais blockchains. Por exemplo, um token ERC20 funcionando na rede principal do Ethereum pode ser transferido para uma sidechain ou blockchain independente compatível com o Ethereum usando uma Ponte Interchain.

É importante ressaltar que as operações de cross-chain não são nativamente suportadas pelas blockchains, exigindo a intervenção de uma terceira parte confiável para executar as transações, o que também traz riscos. Nos últimos dois anos, ataques às Pontes Interchain resultaram em perdas de mais de **20 bilhões de dólares** em ativos dos usuários.

## 2. Tipos de Pontes Interchain

As Pontes Interchain geralmente se enquadram em três categorias principais:

- **Burn/Mint**: Neste método, os tokens na blockchain de origem são queimados e, em seguida, um número equivalente de tokens é criado na blockchain de destino. Esta abordagem mantém o suprimento total de tokens inalterado, mas requer que a Ponte Interchain tenha permissão para criar novos tokens. É adequado para projetos construírem suas próprias Pontes Interchain.

- **Stake/Mint**: Neste método, os tokens na blockchain de origem são bloqueados (stake) e, em seguida, uma quantidade equivalente de tokens (tokens-fichas) é criada na blockchain de destino. Os tokens na blockchain de origem permanecem bloqueados até que os tokens-fichas sejam transferidos de volta. Essa é a abordagem mais comum para Pontes Interchain e não exige nenhuma permissão especial, mas apresenta riscos. Se os ativos na blockchain de origem forem alvos de ataques hackers, os tokens-fichas na blockchain de destino se tornarão inúteis.

- **Stake/Unstake**: Neste método, os tokens na blockchain de origem são bloqueados (stake) e, em seguida, são liberados (unstake) uma quantidade equivalente de tokens na blockchain de destino. Os tokens na blockchain de destino podem ser trocados de volta pelos tokens na blockchain de origem a qualquer momento. Este método exige que a Ponte Interchain tenha tokens bloqueados em ambas as blockchains, tornando-o mais complexo e com uma barreira de entrada mais alta. Geralmente, os usuários são incentivados a bloquear tokens na Ponte Interchain.

## 3. Construindo uma Ponte Interchain Simples

Para entender melhor o conceito de Ponte Interchain, construiremos uma ponte interchain simples que permite a transferência de tokens ERC20 entre a rede de testes Goerli e a rede de testes Sepolia. Utilizaremos o método de queima/emissão (burn/mint), onde os tokens na blockchain de origem (Goerli) serão queimados e tokens equivalentes na blockchain de destino (Sepolia) serão criados. Esta ponte interchain será composta por um contrato inteligente (implantado em ambas as blockchains) e um script em Ethers.js.

Por favor, note que esta é uma implementação muito básica de uma Ponte Interchain, utilizada apenas para fins educacionais. Ela não trata de problemas como transações falhas, reorganização de blockchains, entre outros. Em ambiente de produção, recomenda-se o uso de soluções de Pontes Interchain profissionais ou frameworks auditados.

### 3.1 Contrato de token cross-chain

Primeiro, precisamos implantar um contrato de token ERC20, `CrossChainToken`, nas redes de teste Goerli e Sepolia. Este contrato define o nome, símbolo e fornecimento total do token, bem como uma função `bridge()` para transferências cross-chain.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainToken is ERC20, Ownable {
    
    // Evento Bridge
    event Bridge(address indexed user, uint256 amount);
    // Evento Mint
    event Mint(address indexed to, uint256 amount);

    /**
     * @param name Nome do Token
     * @param symbol Símbolo do Token
     * @param totalSupply Fornecimento total do Token
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }

    /**
     * Função bridge
     * @param amount: quantidade de tokens a serem queimados na cadeia atual e criados na outra cadeia
     */
    function bridge(uint256 amount) public {
        _burn(msg.sender, amount);
        emit Bridge(msg.sender, amount);
    }

    /**
     * Função mint
     */
    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
        emit  Mint(to, amount);
    }
}
```

Este contrato possui três funções principais:

- `constructor()`: O construtor, que será chamado uma vez ao implantar o contrato, é usado para inicializar o nome, símbolo e fornecimento total do token.

- `bridge()`: O usuário chama esta função para realizar uma transferência cross-chain. Ela irá destruir a quantidade de tokens especificada pelo usuário e emitir o evento `Bridge`.

- `mint()`: Apenas o proprietário do contrato pode chamar esta função para lidar com eventos cross-chain e emitir o evento `Mint`. Quando o usuário chama a função `bridge()` em outra cadeia para destruir o token, o script irá ouvir o evento `Bridge` e criar o token para o usuário na cadeia de destino.

### 3.2 Script cross-chain

Com o contrato de token no lugar, precisamos de um servidor para lidar com eventos cross-chain. Podemos escrever um script ethers.js (versão v6) para ouvir o evento `Bridge` e, quando o evento for acionado, criar a mesma quantidade de tokens na cadeia de destino. Se você não conhece o Ethers.js, pode ler o [WTF Ethers Minimalist Tutorial](https://github.com/WTFAcademy/WTF-Ethers).

```javascript
import { ethers } from "ethers";

// Inicialize os provedores das duas cadeias
const providerGoerli = new ethers.JsonRpcProvider("Goerli_Provider_URL");
const providerSepolia = new ethers.JsonRpcProvider("Sepolia_Provider_URL://eth-sepolia.g.alchemy.com/v2/RgxsjQdKTawszh80TpJ-14Y8tY7cx5W2");

// Inicialize os signatários das duas cadeias
// privateKey preenche a chave privada da carteira do administrador
const privateKey = "Your_Key";
const walletGoerli = new ethers.Wallet(privateKey, providerGoerli);
const walletSepolia = new ethers.Wallet(privateKey, providerSepolia);

// Endereço do contrato e ABI
const contractAddressGoerli = "0xa2950F56e2Ca63bCdbA422c8d8EF9fC19bcF20DD";
const contractAddressSepolia = "0xad20993E1709ed13790b321bbeb0752E50b8Ce69";

const abi = [
    "event Bridge(address indexed user, uint256 amount)",
    "function bridge(uint256 amount) public",
    "function mint(address to, uint amount) external",
];

// Inicialize a instância do contrato
const contractGoerli = new ethers.Contract(contractAddressGoerli, abi, walletGoerli);
const contractSepolia = new ethers.Contract(contractAddressSepolia, abi, walletSepolia);

const main = async () => {
     try{
         console.log(`Iniciando a escuta de eventos cross-chain`)

         // Escute o evento Bridge da cadeia Sepolia e, em seguida, execute a operação de mint em Goerli para completar a transferência cross-chain
         contractSepolia.on("Bridge", async (user, amount) => {
             console.log(`Evento Bridge na cadeia Sepolia: Usuário ${user} queimou ${amount} tokens`);

             // Executando a operação de burn
             let tx = await contractGoerli.mint(user, amount);
             await tx.wait();

             console.log(`Criados ${amount} tokens para ${user} na cadeia Goerli`);
         });

       // Escute o evento Bridge da cadeia Goerli e, em seguida, execute a operação de mint em Sepolia para completar a transferência cross-chain
         contractGoerli.on("Bridge", async (user, amount) => {
             console.log(`Evento Bridge na cadeia Goerli: Usuário ${user} queimou ${amount} tokens`);

             // Executando a operação de burn
            let tx = await contractSepolia.mint(user, amount);
            await tx.wait();

            console.log(`Criados ${amount} tokens para ${user} na cadeia Sepolia`);
        });

    }catch(e){
        console.log(e);
    
    } 
}

main();
```

## Reaparecimento no Remix

1. Implante o contrato `CrossChainToken` nas cadeias de teste Goerli e Sepolia, respectivamente. O contrato irá automaticamente criar 10.000 tokens para nós.

     ![](./img/54-4.png)

2. Complete a URL do nó RPC e a chave privada do administrador no script cross-chain `crosschain.js`, preencha os endereços dos contratos de token implantados em Goerli e Sepolia nos locais correspondentes e execute o script.

3. Chame a função `bridge()` do contrato de token na cadeia Goerli para realizar uma transferência cross-chain de 100 tokens.

     ![](./img/54-6.png)

4. O script escuta o evento cross-chain e cria 100 tokens na cadeia Sepolia.

     ![](./img/54-7.png)

5. Chame `balance()` na cadeia Sepolia para verificar o saldo e verifique que o saldo do token foi alterado para 10.100. A transferência cross-chain foi bem-sucedida!

     ![](./img/54-8.png)

## Resumo

Nesta palestra, apresentamos a ponte cross-chain, que permite a transferência de ativos digitais e informações entre duas ou mais blockchains, facilitando a operação de ativos em várias cadeias para os usuários. Ao mesmo tempo, também carrega grandes riscos. Ataques às pontes cross-chain nos últimos dois anos causaram perdas de mais de **2 bilhões de dólares americanos** em ativos dos usuários. Neste tutorial, construímos uma ponte cross-chain simples e implementamos a transferência de tokens ERC20 entre a rede de teste Goerli e a rede de teste Sepolia. Acredito que, através deste tutorial, você terá uma compreensão mais profunda das pontes cross-chain.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->