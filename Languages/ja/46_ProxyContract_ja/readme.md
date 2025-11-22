---
title: 46. プロキシコントラクト
tags:
  - solidity
  - proxy

---

# WTF Solidity 超シンプル入門: 46. プロキシコントラクト

最近、Solidityを再学習しており、詳細を確認しながら「WTF Solidity 超シンプル入門」を執筆しています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週1〜3レッスンのペースで更新していきます。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat グループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはGitHubにて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、プロキシコントラクト（Proxy Contract）について説明します。教材のコードはOpenZeppelinの[Proxyコントラクト](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol)を簡略化したものです。

## プロキシパターン

`Solidity`コントラクトがチェーン上にデプロイされた後、コードは不変（immutable）になります。これには長所と短所があります：

- 長所：安全で、ユーザーは何が起こるかを知ることができる（大部分の場合）
- 短所：コントラクトにバグが存在していても修正やアップグレードができず、新しいコントラクトをデプロイする必要がある。しかし、新しいコントラクトのアドレスは古いものとは異なり、コントラクトのデータも大量のガスを消費して移行する必要がある。

コントラクトをデプロイ後に修正またはアップグレードする方法はあるのでしょうか？答えは「はい」です。それが**プロキシパターン**です。

![プロキシパターン](./img/46-1.png)

プロキシパターンはコントラクトのデータとロジックを分離し、それぞれを異なるコントラクトに保存します。上図のシンプルなプロキシコントラクトを例にすると、データ（状態変数）はプロキシコントラクトに保存され、ロジック（関数）は別のロジックコントラクトに保存されます。プロキシコントラクト（Proxy）は`delegatecall`を通じて、関数呼び出しを完全にロジックコントラクト（Implementation）に委託して実行し、最終的な結果を呼び出し元（Caller）に返します。

プロキシパターンには主に2つの利点があります：
1. アップグレード可能：コントラクトのロジックをアップグレードする必要がある場合、プロキシコントラクトを新しいロジックコントラクトに向けるだけで済みます。
2. ガス節約：複数のコントラクトが同じロジックを使用する場合、1つのロジックコントラクトをデプロイし、データのみを保存する複数のプロキシコントラクトをデプロイして、ロジックコントラクトを参照すればよい。

