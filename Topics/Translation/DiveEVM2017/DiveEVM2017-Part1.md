# 深入以太坊虚拟机 Part1 — 汇编与字节码

> 原文：[Diving Into The Ethereum Virtual Machine | by Howard | Aug 6, 2017](https://blog.qtum.org/diving-into-the-ethereum-vm-6e8d5d2f3c30)

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