# 深入以太坊虚拟机 Part3 — 动态数据类型的表示

> 原文：[Diving Into The Ethereum VM Part 3 — The Hidden Costs of Arrays | by Howard | Aug 24, 2017](https://medium.com/@hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b)

Solidity 提供了其他编程语言中常见的数据结构。除了像数字和结构体这样的简单值之外，还有一些数据类型可以随着更多数据的添加而动态扩展。这些动态类型的三个主要类别是：

* 映射：`mapping(bytes32 => uint256)`，`mapping(address => string)`，等等
* 数组：`[]uint256`，`[]byte`，等等
* 字节数组，只有两种：`string`，`bytes`。

在本系列的上一部分中，我们看到了具有固定大小的简单类型如何在存储中表示。

* 基本值：`uint256`，`byte`，等等
* 固定大小的数组：`[10]uint8`，`[32]byte`，`bytes32`​
* 结合上面类型的结构体

具有固定大小的存储变量在存储中一个接一个地放置，尽可能紧密地打包成 32 字节的块。

（如果这部分看起来不熟悉，请阅读 [深入以太坊虚拟机 Part2 — 固定长度数据类型的表示](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)）

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