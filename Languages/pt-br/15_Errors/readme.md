# WTF Introdução Simples ao Solidity: 15. Exceções

Recentemente, tenho revisado o Solidity para reforçar alguns detalhes e estou escrevendo um "Guia Simples do Solidity" para iniciantes (os experts em programação podem procurar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site da WTF Academy](https://wtf.academy)

Todo código e tutorial estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos falar sobre os três métodos para lançar exceções no Solidity: `error`, `require` e `assert`, e comparar o consumo de `gas` entre eles.

## Exceções

Ao escrever contratos inteligentes, é comum encontrar bugs. Os comandos de exceção do Solidity nos ajudam a fazer depuração.

### Error

`error` é um recurso adicionado na versão 0.8.4 do Solidity, que permite explicar de forma eficiente (e econômica em termos de `gas`) o motivo de uma operação falhar. É possível definir exceções fora dos contratos. Abaixo, definimos a exceção `TransferNotOwner`, que é lançada quando alguém que não é o dono da moeda tenta fazer uma transferência:

```solidity
error TransferNotOwner(); // Erro personalizado
```

Também podemos definir uma exceção com parâmetros, para mostrar o endereço que tentou fazer a transferência:

```solidity
error TransferNotOwner(address sender); // Erro personalizado com parâmetros
```

Durante a execução, o `error` deve ser usado em conjunto com o comando `revert`:

```solidity
function transferOwner1(uint256 tokenId, address newOwner) public {
    if(_owners[tokenId] != msg.sender){
        revert TransferNotOwner();
        // revert TransferNotOwner(msg.sender);
    }
    _owners[tokenId] = newOwner;
}
```

Definimos a função `transferOwner1()`, que verifica se o remetente é o dono da moeda. Se não for, uma exceção de `TransferNotOwner` é lançada; se for, a transferência é feita.

### Require

O comando `require` é uma maneira comum de lançar exceções antes da versão 0.8 do Solidity e ainda é amplamente utilizado. A desvantagem do `require` é que o consumo de `gas` aumenta com o tamanho da descrição da exceção, em comparação com o comando `error`. A sintaxe é: `require(condição de verificação, "descrição da exceção")`. Quando a condição não é atendida, uma exceção é lançada.

Podemos reescrever a função `transferOwner1` usando o comando `require`:

```solidity
function transferOwner2(uint256 tokenId, address newOwner) public {
    require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
    _owners[tokenId] = newOwner;
}
```

### Assert

O comando `assert` geralmente é usado pelos programadores durante a depuração do código, pois não fornece uma explicação do motivo da exceção (ao contrário do `require`). A sintaxe é simples: `assert(condição)`. Se a condição não for atendida, uma exceção é lançada.

Podemos reescrever a função `transferOwner1` usando o comando `assert`:

```solidity
function transferOwner3(uint256 tokenId, address newOwner) public {
    assert(_owners[tokenId] == msg.sender);
    _owners[tokenId] = newOwner;
}
```

## Verificação no Remix

1. Insira um número `uint256` qualquer e um endereço não nulo, chame a função `transferOwner1` (com `error`), e no console do Remix será exibida a nossa exceção customizada `TransferNotOwner`.

2. Insira um número `uint256` qualquer e um endereço não nulo, chame a função `transferOwner2` (com `require`), e no console do Remix será exibida a descrição da exceção do comando `require`.

3. Insira um número `uint256` qualquer e um endereço não nulo, chame a função `transferOwner3` (com `assert`), e apenas a exceção será lançada no console do Remix.

## Comparação de consumo de gas entre os métodos

Comparamos o consumo de `gas` dos três métodos de exceção no Remix, usando o botão de Debug do console, encontramos os seguintes valores:
(compilado com a versão 0.8.17)

1. **Consumo de `gas` do método `error`**: 24457  (**Com parâmetro, consumo de `gas`**: 24660)
2. **Consumo de `gas` do método `require`**: 24755
3. **Consumo de `gas` do método `assert`**: 24473

Podemos observar que o método `error` é o que consome menos `gas`, seguido pelo `assert`, e o `require` consome mais `gas`. Portanto, o `error` é uma boa opção, pois informa o motivo da exceção e consome menos `gas`.

**Observação:** Antes da versão 0.8.0 do Solidity, o `assert` lançava uma `panic exception` que consumia todo o `gas` restante, sem reembolso. Mais detalhes podem ser encontrados na [documentação oficial](https://docs.soliditylang.org/en/v0.8.17/control-structures.html).

## Conclusão

Nesta lição, aprendemos sobre os três métodos para lançar exceções no Solidity: `error`, `require` e `assert`, e comparamos o consumo de `gas` entre eles. Concluímos que o `error` é uma opção eficiente, pois fornece explicação da exceção e consome menos `gas`.

