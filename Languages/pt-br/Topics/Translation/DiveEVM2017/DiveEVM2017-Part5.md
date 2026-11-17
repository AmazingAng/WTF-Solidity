# Profundando na Máquina Virtual Ethereum Parte 5 - O Processo de Criação de Contratos Inteligentes

> Original: [Diving Into The Ethereum VM Part 5 — The Smart Contract Creation Process | by Howard | Oct 24, 2017](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-5-the-smart-contract-creation-process-cb7b6133b855)

Nos artigos anteriores desta série, aprendemos os conceitos básicos da montagem da EVM e como a codificação ABI permite a comunicação entre o mundo externo e os contratos. Neste artigo, vamos aprender como criar contratos a partir do zero.

Artigos anteriores desta série (em ordem):

* [Profundando na Máquina Virtual Ethereum Parte 1 - Montagem e Código de Bytes](../Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)
* [Profundando na Máquina Virtual Ethereum Parte 2 - Representação de Tipos de Dados de Comprimento Fixo](../Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)
* [Profundando na Máquina Virtual Ethereum Parte 3 - Representação de Tipos de Dados Dinâmicos](../Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)
* [Profundando na Máquina Virtual Ethereum Parte 4 - Chamadas de Métodos Externos de Contratos Inteligentes](../Topics/Translation/DiveEVM2017/DiveEVM2017-Part4.md)

Até agora, vimos que o bytecode da EVM é bastante simples, apenas uma sequência de instruções executadas de cima para baixo, sem mágica. O processo de criação de contratos é mais interessante, pois ele borra a linha entre código e dados.

Coloque seu chapéu de bruxo favorito 🎩

## Certidão de Nascimento de um Contrato

Vamos criar um contrato simples (e completamente inútil):

```solidity
// c.sol
pragma solidity ^0.4.11;

contract C {
}
```

Compile-o:

```shell
solc --bin --asm c.sol
```

O bytecode é:

```shell
60606040523415600e57600080fd5b5b603680601c6000396000f30060606040525b600080fd00a165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

Para criar este contrato, precisamos fazer uma chamada RPC [eth_sendTransaction](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sendTransaction) para um nó Ethereum. Você pode usar o Remix ou o MetaMask para fazer isso.

Independentemente da ferramenta de implantação que você usar, os parâmetros da chamada RPC serão semelhantes a isto:

```json
{
  "from": "0xbd04d16f09506e80d1fd1fd8d0c79afa49bd9976",
  "to": null,
  "gas": "68653", // 30400,
  "gasPrice": "1", // 10000000000000
  "data": "0x60606040523415600e57600080fd5b603580601b6000396000f3006060604052600080fd00a165627a7a723058204bf1accefb2526a5077bcdfeaeb8020162814272245a9741cc2fddd89191af1c0029"
}
```

Não há chamadas RPC ou tipos de transação especiais para criar contratos. O mesmo mecanismo de transação é usado para outros propósitos:

* Transferir ether para uma conta ou contrato.
* Chamar um método externo de um contrato com argumentos.

A interpretação da transação pelo Ethereum depende dos parâmetros que você especificar. Para criar um contrato, o endereço `to`​ deve ser vazio (ou omitido).

Eu usei essa transação para criar um exemplo de contrato:

[https://rinkeby.etherscan.io/tx/0x58f36e779950a23591aaad9e4c3c3ac105547f942f221471bf6ffce1d40f8401](https://rinkeby.etherscan.io/tx/0x58f36e779950a23591aaad9e4c3c3ac105547f942f221471bf6ffce1d40f8401)

Ao abrir o Etherscan, você deve ver que os dados de entrada dessa transação são o bytecode gerado pelo compilador Solidity.

Ao processar essa transação, a EVM executa os dados de entrada como código. *Voilà*, o contrato nasceu.

## O que o Bytecode está Fazendo

Podemos dividir o bytecode acima em três partes separadas:

```shell
// Código de implantação (Deploy code)
60606040523415600e57600080fd5b5b603680601c6000396000f300

