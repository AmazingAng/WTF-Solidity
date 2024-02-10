---
title: 2. Tipos de Valor
tags:
  - solidity
  - básico
  - wtfacademy
---

# WTF Introdução Simplificada ao Solidity: 2. Tipos de Valor

Recentemente, tenho revisado Solidity para consolidar alguns detalhes e estou escrevendo um "WTF Introdução Simplificada ao Solidity" para ajudar iniciantes (programadores avançados podem procurar outros tutoriais). Será atualizado semanalmente com 1-3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Todo o código e tutorial estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## Tipos de Variáveis no Solidity

1. **Tipo de Valor (Value Type)**: incluem booleanos, inteiros, etc., esses tipos de variáveis passam diretamente o valor ao serem atribuídas.

2. **Tipo de Referência (Reference Type)**: incluem arrays e structs, esses tipos de variáveis ocupam mais espaço e passam o endereço diretamente ao serem atribuídas (semelhante a ponteiros).

3. **Tipo de Mapeamento (Mapping Type)**: Estrutura de dados para armazenar pares chave-valor no Solidity, pode ser entendido como uma tabela de hash.

Vamos abordar apenas os tipos comuns, os tipos menos utilizados não serão abordados, e neste artigo, falaremos sobre tipos de valor.

## Tipos de Valor

### 1. Booleano

O tipo booleano é uma variável binária, com valores `true` ou `false`.

```solidity
// Booleano
bool public _bool = true;
```

Os operadores booleanos incluem:

- `!` (negação lógica)
- `&&` (e lógico, "and")
- `||` (ou lógico, "or")
- `==` (igual a)
- `!=` (diferente de)

```solidity
// Operações booleanas
bool public _bool1 = !_bool; // negação
bool public _bool2 = _bool && _bool1; // e
bool public _bool3 = _bool || _bool1; // ou
bool public _bool4 = _bool == _bool1; // igual
bool public _bool5 = _bool != _bool1; // diferente
```

No código acima: a variável `_bool` possui o valor `true`; `_bool1` é a negação de `_bool`, ou seja, `false`; `_bool && _bool1` é `false`; `_bool || _bool1` é `true`; `_bool == _bool1` é `false`; `_bool != _bool1` é `true`.

**Observe que:** os operadores `&&` e `||` seguem a regra da avaliação de curto-circuito, o que significa que, se houver uma expressão `f(x) || g(y)`, e `f(x)` for `true`, `g(y)` não será avaliado, mesmo que o resultado seja o oposto de `f(x)`. Da mesma forma, se houver uma expressão `f(x) && g(y)`, e `f(x)` for `false`, `g(y)` não será avaliado.

### 2. Inteiro

Os inteiros são tipos de dados inteiros no Solidity, os mais comuns são:

```solidity
// Inteiros
int public _int = -1; // inteiro, incluindo números negativos
uint public _uint = 1; // inteiro positivo
uint256 public _number = 20220330; // inteiro positivo de 256 bits
```

Os operadores de inteiro comuns incluem:

- Operadores de comparação (retornam um valor booleano): `<=`, `<`, `==`, `!=`, `>=`, `>`
- Operadores aritméticos: `+`, `-`, `*`, `/`, `%` (resto da divisão), `**` (potenciação)

```solidity
// Operações com inteiros
uint256 public _number1 = _number + 1; // +, -, *, /
uint256 public _number2 = 2**2; // potenciação
uint256 public _number3 = 7 % 2; // resto da divisão
bool public _numberbool = _number2 > _number3; // comparação
```

Você pode executar o código acima para ver os valores das 4 variáveis.

### 3. Endereço

O tipo de dado endereço (address) possui duas variantes:

- Endereço normal (address): armazena um valor de 20 bytes (tamanho de um endereço Ethereum).
- Endereço pagável (payable address): além do endereço normal, inclui os métodos `transfer` e `send` para receber transferências de Ether.

Falaremos mais sobre endereços pagáveis em capítulos posteriores.

```solidity
// Endereço
address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
address payable public _address1 = payable(_address); // endereço pagável, permite transferências e verificar saldo
// Membros do tipo de endereço
uint256 public balance = _address1.balance; // saldo do endereço
```

### 4. Arrays de Bytes de Comprimento Fixo

Os arrays de bytes podem ser de comprimento fixo ou variável:

- Arrays de bytes de comprimento fixo: são tipos de valor, o comprimento do array não pode ser alterado após a declaração. Existem tipos como `bytes1`, `bytes8`, `bytes32`, etc. O máximo é armazenar 32 bytes, ou seja, `bytes32`.
- Arrays de bytes de comprimento variável: são tipos de referência (serão abordados em capítulos posteriores), o comprimento do array pode ser alterado após a declaração, como o tipo `bytes`.

```solidity
// Array de Bytes de Comprimento Fixo
bytes32 public _byte32 = "MiniSolidity"; 
bytes1 public _byte = _byte32[0]; 
```

No código acima, a variável `MiniSolidity` é armazenada em `_byte32` como uma sequência de bytes. Se convertido para hexadecimal, seria: `0x4d696e69536f6c69646974790000000000000000000000000000000000000000`

O valor de `_byte` será o primeiro byte de `_byte32`, ou seja, `0x4d`.

### 5. Enum (Enumerado)

Enum é um tipo de dado que pode ser definido pelo usuário no Solidity. Geralmente é usado para atribuir nomes a `uint`, facilitando a leitura e manutenção do código. Se parece com `enum` em linguagens como C, onde os nomes são atribuídos a partir de `0`.

```solidity
// Definindo um enum para Buy, Hold e Sell
enum ActionSet { Buy, Hold, Sell }
// Criando uma variável enum chamada action
ActionSet action = ActionSet.Buy;
```

É possível converter explicitamente `enum` em `uint` e vice-versa, e o Solidity verificaria se o inteiro positivo convertido está dentro do intervalo do `enum`, caso contrário, ocorrerá um erro:

```solidity
// Conversão explícita de enum em uint
function enumToUint() external view returns(uint){
    return uint(action);
}
```

O `enum` é um tipo de dados pouco utilizado, raramente usado.

## Executando no Remix

- Após a implantação do contrato, é possível verificar os valores das variáveis de cada tipo:

![2-1.png](./img/2-1.png)
  
- Exemplo de conversão entre `enum` e `uint`:

![2-2.png](./img/2-2.png)
![2-3.png](./img/2-3.png)

## Conclusão

Neste artigo, apresentamos os tipos de valor no Solidity, incluindo booleanos, inteiros, endereços, arrays de bytes de comprimento fixo e enum. Nos próximos capítulos, continuaremos discutindo outros tipos de variáveis no Solidity, como os tipos de referência e mapeamento.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->