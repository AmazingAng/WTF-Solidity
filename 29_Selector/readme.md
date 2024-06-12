---
title: 29. 选择器
tags:
  - solidity
  - advanced
  - wtfacademy
  - selector
---

# WTF Solidity极简入门: 29. 函数选择器Selector

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

## 函数选择器

当我们调用智能合约时，本质上是向目标合约发送了一段`calldata`，在remix中发送一次交易后，可以在详细信息中看见`input`即为此次交易的`calldata`

![tx input in remix](./img/29-1.png)

发送的`calldata`中前4个字节是`selector`（函数选择器）。这一讲，我们将介绍`selector`是什么，以及如何使用。

### msg.data

`msg.data`是`Solidity`中的一个全局变量，值为完整的`calldata`（调用函数时传入的数据）。

在下面的代码中，我们可以通过`Log`事件来输出调用`mint`函数的`calldata`：

```solidity
// event 返回msg.data
event Log(bytes data);

function mint(address to) external{
    emit Log(msg.data);
}
```

当参数为`0x2c44b726ADF1963cA47Af88B284C06f30380fC78`时，输出的`calldata`为

```text
0x6a6278420000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
```

这段很乱的字节码可以分成两部分：

```text
前4个字节为函数选择器selector：
0x6a627842

后面32个字节为输入的参数：
0x0000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
```

其实`calldata`就是告诉智能合约，我要调用哪个函数，以及参数是什么。

### method id、selector和函数签名

`method id`定义为`函数签名`的`Keccak`哈希后的前4个字节，当`selector`与`method id`相匹配时，即表示调用该函数，那么`函数签名`是什么？

其实在第21讲中，我们简单介绍了函数签名，为`"函数名（逗号分隔的参数类型)"`。举个例子，上面代码中`mint`的函数签名为`"mint(address)"`。在同一个智能合约中，不同的函数有不同的函数签名，因此我们可以通过函数签名来确定要调用哪个函数。

**注意**，在函数签名中，`uint`和`int`要写为`uint256`和`int256`。

我们写一个函数，来验证`mint`函数的`method id`是否为`0x6a627842`。大家可以运行下面的函数，看看结果。

```solidity
function mintSelector() external pure returns(bytes4 mSelector){
    return bytes4(keccak256("mint(address)"));
}
```

结果正是`0x6a627842`：

![method id in remix](./img/29-2.png)

由于计算`method id`时，需要通过函数名和函数的参数类型来计算。在`Solidity`中，函数的参数类型主要分为：基础类型参数，固定长度类型参数，可变长度类型参数和映射类型参数。

##### 基础类型参数
`solidity`中，基础类型的参数有：`uint256`(`uint8`, ... , `uint256`)、`bool`, `address`等。在计算`method id`时，只需要计算`bytes4(keccak256("函数名(参数类型1,参数类型2,...)"))`。例如，如下函数，函数名为`elementaryParamSelector`，参数类型分别为`uint256`和`bool`。所以，只需要计算`bytes4(keccak256("elementaryParamSelector(uint256,bool)"))`便可得到此函数的`method id`。
```solidity
    // elementary（基础）类型参数selector
    // 输入：param1: 1，param2: 0
    // elementaryParamSelector(uint256,bool) : 0x3ec37834
    function elementaryParamSelector(uint256 param1, bool param2) external returns(bytes4 selectorWithElementaryParam){
        emit SelectorEvent(this.elementaryParamSelector.selector);
        return bytes4(keccak256("elementaryParamSelector(uint256,bool)"));
    }
```

##### 固定长度类型参数
固定长度的参数类型通常为固定长度的数组，例如：`uint256[5]`等。例如，如下函数`fixedSizeParamSelector`的参数为`uint256[3]`。因此，在计算该函数的`method id`时，只需要通过`bytes4(keccak256("fixedSizeParamSelector(uint256[3])"))`即可。

```solidity
    // fixed size（固定长度）类型参数selector
    // 输入： param1: [1,2,3]
    // fixedSizeParamSelector(uint256[3]) : 0xead6b8bd
    function fixedSizeParamSelector(uint256[3] memory param1) external returns(bytes4 selectorWithFixedSizeParam){
        emit SelectorEvent(this.fixedSizeParamSelector.selector);
        return bytes4(keccak256("fixedSizeParamSelector(uint256[3])"));
    }
```

##### 可变长度类型参数
可变长度参数类型通常为可变长的数组，例如：`address[]`、`uint8[]`、`string`等。例如，如下函数`nonFixedSizeParamSelector`的参数为`uint256[]`和`string`。因此，在计算该函数的`method id`时，只需要通过`bytes4(keccak256("nonFixedSizeParamSelector(uint256[],string)"))`即可。

```solidity
    // non-fixed size（可变长度）类型参数selector
    // 输入： param1: [1,2,3]， param2: "abc"
    // nonFixedSizeParamSelector(uint256[],string) : 0xf0ca01de
    function nonFixedSizeParamSelector(uint256[] memory param1,string memory param2) external returns(bytes4 selectorWithNonFixedSizeParam){
        emit SelectorEvent(this.nonFixedSizeParamSelector.selector);
        return bytes4(keccak256("nonFixedSizeParamSelector(uint256[],string)"));
    }
```

##### 映射类型参数
映射类型参数通常有：`contract`、`enum`、`struct`等。在计算`method id`时，需要将该类型转化成为`ABI`类型。

例如，如下函数`mappingParamSelector`中`DemoContract`需要转化为`address`，结构体`User`需要转化为`tuple`类型`(uint256,bytes)`，枚举类型`School`需要转化为`uint8`。因此，计算该函数的`method id`的代码为`bytes4(keccak256("mappingParamSelector(address,(uint256,bytes),uint256[],uint8)"))`。

```solidity
contract DemoContract {
    // empty contract
}

contract Selector{
    // Struct User
    struct User {
        uint256 uid;
        bytes name;
    }
    // Enum School
    enum School { SCHOOL1, SCHOOL2, SCHOOL3 }
    ...
    // mapping（映射）类型参数selector
    // 输入：demo: 0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99， user: [1, "0xa0b1"], count: [1,2,3], mySchool: 1
    // mappingParamSelector(address,(uint256,bytes),uint256[],uint8) : 0xe355b0ce
    function mappingParamSelector(DemoContract demo, User memory user, uint256[] memory count, School mySchool) external returns(bytes4 selectorWithMappingParam){
        emit SelectorEvent(this.mappingParamSelector.selector);
        return bytes4(keccak256("mappingParamSelector(address,(uint256,bytes),uint256[],uint8)"));
    }
    ...
}
```

### 使用selector

我们可以利用`selector`来调用目标函数。例如我想调用`elementaryParamSelector`函数，我只需要利用`abi.encodeWithSelector`将`elementaryParamSelector`函数的`method id`作为`selector`和参数打包编码，传给`call`函数：

```solidity
    // 使用selector来调用函数
    function callWithSignature() external{
	...
        // 调用elementaryParamSelector函数
        (bool success1, bytes memory data1) = address(this).call(abi.encodeWithSelector(0x3ec37834, 1, 0));
	...
    }
```

在日志中，我们可以看到`elementaryParamSelector`函数被成功调用，并输出`Log`事件。

![logs in remix](./img/29-3.png)

## 总结

这一讲，我们介绍了什么是`函数选择器`（`selector`），它和`msg.data`、`函数签名`的关系，以及如何使用它调用目标函数。
