# WTF Solidity 超シンプル入門: 50. マルチシグウォレット

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

Vitalik氏は、マルチシグウォレットはハードウェアウォレットよりも安全だと述べています（[ツイート](https://twitter.com/VitalikButerin/status/1558886893995134978?s=20&t=4WyoEWhwHNUtAuABEIlcRw)）。この講義では、マルチシグウォレットについて説明し、極めてシンプルなマルチシグウォレットコントラクトを作成します。教育用コード（150行のコード）は、gnosis safeコントラクト（数千行のコード）を簡略化したものです。

![Vitalikの発言](./img/50-1.png)

## マルチシグウォレット

マルチシグウォレットは、複数の秘密鍵保有者（マルチシグ者）によってトランザクションが承認された後にのみ実行される電子ウォレットです。例えば、ウォレットが3人のマルチシグ者によって管理され、各トランザクションには少なくとも2人の署名承認が必要です。マルチシグウォレットは単一障害点（秘密鍵の紛失、単独での不正行為）を防ぎ、より分散化され、より安全で、多くのDAOに採用されています。

Gnosis Safeマルチシグウォレットは、イーサリアムで最も人気のあるマルチシグウォレットで、約400億ドルの資産を管理しており、コントラクトは監査と実戦テストを経て、マルチチェーン（イーサリアム、BSC、Polygonなど）をサポートし、豊富なDAPPサポートを提供しています。詳細については、私が21年12月に書いた[Gnosis Safe使用チュートリアル](https://peopledao.mirror.xyz/nFCBXda8B5ZxQVqSbbDOn2frFDpTxNVtdqVBXGIjj0s)をご覧ください。

## マルチシグウォレットコントラクト

イーサリアム上のマルチシグウォレットは実際にはスマートコントラクトで、コントラクトウォレットに属します。以下では、極めてシンプルなマルチシグウォレット`MultisigWallet`コントラクトを作成します。そのロジックは非常にシンプルです：

1. マルチシグ者と閾値を設定（オンチェーン）：マルチシグコントラクトをデプロイする際、マルチシグ者リストと実行閾値（少なくともn人のマルチシグ者の署名承認後、トランザクションが実行可能）を初期化する必要があります。Gnosis Safeマルチシグウォレットはマルチシグ者の追加/削除および実行閾値の変更をサポートしていますが、私たちの極めてシンプルなバージョンではこの機能は考慮していません。

2. トランザクションの作成（オフチェーン）：承認待ちのトランザクションには以下の内容が含まれます：
    - `to`：ターゲットコントラクト。
    - `value`：トランザクションで送信するイーサリアムの量。
    - `data`：calldata、呼び出し関数のセレクターとパラメータを含む。
    - `nonce`：初期値は`0`、マルチシグコントラクトの各成功実行トランザクションとともに増加する値で、署名リプレイ攻撃を防ぐ。
    - `chainid`：チェーンID、異なるチェーンの署名リプレイ攻撃を防ぐ。

3. マルチシグ署名の収集（オフチェーン）：前のステップのトランザクションをABIエンコードしてハッシュを計算し、トランザクションハッシュを取得し、マルチシグ者に署名してもらい、それらを連結してパック署名を得ます。ABIエンコードとハッシュについて理解していない場合は、WTF Solidity超シンプル入門[第27講](https://github.com/AmazingAng/WTF-Solidity/blob/main/27_ABIEncode/readme.md)と[第28講](https://github.com/AmazingAng/WTF-Solidity/blob/main/28_Hash/readme.md)をご覧ください。

    ```solidity
    トランザクションハッシュ: 0xc1b055cf8e78338db21407b425114a2e258b0318879327945b661bfdea570e66

    マルチシグ者A署名: 0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11c

    マルチシグ者B署名: 0xbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c

    パック署名：
    0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11cbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c
    ```

4. マルチシグコントラクトの実行関数を呼び出し、署名を検証してトランザクションを実行（オンチェーン）。署名検証とトランザクション実行について理解していない場合は、WTF Solidity超シンプル入門[第22講](https://github.com/AmazingAng/WTF-Solidity/blob/main/22_Call/readme.md)と[第37講](https://github.com/AmazingAng/WTF-Solidity/blob/main/37_Signature/readme.md)をご覧ください。

### イベント

`MultisigWallet`コントラクトには2つのイベント、`ExecutionSuccess`と`ExecutionFailure`があり、それぞれトランザクションの成功と失敗時に発行され、パラメータはトランザクションハッシュです。

```solidity
    event ExecutionSuccess(bytes32 txHash);    // トランザクション成功イベント
    event ExecutionFailure(bytes32 txHash);    // トランザクション失敗イベント
```

### 状態変数

`MultisigWallet`コントラクトには5つの状態変数があります：
1. `owners`：マルチシグ保有者配列
2. `isOwner`：`address => bool`のマッピング、アドレスがマルチシグ保有者かどうかを記録。
3. `ownerCount`：マルチシグ保有者数
4. `threshold`：マルチシグ実行閾値、トランザクションは少なくともn人のマルチシグ者の署名がなければ実行できない。
5. `nonce`：初期値は`0`、マルチシグコントラクトの各成功実行トランザクションとともに増加する値で、署名リプレイ攻撃を防ぐ。

```solidity
    address[] public owners;                   // マルチシグ保有者配列
    mapping(address => bool) public isOwner;   // アドレスがマルチシグ保有者かどうかを記録
    uint256 public ownerCount;                 // マルチシグ保有者数
    uint256 public threshold;                  // マルチシグ実行閾値、トランザクションは少なくともn人のマルチシグ者の署名がなければ実行できない
    uint256 public nonce;                      // nonce、署名リプレイ攻撃を防ぐ
```

### 関数

`MultisigWallet`コントラクトには6つの関数があります：

1. コンストラクタ：`_setupOwners()`を呼び出し、マルチシグ保有者と実行閾値に関連する変数を初期化。
    ```solidity
    // コンストラクタ、owners, isOwner, ownerCount, thresholdを初期化
    constructor(
        address[] memory _owners,
        uint256 _threshold
    ) {
        _setupOwners(_owners, _threshold);
    }
    ```

2. `_setupOwners()`：コントラクトデプロイ時にコンストラクタによって呼び出され、`owners`、`isOwner`、`ownerCount`、`threshold`状態変数を初期化。渡されるパラメータで、実行閾値は1以上でマルチシグ者数以下である必要があります。マルチシグアドレスは`0`アドレスであってはならず、重複してもいけません。
    ```solidity
    /// @dev owners, isOwner, ownerCount, thresholdを初期化
    /// @param _owners: マルチシグ保有者配列
    /// @param _threshold: マルチシグ実行閾値、少なくとも何人のマルチシグ者がトランザクションに署名したか
    function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // thresholdが初期化されていない
        require(threshold == 0, "WTF5000");
        // マルチシグ実行閾値がマルチシグ者数以下
        require(_threshold <= _owners.length, "WTF5001");
        // マルチシグ実行閾値が少なくとも1
        require(_threshold >= 1, "WTF5002");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            // マルチシグ者は0アドレス、本コントラクトアドレス、重複であってはならない
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "WTF5003");
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }
    ```

3. `execTransaction()`：十分なマルチシグ署名を収集した後、署名を検証してトランザクションを実行。渡されるパラメータは、ターゲットアドレス`to`、送信するイーサリアム量`value`、データ`data`、およびパック署名`signatures`。パック署名は、収集したマルチシグ者のトランザクションハッシュに対する署名を、マルチシグ保有者アドレスの昇順に[bytes]データにパックしたものです。このステップでは`encodeTransactionData()`を呼び出してトランザクションをエンコードし、`checkSignatures()`を呼び出して署名が有効で数量が実行閾値に達しているかを検証します。

    ```solidity
    /// @dev 十分なマルチシグ署名を収集した後、トランザクションを実行
    /// @param to ターゲットコントラクトアドレス
    /// @param value msg.value、支払うイーサリアム
    /// @param data calldata
    /// @param signatures パック署名、対応するマルチシグアドレスは小から大の順序で、チェックを容易にする。 ({bytes32 r}{bytes32 s}{uint8 v}) (第1マルチシグの署名, 第2マルチシグの署名 ... )
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        // トランザクションデータをエンコードし、ハッシュを計算
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;  // nonceを増加
        checkSignatures(txHash, signatures); // 署名をチェック
        // callを利用してトランザクションを実行し、トランザクション結果を取得
        (success, ) = to.call{value: value}(data);
        require(success , "WTF5004");
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }
    ```

4. `checkSignatures()`：署名とトランザクションデータのハッシュが対応し、数量が閾値に達しているかをチェックし、そうでなければトランザクションはrevertします。単一の署名の長さは65バイトなので、パック署名の長さは`threshold * 65`以上である必要があります。`signatureSplit()`を呼び出して単一の署名を分離します。この関数の大まかな考え方：
    - ecdsaを使用して署名アドレスを取得。
    - `currentOwner > lastOwner`を利用して署名が異なるマルチシグからのもの（マルチシグアドレス昇順）であることを確認。
    - `isOwner[currentOwner]`を利用して署名者がマルチシグ保有者であることを確認。

    ```solidity
    /**
     * @dev 署名とトランザクションデータが対応しているかをチェック。無効な署名の場合、トランザクションはrevert
     * @param dataHash トランザクションデータハッシュ
     * @param signatures 複数のマルチシグ署名をパックしたもの
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // マルチシグ実行閾値を読み取り
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");

        // 署名の長さが十分であることをチェック
        require(signatures.length >= _threshold * 65, "WTF5006");

        // ループを通じて、収集した署名が有効かをチェック
        // 大まかな考え方：
        // 1. ecdsaでまず署名が有効かを検証
        // 2. currentOwner > lastOwnerを利用して署名が異なるマルチシグからのもの（マルチシグアドレス昇順）であることを確認
        // 3. isOwner[currentOwner]を利用して署名者がマルチシグ保有者であることを確認
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // ecrecoverを利用して署名が有効かをチェック
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
            lastOwner = currentOwner;
        }
    }
    ```

5. `signatureSplit()`：パック署名から単一の署名を分離、パラメータはそれぞれパック署名`signatures`と読み取る署名位置`pos`。インラインアセンブリを利用して、署名の`r`、`s`、`v`の3つの値を分離。

    ```solidity
    /// 単一の署名をパック署名から分離
    /// @param signatures パック署名
    /// @param pos 読み取るマルチシグインデックス
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // 署名の形式：{bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
    ```

6. `encodeTransactionData()`：トランザクションデータをパックしてハッシュを計算、`abi.encode()`と`keccak256()`関数を利用。この関数はトランザクションのハッシュを計算でき、その後オフチェーンでマルチシグ者に署名してもらい収集し、再度`execTransaction()`関数を呼び出して実行します。

    ```solidity
    /// @dev トランザクションデータをエンコード
    /// @param to ターゲットコントラクトアドレス
    /// @param value msg.value、支払うイーサリアム
    /// @param data calldata
    /// @param _nonce トランザクションのnonce
    /// @param chainid チェーンID
    /// @return トランザクションハッシュbytes
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                )
            );
        return safeTxHash;
    }
    ```

## `Remix`デモ

1. マルチシグコントラクトをデプロイ、2つのマルチシグアドレス、トランザクション実行閾値を2に設定。

    ```solidity
    マルチシグアドレス1: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    マルチシグアドレス2: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    ```

    ![デプロイ](./img/50-2.png)

2. マルチシグコントラクトアドレスに`1 ETH`を送金。

    ![送金](./img/50-3.png)

3. `encodeTransactionData()`を呼び出し、マルチシグアドレス1に`1 ETH`を送金するトランザクションをエンコードしてハッシュを計算。

    ```solidity
    パラメータ
    to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    value: 1000000000000000000
    data: 0x
    _nonce: 0
    chainid: 1

    結果
    トランザクションハッシュ： 0xb43ad6901230f2c59c3f7ef027c9a372f199661c61beeec49ef5a774231fc39b
    ```

    ![トランザクションハッシュ計算](./img/50-4.png)

4. RemixのACCOUNTの横にあるペンアイコンのボタンを利用して署名し、内容に上記のトランザクションハッシュを入力して署名を取得、2つのウォレットとも署名が必要。
    ```
    マルチシグアドレス1の署名: 0xa3f3e4375f54ad0a8070f5abd64e974b9b84306ac0dd5f59834efc60aede7c84454813efd16923f1a8c320c05f185bd90145fd7a7b741a8d13d4e65a4722687e1b

    マルチシグアドレス2の署名: 0x6b228b6033c097e220575f826560226a5855112af667e984aceca50b776f4c885e983f1f2155c294c86a905977853c6b1bb630c488502abcc838f9a225c813811c

    2つの署名を連結してパック署名を取得:  0xa3f3e4375f54ad0a8070f5abd64e974b9b84306ac0dd5f59834efc60aede7c84454813efd16923f1a8c320c05f185bd90145fd7a7b741a8d13d4e65a4722687e1b6b228b6033c097e220575f826560226a5855112af667e984aceca50b776f4c885e983f1f2155c294c86a905977853c6b1bb630c488502abcc838f9a225c813811c
    ```

    ![署名](./img/50-5.png)

5. `execTransaction()`関数を呼び出してトランザクションを実行、第3ステップのトランザクションパラメータとパック署名をパラメータとして渡す。トランザクションが正常に実行され、`ETH`がマルチシグから送金されることがわかります。

    ![マルチシグウォレットトランザクション実行](./img/50-6.png)

## まとめ

この講義では、マルチシグウォレットについて説明し、150行未満のコードで極めてシンプルなマルチシグウォレットコントラクトを作成しました。

私はマルチシグウォレットとは深い縁があり、2021年にPeopleDAO国庫作成のためにGnosis Safeを学習し、中英文の[使用チュートリアル](https://peopledao.mirror.xyz/nFCBXda8B5ZxQVqSbbDOn2frFDpTxNVtdqVBXGIjj0s)を書き、その後幸運にも3つの国庫のマルチシグ者として資産安全を維持し、現在はSafeのガーディアンとしてガバナンスに深く参与しています。皆さんの資産がより安全になることを願っています。