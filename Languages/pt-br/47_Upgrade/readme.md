# WTF Solidity Simplificado: 47. Contrato Atualizável

Recentemente, tenho revisitado o estudo de solidity para consolidar os detalhes e escrever um "WTF Solidity Simplificado", destinado aos iniciantes (os profissionais de programação podem buscar outros tutoriais). Atualizo de 1 a 3 aulas por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais são disponibilizados no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

Nesta aula, vamos falar sobre contratos atualizáveis (Upgradeable Contracts). O contrato utilizado neste tutorial é uma simplificação de contratos da `OpenZeppelin` e pode apresentar problemas de segurança, portanto, não deve ser utilizado em ambiente de produção.

## Contrato Atualizável

Se você entendeu o conceito de contrato de proxy, será fácil compreender o contrato atualizável. Ele é um contrato de proxy que pode alterar o contrato lógico.

![](./img/47-1.png)

## Implementação Simples

A seguir, vamos implementar um contrato atualizável simples, que inclui `3` contratos: contrato de proxy, contrato lógico antigo e contrato lógico novo.

### Contrato de Proxy

Este contrato de proxy é mais simples do que o apresentado na [aula anterior](../46_ProxyContract/readme_pt-br.md). Neste caso, não utilizamos `assembly inline` no método `fallback()`, mas simplesmente `implementation.delegatecall(msg.data);`. Portanto, a função de retorno não possui valor, mas é suficiente para fins educacionais.

Ele possui `3` variáveis:
- `implementation`: endereço do contrato lógico.
- `admin`: endereço do admin.
- `words`: string que pode ser alterada por meio de funções do contrato lógico.

Ele possui `3` funções:

- Construtor: inicializa o admin e o endereço do contrato lógico.
- `fallback()`: função de fallback, que delega a chamada para o contrato lógico.
- `upgrade()`: função de atualização que altera o endereço do contrato lógico e só pode ser chamada pelo `admin`.

```solidity
// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// Contrato atualizável simples, no qual o admin pode alterar o endereço do contrato lógico usando a função de atualização, modificando assim a lógica do contrato.
// Apenas para fins educacionais, não deve ser utilizado em ambiente de produção. 
contract SimpleUpgrade {
    address public implementation; // Endereço do contrato lógico
    address public admin; // Endereço do admin
    string public words; // String que pode ser alterada por meio de funções do contrato lógico

    // Construtor, inicializa o admin e o endereço do contrato lógico
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // Função fallback, delega a chamada para o contrato lógico
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // Função de atualização, altera o endereço do contrato lógico e só pode ser chamada pelo admin
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```

### Contrato Lógico Antigo

Este contrato lógico possui `3` variáveis de estado, mantendo a consistência com o contrato de proxy e evitando conflito de slots. Ele possui apenas a função `foo()`, que altera o valor da variável `words` do contrato de proxy para `"old"`.

```solidity
// Contrato lógico 1
contract Logic1 {
    // Variáveis de estado que coincidem com as do contrato de proxy, evitando conflito de slots
    address public implementation;
    address public admin;
    string public words; // String que pode ser alterada por meio de funções do contrato lógico

    // Altera a variável de estado do contrato de proxy, seletor: 0xc2985578
    function foo() public{
        words = "old";
    }
}
```

### Contrato Lógico Novo

Este contrato lógico também possui `3` variáveis de estado, mantendo a consistência com o contrato de proxy. Ele possui apenas a função `foo()`, que altera o valor da variável `words` do contrato de proxy para `"new"`.

```solidity
// Contrato lógico 2
contract Logic2 {
    // Variáveis de estado que coincidem com as do contrato de proxy, evitando conflito de slots
    address public implementation;
    address public admin;
    string public words; // String que pode ser alterada por meio de funções do contrato lógico

    // Altera a variável de estado do contrato de proxy, seletor: 0xc2985578
    function foo() public{
        words = "new";
    }
}
```

## Implementação no Remix

1. Implante os contratos lógicos antigos e novos, `Logic1` e `Logic2`.
2. Implante o contrato atualizável `SimpleUpgrade` e defina o endereço de `implementation` para o contrato lógico antigo.
3. Utilize o seletor `0xc2985578` para chamar a função `foo()` do contrato lógico antigo `Logic1` no contrato de proxy, alterando o valor de `words` para `"old"`.
4. Chame a função `upgrade()` para definir o endereço de `implementation` para o contrato lógico novo `Logic2`.
5. Utilize o seletor `0xc2985578` para chamar a função `foo()` do contrato lógico novo `Logic2` no contrato de proxy, alterando o valor de `words` para `"new"`.

Este tutorial apresentou um contrato atualizável simples, que adiciona a funcionalidade de atualização a contratos inteligentes que normalmente não são alteráveis. No entanto, este contrato possui um problema de `conflito de seletores`, representando um risco de segurança. Nas próximas aulas, iremos abordar os contratos atualizáveis padrão, como o proxy transparente e o `UUPS`.

