---
title: 42. 分账
tags:
  - solidity
  - application

---

# WTF Solidity极简入门: 42. 分账

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们介绍分账合约，该合约允许将`ETH`按权重转给一组账户中，进行分账。代码部分由OpenZeppelin库的[PaymentSplitter合约](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol)简化而来。

## 分账

分账就是按照一定比例分钱财。在现实中，经常会有“分赃不均”的事情发生；而在区块链的世界里，`Code is Law`，我们可以事先把每个人应分的比例写在智能合约中，获得收入后，再由智能合约来进行分账。

![分账](./img/42-1.webp)

## 分账合约

分账合约(`PaymentSplit`)具有以下几个特点：

1. 在创建合约时定好分账受益人`payees`和每人的份额`shares`。
2. 份额可以是相等，也可以是其他任意比例。
3. 在该合约收到的所有`ETH`中，每个受益人将能够提取与其分配的份额成比例的金额。
4. 分账合约遵循`Pull Payment`模式，付款不会自动转入账户，而是保存在此合约中。受益人通过调用`release()`函数触发实际转账。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * 分账合约 
 * @dev 这个合约会把收到的ETH按事先定好的份额分给几个账户。收到ETH会存在分账合约中，需要每个受益人调用release()函数来领取。
 */
contract PaymentSplit{
```

### 事件

分账合约中共有`3`个事件：

- `PayeeAdded`：增加受益人事件。
- `PaymentReleased`：受益人提款事件。
- `PaymentReceived`：分账合约收款事件。

```solidity
    // 事件
    event PayeeAdded(address account, uint256 shares); // 增加受益人事件
    event PaymentReleased(address to, uint256 amount); // 受益人提款事件
    event PaymentReceived(address from, uint256 amount); // 合约收款事件
```

### 状态变量

分账合约中共有`5`个状态变量，用来记录受益地址、份额、支付出去的`ETH`等变量：

- `totalShares`：总份额，为`shares`的和。
- `totalReleased`：从分账合约向受益人支付出去的`ETH`，为`released`的和。
- `payees`：`address`数组，记录受益人地址
- `shares`：`address`到`uint256`的映射，记录每个受益人的份额。
- `released`：`address`到`uint256`的映射，记录分账合约支付给每个受益人的金额。

```solidity
    uint256 public totalShares; // 总份额
    uint256 public totalReleased; // 总支付

    mapping(address => uint256) public shares; // 每个受益人的份额
    mapping(address => uint256) public released; // 支付给每个受益人的金额
    address[] public payees; // 受益人数组
```

### 函数

分账合约中共有`6`个函数：

- 构造函数：始化受益人数组`_payees`和分账份额数组`_shares`，其中数组长度不能为0，两个数组长度要相等。_shares中元素要大于0，_payees中地址不能为0地址且不能有重复地址。
- `receive()`：回调函数，在分账合约收到`ETH`时释放`PaymentReceived`事件。
- `release()`：分账函数，为有效受益人地址`_account`分配相应的`ETH`。任何人都可以触发这个函数，但`ETH`会转给受益人地址`account`。调用了releasable()函数。
- `releasable()`：计算一个受益人地址应领取的`ETH`。调用了`pendingPayment()`函数。
- `pendingPayment()`：根据受益人地址`_account`, 分账合约总收入`_totalReceived`和该地址已领取的钱`_alreadyReleased`，计算该受益人现在应分的`ETH`。
- `_addPayee()`：新增受益人函数及其份额函数。在合约初始化的时候被调用，之后不能修改。

```solidity
    /**
     * @dev 初始化受益人数组_payees和分账份额数组_shares
     * 数组长度不能为0，两个数组长度要相等。_shares中元素要大于0，_payees中地址不能为0地址且不能有重复地址
     */
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        // 检查_payees和_shares数组长度相同，且不为0
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        // 调用_addPayee，更新受益人地址payees、受益人份额shares和总份额totalShares
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev 回调函数，收到ETH释放PaymentReceived事件
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev 为有效受益人地址_account分帐，相应的ETH直接发送到受益人地址。任何人都可以触发这个函数，但钱会打给account地址。
     * 调用了releasable()函数。
     */
    function release(address payable _account) public virtual {
        // account必须是有效受益人
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // 计算account应得的eth
        uint256 payment = releasable(_account);
        // 应得的eth不能为0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // 更新总支付totalReleased和支付给每个受益人的金额released
        totalReleased += payment;
        released[_account] += payment;
        // 转账
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

    /**
     * @dev 计算一个账户能够领取的eth。
     * 调用了pendingPayment()函数。
     */
    function releasable(address _account) public view returns (uint256) {
        // 计算分账合约总收入totalReceived
        uint256 totalReceived = address(this).balance + totalReleased;
        // 调用_pendingPayment计算account应得的ETH
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    /**
     * @dev 根据受益人地址`_account`, 分账合约总收入`_totalReceived`和该地址已领取的钱`_alreadyReleased`，计算该受益人现在应分的`ETH`。
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        // account应得的ETH = 总应得ETH - 已领到的ETH
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    /**
     * @dev 新增受益人_account以及对应的份额_accountShares。只能在构造器中被调用，不能修改。
     */
    function _addPayee(address _account, uint256 _accountShares) private {
        // 检查_account不为0地址
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        // 检查_accountShares不为0
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // 检查_account不重复
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        // 更新payees，shares和totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        // 释放增加受益人事件
        emit PayeeAdded(_account, _accountShares);
    }
```

## `Remix`演示

### 1. 部署`PaymentSplit`分账合约，并转入`1 ETH`

在构造函数中，输入两个受益人地址，份额为`1`和`3`。

![部署](./img/42-2.png)

### 2. 查看受益人地址、份额、应分到的`ETH`

![查看第一位受益人](./img/42-3.png)

![查看第二位受益人](./img/42-4.png)

### 3. 函数领取`ETH`

![调用release](./img/42-5.png)

### 4. 查看总支出、受益人余额、应分到的`ETH`的变化

![查看](./img/42-6.png)

## 总结

这一讲，我们介绍了分账合约。在区块链的世界里，`Code is Law`，我们可以事先把每个人应分的比例写在智能合约中，获得收入后，由智能合约来进行分账，避免事后“分赃不均”。
