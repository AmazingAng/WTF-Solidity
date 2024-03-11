---
title: S13. 未检查的低级调用
tags:
  - solidity
  - security
  - transfer/send/call
---

# WTF Solidity 合约安全: S13. 未检查的低级调用

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity 合约安全”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们将介绍智能合约的未检查低级调用（low-level call）的漏洞。失败的低级调用不会让交易回滚，如果合约中忘记对其返回值进行检查，往往会出现严重的问题。

## 低级调用

以太坊的低级调用包括 `call()`，`delegatecall()`，`staticcall()`，和`send()`。这些函数与 Solidity 其他函数不同，当出现异常时，它并不会向上层传递，也不会导致交易完全回滚；它只会返回一个布尔值 `false` ，传递调用失败的信息。因此，如果未检查低级函数调用的返回值，则无论低级调用失败与否，上层函数的代码会继续运行。对于低级调用更多的内容，请阅读 [WTF Solidity 极简教程第20-23讲](https://github.com/AmazingAng/WTF-Solidity)。

最容易出错的是`send()`：一些合约使用 `send()` 发送 `ETH`，但是 `send()` 限制 gas 要低于 2300，否则会失败。当目标地址的回调函数比较复杂时，花费的 gas 将高于 2300，从而导致 `send()` 失败。如果此时在上层函数没有检查返回值的话，交易继续执行，就会出现意想不到的问题。2016年，有一款叫 `King of Ether` 的链游，因为这个漏洞导致退款无法正常发送（[验尸报告](https://www.kingoftheether.com/postmortem.html)）。

![](./img/S13-1.png)

## 漏洞例子

### 银行合约

这个合约是在`S01 重入攻击`教程中的银行合约基础上修改而成。它包含`1`个状态变量`balanceOf`记录所有用户的以太坊余额；并且包含`3`个函数：
- `deposit()`：存款函数，将`ETH`存入银行合约，并更新用户的余额。
- `withdraw()`：提款函数，将调用者的余额转给它。具体步骤和上面故事中一样：查询余额，更新余额，转账。**注意：这个函数没有检查 `send()` 的返回值，提款失败但余额会清零！**
- `getBalance()`：获取银行合约里的`ETH`余额。

```solidity
contract UncheckedBank {
    mapping (address => uint256) public balanceOf;    // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 提取msg.sender的全部ether
    function withdraw() external {
        // 获取余额
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        balanceOf[msg.sender] = 0;
        // Unchecked low-level call
        bool success = payable(msg.sender).send(balance);
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## 攻击合约

我们构造了一个攻击合约，它刻画了一个倒霉的储户，取款失败但是银行余额清零：合约回调函数 `receive()` 中的 `revert()` 将回滚交易，因此它无法接收 `ETH`；但是提款函数 `withdraw()` 却能正常调用，清空余额。

```solidity
contract Attack {
    UncheckedBank public bank; // Bank合约地址

    // 初始化Bank合约地址
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }
    
    // 回调函数，转账ETH时会失败
    receive() external payable {
        revert();
    }

    // 存款函数，调用时 msg.value 设为存款数量
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // 取款函数，虽然调用成功，但实际上取款失败
    function withdraw() external payable {
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## `Remix`复现

1. 部署 `UncheckedBank` 合约。

2. 部署 `Attack` 合约，构造函数填入 `UncheckedBank` 合约地址。

3. 调用 `Attack` 合约的 `deposit()` 存款函数，存入`1 ETH`。

4. 调用 `Attack` 合约的 `withdraw()` 提款函数，进行提款，调用成功。

5. 分别调用 `UncheckedBank` 合约的 `balanceOf()` 函数和 `Attack` 合约的 `getBalance()` 函数。尽管上一步调用成功并且储户余额被清空，但是提款失败了。

## 预防办法

你可以使用以下几种方法来预防未检查低级调用的漏洞：

1. 检查低级调用的返回值，在上面的银行合约中，我们可以改正 `withdraw()`。
    ```solidity
    bool success = payable(msg.sender).send(balance);
    require(success, "Failed Sending ETH!")
    ```
2. 合约转账`ETH`时，使用 `call()`，并做好重入保护。

3. 使用`OpenZeppelin`的[Address库](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)，它将检查返回值的低级调用封装好了。

## 总结

我们将介绍未检查低级调用的漏洞及其预防方法。以太坊的低级调用（call, delegatecall, staticcall, send）在失败时会返回一个布尔值 false，但不会让整个交易回滚。如果开发者没有对它进行检查的话，则会发生意外。