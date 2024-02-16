No artigo anterior desta série, nós exploramos o código de montagem de um contrato Solidity simples:

```solidity
contract C {
	uint256 a;

	function C() {
		a = 1;
	}
}
```

Esse contrato se resume a chamar a instrução `sstore`:

```shell
// a = 1
sstore(0x0, 0x1)
```

- A EVM armazena o valor `0x1` na posição de armazenamento `0x0`
- Cada posição de armazenamento pode armazenar 32 bytes (ou 256 bits)

> Se isso parece estranho, recomendo ler: [Diving Into The Ethereum VM Part1 — Assembly and Bytecode](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md).

Neste artigo, começaremos a explorar como o Solidity representa tipos de dados de comprimento fixo em blocos de 32 bytes, como estruturas e arrays. Também entenderemos como otimizar o armazenamento e como a otimização pode falhar.

Em linguagens de programação convencionais, entender como os tipos de dados são representados em um nível tão baixo não é muito útil. No Solidity (ou qualquer linguagem EVM), esse conhecimento é crucial, pois o acesso ao armazenamento é muito caro:

- `sstore` custa 20000 gas, cerca de 5000 vezes mais caro do que uma instrução aritmética básica
- `sload` requer 200 gas, cerca de 100 vezes mais caro do que uma instrução aritmética básica

Quando falamos sobre "custo", estamos falando de dinheiro real, não apenas de desempenho em milissegundos. O custo de executar e usar contratos é provavelmente dominado por `sstore` e `sload`!

## Parsecs Upon Parsecs of Tape

Construir um computador genérico requer dois elementos básicos:

1. Uma maneira de loop, pular (jump) ou recursão
2. Uma quantidade infinita de memória

O código de montagem da EVM tem saltos, e o armazenamento da EVM fornece memória infinita. Isso é suficiente para tudo, incluindo simular um mundo que executa uma versão do Ethereum, que por sua vez está simulando um mundo que executa o Ethereum, ou seja...

O armazenamento de um contrato EVM é como uma fita de teletipo infinita, onde cada slot da fita armazena 32 bytes. É assim que se parece:

```shell
[32 bytes][32 bytes][32 bytes]...
```

Veremos como os dados são armazenados nessa fita infinita.

> O comprimento da fita é $2^{256}$ (32 bytes), ou cerca de $10^{77}$ slots de armazenamento por contrato (e $2^{256}$ é da mesma ordem de grandeza). O número de partículas observáveis no universo é de $10^{80}$. Cerca de 1000 contratos seriam suficientes para armazenar todos esses prótons, nêutrons e elétrons. Não acredite em hype de marketing, pois é muito menor do que o infinito.

## A Fita em Branco

O armazenamento é inicialmente em branco, padrão para 0. Ter uma fita infinita não custa nada.

Vamos ver um contrato simples para ilustrar o comportamento de valor zero:

```solidity
// c-many-variables.sol
pragma solidity ^0.4.11;

contract C {
	uint256 a;
	uint256 b;
	uint256 c;
	uint256 d;
	uint256 e;
	uint256 f;

	function C() {
		f = 0xc0fefe;
	}
}
```

O layout de armazenamento é simples.

- A variável `a` está na posição `0x0`
- A variável `b` está na posição `0x1`
- E assim por diante...

A questão chave é: se usarmos apenas `f`, quanto teremos que pagar por `a`, `b`, `c`, `d`, `e`?

Vamos compilar e ver:

```shell
$ solc --bin --asm --optimize c-many-variables.sol
```

O código de montagem é:

```shell
tag_2:
  0xc0fefe
  0x5
  sstore
```

Portanto, a declaração de variáveis de armazenamento não requer nenhum custo, pois não precisa de inicialização. O Solidity reserva um local para essa variável de armazenamento e você só precisa pagar quando armazenar algo nele.

Neste caso, só precisamos pagar pelo armazenamento em `0x5`.

Se escrevêssemos o código de montagem manualmente, poderíamos escolher qualquer posição de armazenamento sem precisar "expandir" o armazenamento:

```shell
// Escrevendo em uma posição arbitrária
sstore(0xc0fefe, 0x42)
```

## Lendo Zero

