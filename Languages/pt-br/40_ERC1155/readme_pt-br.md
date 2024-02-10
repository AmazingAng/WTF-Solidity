# WTF Solidity Simplificado: 40. ERC1155

Recentemente, tenho revisado meu conhecimento em solidity para consolidar alguns detalhes e escrever um "WTF Solidity Simplificado" para iniciantes (os experientes em programação podem procurar outros tutoriais), com atualização semanal de 1-3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Discord: [WTF Academy](https://discord.gg/5akcruXrsk)

Todo o código e tutorial estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, vamos aprender sobre o padrão `ERC1155`, que permite que um contrato contenha diversos tipos de tokens. Também vamos criar uma versão modificada e entediante dos Macacos Não Tão Aleatórios (Bored Ape Yacht Club) - `BAYC1155`: que contém `10.000` tokens e tem metadados idênticos aos tokens BAYC.

## Padrão `EIP1155`
Independentemente de ser o padrão `ERC20` ou `ERC721`, cada contrato representa um token único. Imagine que você queira criar um grande jogo similar a "World of Warcraft" na blockchain Ethereum; isso exigiria que você implantasse um contrato para cada equipamento. Com milhares de equipamentos, você teria que implantar e gerenciar milhares de contratos, o que seria muito trabalhoso. Portanto, a proposta [EIP1155 da Ethereum](https://eips.ethereum.org/EIPS/eip-1155) introduziu o padrão de múltiplos tokens `ERC1155`, que permite que um contrato contenha vários tokens fungíveis e não fungíveis. O `ERC1155` é muito utilizado em aplicações GameFi, como Decentraland e Sandbox.

Em resumo, o `ERC1155` é semelhante ao padrão de tokens não fungíveis introduzido anteriormente [ERC721](https://github.com/AmazingAng/WTFSolidity/tree/main/34_ERC721): no `ERC721`, cada token possui um `tokenId` como identificador único, com cada `tokenId` representando um token único; já no `ERC1155`, cada tipo de token possui um `id` como identificador exclusivo, onde cada `id` representa um tipo específico de token. Dessa forma, diferentes tipos de tokens podem ser gerenciados de forma não fungível em um mesmo contrato, e cada tipo de token pode ter um URI para armazenar seus metadados, semelhante ao `tokenURI` do `ERC721`. Abaixo está o contrato de interface de metadados para o `ERC1155`, chamado de `IERC1155MetadataURI`:

```solidity
/**
 * @dev Interface opcional do ERC1155 que contém a função uri() para consultar metadados.
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Retorna o URI do token da classe `id`.
     */
    function uri(uint256 id) external view returns (string memory);
```

Como diferenciar um tipo de token no `ERC1155` como fungível ou não fungível? É simples: se o número total de tokens para um determinado `id` for `1`, então ele é um token não fungível, similar ao `ERC721`; se o número total de tokens para um `id` for maior que `1`, então é um token fungível, já que esses tokens compartilham o mesmo `id`, semelhante ao `ERC20`.

## Contrato de Interface `IERC1155`

O contrato de interface `IERC1155` abstrai as funcionalidades que um contrato precisa implementar de acordo com o padrão `EIP1155`, incluindo `4` eventos e `6` funções. Ao contrário do `ERC721`, que possui tokens únicos, o `ERC1155` permite a transferência e consulta de vários tokens em uma única operação.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev Interface padrão do ERC1155, implementando as funcionalidades do EIP1155.
 * Mais detalhes: https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Evento de transferência de um token específico.
     * Quando `value` unidades do token da classe `id` são transferidas de `from` para `to` pelo `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Evento de transferência de vários tokens.
     * Os ids e os valores representam os tokens a serem transferidos.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Evento de aprovação geral.
     * Quando `account` autoriza o `operator` a transferir todos os tokens em seu nome.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Evento disparado quando o URI do token com o `id` muda para `value`.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Função para consultar o saldo de um token específico de uma conta.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Função para consultar o saldo de vários tokens de várias contas.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Função para autorizar a transferência de todos os tokens por parte do `operator`.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Função para verificar se um `operator` está autorizado a transferir todos os tokens de uma `account`.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Função para realizar uma transferência segura de `amount` unidades do token da classe `id` de `from` para `to`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Função para realizar uma transferência segura de vários tokens.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
```

### Eventos do `IERC1155`
- Evento `TransferSingle`: evento de transferência de um token específico, disparado durante a transferência de um token.
- Evento `TransferBatch`: evento de transferência de vários tokens, disparado durante a transferência de múltiplos tokens.
- Evento `ApprovalForAll`: evento de aprovação geral, disparado quando um endereço autoriza outro a transferir todos os tokens em seu nome.
- Evento `URI`: evento disparado quando o URI de um token com um `id` específico é alterado.

### Funções do `IERC1155`
- `balanceOf()`: consulta o saldo de um token específico de uma conta, informando o endereço da conta e o `id` do token.
- `balanceOfBatch()`: consulta o saldo de vários tokens de várias contas, sendo necessário que os arrays `accounts` e `ids` tenham o mesmo tamanho.
- `setApprovalForAll()`: autoriza a transferência de todos os tokens por parte de um `operator`, disparando o evento `ApprovalForAll`.
- `isApprovedForAll()`: verifica se um `operator` está autorizado a transferir todos os tokens de uma dada `account`.
- `safeTransferFrom()`: realiza uma transferência segura de um token específico, verificando se o destinatário é um contrato que implementa a função `onERC1155Received()`.
- `safeBatchTransferFrom()`: realiza uma transferência segura de vários tokens, verificando se o destinatário é um contrato que implementa a função `onERC1155BatchReceived()`.

## Contrato de Recepção `ERC1155`

Assim como no padrão `ERC721`, para evitar que os tokens sejam enviados para contratos não desejados, o `ERC1155` requer que o contrato receptor dos tokens herde o `IERC1155Receiver` e implemente as funções de recepção específicas:

- `onERC1155Received()`: função de recebimento de transferência de token único, que aceita a transferência segura do `ERC1155` `safeTransferFrom` e precisa retornar o seletor `0xf23a6e61`.
- `onERC1155BatchReceived()`: função de recebimento de transferência de múltiplos tokens, que aceita a transferência segura de múltiplos tokens do `ERC1155` `safeBatchTransferFrom` e precisa retornar o seletor `0xbc197c81`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev Contrato receptor do ERC1155, necessário para aceitar transferências seguras do ERC1155.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Aceitar a transferência segura do ERC1155 `safeTransferFrom`.
     * Deve retornar 0xf23a6e61 ou bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Aceitar a transferência segura em lote do ERC1155 `safeBatchTransferFrom`.
     * Deve retornar 0xbc197c81 ou bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
```

## Contrato Principal do `ERC1155`

O contrato principal do `ERC1155` implementa as funções exigidas pela interface `IERC1155`, além das funções de cunhagem e destruição de tokens individuais e em massa.

### Variáveis do `ERC1155`

O contrato principal do `ERC1155` possui `4` variáveis de estado:

- `name`: nome do token
- `symbol`: símbolo do token
- `_balances`: mapeamento do saldo do token, acompanhando o saldo de um determinado endereço `account` para um determinado tipo de token `id`.
- `_operatorApprovals`: mapeamento de aprovações em lote, acompanhando se um endereço tem permissão para transferir tokens em nome de outro.

### Funções do `ERC1155`

O contrato principal do `ERC1155` possui `16` funções:

- Construtor: inicializa as variáveis `name` e `symbol`.
- `supportsInterface()`: implementa o padrão `ERC165`, declarando quais interfaces ele suporta para que outros contratos possam verificar.
- `balanceOf()`: implementa o `balanceOf()` da interface `IERC1155`, consultando o saldo de um token específico de uma conta.
- `balanceOfBatch()`: implementa o `balanceOfBatch()` da interface `IERC1155`, consultando o saldo de vários tokens de várias contas.
- `setApprovalForAll()`: implementa o `setApprovalForAll()` da interface `IERC1155`, permitindo a aprovação em lote de transferências e disparando o evento `ApprovalForAll`.
- `isApprovedForAll()`: implementa o `isApprovedForAll()` da interface `IERC1155`, consultando informações sobre aprovação em lote.
- `safeTransferFrom()`: implementa o `safeTransferFrom()` da interface `IERC1155`, realizando uma transferência segura de um token individual e disparando o evento `TransferSingle`.
- `safeBatchTransferFrom()`: implementa o `safeBatchTransferFrom()` da interface `IERC1155`, realizando uma transferência segura de vários tokens e disparando o evento `TransferBatch`.
- `_mint()`: função de cunhagem de token individual.
- `_mintBatch()`: função de cunhagem de vários tokens em massa.
- `_burn()`: função de destruição de token individual.
- `_burnBatch()`: função de destruição de vários tokens em massa.
- `_doSafeTransferAcceptanceCheck()`: verificação de segurança da transferência de token individual, chamada por `safeTransferFrom()` para garantir que o destinatário seja um contrato que implementa a função `onERC1155Received()`.
- `_doSafeBatchTransferAcceptanceCheck()`: verificação de segurança da transferência de vários tokens, chamada por `safeBatchTransferFrom()` para garantir que o destinatário seja um contrato que implementa a função `onERC1155BatchReceived()`.
- `uri()`: retorna o URI do metadado do token de classe `id` no `ERC1155`, similar ao `tokenURI` do `ERC721`.
- `baseURI()`: retorna o `baseURI`, onde o `uri` concatena o `baseURI` com o `id`, necessitando que o desenvolvedor sobrescreva esse método.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/Address.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/String.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev Padrão ERC1155 para múltiplos tokens
 * Veja: https://eips.ethereum.org/EIPS/eip-1155
 */
contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {
    using Address for address; // Utilizando biblioteca Address para verificar se um endereço é de um contrato
    using Strings for uint256; // Utilizando biblioteca String

    // Nome do token
    string public name;
    // Símbolo do token
    string public symbol;
    // Mapeamento dos saldos de tokens por id, endereço de conta e saldo
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Mapeamento de aprovações em lote, endereço e aprovação
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * Construtor, inicializa `name` e `symbol`, e uri_
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev Veja {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Consulta o saldo de um token específico de uma conta.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev Consulta o saldo de vários tokens de várias contas.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public view virtual override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    /**
     * @dev Aprova a transferência de todos os tokens em nome de `operator`.
     * Dispara o evento {ApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Verifica se `operator` está aprovado para transferir todos os tokens de `account`.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Transfere seguramente `amount` unidades do token da classe `id` de `from` para `to`.
     * Dispara o evento {TransferSingle}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        address operator = msg.sender;
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(to != address(0), "

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->