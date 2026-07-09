---
title: 42. 分账
tags:
  - solidity
  - application

---

# WTF Solidity 超シンプル入門: 42. 分账

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、分账合約について説明します。このコントラクトは、`ETH`を重み付けに従って一群のアカウントに分配することができます。コードはOpenZeppelinライブラリの[PaymentSplitterコントラクト](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol)を簡略化したものです。

## 分账

分账とは、一定の比率に従って資金を分配することです。現実世界では、よく「取り分が不平等」という問題が発生しますが、ブロックチェーンの世界では、`Code is Law`なので、事前に各人の取り分の比率をスマートコントラクトに記述しておき、収入を得た後にスマートコントラクトが分账を行うことができます。

![分账](./img/42-1.webp)

## 分账コントラクト

分账コントラクト(`PaymentSplit`)には以下の特徴があります：

1. コントラクト作成時に分账受益者`payees`と各人の持分`shares`を定めます。
2. 持分は等しくても、その他の任意の比率でも構いません。
3. このコントラクトが受け取った全ての`ETH`のうち、各受益者は自分に割り当てられた持分に比例した金額を引き出すことができます。
4. 分账コントラクトは`Pull Payment`モデルに従い、支払いは自動的にアカウントに転送されず、このコントラクトに保存されます。受益者は`release()`関数を呼び出して実際の転送をトリガーします。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * 分账コントラクト
 * @dev このコントラクトは受け取ったETHを事前に定めた持分に従って複数のアカウントに分配します。受け取ったETHは分账コントラクトに保存され、各受益者がrelease()関数を呼び出して受け取る必要があります。
 */
contract PaymentSplit{
```

### イベント

分账コントラクトには合計`3`つのイベントがあります：

- `PayeeAdded`：受益者追加イベント。
- `PaymentReleased`：受益者出金イベント。
- `PaymentReceived`：分账コントラクト入金イベント。

```solidity
    // イベント
    event PayeeAdded(address account, uint256 shares); // 受益者追加イベント
    event PaymentReleased(address to, uint256 amount); // 受益者出金イベント
    event PaymentReceived(address from, uint256 amount); // コントラクト入金イベント
```

### 状態変数

分账コントラクトには合計`5`つの状態変数があり、受益者アドレス、持分、支払い済み`ETH`などの変数を記録するために使用されます：

- `totalShares`：総持分、`shares`の合計。
- `totalReleased`：分账コントラクトから受益者に支払われた`ETH`、`released`の合計。
- `payees`：`address`配列、受益者アドレスを記録
- `shares`：`address`から`uint256`へのマッピング、各受益者の持分を記録。
- `released`：`address`から`uint256`へのマッピング、分账コントラクトが各受益者に支払った金額を記録。

```solidity
    uint256 public totalShares; // 総持分
    uint256 public totalReleased; // 総支払額

    mapping(address => uint256) public shares; // 各受益者の持分
    mapping(address => uint256) public released; // 各受益者への支払額
    address[] public payees; // 受益者配列
```

### 関数

分账コントラクトには合計`6`つの関数があります：

- コンストラクタ：受益者配列`_payees`と分账持分配列`_shares`を初期化します。配列の長さは0であってはならず、2つの配列の長さは等しくなければなりません。`_shares`の要素は0より大きく、`_payees`のアドレスは0アドレスであってはならず、重複もあってはなりません。
- `receive()`：コールバック関数、分账コントラクトが`ETH`を受け取った時に`PaymentReceived`イベントを発行します。
- `release()`：分账関数、有効な受益者アドレス`_account`に対応する`ETH`を分配します。誰でもこの関数をトリガーできますが、`ETH`は受益者アドレス`account`に転送されます。`releasable()`関数を呼び出します。
- `releasable()`：受益者アドレスが受け取るべき`ETH`を計算します。`pendingPayment()`関数を呼び出します。
- `pendingPayment()`：受益者アドレス`_account`、分账コントラクトの総収入`_totalReceived`、そのアドレスが既に受け取った金額`_alreadyReleased`に基づいて、その受益者が現在分配されるべき`ETH`を計算します。
- `_addPayee()`：受益者とその持分を追加する関数。コントラクトの初期化時に呼び出され、後から変更することはできません。

```solidity
    /**
     * @dev 受益者配列_payeesと分账持分配列_sharesを初期化
     * 配列の長さは等しく、0であってはなりません。_sharesの要素は0より大きく、_payeesのアドレスは0アドレスであってはならず、重複もあってはなりません
     */
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        // _payeesと_shares配列の長さが同じで、0でないことをチェック
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        // _addPayeeを呼び出し、受益者アドレスpayees、受益者持分shares、総持分totalSharesを更新
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev コールバック関数、ETH受信時にPaymentReceivedイベントを発行
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev 有効な受益者アドレス_accountに分账し、対応するETHを受益者アドレスに直接送信。誰でもこの関数をトリガーできますが、資金はaccountアドレスに送られます。
     * releasable()関数を呼び出します。
     */
    function release(address payable _account) public virtual {
        // accountは有効な受益者でなければなりません
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // accountが受け取るべきethを計算
        uint256 payment = releasable(_account);
        // 受け取るべきethは0であってはなりません
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // 総支払額totalReleasedと各受益者への支払額releasedを更新
        totalReleased += payment;
        released[_account] += payment;
        // 送金
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

    /**
     * @dev アカウントが受け取ることができるethを計算。
     * pendingPayment()関数を呼び出します。
     */
    function releasable(address _account) public view returns (uint256) {
        // 分账コントラクトの総収入totalReceivedを計算
        uint256 totalReceived = address(this).balance + totalReleased;
        // _pendingPaymentを呼び出してaccountが受け取るべきETHを計算
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    /**
     * @dev 受益者アドレス`_account`、分账コントラクトの総収入`_totalReceived`、そのアドレスが既に受け取った金額`_alreadyReleased`に基づいて、その受益者が現在分配されるべき`ETH`を計算。
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        // accountが受け取るべきETH = 総受取予定ETH - 既に受け取ったETH
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    /**
     * @dev 受益者_accountと対応する持分_accountSharesを追加。コンストラクタでのみ呼び出され、変更できません。
     */
    function _addPayee(address _account, uint256 _accountShares) private {
        // _accountが0アドレスでないことをチェック
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        // _accountSharesが0でないことをチェック
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // _accountが重複していないことをチェック
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        // payees、shares、totalSharesを更新
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        // 受益者追加イベントを発行
        emit PayeeAdded(_account, _accountShares);
    }
```

## `Remix`デモ

### 1. `PaymentSplit`分账コントラクトをデプロイし、`1 ETH`を転送

コンストラクタで、2つの受益者アドレスを入力し、持分を`1`と`3`に設定します。

![デプロイ](./img/42-2.png)

### 2. 受益者アドレス、持分、分配されるべき`ETH`を確認

![第一受益者を確認](./img/42-3.png)

![第二受益者を確認](./img/42-4.png)

### 3. 関数を使って`ETH`を受け取る

![releaseを呼び出し](./img/42-5.png)

### 4. 総支出、受益者残高、分配されるべき`ETH`の変化を確認

![確認](./img/42-6.png)

## まとめ

今回は分账コントラクトについて紹介しました。ブロックチェーンの世界では、`Code is Law`なので、事前に各人の取り分の比率をスマートコントラクトに記述しておき、収入を得た後にスマートコントラクトが分账を行うことで、事後の「取り分不平等」を避けることができます。