# 46. Contrato de Proxy

Eu tenho revisado solidity recentemente para consolidar alguns detalhes e escrever um "Guia Simplificado para Solidity" para iniciantes (programadores experientes podem procurar outras referências). Vou atualizar o guia com 1-3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site Oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos falar sobre Contratos de Proxy. O código de ensino é uma versão simplificada do contrato de Proxy do [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol).

## Modo de Proxy

Os contratos `Solidity` são imutáveis após serem implantados na cadeia. Isso tem suas vantagens e desvantagens:

- Vantagens: segurança, os usuários sabem o que esperar (na maioria das vezes).
- Desvantagens: mesmo que haja um bug no contrato, não é possível modificá-lo ou atualizá-lo, apenas implantar um novo contrato. Além disso, o novo contrato terá um endereço diferente do anterior, e a migração dos dados do contrato existente para o novo exigirá um alto consumo de gas.

Existe uma maneira de modificar ou atualizar contratos após a implantação? Sim, através do **modo de proxy**.

![Modo de Proxy](./img/46-1.png)

No modo de proxy, os dados e a lógica do contrato são separados, armazenados em contratos diferentes. Usando o simples contrato de proxy mostrado no diagrama acima como exemplo, os dados (variáveis de estado) são armazenados no contrato de proxy, enquanto a lógica (funções) é armazenada em outro contrato de lógica. O contrato de proxy delega toda a chamada de função para o contrato de lógica usando `delegatecall` e depois retorna o resultado final ao chamador.

O modo de proxy tem duas principais vantagens:
1. Atualização: quando precisamos atualizar a lógica do contrato, basta direcionar o contrato de proxy para o novo contrato de lógica.
2. Economia de gas: se vários contratos reutilizarem a mesma lógica, basta implantar um contrato de lógica e, em seguida, implantar vários contratos de proxy que armazenam apenas os dados e se conectam à lógica central.

**Dica**: Se você não está familiarizado com o `delegatecall`, pode conferir a [Lição 23 do tutorial](../23_Delegatecall).

## Contrato de Proxy

Aqui está um contrato de Proxy simples, simplificado a partir do contrato de [Proxy do OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol). Ele consiste em três partes: Contrato de Proxy `Proxy`, Contrato de Lógica `Logic` e um exemplo de chamada `Caller`. O código é simples:

1. Implante o contrato de lógica `Logic` primeiro.
2. Crie o contrato de proxy `Proxy`, onde a variável de estado `implementation` registra o endereço do contrato `Logic`.
3. O contrato `Proxy` usa a função de callback `fallback` para delegar todas as chamadas ao contrato `Logic`.
4. Por fim, implante o contrato de chamada `Caller` e chame o contrato de Proxy.

### Contrato de Proxy `Proxy`

O contrato de `Proxy` é curto, mas usa linguagem de montagem inline, o que pode tornar o entendimento um pouco mais desafiador. Possui apenas uma variável de estado, um construtor e uma função de fallback. A variável de estado `implementation` é inicializada no construtor e é usada para armazenar o endereço do contrato `Logic`.

```solidity
contract Proxy {
    address public implementation; // endereço do contrato de lógica

    /**
     * @dev Inicializa o endereço do contrato de lógica
     */
    constructor(address implementation_){
        implementation = implementation_;
    }
```

A função de fallback do `Proxy` encaminha todas as chamadas externas para o contrato `Logic` usando `delegatecall`. Esta função de fallback é única, pois permite a devolução de valores mesmo sem um valor de retorno padrão. Ela usa operações de montagem inline como `calldatacopy`, `delegatecall`, `returndatacopy` e outras para realizar a ação corretamente.

```solidity
/**
 * @dev Função de fallback, delega a chamada desse contrato para o contrato `implementation`
 * Usa montagem para permitir o retorno de valores mesmo sem um valor de retorno padrão
 */
fallback() external payable {
    address _implementation = implementation;
    assembly {
        // Copia calldata para a memória
        calldatacopy(0, 0, calldatasize())

        // Chama o contrato 'implementation' por meio do delegatecall
        let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

        // Copia o retorno para a memória
        returndatacopy(0, 0, returndatasize())

        switch result
        case 0 {
            revert(0, returndatasize())
        }
        default {
            return(0, returndatasize())
        }
    }
}
```

