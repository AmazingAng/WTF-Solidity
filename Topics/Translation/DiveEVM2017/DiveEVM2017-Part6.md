# 深入以太坊虚拟机 Part6 — Solidity 事件实现

> 原文：[How Solidity Events Are Implemented — Diving Into The Ethereum VM Part 6 | by Howard | Jan 21, 2018](https://blog.qtum.org/how-solidity-events-are-implemented-diving-into-the-ethereum-vm-part-6-30e07b3037b9)

在上一部分中，我们了解了“方法”是如何建立在更简单的 EVM 原语（如“跳转”和“比较”指令）之上的抽象。

在本文中，我们将深入探讨 [Solidity Events](https://docs.soliditylang.org/en/develop/contracts.html#events)。总的来说，事件日志有三种主要用途：

* 作为替代返回值，因为交易不记录方法的返回值。
* 作为一种更便宜的替代数据存储，只要合约不需要访问它。
* 最后，作为 DApp 客户端可以订阅的事件。

事件日志是一个相对复杂的语言特性。但就像方法一样，它们映射到更简单的 EVM 日志原语。

通过了解事件是如何使用较低级别的 EVM 指令实现的，以及它们的成本，我们将获得更好的直觉来有效地使用事件。

如果你对前面的内容不熟悉，请阅读前面的文章：

* [深入以太坊虚拟机 Part1 — 汇编与字节码](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)
* [深入以太坊虚拟机 Part2 — 固定长度数据类型的表示 ](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)
* [深入以太坊虚拟机 Part3 — 动态数据类型的表示](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)
* [深入以太坊虚拟机 Part4 — 智能合约外部方法调用](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part4.md)
* [深入以太坊虚拟机 Part5 — 智能合约创建过程](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part5.md)

## Solidity Events

Solidity 事件如下所示：

```solidity
event Deposit(
	address indexed _from,
	bytes32 indexed _id,
	uint _value
);
```

* 它的名称为 `Deposit`​；
* 它具有三个不同类型的参数；
* 其中两种类型是 "indexed"；
* 一个参数不是 "indexed"。

Solidity 事件有两个奇怪的限制：

* 最多可以有 3 个索引参数；
* 如果索引参数的类型大于 32 字节（比如 string 和 bytes），则不存储实际数据，而是存储数据的 KECCAK256 摘要。

为什么会这样？索引参数和非索引参数有什么区别？

## EVM Log Primitives

要开始了解 Solidity 事件的这些怪癖和限制，让我们看一下 `log0`​、`log1`​、...、`log4`​ EVM 指令。

EVM 日志工具使用与 Solidity 不同的术语：

* “topics”：最多可以有 4 个主题(topic)。每个主题正好是 32 个字节。
* “data”：数据是事件的有效负载(payload)。它可以是任意数量的字节。

Solidity 事件如何映射到日志原语？

* 事件的所有“非索引参数”都存储为数据。
* 事件的每个“索引参数”都存储为一个 32 字节的主题。

由于 string 和 bytes 可能超过 32 个字节，如果它们被索引，Solidity 将存储 KECCAK256 摘要而不是实际数据。

Solidity 最多允许拥有 3 个索引参数，但 EVM 最多允许拥有 4 个主题。事实证明，Solidity 将一个主题用作事件的签名。

## The log0 Primitive

最简单的日志原语是 `log0`​。这将创建一个只有数据但没有主题的日志项。日志的数据可以是任意字节数。

我们可以在 Solidity 中直接使用 `log0`​。在本例中，我们将存储一个 32 字节的数字：

```solidity
pragma solidity ^0.4.18;

contract Logger {
	function Logger() public {
		log0(0xc0fefe);
	}
}
```

生成的汇编可以分为两半。前半部分将日志数据（`0xc0fefe`​）从堆栈复制到内存中。后半部分将 `log0`​ 指令的参数放在堆栈上，告诉它在内存中加载数据的位置。

带注释的汇编：

```shell
memory: { 0x40 => 0x60 }

tag_1:
  // copy data into memory
  0xc0fefe
    [0xc0fefe]
  mload(0x40)
    [0x60 0xc0fefe]
  swap1
    [0xc0fefe 0x60]
  dup2
    [0x60 0xc0fefe 0x60]
  mstore
    [0x60]
    memory: {
      0x40 => 0x60
      0x60 => 0xc0fefe
    }

// calculate data start position and size
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

就在执行 `log0`​ 之前，堆栈上有两个参数：`[0x60 0x20]`​。

* `start`​：0x60 是内存中加载数据的位置。
* `size`​：0x20（或32）指定要加载的数据的字节数。

`log0`​ 的 go-ethereum 实现如下：

```go
func log0(pc *uint64, evm *EVM, contract *Contract, memory *Memory, stack *Stack) ([]byte, error) {
	mStart, mSize := stack.pop(), stack.pop()

	data := memory.Get(mStart.Int64(), mSize.Int64())

	evm.StateDB.AddLog(&types.Log{
		Address: contract.Address(),
		Data:    data,
		// This is a non-consensus field, but assigned here because
		// core/state doesn't know the current block number.
		BlockNumber: evm.BlockNumber.Uint64(),
	})

	evm.interpreter.intPool.put(mStart, mSize)
	return nil, nil
}
```

您可以在这段代码中看到 `log0`​ 从堆栈中弹出两个参数，然后从内存中复制数据。然后它调用 `StateDB.AddLog`​ 将日志与合约关联起来。

## Logging With Topics

主题是 32 字节的任意数据。以太坊实现将使用这些主题来索引日志，以实现高效的事件日志查询和过滤。

这个例子使用 `log2`​ 原语。第一个参数是数据（任意字节数），后跟 2 个主题（32 字节）：

```solidity
// log-2.sol
pragma solidity ^0.4.18;

contract Logger {
	function Logger() public {
		log2(0xc0fefe, 0xaaaa1111, 0xbbbb2222);
	}
}
```

汇编非常相似。唯一的区别是两个主题（`0xbbbb2222`​, `0xaaaa1111`​）在一开始就被压入堆栈：

```shell
tag_1:
  // push topics
  0xbbbb2222
  0xaaaa1111

// copy data into memory
  0xc0fefe
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

// create log
  log2
```

数据还是 `0xc0fefe`​，复制到内存。在执行 `log2`​ 之前，EVM 的状态如下所示：

```shell
stack: [0x60 0x20 0xaaaa1111 0xbbbb2222]
memory: {
  0x60: 0xc0fefe
}

log2
```

前两个参数指定用作日志数据的内存区域。两个额外的堆栈参数是两个 32 字节的主题。

## All EVM Logging Primitives

EVM 支持 5 个日志原语：

```shell
0xa0 LOG0
0xa1 LOG1
0xa2 LOG2
0xa3 LOG3
0xa4 LOG4
```

除了使用的主题数量外，它们都是相同的。 go-ethereum 实现实际上使用相同的代码生成这些指令，只是大小不同，它指定要从堆栈中弹出的主题数。

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
			// This is a non-consensus field, but assigned here because
			// core/state doesn't know the current block number.
			BlockNumber: evm.BlockNumber.Uint64(),
		})

		evm.interpreter.intPool.put(mStart, mSize)
		return nil, nil
	}
}
```

随意看一下 sourcegraph 上的代码：[https://sourcegraph.com/github.com/ethereum/go-ethereum@83d16574444d0b389755c9003e74a90d2ab7ca2e/-/blob/core/vm/instructions.go#L744](https://sourcegraph.com/github.com/ethereum/go-ethereum@83d16574444d0b389755c9003e74a90d2ab7ca2e/-/blob/core/vm/instructions.go#L744)

## Logging Testnet Demo

让我们尝试使用已部署的合约生成一些日志。合约记录 5 次，使用不同的数据和主题：

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

该合约部署在 Rinkeby 测试网络上。创建此合约的交易是：[https://rinkeby.etherscan.io/tx/0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1](https://rinkeby.etherscan.io/tx/0x0e88c5281bb38290ae2e9cd8588cd979bc92755605021e78550fbc4d130053d1)

单击“Event Logs”选项，您应该会看到 5 个日志项的原始数据。

主题都是 32 字节。我们记录为数据的数字被编码为 32 字节的数字。

## Querying For The Logs

让我们使用以太坊的 JSON RPC 来查询这些日志。以太坊 API 节点将创建索引，以便通过匹配主题来高效查找日志，或查找由合约地址生成的日志。

我们将使用 [infura.io](https://infura.io/) 提供的托管 RPC 节点。您可以通过注册免费帐户来获取 API 密钥。

获得密钥后，设置 shell 变量 `INFURA_KEY`​ 以使以下 curl 示例正常工作：

举个简单的例子，让我们调用 [eth_getLogs](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getlogs) 来获取与合约相关的所有日志：

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

* `fromBlock`​：从哪个块开始寻找日志。默认情况下，它开始查看区块链的顶端。我们想要所有的日志，所以我们从第一个块开始。
* `address`​：日志是通过合约地址来索引的，所以这实际上是非常有效的。

输出是 etherscan 为“Event Logs”选项显示的基础数据。查看完整输出：[evmlog.json](https://gist.github.com/hayeah/fbc862a87534bc45e77eddea9d779847)。

JSON API 返回的日志项如下所示：

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

接下来，我们可以查询匹配主题“0xc”的日志：

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

* `topics`​：要匹配的主题数组。`null`​ 匹配任何东西。见[详细说明](https://github.com/ethereum/wiki/wiki/JSON-RPC#parameters-38)。

应该有两个匹配的日志：

```json
{
    "address": "0x507e86b11541bcb1f3fe200b2f10ed8fd9413bd0",
    "topics": [
        "0x000000000000000000000000000000000000000000000000000000000000000a",
        "0x000000000000000000000000000000000000000000000000000000000000000b",
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

## Logging Gas Costs

日志原语的 gas 费用取决于您拥有多少主题以及您记录了多少数据：

```shell
// Per byte in a LOG operation's data
LogDataGas       uint64 = 8
// Per LOG 
topicLogTopicGas uint64 = 375   
// Per LOG operation.
LogGas           uint64 = 375
```

这些常量在 [protocol_params](https://github.com/ethereum/go-ethereum/blob/a139041d409d0ffaf81c7cf931c6b24299a05705/params/protocol_params.go#L25) 中定义。

不要忘记使用的内存，即每字节 3 gas：

```shell
MemoryGas        uint64 = 3  
```

等什么？每字节日志数据只花费 8 gas？也就是说 32 个字节需要 256 个 gas，内存使用需要 96 个 gas。因此，322 gas 与 20000 gas 存储相同数量的数据，成本仅为 1.7%！

但是等一下，如果你将日志数据作为 calldata 传递给交易，你也需要为交易数据付费。 calldata 的 gas 成本为：

```shell
TxDataZeroGas      uint64 = 4     // zero tx data abyte
TxDataNonZeroGas   uint64 = 68    // non-zero tx data byte
```

假设所有 32 个字节都不为零，这仍然比存储便宜很多：

```shell
// cost of 32 bytes of log data
32 * 68 = 2176 // tx data cost
32 * 8 = 256 // log data cost
32 * 3 = 96 // memory usage cost
375 // log call cost
----
total (2176 + 256 + 96 + 375)

~14% of sstore for 32 bytes
```

大部分 gas 费用实际上都花在了交易数据上，而不是日志操作本身。

日志操作便宜的原因是日志数据并没有真正存储在区块链中。原则上，日志可以根据需要即时重新计算。尤其是矿工，可以简单地丢弃日志数据，因为未来的计算无论如何都无法访问过去的日志。

整个网络不承担日志成本。只有 API 服务节点需要实际处理、存储和索引日志。

所以日志的成本结构只是防止日志垃圾邮件(spamming)的最小成本。

## Solidity Events

了解了日志原语是如何工作的，Solidity 事件就很简单了。

让我们看一下采用 3 个 uint256 参数（非索引）的 `Log`​ 事件类型：

```solidity
pragma solidity ^0.4.18;

contract Logger {
	event Log(uint256 a, uint256 b, uint256 c);
	function log(uint256 a, uint256 b, uint256 c) public {
		Log(a, b, c);
	}
}
```

与其查看汇编代码，不如查看生成的原始日志。

这是一个调用 `log(1, 2, 3)`​ 的交易：[https://rinkeby.etherscan.io/tx/0x9d3d394867330ae75d7153def724d062b474b0feb1f824fe1ff79e772393d395](https://rinkeby.etherscan.io/tx/0x9d3d394867330ae75d7153def724d062b474b0feb1f824fe1ff79e772393d395)

日志数据中的 data 是事件参数，ABI 编码：

```shell
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003
```

只有一个 topic，一个神秘的 32 字节哈希：

```shell
0x00032a912636b05d31af43f00b91359ddcfddebcffa7c15470a13ba1992e10f0
```

这是事件类型签名的 SHA3 哈希：

```shell
# Install pyethereum 
# https://github.com/ethereum/pyethereum/#installation
> from ethereum.utils import sha3
> sha3("Log(uint256,uint256,uint256)").hex()
'00032a912636b05d31af43f00b91359ddcfddebcffa7c15470a13ba1992e10f0'
```

这与方法调用的 ABI 编码的工作方式非常相似。

因为 Solidity 事件使用一个主题作为事件签名，所以索引参数只剩下 3 个主题。

## Solidity Event With Indexed Arguments

让我们看一个具有一个 indexed `uint256`​ 参数的事件：

```solidity
pragma solidity ^0.4.18;

contract Logger {
	event Log(uint256 a, uint256 indexed b, uint256 c);
	function log(uint256 a, uint256 b, uint256 c) public {
		Log(a, b, c);
	}
}
```

生成的事件日志中现在有两个 topic：

```shell
0x00032a912636b05d31af43f00b91359ddcfddebcffa7c15470a13ba1992e10f0
0x0000000000000000000000000000000000000000000000000000000000000002
```

* 第一个主题是事件类型签名，哈希后的。
* 第二个主题是索引参数，原值。

数据是 ABI 编码的事件参数，不包括索引参数(indexed parameters)：

```shell
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000003
```

## String/Bytes Event Parameter

现在让我们将事件参数更改为字符串：

```solidity
pragma solidity ^0.4.18;

contract Logger {
	event Log(string a, string indexed b, string c);
	function log(string a, string b, string c) public {
		Log(a, b, c);
	}
}
```

使用 `log("a", "b", "c")`​ 生成日志。交易是：[https://rinkeby.etherscan.io/tx/0x21221c2924bbf1860db9e098ab98b3fd7a5de24dd68bab1ea9ce19ae9c303b56](https://rinkeby.etherscan.io/tx/0x21221c2924bbf1860db9e098ab98b3fd7a5de24dd68bab1ea9ce19ae9c303b56)

有两个主题：

```shell
0xb857d3ea78d03217f929ae616bf22aea6a354b78e5027773679b7b4a6f66e86b
0xb5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510
```

* 第一个主题还是方法签名。
* 第二个主题是字符串参数的 sha256 摘要。

让我们验证“b”的哈希是否与第二个主题相同：

```shell
>>> sha3("b").hex()
'b5553de315e0edf504d9150af82dafa5c4667fa618ed0a6f19c69b41166c5510'
```

日志数据是 ABI 编码的两个非索引字符串“a”和“c”：

```shell
0000000000000000000000000000000000000000000000000000000000000040
0000000000000000000000000000000000000000000000000000000000000080
0000000000000000000000000000000000000000000000000000000000000001
6100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000001
6300000000000000000000000000000000000000000000000000000000000000
```

不幸的是，索引字符串参数的原始字符串没有存储（因为使用的是哈希），因此 DApp 客户端无法恢复它。

如果您真的需要原始字符串，只需记录两次，包括索引和非索引：

```shell
event Log(string a, string indexed indexedB, string b);

Log("a", "b", "b");
```

## Query For Logs Efficiently

我们如何找到第一个主题匹配“0x000…001”的所有日志？我们可以从创世块开始，重新执行每一笔交易，看看生成的日志是否符合我们的过滤条件。这不好。

事实证明，区块头(block header)包含了足够的信息，让我们可以快速跳过没有我们想要的日志的块。

区块头包括父哈希、叔父哈希币库(coin base)和用于该区块中包含的交易生成的所有日志的布隆过滤器等信息。看起来像：

```json
type Header struct {

    ParentHash  common.Hash    `json:"parentHash"       gencodec:"required"`

    UncleHash   common.Hash    `json:"sha3Uncles"       gencodec:"required"`

    Coinbase    common.Address `json:"miner"            gencodec:"required"`

    // ...

    // The Bloom filter composed from indexable information (logger address and log topics) contained in each log entry from the receipt of each transaction in the transactions list
    Bloom       Bloom          `json:"logsBloom"        gencodec:"required"`
}
```

[https://sourcegraph.com/github.com/ethereum/go-ethereum@479aa61f11724560c63a7b56084259552892819d/-/blob/core/types/block.go#L70:1](https://sourcegraph.com/github.com/ethereum/go-ethereum@479aa61f11724560c63a7b56084259552892819d/-/blob/core/types/block.go#L70:1)

布隆过滤器是一个固定的 256 字节数据结构。它的行为类似于 set，您可以询问它是否存在某个主题。

所以我们可以这样优化日志查询流程：

```shell
for block in chain:
    # check bloom filter to filter out a block quickly
    if not block.Bloom.exist(topic):
        next
    # block might have the log we want, re-execute
    for tx in block.transactions:
        for log in tx.recalculateLogs():
            if log.topic[0].matches(topic)
                yield log
```

除了主题之外，发出日志的合约地址也被添加到布隆过滤器中。

## BloomBitsTrie

以太坊主网在 2018 年 1 月有大约 5,000,000 个区块，迭代所有区块仍然非常昂贵，因为您需要从磁盘加载区块头。

平均块头约为 500 字节，您总共将加载 2.5GB 的数据。

[Felföldi Zsolt](https://github.com/zsfelfoldi) 在 [PR #14970](https://github.com/ethereum/go-ethereum/pull/14970) 中实现了 BloomBitsTrie，以使日志过滤更快。其思想是，与其单独查看每个块的布隆过滤器，不如设计一个同时查看 32768 个块的数据结构。

要理解接下来的内容，您需要了解的关于布隆过滤器的最少信息是，将一段数据“哈希”为布隆过滤器中的 3 个随机（但确定性）位并将它们设置为 1。为了检查是否存在，我们检查这 3 位是否设置为 1。

以太坊中使用的布隆过滤器是 2048 位。

假设主题“0xa”将布隆过滤器的第 16、632 和 777 位设置为 1。BloomBits Trie 是 2048 x 32768 位图(bitmap)。对 `BloomBits`​ 结构进行索引为我们提供了三个 32768 位向量：

```shell
BloomBits[15] => 32768 bit vector (4096 byte)
BloomBits[631] => 32768 bit vector (4096 byte)
BloomBits[776] => 32768 bit vector (4096 byte)
```

这些位向量告诉我们哪些块的布隆过滤器的第 16、632 和 777 位设置为 1。

让我们看看这些向量的前 8 位，可能看起来像

```shell
10110001...
00101101...
10101001...
```

* 第 1 个块的第 16 位和第 776 位设置为 1，但不是第 631 位。
* 第 3 个块设置了所有三个位。
* 第 8 个块设置了所有三个位。

然后我们可以通过对这些向量应用二进制与来快速找到匹配所有三个位的块：

```shell
00100001...
```

最后的位向量准确地告诉我们 32768 中哪些块符合我们的过滤条件。

为了匹配多个主题，我们只需对每个主题进行相同的索引，然后将最终的位向量二进制和。

有关其工作原理的更多详细信息，请参阅 [BloomBits Trie](https://github.com/zsfelfoldi/go-ethereum/wiki/BloomBits-Trie)。

## Conclusion

总的来说，一个 EVM 日志最多可以有 4 个主题，以及任意数量的字节作为数据。 Solidity 事件的非索引参数被 ABI 编码为数据，索引参数用作日志主题。

存储日志数据的 gas 成本比普通存储要便宜得多，因此只要您的合约不需要访问数据，您就可以将其视为 DApp 的替代方案。

日志设施的两种替代设计选择可能是：

* 允许更多数量的主题，尽管更多主题会降低用于按主题索引日志的布隆过滤器的有效性。
* 允许主题具有任意数量的字节。为什么不呢？