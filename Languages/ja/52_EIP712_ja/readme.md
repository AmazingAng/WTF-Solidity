---
title: 52. EIP712 型付きデータ署名
tags:
  - solidity
  - erc20
  - eip712
  - openzepplin
---

# WTF Solidity 超シンプル入門: 52. EIP712 型付きデータ署名

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、より高度で安全な署名方法である EIP712 型付きデータ署名について紹介します。

## EIP712

以前、[EIP191 署名標準（personal sign）](https://github.com/AmazingAng/WTF-Solidity/blob/main/37_Signature/readme.md) について紹介しました。これはメッセージに署名することができますが、過度にシンプルです。署名データが複雑な場合、ユーザーは十六進文字列（データのハッシュ）しか見ることができず、署名内容が期待通りかどうかを確認することができません。

![image1](./img/52-1.png)

[EIP712型付きデータ署名](https://eips.ethereum.org/EIPS/eip-712)は、より高度で安全な署名方法です。EIP712 に対応した Dapp が署名を要求すると、ウォレットは署名メッセージの生データを表示し、ユーザーはデータが期待通りであることを確認してから署名することができます。

![image2](./img/52-2.png)

## EIP712 の使用方法

EIP712 の応用は一般的にオフチェーン署名（フロントエンドまたはスクリプト）とオンチェーン検証（コントラクト）の2つの部分を含みます。以下では、シンプルな例 `EIP712Storage` を使って EIP712 の使用方法を紹介します。`EIP712Storage` コントラクトには状態変数 `number` があり、EIP712 署名を検証してから変更することができます。

### オフチェーン署名

1. EIP712 署名には必ず `EIP712Domain` 部分が含まれている必要があります。これにはコントラクトの name、version（一般的に「1」と決められています）、chainId、および verifyingContract（署名を検証するコントラクトアドレス）が含まれます。

    ```js
    EIP712Domain: [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
    ]
    ```

    これらの情報はユーザーが署名する際に表示され、特定のチェーンの特定のコントラクトのみが署名を検証できることを保証します。スクリプトで対応するパラメータを渡す必要があります。

    ```js
    const domain = {
        name: "EIP712Storage",
        version: "1",
        chainId: "1",
        verifyingContract: "0xf8e81D47203A594245E36C48e151709F0C19fBe8",
    };
    ```

2. 使用場面に応じて署名のデータ型をカスタマイズする必要があり、コントラクトとマッチする必要があります。`EIP712Storage` の例では、`Storage` 型を定義しました。これには2つのメンバーがあります：`address` 型の `spender`（変数を修正できる呼び出し者を指定）、`uint256` 型の `number`（変数修正後の値を指定）。

    ```js
    const types = {
        Storage: [
            { name: "spender", type: "address" },
            { name: "number", type: "uint256" },
        ],
    };
    ```

3. `message` 変数を作成し、署名される型付きデータを渡します。

    ```js
    const message = {
        spender: "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        number: "100",
    };
    ```

    ![image3](./img/52-3.png)

4. ウォレットオブジェクトの `signTypedData()` メソッドを呼び出し、前の手順の `domain`、`types`、`message` 変数を渡して署名します（ここでは `ethersjs v6` を使用）。

    ```js
    // providerを取得
    const provider = new ethers.BrowserProvider(window.ethereum)
    // signerを取得してsignTypedDataメソッドを呼び出してeip712署名を行う
    const signature = await signer.signTypedData(domain, types, message);
    console.log("Signature:", signature);
    ```

    ![image4](./img/52-4.png)

### オンチェーン検証

次は `EIP712Storage` コントラクトの部分です。署名を検証し、通過すれば `number` 状態変数を修正します。5つの状態変数があります。

1. `EIP712DOMAIN_TYPEHASH`: `EIP712Domain` の型ハッシュ、定数。
2. `STORAGE_TYPEHASH`: `Storage` の型ハッシュ、定数。
3. `DOMAIN_SEPARATOR`: 各ドメイン（Dapp）の署名に混合されるユニークな値で、`EIP712DOMAIN_TYPEHASH` および `EIP712Domain`（name、version、chainId、verifyingContract）から構成され、`constructor()` で初期化されます。
4. `number`: コントラクト内の保存値の状態変数で、`permitStore()` メソッドで修正できます。
5. `owner`: コントラクトの所有者で、`constructor()` で初期化され、`permitStore()` メソッドで署名の有効性を検証します。

また、`EIP712Storage` コントラクトには3つの関数があります。

1. コンストラクタ: `DOMAIN_SEPARATOR` と `owner` を初期化します。
2. `retrieve()`: `number` の値を読み取ります。
3. `permitStore`: EIP712 署名を検証し、`number` の値を修正します。まず、署名を `r`、`s`、`v` に分解します。次に `DOMAIN_SEPARATOR`、`STORAGE_TYPEHASH`、呼び出し者アドレス、入力された `_num` パラメータを使って署名のメッセージテキスト `digest` を構築します。最後に `ECDSA` の `recover()` メソッドを使って署名者アドレスを復元し、署名が有効であれば `number` の値を更新します。

```solidity
// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Storage {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    bytes32 private DOMAIN_SEPARATOR;
    uint256 number;
    address owner;

    constructor(){
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH, // 型ハッシュ
            keccak256(bytes("EIP712Storage")), // name
            keccak256(bytes("1")), // version
            block.chainid, // chain id
            address(this) // コントラクトアドレス
        ));
        owner = msg.sender;
    }

    /**
     * @dev 変数に値を保存
     */
    function permitStore(uint256 _num, bytes memory _signature) public {
        // 署名の長さをチェック、65は標準のr,s,v署名の長度
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 現在、assembly（インラインアセンブリ）のみで署名からr,s,vの値を取得可能
        assembly {
            /*
            最初の32bytesは署名の長さを保存（動的配列の保存規則）
            add(sig, 32) = sigのポインタ + 32
            signatureの最初の32bytesをスキップすることと同等
            mload(p) メモリアドレスpから開始する次の32bytesのデータをロード
            */
            // 長さデータ後の32bytesを読み取る
            r := mload(add(_signature, 0x20))
            // その後の32bytesを読み取る
            s := mload(add(_signature, 0x40))
            // 最後の1byteを読み取る
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // 署名メッセージハッシュを取得
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
        ));

        address signer = digest.recover(v, r, s); // 署名者を復元
        require(signer == owner, "EIP712Storage: Invalid signature"); // 署名をチェック

        // 状態変数を修正
        number = _num;
    }

    /**
     * @dev 値を返す
     * @return 'number'の値
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}
```

## デプロイと復現

1. `Remix` で `EIP712Storage` コントラクトをデプロイします。

2. `eip712storage.html` を実行します。ブラウザのコンテンツセキュリティポリシー（[Content Security Policy](https://github.com/MetaMask/faq/blob/9257d7d52784afa957c12166aff20682cf692ae5/DEVELOPERS.md#requirements-nut_and_bolt)）の要件により、MetaMaskはローカルファイル（file:// プロトコル）を開いてDAppと通信することができません。Node静的ファイルサーバー `http-server` を使用してローカルサービスを開始し、`eip712storage.html` ファイルが含まれるディレクトリで以下のコマンドを実行します：

    ```sh
    npm install -g http-server
    http-server
    ```

    ブラウザで `http://127.0.0.1:8080` を開くとアクセスできます。その後、`Contract Address` をデプロイした `EIP712Storage` コントラクトアドレスに変更し、順番に `Connect Metamask` と `Sign Permit` ボタンをクリックして署名します。署名にはコントラクトをデプロイしたウォレットを使用する必要があります。例えば Remix テストウォレット：

    ```js
    public_key: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    private_key: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
    ```

3. コントラクトの `permitStore()` メソッドを呼び出し、対応する `_num` と署名を入力して `number` の値を修正します。

4. コントラクトの `retrieve()` メソッドを呼び出すと、`number` の値が変更されていることがわかります。

## まとめ

今回は、EIP712 型付きデータ署名について紹介しました。これはより高度で安全な署名標準です。署名を要求する際、ウォレットは署名メッセージの生データを表示し、ユーザーはデータを検証してから署名することができます。この標準は広く応用されており、Metamask、Uniswap token pairs、DAI stablecoin などのシナリオで使用されています。皆さんによく習得していただきたいと思います。