---
title: 45. タイムロック
tags:
  - solidity
  - application

---

# WTF Solidity 超シンプル入門: 45. タイムロック

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、タイムロックとタイムロックコントラクトについて紹介します。コードはCompoundの[Timelockコントラクト](https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol)を簡略化したものです。

## タイムロック

![タイムロック](./img/45-1.jpeg)

タイムロック（Timelock）は、銀行の金庫やその他の高セキュリティコンテナでよく見られるロック機構です。これはタイマーの一種で、たとえ開錠者が正しいパスワードを知っていても、設定された時間が経過する前に金庫やボルトが開かれることを防ぐように設計されています。

ブロックチェーンでは、タイムロックは`DeFi`と`DAO`で広く採用されています。これは一段のコードで、スマートコントラクトの特定の機能を一定期間ロックできます。スマートコントラクトのセキュリティを大幅に向上させることができます。例えば、ハッカーが`Uniswap`のマルチシグをハックして金庫の資金を引き出そうとした場合、金庫コントラクトに2日間のロック期間のタイムロックが設定されていると、ハッカーが引き出しトランザクションを作成してから実際に資金を引き出すまでに2日間の待機期間が必要になります。この間、プロジェクト方は対応策を見つけることができ、投資者は事前にトークンを売却して損失を減らすことができます。

## タイムロックコントラクト

以下では、タイムロック`Timelock`コントラクトについて紹介します。そのロジックは複雑ではありません：

- `Timelock`コントラクトを作成する際、プロジェクト方はロック期間を設定し、コントラクトの管理者を自分に設定できます。

- タイムロックには主に3つの機能があります：
    - トランザクションを作成し、タイムロックキューに追加する。
    - トランザクションのロック期間満了後、トランザクションを実行する。
    - 後悔した場合、タイムロックキュー内の特定のトランザクションをキャンセルする。

- プロジェクト方は一般的にタイムロックコントラクトを重要なコントラクトの管理者に設定し（例：金庫コントラクト）、その後タイムロックを通してそれらを操作します。
- タイムロックコントラクトの管理者は一般的にプロジェクトのマルチシグウォレットであり、分散化を保証します。

### イベント
`Timelock`コントラクトには合計`4`つのイベントがあります。
- `QueueTransaction`：トランザクション作成およびタイムロックキュー参加イベント。
- `ExecuteTransaction`：ロック期間満了後のトランザクション実行イベント。
- `CancelTransaction`：トランザクションキャンセルイベント。
- `NewAdmin`：管理者アドレス変更イベント。

```solidity
    // イベント
    // トランザクションキャンセルイベント
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // トランザクション実行イベント
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // トランザクション作成およびキュー参加イベント
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    // 管理者アドレス変更イベント
    event NewAdmin(address indexed newAdmin);
```

### 状態変数
`Timelock`コントラクトには合計`4`つの状態変数があります。

- `admin`：管理者アドレス。
- `delay`：ロック期間。
- `GRACE_PERIOD`：トランザクション有効期限。トランザクションが実行時点に達しても`GRACE_PERIOD`内に実行されなかった場合、期限切れになります。
- `queuedTransactions`：タイムロックキューに参加したトランザクションの識別子`txHash`から`bool`へのマッピング、タイムロックキュー内のすべてのトランザクションを記録。

```solidity
    // 状態変数
    address public admin; // 管理者アドレス
    uint public constant GRACE_PERIOD = 7 days; // トランザクション有効期限、期限切れのトランザクションは無効
    uint public delay; // トランザクションロック時間（秒）
    mapping (bytes32 => bool) public queuedTransactions; // txHashからboolへ、タイムロックキュー内のすべてのトランザクションを記録
```

### 修飾子
`Timelock`コントラクトには合計`2`つの`modifier`があります。
- `onlyOwner()`：修飾された関数は管理者のみが実行可能。
- `onlyTimelock()`：修飾された関数はタイムロックコントラクトのみが実行可能。

```solidity
    // onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    // onlyTimelock modifier
    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;
    }
```

### 関数
`Timelock`コントラクトには合計`7`つの関数があります。

- コンストラクタ：トランザクションロック時間（秒）と管理者アドレスを初期化。
- `queueTransaction()`：トランザクションを作成してタイムロックキューに追加。パラメータは複雑で、完全なトランザクションを記述する必要があります：
    - `target`：対象コントラクトアドレス
    - `value`：送信ETH数量
    - `signature`：呼び出す関数シグネチャ（function signature）
    - `data`：トランザクションのcall data
    - `executeTime`：トランザクション実行のブロックチェーンタイムスタンプ。

    この関数を呼び出す際、トランザクション予定実行時間`executeTime`が現在のブロックチェーンタイムスタンプ+ロック時間`delay`より大きいことを保証する必要があります。トランザクションの一意識別子はすべてのパラメータのハッシュ値で、`getTxHash()`関数で計算されます。キューに参加したトランザクションは`queuedTransactions`変数で更新され、`QueueTransaction`イベントを発行します。
