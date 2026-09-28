---
title: 43. 線形釈放
tags:
  - solidity
  - application
  - ERC20

---

# WTF Solidity 超シンプル入門: 43. 線形釈放

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、トークン帰属条項について紹介し、`ERC20`トークンの線形釈放コントラクトを作成します。コードは`OpenZeppelin`の`VestingWallet`コントラクトを簡略化したものです。

## トークン帰属条項

![デプロイ](./img/43-1.jpeg)

従来の金融分野では、一部の企業が従業員や経営陣に株式を提供しています。しかし、大量の株式を同時に放出すると、短期的な売却圧力が生じ、株価を押し下げる可能性があります。そのため、通常企業は帰属期間を導入して、約束された資産の所有権を遅延させます。同様に、ブロックチェーン分野では、`Web3`スタートアップがチームにトークンを配分し、同時にトークンを低価格でベンチャーキャピタルやプライベートエクイティに売却します。もし彼らがこれらの低コストトークンを同時に取引所で現金化すれば、価格は暴落し、個人投資家が直接的な損失を被ることになります。

そのため、プロジェクト方は通常トークン帰属条項（token vesting）を約定し、帰属期間内にトークンを段階的に釈放することで、売却圧力を緩和し、チームと資本方の早期撤退を防ぎます。

## 線形釈放

線形釈放とは、トークンが帰属期間内に均一な速度で釈放されることを指します。例えば、あるプライベートエクイティが365,000枚の`ICU`トークンを保有し、帰属期間が1年（365日）の場合、毎日1,000枚のトークンが釈放されます。

以下では、`ERC20`トークンをロックして線形釈放するコントラクト`TokenVesting`を作成します。そのロジックは非常にシンプルです：

- プロジェクト方が線形釈放の開始時間、帰属期間、受益者を規定します。
- プロジェクト方がロックされた`ERC20`トークンを`TokenVesting`コントラクトに転送します。
- 受益者は`release`関数を呼び出して、コントラクトから釈放されたトークンを取り出すことができます。

### イベント
線形釈放コントラクトには合計`1`つのイベントがあります。
- `ERC20Released`：出金イベント、受益者が釈放されたトークンを引き出した際に発行されます。

```solidity
contract TokenVesting {
    // イベント
    event ERC20Released(address indexed token, uint256 amount); // 出金イベント
```

### 状態変数
線形釈放コントラクトには合計`4`つの状態変数があります。
- `beneficiary`：受益者アドレス。
- `start`：帰属期間開始タイムスタンプ。
- `duration`：帰属期間、単位は秒。
- `erc20Released`：トークンアドレス->釈放量のマッピング、受益者が既に受け取ったトークン数量を記録。

```solidity
    // 状態変数
    mapping(address => uint256) public erc20Released; // トークンアドレス->釈放量のマッピング、既に釈放されたトークンを記録
    address public immutable beneficiary; // 受益者アドレス
    uint256 public immutable start; // 開始タイムスタンプ
    uint256 public immutable duration; // 帰属期間
```

### 関数
線形釈放コントラクトには合計`3`つの関数があります。

- コンストラクタ：受益者アドレス、帰属期間（秒）、開始タイムスタンプを初期化します。パラメータは受益者アドレス`beneficiaryAddress`と帰属期間`durationSeconds`です。便宜上、開始タイムスタンプはデプロイ時のブロックチェーンタイムスタンプ`block.timestamp`を使用します。
- `release()`：トークン引き出し関数、既に釈放されたトークンを受益者に転送します。`vestedAmount()`関数を呼び出して引き出し可能なトークン数量を計算し、`ERC20Released`イベントを発行してから、トークンを受益者に`transfer`します。パラメータはトークンアドレス`token`です。
- `vestedAmount()`：線形釈放公式に基づいて、既に釈放されたトークン数量をクエリします。開発者はこの関数を修正することで、釈放方法をカスタマイズできます。パラメータはトークンアドレス`token`とクエリのタイムスタンプ`timestamp`です。

```solidity
    /**
     * @dev 受益者アドレス、釈放期間（秒）、開始タイムスタンプ（現在のブロックチェーンタイムスタンプ）を初期化
     */
    constructor(
        address beneficiaryAddress,
        uint256 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    /**
     * @dev 受益者が既に釈放されたトークンを引き出し。
     * vestedAmount()関数を呼び出して引き出し可能なトークン数量を計算し、その後受益者にtransferします。
     * {ERC20Released}イベントを発行。
     */
    function release(address token) public {
        // vestedAmount()関数を呼び出して引き出し可能なトークン数量を計算
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        // 既に釈放されたトークン数量を更新
        erc20Released[token] += releasable;
        // トークンを受益者に転送
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    /**
     * @dev 線形釈放公式に基づいて、既に釈放された数量を計算。開発者はこの関数を修正することで、釈放方法をカスタマイズできます。
     * @param token: トークンアドレス
     * @param timestamp: クエリのタイムスタンプ
     */
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        // コントラクトが合計で受け取ったトークン数量（現在の残高 + 既に引き出した分）
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        // 線形釈放公式に基づいて、既に釈放された数量を計算
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
```

## `Remix`デモ

### 1. [第31講](../31_ERC20/readme.md)の`ERC20`コントラクトをデプロイし、自分に`10000`枚のトークンを鋳造。

![ERC20デプロイ](./img/43-2.png)

![10000枚のトークンを鋳造](./img/43-3.png)

### 2. `TokenVesting`線形釈放コントラクトをデプロイし、受益者を自分に設定し、帰属期間を`100`秒に設定。

![TokenVestingデプロイ](./img/43-4.png)

### 3. `10000`枚の`ERC20`トークンを線形釈放コントラクトに転送。

![トークン転送](./img/43-5.png)

### 4. `release()`関数を呼び出してトークンを引き出し。

![トークン引き出し](./img/43-6.png)

## まとめ

トークンの短期間大量解錠は価格に巨大な圧力を与えますが、トークン帰属条項を約定することで売却圧力を緩和し、チームと資本方の早期撤退を防ぐことができます。今回は、トークン帰属条項について紹介し、`ERC20`トークンの線形釈放コントラクトを作成しました。