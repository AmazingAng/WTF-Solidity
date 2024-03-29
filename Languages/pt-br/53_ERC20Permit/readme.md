# 53. ERC-2612 ERC20Permit

Eu recentemente tenho revisitado o solidity para consolidar alguns detalhes e escrever um "WTF Solidity - Introdução Simples" para iniciantes (programadores mais avançados podem buscar outros tutoriais), com atualizações semanais de 1 a 3 aulas.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta aula, vamos explorar uma extensão do padrão ERC20, o ERC20Permit, que permite que as autorizações sejam feitas por meio de assinaturas, melhorando a experiência do usuário. Essa funcionalidade foi proposta no EIP-2612, foi incluída como um padrão Ethereum e é utilizada por tokens como USDC e ARB.

## ERC20

No [tutorial 31](https://github.com/AmazingAng/WTF-Solidity/blob/main/31_ERC20/readme.md), expliquei sobre o padrão ERC20, o padrão de token mais popular do Ethereum. Uma das razões principais de sua popularidade é a combinação das funções `approve` e `transferFrom`, que permitem que os tokens sejam transferidos não apenas entre contas externas (EOA), mas também entre contratos.

No entanto, a função `approve` do ERC20 limita as autorizações apenas para o proprietário do token, o que implica que todas as operações iniciais com tokens ERC20 devem ser feitas pela EOA. Por exemplo, se um usuário A estiver trocando USDT por ETH em uma exchange descentralizada, seria necessário realizar duas transações: a primeira para que o usuário A autorize o contrato a usar seus USDT e a segunda para realizar a troca. Isso é inconveniente e o usuário precisa ter ETH para pagar a taxa de transação.

## ERC20Permit

O EIP-2612 propôs o ERC20Permit, uma extensão do padrão ERC20 que introduz a função `permit`, que permite que os usuários modifiquem a autorização por meio de assinaturas EIP-712, sem depender do `msg.sender`. Isso traz duas principais vantagens:

1. A etapa de autorização requer apenas uma assinatura offline do usuário, reduzindo uma transação.
2. Após assinar, o usuário pode delegar a terceiros transações subsequentes, sem a necessidade de possuir ETH. Por exemplo, o usuário A pode enviar a assinatura para um terceiro B que possui ETH para executar as transações.

## Contratos

### Contrato de interface IERC20Permit

Primeiramente, vamos analisar o contrato de interface do ERC20Permit, que define 3 funções:

- `permit()`: permite que o `owner` assine e autorize a transferência de saldo ERC20 para o `spender`, na quantidade `value`. Requerimentos especiais:

    - O `spender` não pode ser um endereço zero.
    - O `deadline` deve ser um timestamp no futuro.
    - `v`, `r` e `s` devem ser uma assinatura válida em formato EIP712 com os parâmetros da função.
    - A assinatura deve utilizar o nonce atual do `owner`.

- `nonces()`: retorna o nonce atual do `owner`. Cada vez que a função `permit()` é chamada com sucesso, o nonce do `owner` é incrementado em 1 para evitar multiple signatures.

- `DOMAIN_SEPARATOR()`: retorna o separador de domínio utilizado para codificar a assinatura da função `permit`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface para a extensão ERC20 Permit, permitindo autorizações por assinatura, conforme definido no https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 */
interface IERC20Permit {
    /**
     * @dev Permite que o `owner` assine e autorize a transferência de saldo ERC20 para o `spender`, na quantidade `value`
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Retorna o nonce atual do `owner`. Cada vez que a função {permit} gera uma assinatura, este valor deve ser incluído.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Retorna o separador de domínio usado para codificar a assinatura da função {permit}
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
```

### Contrato ERC20Permit

A seguir, vamos escrever um contrato simples de ERC20Permit que implementa todas as funções definidas na interface IERC20Permit. O contrato possui 2 variáveis de estado:

- `_nonces`: um mapeamento de `address` para `uint` que registra o nonce atual de cada usuário.
- `_PERMIT_TYPEHASH`: uma constante que armazena o hash do tipo da função `permit()`.

O contrato possui 5 funções:

- Construtor: inicializa o nome e o símbolo do token.
- **`permit()`**: a função principal do ERC20Permit, que implementa o `permit()` da interface IERC20Permit. Ela verifica se a assinatura está atualizada, reconstrói a mensagem da assinatura usando `_PERMIT_TYPEHASH`, `owner`, `spender`, `value`, `nonce` e `deadline` e verifica se a assinatura é válida. Se a assinatura for válida, a função `approve()` do ERC20 é chamada para a ação de autorização.
- `nonces()`: implementa a função `nonces()` da interface IERC20Permit.
- `DOMAIN_SEPARATOR()`: implementa a função `DOMAIN_SEPARATOR()` da interface IERC20Permit.
- `_useNonce()`: uma função para consumir o `nonce`, retornar o nonce atual do usuário e incrementar em 1.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @dev Interface para a extensão ERC20 Permit, permitindo autorizações por assinatura, conforme definido no https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adiciona o método {permit}, que permite que as autorizações de saldo ERC20 de um proprietário sejam modificadas através de mensagens assinadas (veja {IERC20-allowance}). Não é necessário que o proprietário do token envie transações, pois as autorizações podem ser feitas sem a necessidade de ETH.
 */
contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Inicializa o EIP712 com o nome e o ERC20 com o nome e o símbolo.
     */
    constructor(string memory name, string memory symbol) EIP712(name, "1") ERC20(name, symbol){}

    /**
     * @dev Veja {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // Verifica o prazo limite
        require(block.timestamp <= deadline, "ERC20Permit: prazo expirado");

        // Concatena o Hash
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        
        // Calcula e verifica a assinatura
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: assinatura inválida");
        
        // Realiza a autorização
        _approve(owner, spender, value);
    }

    /**
     * @dev Veja {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev Veja {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consome nonce": retorna o `nonce` atual do `owner` e o incrementa em 1.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }
}
```

## Replica no Remix

1. Implante o contrato `ERC20Permit` com os valores `name` e `symbol` definidos como `WTFPermit`.

2. Execute o arquivo `signERC20Permit.html`, altere o `Contract Address` para o endereço do contrato `ERC20Permit` implantado e forneça as outras informações conforme indicado. Em seguida, clique em `Connect Metamask` e depois em `Sign Permit` para assinar e obter os valores `r`, `s` e `v` para a verificação no contrato. A assinatura deve ser realizada com a carteira conectada no ambiente de desenvolvimento, como a carteira no Remix.

    ```js
    owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4    spender: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    value: 100
    deadline: 115792089237316195423570985008687907853269984665640564039457584007913129639935
    private_key: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
    ```

3. Chame a função `permit()` do contrato com os parâmetros apropriados para realizar a autorização.

4. Chame a função `allance()` do contrato com os endereços `owner` e `spender` corretos para verificar a autorização.

## Considerações de Segurança

O uso do ERC20Permit para autorizações através de assinaturas traz conveniência aos usuários, mas também traz riscos. Alguns hackers podem explorar essa funcionalidade para realizar ataques de phishing, enganando os usuários a assinar transações e roubar seus ativos. Em abril de 2023, um ataque de phishing direcionado ao USDC resultou na perda de 228 mil unidades para um usuário.

**Ao assinar, é fundamental ler atentamente o conteúdo a ser assinado!**

## Conclusão

Nesta aula, exploramos o ERC20Permit, uma extensão do padrão ERC20 que permite que as autorizações sejam feitas por meio de assinaturas, melhorando a experiência do usuário e sendo adotada por diversos projetos. No entanto, essa funcionalidade também traz um risco maior, pois uma única assinatura pode permitir o roubo de ativos. Portanto, é essencial ser extremamente cuidadoso ao assinar mensagens.

