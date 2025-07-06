---
title: 23. Delegatecall
tags:
  - solidity
  - advanced
  - wtfacademy
  - call contract
  - delegatecall
---

# WTF Solidity极简入门: 23. Delegatecall

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

## `Delegatecall`

`delegatecall`与`call`类似，是`Solidity`中地址类型的低级成员函数。`delegate`中是委托/代表的意思，那么`delegatecall`委托了什么？

当用户`A`通过合约`B`来`call`合约`C`的时候，执行的是合约`C`的函数，`上下文`(`Context`，可以理解为包含变量和状态的环境)也是合约`C`的：`msg.sender`是`B`的地址，并且如果函数改变一些状态变量，产生的效果会作用于合约`C`的变量上。

![call的上下文](https://images.mirror-media.xyz/publication-images/VgMR533pA8WYtE5Lr65mQ.png?height=698&width=1860)

而当用户`A`通过合约`B`来`delegatecall`合约`C`的时候，执行的是合约`C`的函数，但是`上下文`仍是合约`B`的：`msg.sender`是`A`的地址，并且如果函数改变一些状态变量，产生的效果会作用于合约`B`的变量上。

![delegatecall的上下文](https://images.mirror-media.xyz/publication-images/JucQiWVixdlmJl6zHjCSI.png?height=702&width=1862)

大家可以这样理解：一个投资者（用户`A`）把他的资产（`B`合约的`状态变量`）都交给一个风险投资代理（`C`合约）来打理。执行的是风险投资代理的函数，但是改变的是资产的状态。

`delegatecall`语法和`call`类似，也是：

```solidity
目标合约地址.delegatecall(二进制编码);
```

其中`二进制编码`利用结构化编码函数`abi.encodeWithSignature`获得：

```solidity
abi.encodeWithSignature("函数签名", 逗号分隔的具体参数)
```

`函数签名`为`"函数名（逗号分隔的参数类型）"`。例如`abi.encodeWithSignature("f(uint256,address)", _x, _addr)`。

和`call`不一样，`delegatecall`在调用合约时可以指定交易发送的`gas`，但不能指定发送的`ETH`数额

> **注意**：`delegatecall`有安全隐患，使用时要保证当前合约和目标合约的状态变量存储结构相同，并且目标合约安全，不然会造成资产损失。

## 什么情况下会用到`delegatecall`?

目前`delegatecall`主要有两个应用场景：

1. 代理合约（`Proxy Contract`）：将智能合约的存储合约和逻辑合约分开：代理合约（`Proxy Contract`）存储所有相关的变量，并且保存逻辑合约的地址；所有函数存在逻辑合约（`Logic Contract`）里，通过`delegatecall`执行。当升级时，只需要将代理合约指向新的逻辑合约即可。

2. EIP-2535 Diamonds（钻石）：钻石是一个支持构建可在生产中扩展的模块化智能合约系统的标准。钻石是具有多个实施合约的代理合约。 更多信息请查看：[钻石标准简介](https://eip2535diamonds.substack.com/p/introduction-to-the-diamond-standard)。

## `delegatecall`例子

调用结构：你（`A`）通过合约`B`调用目标合约`C`。

### 被调用的合约C

我们先写一个简单的目标合约`C`：有两个`public`变量：`num`和`sender`，分别是`uint256`和`address`类型；有一个函数，可以将`num`设定为传入的`_num`，并且将`sender`设为`msg.sender`。

```solidity
// 被调用的合约C
contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}
```

### 发起调用的合约B

首先，合约`B`必须和目标合约`C`的变量存储布局必须相同 —— 即存在两个 `public` 变量且变量类型顺序为 `uint256` 和 `address`
> **注意：** 变量名称可以不同

```solidity
contract B {
    uint public num;
    address public sender;
}
```

接下来，我们分别用`call`和`delegatecall`来调用合约`C`的`setVars`函数，更好的理解它们的区别。

`callSetVars`函数通过`call`来调用`setVars`。它有两个参数`_addr`和`_num`，分别对应合约`C`的地址和`setVars`的参数。

```solidity
// 通过call来调用C的setVars()函数，将改变合约C里的状态变量
function callSetVars(address _addr, uint _num) external payable{
    // call setVars()
    (bool success, bytes memory data) = _addr.call(
        abi.encodeWithSignature("setVars(uint256)", _num)
    );
}
```

而`delegatecallSetVars`函数通过`delegatecall`来调用`setVars`。与上面的`callSetVars`函数相同，有两个参数`_addr`和`_num`，分别对应合约`C`的地址和`setVars`的参数。

```solidity
// 通过delegatecall来调用C的setVars()函数，将改变合约B里的状态变量
function delegatecallSetVars(address _addr, uint _num) external payable{
    // delegatecall setVars()
    (bool success, bytes memory data) = _addr.delegatecall(
        abi.encodeWithSignature("setVars(uint256)", _num)
    );
}
```

### 在remix上验证

1. 首先，我们把合约`B`和`C`都部署好

    ![deploy.png](./img/23-1.png)
2. 部署之后，查看`C`合约状态变量的初始值，`B`合约的状态变量也是一样。

    ![initialstate.png](./img/23-2.png)
3. 此时，调用合约`B`中的`callSetVars`，传入参数为合约`C`地址和`10`

    ![call.png](./img/23-3.png)

4. 运行后，合约`C`中的状态变量将被修改：`num`被改为`10`，`sender`变为合约`B`的地址

    ![resultcall.png](./img/23-4.png)
5. 接下来，我们调用合约`B`中的`delegatecallSetVars`，传入参数为合约`C`地址和`100`

    ![delegatecall.png](./img/23-5.png)

6. 由于是`delegatecall`，上下文为合约`B`。在运行后，合约`B`中的状态变量将被修改：`num`被改为`100`，`sender`变为你的钱包地址。合约`C`中的状态变量不会被修改。

    ![resultdelegatecall.png](./img/23-6.png)

## 总结

这一讲我们介绍了`Solidity`中的另一个低级函数`delegatecall`。与`call`类似，它可以用来调用其他合约；不同点在于运行的上下文，`B call C`，上下文为`C`；而`B delegatecall C`，上下文为`B`。目前`delegatecall`最大的应用是代理合约和`EIP-2535 Diamonds`（钻石）。
