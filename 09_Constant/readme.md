---
title: 9. 常数
tags:
  - solidity
  - basic
  - wtfacademy
  - constant/immutable
---

# Solidity极简入门: 9. 常数 constant和immutable

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

WTF技术社群discord，内有加微信群方法：[链接](https://discord.gg/5akcruXrsk)

所有代码和教程开源在github（1024个star发课程认证，2048个star发社群NFT）: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
这一讲，我们介绍`solidity`中两个关键字，`constant`（常量）和`immutable`（不变量）。状态变量声明这个两个关键字之后，不能在合约后更改数值；并且还可以节省`gas`。另外，只有数值变量可以声明`constant`和`immutable`；`string`和`bytes`可以声明为`constant`，但不能为`immutable`。

## constant和immutable
### constant
`constant`变量必须在声明的时候初始化，之后再也不能改变。尝试改变的话，编译不通过。
``` solidity
    // constant变量必须在声明的时候初始化，之后不能改变
    uint256 constant CONSTANT_NUM = 10;
    string constant CONSTANT_STRING = "0xAA";
    bytes constant CONSTANT_BYTES = "WTF";
    address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
```
### immutable
`immutable`变量可以在声明时或构造函数中初始化，因此更加灵活。
``` solidity
    // immutable变量可以在constructor里初始化，之后不能改变
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;
```
你可以使用全局变量例如`address(this)`，`block.number` ，或者自定义的函数给`immutable`变量初始化。在下面这个例子，我们利用了`test()`函数给`IMMUTABLE_TEST`初始化为`9`：
``` solidity
    // 利用constructor初始化immutable变量，因此可以利用
    constructor(){
        IMMUTABLE_ADDRESS = address(this);
        IMMUTABLE_BLOCK = block.number;
        IMMUTABLE_TEST = test();
    }

    function test() public pure returns(uint256){
        uint256 what = 9;
        return(what);
    }
```

## 在remix上验证
1. 部署好合约之后，通过remix上的`getter`函数，能获取到`constant`和`immutable`变量初始化好的值。

   ![9-1.png](./img/9-1.png)   
   
2. `constant`变量初始化之后，尝试改变它的值，会编译不通过并抛出`TypeError: Cannot assign to a constant variable.`的错误。


   ![9-2.png](./img/9-2.png)   
   
3. `immutable`变量初始化之后，尝试改变它的值，会编译不通过并抛出`TypeError: Immutable state variable already initialized.`的错误。

   ![9-3.png](./img/9-3.png)

## 总结
这一讲，我们介绍`solidity`中两个关键字，`constant`（常量）和`immutable`（不变量），让不应该变的变量保持不变。这样的做法能在节省`gas`的同时提升合约的安全性。

