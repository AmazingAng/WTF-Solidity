# 深入以太坊虚拟机系列

**原文**：
- [Diving Into The Ethereum Virtual Machine](https://medium.com/@hayeah/diving-into-the-ethereum-vm-6e8d5d2f3c30)
- [Diving Into The Ethereum VM Part 2 — How I Learned To Start Worrying And Count The Storage Cost](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-2-storage-layout-bc5349cb11b7)
- [Diving Into The Ethereum VM Part 3 — The Hidden Costs of Arrays](https://medium.com/@hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b)
- [Diving Into The Ethereum VM Part 4 — How To Decipher A Smart Contract Method Call](https://medium.com/@hayeah/how-to-decipher-a-smart-contract-method-call-8ee980311603)
- [Diving Into The Ethereum VM Part 5 — The Smart Contract Creation Process](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-5-the-smart-contract-creation-process-cb7b6133b855)
- [Diving Into The Ethereum VM Part 6 — How Solidity Events Are Implemented](https://blog.qtum.org/how-solidity-events-are-implemented-diving-into-the-ethereum-vm-part-6-30e07b3037b9)

**原文作者**：[Howard](https://twitter.com/hayeah)

**翻译**：[alphafitz](https://twitter.com/alphafitz01)

> 写在前面：这是作者 [Howard](https://twitter.com/hayeah) 在 2017 年开始写的一系列文章，当时使用的编译器版本还是 0.4.x，但是其描述的以太坊虚拟机(EVM)的基本工作原理仍然适用并且十分值得学习，帮助我更好地理解了 EVM，故在此将其翻译为中文版。
> 
> 本文中给出的源代码及汇编代码仍然沿用原文内容，涉及到的版本不一致的问题请执行查阅学习。本人尽最大可能保证翻译通顺准确，但大家如果发现错误可以直接提交 pr。
>
>By alphafitz

# 深入以太坊虚拟机 Part1 — 汇编与字节码

Solidity 提供了许多高级语言抽象，但是这些特性使得人们很难理解程序运行时到底发生了什么。阅读 Solidity 文档仍然使我对非常基本的事情感到困惑。

`string`，`bytes32`，`byte[]`，`bytes` 有什么区别？

* 我该使用哪一个？何时使用？
* 当我把 `string` 转换为 `bytes` 时会发生什么？能转换为 `byte[]` 吗？
* 它们费用是多少？

EVM 中如何存储映射(*mapping*)？

* 为什么不能删除一个映射？
* 可以使用映射的映射吗？（可以，但它是如何工作的？）
* 为什么有存储映射(*storage mapping*)但没有内存映射(*memory mapping*)？

编译后的合约对 EVM 来说是怎样的？

* 合约是如何创建的？
* 什么是 `constructor`​？真的吗？
* 什么是 `fallback` 函数？

我认为学习像 Solidity 这样的高级语言如何在以太坊 VM(EVM) 上运行是一项很好的投资。出于几个原因。

1. **Solidity 不是最后的语言**​。更好的 EVM 语言将会到来。
2. **EVM 是一个数据库引擎**。要了解智能合约如何以任何一门 EVM 语言工作，必须理解数据是如何组织、存储和操纵的。
3. **知道如何成为贡献者**。以太坊工具链还很早。深入了解 EVM 将会帮助您为自己和他人制作出色的工具。
4. **智力挑战**。EVM 为在密码学、数据结构和编程语言设计的交叉点上发挥作用提供了一个很好的机会。

在一系列文章中，我想解构简单的 Solidity 合约，以了解它是如何作为 EVM 字节码工作的。

希望学习和写的内容的大纲：

* EVM 字节码的基础知识
* 如何表示不同的类型（映射(*mapping*)、数组(*array*)）
* 创建新合约时发生了什么
* 方法被调用时发生了什么
* ABI 如何桥接不同的 EVM 语言

我的最终目标是能够完整地理解编译好的 Solidity 合约。让我们从阅读一些基本的 EVM 字节码开始吧！

这个 [EVM 指令集](https://gist.github.com/hayeah/bd37a123c02fecffbe629bf98a8391df) 将是一个有用的参考。

## A Simple Contract

我们的第一个合约有一个构造函数和一个状态变量：

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

（注：当前 Solidity 已使用 `constructor` 关键字声明构造函数）

用 `solc` 编译这个合约：

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

数字 `6060604052...` 是 EVM 实际运行的字节码。

## In Baby Steps

编译后的汇编语言中一半是样板(boilerplate)，在大多数 Solidity 程序中都是相似的。我们稍后会来回顾。现在，让我们检查一下合约的独特部分，即不起眼的存储变量赋值：

```shell
a = 1
```

此赋值由字节码 `6001600081905550`表示。让我们将其分解为每行一条指令：

```shell
60 01
60 00
81
90
55
50
```

EVM 基本上是一个循环，从上到下执行每条指令。让我们用相应的字节码注释汇编代码（在标签 `tag_2` 下缩进）以更好地了解它们是如何关联的：

```shell
tag_2:
  // 60 01
  0x1
  // 60 00
  0x0
  // 81
  dup2
  // 90
  swap1
  // 55
  sstore
  // 50
  pop
```

请注意，汇编代码中的 `0x1` 实际上是 `push(0x1)` 的简写。该指令将数字 1 压入堆栈。

只是盯着它仍然很难理解发生了什么。不过不用担心，逐行模拟 EVM 很简单。

## Simulating The EVM

EVM 是一个堆栈机器(stack machine)。指令可能使用堆栈上的值作为参数，并将值作为结果压入堆栈。让我们考虑 `add` 操作。

假设堆栈上有两个值：

```shell
[1, 2]
```

当 EVM 看到 `add` 时，它将顶端的 2 个项加起来，并将结果 push 到堆栈顶端，结果就是：

```shell
[3]
```

在下文中，我们将使用 `[]` 标记堆栈：

```shell
// 空堆栈
stack: []
// 有 3 个项的堆栈。顶端是 3，底部是 1。
stack: [3 2 1]
```

并使用 `{}` 标注合约存储：

```shell
// 存储中什么都没有
store: {}
// 值 0x1 存储在位置 0x0
store: { 0x0 => 0x1 }
```

现在让我们看一些真正的字节码。我们将像 EVM 一样模拟字节码序列 `6001600081905550` 并在每条指令之后打印机器状态：

```shell
// 60 01: 将 1 压入堆栈
0x1
  stack: [0x1]
// 60 00: 将 0 压入堆栈
0x0
  stack: [0x0 0x1]
// 81: 复制堆栈上的第 2 个项
dup2
  stack: [0x1 0x0 0x1]
// 90: 交换顶端的 2 个项
swap1
  stack: [0x0 0x1 0x1]
// 55: 存储值 0x1 到位置 0x0
// 该指令消耗了顶端 2 个项
sstore
  stack: [0x1]
  store: { 0x0 => 0x1 }
// 50: pop (弹出顶端项)
pop
  stack: []
  store: { 0x0 => 0x1 }
```

结束。堆栈是空的，并且有一个项在存储中。

值得注意的是，Solidity 决定将状态变量 `uint256 a` 存储在位置 `0x0`。其他语言完全有可能选择将状态变量存储在其他地方。

在伪代码中，EVM 对 `6001600081905550` 所做的基本上是：

```shell
// a = 1
sstore(0x0, 0x1)
```

仔细看，你会发现 dup2, swap1, pop 都是多余的。汇编代码可以更简单。

```shell
0x1
0x0
sstore
```

你可以尝试模拟上面 3 条指令，并确信它们确实会导致相同的机器状态：

```shell
stack: []
store: { 0x0 => 0x1 }
```

## Two Storage Variables

让我们添加一个相同类型的额外存储变量：

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

编译，重点关注 `tag_2`：

```shell
$ solc --bin --asm c2.sol
// ... more stuff omitted
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

伪代码形式的汇编：

```shell
// a = 1
sstore(0x0, 0x1)
// b = 2
sstore(0x1, 0x2)
```

我们在这里了解到的是，两个存储变量一个接一个地定位，`a` 位于 `0x0` 位置，`b` 位于 `0x1` 位置。

## Storage Packing

每个槽存储(slot storage)可以存储 32 个字节。如果一个变量只需要 16 个字节，那么使用所有 32 个字节是很浪费的。如果可能，Solidity 通过将两种更小的数据类型打包(pack)到一个存储槽中来优化存储效率。

让我们改变 `a` 和 `b`，使它们每个都只有 16 个字节：

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

编译合约：

```shell
$ solc --bin --asm c3.sol
```

生成的汇编更加复杂：

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

上面的汇编代码将两个变量打包到一个存储位置(`0x0`)，就像这样：

```shell
[         b         ][         a         ]
[16 bytes / 128 bits][16 bytes / 128 bits]
```

打包的原因是因为到目前为止最昂贵的操作是存储：

* `sstore` 首次写入新位置需要 20000 gas
* `sstore` 需要 5000 gas 用于后续写入已有位置
* `sload` 花费 500 gas
* 大多数指令花费 3~10 gas

通过使用相同的存储位置，Solidity 为第二个存储变量支付 5000 而不是 20000，从而为我们节省了 15000 gas。

## More Optimization

与其用两个单独的 `sstore` 指令存储 `a` 和 `b`，不如将两个 128 位数字一起打包到内存中，然后只使用一个 `sstore` 存储它们，从而节省额外的 5000 gas。

您可以通过打开 `optimize` 标志让 Solidity 进行此优化：

```shell
$ solc --bin --asm --optimize c3.sol
```

生成的汇编代码只使用一个 `sload` 和一个 `sstore`：

```shell
tag_2:
    /* "c3.sol":95:96  a */
  0x0
    /* "c3.sol":95:100  a = 1 */
  dup1
  sload
    /* "c3.sol":108:113  b = 2 */
  0x200000000000000000000000000000000
  not(sub(exp(0x2, 0x80), 0x1))
    /* "c3.sol":95:100  a = 1 */
  swap1
  swap2
  and
    /* "c3.sol":99:100  1 */
  0x1
    /* "c3.sol":95:100  a = 1 */
  or
  sub(exp(0x2, 0x80), 0x1)
    /* "c3.sol":108:113  b = 2 */
  and
  or
  swap1
  sstore
```

字节码是：

```shell
600080547002000000000000000000000000000000006001608060020a03199091166001176001608060020a0316179055
```

将字节码格式化为每行一条指令：

```shell
// push 0x0
60 00
// dup1
80
// sload
54
// push17 push the the next 17 bytes as a 32 bytes number
70 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

/* not(sub(exp(0x2, 0x80), 0x1)) */
// push 0x1
60 01
// push 0x80 (32)
60 80
// push 0x80 (2)
60 02
// exp
0a
// sub
03
// not
19

// swap1
90
// swap2
91
// and
16
// push 0x1
60 01
// or
17

/* sub(exp(0x2, 0x80), 0x1) */
// push 0x1
60 01
// push 0x80
60 80
// push 0x02
60 02
// exp
0a
// sub
03

// and
16
// or
17
// swap1
90
// sstore
55
```

汇编代码中使用了四个魔法值(magic values)：

* 0x1 (16 字节)，使用低 16 字节

```shell
// 用字节码表示为 0x01
16:32 0x00000000000000000000000000000000
00:16 0x00000000000000000000000000000001
```

* 0x2 (16 字节)，使用更高的 16 字节

```shell
// 用字节码表示为 0x200000000000000000000000000000000
16:32 0x00000000000000000000000000000002
00:16 0x00000000000000000000000000000000
```

* `not(sub(exp(0x2, 0x80), 0x1))`​

```shell
// 高 16 字节的位掩码
16:32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
00:16 0x00000000000000000000000000000000
```

* `sub(exp(0x2, 0x80), 0x1)`​

```shell
// 低 16 字节的位掩码
16:32 0x00000000000000000000000000000000 
00:16 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
```

该代码对这些值进行了一些位操作以达到所需的结果：

```shell
16:32 0x00000000000000000000000000000002 
00:16 0x00000000000000000000000000000001
```

最后，这个 32 字节的值存储在位置 `0x0`。

## Gas Usage

```shell
600080547002000000000000000000000000000000006001608060020a03199091166001176001608060020a0316179055
```

注意，字节码中嵌入了 `0x200000000000000000000000000000000`。但编译器也可以选择使用指令 `exp(0x2, 0x81)`来计算值，这会产生更短的字节码序列。

但事实证明，`0x200000000000000000000000000000000` 比 `exp(0x2, 0x81)` 更便宜。让我们看一下所涉及的 gas 费用：

* 为交易的每个零字节数据或代码支付 4 gas
* 交易的每个非零字节数据或代码需要 68 gas

让我们比较一下两种表示在 gas 中的成本。

* 字节码 `0x200000000000000000000000000000000` 有很多 0，很便宜：(1 \* 68) + ( 16 \* 4) = 196
* 字节码 `608160020a` 更短但没有 0：5 \* 68 = 340

具有更多零的较长序列实际上更便宜！

## Summary

EVM 编译器并未针对字节码大小或速度或内存效率进行精确优化。相反，它优化了 gas 使用，这是一层间接(indirection)以激励以太坊区块链可以有效进行的计算。

我们已经看到了 EVM 的一些古怪方面：

* EVM 是一个 256 位的机器。以 32 字节为单位处理数据是最自然的做法。
* 持久性存储非常昂贵。
* Solidity 编译器做出了有趣的选择，以尽量减少 gas 使用。

Gas 成本的设定有些武断，未来很可能会发生变化。随着成本的变化，编译器会做出不同的选择。

# 深入以太坊虚拟机 Part2 — 固定长度数据类型的表示

在本系列的第一篇文章中，我们了解了一个简单的 Solidity 合约的汇编代码：

```solidity
contract C {
	uint256 a;

	function C() {
		a = 1;
	}
}
```

该合约归结为调用 `sstore`​ 指令：

```shell
// a = 1
sstore(0x0, 0x1)
```

* EVM 将值 `0x1` 存储在存储(storage)位置 `0x0`​
* 每个存储位置可以存储 32 个字节（或 256 位）

在本文中，我们将开始研究 Solidity 如何使用 32 字节的块(chunks)来表示更复杂的数据类型，比如结构体和数组。我们还将了解如何优化存储，以及优化是如何失败的。

在典型的编程语言中，理解数据类型如何在如此低的级别表示并不是非常有用。在 Solidity（或任何 EVM 语言）中，这些知识至关重要，因为访问存储非常昂贵：

* `sstore` 花费 20000 gas，或比基本算术指令贵约 5000 倍
* `sload` 需要 200 gas，或比基本算术指令贵 100 倍

通过“成本”，我们在这里谈论的是 real money，而不仅仅是毫秒级的性能。运行和使用合约的成本很可能由 `sstore` 和 `sload` 主导！

## Parsecs Upon Parsecs of Tape

构建通用计算机需要两个基本要素：

1. 一种循环的方式，跳转(jump)或递归(recursion)
2. 无限的内存数量

EVM 汇编代码有跳转，EVM 存储提供无线内存。这对一切都足够了，包括模拟一个运行以太坊版本的世界，它本身也在模拟一个运行以太坊的世界，即...

合约的 EVM 存储就像一个无限的收报机磁带，磁带的每个插槽(slot)都保存 32 个字节。就像这样：

```shell
[32 bytes][32 bytes][32 bytes]...
```

我们将看到数据如何存在于无限磁带上。

> 磁带的长度为 $2^{256}$(32 字节)，或每个合约约 $10^{77}$(和 $2^{256}$ 同量级) 个存储槽。可观测宇宙的粒子数为 $10^{80}$。大约 1000 份合约足以容纳所有这些质子、中子和电子。不要相信营销炒作，因为它比无穷大要短得多。

## The Blank Tape

存储最初是空白的，默认为 0。拥有无限磁带不会花费您任何费用。

让我们看一个简单的合约来说明零值行为：

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

存储布局很简单。

* 变量 `a` 在位置 `0x0`​
* 变量 `b` 在位置 `0x1`​
* 依此类推...

关键问题：如果我们只使用 `f`，我们要为 a、b、c、d、e 支付多少费用？

让我们编译看看：

```shell
$ solc --bin --asm --optimize c-many-variables.sol
```

汇编为：

```shell
// sstore(0x5, 0xc0fefe)
tag_2:
  0xc0fefe
  0x5
  sstore
```

因此，存储变量声明不需要任何费用，因为不需要初始化。 Solidity 为该存储变量保留了一个位置，并且您只有在其中存储某些内容时才需要支付费用。

在这种情况下，我们只需支付存储到 `0x5` 的费用。

如果我们手动编写汇编，我们可以选择任何存储位置而无需“扩展”存储：

```shell
// Writing to an arbitrary position
sstore(0xc0fefe, 0x42)
```

## Reading Zero

您不仅可以在存储中的任何位置写入，还可以立即从任何位置读取。从未初始化的位置读取只会返回 `0x0`。

让我们看一个从 `a` 读取的合约，一个未初始化的位置：

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

编译：

```shell
$ solc --bin --asm --optimize c-zero-value.sol
```

汇编：

```shell
tag_2:
  // sload(0x0) returning 0x0
  0x0
  dup1
  sload

  // a + 1; where a == 0
  0x1
  add

  // sstore(0x0, a + 1)
  swap1
  sstore
```

请注意，生成从未初始化位置 `sload` 的代码是有效的。

然而，我们可以比 Solidity 编译器更聪明。由于我们知道 `tag_2` 是构造函数，并且 `a` 从未被写入，我们可以将 `sload` 序列替换为 `0x0` 以节省 5000 gas。

## Representing Struct

让我们看看我们的第一个复杂数据类型，一个有 6 个字段的结构体：

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

存储中的布局与状态变量相同：

* 字段 `t.a` 在位置 `0x0`​
* 字段 `t.b` 在位置 `0x1`​
* 依此类推...

和前面一样，我们可以直接写入 `t.f` 而不需要初始化。

编译：

```shell
$ solc --bin --asm --optimize c-struct-fields.sol
```

我们可以看到完全相同的汇编：

```shell
tag_2:
  0xc0fefe
  0x5
  sstore
```

## Fixed Length Array

现在我们声明一个固定长度的数组：

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

由于编译器确切地知道有多少 uint256（32 字节），它可以简单地将数组的元素一个接一个地放置在存储中，就像它对存储变量和结构体所做的那样。

在这个合约中，我们再次存储到位置 `0x5`。

编译：

```shell
$ solc --bin --asm --optimize c-static-array.sol
```

汇编：

```shell
tag_2:
  0xc0fefe
  0x0
  0x5
tag_4:
  add
  0x0
tag_5:
  pop
  sstore
```

它稍微长一点，但如果你仔细看，你会发现它实际上是一样的。让我们手动进一步优化：

```shell
tag_2:
  0xc0fefe

  // 0+5. Replace with 0x5
  0x0
  0x5
  add

  // Push then pop immediately. Useless, just remove.
  0x0
  pop

  sstore
```

去除标签和虚假指令，我们再次得到相同的字节码序列：

```shell
tag_2:
  0xc0fefe
  0x5
  sstore
```

## Array Bound Checking

我们已经看到，定长数组与 struct 和 状态变量具有相同的存储布局，但生成的汇编代码不同。原因是 Solidity 为数组访问生成边界检查。

让我们再次编译数组合约，这次关闭优化：

```shell
$ solc --bin --asm c-static-array.sol
```

汇编代码在下面给出注释，在每条指令后打印机器状态：

```shell
tag_2:
  0xc0fefe
    [0xc0fefe]
  0x5
    [0x5 0xc0fefe]
  dup1

  /* array bound checking code */
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
    // Test condition is true. Will goto tag_5.
    // And `jumpi` consumes two items from stack.
    [0x5 0xc0fefe]
  invalid

// Array access is valid. Do it.
// stack: [0x5 0xc0fefe]
tag_5:
  sstore
    []
    storage: { 0x5 => 0xc0fefe }
```

我们现在看到了边界检查代码。我们已经看到编译器能够优化其中的一些东西，但并不完美。

在本文后面，我们将看到数组边界检查如何干扰编译器优化，从而使固定长度数组的效率远低于存储变量或结构体。

## Packing Behaviour

存储很昂贵（yayaya，我已经说过一百万次了）。一项关键优化是将尽可能多的数据打包到一个 32 字节的存储槽中。

考虑一个有四个存储变量的合约，每个变量 64 位，加起来共 256 位（32 字节）：

```solidity
// c-many-variables--packing.sol
pragma solidity ^0.4.11;

contract C {
	uint64 a;
	uint64 b;
	uint64 c;
	uint64 d;

	function C() {
		a = 0xaaaa;
		b = 0xbbbb;
		c = 0xcccc;
		d = 0xdddd;
	}
}
```

我们希望编译器使用一个 `sstore` 将它们放在同一个存储槽中。

编译：

```shell
$ solc --bin --asm --optimize c-many-variables--packing.sol
```

汇编：

```shell
tag_2:
    /* "c-many-variables--packing.sol":121:122  a */
  0x0
    /* "c-many-variables--packing.sol":121:131  a = 0xaaaa */
  dup1
  sload
    /* "c-many-variables--packing.sol":125:131  0xaaaa */
  0xaaaa
  not(0xffffffffffffffff)
    /* "c-many-variables--packing.sol":121:131  a = 0xaaaa */
  swap1
  swap2
  and
  or
  not(sub(exp(0x2, 0x80), exp(0x2, 0x40)))
    /* "c-many-variables--packing.sol":139:149  b = 0xbbbb */
  and
  0xbbbb0000000000000000
  or
  not(sub(exp(0x2, 0xc0), exp(0x2, 0x80)))
    /* "c-many-variables--packing.sol":157:167  c = 0xcccc */
  and
  0xcccc00000000000000000000000000000000
  or
  sub(exp(0x2, 0xc0), 0x1)
    /* "c-many-variables--packing.sol":175:185  d = 0xdddd */
  and
  0xdddd000000000000000000000000000000000000000000000000
  or
  swap1
  sstore
```

有很多我无法破解的位运算，我不关心。需要注意的关键是这里只有一个 `sstore`。

优化成功！

## Breaking The Optimizer

要是优化器能一直工作得这么好就好了。让我们打破它。我们所做的唯一改变是我们使用辅助函数来设置存储变量：

```solidity
// c-many-variables--packing-helpers.sol
pragma solidity ^0.4.11;

contract C {
	uint64 a;
	uint64 b;
	uint64 c;
	uint64 d;

	function C() {
		setAB();
		setCD();
	}

	function setAB() internal {
		a = 0xaaaa;
		b = 0xbbbb;
	}

	function setCD() internal {
		c = 0xcccc;
		d = 0xdddd;
	}
}
```

编译：

```shell
$ solc --bin --asm --optimize c-many-variables--packing-helpers.sol
```

汇编输出太多。我们将忽略大部分细节并专注于结构：

```shell
// Constructor function
tag_2:
  // ...
  // call setAB() by jumping to tag_5
  jump
tag_4:
  // ...
  // call setCD() by jumping to tag_7
  jump

// function setAB()
tag_5:
  // Bit-shuffle and set a, b
  // ...
  sstore
tag_9:
  jump  // return to caller of setAB()

// function setCD()
tag_7:
  // Bit-shuffle and set c, d
  // ...
  sstore
tag_10:
  jump  // return to caller of setCD()
```

现在有两个 `sstore` 而不是一个。Solidity 编译器可以在标签内进行优化，但不能跨标签进行优化。

调用函数可能会花费更多，不是因为函数调用很昂贵（它们只是跳转指令），而是因为 `sstore` 优化可能会失败。

为了解决这个问题，Solidity 编译器需要学习如何内联函数，本质上得到与不调用函数相同的代码：

```shell
a = 0xaaaa;
b = 0xbbbb;
c = 0xcccc;
d = 0xdddd;
```

> 如果我们仔细阅读完整的汇编输出，我们会看到函数 `setAB()` 和 `setCD()` 的汇编代码被包含了两次，这会增加代码的大小，从而使您在部署合约时花费额外的 gas。我们后面会在了解合约生命周期时讨论这个问题。

## Why The Optimizer Breaks

优化器不会跨标签进行优化。考虑“1+1”，如果在同一个标签下，可以优化为 `0x2`：

```shell
// Optimize OK!
tag_0:
  0x1
  0x1
  add
  ...
```

但如果指令由标签分隔，就不是这样了：

```shell
// Optimize Fail!
tag_0:
  0x1
  0x1
tag_1:
  add
  ...
```

从版本 0.4.13 开始，此行为是正确的。将来可能会改变。

## Breaking The Optimizer, Again

让我们看看优化器失败的另一种方式。打包是否适用于固定长度的数组？考虑：

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

同样，我们希望使用一个 `sstore` 指令将四个 64 位数字打包到一个 32 字节的存储槽中。

编译的汇编代码太长。让我们只计算 `sstore` 和 `sload` 指令的数量：

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

即使这个固定长度数组与等效结构或存储变量具有完全相同的存储布局，优化也会失败。现在需要四对 `sload` 和 `sstore`。

快速浏览一下汇编代码会发现，每个数组访问都有绑定检查代码，并组织在不同的标签下。但是标签边界会破坏优化。

不过有一个小小的安慰。 3 个额外的 `sstore` 指令比第一个便宜：

* `sstore` 首次写入新位置需要 20000 gas
* `sstore` 后续写入现有位置需要 5000 gas

因此这个特殊的优化失败让我们花费了 35k 而不是 20k，额外增加了 75%。

## Conclusion

如果 Solidity 编译器可以计算出存储变量的大小，它只需将它们一个接一个地放在存储中。如果可能，编译器会将数据紧密打包成 32 字节的块。

总结一下我们目前看到的打包行为：

* 存储变量：是的；
* 结构体字段：是的；
* 定长数组：没有；理论上，是的。

因为存储访问成本很高，您应该将存储变量视为您的数据库模式。在编写合约时，进行小型实验并检查程序集以了解编译器是否正确优化可能很有用。

我们可以肯定，Solidity 编译器将来会改进。但现在，我们不能盲目相信它的优化器。

Literally，了解您的存储变量是值得的。

# 深入以太坊虚拟机 Part3 — 动态数据类型的表示

Solidity 提供了其他编程语言中常见的数据结构。除了像数字和结构体这样的简单值之外，还有一些数据类型可以随着更多数据的添加而动态扩展。这些动态类型的三个主要类别是：

* 映射：`mapping(bytes32 => uint256)`，`mapping(address => string)`，等等
* 数组：`[]uint256`，`[]byte`，等等
* 字节数组，只有两种：`string`，`bytes`。

在本系列的上一部分中，我们看到了具有固定大小的简单类型如何在存储中表示。

* 基本值：`uint256`，`byte`，等等
* 固定大小的数组：`[10]uint8`，`[32]byte`，`bytes32`​
* 结合上面类型的结构体

具有固定大小的存储变量在存储中一个接一个地放置，尽可能紧密地打包成 32 字节的块。

在本文中，我们将研究 Solidity 如何支持更复杂的数据结构。 Solidity 中的数组和映射可能表面上看起来很熟悉，但它们的实现方式赋予了它们完全不同的性能特征。

我们将从映射开始，这是三者中最简单的。事实证明，数组和字节数组只是具有更高级特性的映射。<br />

## Mapping

让我们在 `uint256 => uint256` 映射中存储一个值：

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

编译：

```shell
solc --bin --asm --optimize c-mapping.sol
```

汇编：

```shell
tag_2:
  // Doesn't do anything. Should be optimized away.
  0xc0fefe
  0x0
  swap1
  dup2
  mstore
  0x20
  mstore
  // Storing 0x42 to the address 0x798...187c
  0x42
  0x79826054ee948a209ff4a6c9064d7398508d2c1909a392f899d301c6d232187c
  sstore
```

我们可以将 EVM 存储视为一个键值(key-value)数据库，每个键限制为存储 32 个字节。这里没有直接使用键 `0xC0FEFE`，而是将键散列为 `0x798...187c`，并将值 `0x42` 存储在那里。使用的散列函数是 `keccak256` (SHA256) 函数。

在这个例子中，我们看不到 `keccak256` 指令本身，因为优化器决定预先计算结果并将其内联到字节码中。我们仍然可以看到这种计算的痕迹，形式是无用的 `mstore` 指令。

## Calculate The Address

让我们使用一些 Python 代码将 `0xC0FEFE` 哈希为 `0x798...187c`。如果您想继续学习，则需要 Python 3.6，或安装 [pysha3](https://pypi.python.org/pypi/pysha3) 以获取 `keccak_256` 哈希函数。

定义两个辅助函数：

```python
import binascii
import sha3

# Convert a number to 32 bytes array.
def bytes32(i):
    return binascii.unhexlify('%064x' % i)

# Calculate the keccak256 hash of a 32 bytes array.
def keccak256(x):
    return sha3.keccak_256(x).hexdigest()
```

将数字转换为 32 个字节：

```shell
>>> bytes32(1)
b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
>>> bytes32(0xC0FEFE)
b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\xfe\xfe'
```

要将两个字节数组连接在一起，可使用 `+` 运算符：

```shell
>>> bytes32(1) + bytes32(2)
b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02'
```

计算字节的 keccak256 哈希：

```shell
>>> keccak256(bytes(1))
'bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a'
```

现在我们可以计算 `0x798...187c`。

存储变量 `items` 的位置是 `0x0`（因为它是第一个存储变量）。要获取地址，将键 `0xc0fefe` 与 `items` 的位置连接：

```shell
# key = 0xC0FEFE, position = 0
>>> keccak256(bytes32(0xC0FEFE) + bytes32(0))
'79826054ee948a209ff4a6c9064d7398508d2c1909a392f899d301c6d232187c'
```

计算键存储地址的公式为：

```shell
keccak256(bytes32(key) + bytes32(position))
```

## Two Mappings

让我们采用我们计算值存储位置的公式！假设我们有一个包含两个映射的合约：

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

* `itemsA` 的位置是 `0`，对于键 `0xAAAA`：

```shell
# key = 0xAAAA, position = 0
>>> keccak256(bytes32(0xAAAA) + bytes32(0))
'839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3'
```

* `itemsB` 的位置是`1`，对于键 `0xBBBB`：

```shell
# key = 0xBBBB, position = 1
>>> keccak256(bytes32(0xBBBB) + bytes32(1))
'34cb23340a4263c995af18b23d9f53b67ff379ccaa3a91b75007b010c489d395'
```

让我们用编译器验证这些计算：

```shell
$ solc --bin --asm --optimize  c-mapping-2.sol
```

汇编：

```shell
tag_2:
  // ... Omit memory operations that could be optimized away

  0xaaaa
  0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
  sstore

  0xbbbb
  0x34cb23340a4263c995af18b23d9f53b67ff379ccaa3a91b75007b010c489d395
  sstore
```

正如预期的那样。

## KECCAK256 in Assembly

编译器能够预先计算键的地址，因为所涉及的值是常量。如果使用的键是变量，则需要使用汇编代码进行散列。现在我们要禁用这种优化，这样我们就可以看到在汇编中散列是如何完成的。

事实证明，通过引入一个带有虚拟变量 `i` 的额外间接访问，很容易削弱优化器：

```solidity
// c-mapping--no-constant-folding.sol
pragma solidity ^0.4.11;

contract C {
	mapping(uint256 => uint256) items;

	// This variable causes constant folding to fail.
	uint256 i = 0xC0FEFE;

	function C() {
		items[i] = 0x42;
	}
}
```

变量 `items` 的位置仍然是 `0x0`，所以我们应该期待与之前相同的地址。

使用编译优化，但这次没有哈希预计算：

```shell
$ solc --bin --asm --optimize  c-mapping--no-constant-folding.sol
```

注释的汇编：

```shell
tag_2:
  // Load `i` onto the stack
  sload(0x1)
    [0xC0FEFE]

  // Store the key `0xC0FEFE` in memory at 0x0, for hashing.
  0x0
    [0x0 0xC0FEFE]
  swap1
    [0xC0FEFE 0x0]
  dup2
    [0x0 0xC0FEFE 0x0]
  mstore
    [0x0]
    memory: {
      0x00 => 0xC0FEFE
    }

  // Store the position `0x0` in memory at 0x20 (32), for hashing.
  0x20 // 32
    [0x20 0x0]
  dup2
    [0x0 0x20 0x0]
  swap1
    [0x20 0x0 0x0]
  mstore
    [0x0]
    memory: {
      0x00 => 0xC0FEFE
      0x20 => 0x0
    }

  // Starting at 0th byte, hash the next 0x40 (64) bytes in memory
  0x40 // 64
    [0x40 0x0]
  swap1
    [0x0 0x40]
  keccak256
    [0x798...187c]

  // Store 0x42 at the calculated address
  0x42
    [0x42 0x798...187c]
  swap1
    [0x798...187c 0x42]
  sstore
    store: {
      0x798...187c => 0x42
    }
```

`mstore` 指令在内存中写入 32 个字节。内存要便宜得多，读写只需 3 个 gas。汇编的前半部分通过将键和位置加载到相邻的内存块中来“连接”键和位置：

```shell
 0                   31  32                 63
[    key (32 bytes)    ][ position (32 bytes) ]
```

然后 `keccak256` 指令对该内存区域中的数据进行哈希处理。费用取决于哈希的数据量：

* 每个 SHA3 操作需要支付 30
* 每个 32 字节的字(word)需要支付 6

对于一个 `uint256` 的键，gas 成本为 42 (`30 + 6 * 2)`)。

## Mapping Large Values

每个存储槽只能存储 32 个字节。如果我们尝试存储一个更大的结构会发生什么？

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

编译，你应该会看到 3 个 `sstore` 指令：

```shell
tag_2:
  // ...omitting unoptimized code
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

请注意，除了最后一位之外，计算出的地址是相同的。 `Tuple` 结构体的成员字段依次排列（..7d、..7e、..7f）。

## Mappings Don't Pack

考虑到映射的设计方式，您为每项支付的最小存储量是 32 字节，即使您只存储 1 个字节：

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

如果一个值大于 32 字节，则您以 32 字节为增量支付存储费用。

## Dynamic Arrays Are Mapping++

在典型的语言中，数组只是一起存放在内存中的项列表。假设您有一个包含 100 个 `uint8` 元素的数组，那么它将占用 100 个字节的内存。在这种机制下，将整个数组批量加载到 CPU 缓存中并循环访问这些项目是很便宜的。

对于大多数语言，数组比映射便宜。然而，对于 Solidity，数组是更昂贵版本的映射。数组的项将在存储中按顺序排列，例如：

```shell
0x290d...e563
0x290d...e564
0x290d...e565
0x290d...e566
```

但请记住，对这些存储槽的每次访问实际上都是在数据库中进行键值查找。访问一个数组元素与访问映射元素没有什么不同。

考虑 `[]uint256` 类型，它本质上与 `mapping(uint256 => uint256)` 相同，并添加了使其“类似数组”的特性：

* `length` 表示有多少个项；
* 边界检查。读取和写入大于长度的索引时抛出错误(error)；
* 比映射更复杂的存储打包行为；
* 缩小数组时自动清零未使用的存储槽；
* 对 `bytes` 和 `string` 进行特殊优化，使短数组（小于 31 字节）的存储效率更高。

## Simple Array

让我们看一个存储三个项的数组：

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

数组访问的汇编代码太复杂而无法追踪。让我们使用 Remix 调试器来运行合约。

在模拟结束时，我们可以看到使用了 4 个存储槽。

```shell
key: 0x0000000000000000000000000000000000000000000000000000000000000000
value: 0x0000000000000000000000000000000000000000000000000000000000000003

key: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
value: 0x00000000000000000000000000000000000000000000000000000000000000aa

key: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564
value: 0x00000000000000000000000000000000000000000000000000000000000000bb

key: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e565
value: 0x00000000000000000000000000000000000000000000000000000000000000cc
```

`chunks` 变量的位置为 `0x0`，用于存储数组的长度（`0x3`）。哈希变量的位置以找到存储数组数据的地址：

```shell
# position = 0
>>> keccak256(bytes32(0))
'290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563'
```

数组中的每一项都是从这个地址（`0x29..63`、`0x29..64`、`0x29..65`）开始按顺序排列的。

## Dynamic Array Packing

所有重要的打包行为是怎么样的？数组优于映射的一个优点是打包是可以使用的。`uint128[]` 数组的四个项目正好适合两个存储槽（加上 1 用于存储长度）。

考虑：

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

在 Remix 中运行这个，最后的存储是这样的：

```shell
key: 0x0000000000000000000000000000000000000000000000000000000000000000
value: 0x0000000000000000000000000000000000000000000000000000000000000004

key: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
value: 0x000000000000000000000000000000bb000000000000000000000000000000aa

key: 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564
value: 0x000000000000000000000000000000dd000000000000000000000000000000cc
```

正如预期的那样，只使用了 3 个存储槽。长度再次存储在 `0x0`，即存储变量的位置。四个项打包在两个独立的存储槽中。这个数组的起始地址是变量位置的哈希值：

```shell
# position = 0
>>> keccak256(bytes32(0))
'290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563'
```

现在，地址每两个数组元素递增一次。看起来不错！

但是汇编代码本身并没有得到很好的优化。由于只使用了两个存储槽，我们希望优化器使用两个 `sstore` 进行赋值(assignment)。不幸的是，由于引入了边界检查（和其他一些东西），因此无法优化 `sstore` 指令。

四个 `sstore` 指令用于赋值(assignment)：

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

## Byte Arrays & String

`bytes` 和 `string` 是分别针对字节(bytes)和字符(characters)进行优化的特殊数组类型。如果数组的长度小于 31 字节，则只使用一个存储槽来存储整个事物。较长字节数组的表示方式与普通数组大致相同。

让我们看看一个短字节数组的作用：

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

由于数组只有 3 个字节（小于 31 个字节），它只占用一个存储槽。在 Remix 中运行，存储如下：

```shell
key: 0x0000000000000000000000000000000000000000000000000000000000000000
value: 0xaabbcc0000000000000000000000000000000000000000000000000000000006
```

数据 `0xaabbcc...` 从左到右存储。后面的 `0` 是空数据。最后一个字节 `0x06` 是数组的编码长度。公式为 `encodedLength / 2 = length`。在这种情况下，实际长度为 `6 / 2 = 3`。

字符串的工作方式完全相同。

## A Long Byte Array

如果数据量大于 31 字节，则字节数组类似于 `[]byte`。让我们看一下 128 字节长的字节数组：

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

在 Remix 中运行，我们看到存储中使用了四个插槽：

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

存储槽 `0x0` 不再用于存储数据。整个槽现在存储编码的数组长度。要获得实际长度，请执行 `length = (encodedLength - 1) / 2`。在这种情况下，长度为 `128 = (0x101 - 1) / 2`。实际字节存储在 `0x290d...e563` 中，并且依次存储在后面的插槽中。

字节数组的汇编代码很大。除了正常的边界检查和数组大小调整之外，它还需要对长度进行编码/解码，并注意在长字节数组和短字节数组之间进行转换。

> 为什么要将长度编码？因为它的完成方式，有一个简单的方法来测试一个字节数组是短的还是长的。请注意，长数组的编码长度总是奇数，短数组则是偶数。汇编代码只需要查看最后一位，看看它是零（偶数/短）还是非零（奇数/长）。

## Conclusion

深入了解 Solidity 编译器的内部工作原理，我们发现熟悉的数据结构（如映射和数组）与传统的编程语言完全不同。

回顾一下：

* 数组就像映射，效率不高。
* 比映射更复杂的汇编代码。
* 较小类型（byte，uint8，string）比映射有着更高的存储效率。
* 汇编没有很好地优化。即使使用打包，每次赋值也有一个 `sstore`。

EVM 存储是一个键值对数据库，很像 git。如果你改变任何东西，根节点的校验和就会改变。如果两个根节点的校验和相同，则保证存储的数据相同。

要了解 Solidity 和 EVM 的奇特之处，请想象数组的每个元素都是 git 仓库中自己的文件。当你改变一个数组元素的值时，你实际上是在创建一个 git commit。当遍历一个数组时，你不能一次加载整个数组，你必须查看仓库并分别找到每个文件。

不仅如此，每个文件限制为 32 个字节！因为我们需要将数据结构分割成 32 字节的块，Solidity 的编译器由于各种逻辑和优化技巧而变得复杂，所有这些都是在汇编中完成的。

然而，32 字节的限制完全是任意的。背后的键值存储可以使用键存储任意数量的字节。也许将来我们可以添加一条新的 EVM 指令来使用键存储任意字节。

目前，EVM 存储是一个装作(pretend) 32 字节数组的键值数据库。

> 请参阅 [ArrayUtils::resizeDynamicArray](https://github.com/ethereum/solidity/blob/3b07c4d38e40c52ee8a4d16e56e2afa1a0f27905/libsolidity/codegen/ArrayUtils.cpp#L624) 以了解编译器在调整数组大小时所做的事情。通常数据结构将作为标准库的一部分在语言中完成，但在 Solidity 中，它被嵌入到编译器中。

# 深入以太坊虚拟机 Part4 — 智能合约外部方法调用

在本系列的前几篇文章中，我们已经了解了 Solidity 如何表示 EVM 存储中的复杂数据结构。但是，如果无法与之交互，数据将毫无用处。智能合约是数据与外界之间的中介。

在本文中，我们将了解 Solidity 和 EVM 如何使外部程序能够调用合约的方法并导致其状态发生变化。

“外部程序”不限于 DApp/JavaScript。任何可以使用 HTTP RPC 与以太坊节点通信的程序都可以通过创建交易与部署在区块链上的任何合约进行交互。

创建一个交易就像发出一个 HTTP 请求。Web 服务器将接受您的 HTTP 请求并对数据库进行更改。交易会被网络接受，并且底层区块链扩展到包括状态变化。

交易之于智能合约就像 HTTP 请求之于 Web 服务一样。

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

# 深入以太坊虚拟机 Part5 — 智能合约创建过程

在本系列的前几篇文章中，我们学习了 EVM 汇编的基础知识，以及 ABI 编码如何允许外部世界与合约进行通信。在本文中，我们将了解如何从无到有创建合约。

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

在处理此交易时，EVM 会将输入数据作为代码执行。*Voila*，合同诞生了。

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

## A Contract That Creats Contracts

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

# 深入以太坊虚拟机 Part6 — Solidity 事件实现

在上一部分中，我们了解了“方法”是如何建立在更简单的 EVM 原语（如“跳转”和“比较”指令）之上的抽象。

在本文中，我们将深入探讨 [Solidity Events](https://docs.soliditylang.org/en/develop/contracts.html#events)。总的来说，事件日志有三种主要用途：

* 作为替代返回值，因为交易不记录方法的返回值。
* 作为一种更便宜的替代数据存储，只要合约不需要访问它。
* 最后，作为 DApp 客户端可以订阅的事件。

事件日志是一个相对复杂的语言特性。但就像方法一样，它们映射到更简单的 EVM 日志原语。

通过了解事件是如何使用较低级别的 EVM 指令实现的，以及它们的成本，我们将获得更好的直觉来有效地使用事件。

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
* 允许主题具有任意数量的字节。为什么不这样呢？