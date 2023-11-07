---
title: 2. 值类型
tags:
  - solidity
  - basic
  - wtfacademy
---

# WTF Solidity极简入门: 2. 值类型

我最近在重新学Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## Solidity中的变量类型

1. **值类型(Value Type)**：包括布尔型，整数型等等，这类变量赋值时候直接传递数值。

2. **引用类型(Reference Type)**：包括数组和结构体，这类变量占空间大，赋值时候直接传递地址（类似指针）。

3. **映射类型(Mapping Type)**: Solidity中存储键值对的数据结构，可以理解为哈希表

我们将仅介绍常用类型，不常用的类型不会涉及，本篇将介绍值类型。

## 值类型

### 1. 布尔型

布尔型是二值变量，取值为 `true` 或 `false`。

```solidity
// 布尔值
bool public _bool = true;
```

布尔值的运算符包括：

- `!` （逻辑非）
- `&&` （逻辑与，"and"）
- `||` （逻辑或，"or"）
- `==` （等于）
- `!=` （不等于）

```solidity
// 布尔运算
bool public _bool1 = !_bool; // 取非
bool public _bool2 = _bool && _bool1; // 与
bool public _bool3 = _bool || _bool1; // 或
bool public _bool4 = _bool == _bool1; // 相等
bool public _bool5 = _bool != _bool1; // 不相等
```

在上述代码中：变量 `_bool` 的取值是 `true`；`_bool1` 是 `_bool` 的非，为 `false`；`_bool && _bool1` 为 `false`；`_bool || _bool1` 为 `true`；`_bool == _bool1` 为 `false`；`_bool != _bool1` 为 `true`。

**值得注意的是：**`&&` 和 `||` 运算符遵循短路规则，这意味着，假如存在 `f(x) || g(y)` 的表达式，如果 `f(x)` 是 `true`，`g(y)` 不会被计算，即使它和 `f(x)` 的结果是相反的。假如存在`f(x) && g(y)` 的表达式，如果 `f(x)` 是 `false`，`g(y)` 不会被计算。

### 2. 整型

整型是 Solidity 中的整数，最常用的包括：

```solidity
// 整型
int public _int = -1; // 整数，包括负数
uint public _uint = 1; // 正整数
uint256 public _number = 20220330; // 256位正整数
```

常用的整型运算符包括：

- 比较运算符（返回布尔值）： `<=`， `<`，`==`， `!=`， `>=`， `>`
- 算数运算符： `+`， `-`， `*`， `/`， `%`（取余），`**`（幂）

```solidity
// 整数运算
uint256 public _number1 = _number + 1; // +，-，*，/
uint256 public _number2 = 2**2; // 指数
uint256 public _number3 = 7 % 2; // 取余数
bool public _numberbool = _number2 > _number3; // 比大小
```

大家可以运行一下代码，看看这 4 个变量分别是多少。

### 3. 地址类型

地址类型(address)有两类：

- 普通地址（address）: 存储一个 20 字节的值（以太坊地址的大小）。
- payable address: 比普通地址多了 `transfer` 和 `send` 两个成员方法，用于接收转账。

我们会在之后的章节更加详细地介绍 payable address。

```solidity
// 地址
address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
address payable public _address1 = payable(_address); // payable address，可以转账、查余额
// 地址类型的成员
uint256 public balance = _address1.balance; // balance of address
```

### 4. 定长字节数组

字节数组分为定长和不定长两种：

- 定长字节数组: 属于值类型，数组长度在声明之后不能改变。根据字节数组的长度分为 `bytes1`, `bytes8`, `bytes32` 等类型。定长字节数组最多存储 32 bytes 数据，即`bytes32`。
- 不定长字节数组: 属于引用类型（之后的章节介绍），数组长度在声明之后可以改变，包括 `bytes` 等。

```solidity
// 固定长度的字节数组
bytes32 public _byte32 = "MiniSolidity"; 
bytes1 public _byte = _byte32[0]; 
```

在上述代码中，`MiniSolidity` 变量以字节的方式存储进变量 `_byte32`。如果把它转换成 `16 进制`，就是：`0x4d696e69536f6c69646974790000000000000000000000000000000000000000`

`_byte` 变量的值为 `_byte32` 的第一个字节，即 `0x4d`。

### 5. 枚举 enum

枚举（`enum`）是 Solidity 中用户定义的数据类型。它主要用于为 `uint` 分配名称，使程序易于阅读和维护。它与 `C 语言` 中的 `enum` 类似，使用名称来代替从 `0` 开始的 `uint`：

```solidity
// 用enum将uint 0， 1， 2表示为Buy, Hold, Sell
enum ActionSet { Buy, Hold, Sell }
// 创建enum变量 action
ActionSet action = ActionSet.Buy;
```

枚举可以显式地和 `uint` 相互转换，并会检查转换的正整数是否在枚举的长度内，否则会报错：

```solidity
// enum可以和uint显式的转换
function enumToUint() external view returns(uint){
    return uint(action);
}
```

`enum` 是一个比较冷门的变量，几乎没什么人用。

## 在 Remix 上运行

- 部署合约后可以查看每个类型的变量的数值：

![2-1.png](./img/2-1.png)
  
- `enum` 和 `uint` 转换的示例：

![2-2.png](./img/2-2.png)
![2-3.png](./img/2-3.png)

## 总结

在这一讲，我们介绍了 Solidity 中值类型，包括布尔型、整型、地址、定长字节数组和枚举。在后续章节，我们将继续介绍 Solidity 的其他变量类型，包括引用类型和映射类型。
