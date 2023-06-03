# 深入以太坊虚拟机 Part5 — 智能合约创建过程

> 原文：[Diving Into The Ethereum VM Part 5 — The Smart Contract Creation Process | by Howard | Oct 24, 2017](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-5-the-smart-contract-creation-process-cb7b6133b855)

在本系列的前几篇文章中，我们学习了 EVM 汇编的基础知识，以及 ABI 编码如何允许外部世界与合约进行通信。在本文中，我们将了解如何从无到有创建合约。

本系列的前几篇文章（按顺序）。

* [深入以太坊虚拟机 Part1 — 汇编与字节码](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)
* [深入以太坊虚拟机 Part2 — 固定长度数据类型的表示 ](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)
* [深入以太坊虚拟机 Part3 — 动态数据类型的表示](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)
* [深入以太坊虚拟机 Part4 — 智能合约外部方法调用](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part4.md)

到目前为止，我们看到的 EVM 字节码很简单，只是 EVM 从上到下执行的指令，没有魔法。合约创建过程更有趣，因为它模糊了代码和数据之间的界限。

在学习如何创建合约时，我们会看到有时数据就是代码，有时代码就是数据。

戴上你最喜欢的巫师帽🎩

## A Contract's Birth Certificate

让我们创建一个简单（而且完全没用）的合约：

```solidity
// c.sol
pragma solidity ^0.4.11;

contract C {
}
```

编译它：

```shell
solc --bin --asm c.sol
```

字节码是：

```shell
60606040523415600e57600080fd5b5b603680601c6000396000f30060606040525b600080fd00a165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

要创建此合约，我们需要通过对以太坊节点进行 [eth_sendtransaction](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sendtransaction) RPC 调用来创建交易。您可以使用 Remix 或 Metamask 来执行此操作。

无论您使用什么部署工具，RPC 调用的参数都类似于：

```json
{
  "from": "0xbd04d16f09506e80d1fd1fd8d0c79afa49bd9976",
  "to": null,
  "gas": "68653", // 30400,
  "gasPrice": "1", // 10000000000000
  "data": "0x60606040523415600e57600080fd5b603580601b6000396000f3006060604052600080fd00a165627a7a723058204bf1accefb2526a5077bcdfeaeb8020162814272245a9741cc2fddd89191af1c0029"
}
```

没有特殊的 RPC 调用或交易类型来创建合约。相同的交易机制也用于其他目的：

* 将以太币转移到账户或合约。
* 使用参数调用合约的方法。

根据您指定的参数，以太坊对交易的解释不同。要创建合约，`to`​ 地址应为空（或省略）。

我用这个交易创建了示例合约：

[https://rinkeby.etherscan.io/tx/0x58f36e779950a23591aaad9e4c3c3ac105547f942f221471bf6ffce1d40f8401](https://rinkeby.etherscan.io/tx/0x58f36e779950a23591aaad9e4c3c3ac105547f942f221471bf6ffce1d40f8401)

打开 Etherscan，您应该看到该交易的输入数据是 Solidity 编译器生成的字节码。

在处理此交易时，EVM 会将输入数据作为代码执行。*Voila*，合约诞生了。

## What The Bytecode Is Doing

我们可以将上面的字节码分成三个单独的块：

```shell
// 部署代码 (Deploy code)
60606040523415600e57600080fd5b5b603680601c6000396000f300

// 合约代码 (Contract code)
60606040525b600080fd00

// 辅助数据 (Auxdata)
a165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

* 部署代码在创建合约时运行。
* 合约代码在合约创建后其方法被调用时运行。
* （可选）辅助数据是源代码的加密指纹，用于验证。这只是数据，从未由 EVM 执行。

部署代码有两个主要目标：

1. 运行构造函数，并设置初始存储变量（如合约所有者）。
2. 计算合约代码，并将其返回给 EVM。

