# Aprofundando na Máquina Virtual Ethereum Parte 3 — A Representação de Tipos de Dados Dinâmicos

> Artigo original: [Diving Into The Ethereum VM Part 3 — The Hidden Costs of Arrays | by Howard | Aug 24, 2017](https://medium.com/@hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b)

Solidity oferece estruturas de dados comuns encontradas em outras linguagens de programação. Além de valores simples como números e estruturas, existem alguns tipos de dados que podem se expandir dinamicamente à medida que mais dados são adicionados. Esses tipos dinâmicos se enquadram em três categorias principais:

* Mapeamentos: `mapping(bytes32 => uint256)`, `mapping(address => string)`, etc.
* Arrays: `[]uint256`, `[]byte`, etc.
* Arrays de bytes, apenas dois tipos: `string`, `bytes`.

Na parte anterior desta série, vimos como tipos simples de tamanho fixo são representados no armazenamento.

* Valores básicos: `uint256`, `byte`, etc.
* Arrays de tamanho fixo: `[10]uint8`, `[32]byte`, `bytes32`
* Estruturas combinando os tipos acima

Variáveis de armazenamento de tamanho fixo são colocadas uma após a outra no armazenamento, empacotadas o mais próximo possível em blocos de 32 bytes.

(Se esta parte parece não familiar, por favor, leia [Aprofundando na Máquina Virtual Ethereum Parte 2 — A Representação de Tipos de Dados de Comprimento Fixo](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md))

Neste artigo, vamos explorar como o Solidity suporta estruturas de dados mais complexas. Arrays e mapeamentos no Solidity podem parecer familiares na superfície, mas a maneira como são implementados lhes confere características de desempenho completamente diferentes.

Vamos começar com mapeamentos, que são os mais simples dos três. Acontece que arrays e arrays de bytes são apenas mapeamentos com características mais avançadas.<br />

## Mapeamento

Vamos armazenar um valor em um mapeamento `uint256 => uint256`:

```solidity
// c-mapping.sol
pragma solidity ^0.4.11;

contract C {
	mapping(uint256 => uint256) items;

	function C() {
		items[0xC0FEFE] = 0x42;
	}
}
```

Compilação:

```shell
solc --bin --asm --optimize c-mapping.sol
```

Assembly:

```shell
tag_2:
  // Não faz nada. Deveria ser otimizado para remoção.
  0xc0fefe
  0x0
  swap1
  dup2
  mstore
  0x20
  mstore
  // Armazenando 0x42 no endereço 0x798...187c
  0x42
  0x79826054ee948a209ff4a6c9064d7398508d2c1909a392f899d301c6d232187c
  sstore
```

Podemos considerar o armazenamento EVM como um banco de dados chave-valor, onde cada chave é limitada a armazenar 32 bytes. Aqui, a chave `0xC0FEFE` não é usada diretamente, mas sim hashada para `0x798...187c`, e o valor `0x42` é armazenado lá. A função de hash usada é a `keccak256` (SHA256).

Neste exemplo, não vemos a instrução `keccak256` em si, porque o otimizador decidiu pré-calcular o resultado e incluí-lo inline no bytecode. Ainda podemos ver vestígios desse cálculo na forma de instruções `mstore` desnecessárias.

## Calcular o Endereço

Vamos usar algum código Python para hashar `0xC0FEFE` para `0x798...187c`. Se você deseja seguir adiante, precisará do Python 3.6, ou instalar [pysha3](https://pypi.python.org/pypi/pysha3) para obter a função de hash `keccak_256`.

Definindo duas funções auxiliares:

```python
import binascii
import sha3

# Converte um número para um array de 32 bytes.
def bytes32(i):
    return binascii.unhexlify('%064x' % i)

# Calcula o hash keccak256 de um array de 32 bytes.
def keccak256(x):
    return sha3.keccak_256(x).hexdigest()
```

Convertendo números para 32 bytes:

```shell
>>> bytes32(1)
b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
>>> bytes32(0xC0FEFE)
b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\xfe\xfe'
```

Para concatenar dois arrays de bytes, use o operador `+`:

```shell
>>> bytes32(1) + bytes32(2)
b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03'
```

Calculando o hash keccak256 de bytes:

```shell
>>> keccak256(bytes(1))
'bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a'
```

Agora podemos calcular `0x798...187c`.

A posição da variável de armazenamento `items` é `0x0` (porque é a primeira variável de armazenamento). Para obter o endereço, concatenamos a chave `0xc0fefe` com a posição de `items`:

```shell
# chave = 0xC0FEFE, posição = 0
>>> keccak256(bytes32(0xC0FEFE) + bytes32(0))
'79826054ee948a209ff4a6c9064d7398508d2c1909a392f899d301c6d232187c'
```

A fórmula para calcular o endereço de armazenamento da chave é:

```shell
keccak256(bytes32(chave) + bytes32(posição))
```

## Dois Mapeamentos

Vamos aplicar nossa fórmula para calcular a posição de armazenamento de valores! Suponha que temos um contrato com dois mapeamentos:

```solidity
// c-mapping-2.sol
pragma solidity ^0.4.11;

contract C {
	mapping(uint256 => uint256) itemsA;
	mapping(uint256 => uint256) itemsB;

	function C() {
		itemsA[0xAAAA] = 0xAAAA;
		itemsB[0xBBBB] = 0xBBBB;
	}
}
```

* A posição de `itemsA` é `0`, para a chave `0xAAAA`:

```shell
# chave = 0xAAAA, posição = 0
>>> keccak256(bytes32(0xAAAA) + bytes32(0))
'839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3'
```

* A posição de `itemsB` é `1`, para a chave `0xBBBB`:

```shell
# chave = 0xBBBB, posição = 1
>>> keccak256(bytes32(0xBBBB) + bytes32(1))
'34cb23340a4263c995af18b23d9f53b67ff379ccaa3a91b75007b010c489d395'
```

Vamos verificar esses cálculos com o compilador:

```shell
$ solc --bin --asm --optimize  c-mapping-2.sol
```

Assembly:

```shell
tag_2:
  // ... Omitindo operações de memória que poderiam ser otimizadas

  0xaaaa
  0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
  sstore

  0xbbbb
  0x34cb23340a4263c995af18b23d9f53b67ff379ccaa3a91b75007b010c489d395
  sstore
```

Como esperado.

## KECCAK256 em Assembly

O compilador foi capaz de pré-calcular o endereço da chave porque os valores envolvidos eram constantes. Se a chave usada for uma variável, precisaremos usar código assembly para fazer o hash. Agora vamos desabilitar essa otimização para que possamos ver como o hash é feito em assembly.

Isso pode ser facilmente feito introduzindo um acesso indireto adicional com uma variável fictícia `i`:

```solidity
// c-mapping--no-constant-folding.sol
pragma solidity ^0.4.11;

contract C {
	mapping(uint256 => uint256) items;

	// Esta variável faz com que a dobragem de constantes falhe.
	uint256 i = 0xC0FEFE;

	function C() {
		items[i] = 0x42;
	}
}
```

A posição da variável `items` ainda é `0x0`, então deveríamos esperar o mesmo endereço que antes.

Compilando com otimização, mas desta vez sem pré-cálculo do hash:

```shell
$ solc --bin --asm --optimize  c-mapping--no-constant-folding.sol
```

Assembly comentado:

```shell
tag_2:
  // Carrega `i` na pilha
  sload(0x1)
    [0xC0FEFE]

  // Armazena a chave `0xC0FEFE` na memória em 0x0, para hashing.
  0x0
    [0x0 0xC0FEFE]
  swap1
    [0xC0FEFE 0x0]
  dup2
    [0x0 0xC0FEFE 0x0]
  mstore
    [0x0]
    memória: {
      0x00 => 0xC0FEFE
    }

  // Armazena a posição `0x0` na memória em 0x20 (32), para hashing.
  0x20 // 32
    [0x20 0x0]
  dup2
    [0x0 0x20 0x0]
  swap1
    [0x20 0x0 0x0]
  mstore
    [0x0]
    memória: {
      0x00 => 0xC0FEFE
      0x20 => 0x0
    }

  // A partir do byte 0, faz o hash dos próximos 0x40 (64) bytes na memória
  0x40 // 64
    [0x40 0x0]
  swap1
    [0x0 0x40]
  keccak256
    [0x798...187c]

  // Armazena 0x42 no endereço calculado
  0x42
    [0x42 0x798...187c]
  swap1
    [0x798...187c 0x42]
  sstore
    armazenamento: {
      0x798...187c => 0x42
    }
```

A instrução `mstore` escreve 32 bytes na memória. A memória é muito mais barata, com leitura e escrita custando apenas 3 gas. A primeira metade do assembly "concatena" a chave e a posição carregando-as em blocos de memória adjacentes:

```shell
 0                   31  32                 63
[    chave (32 bytes)    ][ posição (32 bytes) ]
```

Então, a instrução `keccak256` faz o hash dos dados nessa área de memória. O custo depende da quantidade de dados hashados:

* Cada operação SHA3 custa 30
* Cada palavra (word) de 32 bytes custa 6

Para uma chave `uint256`, o custo em gas é 42 (`30 + 6 * 2`).

## Mapeando Valores Grandes

Cada slot de armazenamento só pode armazenar 32 bytes. O que acontece se tentarmos armazenar uma estrutura maior?

```solidity
pragma solidity ^0.4.11;

contract C {
	mapping(uint256 => Tuple) tuples;

	struct Tuple {
		uint256 a;
		uint256 b;
		uint256 c;
	}

	function C() {
		tuples[0x1].a = 0x1A;
		tuples[0x1].b = 0x1B;
		tuples[0x1].c = 0x1C;
	}
}
```

Compilando, você deve ver 3 instruções `sstore`:

```shell
tag_2:
  // ...omitindo código não otimizado
  0x1a
  0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7d
  sstore

  0x1b
  0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7e
  sstore

  0x1c
  0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7f
  sstore
```

Note que, exceto pelo último dígito, os endereços calculados são os mesmos. Os campos de membro da estrutura `Tuple` são alinhados em sequência (..7d, ..7e, ..7f).

## Mapeamentos Não Empacotam

Dada a maneira como os mapeamentos são projetados, você paga pelo menos 32 bytes de armazenamento por item, mesmo que esteja armazenando apenas 1 byte:

```solidity
pragma solidity ^0.4.11;

contract C {
	mapping(uint256 => uint8) items;

	function C() {
		items[0xA] = 0xAA;
		items[0xB] = 0xBB;
	}
}
```

Se um valor for maior que 32 bytes, você paga o armazenamento em incrementos de 32 bytes.

## Arrays Dinâmicos São Mapeamentos++

Em linguagens típicas, um array é apenas uma lista de itens armazenados juntos na memória. Suponha que você tenha um array com 100 elementos `uint8`, ele ocuparia 100 bytes de memória. Nesse mecanismo, é barato carregar todo o array no cache da CPU e iterar sobre esses itens.

Para a maioria das linguagens, arrays são mais baratos que mapeamentos. No entanto, para Solidity, arrays são versões mais caras de mapeamentos. Os itens de um array são armazenados sequencialmente no armazenamento, por exemplo:

```shell
0x290d...e563
0x290d...e564
0x290d...e565
0x290d...e566
```

Mas lembre-se, cada acesso a esses slots de armazenamento é na verdade uma busca chave-valor no banco de dados. Acessar um elemento de array não é diferente de acessar um elemento de mapeamento.

Considere o tipo `[]uint256`, que é essencialmente o mesmo que `mapping(uint256 => uint256)`, mas com características adicionadas que o tornam "semelhante a um array":

* `length` indica quantos itens existem;
* Verificação de limites. Lança um erro ao ler ou escrever um índice maior que o comprimento;
* Comportamento de empacotamento de armazenamento mais complexo que mapeamentos;
* Limpeza automática de slots de armazenamento não utilizados ao encolher arrays;
* Otimizações especiais para `bytes` e `string` que tornam o armazenamento de arrays curtos (menos de 31 bytes) mais eficiente.

## Array Simples

Vamos olhar para um array armazenando três itens:

```solidity
// c-darray.sol
pragma solidity ^0.4.11;

contract C {
	uint256[] chunks;

	function C() {
		chunks.push(0xAA);
		chunks.push(0xBB);
		chunks.push(0xCC);
	}
}
```

O código assembly para acesso ao array é complexo demais para rastrear. Vamos usar o depurador Remix para executar o contrato.

No final da simulação, podemos ver que 4 slots de armazenamento foram usados.

```shell
chave: 0x0000000000000000000000000000000000000000000000000000000000000000
valor: 0x0000000000000000000000000000000000000000000000000000000000000000003

chave: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
valor: 0x00000000000000000000000000000000000000000000000000000000000000aa

chave: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564
valor: 0x00000000000000000000000000000000000000000000000000000000000000bb

chave: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e565
valor: 0x00000000000000000000000000000000000000000000000000000000000000cc

A posição da variável `chunks` é `0x0`, usada para armazenar o comprimento do array (`0x3`). O hash da posição da variável é usado para encontrar os endereços onde os dados do array são armazenados:

```shell
# posição = 0
>>> keccak256(bytes32(0))
'290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563'
```

Cada item do array é armazenado sequencialmente a partir deste endereço (`0x29..63`, `0x29..64`, `0x29..65`).

## Empacotamento de Array Dinâmico

Como é o comportamento de empacotamento importante? Uma vantagem dos arrays sobre os mapeamentos é que o empacotamento é possível. Quatro itens de um array `uint128[]` cabem perfeitamente em dois slots de armazenamento (mais 1 para o comprimento).

Considere:

```solidity
pragma solidity ^0.4.11;

contract C {
	uint128[] s;

	function C() {
		s.length = 4;
		s[0] = 0xAA;
		s[1] = 0xBB;
		s[2] = 0xCC;
		s[3] = 0xDD;
	}
}
```

Executando isso no Remix, o armazenamento final é assim:

```shell
chave: 0x0000000000000000000000000000000000000000000000000000000000000000
valor: 0x0000000000000000000000000000000000000000000000000000000000000004

chave: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
valor: 0x000000000000000000000000000000bb000000000000000000000000000000aa

chave: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564
valor: 0x000000000000000000000000000000dd000000000000000000000000000000cc
```

Como esperado, apenas 3 slots de armazenamento foram usados. O comprimento é armazenado novamente em `0x0`, a posição da variável de armazenamento. Quatro itens são empacotados em dois slots de armazenamento separados. O endereço inicial deste array é o hash da posição da variável:

```shell
# posição = 0
>>> keccak256(bytes32(0))
'290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563'
```

Agora, o endereço aumenta uma vez a cada dois elementos do array. Parece bom!

No entanto, o código assembly em si não é otimizado de forma ideal. Apesar de usar apenas dois slots de armazenamento, esperaríamos que o otimizador usasse dois `sstore` para as atribuições. Infelizmente, devido à introdução de verificações de limites (e outras coisas), não é possível otimizar as instruções `sstore`.

Quatro instruções `sstore` são usadas para as atribuições:

```shell
/* "c-bytes--sstore-optimize-fail.sol":105:116  s[0] = 0xAA */
sstore
/* "c-bytes--sstore-optimize-fail.sol":126:137  s[1] = 0xBB */
sstore
/* "c-bytes--sstore-optimize-fail.sol":147:158  s[2] = 0xCC */
sstore
/* "c-bytes--sstore-optimize-fail.sol":168:179  s[3] = 0xDD */
sstore
```

## Arrays de Bytes e String

`bytes` e `string` são tipos especiais de arrays otimizados para bytes e caracteres, respectivamente. Se o comprimento do array for menor que 31 bytes, apenas um slot de armazenamento é usado para armazenar todo o conteúdo. Arrays de bytes mais longos são representados de forma semelhante a arrays comuns.

Vamos ver um array de bytes curto em ação:

```solidity
// c-bytes--long.sol
pragma solidity ^0.4.11;

contract C {
	bytes s;

	function C() {
		s.push(0xAA);
		s.push(0xBB);
		s.push(0xCC);
	}
}
```

Como o array tem apenas 3 bytes (menos de 31 bytes), ele ocupa apenas um slot de armazenamento. Executando no Remix, o armazenamento é:

```shell
chave: 0x0000000000000000000000000000000000000000000000000000000000000000
valor: 0xaabbcc0000000000000000000000000000000000000000000000000000000006
```

Os dados `0xaabbcc...` são armazenados da esquerda para a direita. Os zeros seguintes são dados vazios. O último byte `0x06` é o comprimento codificado do array. A fórmula é `comprimentoCodificado / 2 = comprimento`. Neste caso, o comprimento real é `6 / 2 = 3`.

O funcionamento das strings é exatamente o mesmo.

## Um Array de Bytes Longo

Se os dados forem maiores que 31 bytes, o array de bytes se comporta de forma semelhante a `[]byte`. Vamos ver um array de bytes de 128 bytes:

```solidity
// c-bytes--long.sol
pragma solidity ^0.4.11;

contract C {
	bytes s;

	function C() {
		s.length = 32 * 4;
		s[31] = 0x1;
		s[63] = 0x2;
		s[95] = 0x3;
		s[127] = 0x4;
	}
}
```

Executando no Remix, vemos que quatro slots de armazenamento são usados:

```shell
0x0000...0000
0x0000...0101

0x290d...e563
0x0000...0001

0x290d...e564
0x0000...0002

0x290d...e565
0x0000...0003

0x290d...e566
0x0000...0004
```

O slot de armazenamento `0x0` não é mais usado para armazenar dados. O slot inteiro agora armazena o comprimento codificado do array. Para obter o comprimento real, execute `comprimento = (comprimentoCodificado - 1) / 2`. Neste caso, o comprimento é `128 = (0x101 - 1) / 2`. Os bytes reais são armazenados começando em `0x290d...e563` e armazenados sequencialmente nos slots seguintes.

O código assembly para arrays de bytes é extenso. Além das verificações de limites normais e ajustes de tamanho do array, ele também precisa codificar/descodificar o comprimento e lidar com a transição entre arrays de bytes curtos e longos.

> Por que codificar o comprimento? Por causa da maneira como é feito, há um método simples para testar se um array de bytes é curto ou longo. Note que o comprimento codificado de arrays longos é sempre ímpar, enquanto para arrays curtos é par. O código assembly só precisa olhar para o último bit para ver se é zero (par/curto) ou não-zero (ímpar/longo).

## Conclusão

Ao explorar o funcionamento interno do compilador Solidity, descobrimos que estruturas de dados familiares, como mapeamentos e arrays, operam de maneira completamente diferente das linguagens de programação tradicionais.

Para recapitular:

* Arrays são como mapeamentos, mas menos eficientes.
* Código assembly mais complexo do que mapeamentos.
* Tipos menores (byte, uint8, string) têm eficiência de armazenamento superior a mapeamentos.
* O assembly não é otimizado de forma ideal. Mesmo com empacotamento, há um `sstore` por atribuição.

O armazenamento EVM é um banco de dados de pares chave-valor, muito parecido com o git. Se você alterar qualquer coisa, o checksum do nó raiz muda. Se dois checksums de nó raiz forem iguais, garante-se que os dados armazenados sejam os mesmos.

Para entender as peculiaridades do Solidity e do EVM, imagine que cada elemento de um array é seu próprio arquivo em um repositório git. Quando você altera o valor de um elemento do array, você está, na verdade, criando um commit git. Quando você itera por um array, você não pode carregar o array inteiro de uma vez; você precisa olhar para o repositório e encontrar cada arquivo separadamente.

Além disso, cada arquivo é limitado a 32 bytes! Porque precisamos dividir estruturas de dados em blocos de 32 bytes, o compilador Solidity se torna complexo devido a várias lógicas e truques de otimização, todos realizados em assembly.

No entanto, a limitação de 32 bytes é completamente arbitrária. O armazenamento de pares chave-valor subjacente pode armazenar qualquer quantidade de bytes usando a chave. Talvez no futuro, possamos adicionar uma nova instrução EVM para usar a chave para armazenar qualquer quantidade de bytes.

Por enquanto, o armazenamento EVM é um banco de dados de pares chave-valor que finge ser um array de 32 bytes.

> Veja [ArrayUtils::resizeDynamicArray](https://github.com/ethereum/solidity/blob/3b07c4d38e40c52ee8a4d16e56e2afa1a0f27905/libsolidity/codegen/ArrayUtils.cpp#L624) para entender o que o compilador faz ao ajustar o tamanho de um array. Normalmente, estruturas de dados seriam implementadas como parte de uma biblioteca padrão em uma linguagem, mas no Solidity, elas são embutidas no compilador.