### Contrato de Lógica `Logic`

Este é um contrato de lógica muito simples, criado apenas para fins de demonstração do contrato de Proxy. Ele contém `2` variáveis, `1` evento e `1` função:

- `implementation`: variável de espaço reservado, mantida consistente com o contrato de `Proxy` para evitar conflitos de slots.
- `x`: variável `uint` definida como `99`.
- `CallSuccess`: evento acionado quando a chamada é bem-sucedida.
- `increment()`: função que será chamada pelo contrato de `Proxy`, acionando o evento `CallSuccess`, e retornando um `uint`, cujo selecionador é `0xd09de08a`. Quando chamada diretamente, a função retornaria `100`, mas chamada através do `Proxy` retornará `1`.

```solidity
/**
 * @dev Contrato de lógica para executar as chamadas delegadas
 */
contract Logic {
    address public implementation; // mantido consistente com Proxy para evitar conflitos de slots
    uint public x = 99;
    event CallSuccess();

    // Esta função aciona o evento CallSuccess e retorna um uint
    // Selector da função: 0xd09de08a
    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
    }
}
```

### Contrato de Chamada `Caller`

O contrato `Caller` demonstra como chamar um contrato de proxy. É um contrato simples que precisa que você entenda as lições sobre `call` e `ABI encoding`.

Possui `1` variável e `2` funções:

- `proxy`: variável de estado que armazena o endereço do contrato de proxy.
- Construtor: inicializa a variável `proxy` ao implantar o contrato.
- `increase()`: chama a função `increment()` do contrato de proxy usando `call` e retorna um `uint`. Para realizar a chamada, usamos `abi.encodeWithSignature()` para obter o seletor da função `increment()`, e para decodificar o valor de retorno, usamos `abi.decode()`.

```solidity
/**
 * @dev Contrato Caller que chama o contrato de Proxy e obtém o resultado
 */
contract Caller{
    address public proxy; // endereço do contrato de proxy

    constructor(address proxy_){
        proxy = proxy_;
    }

    // Chama a função increment() através do contrato de Proxy
    function increment() external returns(uint) {
        ( , bytes memory data) = proxy.call(abi.encodeWithSignature("increment()"));
        return abi.decode(data,(uint));
    }
}
```

## Demonstração no `Remix`

1. Implante o contrato de `Logic`.

2. Chame a função `increment()` do contrato de `Logic`, que retorna `100`.

3. Implante o contrato de `Proxy` e forneça o endereço do contrato de `Logic`.

4. Chame a função `increment()` do contrato de `Proxy`, sem retorno.

5. Implante o contrato `Caller` e forneça o endereço do contrato de `Proxy`.

6. Chame a função `increment()` do contrato `Caller`, que retornará `1`.

## Conclusão

Nesta lição, apresentamos o modo de proxy e um contrato de proxy simples. O contrato de proxy utiliza a função `delegatecall` para delegar chamadas de função para outro contrato de lógica, separando assim os dados e a lógica em contratos diferentes. Além disso, ele utiliza operações de montagem inline para permitir que a função de fallback, que normalmente não teria um valor de retorno, retorne dados. A pergunta que deixamos para você foi: por que chamar `increment()` através do Proxy retornará `1`? De acordo com a [Lição 23 sobre delegatecall](../23_Delegatecall/readme_pt-br.md), ao chamar uma função do contrato de lógica através do contrato de proxy, qualquer operação que modifique ou leia variáveis de estado no contrato de lógica afetará as variáveis de estado correspondentes no contrato de proxy. Como a variável `x` do contrato de proxy não foi definida (ou seja, corresponde ao zero na posição de armazenamento do contrato de proxy), chamar `increment()` através do Proxy retornará `1`.

Na próxima lição, veremos contratos de proxy atualizáveis.

Embora os contratos de proxy sejam poderosos, eles também são propensos a bugs, então é recomendável copiar os modelos de contratos do [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy).

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->