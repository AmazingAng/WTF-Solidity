# Solidity极简入门: 6. 映射类型 mapping

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

WTF技术社群discord，内有加微信群方法：[链接](https://discord.gg/5akcruXrsk)

所有代码和教程开源在github（1024个star发课程认证，2048个star发社群NFT）: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍solidity中的哈希表：映射（`Mapping`）类型。

## 映射Mapping
在映射中，人们可以通过键（`Key`）来查询对应的值（`Value`），比如：通过一个人的`id`来查询他的钱包地址。

声明映射的格式为`mapping(_KeyType => _ValueType)`，其中`_KeyType`和`_ValueType`分别是`Key`和`Value`的变量类型。例子：
```solidity
    mapping(uint => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址
```  
## 映射的规则
- **规则1**：映射的`_KeyType`只能选择`solidity`默认的类型，比如`uint`，`address`等，不能用自定义的结构体。而`_ValueType`可以使用自定义的类型。下面这个例子会报错，因为`_KeyType`使用了我们自定义的结构体：
```solidity
    // 我们定义一个结构体 Struct
    struct Student{
        uint256 id;
        uint256 score; 
    }
     mapping(Student => uint) public testVar;
```
- **规则2**：映射的存储位置必须是`storage`，因此可以用于合约的状态变量，函数中的`storage`变量。不能用于`public`函数的参数或返回结果中，因为`mapping`记录的是一种关系 (key - value pair)。

- **规则3**：如果映射声明为`public`，那么`solidity`会自动给你创建一个`getter`函数，可以通过`Key`来查询对应的`Value`。

- **规则4**：给映射新增的键值对的语法为`_Var[_Key] = _Value`，其中`_Var`是映射变量名，`_Key`和`_Value`对应新增的键值对。例子：
```solidity
    function writeMap (uint _Key, address _Value) public{
        idToAddress[_Key] = _Value;
    }
```
## 映射的原理
- **原理1**: 映射不储存任何键（`Key`）的资讯，也没有length的资讯。

- **原理2**: 映射使用`keccak256(key)`当成offset存取value。

- **原理3**: 因为Ethereum会定义所以未使用的空间为0，所以对于所以未赋值（`Value`）的键（`Key`），其初始值都是0。

## 在Remix上验证 (以 `Mapping.sol`为例)
- 映射示例 1 部署

    ![6-1](./img/6-1.jpg)

- 映射示例 2 初始值

    ![6-2](./img/6-2.jpg)

- 映射示例 3 key-value pair

    ![6-3](./img/6-3.jpg)



## 总结
这一讲，我们介绍了`solidity`中哈希表——映射（`Mapping`）的用法。至此，我们已经学习了所有常用变量种类，之后我们会学习控制流`if-else`,` while`等。

