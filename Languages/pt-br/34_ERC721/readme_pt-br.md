# 34. ERC721

Eu recentemente retomei o estudo do solidity para consolidar os detalhes e escrever um "Guia Simples de Solidity", para iniciantes (programadores experientes devem procurar outros tutoriais). Atualizo o guia de 1 a 3 vezes por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Junte-se à comunidade de cientistas WTF, com instruções para entrar no grupo do WhatsApp: [Link](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais estão disponíveis no meu GitHub (1024 estrelas para certificação do curso, 2048 estrelas para NFT do grupo): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

`BTC` e `ETH` são exemplos de tokens homogêneos, onde a primeira unidade minerada do `BTC` é equivalente à décima milésima unidade. Porém, no mundo real, muitos itens são heterogêneos, como imóveis, antiguidades, arte virtual, etc., os quais não podem ser representados por tokens homogêneos. Por isso, o EIP721 da Ethereum propôs o padrão `ERC721` para abstrair esses itens não fungíveis. Nesta aula, vamos abordar o padrão `ERC721` e emitir um NFT baseado nele.

## EIP e ERC

É importante entender o que significa o título desta seção. Aqui discutimos sobre o `ERC721`, mencionando o `EIP721`, qual a relação entre eles?

`EIP` significa `Ethereum Improvement Proposals` (Proposta de Melhoria do Ethereum), uma série de documentos numerados propostos pela comunidade de desenvolvedores do Ethereum, semelhante aos RFCs da IETF na Internet.

`EIP` pode ser de qualquer domínio dentro do ecossistema Ethereum, incluindo novos recursos, padrões de tokens (como `ERC20`, `ERC721`), melhorias de protocolo, entre outros.

`ERC`, por outro lado, significa Ethereum Request For Comment (Solicitação de Comentário Ethereum), usado para registrar diversos padrões e protocolos de desenvolvimento de aplicativos na Ethereum. Exemplos incluem os padrões de tokens como `ERC20`, `ERC721`, `ERC777, etc.

Os padrões ERC são de grande importância e impacto no desenvolvimento do ecossistema Ethereum, como os padrões `ERC20`, `ERC223`, `ERC721`, `ERC777, etc.

Então, a conclusão final é: `EIP` engloba `ERC`.

**Após concluir esta aula, você entenderá por que começamos falando sobre `ERC165` em vez de `ERC721`. Se deseja ver a conclusão diretamente, vá para o final do texto.**

## ERC165

Por meio do padrão [ERC165](), os contratos inteligentes podem declarar as interfaces que suportam, permitindo que outros contratos realizem verificações. Simplificando, o ERC165 é usado para verificar se um contrato suporta as interfaces `ERC721` e `ERC1155`.

A interface do contrato `IERC165` possui apenas uma função `supportsInterface`, que recebe o `interfaceId` a ser verificado e retorna `true` se o contrato implementar essa interface:

```solidity
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the EIP for more details:
     * https://eips.ethereum.org/EIPS/eip-165
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```

Vejamos como o `ERC721` implementa a função `supportsInterface()`:

```solidity
function supportsInterface(bytes4 interfaceId) external pure override returns (bool)
{
    return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC165).interfaceId;
}
```

Quando o `interfaceId` consultado é o `IERC721` ou o `IERC165`, a função retorna `true`; caso contrário, retorna `false`.

## IERC721

O `IERC721` é a interface do padrão `ERC721`, que define as funções que devem ser implementadas pelo `ERC721`. Ele utiliza o `tokenId` para representar um token não fungível específico, sendo necessário especificar o `tokenId` em operações de transferência ou autorização, ao contrário dos tokens `ERC20` onde apenas a quantidade é necessária.

```solidity
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
```

### Eventos do IERC721
O `IERC721` possui 3 eventos, sendo o `Transfer` e o `Approval` presente também no `ERC20`.
- O evento `Transfer`: acionado durante uma transferência, registrando o endereço de origem `from`, o endereço de destino `to` e o `tokenId`.
- O evento `Approval`: acionado durante a autorização, registrando o endereço autorizante `owner`, o endereço autorizado `approved` e o `tokenId`.
- O evento `ApprovalForAll`: acionado durante uma autorização em lote, registrando o endereço autorizante `owner`, o endereço autorizado `operator` e a aprovação `approved`.

### Funções do IERC721
- `balanceOf`: retorna a quantidade de NFT que um endereço possui.
- `ownerOf`: retorna o proprietário de um determinado `tokenId`.
- `transferFrom`: transferência regular, com os parâmetros do endereço de origem `from`, o endereço de destino `to` e o `tokenId`.
- `safeTransferFrom`: transferência segura (se o destinatário for um contrato, ele deve implementar a interface `ERC721Receiver`). Com os parâmetros do endereço de origem `from`, o endereço de destino `to` e o `tokenId`.
- `approve`: autoriza outro endereço a usar o seu NFT, com os parâmetros do endereço autorizado `to` e o `tokenId`.
- `getApproved`: consulta o endereço autorizado para um determinado `tokenId`.
- `setApprovalForAll`: autoriza em lotes os NFT de posse de um endereço a serem acessados por outro endereço `operator`.
- `isApprovedForAll`: verifica se um determinado endereço autorizou em lote outro endereço `operator`.
- `safeTransferFrom`: versão sobrecarregada da transferência segura, com o parâmetro `data`.

## IERC721Receiver
Se um contrato não implementar as funções relacionadas ao `ERC721`, os NFTs transferidos para ele ficarão presos, sem a possibilidade de transferência. Para evitar transferências erradas, o `ERC721` implementa a função `safeTransferFrom()` para transferências seguras, onde o contrato de destino deve implementar a interface `IERC721Receiver` para receber os NFTs, caso contrário, a transação irá reverter. A interface `IERC721Receiver` contém apenas uma função `onERC721Received()`.

```solidity
// Interface do receptor de NFT ERC721: o contrato deve implementar esta interface para receber NFTs seguros
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
```

O código `_checkOnERC721Received` garante que o contrato de destino implementou a função `onERC721Received()` e retorna o seletor `onERC721Received`.

```solidity
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }
```

## IERC721Metadata
`IERC721Metadata` é a interface de extensão do `ERC721` que define três funções comuns para consulta de metadados:

- `name()`: retorna o nome do token.
- `symbol()`: retorna o símbolo do token.
- `tokenURI()`: consulta o link da metadados via `tokenId`, uma função exclusiva do `ERC721`.

```solidity
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
```

## Contrato ERC721
O contrato principal do `ERC721` implementa todas as funcionalidades definidas no `IERC721`, `IERC165` e `IERC721Metadata`, além de conter 4 variáveis de estado e 17 funções. É uma implementação simples, com comentários explicativos em cada função:

```solidity
// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.4;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    using Address for address; // Usando a biblioteca Address para verificar se é um contrato
    using Strings for uint256; // Usando a biblioteca String

    // Nome do Token
    string public override name;
    // Símbolo do Token
    string public override symbol;
    // Mapeamento de tokenId para o endereço do proprietário
    mapping(uint => address) private _owners;
    // Mapeamento de endereço para a quantidade de tokens possuída
    mapping(address => uint) private _balances;
    // Mapeamento de tokenId para o endereço autorizado
    mapping(uint => address) private _tokenApprovals;
    // Mapeamento de endereço para autorizações em lote
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * Construtor para inicializar `name` e `symbol`.
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Implementação da interface IERC165 para supportsInterface
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Implementação do balanceOf da IERC721
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // Implementação do ownerOf da IERC721
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // Implementação do isApprovedForAll da IERC721
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // Implementação do setApprovalForAll da IERC721
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Implementação do getApproved da IERC721
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }
     
    // Função de autorização. Autoriza o endereço `to` a operar o `tokenId`, emitindo o evento Approval.
    function _approve(
        address owner,
        address to,
        uint tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // Implementação da função approve da IERC721
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    // Verifica se `spender` pode usar `tokenId` (ele é o proprietário ou foi autorizado)
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) private view returns (bool) {
        return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }

    /*
     * Função de transferência. Transfere o `tokenId` de `from` para `to`, emitindo o evento Transfer.
     * Condições:
     * 1. `tokenId` pertence a `from`
     * 2. `to` não é um endereço zero
     */
    function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");

        _approve(owner, address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    // Implementação da função transferFrom da IERC721
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    /**
     * Safe transfer function. Transfers the `tokenId` token from `from` to `to`, checking if the recipient contract understands the ERC721 protocol.
     * Emits the Transfer event.
     * Conditions:
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist, and be owned by `from`.
     * - If `to` is a smart contract, it must support IERC721Receiver.
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "not ERC721Receiver");
    }

    /**
     * Implementation of the safeTransferFrom function of IERC721.
     * Emits the Transfer event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    // Overloaded safeTransferFrom function
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** 
     * Mint function. Mints the `tokenId` and transfers it to `to`, emitting the Transfer event.
     * Este método pode ser chamado por qualquer um, deve ser modificado para condições específicas.
     * Condições:
     * 1. `tokenId` não deve existir.
     * 2. `to` não é um endereço zero.
     */
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // Burn function. Burns the `tokenId`, emitting the Transfer event.
    // Condições: `tokenId` deve existir.
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approve(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // CheckOnERC721Received function: executed when `to` is a contract to call IERC721Receiver-onERC721Received, ensuring that the `tokenId` is not accidentally sent to a black hole.
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->