// Código do contrato (Contract code)
60606040525b600080fd00

// Dados auxiliares (Auxdata)
a165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

* O código de implantação é executado quando o contrato é criado.
* O código do contrato é executado quando os métodos do contrato são chamados após a criação.
* (Opcional) Os dados auxiliares são uma impressão digital criptografada do código-fonte para fins de verificação. Isso é apenas dados, nunca executados pela EVM.

O código de implantação tem dois objetivos principais:

1. Executar o construtor e configurar as variáveis de armazenamento iniciais (como o proprietário do contrato).
2. Calcular o código do contrato e retorná-lo para a EVM.

O código de implantação gerado pelo compilador Solidity carrega o bytecode `60606040525b600080fd00`​ na memória e o retorna como código do contrato. Neste exemplo, a "computação" é apenas a leitura de um grande bloco de dados na memória. Em teoria, poderíamos gerar o código do contrato programaticamente.

O papel exato do construtor depende da linguagem, mas qualquer linguagem EVM deve retornar o código do contrato no final.

## Criação de Contrato

Então, o que acontece depois que o código de implantação é executado e o código do contrato é retornado? Como o Ethereum cria um contrato com base no código retornado?

Vamos mergulhar no código-fonte para obter detalhes. Descobri que a implementação do Go-Ethereum é a referência mais fácil para encontrar as informações corretas. Obtemos os nomes de variáveis corretos, informações de tipo estático e referências cruzadas de símbolos. Tente superar isso, Yellow Paper!

