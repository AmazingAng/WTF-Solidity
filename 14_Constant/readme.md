# Solidity极简入门: 14. 常数 constant和immutable

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

所有代码开源在github(64个star开微信交流群，已开[填表加入](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform)；128个star录教学视频): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

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
   ![14 1.png](https://github.com/Rulesbreaker/WTFSolidity/blob/080325f750e18aaf89e6283c9b9f3209668fc037/14_Constant/img/14.1.png)   
   
2. `constant`变量初始化之后，尝试改变它的值，会编译不通过并抛出`TypeError: Cannot assign to a constant variable.`的错误。
   ![14 2.png](https://github.com/Rulesbreaker/WTFSolidity/blob/080325f750e18aaf89e6283c9b9f3209668fc037/14_Constant/img/14.2.png)   
   
3. `immutable`变量初始化之后，尝试改变它的值，会编译不通过并抛出`TypeError: Immutable state variable already initialized.`的错误。
   ![14 3.png](https://github.com/Rulesbreaker/WTFSolidity/blob/080325f750e18aaf89e6283c9b9f3209668fc037/14_Constant/img/14.3.png)

## 总结
这一讲，我们介绍`solidity`中两个关键字，`constant`（常量）和`immutable`（不变量），让不应该变的变量保持不变。这样的做法能在节省`gas`的同时提升合约的安全性。

