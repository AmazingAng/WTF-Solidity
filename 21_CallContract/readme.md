---
title: 21. 调用其他合约
tags:
  - solidity
  - advanced
  - wtfacademy
  - call contract
---

# WTF Solidity极简入门: 21. 调用其他合约

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

## 调用已部署合约

在`Solidity`中，一个合约可以调用另一个合约的函数，这在构建复杂的DApps时非常有用。本教程将会介绍如何在已知合约代码（或接口）和地址的情况下，调用已部署的合约。

## 目标合约

我们先写一个简单的合约`OtherContract`，用于被其他合约调用。

```solidity
contract OtherContract {
    uint256 private _x = 0; // 状态变量_x
    // 收到eth的事件，记录amount和gas
    event Log(uint amount, uint gas);
    
    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // 可以调整状态变量_x的函数，并且可以往合约转ETH (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // 如果转入ETH，则释放Log事件
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // 读取_x
    function getX() external view returns(uint x){
        x = _x;
    }
}
```

这个合约包含一个状态变量`_x`、一个在收到`ETH`时触发的事件`Log`，以及三个函数：

- `getBalance()`: 返回合约`ETH`余额。
- `setX()`: `external payable`函数，可以设置`_x`的值，并向合约发送`ETH`。
- `getX()`: 读取`_x`的值。

## 调用`OtherContract`合约

我们可以利用合约的地址和合约代码（或接口）来创建对一个合约的引用：`_Name(_Address)`：

- `_Name`是合约名，必须与​​合约代码或接口中定义的合约名​​严格一致​​。
- `_Address`是目标合约部署在链上的地址。

创建引用后，就可以通过它来调用目标合约的函数了：`_Name(_Address).f()`，其中`f()`是要调用的函数。

下面我们介绍4个调用合约的例子，在remix中编译合约后，分别部署`OtherContract`和`CallContract`：

![deploy contract0 in remix](./img/21-1.png)

![deploy contract1 in remix](./img/21-2.png)

![deploy contract2 in remix](./img/21-3.png)

### 1. 传入合约地址

我们可以在函数里传入目标合约地址，生成目标合约的引用，然后调用目标函数。以调用`OtherContract`合约的`setX`函数为例，我们在新合约中写一个`callSetX`函数，传入已部署好的`OtherContract`合约地址`_Address`和`setX`的参数`x`：

```solidity
function callSetX(address _Address, uint256 x) external{
    OtherContract(_Address).setX(x);
}
```

复制`OtherContract`合约的地址，填入`callSetX`函数的参数中，成功调用后，调用`OtherContract`合约中的`getX`验证`x`变为123

![call contract1 in remix](./img/21-4.png)

![call contract2 in remix](./img/21-5.png)

### 2. 传入合约变量

我们可以直接在函数里传入合约的引用，只需要把上面参数的`address`类型改为目标合约名，比如`OtherContract`。下面例子实现了调用目标合约的`getX()`函数。

**注意**：该函数参数`OtherContract _Address`底层类型仍然是`address`，生成的`ABI`中、调用`callGetX`时传入的参数都是`address`类型

```solidity
function callGetX(OtherContract _Address) external view returns(uint x){
    x = _Address.getX();
}
```

复制`OtherContract`合约的地址，填入`callGetX`函数的参数中，调用后成功获取`x`的值

![call contract3 in remix](./img/21-6.png)

### 3. 创建合约变量

我们可以创建合约变量，然后通过它来调用目标函数。下面例子，我们给变量`oc`存储了`OtherContract`合约的引用：

```solidity
function callGetX2(address _Address) external view returns(uint x){
    OtherContract oc = OtherContract(_Address);
    x = oc.getX();
}
```

复制`OtherContract`合约的地址，填入`callGetX2`函数的参数中，调用后成功获取`x`的值

![call contract4 in remix](./img/21-7.png)

### 4. 调用合约并发送`ETH`

如果目标合约的函数是`payable`的，那么我们可以通过调用它来给合约转账：`_Name(_Address).f{value: _Value}()`，其中`_Name`是合约名，`_Address`是合约地址，`f`是目标函数名，`_Value`是要转的`ETH`数额（以`wei`为单位）。

`OtherContract`合约的`setX`函数是`payable`的，在下面这个例子中我们通过调用`setX`来往目标合约转账。

```solidity
function setXTransferETH(address otherContract, uint256 x) payable external{
    OtherContract(otherContract).setX{value: msg.value}(x);
}
```

复制`OtherContract`合约的地址，填入`setXTransferETH`函数的参数中，并转入10ETH

![call contract5 in remix](./img/21-8.png)

转账后，我们可以通过`Log`事件和`getBalance()`函数观察目标合约`ETH`余额的变化。

![call contract6 in remix](./img/21-9.png)

## 总结

这一讲，我们介绍了如何通过目标合约代码（或接口）和地址来创建合约的引用，从而调用目标合约的函数。