O método relevante é [evm.Create](https://sourcegraph.com/github.com/ethereum/go-ethereum@e9295163aa25479e817efee4aac23eaeb7554bba/-/blob/core/vm/evm.go#L301), leia-o no Sourcegraph (ele mostra informações de tipo quando você passa o mouse sobre as variáveis, muito legal). Vamos dar uma olhada no código, pulando algumas verificações de erro e detalhes tediosos. De cima para baixo:

* Verifique se o chamador tem saldo suficiente para a transferência:

```go
if !evm.CanTransfer(evm.StateDB, caller.Address(), value) {
	return nil, common.Address{}, gas, ErrInsufficientBalance
}
```

* Gere o endereço do novo contrato a partir do endereço do chamador (usando o `nonce`​ da conta do criador):

```go
contractAddr = crypto.CreateAddress(caller.Address(), nonce)
```

* Crie uma nova conta de contrato usando o endereço gerado:

```go
evm.StateDB.CreateAccount(contractAddr)
```

* Transfira a doação inicial de ether do chamador para o novo contrato:

```go
evm.Transfer(evm.StateDB, caller.Address(), contractAddr, value)
```

* Defina os dados de entrada como o código de implantação do contrato e execute-o usando a EVM. A variável `ret`​ contém o código do contrato retornado:

```go
contract := NewContract(caller, AccountRef(contractAddr), value, gas)
contract.SetCallCode(&contractAddr, crypto.Keccak256Hash(code), code)
ret, err = run(evm, snapshot, contract, nil)
```

* Verifique erros. Ou falhe se o código do contrato for muito grande. Consuma o gas do usuário e defina o código do contrato:

```go
if err == nil && !maxCodeSizeExceeded {
	createDataGas := uint64(len(ret)) * params.CreateDataGas
	if contract.UseGas(createDataGas) {
		evm.StateDB.SetCode(contractAddr, ret)
	} else {
		err = ErrCodeStoreOutOfGas
	}
}
```

## Código que Implanta Código

Agora vamos mergulhar no código de montagem detalhado para ver como o "código de implantação" retorna o "código do contrato" ao criar um contrato. Novamente, vamos analisar o exemplo do contrato:

```solidity
pragma solidity ^0.4.11;

contract C {
}
```

O bytecode do contrato é dividido em diferentes partes:

```shell
// Código de implantação (Deploy code)
60606040523415600e57600080fd5b5b603680601c6000396000f300

// Código do contrato (Contract code)
60606040525b600080fd00

// Dados auxiliares (Auxdata)
a165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

A montagem do código de implantação é:

```shell
// Reservar 0x60 bytes de memória para uso interno do Solidity.
mstore(0x40, 0x60)

// Contrato não pagável. Reverter se o chamador enviou ether.
jumpi(tag_1, iszero(callvalue))
0x0
dup1
revert

// Copiar o código do contrato para a memória e retornar.
tag_1:
tag_2:
  dataSize(sub_0)
  dup1
  dataOffset(sub_0)
  0x0
  codecopy
  0x0
  return
stop
```

Vamos rastrear a montagem acima para retornar o código do contrato:

```shell
// 60 36 (PUSH 0x36)
dataSize(sub_0)
  stack: [0x36]
dup1
  stack: [0x36 0x36]
// 60 1c == (PUSH 0x1c)
dataOffset(sub_0)
  stack: [0x1c 0x36 0x36]
0x0
  stack: [0x0 0x1c 0x36 0x36]
codecopy
  // Consome 3 argumentos
  // Copia `length` de dados de `codeOffset` para `memoryOffset`
  // memoryOffset = 0x0
  // codeOffset   = 0x1c
  // length       = 0x36
  stack: [0x36]
0x0
  stack: [0x0 0x36]
  memory: [
    0x0:0x36 => calldata[0x1c:0x36]
  ]
return
  // Consome 2 argumentos
  // Retorna `length` de dados de `memoryOffset`
  // memoryOffset  = 0x0
  // length        = 0x36
  stack: []
  memory: [
    0x0:0x36 => calldata[0x1c:0x36]
  ]
```

`dataSize(sub_0)`​ e `dataOffset(sub_0)`​ não são instruções reais. Na verdade, elas são instruções PUSH que colocam constantes na pilha. Os dois constantes `0x1C`​ (28) e `0x36`​ (54) especificam uma substring do bytecode como o código do contrato retornado.

A montagem do código de implantação corresponde aproximadamente ao seguinte código Python3:

```python
memory = []
calldata = bytes.fromhex("60606040523415600e57600080fd5b5b603680601c6000396000f30060606040525b600080fd00a165627a7a72305820b5090d937cf89f134d30e54dba87af4247461dd3390acf19d4010d61bfdd983a0029")

size = 0x36   // dataSize(sub_0)
offset = 0x1c // dataOffset(sub_0)

// Copiar substring de calldata para a memória
memory[0:size] = calldata[offset:offset+size]

// Em vez de retornar, imprimir o conteúdo da memória em hexadecimal
print(bytes(memory[0:size]).hex())
```

O conteúdo da memória resultante é:

```shell
60606040525b600080fd00
a165627a7a72305820b5090d937cf89f134d30e54dba87af4247461dd3390acf19d4010d61bfdd983a0029
```

Correspondendo à montagem (juntamente com auxdata):

```shell
// 6060604052600080fd00
mstore(0x40, 0x60)
tag_1:
  0x0
  dup1
  revert

auxdata: 0xa165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

Dê uma olhada no Etherscan novamente, e você verá que é exatamente o que foi implantado como código do contrato: [Ethereum Account 0x2c7f561f1fc5c414c48d01e480fdaae2840b8aa2 Info](https://rinkeby.etherscan.io/address/0x2c7f561f1fc5c414c48d01e480fdaae2840b8aa2#code)

```shell
PUSH1 0x60
PUSH1 0x40
MSTORE
JUMPDEST
PUSH1 0x00
DUP1
REVERT
STOP
```

## CODECOPY

O código de implantação usa a instrução `codecopy`​ para copiar dados da entrada da transação para a memória.

Comparado com outras instruções mais simples, o comportamento exato e os parâmetros da instrução `codecopy`​ não são tão óbvios. Se eu procurasse isso no Yellow Paper, eu poderia ficar ainda mais confuso. Em vez disso, vamos nos referir ao código-fonte do go-ethereum para ver o que ele está fazendo.

Veja [CODECOPY](https://sourcegraph.com/github.com/ethereum/go-ethereum@e9295163aa25479e817efee4aac23eaeb7554bba/-/blob/core/vm/instructions.go#L408:6):

```go
func opCodeCopy(pc *uint64, evm *EVM, contract *Contract, memory *Memory, stack *Stack) ([]byte, error) {
	var (
		memOffset  = stack.pop()
		codeOffset = stack.pop()
		length     = stack.pop()
	)
	codeCopy := getDataBig(contract.Code, codeOffset, length)
	memory.Set(memOffset.Uint64(), length.Uint64(), codeCopy)

	evm.interpreter.intPool.put(memOffset, codeOffset, length)
	return nil, nil
}
```

Sem letras gregas!

> A linha `evm.interpreter.intPool.put(memOffset, codeOffset, length)`​ recicla objetos (big integers) para uso posterior. Isso é apenas uma otimização de desempenho.

## Argumento do Construtor

Além de retornar o código do contrato, outra finalidade do código de implantação é executar o construtor para fazer a configuração. Se houver argumentos de construtor, o código de implantação precisa carregar os dados de algum lugar.

A convenção do Solidity para passar argumentos de construtor é anexá-los ao final do bytecode como uma codificação ABI dos valores dos argumentos. A chamada RPC envia o bytecode e os argumentos codificados como dados de entrada, como mostrado abaixo:

```json
{
  "from": "0xbd04d16f09506e80d1fd1fd8d0c79afa49bd9976"
  "data": hexencode(compiledByteCode + encodedParams),
}
```

Vamos dar uma olhada em um exemplo de contrato com um argumento de construtor:

```solidity
pragma solidity ^0.4.11;

contract C {
	uint256 a;

	function C(uint256 _a) {
		a = _a;
	}
}
```

Eu criei este contrato com o valor `66`. A transação no Etherscan: [https://rinkeby.etherscan.io/tx/0x2f409d2e186883bd3319a8291a345ddbc1c0090f0d2e182a32c9e54b5e3fdbd8](https://rinkeby.etherscan.io/tx/0x2f409d2e186883bd3319a8291a345ddbc1c0090f0d2e182a32c9e54b5e3fdbd8)

Os dados de entrada são:

```shell
0x60606040523415600e57600080fd5b6040516020806073833981016040528080519060200190919050508060008190555050603580603e6000396000f3006060604052600080fd00a165627a7a7230582062a4d50871818ee0922255f5848ba4c7e4edc9b13c555984b91e7447d3bb0e7400290000000000000000000000000000000000000000000000000000000000000042
```

Podemos ver que o argumento do construtor, o número 66, está presente no final dos dados de entrada, mas codificado em ABI como um número de 32 bytes:

```shell
0000000000000000000000000000000000000000000000000000000000000042
```

Para lidar com os argumentos do construtor, o código de implantação copia os argumentos ABI da parte final dos dados da transação para a memória e, em seguida, copia-os da memória para a pilha.

## Um Contrato que Cria Contratos

O contrato `FooFactory`​ pode criar novas instâncias de `Foo`​ chamando `makeNewFoo`​:

```solidity
pragma solidity ^0.4.11;

contract Foo {
}

contract FooFactory {
	address fooInstance;

	function makeNewFoo() {
		fooInstance = new Foo();
	}
}
```

A montagem completa desse contrato está em [This Gist](https://gist.github.com/hayeah/a94aa4e87b7b42e9003adf64806c84e4). A estrutura de saída do compilador é um pouco complexa, pois existem dois conjuntos de bytecode, um para "tempo de instalação" e outro para "tempo de execução". É organizado assim:

```shell
FooFactoryDeployCode
FooFactoryContractCode
	FooDeployCode
	FooContractCode
	FooAUXData
FooFactoryAUXData
```

O `FooFactoryContractCode`​ basicamente copia o bytecode de `tag_8`​ de `Foo`​ e, em seguida, salta de volta para `tag_7`​ para executar a instrução `create`​.

A instrução `create`​ é semelhante a uma chamada RPC `eth_sendTransaction`. Ela fornece uma maneira de criar um novo contrato dentro da EVM.

Para o código-fonte do go-ethereum, consulte [opCreate](https://sourcegraph.com/github.com/ethereum/go-ethereum@e9295163aa25479e817efee4aac23eaeb7554bba/-/blob/core/vm/instructions.go#L572:6). A instrução chama `evm.Create`​ para criar um contrato:

```go
res, addr, returnGas, suberr := evm.Create(contract, input, gas, value)
```

Já vimos `evm.Create`​ antes, mas desta vez o chamador é um contrato inteligente, não uma pessoa.

## AUXDATA

Se você realmente precisa saber o que é auxdata, leia [Contract Metadata](https://github.com/ethereum/solidity/blob/8fbfd62d15ae83a757301db35621e95bccace97b/docs/metadata.rst#encoding-of-the-metadata-hash-in-the-bytecode). A essência é que `auxdata`​ é um valor de hash que você pode usar para obter metadados sobre o contrato implantado.

O formato de `auxdata`​ é:

```shell
0xa1 0x65 'b' 'z' 'z' 'r' '0' 0x58 0x20 <32 bytes swarm hash> 0x00 0x29
```

Desconstruindo a sequência de bytes `auxdata`​ que vimos antes:

```shell
a1 65
// b z z r 0 (ASCII)
62 7a 7a 72 30
58 20
// 32 bytes hash
62a4d50871818ee0922255f5848ba4c7e4edc9b13c555984b91e7447d3bb0e74
00 29
```

## Conclusão

A criação de contratos é semelhante ao funcionamento de um instalador de software autoextraível. Quando o instalador é executado, ele configura o ambiente do sistema e, em seguida, extrai o programa de destino para o sistema lendo-o de seu pacote.

* Existe uma separação rígida entre "tempo de instalação" e "tempo de execução". Não há como executar o construtor duas vezes.
* Contratos inteligentes podem usar o mesmo processo para criar outros contratos inteligentes.
* É fácil de implementar em linguagens que não sejam Solidity.

Inicialmente, fiquei confuso com as diferentes partes do "instalador de contrato inteligente" sendo empacotadas como uma única string de bytes nos dados da transação:

```json
{
  "data": constructorCode + contractCode + auxdata + constructorData
}
```

Lendo a documentação de `eth_sendTransaction`, não estava claro como o `data`​ deveria ser codificado. Eu não conseguia entender como os argumentos do construtor eram passados para a transação até que um amigo me disse que eles eram codificados em ABI e anexados ao final do bytecode.

Outra abordagem de design mais clara poderia ser enviar essas partes como propriedades separadas na transação:

```json
{
	// Para o bytecode de "tempo de instalação"
	"constructorCode": ...,
	// Para o bytecode de "tempo de execução"
	"constructorBody": ...,
	// Para a codificação dos argumentos
	"data": ...,
}
```

No entanto, ao pensar mais sobre isso, acho que a simplicidade do objeto de transação é realmente poderosa. Para a transação, `data`​ é apenas uma string de bytes, sem especificar como interpretar o modelo de linguagem dos dados. Ao manter a simplicidade do objeto de transação, os implementadores de linguagens têm uma tela em branco para projetar e experimentar.

Na verdade, no futuro, `data`​ pode até ser interpretado por diferentes máquinas virtuais.