**ヒント**：`delegatecall`に慣れていない方は、本チュートリアルの[第23回 Delegatecall](https://github.com/AmazingAng/WTF-Solidity/tree/main/23_Delegatecall)をご覧ください。

## プロキシコントラクト

以下、OpenZeppelinの[Proxyコントラクト](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol)から簡略化されたシンプルなプロキシコントラクトを紹介します。これには3つの部分があります：プロキシコントラクト`Proxy`、ロジックコントラクト`Logic`、そして呼び出し例`Caller`です。ロジックはそれほど複雑ではありません：

- まずロジックコントラクト`Logic`をデプロイする
- プロキシコントラクト`Proxy`を作成し、状態変数`implementation`に`Logic`コントラクトのアドレスを記録
- `Proxy`コントラクトはフォールバック関数`fallback`を利用して、すべての呼び出しを`Logic`コントラクトに委託
- 最後に呼び出し例`Caller`コントラクトをデプロイし、`Proxy`コントラクトを呼び出す
- **注意**：`Logic`コントラクトと`Proxy`コントラクトの状態変数の保存構造は同じでなければならず、そうでないと`delegatecall`が予期しない動作を引き起こし、セキュリティリスクが発生します。

### プロキシコントラクト`Proxy`

`Proxy`コントラクトは長くありませんが、インラインアセンブリを使用しているため理解が難しいです。状態変数1つ、コンストラクタ1つ、フォールバック関数1つのみです。状態変数`implementation`はコンストラクタで初期化され、`Logic`コントラクトのアドレスを保存するために使用されます。

```solidity
contract Proxy {
    address public implementation; // ロジックコントラクトのアドレス。implementationコントラクトの同じ位置の状態変数の型はProxyコントラクトと同じでなければならない

    /**
     * @dev ロジックコントラクトのアドレスを初期化
     */
    constructor(address implementation_){
        implementation = implementation_;
    }
```

`Proxy`のフォールバック関数は、本コントラクトへの外部呼び出しを`Logic`コントラクトに委託します。このフォールバック関数は特殊で、インラインアセンブリ（inline assembly）を利用して、本来返り値を持つことができないフォールバック関数に返り値を持たせています。使用されているインラインアセンブリのオペコード：

- `calldatacopy(t, f, s)`：calldata（入力データ）を位置`f`から`s`バイト分、メモリの位置`t`にコピー
- `delegatecall(g, a, in, insize, out, outsize)`：アドレス`a`のコントラクトを呼び出し、入力は`mem[in..(in+insize))`、出力は`mem[out..(out+outsize))`、`g` weiのイーサリアムガスを提供。このオペコードはエラー時に`0`を返し、成功時に`1`を返す
- `returndatacopy(t, f, s)`：returndata（出力データ）を位置`f`から`s`バイト分、メモリの位置`t`にコピー
- `switch`：基本的な`if/else`、異なるケース`case`で異なる値を返す。デフォルトの`default`ケースを持つことができる
- `return(p, s)`：関数の実行を終了し、データ`mem[p..(p+s))`を返す
- `revert(p, s)`：関数の実行を終了し、状態をロールバック、データ`mem[p..(p+s))`を返す

```solidity
/**
* @dev フォールバック関数、本コントラクトへの呼び出しを`implementation`コントラクトに委託
* assemblyを通じて、フォールバック関数も返り値を持つことができる
*/
fallback() external payable {
    address _implementation = implementation;
    assembly {
        // msg.dataをメモリにコピー
        // calldatacopyオペコードのパラメータ：メモリ開始位置、calldata開始位置、calldata長さ
        calldatacopy(0, 0, calldatasize())

        // delegatecallを使用してimplementationコントラクトを呼び出す
        // delegatecallオペコードのパラメータ：gas、ターゲットコントラクトアドレス、input mem開始位置、input mem長さ、output area mem開始位置、output area mem長さ
        // output area開始位置と長さは0に設定
        // delegatecall成功時は1を返し、失敗時は0を返す
        let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

        // return dataをメモリにコピー
        // returndataオペコードのパラメータ：メモリ開始位置、returndata開始位置、returndata長さ
        returndatacopy(0, 0, returndatasize())

        switch result
        // delegatecallが失敗した場合、revert
        case 0 {
            revert(0, returndatasize())
        }
        // delegatecallが成功した場合、mem開始位置0、長さreturndatasize()のデータ（bytes形式）を返す
        default {
            return(0, returndatasize())
        }
    }
}
```

### ロジックコントラクト`Logic`

これはプロキシコントラクトのデモンストレーションのための非常にシンプルなロジックコントラクトです。`2`つの変数、`1`つのイベント、`1`つの関数が含まれています：
- `implementation`：プレースホルダー変数、`Proxy`コントラクトと一致させ、スロット競合を防ぐ
- `x`：`uint`変数、`99`に設定されている
- `CallSuccess`イベント：呼び出し成功時に発行される
- `increment()`関数：`Proxy`コントラクトから呼び出され、`CallSuccess`イベントを発行し、`uint`を返す。セレクタは`0xd09de08a`。直接`increment()`を呼び出すと`100`を返すが、`Proxy`を通じて呼び出すと`1`を返す。なぜか考えてみてください。

```solidity
/**
 * @dev ロジックコントラクト、委託された呼び出しを実行
 */
contract Logic {
    address public implementation; // Proxyと一致させ、スロット競合を防ぐ
    uint public x = 99;
    event CallSuccess(); // 呼び出し成功イベント

    // この関数はCallSuccessイベントを発行し、uintを返す
    // 関数セレクタ: 0xd09de08a
    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
    }
}
```

### 呼び出し元コントラクト`Caller`

`Caller`コントラクトは、プロキシコントラクトを呼び出す方法を示します。これも非常にシンプルです。しかし、理解するためには本チュートリアルの[第22回 Call](https://github.com/AmazingAng/WTF-Solidity/tree/main/22_Call/readme.md)と[第27回 ABIエンコーディング](https://github.com/AmazingAng/WTF-Solidity/tree/main/27_ABIEncode/readme.md)を先に学習する必要があります。

`1`つの変数と`2`つの関数があります：
- `proxy`：状態変数、プロキシコントラクトのアドレスを記録
- コンストラクタ：コントラクトデプロイ時に`proxy`変数を初期化
- `increase()`：`call`を利用してプロキシコントラクトの`increment()`関数を呼び出し、`uint`を返す。呼び出し時には、`abi.encodeWithSignature()`を利用して`increment()`関数のセレクタを取得。返り値では、`abi.decode()`を利用して返り値を`uint`型にデコード

```solidity
/**
 * @dev Callerコントラクト、プロキシコントラクトを呼び出し、実行結果を取得
 */
contract Caller{
    address public proxy; // プロキシコントラクトアドレス

    constructor(address proxy_){
        proxy = proxy_;
    }

    // プロキシコントラクトを通じてincrement()関数を呼び出す
    function increment() external returns(uint) {
        ( , bytes memory data) = proxy.call(abi.encodeWithSignature("increment()"));
        return abi.decode(data,(uint));
    }
}
```

## `Remix`でのデモンストレーション

1. `Logic`コントラクトをデプロイする。

![](./img/46-2.jpg)

2. `Logic`コントラクトの`increment()`関数を呼び出すと、`100`が返される。

![](./img/46-3.jpg)

3. `Proxy`コントラクトをデプロイし、初期化時に`Logic`コントラクトのアドレスを入力する。

![](./img/46-4.jpg)

4. `Proxy`コントラクトの`increment()`関数を呼び出すと、返り値はない。

    呼び出し方法：`Remix`のデプロイパネルで`Proxy`コントラクトをクリックし、一番下の`Low level interaction`に`increment()`関数のセレクタ`0xd09de08a`を入力し、`Transact`をクリック。

![](./img/46-5.jpg)

5. `Caller`コントラクトをデプロイし、初期化時に`Proxy`コントラクトのアドレスを入力する。

![](./img/46-6.jpg)

6. `Caller`コントラクトの`increment()`関数を呼び出すと、`1`が返される。

![](./img/46-7.jpg)

## まとめ

このレッスンでは、プロキシパターンとシンプルなプロキシコントラクトについて説明しました。プロキシコントラクトは`delegatecall`を利用して関数呼び出しを別のロジックコントラクトに委託し、データとロジックが異なるコントラクトによって管理されます。また、インラインアセンブリの黒魔術を利用して、返り値を持たないフォールバック関数でもデータを返せるようにしています。前述の質問への答え：なぜProxyを通じて`increment()`を呼び出すと1が返されるのか？[第23回 Delegatecall](https://github.com/AmazingAng/WTF-Solidity/tree/main/23_Delegatecall)で説明したように、CallerコントラクトがProxyコントラクトを通じてLogicコントラクトを`delegatecall`する際、Logicコントラクトの関数が状態変数を変更または読み取る場合、すべてProxyの対応する変数上で操作されます。ここでProxyコントラクトの`x`変数の値は0です（`x`変数を設定したことがないため、Proxyコントラクトのstorageエリアの対応位置の値は0）。そのため、Proxyを通じて`increment()`を呼び出すと1が返されます。

次のレッスンでは、アップグレード可能なプロキシコントラクトについて説明します。

プロキシコントラクトは非常に強力ですが、`バグ`が発生しやすいため、使用する際は[OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy)のテンプレートコントラクトを直接コピーすることをお勧めします。