- `executeTransaction()`：トランザクションを実行。パラメータは`queueTransaction()`と同じです。実行されるトランザクションがタイムロックキューにあり、トランザクションの実行時間に達し、期限切れでないことが要求されます。トランザクション実行時には`solidity`の低級メンバー関数`call`を使用します（[第22講](https://github.com/AmazingAng/WTF-Solidity/blob/main/22_Call/readme.md)で紹介）。
- `cancelTransaction()`：トランザクションをキャンセル。パラメータは`queueTransaction()`と同じです。キャンセルされるトランザクションがキューにあることが要求され、`queuedTransactions`を更新して`CancelTransaction`イベントを発行します。
- `changeAdmin()`：管理者アドレスを変更、`Timelock`コントラクトのみが呼び出し可能。
- `getBlockTimestamp()`：現在のブロックチェーンタイムスタンプを取得。
- `getTxHash()`：トランザクションの識別子を返す、多くのトランザクションパラメータの`hash`。

```solidity
    /**
     * @dev コンストラクタ、トランザクションロック時間（秒）と管理者アドレスを初期化
     */
    constructor(uint delay_) {
        delay = delay_;
        admin = msg.sender;
    }

    /**
     * @dev 管理者アドレスを変更、呼び出し者はTimelockコントラクトである必要があります。
     */
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }

    /**
     * @dev トランザクションを作成してタイムロックキューに追加。
     * @param target: 対象コントラクトアドレス
     * @param value: 送信eth数量
     * @param signature: 呼び出す関数シグネチャ（function signature）
     * @param data: call data、内部にいくつかのパラメータがあります
     * @param executeTime: トランザクション実行のブロックチェーンタイムスタンプ
     *
     * 要求：executeTime は 現在のブロックチェーンタイムスタンプ+delay より大きい
     */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns (bytes32) {
        // チェック：トランザクション実行時間がロック時間を満たす
        require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        // トランザクションの一意識別子を計算：一堆東西のhash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // トランザクションをキューに追加
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, executeTime);
        return txHash;
    }

    /**
     * @dev 特定のトランザクションをキャンセル。
     *
     * 要求：トランザクションがタイムロックキューにある
     */
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner{
        // トランザクションの一意識別子を計算：一堆東西のhash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // チェック：トランザクションがタイムロックキューにある
        require(queuedTransactions[txHash], "Timelock::cancelTransaction: Transaction hasn't been queued.");
        // トランザクションをキューから削除
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }

    /**
     * @dev 特定のトランザクションを実行。
     *
     * 要求：
     * 1. トランザクションがタイムロックキューにある
     * 2. トランザクションの実行時間に達している
     * 3. トランザクションが期限切れでない
     */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // チェック：トランザクションがタイムロックキューにあるか
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        // チェック：トランザクションの実行時間に達しているか
        require(getBlockTimestamp() >= executeTime, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        // チェック：トランザクションが期限切れでないか
       require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
        // トランザクションをキューから削除
        queuedTransactions[txHash] = false;

        // call dataを取得
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // callを利用してトランザクションを実行
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);

        return returnData;
    }

    /**
     * @dev 現在のブロックチェーンタイムスタンプを取得
     */
    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev 一堆東西をまとめてトランザクションの識別子にする
     */
    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, executeTime));
    }
```

## `Remix`デモ
### 1. `Timelock`コントラクトをデプロイ、ロック期間を`120`秒に設定。

![`Remix`デモ](./img/45-1.jpg)

### 2. 直接`changeAdmin()`を呼び出すとエラーが発生。

![`Remix`デモ](./img/45-2.jpg)

### 3. 管理者変更トランザクションを構築。
トランザクションを構築するために、以下のパラメータをそれぞれ入力する必要があります：
address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime
- `target`：`Timelock`自体の関数を呼び出すため、コントラクトアドレスを入力。
- `value`：ETHを転送しないため、ここは`0`。
- `signature`：`changeAdmin()`の関数シグネチャ：`"changeAdmin(address)"`。
- `data`：ここに渡すパラメータ、つまり新しい管理者のアドレスを入力。ただし、アドレスを32バイトのデータに埋め込み、[イーサリアムABIエンコード標準](https://github.com/AmazingAng/WTF-Solidity/blob/main/27_ABIEncode/readme.md)を満たす必要があります。[hashex](https://abi.hashex.org/)サイトでパラメータのABIエンコードができます。例：
    ```solidity
    エンコード前アドレス：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    エンコード後アドレス：0x000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2
    ```
- `executeTime`：まず`getBlockTimestamp()`を呼び出して現在のブロックチェーン時間を取得し、その上に150秒追加して入力。
![`Remix`デモ](./img/45-3.jpg)

### 4. `queueTransaction`を呼び出して、トランザクションをタイムロックキューに配置。

![`Remix`デモ](./img/45-4.jpg)

### 5. ロック期間内に`executeTransaction`を呼び出すと、呼び出しに失敗。

![`Remix`デモ](./img/45-5.jpg)

### 6. ロック期間満了時に`executeTransaction`を呼び出すと、トランザクションが成功。

![`Remix`デモ](./img/45-6.jpg)

### 7. 新しい`admin`アドレスを確認。

![`Remix`デモ](./img/45-7.jpg)

## まとめ

タイムロックはスマートコントラクトの特定の機能を一定期間ロックし、プロジェクト方の`rug pull`やハッカー攻撃の機会を大幅に減らし、分散型アプリケーションのセキュリティを向上させることができます。`DeFi`と`DAO`で広く採用されており、`Uniswap`や`Compound`も含まれます。あなたが投資しているプロジェクトはタイムロックを使用していますか？