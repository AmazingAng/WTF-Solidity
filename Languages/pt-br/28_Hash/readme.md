# WTF Introdução Simples ao Solidity: 28. Hash

Recentemente, tenho revisado meus conhecimentos em Solidity, consolidando os detalhes e escrevendo uma "Introdução Simples ao Solidity" para iniciantes (os programadores avançados podem procurar outros tutoriais). Atualizo com 1-3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

Uma função de hash (hash function) é um conceito criptográfico que pode transformar uma mensagem de comprimento variável em um valor de comprimento fixo, também conhecido como hash. Nesta lição, vamos apresentar brevemente as funções de hash e sua aplicação em Solidity.

## Propriedades de um Hash

Uma função de hash de qualidade deve possuir as seguintes características:

- Unidirecionalidade: é fácil e único determinar o hash de uma mensagem de entrada, mas é difícil reverter o processo.
- Sensibilidade: uma pequena alteração na mensagem de entrada causa uma grande alteração no hash.
- Eficiência: o cálculo do hash a partir da mensagem de entrada deve ser eficiente.
- Uniformidade: a probabilidade de cada valor de hash deve ser praticamente igual.
- Resistência a colisões:
  - Resistência fraca a colisões: encontrar outra mensagem x' para a mensagem x, de modo que hash(x) = hash(x'), é difícil.
  - Resistência forte a colisões: é difícil encontrar quaisquer x e x' tal que hash(x) = hash(x').

## Aplicações de Hash

- Gerar identificadores únicos de dados
- Assinaturas criptografadas
- Criptografia segura

## Keccak256

A função `Keccak256` é a função de hash mais comum em Solidity e é utilizada da seguinte forma:

```solidity
hash = keccak256(data);
```

### Keccak256 e sha3

Existem algumas curiosidades interessantes:

1. O sha3 foi padronizado a partir do Keccak e, em muitos casos, ambos são sinônimos. No entanto, quando o SHA3 foi finalmente padronizado em agosto de 2015, o NIST ajustou o algoritmo de preenchimento. **Portanto, SHA3 e o resultado do cálculo do Keccak são diferentes**, e isso deve ser levado em consideração durante o desenvolvimento.
2. Quando o Ethereum estava sendo desenvolvido, o sha3 ainda estava em processo de padronização, então o Ethereum e o Solidity usam o Keccak256 para o sha3. Para evitar confusão, é mais claro escrever Keccak256 diretamente no código do contrato.

### Gerar Identificadores Únicos de Dados

Podemos usar o `keccak256` para gerar identificadores únicos de dados. Por exemplo, se tivermos diferentes tipos de dados, como `uint`, `string` e `address`, podemos empacotá-los com o método `abi.encodePacked` e usar o `keccak256` para gerar um identificador único:

```solidity
function hash(
    uint _num,
    string memory _string,
    address _addr
    ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_num, _string, _addr));
}
```

### Resistência Fraca a Colisões

Vamos usar o `keccak256` para demonstrar a resistência fraca a colisões mencionada anteriormente, ou seja, encontrar outra mensagem x' para a mensagem x de forma que hash(x) = hash(x') seja difícil.

Dado uma mensagem '0xAA', tentaremos encontrar outra mensagem para que os hashes sejam iguais: 

```solidity
// Resistência fraca a colisões
function weak(
    string memory string1
    )public view returns (bool){
    return keccak256(abi.encodePacked(string1)) == _msg;
}
```

Você pode tentar várias vezes para ver se consegue ter sorte e encontrar uma colisão.

### Resistência Forte a Colisões

Vamos construir uma função `strong` que recebe dois parâmetros `string` diferentes, `string1` e `string2`, e verifica se seus hashes são iguais:

```solidity
// Resistência forte a colisões
function strong(
        string memory string1,
        string memory string2
    )public pure returns (bool){
    return keccak256(abi.encodePacked(string1)) == keccak256(abi.encodePacked(string2));
}
```

Novamente, você pode tentar várias vezes para ver se consegue ter sorte e encontrar uma colisão.

## Verificação no Remix

- Deploy do contrato para visualizar os resultados dos identificadores gerados

    ![28-1](./img/28-1.png)

- Verificar a sensibilidade da função de hash, bem como a resistência forte e fraca a colisões

    ![28-2](./img/28-2.png)

## Conclusão

Nesta lição, discutimos o que é uma função de hash e como usar a função de hash mais comum em Solidity, o `keccak256`.

