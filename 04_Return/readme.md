---
title: 4. 函数输出
tags:
  - solidity
  - basic
  - wtfacademy
  - return
---

# WTF Solidity极简入门: 4. 函数输出

我最近在重新学Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍 Solidity 函数输出，包括：返回多种变量，命名式返回，以及利用解构式赋值读取全部或部分返回值。

## 返回值：return 和 returns

Solidity 中与函数输出相关的有两个关键字：`return`和`returns`。它们的区别在于：

- `returns`：跟在函数名后面，用于声明返回的变量类型及变量名。
- `return`：用于函数主体中，返回指定的变量。

```solidity
// 返回多个变量
function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
    return(1, true, [uint256(1),2,5]);
}
```

在上述代码中，我们利用 `returns` 关键字声明了有多个返回值的 `returnMultiple()` 函数，然后我们在函数主体中使用 `return(1, true, [uint256(1),2,5])` 确定了返回值。你可能会疑惑 uint256[3] memory 和 [uint256(1), 2,5] 这两个写法，你可以先在网上搜一下相关的说明或者带着这个疑惑继续学习后面的章节，你就会得到答案了。

## 命名式返回

我们可以在 `returns` 中标明返回变量的名称。Solidity 会初始化这些变量，并且自动返回这些函数的值，无需使用 `return`。

```solidity
// 命名式返回
function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
    _number = 2;
    _bool = false;
    _array = [uint256(3),2,1];
}
```

在上述代码中，我们用 `returns(uint256 _number, bool _bool, uint256[3] memory _array)` 声明了返回变量类型以及变量名。这样，在主体中只需为变量 `_number`、`_bool`和`_array` 赋值，即可自动返回。

当然，你也可以在命名式返回中用 `return` 来返回变量：

```solidity
// 命名式返回，依然支持return
function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
    return(1, true, [uint256(1),2,5]);
}
```

## 解构式赋值

Solidity 支持使用解构式赋值规则来读取函数的全部或部分返回值。

- 读取所有返回值：声明变量，然后将要赋值的变量用`,`隔开，按顺序排列。

    ```solidity
    uint256 _number;
    bool _bool;
    uint256[3] memory _array;
    (_number, _bool, _array) = returnNamed();
    ```

- 读取部分返回值：声明要读取的返回值对应的变量，不读取的留空。在下面的代码中，我们只读取`_bool`，而不读取返回的`_number`和`_array`：

    ```solidity
    (, _bool2, ) = returnNamed();
    ```

## 在 Remix 上运行

- 部署合约后查看三种返回方式的结果

    ![4-1.png](./img/4-1.png)

## 总结

这一讲，我们介绍 Solidity 函数返回值，包括：返回多种变量，命名式返回，以及利用解构式赋值读取全部或部分返回值。这些知识点有助于我们在编写智能合约时，更灵活地处理函数返回值。
