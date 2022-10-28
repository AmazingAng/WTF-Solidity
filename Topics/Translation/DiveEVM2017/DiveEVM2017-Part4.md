# 深入以太坊虚拟机 Part4 — 智能合约外部方法调用

> 原文：[How To Decipher A Smart Contract Method Call | by Howard | Sep 18, 2017](https://medium.com/@hayeah/how-to-decipher-a-smart-contract-method-call-8ee980311603)

在本系列的前几篇文章中，我们已经了解了 Solidity 如何表示 EVM 存储中的复杂数据结构。但是，如果无法与之交互，数据将毫无用处。智能合约是数据与外界之间的中介。

在本文中，我们将了解 Solidity 和 EVM 如何使外部程序能够调用合约的方法并导致其状态发生变化。

“外部程序”不限于 DApp/JavaScript。任何可以使用 HTTP RPC 与以太坊节点通信的程序都可以通过创建交易与部署在区块链上的任何合约进行交互。

创建一个交易就像发出一个 HTTP 请求。Web 服务器将接受您的 HTTP 请求并对数据库进行更改。交易会被网络接受，并且底层区块链扩展到包括状态变化。

交易之于智能合约就像 HTTP 请求之于 Web 服务一样。

如果对 EVM 汇编和 Solidity 数据表示不熟悉，请参阅本系列之前的文章以了解更多信息：

* [深入以太坊虚拟机 Part1 — 汇编与字节码](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)
* [深入以太坊虚拟机 Part2 — 固定长度数据类型的表示 ](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)
* [深入以太坊虚拟机 Part3 — 动态数据类型的表示](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)

## Contract Transaction

让我们看一个将状态变量设置为 `0x1`​ 的交易。我们要与之交互的合约具有变量 `a`​ 的 setter 和 getter：

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

该合约部署在测试网络 Rinkeby 上。随意使用地址 [0x62650ae5...](https://rinkeby.etherscan.io/address/0x62650ae5c5777d1660cc17fcd4f48f6a66b9a4c2) 的 Etherscan 检查它。

我创建了一个调用 `setA(1)`​ 的交易。在地址 [0x7db471e5...](https://rinkeby.etherscan.io/tx/0x7db471e5792bbf38dc784a5b983ee6a7bbe3f1db85dd4daede9ee88ed88057a5) 处检查此交易。

交易的输入数据为：

```shell
0xee919d500000000000000000000000000000000000000000000000000000000000000001
```

对于 EVM，这只是 36 字节的原始数据。它作为 `calldata`​ 未经处理传递给智能合约。如果智能合约是一个 Solidity 程序，那么它将这些输入字节解释为一个方法调用，并为 `setA(1)`​ 执行适当的汇编代码。

输入数据可以分解为两个子部分：

```shell
# The method selector (4 bytes)
0xee919d5
# The 1st argument (32 bytes)
00000000000000000000000000000000000000000000000000000000000000001
```

前四个字节是方法选择器(method selector)。其余的输入数据是 32 字节的块的方法参数。在这个例子中，只有 1 个参数，即值 `0x1`​。

方法选择器是方法签名的 kecccak256 哈希。在这个例子中，方法签名是 `setA(uint256)`​，它是方法的名称及其参数的类型。

让我们用 Python 计算方法选择器。首先，哈希方法签名：

```shell
# Install pyethereum https://github.com/ethereum/pyethereum/#installation
> from ethereum.utils import sha3
> sha3("setA(uint256)").hex()
'ee919d50445cd9f463621849366a537968fe1ce096894b0d0c001528383d4769'
```

然后取哈希的前 4 个字节：

```shell
> sha3("setA(uint256)")[0:8].hex()
'ee919d50'
```

> 注意：每个字节由 Python 十六进制字符串中的 2 个字符表示

## The Application Binary Interface (ABI)

就 EVM 而言，交易的输入数据（`calldata`​）只是一个字节序列。 EVM 没有对调用方法的内置支持。

智能合约可以选择通过结构化方式处理输入数据来模拟方法调用，如上一节所示。

如果 EVM 上的语言都同意如何解释输入数据，那么它们可以轻松地相互操作。[合约应用程序二进制接口](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI#formal-specification-of-the-encoding) (ABI) 指定了一个通用的编码方案。

我们已经看到了 ABI 如何编码像 `setA(1)`​ 这样的简单方法调用。在后面的部分中，我们将看到如何对具有更复杂参数的方法调用进行编码。

## Calling A Getter

如果你调用的方法改变了状态，那么整个网络都必须同意。这将需要交易，并且会花费你的 gas。

像 `getA()`​ 这样的 getter 方法不会改变任何东西。我们可以将方法调用发送到本地以太坊节点，而不是要求整个网络进行计算。`eth_call`​ RPC 请求允许您在本地模拟交易。这对于只读方法或 gas 费使用估计很有用。

`eth_call`​ 类似于缓存的 HTTP GET 请求。

* 它不会改变全球共识状态。
* 本地区块链（“缓存”）可能稍稍过时。

让我们使用 `eth_call`​ 来调用 `getA`​ 方法，得到状态 `a`​ 作为返回。首先，计算方法选择器：

```shell
>>> sha3("getA()")[0:8].hex()
'd46300fd'
```

由于没有参数，输入数据本身就是方法选择器。我们可以向任何以太坊节点发送 `eth_call`​ 请求。在本例中，我们将请求发送到 infura.io 托管的公共以太坊节点：

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

EVM 执行计算并返回原始字节作为结果：

```shell
{
"jsonrpc":"2.0",
"id":1,
        "result":"0x0000000000000000000000000000000000000000000000000000000000000001"
}
```

根据 ABI，字节应该被解释为值 `0x1`​。

## Assembly For External Method Calling

现在让我们看看编译后的合约如何处理原始输入数据以进行方法调用。考虑一个定义了 `setA(uint256)`​ 的合约：

```solidity
// call.sol
pragma solidity ^0.4.11;

contract C {
	uint256 a;

	// Note: `payable` makes the assembly a bit simpler
	function setA(uint256 _a) payable {
		a = _a;
	}
}
```

编译：

```shell
solc --bin --asm --optimize call.sol
```

被调用方法的汇编代码在合约主体中，组织在 `sub_0`​ 下：

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

有两段样板代码与本次讨论无关，但仅供参考(FYI)：

* 最顶部的 `mstore(0x40, 0x60)`​ 保留内存中的前 64 字节用于 sha3 哈希。无论合约是否需要，这始终存在。
* 最底部的 `auxdata`​ 用于验证发布的源代码与部署的字节码是否相同。这是可选的，但已包含在编译器中。

让我们将剩余的汇编代码分成两部分以便于分析：

1. 匹配选择器并跳转到方法。
2. 加载参数，执行方法，并从方法返回。

首先，用于匹配选择器的带注释汇编：

```shell
// Load the first 4 bytes as method selector
and(div(calldataload(0x0), 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)

// if selector matches `0xee919d50`, goto setA
0xee919d50
dup2
eq
tag_2
jumpi

// No matching method. Fail & revert.
tag_1:
  0x0
  dup1
  revert

// Body of setA
tag_2:
  ...
```

除了在开始时从 call data 中加载 4 个字节的 bit-shuffling 外，都很简单。为清楚起见，低级伪代码中的汇编逻辑如下：

```shell
methodSelector = calldata[0:4]

if methodSelector == "0xee919d50":
  goto tag_2 // goto setA
else:
  // No matching method. Fail & revert.
  revert
```

实际方法调用的注释汇编：

```shell
// setA
tag_2:
  // Where to goto after method call
  tag_3

  // Load first argument (the value 0x1).
  calldataload(0x4)

  // Execute method.
  jump(tag_4)
tag_4:
  // sstore(0x0, 0x1)
  0x0
  dup2
  swap1
  sstore
tag_5:
  pop
  // end of program, will goto tag_3 and stop
  jump
tag_3:
  // end of program
  stop
```

在进入方法部分之前，汇编做了两件事：

1. 保存方法调用后返回的位置。
2. 将 call data 中的参数加载到堆栈上。

在低级伪代码中：

```shell
// Saves the position to return to after method call.
@returnTo = tag_3

tag_2: // setA
  // Loads the arguments from call data onto the stack.
  @arg1 = calldata[4:4+32]
tag_4: // a = _a
  sstore(0x0, @arg1)
tag_5 // return
  jump(@returnTo)
tag_3:
  stop
```

将两个部分结合在一起：

```shell
methodSelector = calldata[0:4]

if methodSelector == "0xee919d50":
  goto tag_2 // goto setA
else:
  // No matching method. Fail.
  revert

@returnTo = tag_3
tag_2: // setA(uint256 _a)
  @arg1 = calldata[4:36]
tag_4: // a = _a
  sstore(0x0, @arg1)
tag_5 // return
  jump(@returnTo)
tag_3:
  stop
```

> Fun trivia：revert 的操作码是 `fd`​。但是您不会在黄皮书中找到它的规范，也不会在代码中找到它的实现。事实上，`fd`​ 并不真实存在！这是一个无效的操作。当 EVM 遇到无效操作时，它会放弃并恢复状态作为副作用 (revert state as a side-effect)。

## Handling Multiple Methods

Solidity 编译器如何为具有多种方法的合约生成汇编代码？

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

简单。只是一个接一个的更多的 `if-else`​ 分支：

```shell
// methodSelector = calldata[0:4]
and(div(calldataload(0x0), 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)

// if methodSelector == 0x9cdcf9b
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

在伪代码中：

```shell
methodSelector = calldata[0:4]

if methodSelector == "0x9cdcf9b":
  goto tag_2
elsif methodSelector == "0xee919d50":
  goto tag_3
else:
  // Cannot find a matching method. Fail.
  revert
```

## ABI Encoding For Complex Method Calls

对于方法调用，交易输入数据的前四个字节始终是方法选择器。然后方法参数以 32 字节为单位跟在后面。 [ABI 编码规范](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) 详细说明了如何对更复杂类型的参数进行编码，但阅读起来可能会非常痛苦。

学习 ABI 编码的另一个策略是使用 [pyethereum 的 ABI 编码函数](https://github.com/ethereum/pyethereum/blob/4e945e2a24554ec04eccb160cff689a82eed7e0d/ethereum/abi.py) 来研究不同类型的数据是如何编码的。我们将从简单的案例开始，然后构建更复杂的类型。

首先，导入 `encode_abi`​ 函数：

```python
from ethereum.abi import encode_abi
```

对于具有三个 uint256 参数的方法（例如 `foo(uint256 a, uint256 b, uint256 c)`​），编码参数只是一个接一个的 uint256 数字：

```shell
# The first array lists the types of the arguments.
# The second array lists the argument values.
> encode_abi(["uint256", "uint256", "uint256"],[1, 2, 3]).hex()
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003
```

小于 32 字节的类型被填充到 32 字节：

```shell
> encode_abi(["int8", "uint32", "uint64"],[1, 2, 3]).hex()
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003
```

对于固定大小的数组，元素也是 32 字节的块（必要时填充零），一个接一个地放置：

```shell
> encode_abi(
   ["int8[3]", "int256[3]"],
   [[1, 2, 3], [4, 5, 6]]
).hex()

// int8[3]. Zero-padded to 32 bytes.
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003

// int256[3].
0000000000000000000000000000000000000000000000000000000000000004
0000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000000006
```

## ABI Encoding for Dynamic Arrays

ABI 引入了一个间接层(layer of indirection)来编码动态数组，遵循称为 [头尾编码(head-tail encoding)](https://github.com/ethereum/pyethereum/blob/4e945e2a24554ec04eccb160cff689a82eed7e0d/ethereum/abi.py#L735-L741) 的方案。

这个思想是动态数组的元素被打包在交易 calldata 的尾部。参数（“head”）是对数组元素所在的 calldata 的引用。

如果我们调用具有 3 个动态数组的方法，则参数编码如下（为清楚起见添加了注释和换行符）：

```shell
> encode_abi(
  ["uint256[]", "uint256[]", "uint256[]"],
  [[0xa1, 0xa2, 0xa3], [0xb1, 0xb2, 0xb3], [0xc1, 0xc2, 0xc3]]
).hex()

/************* HEAD (32*3 bytes) *************/
// arg1: look at position 0x60 for array data
0000000000000000000000000000000000000000000000000000000000000060
// arg2: look at position 0xe0 for array data
00000000000000000000000000000000000000000000000000000000000000e0
// arg3: look at position 0x160 for array data
0000000000000000000000000000000000000000000000000000000000000160

/************* TAIL (128**3 bytes) *************/
// position 0x60. Data for arg1.
// Length followed by elements.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000a1
00000000000000000000000000000000000000000000000000000000000000a2
00000000000000000000000000000000000000000000000000000000000000a3

// position 0xe0. Data for arg2.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000b1
00000000000000000000000000000000000000000000000000000000000000b2
00000000000000000000000000000000000000000000000000000000000000b3

// position 0x160. Data for arg3.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000c1
00000000000000000000000000000000000000000000000000000000000000c2
00000000000000000000000000000000000000000000000000000000000000c3
```

所以 `head`​ 有三个 32 字节的参数，指向尾部的位置，尾部包含三个动态数组的实际数据。

例如，第一个参数是 `0x60`​，指向 calldata 的第 96（`0x60`​）个字节。如果查看第 96 个字节，它是数组的开头。前 32 个字节是长度，后跟三个元素。

可以混合使用动态和静态参数。这是一个带有（`static`​、`dynamic`​、`static`​）参数的示例。静态参数按原样编码，而第二个动态数组的数据放在尾部：

```shell
> encode_abi(
  ["uint256", "uint256[]", "uint256"],
  [0xaaaa, [0xb1, 0xb2, 0xb3], 0xbbbb]
).hex()

/************* HEAD (32*3 bytes) *************/
// arg1: 0xaaaa
000000000000000000000000000000000000000000000000000000000000aaaa
// arg2: look at position 0x60 for array data
0000000000000000000000000000000000000000000000000000000000000060
// arg3: 0xbbbb
000000000000000000000000000000000000000000000000000000000000bbbb

/************* TAIL (128 bytes) *************/
// position 0x60. Data for arg2.
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000b1
00000000000000000000000000000000000000000000000000000000000000b2
00000000000000000000000000000000000000000000000000000000000000b3
```

有很多零，但没关系。

## Encoding Bytes

字符串和字节数组也是头尾编码的。唯一的区别是字节被紧密地打包成 32 个字节的块，如下所示：

```shell
> encode_abi(
  ["string", "string", "string"],
  ["aaaa", "bbbb", "cccc"]
).hex()

// arg1: look at position 0x60 for string data
0000000000000000000000000000000000000000000000000000000000000060
// arg2: look at position 0xa0 for string data
00000000000000000000000000000000000000000000000000000000000000a0
// arg3: look at position 0xe0 for string data
00000000000000000000000000000000000000000000000000000000000000e0

// 0x60 (96). Data for arg1
0000000000000000000000000000000000000000000000000000000000000004
6161616100000000000000000000000000000000000000000000000000000000

// 0xa0 (160). Data for arg2
0000000000000000000000000000000000000000000000000000000000000004
6262626200000000000000000000000000000000000000000000000000000000

// 0xe0 (224). Data for arg3
0000000000000000000000000000000000000000000000000000000000000004
6363636300000000000000000000000000000000000000000000000000000000
```

对于每个字符串/字节数组，前 32 个字节编码了长度，紧跟着是字节。

如果字符串大于 32 字节，则使用多个 32 字节块：

```shell
// encode 48 bytes of string data
ethereum.abi.encode_abi(
  ["string"],
  ["a" * (32+16)]
).hex()

0000000000000000000000000000000000000000000000000000000000000020

// length of string is 0x30 (48)
0000000000000000000000000000000000000000000000000000000000000030
6161616161616161616161616161616161616161616161616161616161616161
6161616161616161616161616161616100000000000000000000000000000000
```

## Nested Arrays

嵌套数组的每个嵌套都有一个间接寻址。

```shell
> encode_abi(
  ["uint256[][]"],
  [[[0xa1, 0xa2, 0xa3], [0xb1, 0xb2, 0xb3], [0xc1, 0xc2, 0xc3]]]
).hex()

// arg1: The outter array is at position 0x20.
0000000000000000000000000000000000000000000000000000000000000020

// 0x20. Each element is the position of an inner array.
0000000000000000000000000000000000000000000000000000000000000003
0000000000000000000000000000000000000000000000000000000000000060
00000000000000000000000000000000000000000000000000000000000000e0
0000000000000000000000000000000000000000000000000000000000000160

// array[0] at 0x60
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000a1
00000000000000000000000000000000000000000000000000000000000000a2
00000000000000000000000000000000000000000000000000000000000000a3

// array[1] at 0xe0
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000b1
00000000000000000000000000000000000000000000000000000000000000b2
00000000000000000000000000000000000000000000000000000000000000b3

// array[2] at 0x160
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000c1
00000000000000000000000000000000000000000000000000000000000000c2
00000000000000000000000000000000000000000000000000000000000000c3
```

是的，有很多零。

## Gas Cost & ABI Encoding Design

为什么 ABI 将方法选择器截断为仅 4 个字节？如果我们不使用 sha256 的全部 32 个字节，不同的方法是否会发生不幸的冲突？如果截断是为了节省成本，那么如果使用零填充浪费了更多字节，为什么还要在方法选择器中节省 28 个字节呢？

这两种设计选择似乎是矛盾的……直到我们考虑交易的 gas 费用。

* 每笔交易支付 21000。
* 交易的每个零字节数据或代码需要支付 4。
* 交易的每个非零字节数据或代码需要支付 68。

零值便宜 17 倍，因此零填充并不像看起来那么糟糕。

方法选择器是一个加密哈希，它是伪随机的。随机字符串往往具有大部分非零字节，因为每个字节只有 0.3% (1/255) 的机会为 0。

* `0x1`​ 填充到 32 字节需要 192 gas。（4 * 31 + 68）
* sha256 可能有 32 个非零字节，这大约需要 2176 gas。（32 * 68）
* sha256 被截断为 4 个字节将花费大约 272 gas。（32 * 4）

ABI 展示了另一个受 gas 费用结构激励的古怪低级设计示例。

## Negative Integers...

负整数通常使用称为[二进制补码](https://en.wikipedia.org/wiki/Two%27s_complement)的方案表示。 int8 编码类型的值 `-1`​ 将全部为 1 `1111 1111`​。

ABI 用 1 填充负整数，因此 `-1`​ 将被填充为：

```shell
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
```

小的负数大部分是 1，这会花费你很多 gas。

¯_(ツ)_/¯

## Conclusion

要与智能合约交互，您需要向其发送原始字节。它会进行一些计算，可能会改变自己的状态，然后向您发送原始字节作为返回。方法调用实际上并不存在。这是 ABI 创造的集体幻觉(collective illusion)。

ABI 被指定为低级格式，但在功能上它更像是跨语言 RPC 框架的序列化格式。

我们可以在 DApp 和 Web App 的架构层之间进行类比：

* 区块链就像背后的数据库。
* 合约就像一个网络服务。
* 交易就像一个请求。
* ABI 是数据交换格式，类似于[协议缓冲区](https://en.wikipedia.org/wiki/Protocol_Buffers)。