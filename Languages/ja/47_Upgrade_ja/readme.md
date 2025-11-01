---
title: 47. アップグレード可能コントラクト
tags:
  - solidity
  - proxy
  - OpenZeppelin

---

# WTF Solidity 超シンプル入門: 47. アップグレード可能コントラクト

最近、Solidityを再学習しており、詳細を確認しながら「WTF Solidity 超シンプル入門」を執筆しています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週1〜3レッスンのペースで更新していきます。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat グループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはGitHubにて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、アップグレード可能コントラクト（Upgradeable Contract）について説明します。教材で使用するコントラクトは`OpenZeppelin`のコントラクトを簡略化したもので、セキュリティ上の問題がある可能性があるため、本番環境では使用しないでください。

## アップグレード可能コントラクト

プロキシコントラクトを理解していれば、アップグレード可能コントラクトを理解するのは簡単です。これはロジックコントラクトを変更できるプロキシコントラクトです。

![アップグレード可能パターン](./img/47-1.png)

## シンプルな実装

以下、シンプルなアップグレード可能コントラクトを実装します。これには`3`つのコントラクトが含まれます：プロキシコントラクト、旧ロジックコントラクト、新ロジックコントラクトです。

### プロキシコントラクト

このプロキシコントラクトは[第46回](https://github.com/AmazingAng/WTF-Solidity/blob/main/46_ProxyContract/readme.md)のものよりシンプルです。`fallback()`関数で`インラインアセンブリ`を使用せず、単に`implementation.delegatecall(msg.data);`を使用しています。そのため、フォールバック関数には返り値がありませんが、教材としては十分です。

`3`つの変数を含みます：

- `implementation`：ロジックコントラクトのアドレス
- `admin`：管理者アドレス
- `words`：文字列、ロジックコントラクトの関数を通じて変更可能

`3`つの関数を含みます：

- コンストラクタ：管理者とロジックコントラクトのアドレスを初期化
- `fallback()`：フォールバック関数、呼び出しをロジックコントラクトに委託
- `upgrade()`：アップグレード関数、ロジックコントラクトのアドレスを変更、`admin`のみが呼び出し可能

```solidity
// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// シンプルなアップグレード可能コントラクト、管理者はアップグレード関数を通じてロジックコントラクトアドレスを変更でき、
// それによりコントラクトのロジックを変更できる
// 教材デモ用、本番環境では使用しないでください
contract SimpleUpgrade {
    address public implementation; // ロジックコントラクトアドレス
    address public admin; // 管理者アドレス
    string public words; // 文字列、ロジックコントラクトの関数を通じて変更可能

    // コンストラクタ、管理者とロジックコントラクトアドレスを初期化
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback関数、呼び出しをロジックコントラクトに委託
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // アップグレード関数、ロジックコントラクトアドレスを変更、管理者のみ呼び出し可能
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```

### 旧ロジックコントラクト

このロジックコントラクトには`3`つの状態変数が含まれ、プロキシコントラクトと一致させてスロット競合を防ぎます。`foo()`関数が1つだけあり、プロキシコントラクトの`words`の値を`"old"`に変更します。

```solidity
// ロジックコントラクト1
contract Logic1 {
    // 状態変数はproxyコントラクトと一致、スロット競合を防ぐ
    address public implementation;
    address public admin;
    string public words; // 文字列、ロジックコントラクトの関数を通じて変更可能

    // proxyの状態変数を変更、セレクタ：0xc2985578
    function foo() public{
        words = "old";
    }
}
```

### 新ロジックコントラクト

このロジックコントラクトには`3`つの状態変数が含まれ、プロキシコントラクトと一致させてスロット競合を防ぎます。`foo()`関数が1つだけあり、プロキシコントラクトの`words`の値を`"new"`に変更します。

```solidity
// ロジックコントラクト2
contract Logic2 {
    // 状態変数はproxyコントラクトと一致、スロット競合を防ぐ
    address public implementation;
    address public admin;
    string public words; // 文字列、ロジックコントラクトの関数を通じて変更可能

    // proxyの状態変数を変更、セレクタ：0xc2985578
    function foo() public{
        words = "new";
    }
}
```

## `Remix`での実装

1. 新旧ロジックコントラクト`Logic1`と`Logic2`をデプロイする。
![47-2.png](./img/47-2.png)
![47-3.png](./img/47-3.png)

2. アップグレード可能コントラクト`SimpleUpgrade`をデプロイし、`implementation`アドレスを旧ロジックコントラクトに向ける。
![47-4.png](./img/47-4.png)

3. セレクタ`0xc2985578`を使用して、プロキシコントラクトで旧ロジックコントラクト`Logic1`の`foo()`関数を呼び出し、`words`の値を`"old"`に変更する。
![47-5.png](./img/47-5.png)

4. `upgrade()`を呼び出し、`implementation`アドレスを新ロジックコントラクト`Logic2`に向ける。
![47-6.png](./img/47-6.png)

5. セレクタ`0xc2985578`を使用して、プロキシコントラクトで新ロジックコントラクト`Logic2`の`foo()`関数を呼び出し、`words`の値を`"new"`に変更する。
![47-7.png](./img/47-7.png)

## まとめ

このレッスンでは、シンプルなアップグレード可能コントラクトを紹介しました。これはロジックコントラクトを変更できるプロキシコントラクトで、変更不可能なスマートコントラクトにアップグレード機能を追加します。ただし、このコントラクトには`セレクタ競合`の問題があり、セキュリティリスクが存在します。次回は、このリスクを解決するアップグレード可能コントラクトの標準：透明プロキシと`UUPS`について説明します。