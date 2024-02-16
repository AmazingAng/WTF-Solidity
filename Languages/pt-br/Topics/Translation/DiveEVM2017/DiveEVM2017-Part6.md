# Aprofundando na Máquina Virtual Ethereum Parte 6 - Implementação de Eventos Solidity

> Artigo original: [How Solidity Events Are Implemented — Diving Into The Ethereum VM Part 6 | por Howard | 21 de janeiro de 2018](https://blog.qtum.org/how-solidity-events-are-implemented-diving-into-the-ethereum-vm-part-6-30e07b3037b9)

Na parte anterior, aprendemos como "métodos" são abstrações construídas sobre primitivas mais simples da EVM, como instruções "jump" e "compare".

Neste artigo, vamos explorar mais a fundo os [Eventos Solidity](https://docs.soliditylang.org/en/develop/contracts.html#events). Em geral, os registros de eventos têm três usos principais:

* Como uma alternativa para valores de retorno, já que transações não registram o valor de retorno dos métodos.
* Como uma alternativa mais barata para armazenamento de dados, desde que o contrato não precise acessá-lo.
* Por fim, como eventos que clientes DApp podem assinar.

Os registros de eventos são uma característica de linguagem relativamente complexa. Mas, assim como os métodos, eles são mapeados para primitivas de registro de eventos mais simples da EVM.

Ao entender como os eventos são implementados usando instruções de nível mais baixo da EVM e seus custos, ganhamos uma intuição melhor para usar eventos de forma eficaz.

Se você não está familiarizado com o conteúdo anterior, por favor, leia os artigos anteriores:

* [Aprofundando na Máquina Virtual Ethereum Parte 1 - Assembly e Bytecode](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)
* [Aprofundando na Máquina Virtual Ethereum Parte 2 - Representação de Tipos de Dados de Comprimento Fixo](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)
* [Aprofundando na Máquina Virtual Ethereum Parte 3 - Representação de Tipos de Dados Dinâmicos](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)
* [Aprofundando na Máquina Virtual Ethereum Parte 4 - Chamadas Externas de Métodos de Contratos Inteligentes](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part4.md)
* [Aprofundando na Máquina Virtual Ethereum Parte 5 - Processo de Criação de Contratos Inteligentes](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part5.md)

## Eventos Solidity

Um evento Solidity se parece com isto:

```solidity
event Deposit(
	address indexed _from,
	bytes32 indexed _id,
	uint _value
);
```

* Seu nome é `Deposit`;
* Ele tem três parâmetros de tipos diferentes;
* Dois desses tipos são "indexados";
* Um parâmetro não é "indexado".

Eventos Solidity têm duas restrições peculiares:

* No máximo, podem ter 3 parâmetros indexados;
* Se o tipo do parâmetro indexado for maior que 32 bytes (como string e bytes), os dados reais não são armazenados, mas sim o resumo KECCAK256 dos dados.

Por que é assim? Qual é a diferença entre parâmetros indexados e não indexados?

## Primitivas de Registro da EVM

Para começar a entender essas peculiaridades e restrições dos eventos Solidity, vamos olhar para as instruções `log0`, `log1`, ..., `log4` da EVM.

As ferramentas de registro da EVM usam uma terminologia diferente da Solidity:

* "topics": Podem ter até 4 tópicos. Cada tópico tem exatamente 32 bytes.
* "data": Os dados são o payload do evento. Pode ser qualquer número de bytes.

Como os eventos Solidity são mapeados para as primitivas de registro?

* Todos os "parâmetros não indexados" de um evento são armazenados como dados.
* Cada "parâmetro indexado" de um evento é armazenado como um tópico de 32 bytes.

Como strings e bytes podem exceder 32 bytes, se forem indexados, a Solidity armazena o resumo KECCAK256 em vez dos dados reais.

A Solidity permite no máximo 3 parâmetros indexados, mas a EVM permite até 4 tópicos. Acontece que a Solidity usa um tópico como a assinatura do evento.

## A Primitiva log0

A primitiva de registro mais simples é `log0`. Isso cria um item de registro que tem apenas dados, mas nenhum tópico. Os dados do registro podem ser qualquer número de bytes.

Podemos usar `log0` diretamente na Solidity. Neste exemplo, vamos armazenar um número de 32 bytes:

```solidity
pragma solidity ^0.4.18;

contract Logger {
	function Logger() public {
		log0(0xc0fefefe);
	}
}
```

O assembly gerado pode ser dividido em duas partes. A primeira parte copia os dados do registro (`0xc0fefefe`) da pilha para a memória. A segunda parte coloca os parâmetros da instrução `log0` na pilha, indicando onde os dados estão localizados na memória.

Assembly anotado:

```shell
memory: { 0x40 => 0x60 }

tag_1:
  // copia dados para a memória
  0xc0fefefe
    [0xc0fefefe]
  mload(0x40)
    [0x60 0xc0fefefe]
  swap1
    [0xc0fefefe 0x60]
  dup2
    [0x60 0xc0fefefe 0x60]
  mstore
    [0x60]
    memory: {
      0x40 => 0x60
      0x60 => 0xc0fefefe
    }

// calcula posição inicial dos dados e tamanho
  0x20
    [0x20 0x60]
  add
    [0x80]
  mload(0x40)
    [0x60 0x80]
  dup1
    [0x60 0x60 0x80]
  swap2
    [0x60 0x80 0x60]
  sub
    [0x20 0x60]
  swap1
    [0x60 0x20]

log0
```

Justo antes de executar `log0`, a pilha tem dois parâmetros: `[0x60 0x20]`.

* `start`: 0x60 é a posição na memória onde os dados são carregados.
* `size`: 0x20 (ou 32) especifica o número de bytes de dados a serem carregados.

A implementação de `log0` no go-ethereum é a seguinte:

```go
func log0(pc *uint64, evm *EVM, contract *Contract, memory *Memory, stack *Stack) ([]byte, error) {
	mStart, mSize := stack.pop(), stack.pop()

	data := memory.Get(mStart.Int64(), mSize.Int64())

	evm.StateDB.AddLog(&types.Log{
		Address: contract.Address(),
		Data:    data,
		// Este é um campo não-consenso, mas atribuído aqui porque
		// core/state não sabe o número do bloco atual.
		BlockNumber: evm.BlockNumber.Uint64(),
	})

	evm.interpreter.intPool.put(mStart, mSize)
	return nil, nil
}
```

Você pode ver neste código que `log0` retira dois parâmetros da pilha e então copia os dados da memória. Em seguida, chama `StateDB.AddLog` para associar o registro ao contrato.

## Registro Com Tópicos

Tópicos são dados arbitrários de 32 bytes. Implementações Ethereum usarão esses tópicos para indexar registros de eventos, permitindo consultas e filtros eficientes de registros de eventos.

Este exemplo usa a primitiva `log2`. O primeiro parâmetro são os dados (qualquer número de bytes), seguido por 2 tópicos (32 bytes cada):

```solidity
// log-2.sol
pragma solidity ^0.4.18;

contract Logger {
	function Logger() public {
		log2(0xc0fefefe, 0xaaaa1111, 0xbbbb2222);
	}
}
```

O assembly é muito semelhante. A única diferença é que dois tópicos (`0xbbbb2222`, `0xaaaa1111`) são empurrados para a pilha no início:

```shell
tag_1:
  // empurra tópicos
  0xbbbb2222
  0xaaaa1111

// copia dados para a memória
  0xc0fefefe
  mload(0x40)
  swap1
  dup2
  mstore
  0x20
  add
  mload(0x40)
  dup1
  swap2
  sub
  swap1

// cria registro
  log2
```

Os dados ainda são `0xc0fefefe`, copiados para a memória. Justo antes de executar `log2`, o estado da EVM é o seguinte:

```shell
stack: [0x60 0x20 0xaaaa1111 0xbbbb2222]
memory: {
  0x60: 0xc0fefefe
}

log2
```

Os dois primeiros parâmetros especificam a área de memória usada como dados do registro. Os dois parâmetros adicionais na pilha são os dois tópicos de 32 bytes.

## Todas as Primitivas de Registro da EVM

A EVM suporta 5 primitivas de registro:

```shell
0xa0 LOG0
0xa1 LOG1
0xa2 LOG2
0xa3 LOG3
0xa4 LOG4
```

Elas são todas iguais, exceto pelo número de tópicos usados. A implementação no go-ethereum usa o mesmo código para gerar essas instruções, apenas variando o tamanho, que especifica o número de tópicos a serem retirados da pilha.

```go
func makeLog(size int) executionFunc {
	return func(pc *uint64, evm *EVM, contract *Contract, memory *Memory, stack *Stack) ([]byte, error) {
		topics := make([]common.Hash, size)
		mStart, mSize := stack.pop(), stack.pop()
		for i := 0; i < size; i++ {
			topics[i] = common.BigToHash(stack.pop())
		}

		d := memory.Get(mStart.Int64(), mSize.Int64())
		evm.StateDB.AddLog(&types.Log{
			Address: contract.Address(),
			Topics:  topics,
			Data:    d,
			// Este é um campo não-consenso, mas atribuído aqui porque
			// core/state não sabe o número do bloco atual.
			BlockNumber: evm.BlockNumber.Uint64(),
		})

		evm.interpreter.intPool.put(mStart, mSize)
		return nil, nil
	}
}
```

Sinta-se à vontade para verificar o código no sourcegraph: [https://sourcegraph.com/github.com/ethereum/go-ethereum@83d16574444d0b389755c9003e74a90d2ab7ca2e/-/blob/core/vm/instructions.go#L744](https://sourcegraph.com/github.com/ethereum/go-ethereum@83d16574444d0b389755c9003e74a90d2ab7ca2e/-/blob/core/vm/instructions.go#L744)

## Demonstração de Registro no Testnet

Vamos tentar gerar alguns registros usando um contrato implantado. O contrato registra 5 vezes, usando diferentes dados e tópicos:

```solidity
pragma solidity ^0.4.18;

contract Logger {
	function Logger() public {
		log0(0x0);
		log1(0x1, 0xa);
		log2(0x2, 0xa, 0xb);
		log3(0x3, 0xa, 0xb, 0xc);
		log4(0x4, 0xa, 0xb, 0xc, 0xd);
	}
}
```

Este contrato foi implantado na rede de teste Rinkeby. A transação que criou este contrato é: [https://rinkeby.etherscan.io/tx/0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1](https://rinkeby.etherscan.io/tx/0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1)

Clicando na opção "Event Logs", você deve ver os dados brutos dos 5 itens de registro.

Os tópicos são todos de 32 bytes. Os números que registramos como dados são codificados como números de 32 bytes.

## Consultando os Registros

Vamos usar o JSON RPC do Ethereum para consultar esses registros. Nós de API Ethereum criarão índices para permitir a localização eficiente de registros por correspondência de tópicos, ou para encontrar registros gerados por um endereço de contrato.

Vamos usar o nó RPC hospedado fornecido por [infura.io](https://infura.io/). Você pode obter uma chave de API registrando-se para uma conta gratuita.

Depois de obter a chave, configure a variável de shell `INFURA_KEY` para que os exemplos de curl a seguir funcionem:

Aqui está um exemplo simples, onde chamamos [eth_getLogs](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getlogs) para obter todos os registros associados ao contrato:

```shell
curl "https://rinkeby.infura.io/$INFURA_KEY" \
  -X POST \
  -H "Content-Type: application/json" \
  --data '
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getLogs",
  "params": [{
    "fromBlock": "0x0",
    "address": "0x507e86b11541bcb1f3fe200b2f10ed8fd9413bd0"
  }]
}
'
```

* `fromBlock`: De qual bloco começar a procurar pelos registros. Por padrão, começa a olhar do topo da cadeia de blocos. Queremos todos os registros, então começamos do primeiro bloco.
* `address`: Os registros são indexados pelo endereço do contrato, então isso é realmente eficiente.

A saída é os dados brutos que o etherscan mostra para a opção "Event Logs". Veja a saída completa: [evmlog.json](https://gist.github.com/hayeah/fbc862a87534bc45e77eddea9d779847).

Um item de registro retornado pela API JSON se parece com isto:

```json
{
	"address": "0x507e86b11541bcb1f3fe200b2f10ed8fd9413bd0",
	"topics": [
		"0x000000000000000000000000000000000000000000000000000000000000000a"
	],
	"data": "0x0000000000000000000000000000000000000000000000000000000000000001",
	"blockNumber": "0x179097",
	"transactionHash": "0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1",
	"transactionIndex": "0x1",
	"blockHash": "0x541bb92d8de24cad637717cdc43ae5e66d9d6193b9f964fbb6461f6727eb9e57",
	"logIndex": "0x2",
	"removed": false
}
```

Em seguida, podemos consultar por registros que correspondam ao tópico "0xc":

```shell
curl "https://rinkeby.infura.io/$INFURA_KEY" \
  -X POST \
  -H "Content-Type: application/json" \
  --data '
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getLogs",
  "params": [{
    "fromBlock": "0x179097",
    "toBlock": "0x179097",
    "address": "0x507e86b11541bcb1f3fe200b2f10ed8fd9413bd0",
    "topics": [null, null, "0x000000000000000000000000000000000000000000000000000000000000000c"]
  }]
}
'
```

* `topics`: Um array de tópicos para corresponder. `null` corresponde a qualquer coisa. Veja [a documentação detalhada](https://github.com/ethereum/wiki/wiki/JSON-RPC#parameters-38).

Deveria haver dois registros correspondentes:

```json
{
    "address": "0x507e86b11541bcb1f3fe200b2f10ed8fd9413bd0",
    "topics": [
        "0x000000000000000000000000000000000000000000000000000000000000000a",
        "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b",
        "0x000000000000000000000000000000000000000000000000000000000000000c"
    ],
    "data": "0x0000000000000000000000000000000000000000000000000000000000000003",
    "blockNumber": "0x179097",
    "transactionHash": "0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1",
    "transactionIndex": "0x1",
    "blockHash": "0x541bb92d8de24cad637717cdc43ae5e66d9d6193b9f964fbb6461f6727eb9e57",
    "logIndex": "0x4",
    "removed": false
},
{
    "address": "0x507e86b11541bcb1f3fe200b2f10ed8fd9413bd0",
    "topics": [
        "0x000000000000000000000000000000000000000000000000000000000000000a",
        "0x000000000000000000000000000000000000000000000000000000000000000b",
        "0x000000000000000000000000000000000000000000000000000000000000000c",
        "0x000000000000000000000000000000000000000000000000000000000000000d"
    ],
    "data": "0x0000000000000000000000000000000000000000000000000000000000000004",
    "blockNumber": "0x179097",
    "transactionHash": "0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1",
    "transactionIndex": "0x1",
    "blockHash": "0x541bb92d8de24cad637717cdc43ae5e66d9d6193b9f964fbb6461f6727eb9e57",
    "logIndex": "0x5",
    "removed": false
}
```

## Custos de Gas para Registro

Os custos de gas para as primitivas de registro dependem de quantos tópicos você tem e quanto dados você está registrando:

```shell
// Por byte em dados de uma operação LOG
LogDataGas       uint64 = 8
// Por LOG
topicLogTopicGas uint64 = 375   
// Por operação LOG.
LogGas           uint64 = 375
```

Essas constantes são definidas em [protocol_params](https://github.com/ethereum/go-ethereum/blob/a139041d409d0ffaf81c7cf931c6b24299a05705/params/protocol_params.go#L25).

Não esqueça do uso de memória, que é 3 gas por byte:

```shell
MemoryGas        uint64 = 3  
```

Espera aí? Cada byte de dados de registro custa apenas 8 gas? Isso significa que 32 bytes custam 256 gas, e o uso de memória custa 96 gas. Então, 322 gas contra 20000 gas para armazenar a mesma quantidade de dados, custando apenas 1.7%!

Mas espere, se você passar os dados do registro como calldata para a transação, você também precisa pagar pelo dado da transação. O custo de gas para calldata é:

```shell
TxDataZeroGas      uint64 = 4     // byte de dado de tx zero
TxDataNonZeroGas   uint64 = 68    // byte de dado de tx não-zero
```

Assumindo que todos os 32 bytes não são zero, isso ainda é muito mais barato do que armazenamento:

```shell
// custo de 32 bytes de dados de registro
32 * 68 = 2176 // custo de dado de tx
32 * 8 = 256 // custo de dado de registro
32 * 3 = 96 // custo de uso de memória
375 // custo de chamada de registro
----
total (2176 + 256 + 96 + 375)

~14% de sstore para 32 bytes
```

A maior parte do custo de gas é realmente gasta com o dado da transação, não com a operação de registro em si.

As operações de registro são baratas porque os dados de registro não são realmente armazenados na blockchain. Em princípio, os registros podem ser recalculados conforme necessário. Especialmente os mineradores, podem simplesmente descartar os dados de registro, já que cálculos futuros não podem acessar registros passados de qualquer forma.

A rede inteira não assume o custo dos registros. Apenas nós de serviços de API precisam realmente processar, armazenar e indexar registros.

Portanto, a estrutura de custo dos registros é apenas o custo mínimo para prevenir spam de registros.

## Eventos Solidity

Compreendendo como as primitivas de registro funcionam, os eventos Solidity são simples.

Vamos olhar para um tipo de evento `Log` que toma 3 parâmetros uint256 (não indexados):

```solidity
pragma solidity ^0.4.18;

contract Logger {
	event Log(uint256 a, uint256 b, uint256 c);
	function log(uint256 a, uint256 b, uint256 c) public {
		Log(a, b, c);
	}
}
```

Em vez de olhar para o código assembly, vamos olhar para o registro bruto gerado.

Esta é uma transação que chama `log(1, 2, 3)`: [https://rinkeby.etherscan.io/tx/0x9d3d394867330ae75d7153def724d062b474b0feb1f824fe1ff79e772393d395](https://rinkeby.etherscan.io/tx/0x9d3d394867330ae75d7153def724d062b474b0feb1f824fe1ff79e772393d395)

Os dados no registro são os parâmetros do evento, codificados em ABI:

```shell
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003
```

Há apenas um tópico, um hash misterioso de 32 bytes:

```shell
0x00032a912636b05d31af43f00b91359ddcfddebcffa7c15470a13ba1992e10f0
```

Este é o hash SHA3 da assinatura do tipo de evento:

```shell
# Instale pyethereum 
# https://github.com/ethereum/pyethereum/#installation
> from ethereum.utils import sha3
> sha3("Log(uint256,uint256,uint256)").hex()
'00032a912636b05d31af43f00b91359ddcfddebcffa7c15470a13ba1992e10f0'
```

Isso é muito semelhante à forma como a codificação ABI funciona para chamadas de método.

Como os eventos Solidity usam um tópico como a assinatura do evento, restam apenas 3 tópicos para parâmetros indexados.

## Evento Solidity Com Argumentos Indexados

Vamos olhar para um evento com um parâmetro `uint256` indexado:

```solidity
pragma solidity ^0.4.18;

contract Logger {
	event Log(uint256 a, uint256 indexed b, uint256 c);
	function log(uint256 a, uint256 b, uint256 c) public {
		Log(a, b, c);
	}
}
```

O registro de evento gerado agora tem dois tópicos:

```shell
0x00032a912636b05d31af43f00b91359ddcfddebcffa7c15470a13ba1992e10f0
0x0000000000000000000000000000000000000000000000000000000000000002
```

* O primeiro tópico é a assinatura do tipo de evento, após o hash.
* O segundo tópico é o parâmetro indexado, no valor original.

Os dados são os parâmetros do evento codificados em ABI, excluindo os parâmetros indexados:

```shell
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000003
```

## Parâmetro de Evento String/Bytes

Agora, vamos mudar o parâmetro do evento para uma string:

```solidity
pragma solidity ^0.4.18;

contract Logger {
	event Log(string a, string indexed b, string c);
	function log(string a, string b, string c) public {
		Log(a, b, c);
	}
}
```

Usando `log("a", "b", "c")` para gerar o registro. A transação é: [https://rinkeby.etherscan.io/tx/0x21221c2924bbf1860db9e098ab98b3fd7a5de24dd68bab1ea9ce19ae9c303b56](https://rinkeby.etherscan.io/tx/0x21221c2924bbf1860db9e098ab98b3fd7a5de24dd68bab1ea9ce19ae9c303b56)

Há dois tópicos:

```shell
0xb857d3ea78d03217f929ae616bf22aea6a354b78e5027773679b7b4a6f66e86b
0xb5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510
```

* O primeiro tópico ainda é a assinatura do método.
* O segundo tópico é o resumo sha256 do parâmetro da string.

Vamos verificar se o hash de "b" corresponde ao segundo tópico:

```shell
>>> sha3("b").hex()
'b5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510'
```

Os dados do registro são os dois parâmetros de string não indexados "a" e "c", codificados em ABI:

```shell
0000000000000000000000000000000000000000000000000000000000000040
0000000000000000000000000000000000000000000000000000000000000080
0000000000000000000000000000000000000000000000000000000000000001
6100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000001
6300000000000000000000000000000000000000000000000000000000000000
```

Infelizmente, a string original do parâmetro indexado não é armazenada (porque é usada a hash), então clientes DApp não podem recuperá-la.

Se você realmente precisa da string original, basta registrar duas vezes, incluindo indexado e não indexado:

```shell
event Log(string a, string indexed indexedB, string b);

Log("a", "b", "b");
```

## Consulta Eficiente por Registros

Como encontramos todos os registros onde o primeiro tópico corresponde a "0x000...001"? Poderíamos começar do bloco gênesis e reexecutar cada transação, vendo se os registros gerados correspondem ao nosso filtro. Isso não é ideal.

Acontece que o cabeçalho do bloco contém informações suficientes para nos permitir pular rapidamente blocos que não têm os registros que queremos.

O cabeçalho do bloco inclui o hash do pai, hash dos tios, base da moeda e um filtro de Bloom para todas as informações indexáveis (endereço do registrador e tópicos de registro) contidas em cada entrada de registro do recibo de cada transação na lista de transações. Parece algo assim:

```json
type Header struct {

    ParentHash  common.Hash    `json:"parentHash"       gencodec:"required"`

    UncleHash   common.Hash    `json:"sha3Uncles"       gencodec:"required"`

    Coinbase    common.Address `json:"miner"            gencodec:"required"`

    // ...

    // O filtro de Bloom composto de informações indexáveis (endereço do registrador e tópicos de registro) contidas em cada entrada de registro do recibo de cada transação na lista de transações
    Bloom       Bloom          `json:"logsBloom"        gencodec:"required"`
}
```

[https://sourcegraph.com/github.com/ethereum/go-ethereum@479aa61f11724560c63a7b56084259552892819d/-/blob/core/types/block.go#L70:1](https://sourcegraph.com/github.com/ethereum/go-ethereum@479aa61f11724560c63a7b56084259552892819d/-/blob/core/types/block.go#L70:1)

O filtro de Bloom é uma estrutura de dados fixa de 256 bytes. Ele age como um conjunto, onde você pode perguntar se um determinado tópico existe.

Então, podemos otimizar o processo de consulta de registros assim:

```shell
for block in chain:
    # verifica o filtro de Bloom para filtrar rapidamente um bloco
    if not block.Bloom.exist(topic):
        next
    # o bloco pode ter o registro que queremos, reexecuta
    for tx in block.transactions:
        for log in tx.recalculateLogs():
            if log.topic[0].matches(topic)
                yield log
```

Além dos tópicos, o endereço do contrato que emitiu o registro também é adicionado ao filtro de Bloom.

## BloomBitsTrie

A rede principal Ethereum tinha cerca de 5.000.000 de blocos em janeiro de 2018, iterar por todos os blocos ainda é muito caro, pois você precisa carregar os cabeçalhos dos blocos do disco.

O cabeçalho médio do bloco tem cerca de 500 bytes, você estaria carregando um total de 2,5 GB de dados.

[Felföldi Zsolt](https://github.com/zsfelfoldi) implementou o BloomBitsTrie no [PR #14970](https://github.com/ethereum/go-ethereum/pull/14970) para tornar a filtragem de registros mais rápida. A ideia é, em vez de olhar para o filtro de Bloom de cada bloco individualmente, projetar uma estrutura de dados que olhe para 32.768 blocos de uma vez.

Para entender o que vem a seguir, a informação mínima que você precisa saber sobre filtros de Bloom é que, para "hashar" um pedaço de dados em um filtro de Bloom, você define 3 bits aleatórios (mas determinísticos) no filtro de Bloom como 1. Para verificar a existência, verificamos se esses 3 bits estão definidos como 1.

O filtro de Bloom usado no Ethereum é de 2048 bits.

Suponha que o tópico "0xa" defina os bits 16, 632 e 777 do filtro de Bloom como 1. O BloomBits Trie é um bitmap de 2048 x 32.768 bits. Indexar a estrutura `BloomBits` nos fornece três vetores de 32.768 bits:

```shell
BloomBits[15] => vetor de 32.768 bits (4096 bytes)
BloomBits[631] => vetor de 32.768 bits (4096 bytes)
BloomBits[776] => vetor de 32.768 bits (4096 bytes)
```

Esses vetores de bits nos dizem quais blocos têm os bits 16, 632 e 777 do filtro de Bloom definidos como 1.

Vamos olhar para os primeiros 8 bits desses vetores, que podem parecer algo assim:

```shell
10110001...
00101101...
10101001...
```

* O 1º bloco tem os bits 16 e 776 definidos como 1, mas não o 631.
* O 3º bloco tem todos os três bits definidos.
* O 8º bloco tem todos os três bits definidos.

Então, podemos encontrar rapidamente os blocos que correspondem a todos os três bits aplicando um AND binário nesses vetores:

```shell
00100001...
```

O vetor de bits final nos diz exatamente quais dos 32.768 blocos correspondem ao nosso filtro.

Para corresponder a vários tópicos, simplesmente indexamos cada tópico da mesma maneira e então fazemos um AND binário dos vetores de bits finais.

Para mais detalhes sobre como isso funciona, veja [BloomBits Trie](https://github.com/zsfelfoldi/go-ethereum/wiki/BloomBits-Trie).

## Conclusão

Em resumo, um registro EVM pode ter até 4 tópicos e qualquer número de bytes como dados. Os parâmetros não indexados de um evento Solidity são codificados em ABI como dados, e os parâmetros indexados são usados como tópicos de registro.

O custo de gas para armazenar dados de registro é muito mais barato do que o armazenamento regular, então você pode considerá-lo como uma alternativa para DApps, desde que seu contrato não precise acessar os dados.

Duas escolhas de design alternativas para a facilidade de registro poderiam ser:

* Permitir mais tópicos, embora mais tópicos reduzam a eficência dos filtros de Bloom usados para indexar registros por tópico.
* Permitir que os tópicos tenham qualquer número de bytes. Por que não?

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->