Você não só pode escrever em qualquer posição de armazenamento, mas também pode ler imediatamente de qualquer posição. Ler de uma posição não inicializada retornará apenas `0x0`.

Vamos ver um contrato que lê de `a`, uma posição não inicializada:

```solidity
// c-zero-value.sol
pragma solidity ^0.4.11;

contract C {

	uint256 a;

	function C() {
		a = a + 1;
	}
}
```

Compilando:

```shell
$ solc --bin --asm --optimize c-zero-value.sol
```

O código de montagem é:

```shell
tag_2:
  // sload(0x0) retornando 0x0
  0x0
  dup1
  sload

  // a + 1; onde a == 0
  0x1
  add

  // sstore(0x0, a + 1)
  swap1
  sstore
```

Observe que o código gerado para carregar de uma posição não inicializada `sload` é válido.

No entanto, podemos ser mais inteligentes do que o compilador Solidity. Como sabemos que `tag_2` é o construtor e `a` nunca foi escrito, podemos substituir a sequência `sload` por `0x0` para economizar 5000 gas.

## Representando Struct

Vamos ver nosso primeiro tipo de dados complexo, uma struct com 6 campos:

```solidity
// c-struct-fields.sol
pragma solidity ^0.4.11;

contract C {
	struct Tuple {
		uint256 a;
		uint256 b;
		uint256 c;
		uint256 d;
		uint256 e;
		uint256 f;
	}

	Tuple t;

	function C() {
		t.f = 0xC0FEFE;
	}
}
```

O layout de armazenamento é o mesmo que as variáveis de estado:

- O campo `t.a` está na posição `0x0`
- O campo `t.b` está na posição `0x1`
- E assim por diante...

Assim como antes, podemos escrever diretamente em `t.f` sem precisar inicializar.

Compilando:

```shell
$ solc --bin --asm --optimize c-struct-fields.sol
```

Podemos ver o mesmo código de montagem:

```shell
tag_2:
  0xc0fefe
  0x5
  sstore
```

## Array de Comprimento Fixo

Agora vamos declarar um array de comprimento fixo:

```solidity
// c-static-array.sol
pragma solidity ^0.4.11;

contract C {
    uint256[6] numbers;

    function C() {
      numbers[5] = 0xC0FEFE;
    }
}
```

Como o compilador sabe exatamente quantos uint256 (32 bytes) existem, ele pode simplesmente colocar os elementos do array um após o outro no armazenamento, da mesma forma que faz com as variáveis de estado e structs.

Neste contrato, mais uma vez armazenamos na posição `0x5`.

Compilando:

```shell
$ solc --bin --asm --optimize c-static-array.sol
```

O código de montagem é um pouco mais longo, mas se você olhar atentamente, verá que é essencialmente o mesmo. Vamos otimizar manualmente ainda mais:

```shell
tag_2:
  0xc0fefe

  // 0+5. Substituímos por 0x5
  0x0
  0x5
  add

  // Empurrar e depois remover imediatamente. Inútil, apenas remova.
  0x0
  pop

  sstore
```

Removendo rótulos e instruções falsas, obtemos novamente a mesma sequência de bytes:

```shell
tag_2:
  0xc0fefe
  0x5
  sstore
```

## Verificação de Limite de Array

Vimos que arrays de comprimento fixo têm o mesmo layout de armazenamento que variáveis de estado e structs, mas o código de montagem gerado é diferente. Isso ocorre porque o Solidity gera verificações de limite para acessos a arrays.

Vamos compilar novamente o contrato de array, desta vez sem otimização:

```shell
$ solc --bin --asm c-static-array.sol
```

O código de montagem é fornecido com comentários após cada instrução, mostrando o estado da máquina:

```shell
tag_2:
  0xc0fefe
    [0xc0fefe]
  0x5
    [0x5 0xc0fefe]
  dup1

  /* código de verificação de limite de array */
  // 5 < 6
  0x6
    [0x6 0x5 0xc0fefe]
  dup2
    [0x5 0x6 0x5 0xc0fefe]
  lt
    [0x1 0x5 0xc0fefe]
  // bound_check_ok = 1 (TRUE)

  // if(bound_check_ok) { goto tag5 } else { invalid }
  tag_5
    [tag_5 0x1 0x5 0xc0fefe]
  jumpi
    // A condição de teste é verdadeira. Irá para tag_5.
    // E `jumpi` consome dois itens da pilha.
    [0x5 0xc0fefe]
  invalid

// O acesso ao array é válido. Faça isso.
// pilha: [0x5 0xc0fefe]
tag_5:
  sstore
    []
    storage: { 0x5 => 0xc0fefe }
```

