# WTF Solidity 超シンプル入門: 48. 透明プロキシ

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

この講義では、プロキシコントラクトのセレクター衝突（Selector Clash）と、この問題の解決策である透明プロキシ（Transparent Proxy）について説明します。教育用のコードは`OpenZeppelin`の[TransparentUpgradeableProxy](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/transparent/TransparentUpgradeableProxy.sol)を簡略化したもので、本番環境での使用は適していません。

## セレクター衝突

スマートコントラクトにおいて、関数セレクター（selector）は関数シグネチャのハッシュの最初の4バイトです。例えば`mint(address account)`のセレクターは`bytes4(keccak256("mint(address)"))`、つまり`0x6a627842`です。セレクターについての詳細は[WTF Solidity超シンプル入門第29講：関数セレクター](https://github.com/AmazingAng/WTF-Solidity/blob/main/29_Selector/readme.md)を参照してください。

関数セレクターは4バイトのみで範囲が小さいため、異なる2つの関数が同じセレクターを持つ可能性があります。以下の例をご覧ください：

```solidity
// セレクター衝突の例
contract Foo {
    function burn(uint256) external {}
    function collate_propagate_storage(bytes16) external {}
}
```

![48-1.png](./img/48-1.png)

この例では、関数`burn()`と`collate_propagate_storage()`のセレクターは共に`0x42966c68`で同じです。この状況を「セレクター衝突」と呼びます。この場合、`EVM`は関数セレクターによってユーザーがどの関数を呼び出したいかを判別できないため、このコントラクトはコンパイルできません。

プロキシコントラクトとロジックコントラクトは2つの別々のコントラクトなので、それらの間に「セレクター衝突」があっても正常にコンパイルできますが、これは深刻なセキュリティ事故を引き起こす可能性があります。例えば、ロジックコントラクトの`a`関数とプロキシコントラクトのアップグレード関数のセレクターが同じ場合、管理者が`a`関数を呼び出すときに、プロキシコントラクトがブラックホールコントラクトにアップグレードされてしまうという深刻な結果を招く可能性があります。

現在、この問題を解決する2つのアップグレード可能なコントラクト標準があります：透明プロキシ`Transparent Proxy`と汎用アップグレード可能プロキシ`UUPS`です。

## 透明プロキシ

透明プロキシのロジックは非常にシンプルです：管理者が「関数セレクター衝突」によってロジックコントラクトの関数を呼び出すときに、プロキシコントラクトのアップグレード関数を誤って呼び出してしまう可能性があります。そこで管理者の権限を制限し、ロジックコントラクトの関数を一切呼び出せないようにすることで衝突を解決します：

- 管理者は道具役となり、プロキシコントラクトのアップグレード関数のみを呼び出してコントラクトをアップグレードでき、コールバック関数を通じてロジックコントラクトを呼び出すことはできません。
- その他のユーザーはアップグレード関数を呼び出せませんが、ロジックコントラクトの関数は呼び出せます。

### プロキシコントラクト

ここのプロキシコントラクトは[第47講](https://github.com/AmazingAng/WTF-Solidity/blob/main/47_Upgrade/readme.md)のものと非常に似ていますが、`fallback()`関数が管理者アドレスの呼び出しを制限している点が異なります。

3つの変数を含みます：
- `implementation`：ロジックコントラクトのアドレス。
- `admin`：管理者アドレス。
- `words`：文字列、ロジックコントラクトの関数で変更可能。

3つの関数を含みます：

- コンストラクタ：管理者とロジックコントラクトのアドレスを初期化。
- `fallback()`：コールバック関数、呼び出しをロジックコントラクトに委譲、`admin`は呼び出し不可。
- `upgrade()`：アップグレード関数、ロジックコントラクトのアドレスを変更、`admin`のみ呼び出し可能。

```solidity
// 透明アップグレード可能コントラクトの教育用コード、本番環境では使用しないでください。
contract TransparentProxy {
    address implementation; // ロジックコントラクトのアドレス
    address admin; // 管理者
    string public words; // 文字列、ロジックコントラクトの関数で変更可能

    // コンストラクタ、管理者とロジックコントラクトのアドレスを初期化
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback関数、呼び出しをロジックコントラクトに委譲
    // 管理者は呼び出し不可、セレクター衝突による事故を回避
    fallback() external payable {
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // アップグレード関数、ロジックコントラクトのアドレスを変更、管理者のみ呼び出し可能
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
}
```

### ロジックコントラクト

ここの新旧ロジックコントラクトは[第47講](https://github.com/AmazingAng/WTF-Solidity/blob/main/47_Upgrade/readme.md)と同じです。ロジックコントラクトは3つの状態変数を含み、プロキシコントラクトと一致させてスロット衝突を防ぎます。関数`foo()`を1つ含み、旧ロジックコントラクトは`words`の値を`"old"`に変更し、新しいものは`"new"`に変更します。

```solidity
// 旧ロジックコントラクト
contract Logic1 {
    // 状態変数をプロキシコントラクトと一致させ、スロット衝突を防ぐ
    address public implementation;
    address public admin;
    string public words; // 文字列、ロジックコントラクトの関数で変更可能

    // プロキシ内の状態変数を変更、セレクター： 0xc2985578
    function foo() public{
        words = "old";
    }
}

// 新ロジックコントラクト
contract Logic2 {
    // 状態変数をプロキシコントラクトと一致させ、スロット衝突を防ぐ
    address public implementation;
    address public admin;
    string public words; // 文字列、ロジックコントラクトの関数で変更可能

    // プロキシ内の状態変数を変更、セレクター：0xc2985578
    function foo() public{
        words = "new";
    }
}
```

## `Remix`での実装

1. 新旧ロジックコントラクト`Logic1`と`Logic2`をデプロイします。
![48-2.png](./img/48-2.png)
![48-3.png](./img/48-3.png)

2. 透明プロキシコントラクト`TranparentProxy`をデプロイし、`implementation`アドレスを旧ロジックコントラクトに指定します。
![48-4.png](./img/48-4.png)

3. セレクター`0xc2985578`を使用して、プロキシコントラクト内で旧ロジックコントラクト`Logic1`の`foo()`関数を呼び出します。管理者はロジックコントラクトを呼び出せないため、呼び出しは失敗します。
![48-5.png](./img/48-5.png)

4. 新しいウォレットに切り替えて、セレクター`0xc2985578`を使用し、プロキシコントラクト内で旧ロジックコントラクト`Logic1`の`foo()`関数を呼び出し、`words`の値を`"old"`に変更します。呼び出しは成功します。
![48-6.png](./img/48-6.png)

5. 管理者ウォレットに戻り、`upgrade()`を呼び出して、`implementation`アドレスを新ロジックコントラクト`Logic2`に指定します。
![48-7.png](./img/48-7.png)

6. 新しいウォレットに切り替えて、セレクター`0xc2985578`を使用し、プロキシコントラクト内で新ロジックコントラクト`Logic2`の`foo()`関数を呼び出し、`words`の値を`"new"`に変更します。
![48-8.png](./img/48-8.png)

## まとめ

この講義では、プロキシコントラクトにおける「セレクター衝突」と、透明プロキシを使用してこの問題を回避する方法について説明しました。透明プロキシのロジックはシンプルで、管理者がロジックコントラクトを呼び出すことを制限することで「セレクター衝突」問題を解決します。欠点もあり、ユーザーが関数を呼び出すたびに管理者かどうかの追加チェックが行われ、より多くのガスを消費します。しかし、瑕疵を補って余りある利点があり、透明プロキシは依然として多くのプロジェクトが選択するソリューションです。

次回の講義では、ガス効率が良いがより複雑な汎用アップグレード可能プロキシ`UUPS`について説明します。