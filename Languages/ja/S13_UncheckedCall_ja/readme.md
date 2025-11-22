---
title: S13. 未チェックの低レベル呼び出し
tags:
  - solidity
  - security
  - transfer/send/call
---

# WTF Solidity 合約セキュリティ: S13. 未チェックの低レベル呼び出し

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、スマートコントラクトの未チェック低レベル呼び出し（low-level call）の脆弱性について紹介します。失敗した低レベル呼び出しは取引をロールバックしません。コントラクト内でその戻り値をチェックすることを忘れると、しばしば深刻な問題が発生します。

## 低レベル呼び出し

イーサリアムの低レベル呼び出しには`call()`、`delegatecall()`、`staticcall()`、`send()`があります。これらの関数はSolidityの他の関数と異なり、例外が発生した時に上位層に伝播せず、取引を完全にロールバックすることもありません。ただブール値`false`を返して、呼び出し失敗の情報を伝達するだけです。したがって、低レベル関数呼び出しの戻り値をチェックしない場合、低レベル呼び出しが失敗するかどうかに関係なく、上位層関数のコードは継続して実行されます。低レベル呼び出しのより詳しい内容については、[WTF Solidity極簡チュートリアル第20-23講](https://github.com/AmazingAng/WTF-Solidity)をお読みください。

最もエラーが起きやすいのは`send()`です：一部のコントラクトは`send()`を使って`ETH`を送信しますが、`send()`はgasを2300以下に制限し、それ以外は失敗します。ターゲットアドレスのコールバック関数が複雑な場合、消費されるgasは2300を超え、`send()`の失敗を引き起こします。この時、上位層関数で戻り値をチェックしない場合、取引は継続実行され、予期しない問題が発生します。2016年、`King of Ether`というブロックチェーンゲームで、この脆弱性により返金が正常に送信できない問題が発生しました（[事後分析レポート](https://www.kingoftheether.com/postmortem.html)）。

![](./img/S13-1.png)

## 脆弱性の例

### 銀行コントラクト

このコントラクトは`S01 リエントランシー攻撃`チュートリアルの銀行コントラクトを基に修正したものです。`balanceOf`状態変数でユーザーのイーサリアム残高を記録し、3つの関数を含みます：
- `deposit()`：預金関数、`ETH`を銀行コントラクトに預け、ユーザーの残高を更新します。
- `withdraw()`：出金関数、呼び出し者の残高を転送します。具体的な手順は上記のストーリーと同じです：残高を照会、残高を更新、転送。**注意：この関数は`send()`の戻り値をチェックしていません。出金が失敗しても残高はゼロになります！**
- `getBalance()`：銀行コントラクト内の`ETH`残高を取得します。

```solidity
contract UncheckedBank {
    mapping (address => uint256) public balanceOf;    // 残高mapping

    // etherを預け、残高を更新
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // msg.senderの全etherを出金
    function withdraw() external {
        // 残高を取得
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        balanceOf[msg.sender] = 0;
        // 未チェック低レベル呼び出し
        bool success = payable(msg.sender).send(balance);
    }

    // 銀行コントラクトの残高を取得
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## 攻撃コントラクト

攻撃コントラクトを構築しました。これは不運な預金者を描写しており、出金は失敗するが銀行残高はゼロになります：コントラクトのコールバック関数`receive()`内の`revert()`が取引をロールバックするため、`ETH`を受け取ることができません。しかし、出金関数`withdraw()`は正常に呼び出すことができ、残高をクリアします。

```solidity
contract Attack {
    UncheckedBank public bank; // Bankコントラクトアドレス

    // Bankコントラクトアドレスを初期化
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }

    // コールバック関数、ETH転送時に失敗
    receive() external payable {
        revert();
    }

    // 預金関数、呼び出し時にmsg.valueを預金額に設定
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // 出金関数、呼び出しは成功するが実際の出金は失敗
    function withdraw() external payable {
        bank.withdraw();
    }

    // 本コントラクトの残高を取得
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## `Remix`での再現

1. `UncheckedBank`コントラクトをデプロイします。

2. `Attack`コントラクトをデプロイし、コンストラクタに`UncheckedBank`コントラクトアドレスを入力します。

3. `Attack`コントラクトの`deposit()`預金関数を呼び出し、`1 ETH`を預けます。

4. `Attack`コントラクトの`withdraw()`出金関数を呼び出して出金を行います。呼び出しは成功します。

5. `UncheckedBank`コントラクトの`balanceOf()`関数と`Attack`コントラクトの`getBalance()`関数をそれぞれ呼び出します。前のステップの呼び出しが成功し、預金者の残高がクリアされたにもかかわらず、出金は失敗しています。

## 予防方法

以下の方法で未チェック低レベル呼び出しの脆弱性を予防できます：

1. 低レベル呼び出しの戻り値をチェックします。上記の銀行コントラクトでは、`withdraw()`を修正できます。
    ```solidity
    bool success = payable(msg.sender).send(balance);
    require(success, "Failed Sending ETH!")
    ```
2. コントラクトで`ETH`を転送する時は、`call()`を使用し、リエントランシー保護を適切に行います。

3. `OpenZeppelin`の[Addressライブラリ](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)を使用します。戻り値をチェックする低レベル呼び出しがうまくカプセル化されています。

## まとめ

このレッスンでは、未チェック低レベル呼び出しの脆弱性とその予防方法を紹介しました。イーサリアムの低レベル呼び出し（call、delegatecall、staticcall、send）は失敗時にブール値falseを返しますが、取引全体をロールバックすることはありません。開発者がこれをチェックしない場合、予期せぬ問題が発生します。