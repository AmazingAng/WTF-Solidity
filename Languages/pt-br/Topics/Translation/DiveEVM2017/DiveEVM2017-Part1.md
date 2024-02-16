# Explorando a Máquina Virtual Ethereum Parte 1 - Assembly e Bytecode

> Original: [Diving Into The Ethereum Virtual Machine | by Howard | Aug 6, 2017](https://blog.qtum.org/diving-into-the-ethereum-vm-6e8d5d2f3c30)

Solidity fornece muitas abstrações de linguagem de alto nível, mas esses recursos tornam difícil entender o que realmente acontece durante a execução do programa. Ainda me sinto confuso sobre coisas muito básicas ao ler a documentação do Solidity.

Qual é a diferença entre `string`, `bytes32`, `byte[]` e `bytes`?

* Qual devo usar? Quando devo usar?
* O que acontece quando converto uma `string` para `bytes`? Posso converter para `byte[]`?
* Quanto custam em termos de gas?

Como o mapeamento (*mapping*) é armazenado na EVM?

* Por que não é possível excluir um mapeamento?
* É possível ter um mapeamento de mapeamento? (Sim, mas como isso funciona?)
* Por que existe mapeamento de armazenamento (*storage mapping*) mas não mapeamento de memória (*memory mapping*)?

Como é um contrato compilado para a EVM?

* Como um contrato é criado?
* O que é o `constructor`? É real?
* O que é a função `fallback`?

Acredito que aprender como linguagens de alto nível como Solidity funcionam na Máquina Virtual Ethereum (EVM) é um bom investimento. Por várias razões.

1. Solidity não é a última linguagem. Melhores linguagens EVM virão.
2. A EVM é um mecanismo de banco de dados. Para entender como os contratos inteligentes funcionam em qualquer linguagem EVM, é necessário entender como os dados são organizados, armazenados e manipulados.
3. Saber como se tornar um contribuidor. A ferramentachain Ethereum ainda está em estágios iniciais. Ter um conhecimento profundo da EVM ajudará você a criar ótimas ferramentas para si mesmo e para os outros.
4. Desafio intelectual. A EVM oferece uma ótima oportunidade para trabalhar na interseção da criptografia, estruturas de dados e design de linguagens de programação.

Nesta série de artigos, pretendo desmontar contratos simples do Solidity para entender como eles funcionam como bytecode na EVM.

Aqui está um esboço do que espero aprender e escrever:

* Conhecimento básico de bytecode da EVM
* Como representar diferentes tipos (mapeamentos, arrays)
* O que acontece quando um novo contrato é criado
* O que acontece quando uma função é chamada
* Como a ABI conecta diferentes linguagens EVM

Meu objetivo final é ter uma compreensão completa de um contrato Solidity compilado. Vamos começar lendo alguns bytecode básicos da EVM!

Este [conjunto de instruções da EVM](https://gist.github.com/hayeah/bd37a123c02fecffbe629bf98a8391df) será uma referência útil.

## Um Contrato Simples

Nosso primeiro contrato tem um construtor e uma variável de estado:

```solidity
// c1.sol
pragma solidity ^0.4.11;
contract C {
	uint256 a;
	function C() {
		a = 1;
	}
}
```

(Observação: O Solidity atualmente usa a palavra-chave `constructor` para declarar o construtor)

Compile o contrato usando `solc`:

```shell
$ solc --bin --asm c1.sol
======= c1.sol:C =======
EVM assembly:
    /* "c1.sol":26:94  contract C {... */
  mstore(0x40, 0x60)
    /* "c1.sol":59:92  function C() {... */
  jumpi(tag_1, iszero(callvalue))
  0x0
  dup1
  revert
tag_1:
tag_2:
    /* "c1.sol":84:85  1 */
  0x1
    /* "c1.sol":80:81  a */
  0x0
    /* "c1.sol":80:85  a = 1 */
  dup2
  swap1
  sstore
  pop
    /* "c1.sol":59:92  function C() {... */
tag_3:
    /* "c1.sol":26:94  contract C {... */
tag_4:
  dataSize(sub_0)
  dup1
  dataOffset(sub_0)
  0x0
  codecopy
  0x0
  return
stop
sub_0: assembly {
        /* "c1.sol":26:94  contract C {... */
      mstore(0x40, 0x60)
    tag_1:
      0x0
      dup1
      revert
auxdata: 0xa165627a7a72305820af3193f6fd31031a0e0d2de1ad2c27352b1ce081b4f3c92b5650ca4dd542bb770029
}
Binary:
60606040523415600e57600080fd5b5b60016000819055505b5b60368060266000396000f30060606040525b600080fd00a165627a7a72305820af3193f6fd31031a0e0d2de1ad2c27352b1ce081b4f3c92b5650ca4dd542bb770029
```

O número `6060604052...` é o bytecode real que será executado na EVM.

## Passo a Passo

Metade do código de montagem compilado é boilerplate e é semelhante na maioria dos programas Solidity. Vamos revisar isso mais tarde. Por enquanto, vamos dar uma olhada na parte única do contrato, que é a atribuição de variável de armazenamento aparentemente insignificante:

```shell
a = 1
```

Essa atribuição é representada pelo bytecode `6001600081905550`. Vamos quebrá-lo em uma instrução por linha:

```shell
60 01
60 00
81
90
55
50
```

A EVM é basicamente uma máquina de pilha, onde as instruções podem usar valores na pilha como parâmetros e empilhar valores como resultado. Vamos considerar a operação `add`.

Suponha que a pilha tenha dois valores:

```shell
[1, 2]
```

Quando a EVM encontra a instrução `add`, ela soma os dois itens do topo da pilha e empilha o resultado no topo da pilha, resultando em:

```shell
[3]
```

No texto a seguir, usaremos `[]` para indicar a pilha:

```shell
// pilha vazia
stack: []
// pilha com 3 itens. O topo é 3, a base é 1.
stack: [3 2 1]
```

E usaremos `{}` para indicar o armazenamento do contrato:

```shell
// armazenamento vazio
store: {}
// valor 0x1 armazenado na posição 0x0
store: { 0x0 => 0x1 }
```

Agora vamos olhar para o bytecode real. Vamos simular a sequência de bytecode `6001600081905550` como a EVM faria e imprimir o estado da máquina após cada instrução:

```shell
// 60 01: empilha 1
0x1
  stack: [0x1]
// 60 00: empilha 0
0x0
  stack: [0x0 0x1]
// 81: duplica o segundo item da pilha
dup2
  stack: [0x1 0x0 0x1]
// 90: troca os dois itens do topo da pilha
swap1
  stack: [0x0 0x1 0x1]
// 55: armazena o valor 0x1 na posição 0x0
// essa instrução consome os dois itens do topo da pilha
sstore
  stack: [0x1]
  store: { 0x0 => 0x1 }
// 50: pop (remove o item do topo da pilha)
pop
  stack: []
  store: { 0x0 => 0x1 }
```

Fim. A pilha está vazia e há um item no armazenamento.

Observe que o Solidity decidiu armazenar a variável de estado `uint256 a` na posição `0x0`. Outras linguagens podem escolher armazenar a variável de estado em outro lugar.

Em pseudocódigo, o que a EVM fez com `6001600081905550` é basicamente:

```shell
// a = 1
sstore(0x0, 0x1)
```

Olhando mais de perto, você pode perceber que `dup2`, `swap1` e `pop` são redundantes. O código de montagem poderia ser mais simples.

```shell
0x1
0x0
sstore
```

Você pode tentar simular as três instruções acima e ter certeza de que elas realmente levam ao mesmo estado da máquina:

```shell
stack: []
store: { 0x0 => 0x1 }
```

## Duas Variáveis de Armazenamento

Vamos adicionar uma variável de armazenamento adicional do mesmo tipo:

```solidity
// c2.sol
pragma solidity ^0.4.11;
contract C {
	uint256 a;
	uint256 b;
	function C() {
		a = 1;
		b = 2;
	}
}
```

Compile o contrato e preste atenção em `tag_2`:

```shell
$ solc --bin --asm c2.sol
// ... mais coisas omitidas
tag_2:
    /* "c2.sol":99:100  1 */
  0x1
    /* "c2.sol":95:96  a */
  0x0
    /* "c2.sol":95:100  a = 1 */
  dup2
  swap1
  sstore
  pop
    /* "c2.sol":112:113  2 */
  0x2
    /* "c2.sol":108:109  b */
  0x1
    /* "c2.sol":108:113  b = 2 */
  dup2
  swap1
  sstore
  pop
```

O pseudocódigo do bytecode é:

```shell
// a = 1
sstore(0x0, 0x1)
// b = 2
sstore(0x1, 0x2)
```

Aqui aprendemos que as duas variáveis de armazenamento são localizadas uma após a outra, com `a` na posição `0x0` e `b` na posição `0x1`.

## Empacotamento de Armazenamento

Cada slot de armazenamento pode armazenar 32 bytes. Se uma variável precisa apenas de 16 bytes, usar todos os 32 bytes seria um desperdício. Se possível, o Solidity otimiza a eficiência de armazenamento empacotando dois tipos de dados menores em um único slot de armazenamento.

Vamos alterar `a` e `b` para terem apenas 16 bytes cada:

```solidity
pragma solidity ^0.4.11;
contract C {
	uint128 a;
	uint128 b;
	function C() {
		a = 1;
		b = 2;
	}
}
```

Compile o contrato:

```shell
$ solc --bin --asm c3.sol
```

O código de montagem gerado é mais complexo:

```shell
tag_2:
  // a = 1
  0x1
  0x0
  dup1
  0x100
  exp
  dup2
  sload
  dup2
  0xffffffffffffffffffffffffffffffff
  mul
  not
  and
  swap1
  dup4
  0xffffffffffffffffffffffffffffffff
  and
  mul
  or
  swap1
  sstore
  pop
  // b = 2
  0x2
  0x0
  0x10
  0x100
  exp
  dup2
  sload
  dup2
  0xffffffffffffffffffffffffffffffff
  mul
  not
  and
  swap1
  dup4
  0xffffffffffffffffffffffffffffffff
  and
  mul
  or
  swap1
  sstore
  pop
```

O bytecode é:

```shell
60608060020a03199091166001176001608060020a0316179055
```

Formatando o bytecode para uma instrução por linha:

```shell
// push 0x0
60 00
// push 0x1
60 01
// push 0x100
60 80
// push 0x100
60 80
// exp
0a
// duplica o segundo item da pilha
80
// carrega o valor do armazenamento
54
// duplica o segundo item da pilha
80
// push 0xffffffffffffffffffffffffffffffff
60 ff
// multiplica
ff
// negação
19
// and
90
// troca os dois itens do topo da pilha
91
// duplica o quarto item da pilha
94
// push 0xffffffffffffffffffffffffffffffff
60 ff
// and
ff
// multiplica
94
// ou
17
// troca os dois itens do topo da pilha
91
// armazena o valor 0x1 na posição 0x0
55

// push 0x2
60 02
// push 0x0
60 00
// push 0x10
60 10
// push 0x100
60 80
// exp
0a
// duplica o segundo item da pilha
80
// carrega o valor do armazenamento
54
// duplica o segundo item da pilha
80
// push 0xffffffffffffffffffffffffffffffff
60 ff
// multiplica
ff
// negação
19
// and
90
// troca os dois itens do topo da pilha
91
// duplica o quarto item da pilha
94
// push 0xffffffffffffffffffffffffffffffff
60 ff
// and
ff
// multiplica
94
// ou
17
// troca os dois itens do topo da pilha
91
// armazena o valor 0x2 na posição 0x1
55
```

O código de montagem usa quatro valores mágicos:

* 0x1 (16 bytes), usando os 16 bytes mais baixos

```shell
// representado em bytecode como 0x01
16:32 0x00000000000000000000000000000000
00:16 0x00000000000000000000000000000001
```

* 0x2 (16 bytes), usando os 16 bytes mais altos

```shell
// representado em bytecode como 0x200000000000000000000000000000000
16:32 0x00000000000000000000000000000002
00:16 0x00000000000000000000000000000000
```

* `not(sub(exp(0x2, 0x80), 0x1))`

```shell
// máscara de bits para os 16 bytes mais altos
16:32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
00:16 0x00000000000000000000000000000000
```

* `sub(exp(0x2, 0x80), 0x1)`

```shell
// máscara de bits para os 16 bytes mais baixos
16:32 0x000000

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->