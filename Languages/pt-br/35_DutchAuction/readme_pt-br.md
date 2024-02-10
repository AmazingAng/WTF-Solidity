# 35. Leilão Holandês

Recentemente, tenho revisado meus conhecimentos de Solidity para consolidar detalhes e escrever um tutorial "Introdução Simplificada ao Solidity" para iniciantes (os programadores avançados podem buscar outro tutorial). Atualizarei o tutorial com 1-3 lições por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Junte-se à comunidade WTF Scientist para obter informações sobre como entrar no grupo do WhatsApp: [Link](https://discord.gg/5akcruXrsk)

Todo o código e tutorial estão disponíveis no Github (Cursos certificados após 1024 estrelas, comunidade NFT após 2048 estrelas): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta lição, vou falar sobre o leilão holandês e como usar o contrato simplificado `DutchAuction` para vender tokens não fungíveis (NFTs) do padrão ERC721 por meio de um leilão holandês.

## Leilão Holandês

O leilão holandês é uma forma especial de leilão em que o preço do lance do item leiloado é gradualmente reduzido do mais alto para o mais baixo até que o primeiro comprador faça um lance igual ou superior ao preço de reserva para confirmar a venda.

![Leilão Holandês](./img/35-1.png)

No mundo das criptomoedas, muitos NFTs são vendidos por meio de um leilão holandês, como o caso do "Azuki" e "World of Women". O "Azuki" conseguiu arrecadar mais de 8000 ETH por meio de um leilão holandês.

Os projetos gostam muito desse formato de leilão por dois motivos principais:

1. O preço no leilão holandês diminui gradualmente, permitindo que o projeto arrecade a receita máxima.
2. O leilão dura um período prolongado (geralmente mais de 6 horas), o que evita a "guerra de gas".

## Contrato `DutchAuction`

O código é baseado no contrato `Azuki` simplificado [código](https://etherscan.io/address/0xed5af388653567af2f388e6224dc7c4b3241c544#code). O contrato `DutchAuction` herda os contratos `ERC721` e `Ownable` previamente apresentados:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/ERC721.sol";

contract DutchAuction is Ownable, ERC721 {
```

### Variáveis de Estado do `DutchAuction`

Há um total de 9 variáveis de estado no contrato, sendo 6 relacionadas ao leilão. Elas são:

- `COLLECTOIN_SIZE`: total de NFTs.
- `AUCTION_START_PRICE`: preço inicial e mais alto do leilão holandês.
- `AUCTION_END_PRICE`: preço final e mais baixo do leilão holandês.
- `AUCTION_TIME`: duração do leilão.
- `AUCTION_DROP_INTERVAL`: intervalo de tempo para a redução do preço.
- `auctionStartTime`: timestamp de início do leilão (utilizando `block.timestamp`).

```solidity
    uint256 public constant COLLECTOIN_SIZE = 10000; // Total de NFTs
    uint256 public constant AUCTION_START_PRICE = 1 ether; // Preço inicial (mais alto)
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // Preço final (mais baixo)
    uint256 public constant AUCTION_TIME = 10 minutes; // Duração do leilão, apenas para fins de teste
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; // Intervalo de redução de preço
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_TIME / AUCTION_DROP_INTERVAL); // Passo de redução de preço por vez
    
    uint256 public auctionStartTime; // Timestamp de início do leilão
    string private _baseTokenURI;   // URI de metadados
    uint256[] private _allTokens; // Lista de todos os tokens existentes
```

### Funções do `DutchAuction`

Existem 9 funções no contrato DutchAuction, com foco nas relacionadas ao leilão. Não irei repetir as funções relacionadas ao ERC721, apenas focarei nas relacionadas ao leilão.

- Definir o timestamp de início do leilão: No construtor do contrato, o timestamp de início é definido como o timestamp do bloco atual. O proprietário do contrato também pode ajustar o timestamp de início através da função `setAuctionStartTime()`.

```solidity
    constructor() ERC721("WTF Dutch Auction", "WTF Dutch Auction") {
        auctionStartTime = block.timestamp;
    }

    // Função para configurar o timestamp de início do leilão, apenasOwner
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }
```

- Obter o preço atual do leilão: A função `getAuctionPrice()` calcula o preço do leilão com base no timestamp atual e nas variáveis relacionadas ao leilão.

Se o `block.timestamp` for menor que o timestamp de início, o preço será o preço inicial `AUCTION_START_PRICE`;
Se o `block.timestamp` for maior que o tempo definido para o final do leilão, o preço será o preço final `AUCTION_END_PRICE`;
Caso contrário, o preço será calculado com base na redução gradual do preço.

```solidity
    // Função para obter o preço atual do leilão
    function getAuctionPrice() public view returns (uint256) {
        if (block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        } else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }
```

- Leilão e criação de NFTs: Os usuários podem participar do leilão e criar NFTs através da função `auctionMint()`. Essa função verifica se o leilão já começou e se a quantidade a ser criada não excede o limite de NFTs. Em seguida, o contrato calcula o custo do leilão com base no preço atual e na quantidade desejada e verifica se o valor enviado em ETH é suficiente. Se sim, os NFTs são criados para o usuário e o excesso de ETH é devolvido; caso contrário, a transação é revertida.

```solidity
    // Função para leilão e criação de NFTs
    function auctionMint(uint256 quantity) external payable {
        uint256 _saleStartTime = uint256(auctionStartTime); // Criação de variável local para reduzir custos de gas
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "o leilão ainda não começou"
        ); // Verifica se o timestamp de início foi configurado e se o leilão começou
        require(
            totalSupply() + quantity <= COLLECTOIN_SIZE,
            "não há quantidade restante suficiente para criar a quantidade desejada de NFTs"
        ); // Verifica se a quantidade excede o número limite de NFTs

        uint256 totalCost = getAuctionPrice() * quantity; // Calcula o custo da criação de NFTs
        require(msg.value >= totalCost, "Precisa enviar mais ETH."); // Verifica se o usuário enviou ETH suficiente
        
        // Criação de NFTs
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }
        // Reembolsa o excesso de ETH
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost); // Verifique se há riscos de reentrância nesta linha
        }
    }
