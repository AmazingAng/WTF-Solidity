---
title: 16. 関数のオーバーロード
tags:
  - solidity
  - advanced
  - wtfacademy
  - overloading
---

# WTF Solidity 超シンプル入門: 16. 関数のオーバーロード

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy\_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

## オーバーロード

`Solidity`ではオーバーロードは許可されています（`overloading`）、すなわち同名の関数は異なる関数として認識されます。特に注目すべきは、`Solidity`は修飾子（`modifier`）のオーバーロードを許容していない点です。

### 関数のオーバーロード

例えば，私たちは２つの`saySomething()`の関数を定義できます。一方は引数がなく、`return`値は`nothing`、もう一方は`string`方の引数を取り、その引数を`return`値としています。

```solidity
function saySomething() public pure returns(string memory){
    return("Nothing");
}

function saySomething(string memory something) public pure returns(string memory){
    return(something);
}
```

最終的に、オーバーロード関数はコンパイラによって異なる関数セレクタ（selector）に変換されます。関数セレクタについての詳細は[WTF Solidity 超シンプル入門: 29. 関数セレクタ Selector](https://github.com/AmazingAng/WTF-Solidity/tree/main/29_Selector)を参照してほしいです。

`Overloading.sol`コントラクトを例に取り、Remix でコンパイルしてデプロイした後、オーバーロード関数 `saySomething()` と `saySomething(string memory something)` をそれぞれ呼び出すと、異なる結果が返され、異なる関数として区別されることがわかります。

![16-1.jpg](./img/16-1.jpg)

### 引数のマッチング（Argument Matching）

オーバーロード関数を呼び出す際、入力された実際の引数と関数の引数の変数型が一致するかどうかがチェックされます。もし同じ型の複数のオーバーロード関数が存在する場合、エラーが発生します。以下の例では、`f()`という名前の関数が２つあります。一つは`uint8`型の引数を持ち、もう一つは`uint256`型の引数を持ちます。

```solidity
function f(uint8 _in) public pure returns (uint8 out) {
    out = _in;
}

function f(uint256 _in) public pure returns (uint256 out) {
    out = _in;
}
```

私たちは`f(50)`を呼び出すと、`50`は`uint8`にも`uint256`にも変換できるため、エラーが発生します。

## まとめ

今回は、`Solidity`での関数のオーバーロードの基本的な使い方を紹介しました。

- 名前が同じでも入力引数の型が異なる関数は同時に存在でき、それらは異なる関数として扱われます。
