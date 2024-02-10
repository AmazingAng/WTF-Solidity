# WTF Solidity Simplified: 49. Procuração Universal e Atualizável

Recentemente, tenho revisado meus conhecimentos sobre solidity para consolidar os detalhes e também escrever um guia simplificado intitulado "WTF Solidity Simplified" para ajudar os iniciantes (os experts podem procurar por outras fontes de aprendizado). Estarei lançando de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website wtf.academy](https://wtf.academy)

Todo o código e guias estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, vamos falar sobre uma outra solução para o conflito de seletores em contratos de proxy: a Procuração Universal e Atualizável (UUPS, do inglês Universal Upgradeable Proxy Standard). O código de ensino foi simplificado a partir do `UUPSUpgradeable` do `OpenZeppelin` e não deve ser usado em produção.

## UUPS

Na última lição, vimos sobre o "conflito de seletores" (Selector Clash) em contratos que têm duas funções com seletores iguais, o que pode resultar em problemas graves. Como alternativa aos contratos de proxy transparente, a UUPS também resolve esse problema.

A UUPS (Procuração Universal e Atualizável) coloca a função de atualização no contrato lógico. Dessa forma, se houver outras funções que entrem em conflito com a função de atualização, um erro de compilação será gerado.

A tabela abaixo resume as diferenças entre contratos de atualização padrão, proxies transparentes e UUPS:

![Tipos de contratos de atualização](./img/49-1.png)

## Contrato de Procuração UUPS

O contrato de procuração UUPS parece um contrato de proxy não atualizável, porque a função de atualização está no contrato lógico. Ele possui `3` variáveis:
- `implementation`: endereço do contrato lógico.
- `admin`: endereço do administrador.
- `words`: uma string que pode ser alterada através de funções do contrato lógico.

Ele possui `2` funções:

- Constructor: inicializa o administrador e o endereço do contrato lógico.
- `fallback()`: função de fallback, que delega a chamada para o contrato lógico.

```solidity
contract UUPSProxy {
    address public implementation; // endereço do contrato lógico
    address public admin; // endereço do administrador
    string public words; // uma string que pode ser alterada através de funções do contrato lógico

    // Constructor: inicializa o administrador e o endereço do contrato lógico
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback function: delega a chamada para o contrato lógico
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
}
```

## Contrato Lógico UUPS

O contrato lógico UUPS, diferentemente do apresentado na [lição 47](../47_Upgrade/readme_pt-br.md), possui uma função adicional de atualização. O contrato contém `3` variáveis de estado, que são mantidas em comum com o contrato de procuração para evitar conflitos nos slots. Ele contém `2` funções:
- `upgrade()`: função de atualização, que altera o endereço do contrato lógico `implementation` e só pode ser chamada pelo `admin`.
- `foo()`: a versão antiga do contrato UUPS define `words` como `"old"`, enquanto a nova define como `"new"`.

```solidity
// Contrato lógico UUPS (função de atualização no contrato lógico)
contract UUPS1 {
    // Variáveis de estado comuns com o contrato de proxy para evitar conflitos nos slots
    address public implementation;
    address public admin;
    string public words; // uma string que pode ser alterada através de funções do contrato lógico

    // Altera as variáveis de estado do proxy - selector: 0xc2985578
    function foo() public {
        words = "old";
    }

    // Função de atualização, altera o endereço do contrato lógico
    // Pode ser chamada apenas pelo admin - selector: 0x0900f010
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// Novo contrato lógico UUPS
contract UUPS2 {
    // Variáveis de estado comuns com o contrato de proxy para evitar conflitos nos slots
    address public implementation;
    address public admin;
    string public words; // uma string que pode ser alterada através de funções do contrato lógico

    // Altera as variáveis de estado do proxy - selector: 0xc2985578
    function foo() public {
        words = "new";
    }

    // Função de atualização, altera o endereço do contrato lógico
    // Pode ser chamada apenas pelo admin - selector: 0x0900f010
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```

## Implementação no Remix

1. Implante os contratos lógicos UUPS1 e UUPS2.

2. Implante o contrato de procuração UUPS e aponte o endereço de `implementation` para o contrato lógico UUPS1.

3. Use o seletor `0xc2985578` para chamar a função `foo()` do contrato lógico UUPS1 e alterar o valor de `words` para `"old"`.

4. Utilize um codificador ABI online, como o HashEx, para obter a codificação binária e chame a função de atualização `upgrade()`, direcionando o endereço de `implementation` para o contrato lógico UUPS2.

5. Utilize o seletor `0xc2985578` para chamar a função `foo()` do contrato lógico UUPS2 e alterar o valor de `words` para `"new"`.

Nesta lição, aprendemos sobre a solução UUPS para o conflito de seletores em contratos de proxy. A UUPS coloca a função de atualização no contrato lógico para que conflitos de seletores não possam ser compilados. Comparado ao proxy transparente, o UUPS economiza gás, mas é mais complexo.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->