```

- Retirada de Ether: O proprietário do contrato pode usar a função `withdrawMoney()` para sacar o ETH arrecadado com o leilão.

```solidity
    // Função para sacar o dinheiro arrecadado, apenasOwner
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transferência falhou.");
    }
```

## Demonstração no Remix
1. Implantação do contrato: Primeiro, implante o contrato `DutchAuction.sol` e defina o timestamp de início do leilão usando a função `setAuctionStartTime()`. Neste exemplo, o timestamp foi definido para 12 de julho de 2022 às 1h30, que corresponde a 1658338200 em UTC.

2. Leilão Holandês: Em seguida, use a função `getAuctionPrice()` para obter o preço atual no leilão. Antes do início do leilão, o preço será igual ao `AUCTION_START_PRICE`. Conforme o leilão avança, o preço gradualmente diminui até atingir o `AUCTION_END_PRICE` e não mudar mais.

3. Criação de NFTs: Utilize a função `auctionMint()` para criar NFTs através do leilão. Neste exemplo, como o tempo já passou do tempo do leilão, apenas o `AUCTION_END_PRICE` foi cobrado para completar o leilão.

4. Retirada de ETH: Simplesmente utilize a função `withdrawMoney()` para transferir o ETH arrecadado no leilão para a carteira do criador do contrato.

## Conclusão
Nesta lição, introduzimos o leilão holandês e explicamos como utilizar o contrato simplificado `DutchAuction` para vender NFTs do padrão ERC721 através de um leilão holandês. O item NFT mais caro que já arrematei foi uma música NFT do músico Jonathan Mann. Qual foi o seu?

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->