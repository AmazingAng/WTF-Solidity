# WTF Solidity 超シンプル入門: 49. 汎用アップグレード可能プロキシ

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

この講義では、プロキシコントラクトにおけるセレクター衝突（Selector Clash）のもう一つの解決方法である汎用アップグレード可能プロキシ（UUPS、universal upgradeable proxy standard）について説明します。教育用のコードは`OpenZeppelin`の`UUPSUpgradeable`を簡略化したもので、本番環境での使用は適していません。

## UUPS

[前回の講義](https://github.com/AmazingAng/WTF-Solidity/blob/main/48_TransparentProxy/readme.md)で「セレクター衝突」（Selector Clash）について学習しました。これは、コントラクトに同じセレクターを持つ2つの関数が存在することで、深刻な結果を招く可能性があります。透明プロキシの代替案として、UUPSもこの問題を解決できます。

UUPS（universal upgradeable proxy standard、汎用アップグレード可能プロキシ）は、アップグレード関数をロジックコントラクト内に配置します。これにより、他の関数とアップグレード関数の間に「セレクター衝突」が存在する場合、コンパイル時にエラーが報告されます。

以下の表では、通常のアップグレード可能コントラクト、透明プロキシ、およびUUPSの違いをまとめています：

![各種アップグレードコントラクト](./img/49-1.png)

## UUPSコントラクト

まず、[WTF Solidity超シンプル入門第23講：Delegatecall](https://github.com/AmazingAng/WTF-Solidity/blob/main/23_Delegatecall/readme.md)を復習しましょう。ユーザーAがコントラクトB（プロキシコントラクト）を通してコントラクトC（ロジックコントラクト）を`delegatecall`する場合、コンテキストは依然としてコントラクトBのコンテキストであり、`msg.sender`は依然としてユーザーAでありコントラクトBではありません。したがって、UUPSコントラクトはアップグレード関数をロジックコントラクト内に配置し、呼び出し者が管理者であるかどうかをチェックできます。

![delegatecall](./img/49-2.png)

### UUPSのプロキシコントラクト

UUPSのプロキシコントラクトは、アップグレード不可能なプロキシコントラクトのように見え、非常にシンプルです。アップグレード関数がロジックコントラクト内に配置されているためです。3つの変数を含みます：
- `implementation`：ロジックコントラクトのアドレス。
- `admin`：管理者アドレス。
- `words`：文字列、ロジックコントラクトの関数で変更可能。

2つの関数を含みます：

- コンストラクタ：管理者とロジックコントラクトのアドレスを初期化。
- `fallback()`：コールバック関数、呼び出しをロジックコントラクトに委譲。

```solidity
contract UUPSProxy {
    address public implementation; // ロジックコントラクトのアドレス
    address public admin; // 管理者アドレス
    string public words; // 文字列、ロジックコントラクトの関数で変更可能

    // コンストラクタ、管理者とロジックコントラクトのアドレスを初期化
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback関数、呼び出しをロジックコントラクトに委譲
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
}
```

### UUPSのロジックコントラクト

UUPSのロジックコントラクトと[第47講](https://github.com/AmazingAng/WTF-Solidity/blob/main/47_Upgrade/readme.md)のものとの違いは、アップグレード関数が追加されていることです。UUPSロジックコントラクトは3つの状態変数を含み、プロキシコントラクトと一致させてスロット衝突を防ぎます。2つの関数を含みます：
- `upgrade()`：アップグレード関数、ロジックコントラクトのアドレス`implementation`を変更、`admin`のみ呼び出し可能。
- `foo()`：旧UUPSロジックコントラクトは`words`の値を`"old"`に変更し、新しいものは`"new"`に変更。

```solidity
// UUPSロジックコントラクト（アップグレード関数がロジックコントラクト内に記述）
contract UUPS1{
    // 状態変数をプロキシコントラクトと一致させ、スロット衝突を防ぐ
    address public implementation;
    address public admin;
    string public words; // 文字列、ロジックコントラクトの関数で変更可能

    // プロキシ内の状態変数を変更、セレクター： 0xc2985578
    function foo() public{
        words = "old";
    }

    // アップグレード関数、ロジックコントラクトのアドレスを変更、管理者のみ呼び出し可能。セレクター：0x0900f010
    // UUPSでは、ロジックコントラクト内にアップグレード関数が必要、そうでなければ再度アップグレードできません。
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// 新UUPSロジックコントラクト
contract UUPS2{
    // 状態変数をプロキシコントラクトと一致させ、スロット衝突を防ぐ
    address public implementation;
    address public admin;
    string public words; // 文字列、ロジックコントラクトの関数で変更可能

    // プロキシ内の状態変数を変更、セレクター： 0xc2985578
    function foo() public{
        words = "new";
    }

    // アップグレード関数、ロジックコントラクトのアドレスを変更、管理者のみ呼び出し可能。セレクター：0x0900f010
    // UUPSでは、ロジックコントラクト内にアップグレード関数が必要、そうでなければ再度アップグレードできません。
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```

## `Remix`での実装

1. UUPS新旧ロジックコントラクト`UUPS1`と`UUPS2`をデプロイします。

![demo](./img/49-3.jpg)

2. UUPSプロキシコントラクト`UUPSProxy`をデプロイし、`implementation`アドレスを旧ロジックコントラクト`UUPS1`に指定します。

![demo](./img/49-4.jpg)

3. セレクター`0xc2985578`を使用して、プロキシコントラクト内で旧ロジックコントラクト`UUPS1`の`foo()`関数を呼び出し、`words`の値を`"old"`に変更します。

![demo](./img/49-5.jpg)

4. オンラインABIエンコーダー[HashEx](https://abi.hashex.org/)を使用してバイナリエンコーディングを取得し、アップグレード関数`upgrade()`を呼び出して、`implementation`アドレスを新ロジックコントラクト`UUPS2`に指定します。

![エンコーディング](./img/49-3.png)

![demo](./img/49-6.jpg)

5. セレクター`0xc2985578`を使用して、プロキシコントラクト内で新ロジックコントラクト`UUPS2`の`foo()`関数を呼び出し、`words`の値を`"new"`に変更します。

![demo](./img/49-7.jpg)

## まとめ

この講義では、プロキシコントラクトの「セレクター衝突」のもう一つの解決策であるUUPSについて説明しました。透明プロキシとは異なり、UUPSはアップグレード関数をロジックコントラクト内に配置することで、「セレクター衝突」がコンパイルを通過できないようにします。透明プロキシと比較して、UUPSはガス効率が良いですが、より複雑でもあります。