Agora vemos o código de verificação de limite. Vimos que o compilador pode otimizar algumas coisas dentro dos rótulos, mas não entre eles.

Chamadas de função podem custar mais, não porque as chamadas de função são caras (elas são apenas instruções de salto), mas porque a otimização de `sstore` pode falhar.

Para resolver esse problema, o compilador Solidity precisa aprender a inlining de funções, essencialmente obtendo o mesmo código que se não chamasse a função:

```shell
a = 0xaaaa;
b = 0xbbbb;
c = 0xcccc;
d = 0xdddd;
```

> Se lermos o código de montagem completo com atenção, veremos que o código de montagem das funções `setAB()` e `setCD()` é incluído duas vezes, o que aumenta o tamanho do código e faz com que você gaste mais gas ao implantar o contrato. Discutiremos esse problema ao entender o ciclo de vida do contrato.

## Por que o Otimizador Falha

O otimizador não otimiza entre rótulos. Considere "1+1", se estiver no mesmo rótulo, pode ser otimizado para `0x2`:

```shell
// Otimização OK!
tag_0:
  0x1
  0x1
  add
  ...
```

Mas se as instruções são separadas por rótulos, não funciona assim:

```shell
// Otimização Falha!
tag_0:
  0x1
  0x1
tag_1:
  add
  ...
```

A partir da versão 0.4.13, esse comportamento está correto. Pode mudar no futuro.

## Quebrando o Otimizador, Novamente

Vamos ver outra maneira de fazer o otimizador falhar. O empacotamento se aplica a arrays de comprimento fixo? Considere:

```solidity
// c-static-array--packing.sol
pragma solidity ^0.4.11;

contract C {
	uint64[4] numbers;

	function C() {
		numbers[0] = 0x0;
		numbers[1] = 0x1111;
		numbers[2] = 0x2222;
		numbers[3] = 0x3333;
	}
}
```

Novamente, queremos empacotar os quatro números de 64 bits em um slot de armazenamento de 32 bytes usando apenas uma instrução `sstore`.

Compilando e contando as instruções `sstore` e `sload`:

```shell
$ solc --bin --asm --optimize c-static-array--packing.sol | grep -E '(sstore|sload)'
  sload
  sstore
  sload
  sstore
  sload
  sstore
  sload
  sstore
```

Mesmo que esse array de comprimento fixo tenha o mesmo layout de armazenamento que uma struct ou variáveis de estado equivalentes, a otimização falha. Agora precisamos de quatro pares de `sload` e `sstore`.

Uma rápida olhada no código de montagem revela que cada acesso ao array tem código de verificação de limite e está organizado em rótulos diferentes. Mas as fronteiras dos rótulos quebram a otimização.

No entanto, há um pequeno consolo. 3 `sstore` extras são mais baratos do que o primeiro:

- A primeira gravação em uma nova posição requer 20000 gas
- Gravações subsequentes na mesma posição requerem 5000 gas

Portanto, essa falha de otimização específica nos custa 35k em vez de 20k, um aumento de 75%.

## Conclusão

Se o compilador Solidity puder calcular o tamanho das variáveis de armazenamento, ele simplesmente as colocará uma após a outra no armazenamento. Se possível, o compilador compactará os dados em blocos de 32 bytes o máximo possível.

Resumindo o comportamento de empacotamento que vimos até agora:

- Variáveis de armazenamento: sim;
- Campos de struct: sim;
- Arrays de comprimento fixo: não; teoricamente, sim.

Como o custo de acesso ao armazenamento é alto, você deve considerar suas variáveis de armazenamento como o esquema do seu banco de dados. Fazer pequenos experimentos ao escrever contratos e verificar o assembly para ver se o compilador otimizou corretamente pode ser útil.

Podemos ter certeza de que o compilador Solidity melhorará no futuro. Mas por enquanto, não podemos confiar cegamente em seu otimizador.

Literalmente, conhecer suas variáveis de armazenamento vale a pena.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->