---
title: 44. トークンロック
tags:
  - solidity
  - application
  - ERC20

---

# WTF Solidity 超シンプル入門: 44. トークンロック

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、流動性提供者`LP`トークンとは何か、なぜ流動性をロックする必要があるのかについて紹介し、シンプルな`ERC20`トークンロックコントラクトを作成します。

## トークンロック

![トークンロック](./img/44-1.webp)

トークンロック（Token Locker）は、シンプルなタイムロックコントラクトで、コントラクト内のトークンを一定期間ロックし、受益者はロック期間満了後にトークンを取り出すことができます。トークンロックは一般的に流動性提供者`LP`トークンをロックするために使用されます。

### `LP`トークンとは？

ブロックチェーンでは、ユーザーは分散型取引所`DEX`でトークンを取引します（例：`Uniswap`取引所）。`DEX`は中央集権取引所（`CEX`）とは異なり、分散型取引所は自動マーケットメーカー（`AMM`）メカニズムを使用し、ユーザーやプロジェクト方がプールを提供する必要があり、これにより他のユーザーが即座に売買できるようになります。簡単に言うと、ユーザー/プロジェクト方は対応するペア（例：`ETH/DAI`）をプールに質入れし、補償として`DEX`は対応する流動性提供者`LP`トークン証明書を鋳造し、彼らが対応する持分を質入れしたことを証明し、手数料を徴収できるようにします。

### なぜ流動性をロックする必要があるのか？

プロジェクト方が何の前触れもなく流動性プール内の`LP`トークンを引き出すと、投資者の手にあるトークンは現金化できなくなり、直接ゼロになってしまいます。この行為は`rug-pull`とも呼ばれ、2021年だけでも、様々な`rug-pull`詐欺が投資者から28億ドル以上の暗号通貨を騙し取りました。

しかし、`LP`トークンがトークンロックコントラクト内にロックされている場合、ロック期間が終了する前にプロジェクト方は流動性プールを引き出すことができず、`rug pull`もできません。そのため、トークンロックはプロジェクト方の早期逃走を防ぐことができます（ロック期間満了時の逃走には注意が必要）。

## トークンロックコントラクト

以下では、`ERC20`トークンをロックするコントラクト`TokenLocker`を作成します。そのロジックは非常にシンプルです：

- 開発者がコントラクトをデプロイする際に、ロック時間、受益者アドレス、およびトークンコントラクトを規定します。
- 開発者が`TokenLocker`コントラクトにトークンを転送します。
- ロック期間満了時に、受益者はコントラクト内のトークンを取り出すことができます。

### イベント

`TokenLocker`コントラクトには合計`2`つのイベントがあります。

- `TokenLockStart`：ロック開始イベント、コントラクトデプロイ時に発行され、受益者アドレス、トークンアドレス、ロック開始時間、終了時間を記録。
- `Release`：トークン釈放イベント、受益者がトークンを取り出した際に発行され、受益者アドレス、トークンアドレス、釈放トークン時間、トークン数量を記録。

```solidity
    // イベント
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);
```

### 状態変数

`TokenLocker`コントラクトには合計`4`つの状態変数があります。

- `token`：ロック対象トークンアドレス。
- `beneficiary`：受益者アドレス。
- `locktime`：ロック時間（秒）。
- `startTime`：ロック開始タイムスタンプ（秒）。

```solidity
    // ロックされるERC20トークンコントラクト
    IERC20 public immutable token;
    // 受益者アドレス
    address public immutable beneficiary;
    // ロック時間（秒）
    uint256 public immutable lockTime;
    // ロック開始タイムスタンプ（秒）
    uint256 public immutable startTime;
```

### 関数

`TokenLocker`コントラクトには合計`2`つの関数があります。

- コンストラクタ：トークンコントラクト、受益者アドレス、およびロック時間を初期化します。
- `release()`：ロック期間満了後、トークンを受益者に釈放します。受益者が自発的に`release()`関数を呼び出してトークンを取り出す必要があります。

```solidity
    /**
     * @dev タイムロックコントラクトをデプロイし、トークンコントラクトアドレス、受益者アドレス、ロック時間を初期化。
     * @param token_: ロックされるERC20トークンコントラクト
     * @param beneficiary_: 受益者アドレス
     * @param lockTime_: ロック時間（秒）
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 lockTime_
    ) {
        require(lockTime_ > 0, "TokenLock: lock time should greater than 0");
        token = token_;
        beneficiary = beneficiary_;
        lockTime = lockTime_;
        startTime = block.timestamp;

        emit TokenLockStart(beneficiary_, address(token_), block.timestamp, lockTime_);
    }

    /**
     * @dev ロック時間経過後、トークンを受益者に釈放。
     */
    function release() public {
        require(block.timestamp >= startTime+lockTime, "TokenLock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");

        token.transfer(beneficiary, amount);

        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
```

## `Remix`デモ

### 1. [第31講](../31_ERC20/readme.md)の`ERC20`コントラクトをデプロイし、自分に`10000`枚のトークンを鋳造。

![`Remix`デモ](./img/44-2.jpg)

### 2. `TokenLocker`コントラクトをデプロイし、トークンアドレスを`ERC20`コントラクトアドレスに、受益者を自分に、ロック期間を`180`秒に設定。

![`Remix`デモ](./img/44-3.jpg)

### 3. `10000`枚のトークンをコントラクトに転送。

![`Remix`デモ](./img/44-4.jpg)

### 4. ロック期間`180`秒内に`release()`関数を呼び出しても、トークンを取り出すことはできません。

![`Remix`デモ](./img/44-5.jpg)

### 5. ロック期間後に`release()`関数を呼び出し、トークンの取り出しに成功。

![`Remix`デモ](./img/44-6.jpg)

## まとめ

今回は、トークンロックコントラクトについて紹介しました。プロジェクト方は一般的に`DEX`で流動性を提供し、投資者の取引を支援します。プロジェクト方が突然`LP`を引き出すと`rug-pull`が発生しますが、`LP`をトークンロックコントラクト内にロックすることで、この状況を回避できます。