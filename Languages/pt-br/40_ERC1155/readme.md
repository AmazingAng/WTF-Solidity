---
title: 40. ERC1155
tags:
  - solidity
  - aplicação
  - wtfacademy
  - ERC1155
---

# WTF Introdução Simples ao Solidity: 40. ERC1155

Recentemente, tenho estado a estudar Solidity novamente para consolidar alguns detalhes e escrever um "WTF Introdução Simples ao Solidity" para iniciantes (programadores experientes podem procurar outros tutoriais). Serão lançadas de 1 a 3 aulas por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Discord: [WTF Academy](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta aula, vamos aprender sobre o padrão `ERC1155`, que permite que um contrato contenha vários tipos de tokens. Além disso, vamos criar um token chato modificado chamado `BAYC1155`, que contém 10.000 tipos de tokens e tem metadados idênticos ao `BAYC`.

## `EIP1155`
Tanto o padrão `ERC20` quanto o `ERC721` permitem que um contrato represente um único tipo de token. No entanto, se quisermos criar um jogo em larga escala semelhante ao "World of Warcraft" na Ethereum, teríamos que implantar um contrato para cada item do jogo. Isso seria muito complicado, pois teríamos que implantar e gerenciar milhares de contratos. Por isso, a proposta [EIP1155 da Ethereum](https://eips.ethereum.org/EIPS/eip-1155) introduziu o padrão `ERC1155`, que permite que um contrato contenha vários tipos de tokens fungíveis e não fungíveis. O `ERC1155` é amplamente utilizado em aplicativos de GameFi, como Decentraland e Sandbox.

Em resumo, o `ERC1155` é semelhante ao padrão de token não fungível (NFT) `ERC721` que discutimos anteriormente. No `ERC721`, cada token tem um `tokenId` como identificador exclusivo e cada `tokenId` corresponde a um único token. No `ERC1155`, cada tipo de token tem um `id` como identificador exclusivo e cada `id` corresponde a um tipo de token. Isso permite que diferentes tipos de tokens sejam gerenciados no mesmo contrato e cada tipo de token tem uma URL `uri` para armazenar seus metadados, semelhante ao `tokenURI` do `ERC721`. Abaixo está o contrato de interface de metadados `IERC1155MetadataURI` do `ERC1155`:

```solidity
/**
 * @dev Interface opcional do ERC1155 que adiciona a função uri() para consultar metadados
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Retorna a URL dos metadados do token do tipo `id`
     */
    function uri(uint256 id) external view returns (string memory);
```

Então, como diferenciamos entre tokens fungíveis e não fungíveis no `ERC1155`? É muito simples: se a quantidade total de tokens correspondente a um determinado `id` for `1`, então é um token não fungível, semelhante ao `ERC721`. Se a quantidade total de tokens correspondente a um determinado `id` for maior que `1`, então é um token fungível, pois todos esses tokens compartilham o mesmo `id`, semelhante ao `ERC20`.

## Contrato de Interface `IERC1155`

A interface `IERC1155` abstrai as funcionalidades que o `EIP1155` requer que sejam implementadas. Ela inclui `4` eventos e `6` funções. Ao contrário do `ERC721`, que representa um único tipo de token, o `ERC1155` permite a transferência e consulta de saldo de vários tipos de tokens em uma única operação.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev Interface padrão do ERC1155 que implementa as funcionalidades do EIP1155
 * Veja: https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Evento de transferência de um único tipo de token
     * É emitido quando `value` tokens do tipo `id` são transferidos de `from` para `to` pelo `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Evento de transferência de vários tipos de tokens
     * `ids` e `values` são os arrays de tipos e quantidades de tokens transferidos.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Evento de aprovação em lote
     * É emitido quando `account` aprova o `operator` para gerenciar todos os seus tokens.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Evento de alteração da URL dos metadados de um tipo de token `id`
     * É emitido quando a URL dos metadados de um tipo de token `id` é alterada para `value`.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Função para consultar o saldo de tokens do tipo `id` que o `account` possui.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Função para consultar o saldo de vários tipos de tokens que o `accounts` possui.
     * Os arrays `accounts` e `ids` devem ter o mesmo tamanho.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Função para aprovar o `operator` a gerenciar todos os tokens do `caller`.
     * Emite o evento {ApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Função para consultar se o `operator` está aprovado para gerenciar todos os tokens do `account`.
     * Veja a função {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Função para transferir `amount` tokens do tipo `id` do `from` para o `to`.
     * Emite o evento {TransferSingle}.
     * Requerimentos:
     * - Se o `caller` não for o `from`, ele precisa ter a aprovação do `from`.
     * - O `from` precisa ter saldo suficiente.
     * - Se o `to` for um contrato, ele precisa implementar a função `onERC1155Received` do `IERC1155Receiver` e retornar o valor correto.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Função para transferir vários tipos de tokens do `from` para o `to`.
     * Emite o evento {TransferBatch}.
     * Requerimentos:
     * - Os arrays `ids` e `amounts` devem ter o mesmo tamanho.
     * - Se o `to` for um contrato, ele precisa implementar a função `onERC1155BatchReceived` do `IERC1155Receiver` e retornar o valor correto.
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
- Evento `TransferSingle`: evento de transferência de um único tipo de token, é emitido quando `value` tokens do tipo `id` são transferidos de `from` para `to` pelo `operator`.
- Evento `TransferBatch`: evento de transferência de vários tipos de tokens, `ids` e `values` são os arrays de tipos e quantidades de tokens transferidos.
- Evento `ApprovalForAll`: evento de aprovação em lote, é emitido quando `account` aprova o `operator` para gerenciar todos os seus tokens.
- Evento `URI`: evento de alteração da URL dos metadados de um tipo de token `id`, é emitido quando a URL dos metadados de um tipo de token `id` é alterada para `value`.

### Funções do `IERC1155`
- `balanceOf()`: função para consultar o saldo de tokens do tipo `id` que o `account` possui.
- `balanceOfBatch()`: função para consultar o saldo de vários tipos de tokens que o `accounts` possui.
- `setApprovalForAll()`: função para aprovar o `operator` a gerenciar todos os tokens do `caller`.
- `isApprovedForAll()`: função para consultar se o `operator` está aprovado para gerenciar todos os tokens do `account`.
- `safeTransferFrom()`: função para transferir `amount` tokens do tipo `id` do `from` para o `to`.
- `safeBatchTransferFrom()`: função para transferir vários tipos de tokens do `from` para o `to`.

## Contrato de Recebimento do `ERC1155`

Assim como o padrão `ERC721`, para evitar que os tokens sejam transferidos para contratos "buraco negro", o `ERC1155` exige que o contrato de recebimento do token implemente a interface `IERC1155Receiver` e os dois métodos de recebimento:

- `onERC1155Received()`: método de recebimento para transferência de um único tipo de token, deve ser implementado e retornar o seletor `0xf23a6e61`.

- `onERC1155BatchReceived()`: método de recebimento para transferência de vários tipos de tokens, deve ser implementado e retornar o seletor `0xbc197c81`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev Contrato de recebimento do ERC1155, deve ser implementado para receber transferências seguras do ERC1155
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Recebe transferência segura do ERC1155 `safeTransferFrom` 
     * Deve retornar 0xf23a6e61 ou `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Recebe transferência segura em lote do ERC1155 `safeBatchTransferFrom` 
     * Deve retornar 0xbc197c81 ou `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
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

O contrato principal do `ERC1155` implementa as funções especificadas pela interface `IERC1155` e também inclui funções para a criação e destruição de tokens individuais e em lote.

### Variáveis do `ERC1155`

O contrato principal do `ERC1155` inclui `4` variáveis de estado:

- `name`: nome do token
- `symbol`: símbolo do token
- `_balances`: mapeamento dos saldos dos tokens, que registra o saldo do tipo de token `id` para um determinado endereço `account`.
- `_operatorApprovals`: mapeamento das aprovações em lote, que registra se um endereço possui aprovação para gerenciar os tokens de outro endereço.

### Funções do `ERC1155`

O contrato principal do `ERC1155` inclui `16` funções:

- Construtor: inicializa as variáveis de estado `name` e `symbol`.
- `supportsInterface()`: implementa o padrão `ERC165`, declarando as interfaces que suporta para que outros contratos possam verificar.
- `balanceOf()`: implementa a função `balanceOf()` da interface `IERC1155`, que consulta o saldo de um determinado tipo de token para um determinado endereço.
- `balanceOfBatch()`: implementa a função `balanceOfBatch()` da interface `IERC1155`, que consulta o saldo de vários tipos de tokens para vários endereços.
- `setApprovalForAll()`: implementa a função `setApprovalForAll()` da interface `IERC1155`, que aprova um endereço para gerenciar todos os tokens de um determinado endereço.
- `isApprovedForAll()`: implementa a função `isApprovedForAll()` da interface `IERC1155`, que consulta se um endereço está aprovado para gerenciar todos os tokens de outro endereço.
- `safeTransferFrom()`: implementa a função `safeTransferFrom()` da interface `IERC1155`, que transfere um determinado valor de um tipo de token de um endereço para outro.
- `safeBatchTransferFrom()`: implementa a função `safeBatchTransferFrom()` da interface `IERC1155`, que transfere vários tipos de tokens de um endereço para outro.
- `_mint()`: função de criação de um único tipo de token.
- `_mintBatch()`: função de criação de vários tipos de tokens.
- `_burn()`: função de destruição de um único tipo de token.
- `_burnBatch()`: função de destruição de vários tipos de tokens.
- `_doSafeTransferAcceptanceCheck()`: verificação de segurança para transferência de um único tipo de token, chamada pela função `safeTransferFrom()`, garante que o destinatário seja um contrato que implemente a função `onERC1155Received()`.
- `_doSafeBatchTransferAcceptanceCheck()`: verificação de segurança para transferência de vários tipos de tokens, chamada pela função `safeBatchTransferFrom()`, garante que o destinatário seja um contrato que implemente a função `onERC1155BatchReceived()`.
- `uri()`: retorna a URL dos metadados do tipo de token `id`, semelhante ao `tokenURI` do `ERC721`.
- `baseURI()`: retorna o `baseURI`, que é concatenado com o `id` para formar a URL completa dos metadados do `ERC1155`. Esta função pode ser sobrescrita.

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
 * @dev Padrão ERC1155 para múltiplos tipos de tokens
 * Veja https://eips.ethereum.org/EIPS/eip-1155
 */
contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {
    using Address for address; // Usando a biblioteca Address para verificar se um endereço é um contrato
    using Strings for uint256; // Usando a biblioteca Strings

    // Nome do token
    string public name;
    // Símbolo do token
    string public symbol;
    // Mapeamento dos saldos dos tokens
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Mapeamento das aprovações em lote
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * Construtor, inicializa o nome e o símbolo
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
     * @dev Consulta o saldo de tokens do tipo `id` que o `account` possui.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev Consulta o saldo de vários tipos de tokens que o `accounts` possui.
     * Requerimentos:
     * - Os arrays `accounts` e `ids` devem ter o mesmo tamanho.
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
     * @dev Aprova o `operator` a gerenciar todos os tokens do `caller`.
     * Emite o evento {ApprovalForAll}.
     * Requerimentos:
     * - O `caller` não pode ser o `operator`.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Consulta se o `operator` está aprovado para gerenciar todos os tokens do `account`.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Transfere `amount` tokens do tipo `id` do `from` para o `to`.
     * Emite o evento {TransferSingle}.
     * Requerimentos:
     * - O `to` não pode ser o endereço zero.
     * - O `from` deve ter saldo suficiente.
     * - Se o `to` for um contrato, ele deve implementar a função `onERC1155Received` do `IERC1155Receiver` e retornar o valor correto.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);    
    }

    /**
     * @dev Transfere em lote `amounts` tokens dos tipos `ids` do `from` para o `to`.
     * Emite o evento {TransferBatch}.
     * Requerimentos:
     * - O `to` não pode ser o endereço zero.
     * - O `from` deve ter saldo suficiente.
     * - Se o `to` for um contrato, ele deve implementar a função `onERC1155BatchReceived` do `IERC1155Receiver` e retornar o valor correto.
     * - Os arrays `ids` e `amounts` devem ter o mesmo tamanho.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);    
    }

    /**
     * @dev Função interna para criar um único tipo de token.
     * Emite o evento {TransferSingle}.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = msg.sender;

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev Função interna para criar vários tipos de tokens.
     * Emite o evento {TransferBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Função interna para destruir um único tipo de token.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev Função interna para destruir vários tipos de tokens.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    // Função interna para verificar a transferência segura do ERC1155
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    // Função interna para verificar a transferência segura em lote do ERC1155
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    /**
     * @dev Retorna a URL dos metadados do tipo de token `id`, semelhante ao `tokenURI` do `ERC721`.
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    /**
     * @dev Retorna o `baseURI`, que é concatenado com o `id` para formar a URL completa dos metadados do `ERC1155`.
     * Esta função pode ser sobrescrita.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
```

## `BAYC`, mas `ERC1155`

Vamos modificar o token chato `BAYC` do padrão `ERC721` e criar um token gratuito chamado `BAYC1155` usando o `ERC1155`. Vamos modificar a função `_baseURI()` para que o `uri` do `BAYC1155` seja igual ao `tokenURI` do `BAYC`. Dessa forma, os metadados do `BAYC1155` serão idênticos aos do `BAYC`:

```solidity
// SPDX-License-Identifier: MIT
// por 0xAA
pragma solidity ^0.8.4;

import "./ERC1155.sol";

contract BAYC1155 is ERC1155 {
    uint256 constant MAX_ID = 10000; 

    constructor() ERC1155("BAYC1155", "BAYC1155") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }
    
    function mint(address to, uint256 id, uint256 amount) external {
        require(id < MAX_ID, "id overflow");
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
    }
}
```

## Demonstração no Remix

### 1. Implante o contrato `BAYC1155`
![deploy](./img/40-1.jpg)

### 2. Verifique o `uri` dos metadados
![metadata](./img/40-2.jpg)

### 3. Faça uma operação de `mint` e verifique a alteração no saldo
Na seção `mint`, insira o endereço da conta, o `id` e a quantidade e clique no botão `mint`. Se a quantidade for `1`, será um token não fungível; se a quantidade for maior que `1`, será um token fungível.

![mint1](./img/40-3.jpg)

Na seção `balanceOf`, insira o endereço da conta e o `id` para verificar o saldo correspondente.

![mint2](./img/40-4.jpg)

### 4. Faça uma operação de `mintBatch` e verifique a alteração no saldo
Na seção `mintBatch`, insira os arrays de `ids` e `amounts` para os tokens que deseja criar. Os dois arrays devem ter o mesmo tamanho.

![batchmint1](./img/40-5.jpg)

Na seção `balanceOf`, insira o endereço da conta e os `ids` dos tokens que foram criados para verificar o saldo correspondente.

![batchmint2](./img/40-6.jpg)

### 5. Faça uma operação de transferência em lote e verifique a alteração no saldo
Assim como na operação de criação, insira os arrays de `ids` e `amounts` para os tokens que deseja transferir em lote.

![transfer1](./img/40-7.jpg)

Na seção `balanceOf`, insira o endereço da conta para a qual os tokens foram transferidos e os `ids` dos tokens para verificar o saldo correspondente.

![transfer2](./img/40-8.jpg)

## Conclusão

Nesta aula, aprendemos sobre o padrão `ERC1155` proposto pelo Ethereum EIP1155, que permite que um contrato contenha vários tipos de tokens fungíveis e não fungíveis. Também criamos uma versão modificada do token chato `BAYC` chamado `BAYC1155`, que contém 10.000 tipos de tokens e tem metadados idênticos ao `BAYC`. Atualmente, o `ERC1155` é amplamente utilizado em aplicativos de GameFi. No entanto, acredito que, com o desenvolvimento contínuo da tecnologia do metaverso, esse padrão se tornará cada vez mais popular.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->