Solidity 编译器生成的部署代码将字节码 `60606040525b600080fd00`​ 加载到内存中，然后将其作为合约代码返回。在这个例子中，“计算”只是将一大块数据读入内存。原则上，我们可以通过编程方式生成合约代码。

构造函数的确切作用取决于语言，但任何 EVM 语言都必须在最后返回合约代码。

## Contract Creation

那么在部署代码运行并返回合约代码之后会发生什么。以太坊如何根据返回的合约代码创建合约？

让我们一起深入研究源代码以了解详细信息。

我发现 Go-Ethereum 实现是查找所需信息的最简单参考。我们得到正确的变量名、静态类型信息和符号交叉引用。Try beating that, Yellow Paper!

相关的方法是 [evm.Create](https://sourcegraph.com/github.com/ethereum/go-ethereum@e9295163aa25479e817efee4aac23eaeb7554bba/-/blob/core/vm/evm.go#L301)，在 Sourcegraph 上阅读它（当您将鼠标悬停在变量上时会显示类型信息，非常棒）。让我们略读代码，省略一些错误检查和繁琐的细节。从上到下：

* 检查调用者是否有足够的余额进行转账：

```go
if !evm.CanTransfer(evm.StateDB, caller.Address(), value) {
	return nil, common.Address{}, gas, ErrInsufficientBalance
}
```

* 从调用者的地址生成(derive)新合约的地址（传入创建者账户的 `nonce`​）：

```go
contractAddr = crypto.CreateAddress(caller.Address(), nonce)
```

* 使用生成的合约地址创建新的合约账户（更改“世界状态 (word state)”StateDB）：

```go
evm.StateDB.CreateAccount(contractAddr)
```

* 将初始 Ether 捐赠(endowment)从调用者转移到新合约：

```go
evm.Transfer(evm.StateDB, caller.Address(), contractAddr, value)
```

* 将输入数据设置为合约的部署代码，然后使用 EVM 执行。`ret`​ 变量是返回的合约代码：

```go
contract := NewContract(caller, AccountRef(contractAddr), value, gas)
contract.SetCallCode(&contractAddr, crypto.Keccak256Hash(code), code)
ret, err = run(evm, snapshot, contract, nil)
```

* 检查错误。或者如果合约代码太大，则失败。收取用户 gas，然后设置合约代码：

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

## Code That Deploys Code

现在让我们深入了解详细的汇编代码，看看在创建合约时“部署代码”如何返回“合约代码”。同样，我们将分析示例合约：

```solidity
pragma solidity ^0.4.11;

contract C {
}
```

该合约的字节码分成不同的块：

```shell
// 部署代码 (Deploy code)
60606040523415600e57600080fd5b5b603680601c6000396000f300

// 合约代码 (Contract code)
60606040525b600080fd00

// 辅助数据 (Auxdata)
a165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

部署代码的汇编是：

```shell
// Reserve 0x60 bytes of memory for Solidity internal uses.
mstore(0x40, 0x60)

// Non-payable contract. Revert if caller sent ether.
jumpi(tag_1, iszero(callvalue))
0x0
dup1
revert

// Copy contract code into memory, and return.
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

跟踪上述汇编以返回合约代码：

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
  // Consumes 3 arguments
  // Copy `length` of data from `codeOffset` to `memoryOffset`
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
  // Consumes 2 arguments
  // Return `length` of data from `memoryOffset`
  // memoryOffset  = 0x0
  // length        = 0x36
  stack: []
  memory: [
    0x0:0x36 => calldata[0x1c:0x36]
  ]
```

`dataSize(sub_0)`​ 和 `dataOffset(sub_0)`​ 不是真正的指令。它们实际上是将常量放入堆栈的 PUSH 指令。两个常量 `0x1C`​ (28) 和 `0x36`​ (54) 指定一个字节码子串作为合约代码返回。

部署代码汇编大致对应如下 Python3 代码：

```python
memory = []
calldata = bytes.fromhex("60606040523415600e57600080fd5b5b603680601c6000396000f30060606040525b600080fd00a165627a7a72305820b5090d937cf89f134d30e54dba87af4247461dd3390acf19d4010d61bfdd983a0029")

size = 0x36   // dataSize(sub_0)
offset = 0x1c // dataOffset(sub_0)

// Copy substring of calldata to memory
memory[0:size] = calldata[offset:offset+size]

// Instead of return, print the memory content in hex
print(bytes(memory[0:size]).hex())
```

结果内存内容是：

```shell
60606040525b600080fd00
a165627a7a72305820b5090d937cf89f134d30e54dba87af4247461dd3390acf19d4010d61bfdd983a0029
```

对应于汇编（加上 auxdata）：

```shell
// 6060604052600080fd00
mstore(0x40, 0x60)
tag_1:
  0x0
  dup1
  revert

auxdata: 0xa165627a7a723058209747525da0f525f1132dde30c8276ec70c4786d4b08a798eda3c8314bf796cc30029
```

再次查看 Etherscan，这正是部署为合约代码的内容：[Ethereum Account 0x2c7f561f1fc5c414c48d01e480fdaae2840b8aa2 Info](https://rinkeby.etherscan.io/address/0x2c7f561f1fc5c414c48d01e480fdaae2840b8aa2#code)

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

部署代码使用 `codecopy`​ 从交易的输入数据复制到内存。

与其他更简单的指令相比，`codecopy`​ 指令的确切行为和参数不那么明显。如果我在黄皮书中查找它，我可能会更加困惑。相反，让我们参考 go-ethereum 源代码，看看它在做什么。

见 [CODECOPY](https://sourcegraph.com/github.com/ethereum/go-ethereum@e9295163aa25479e817efee4aac23eaeb7554bba/-/blob/core/vm/instructions.go#L408:6)：

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

没有希腊字母！

> `evm.interpreter.intPool.put(memOffset, codeOffset, length)`​ 行回收对象 (big integers) 以供后面使用。这只是一个效率优化。

## Constructor Argument

除了返回合约代码外，部署代码的另一个目的是运行构造函数进行设置。如果有构造函数参数，部署代码需要以某种方式从某个地方加载参数数据。

传递构造函数参数的 Solidity 约定是在调用 `eth_sendtransaction`​ 时在字节码末尾附加 ABI 编码的参数值。 RPC 调用会将字节码和 ABI 编码参数一起作为输入数据传递，如下所示：

```json
{
  "from": "0xbd04d16f09506e80d1fd1fd8d0c79afa49bd9976"
  "data": hexencode(compiledByteCode + encodedParams),
}
```

让我们看一个带有一个构造函数参数的示例合约：

```solidity
pragma solidity ^0.4.11;

contract C {
	uint256 a;

	function C(uint256 _a) {
		a = _a;
	}
}
```

我创建了这个合约，传入值 `66`​。 Etherscan 上的交易：[https://rinkeby.etherscan.io/tx/0x2f409d2e186883bd3319a8291a345ddbc1c0090f0d2e182a32c9e54b5e3fdbd8](https://rinkeby.etherscan.io/tx/0x2f409d2e186883bd3319a8291a345ddbc1c0090f0d2e182a32c9e54b5e3fdbd8)

输入数据为：

```shell
0x60606040523415600e57600080fd5b6040516020806073833981016040528080519060200190919050508060008190555050603580603e6000396000f3006060604052600080fd00a165627a7a7230582062a4d50871818ee0922255f5848ba4c7e4edc9b13c555984b91e7447d3bb0e7400290000000000000000000000000000000000000000000000000000000000000042
```

我们可以在最后看到构造函数参数，即数字 66，但 ABI 编码为 32 字节数字：

```shell
0000000000000000000000000000000000000000000000000000000000000042
```

为了处理构造函数中的参数，部署代码将 ABI 参数从 `calldata`​ 的末尾复制到内存中，然后从内存复制到堆栈中。

## A Contract That Creates Contracts

`FooFactory`​ 合约可以通过调用 `makeNewFoo`​ 创建新的 `Foo`​ 实例：

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

该合约的完整汇编在 [This Gist](https://gist.github.com/hayeah/a94aa4e87b7b42e9003adf64806c84e4) 中。编译器输出的结构比较复杂，因为有两组“install time”和“run time”字节码。它是这样组织的：

```shell
FooFactoryDeployCode
FooFactoryContractCode
	FooDeployCode
	FooContractCode
	FooAUXData
FooFactoryAUXData
```

`FooFactoryContractCode`​ 基本上是复制 `tag_8`​ 中 `Foo`​ 的字节码，然后跳转回 `tag_7`​ 以执行 `create`​ 指令。

`create`​ 指令类似于 `eth_sendtransaction`​ RPC 调用。它提供了一种在 EVM 内创建新合约的方法。

有关 go-ethereum 源代码，请参见 [opCreate](https://sourcegraph.com/github.com/ethereum/go-ethereum@e9295163aa25479e817efee4aac23eaeb7554bba/-/blob/core/vm/instructions.go#L572:6)。该指令调用 `evm.Create`​ 来创建一个合约：

```go
res, addr, returnGas, suberr := evm.Create(contract, input, gas, value)
```

我们之前见过 `evm.Create`​，但这次调用者是智能合约，而不是人。

## AUXDATA

如果您真的必须了解 auxdata 是什么，请阅读 [Contract Metadata](https://github.com/ethereum/solidity/blob/8fbfd62d15ae83a757301db35621e95bccace97b/docs/metadata.rst#encoding-of-the-metadata-hash-in-the-bytecode)。它的要点是 `auxdata`​ 是一个哈希值，您可以使用它来获取有关已部署合约的元数据。

`auxdata`​ 的格式为：

```shell
0xa1 0x65 'b' 'z' 'z' 'r' '0' 0x58 0x20 <32 bytes swarm hash> 0x00 0x29
```

解构我们之前看到的 auxdata 字节序列：

```shell
a1 65
// b z z r 0 (ASCII)
62 7a 7a 72 30
58 20
// 32 bytes hash
62a4d50871818ee0922255f5848ba4c7e4edc9b13c555984b91e7447d3bb0e74
00 29
```

## Conclusion

合约被创建的方式类似于自解压软件安装程序的工作方式。当安装程序运行时，它会配置系统环境，然后通过读取其程序包将目标程序提取到系统中。

* “install time”和“run time”之间存在强制分离。没有办法运行构造函数两次。
* 智能合约可以使用相同的过程来创建其他智能合约。
* 非 Solidity 语言很容易实现。

起初，我发现“智能合约安装程序”的不同部分在交易中作为 `data`​ 字节字符串打包在一起，这让我感到困惑：

```json
{
  "data": constructorCode + contractCode + auxdata + constructorData
}
```

从阅读 `eth_sendtransaction`​ 的文档来看，`data`​ 应该如何编码并不明显。我无法弄清楚构造函数参数是如何传递到交易中的，直到一个朋友告诉我它们是 ABI 编码然后附加到字节码的末尾。

另一种更清晰的设计可能是将这些部分作为交易中的单独属性发送：

```json
{
	// For "install time" bytecode
	"constructorCode": ...,
	// For "run time" bytecode
	"constructorBody": ...,
	// For encoding arguments
	"data": ...,
}
```

不过，仔细想想，我认为 Transaction 对象如此简单实际上非常强大。对于交易来说，`data`​ 只是一个字节字符串，它并没有规定如何解释数据的语言模型。通过保持 Transaction 对象的简单性，语言实现者有一个用于设计和实验的空白画布(blank canvas)。

事实上，未来 `data`​ 甚至可以由不同的虚拟机解释。