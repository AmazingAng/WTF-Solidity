# Solidity极简入门: 9. 事件

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

所有代码开源在github(64个star开微信交流群，已开[填表加入](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform)；128个star录教学视频): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们用转账ERC20代币为例来介绍`solidity`中的事件（`event`）。

## 事件
`Solidity`中的事件（`event`）是`EVM`上日志的抽象，它具有两个特点：

- 响应：应用程序（[`ether.js`](https://learnblockchain.cn/docs/ethers.js/api-contract.html#id18)）可以通过`RPC`接口订阅和监听这些事件，并在前端做响应。
- 经济：事件是`EVM`上比较经济的存储数据的方式，每个大概消耗2,000-5,000 `gas`不等。相比之下，存储一个新的变量至少需要20,000 `gas`。

wishucry注：实际测试了一下，以 Transfer 标准事件为例，事件的消耗 gas 值约为1700多，如果是匿名事件，存储将更小，消耗几百 gas。

### 规则
事件的声明由`event`关键字开头，然后跟事件名称，括号里面写好事件需要记录的变量类型和变量名。以`ERC20`代币合约的`Transfer`事件为例：
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```
我们可以看到，`Transfer`事件共记录了3个变量`from`，`to`和`value`，分别对应代币的转账地址，接收地址和转账数量。

同时`from`和`to`前面带着`indexed`关键字，每个`indexed`标记的变量可以理解为检索事件的索引“键”，在以太坊上单独作为一个 topic 进行存储和索引，程序可以轻松的筛选出特定转账地址和接收地址的转账事件。每个事件最多有3个带`indexed`的变量。事件的哈希以及这三个带`indexed`的变量在英文技术文档往往也被称为 `topic[0]` 到 `topic[3]`。每个 `indexed` 变量的大小为固定的256比特。

`value` 不带 `indexed` 关键字，会存储在事件的 `data` 部分中，可以理解为事件的“值”。`data` 部分的变量不能被直接检索，但可以存储任意大小的数据。因此一般 `data` 部分可以用来存储复杂的数据结构，例如数组和字符串等等，因为这些数据超过了256比特，即使存储在事件的 `topic` 部分中，也是以哈希的方式存储。另外，`data` 部分的变量在存储上消耗的gas相比于 `topic` 更少。

我们可以在函数里释放事件。在下面的例子中，每次用`_transfer()`函数进行转账操作的时候，都会释放`Transfer`事件，并记录相应的变量。
```solidity
    // 定义_transfer函数，执行转账逻辑
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {

        _balances[from] = 10000000; // 给转账地址一些初始代币

        _balances[from] -=  amount; // from地址减去转账数量
        _balances[to] += amount; // to地址加上转账数量

        // 释放事件
        emit Transfer(from, to, amount);
    }
```

### Remix 演示
以 `Event.sol` 合约为例，编译部署。

然后调用 `_transfer` 函数。
![](assets/16535538066362.jpg)

点击右侧的交易查看详情，可以看到日志的具体内容。
![](assets/16535540748258.jpg)


### 在etherscan上查询事件
我们尝试用`_transfer()`函数在`Rinkeby`测试网络上转账100代币，可以在`etherscan`上查询到相应的`tx`：[网址](https://rinkeby.etherscan.io/tx/0x8cf87215b23055896d93004112bbd8ab754f081b4491cb48c37592ca8f8a36c7)。

点击`Logs`按钮，就能看到事件明细：

![Event明细](https://images.mirror-media.xyz/publication-images/gx6_wDMYEl8_Gc_JkTIKn.png?height=980&width=1772)

`Topics`里面有三个元素，`[0]`是这个事件的哈希，`[1]`和`[2]`是我们定义的两个`indexed`变量的信息，即转账的转出地址和接收地址。`Data`里面是剩下的不带`indexed`的变量，也就是转账数量。

## 总结
这一讲，我们介绍了如何使用和查询`solidity`中的事件。很多链上分析工具包括`Nansen`和`Dune Analysis`都是基于事件工作的。

