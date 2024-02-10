# 38. Exchange de NFT

Eu recentemente comecei a estudar Solidity novamente, revisando os detalhes, e estou escrevendo um "Guia Simples de Solidity" para iniciantes (programadores avançados podem procurar outros tutoriais), com atualizações semanais de 1-3 palestras.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Discord: [WTF Academy](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais são de código aberto no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

`Opensea` é a maior plataforma de negociação de NFTs na Ethereum, com um volume total de negociação de mais de $30 bilhões. O `Opensea` cobra uma taxa de 2.5% em cada transação, o que significa que eles lucraram pelo menos $750 milhões com as transações dos usuários. Além disso, sua operação não é descentralizada e eles não estão planejando lançar uma moeda para compensar os usuários. Os jogadores de NFT estão insatisfeitos com o `Opensea` há muito tempo, e hoje vamos usar contratos inteligentes para construir uma exchange descentralizada de NFTs sem taxas: `NFTSwap`.

## Lógica de Design

- Vendedor: a parte que vende o NFT, pode listar `list`, cancelar a listagem `revoke`, e alterar o preço `update`.
- Comprador: a parte que compra o NFT, pode comprar `purchase`.
- Pedido: uma ordem de NFT publicada pelo vendedor, uma série de tokens com o mesmo `tokenId` pode ter no máximo um pedido, contendo o preço de listagem `price` e as informações do proprietário `owner`. Quando uma ordem é concluída ou cancelada, as informações são zeradas.

## Contrato `NFTSwap`

### Eventos
O contrato inclui 4 eventos, correspondentes à listagem `list`, à revogação `revoke`, à alteração de preço `update` e à compra `purchase` desses quatro comportamentos:
```solidity
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);    
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);
```

### Pedido
A ordem de NFT é abstraída como uma estrutura `Order`, contendo o preço de listagem `price` e as informações do proprietário `owner`. O mapeamento `nftList` registra a ordem correspondente ao contrato NFT e as informações do `tokenId`.
```solidity
    // Definição da estrutura da ordem
    struct Order{
        address owner;
        uint256 price; 
    }
    // Mapeamento da Ordem de NFT
    mapping(address => mapping(uint256 => Order)) public nftList;
```

### Função de fallback
No `NFTSwap`, os usuários usam `ETH` para comprar o NFT. Portanto, o contrato precisa implementar a função `fallback()` para receber `ETH`.
```solidity
    fallback() external payable{}
```

### onERC721Received
A função de transferência segura `ERC721` verifica se o contrato receptor implementou a função `onERC721Received()` e retorna o seletor correto. Após o usuário fazer um pedido, o NFT precisa ser enviado para o contrato `NFTSwap`. Portanto, o `NFTSwap` herda a interface `IERC721Receiver` e implementa a função `onERC721Received()`:
```solidity
contract NFTSwap is IERC721Receiver{

    // Implementa a função onERC721Received do IERC721Receiver para poder receber tokens ERC721
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }
```

### Transações
O contrato implementa 4 funções relacionadas a transações:

- Listagem `list()`: o vendedor cria o NFT e faz a ordem, acionando o evento `List`. Os parâmetros são o endereço do contrato NFT `_nftAddr`, o `tokenId` correspondente do NFT `_tokenId` e o preço de listagem `_price` (**nota: a unidade é `wei`**). Após o sucesso, o NFT é transferido do vendedor para o contrato `NFTSwap`.
```solidity
    // Listagem: o vendedor lista o NFT para venda, o endereço do contrato é _nftAddr, o tokenId é _tokenId, o preço é em ethers (unidade em wei)
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public{
        IERC721 _nft = IERC721(_nftAddr); // Declara a variável da interface do contrato IERC721
        require(_nft.getApproved(_tokenId) == address(this), "Necessita de Aprovação"); // O contrato precisa de autorização
        require(_price > 0); // Preço maior que 0

        Order storage _order = nftList[_nftAddr][_tokenId]; // Define o proprietário e o preço do NFT
        _order.owner = msg.sender;
        _order.price = _price;
        // Transfere o NFT para o contrato
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Aciona o evento List
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }
```

- Revogação `revoke()`: o vendedor retira a listagem e aciona o evento `Revoke`. Os parâmetros são o endereço do contrato NFT `_nftAddr` e o `tokenId` correspondente do NFT `_tokenId`. Após o sucesso, o NFT é transferido de volta para o vendedor.
```solidity
    // Revogação: o vendedor retira a listagem
    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // Obter a ordem
        require(_order.owner == msg.sender, "Não é o Dono"); // Apenas o proprietário pode fazer isso
        // Declara a variável da interface do contrato IERC721
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Pedido Inválido"); // O NFT está no contrato
        
        // Transfere o NFT de volta para o vendedor
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; // Exclui a ordem
      
        // Aciona o evento Revogar
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }
```

- Atualização de preço `update()`: o vendedor altera o preço da ordem do NFT e aciona o evento `Update`. Os parâmetros são o endereço do contrato NFT `_nftAddr`, o `tokenId` correspondente do NFT `_tokenId` e o novo preço de listagem `_newPrice` (**nota: a unidade é `wei`**).
```solidity
    // Atualizar preço: o vendedor atualiza o preço da ordem do NFT
    function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Preço Inválido"); // Preço do NFT maior que 0
        Order storage _order = nftList[_nftAddr][_tokenId]; // Obter a ordem
        require(_order.owner == msg.sender, "Não é o Dono"); // Apenas o proprietário pode fazer isso
        // Declara a variável da interface do contrato IERC721
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Pedido Inválido"); // O NFT está no contrato
        
        // Atualiza o preço do NFT
        _order.price = _newPrice;
      
        // Aciona o evento Atualizar
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }
```

- Compra `purchase`: o comprador paga com `ETH` para comprar o NFT listado e aciona o evento `Purchase`. Os parâmetros são o endereço do contrato NFT `_nftAddr`, o `tokenId` correspondente do NFT `_tokenId`. Após o sucesso, o valor pago em `ETH` é transferido para o vendedor e o NFT é transferido do contrato `NFTSwap` para o comprador.
```solidity
    // Compra: o comprador compra o NFT, fornecendo o endereço do contrato _nftAddr, tokenId _tokenId, e acompanhado por ETH
    function purchase(address _nftAddr, uint256 _tokenId) payable public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // Obter a ordem
        require(_order.price > 0, "Preço Inválido"); // Preço do NFT maior que 0
        require(msg.value >= _order.price, "Aumente o preço"); // Preço de compra maior que o preço de listagem
        // Declara a variável da interface do contrato IERC721
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Pedido Inválido"); // O NFT está no contrato

        // Transfere o NFT para o comprador
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // Transfere o valor para o vendedor, e, se houver excesso, devolve o restante para o comprador
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value-_order.price);

        delete nftList[_nftAddr][_tokenId]; // Exclui a ordem

        // Aciona o evento Compra
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);
    }
```

## Implementação no Remi

### 1. Deploy do contrato NFT
Siga o tutorial [ERC721](https://github.com/AmazingAng/WTFSolidity/tree/main/34_ERC721) para entender sobre NFTs e faça o deploy do contrato NFT `WTFApe`.

![Deploy do contrato NFT](./img/38-1.png)

Mint o primeiro NFT para si mesmo, aqui estamos mintando os primeiros e segundos NFTs, com os `tokenId` sendo respectivamente `0` e `1`.

![Mint do NFT](./img/38-2.png)

No contrato `WTFApe`, confirme que agora você é o dono do NFT com `tokenId` igual a `0`.

![Confirmação de propriedade do NFT](./img/38-3.png)

Siga os passos acima para mintar os NFTs com `tokenId` igual a `0` e `1`.

### 2. Deploy do contrato `NFTSwap`
Faça o deploy do contrato `NFTSwap`.

![Deploy do contrato `NFTSwap`](./img/38-4.png)

### 3. Autorize o `NFT` a ser listado no `NFTSwap`
No contrato `WTFApe`, chame a função `approve()` para autorizar o `tokenId` do primeiro NFT a ser listado no contrato `NFTSwap`.

`approve(address to, uint tokenId)` tem 2 parâmetros:

`to`: o `tokenId` autorizado a ser listado para o endereço `to`, que neste caso é o endereço do contrato `NFTSwap`.

`tokenId`: o `tokenId` do NFT, neste caso o `tokenId` é `0`.

![Autorização do NFT](./img/38-5.png)

Repita o processo para autorizar o `tokenId` igual a `1` para o contrato `NFTSwap`.

### 4. Listagem do `NFT`
Chame a função `list()` do contrato `NFTSwap` para listar o NFT com `tokenId` igual a `0` no contrato `NFTSwap`, com o preço de `1` `wei`.

`list(address _nftAddr, uint256 _tokenId, uint256 _price)` tem 3 parâmetros:

`_nftAddr`: o endereço do contrato NFT, neste caso o endereço do contrato `WTFApe`.

`_tokenId`: o `tokenId` do NFT, neste caso o `tokenId` é `0`.

`_price`: o preço do NFT, `1` `wei` neste caso.

![Listagem do NFT](./img/38-6.png)

Repita o processo para listar o NFT com `tokenId` igual a `1` no contrato `NFTSwap`, com o preço de `1` `wei`.

### 5. Verificar NFT listados

Chame a função `nftList()` no contrato `NFTSwap` para verificar os NFTs listados.

`nftList`: é um mapeamento de ordens de NFT, com a estrutura:

`nftList[_nftAddr][_tokenId]`: dando o `_nftAddr` e `_tokenId`, você obtém uma ordem de NFT.

![Verificação de NFT listados](./img/38-7.png)

### 6. Atualizar o preço do `NFT`

Chame a função `update()` do contrato `NFTSwap` para atualizar o preço do NFT com `tokenId` igual a `0` para `77` `wei`.

`update(address _nftAddr, uint256 _tokenId, uint256 _newPrice)` tem 3 parâmetros:

`_nftAddr`: o endereço do contrato NFT, neste caso o endereço do contrato `WTFApe`.

`_tokenId`: o `tokenId` do NFT, neste caso o `tokenId` é `0`.

`_newPrice`: o novo preço do NFT, `77` `wei` neste caso.

Após a atualização, verifique o preço atualizado chamando a função `nftList`.

![Atualização do preço do NFT](./img/38-8.png)

### 7. Deslistar o `NFT`

Chame a função `revoke()` do contrato `NFTSwap` para deslistar o NFT.

No processo anterior, listamos dois NFTs com `tokenId` igual a `0` e `1`. Desta vez, vamos deslistar o NFT com `tokenId` igual a `1`.

`revoke(address _nftAddr, uint256 _tokenId)` tem 2 parâmetros:

`_nftAddr`: o endereço do contrato NFT, neste caso o endereço do contrato `WTFApe`.

`_tokenId`: o `tokenId` do NFT, neste caso o `tokenId` é `1`.

![Deslistagem do NFT](./img/38-9.png)

Após chamar a função `revoke()`, verifique se o NFT foi deslistado chamando a função `nftList`. Para listá-lo novamente será necessário repetir os passos de autorização e listagem.

![Verificação do NFT deslistado](./img/38-10.png)

**Nota: Após deslistar um NFT, você precisará autorizar e listar novamente para realizar a compra.**

### 8. Comprar o `NFT`

Troque de conta, e chame a função `purchase()` do contrato `NFTSwap` para comprar o NFT, fornecendo o endereço do contrato NFT, o `tokenId` e o valor de `ETH` a ser pago.

Deslistamos o NFT com `tokenId` igual a `1` anteriormente, agora vamos comprar o NFT com `tokenId` igual a `0`.

`purchase(address _nftAddr, uint256 _tokenId, uint256 _wei)` tem 3 parâmetros:

`_nftAddr`: o endereço do contrato NFT, neste caso o endereço do contrato `WTFApe`.

`_tokenId`: o `tokenId` do NFT, neste caso o `tokenId` é `0`.

`_wei`: a quantidade de `ETH` a ser paga, `77` `wei` neste caso.

![Compra do NFT](./img/38-11.png)

### 9. Verificar mudança do proprietário do `NFT`

Após a compra bem-sucedida, chame a função `ownerOf()` do contrato `WTFApe` para verificar a mudança do proprietário do NFT. Compra bem-sucedida!

![Verificação da mudança do proprietário do NFT](./img/38-12.png)

## Conclusão
Nesta palestra, construímos uma exchange descentralizada de NFTs sem taxas. O `Opensea` contribuiu muito para o desenvolvimento dos NFTs, mas suas desvantagens são evidentes: altas taxas, falta de recompensas em token para os usuários e um sistema de negociação suscetível a fraudes que podem resultar na perda de ativos dos usuários. Atualmente, novas plataformas de negociação de NFTs como `Looksrare` e `dydx` estão desafiando a posição do `Opensea`, e até o `Uniswap` está estudando novas exchanges de NFT. Acredito que em breve teremos acesso a exchanges de NFTs ainda melhores.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->