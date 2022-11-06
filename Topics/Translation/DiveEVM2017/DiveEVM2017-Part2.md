# 深入以太坊虚拟机 Part2 — 固定长度数据类型的表示

> 原文：[Diving Into The Ethereum VM Part 2 — How I Learned To Start Worrying And Count The Storage Cost | by Howard | Aug 14, 2017 ](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-2-storage-layout-bc5349cb11b7)

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

> 如果看起来不熟悉，建议阅读：[深入以太坊虚拟机 Part1 — 汇编与字节码](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)。

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