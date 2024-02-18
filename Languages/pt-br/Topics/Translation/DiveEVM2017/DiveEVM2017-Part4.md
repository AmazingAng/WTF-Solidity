# Aprofundando na Máquina Virtual Ethereum Parte 4 — Chamadas de Métodos Externos de Contratos Inteligentes

> Artigo original: [How To Decipher A Smart Contract Method Call | por Howard | 18 de Setembro, 2017](https://medium.com/@hayeah/how-to-decipher-a-smart-contract-method-call-8ee980311603)

Nos artigos anteriores desta série, já exploramos como a Solidity representa estruturas de dados complexas no armazenamento da EVM. No entanto, os dados seriam inúteis se não pudéssemos interagir com eles. Os contratos inteligentes são o intermediário entre os dados e o mundo exterior.

Neste artigo, vamos entender como a Solidity e a EVM permitem que programas externos chamem métodos do contrato e causem mudanças em seu estado.

"Programas externos" não se limitam a DApp/JavaScript. Qualquer programa que possa se comunicar com um nó Ethereum via HTTP RPC pode interagir com qualquer contrato implantado na blockchain criando uma transação.

Criar uma transação é como fazer uma solicitação HTTP. O servidor web aceita sua solicitação HTTP e faz alterações no banco de dados. A transação é aceita pela rede, e a blockchain subjacente é expandida para incluir a mudança de estado.

Uma transação para um contrato inteligente é como uma solicitação HTTP para um serviço web.

Se você não está familiarizado com a montagem EVM e a representação de dados da Solidity, consulte os artigos anteriores desta série para mais informações:

* [Aprofundando na Máquina Virtual Ethereum Parte 1 — Montagem e Bytecode](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)
* [Aprofundando na Máquina Virtual Ethereum Parte 2 — Representação de Tipos de Dados de Comprimento Fixo](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)
* [Aprofundando na Máquina Virtual Ethereum Parte 3 — Representação de Tipos de Dados Dinâmicos](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)

## Transação de Contrato

Vamos olhar para uma transação que define a variável de estado para `0x1`. O contrato com o qual estamos interagindo tem um setter e um getter para a variável `a`:

```solidity
pragma solidity ^0.4.11;

contract C {
	uint256 a;

	function setA(uint256 _a) {
		a = _a;
	}

	function getA() returns(uint256) {
		return a;
	}
}
```

Este contrato está implantado na rede de teste Rinkeby. Sinta-se à vontade para usar o Etherscan no endereço [0x62650ae5...](https://rinkeby.etherscan.io/address/0x62650ae5c5777d1660cc17fcd4f48f6a66b9a4c2) para verificar isso.

Criei uma transação que chama `setA(1)`. Verifique esta transação no endereço [0x7db471e5...](https://rinkeby.etherscan.io/tx/0x7db471e5792bbf38dc784a5b983ee6a7bbe3f1db85dd4daede9ee88ed88057a5).

Os dados de entrada da transação são:

```shell
0xee919d500000000000000000000000000000000000000000000000000000000000000001
```

Para a EVM, isso é apenas 36 bytes de dados brutos. É passado como `calldata` para o contrato inteligente sem processamento. Se o contrato inteligente for um programa Solidity, ele interpretará esses bytes de entrada como uma chamada de método e executará o código de montagem apropriado para `setA(1)`.

Os dados de entrada podem ser divididos em duas subseções:

```shell
# O seletor de método (4 bytes)
0xee919d50
# O 1º argumento (32 bytes)
0000000000000000000000000000000000000000000000000000000000000001
```

Os primeiros quatro bytes são o seletor de método. O restante dos dados de entrada são blocos de 32 bytes dos argumentos do método. Neste caso, há apenas 1 argumento, que é o valor `0x1`.

O seletor de método é o hash kecccak256 da assinatura do método. Neste caso, a assinatura do método é `setA(uint256)`, que é o nome do método e o tipo de seus argumentos.

Vamos calcular o seletor de método usando Python. Primeiro, fazemos o hash da assinatura do método:

```shell
# Instale pyethereum https://github.com/ethereum/pyethereum/#installation
> from ethereum.utils import sha3
> sha3("setA(uint256)").hex()
'ee919d50445cd9f463621849366a537968fe1ce096894b0d0c001528383d4769'
```

Em seguida, pegamos os primeiros 4 bytes do hash:

```shell
> sha3("setA(uint256)")[0:8].hex()
'ee919d50'
```

> Nota: Cada byte é representado por 2 caracteres em uma string hexadecimal do Python

## A Interface Binária de Aplicação (ABI)

Para a EVM, os dados de entrada da transação (`calldata`) são apenas uma sequência de bytes. A EVM não tem suporte embutido para chamar métodos.

Contratos inteligentes podem optar por processar os dados de entrada de maneira estruturada para simular chamadas de método, como mostrado na seção anterior.

Se os idiomas na EVM concordarem em como interpretar os dados de entrada, eles podem operar facilmente entre si. A [Interface Binária de Aplicação de Contrato](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI#formal-specification-of-the-encoding) (ABI) especifica um esquema de codificação universal.

Já vimos como a ABI codifica chamadas de método simples como `setA(1)`. Nas seções seguintes, veremos como codificar chamadas de método com argumentos mais complexos.

## Chamando um Getter

Se o método que você está chamando muda o estado, então toda a rede deve concordar. Isso exigirá uma transação e custará gas.

Métodos getter como `getA()` não mudam nada. Podemos enviar a chamada de método para o nó Ethereum local, em vez de exigir que toda a rede faça o cálculo. A solicitação RPC `eth_call` permite simular transações localmente. Isso é útil para métodos somente leitura ou estimativas de custo de gas.

`eth_call` é semelhante a uma solicitação HTTP GET em cache.

* Não muda o estado de consenso global.
* A blockchain local ("cache") pode estar ligeiramente desatualizada.

Vamos usar `eth_call` para chamar o método `getA` e obter o estado `a` como retorno. Primeiro, calculamos o seletor de método:

```shell
>>> sha3("getA()")[0:8].hex()
'd46300fd'
```

Como não há argumentos, os dados de entrada são o próprio seletor de método. Podemos enviar uma solicitação `eth_call` para qualquer nó Ethereum. Neste caso, enviaremos a solicitação para um nó Ethereum público hospedado no infura.io:

```shell
$ curl -X POST \
-H "Content-Type: application/json" \
"https://rinkeby.infura.io/YOUR_INFURA_TOKEN" \
--data '
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_call",
  "params": [
    {
      "to": "0x62650ae5c5777d1660cc17fcd4f48f6a66b9a4c2",
      "data": "0xd46300fd"
    },
    "latest"
  ]
}
'
```

A EVM executa o cálculo e retorna bytes brutos como resultado:

```shell
{
"jsonrpc":"2.0",
"id":1,
        "result":"0x0000000000000000000000000000000000000000000000000000000000000001"
}
```

De acordo com a ABI, os bytes devem ser interpretados como o valor `0x1`.

## Montagem para Chamadas de Métodos Externos

Agora, vamos ver como um contrato compilado lida com dados de entrada brutos para fazer chamadas de método. Considere um contrato que definiu `setA(uint256)`:

```solidity
// call.sol
pragma solidity ^0.4.11;

contract C {
	uint256 a;

	// Nota: `payable` torna a montagem um pouco mais simples
	function setA(uint256 _a) payable {
		a = _a;
	}
}
```

Compilação:

```shell
solc --bin --asm --optimize call.sol
```

O código de montagem do método chamado está no corpo do contrato, organizado sob `sub_0`:

```shell
sub_0: assembly {
    mstore(0x40, 0x60)
    and(div(calldataload(0x0), 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)
    0xee919d50
    dup2
    eq
    tag_2
    jumpi
  tag_1:
    0x0
    dup1
    revert
  tag_2:
    tag_3
    calldataload(0x4)
    jump(tag_4)
  tag_3:
    stop
  tag_4:
      /* "call.sol":95:96  a */
    0x0
      /* "call.sol":95:101  a = _a */
    dup2
    swap1
    sstore
  tag_5:
    pop
    jump // out

auxdata: 0xa165627a7a7230582016353b5ec133c89560dea787de20e25e96284d67a632e9df74dd981cc4db7a0a0029
}
```

Há dois pedaços de código de modelo que não são relevantes para nossa discussão, mas apenas para sua informação (FYI):

* O `mstore(0x40, 0x60)` no topo reserva os primeiros 64 bytes na memória para o hash sha3. Isso está sempre presente, independentemente de o contrato precisar ou não.
* O `auxdata` no fundo é usado para verificar se o código-fonte publicado corresponde ao bytecode implantado. Isso é opcional, mas incluído pelo compilador.

Vamos dividir o restante do código de montagem em duas partes para análise:

1. Correspondência do seletor e salto para o método.
2. Carregamento de argumentos, execução do método e retorno do método.

Primeiro, a montagem anotada para correspondência do seletor:

```shell
// Carrega os primeiros 4 bytes como seletor de método
and(div(calldataload(0x0), 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)

// se o seletor corresponder a `0xee919d50`, vá para setA
0xee919d50
dup2
eq
tag_2
jumpi

// Nenhum método correspondente. Falha e reverte.
tag_1:
  0x0
  dup1
  revert

// Corpo de setA
tag_2:
  ...
```

Além de carregar 4 bytes do início dos dados de chamada para bit-shuffling, tudo é bastante simples. Para clareza, aqui está a lógica de montagem em pseudocódigo de baixo nível:

```shell
methodSelector = calldata[0:4]

if methodSelector == "0xee919d50":
  goto tag_2 // vá para setA
else:
  // Nenhum método correspondente. Falha e reverte.
  revert
```

A montagem anotada para a chamada de método real:

```shell
// setA
tag_2:
  // Onde ir após a chamada do método
  tag_3

  // Carrega o primeiro argumento (o valor 0x1).
  calldataload(0x4)

  // Executa o método.
  jump(tag_4)
tag_4:
  // sstore(0x0, 0x1)
  0x0
  dup2
  swap1
  sstore
tag_5:
  pop
  // fim do programa, irá para tag_3 e parar
  jump
tag_3:
  // fim do programa
  stop
```

Antes de entrar na parte do método, a montagem faz duas coisas:

1. Salva a posição para retornar após a chamada do método.
2. Carrega os argumentos dos dados de chamada para a pilha.

Em pseudocódigo de baixo nível:

```shell
// Salva a posição para retornar após a chamada do método.
@returnTo = tag_3

tag_2: // setA
  // Carrega os argumentos dos dados de chamada para a pilha.
  @arg1 = calldata[4:4+32]
tag_4: // a = _a
  sstore(0x0, @arg1)
tag_5 // retornar
  jump(@returnTo)
tag_3:
  stop
```

Combinando as duas partes:

```shell
methodSelector = calldata[0:4]

if methodSelector == "0xee919d50":
  goto tag_2 // vá para setA
else:
  // Nenhum método correspondente. Falha.
  revert

@returnTo = tag_3
tag_2: // setA(uint256 _a)
  @arg1 = calldata[4:36]
tag_4: // a = _a
  sstore(0x0, @arg1)
tag_5 // retornar
  jump(@returnTo)
tag_3:
  stop
```

> Curiosidade: O opcode de revert é `fd`. Mas você não encontrará sua especificação no livro amarelo, nem encontrará sua implementação no código. Na verdade, `fd` não existe de verdade! É uma operação inválida. Quando a EVM encontra uma operação inválida, ela falha e reverte o estado como um efeito colateral (revert state as a side-effect).

## Lidando com Múltiplos Métodos

Como o compilador Solidity gera código de montagem para um contrato com vários métodos?

```solidity
pragma solidity ^0.4.11;

contract C {
	uint256 a;
	uint256 b;

	function setA(uint256 _a) {
		a = _a;
	}

	function setB(uint256 _b) {
		b = _b;
	}
}
```

Simples. Apenas mais ramificações `if-else` uma após a outra:

```shell
// methodSelector = calldata[0:4]
and(div(calldataload(0x0), 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)

// se methodSelector == 0x9cdcf9b
0x9cdcf9b
dup2
eq
tag_2 // SetB
jumpi

// elsif methodSelector == 0xee919d50
dup1
0xee919d50
eq
tag_3 // SetA
jumpi
```

Em pseudocódigo:

```shell
methodSelector = calldata[0:4]

if methodSelector == "0x9cdcf9b":
  goto tag_2
elsif methodSelector == "0xee919d50":
  goto tag_3
else:
  // Não é possível encontrar um método correspondente. Falha.
  revert
```

## Codificação ABI para Chamadas de Método Complexas

Para chamadas de método, os primeiros quatro bytes dos dados de entrada da transação são sempre o seletor de método. Em seguida, os argumentos do método seguem em blocos de 32 bytes. A [especificação de codificação ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) detalha como codificar argumentos de tipos mais complexos, mas pode ser bastante doloroso de ler.

Outra estratégia para aprender a codificação ABI é usar as [funções de codificação ABI do pyethereum](https://github.com/ethereum/pyethereum/blob/4e945e2a24554ec04eccb160cff689a82eed7e0d/ethereum/abi.py) para estudar como diferentes tipos de dados são codificados. Vamos começar com casos simples e depois construir tipos mais complexos.

Primeiro, importe a função `encode_abi`:

```python
from ethereum.abi import encode_abi
```

Para um método com três argumentos uint256 (por exemplo, `foo(uint256 a, uint256 b, uint256 c)`), a codificação dos argumentos é apenas uma sequência de números uint256 um após o outro:

```shell
# O primeiro array lista os tipos dos argumentos.
# O segundo array lista os valores dos argumentos.
> encode_abi(["uint256", "uint256", "uint256"],[1, 2, 3]).hex()
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000003
```

Tipos menores que 32 bytes são preenchidos até 32 bytes:

```shell
> encode_abi(["int8", "uint32", "uint64"],[1, 2, 3]).hex()
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003
```

Para arrays de tamanho fixo, os elementos também são blocos de 32 bytes (preenchidos com zero quando necessário), colocados um após o outro:

```shell
> encode_abi(
   ["int8[3]", "int256[3]"],
   [[1, 2, 3], [4, 5, 6]]
).hex()

// int8[3]. Preenchido com zero até 32 bytes.
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003

// int256[3].
0000000000000000000000000000000000000000000000000000000000000004
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000000006
```

## Codificação ABI para Arrays Dinâmicos

A ABI introduz uma camada de indireção para codificar arrays dinâmicos, seguindo um esquema conhecido como [codificação cabeça-cauda (head-tail encoding)](https://github.com/ethereum/pyethereum/blob/4e945e2a24554ec04eccb160cff689a82eed7e0d/ethereum/abi.py#L735-L741).

A ideia é que os elementos do array dinâmico sejam empacotados no final dos dados de chamada da transação. O argumento ("cabeça") é uma referência para onde os elementos do array estão nos dados de chamada.

Se chamarmos um método com 3 arrays dinâmicos, a codificação dos argumentos será a seguinte (comentários e quebras de linha adicionados para clareza):

```shell
> encode_abi(
  ["uint256[]", "uint256[]", "uint256[]"],
  [[0xa1, 0xa2, 0xa3], [0xb1, 0xb2, 0xb3], [0xc1, 0xc2, 0xc3]]
).hex()

/************* CABEÇA (32*3 bytes) *************/
// arg1: olhe na posição 0x60 para os dados do array
0000000000000000000000000000000000000000000000000000000000000060
// arg2: olhe na posição 0xe0 para os dados do array
00000000000000000000000000000000000000000000000000000000000000e0
// arg3: olhe na posição 0x160 para os dados do array
0000000000000000000000000000000000000000000000000000000000000160

/************* CAUDA (128**3 bytes) *************/
// posição 0x60. Dados para arg1.
// Comprimento seguido pelos elementos.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000a1
00000000000000000000000000000000000000000000000000000000000000a2
00000000000000000000000000000000000000000000000000000000000000a3

// posição 0xe0. Dados para arg2.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000b1
00000000000000000000000000000000000000000000000000000000000000b2
00000000000000000000000000000000000000000000000000000000000000b3

// posição 0x160. Dados para arg3.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000c1
00000000000000000000000000000000000000000000000000000000000000c2
00000000000000000000000000000000000000000000000000000000000000c3
```

Então, a "cabeça" tem três argumentos de 32 bytes, apontando para as posições da "cauda", que contém os dados reais dos três arrays dinâmicos.

Por exemplo, o primeiro argumento é `0x60`, apontando para o 96º (`0x60`) byte dos dados de chamada. Se olharmos para o 96º byte, ele é o início do array. Os primeiros 32 bytes são o comprimento, seguidos por três elementos.

Podemos misturar argumentos dinâmicos e estáticos. Aqui está um exemplo com argumentos (`estático`, `dinâmico`, `estático`). Os argumentos estáticos são codificados como estão, enquanto os dados do segundo array dinâmico são colocados na "cauda":

```shell
> encode_abi(
  ["uint256", "uint256[]", "uint256"],
  [0xaaaa, [0xb1, 0xb2, 0xb3], 0xbbbb]
).hex()

/************* CABEÇA (32*3 bytes) *************/
// arg1: 0xaaaa
000000000000000000000000000000000000000000000000000000000000aaaa
// arg2: olhe na posição 0x60 para os dados do array
0000000000000000000000000000000000000000000000000000000000000060
// arg3: 0xbbbb
000000000000000000000000000000000000000000000000000000000000bbbb

/************* CAUDA (128 bytes) *************/
// posição 0x60. Dados para arg2.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000b1
00000000000000000000000000000000000000000000000000000000000000000000000000000000b2
00000000000000000000000000000000000000000000000000000000000000b3
```

Há muitos zeros, mas isso não é um problema.

## Codificação de Bytes

Strings e arrays de bytes também são codificados com a codificação cabeça-cauda. A única diferença é que os bytes são empacotados de forma compacta em blocos de 32 bytes, como mostrado abaixo:

```shell
> encode_abi(
  ["string", "string", "string"],
  ["aaaa", "bbbb", "cccc"]
).hex()

// arg1: olhe na posição 0x60 para os dados da string
0000000000000000000000000000000000000000000000000000000000000060
// arg2: olhe na posição 0xa0 para os dados da string
00000000000000000000000000000000000000000000000000000000000000a0
// arg3: olhe na posição 0xe0 para os dados da string
00000000000000000000000000000000000000000000000000000000000000e0

// 0x60 (96). Dados para arg1
0000000000000000000000000000000000000000000000000000000000000004
6161616100000000000000000000000000000000000000000000000000000000

// 0xa0 (160). Dados para arg2
0000000000000000000000000000000000000000000000000000000000000004
6262626200000000000000000000000000000000000000000000000000000000

// 0xe0 (224). Dados para arg3
0000000000000000000000000000000000000000000000000000000000000004
6363636300000000000000000000000000000000000000000000000000000000
```

Para cada string/array de bytes, os primeiros 32 bytes codificam o comprimento, seguidos pelos bytes.

Se a string for maior que 32 bytes, serão usados múltiplos blocos de 32 bytes:

```shell
// codifica 48 bytes de dados de string
ethereum.abi.encode_abi(
  ["string"],
  ["a" * (32+16)]
).hex()

0000000000000000000000000000000000000000000000000000000000000020

// o comprimento da string é 0x30 (48)
0000000000000000000000000000000000000000000000000000000000000030
6161616161616161616161616161616161616161616161616161616161616161
6161616161616161616161616161616100000000000000000000000000000000
```

## Arrays Aninhados

Cada nível de aninhamento em arrays tem sua própria camada de indireção.

```shell
> encode_abi(
  ["uint256[][]"],
  [[[0xa1, 0xa2, 0xa3], [0xb1, 0xb2, 0xb3], [0xc1, 0xc2, 0xc3]]]
).hex()

// arg1: O array externo está na posição 0x20.
0000000000000000000000000000000000000000000000000000000000000020

// 0x20. Cada elemento é a posição de um array interno.
0000000000000000000000000000000000000000000000000000000000000003
0000000000000000000000000000000000000000000000000000000000000060
00000000000000000000000000000000000000000000000000000000000000e0
0000000000000000000000000000000000000000000000000000000000000160

// array[0] na posição 0x60
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000a1
00000000000000000000000000000000000000000000000000000000000000a2
00000000000000000000000000000000000000000000000000000000000000a3

// array[1] na posição 0xe0
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000b1
00000000000000000000000000000000000000000000000000000000000000b2
00000000000000000000000000000000000000000000000000000000000000b3

// array[2] na posição 0x160
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000c1
00000000000000000000000000000000000000000000000000000000000000c2
00000000000000000000000000000000000000000000000000000000000000c3
```

Sim, há muitos zeros.

## Custo de Gas e Design de Codificação ABI

Por que a ABI trunca o seletor de método para apenas 4 bytes? Se não usarmos todos os 32 bytes do sha256, métodos diferentes poderiam ter colisões infelizes? Se o truncamento é para economizar custos, por que então economizar 28 bytes no seletor de método se estamos desperdiçando mais bytes com preenchimento de zeros?

Essas duas escolhas de design parecem contraditórias... até considerarmos o custo do gas das transações.

* Cada transação paga 21000.
* Cada byte de dados ou código de transação zero custa 4.
* Cada byte de dados ou código de transação não zero custa 68.

Os valores zero são 17 vezes mais baratos, então o preenchimento com zeros não é tão ruim quanto parece.

O seletor de método é um hash criptográfico, que é pseudoaleatório. Strings aleatórias tendem a ter a maioria dos bytes não zero, pois cada byte tem apenas 0,3% (1/255) de chance de ser zero.

* `0x1` preenchido até 32 bytes custaria 192 de gas. (4 * 31 + 68)
* sha256 poderia ter 32 bytes não zero, custando cerca de 2176 de gas. (32 * 68)
* sha256 truncado para 4 bytes custaria cerca de 272 de gas. (32 * 4)

A ABI mostra outro exemplo peculiar de design de baixo nível incentivado pela estrutura de custos do gas.

## Inteiros Negativos...

Inteiros negativos são comumente representados usando um esquema chamado [complemento de dois](https://en.wikipedia.org/wiki/Two%27s_complement). O valor `-1` do tipo int8 seria todo 1s `1111 1111`.

A ABI preenche inteiros negativos com 1s, então `-1` seria preenchido como:

```shell
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
```

Números negativos pequenos são majoritariamente 1s, o que custaria muito gas.

¯\_(ツ)_/¯

## Conclusão

Para interagir com contratos inteligentes, você precisa enviar bytes brutos para eles. Eles farão alguns cálculos, possivelmente mudarão seu próprio estado e então enviarão bytes brutos de volta para você. Chamadas de método, na verdade, não existem. É uma ilusão coletiva criada pela ABI.

A ABI é especificada como um formato de baixo nível, mas funcionalmente, é mais como um formato de serialização para um framework de RPC entre linguagens.

Podemos fazer uma analogia entre a arquitetura de DApps e Web Apps:

* A blockchain é como o banco de dados por trás.
* Contratos são como um serviço de rede.
* Transações são como uma solicitação.
* A ABI é o formato de troca de dados, semelhante a [Protocol Buffers](https://en.wikipedia.org/wiki/Protocol_Buffers).

