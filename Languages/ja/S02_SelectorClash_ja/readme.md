---
title: S02. セレクタークラッシュ
tags:
  - solidity
  - security
  - selector
  - abi encode
---

# WTF Solidity 合約セキュリティ: S02. セレクタークラッシュ

私は最近Solidityを学び直して詳細を固めており、「WTF Solidity 合約セキュリティ」を書いています。初心者向けの内容で（プログラミング上級者は他のチュートリアルをお探しください）、毎週1-3講座を更新しています。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、セレクタークラッシュ攻撃について紹介します。これは、クロスチェーンブリッジPoly Networkが被害を受けた原因の一つです。2021年8月、Poly NetworkのETH、BSC、Polygon上のクロスチェーンブリッジコントラクトが盗難に遭い、損失は6.11億ドルにも達しました（[まとめ](https://rekt.news/zh/polynetwork-rekt/)）。これは2021年最大のブロックチェーンハッキング事件であり、歴史上被害額第2位の事件で、Ronin ブリッジハッキング事件に次ぐものです。

## セレクタークラッシュ

イーサリアムスマートコントラクトにおいて、関数セレクターは関数シグネチャ `"<function name>(<function input types>)"` のハッシュ値の最初の`4`バイト（`8`桁の16進数）です。ユーザーがコントラクトの関数を呼び出す際、`calldata`の最初の`4`バイトがターゲット関数のセレクターとなり、どの関数を呼び出すかを決定します。詳しく知りたい場合は、[WTF Solidity極簡チュートリアル第29講：関数セレクター](https://github.com/AmazingAng/WTF-Solidity/blob/main/29_Selector/readme.md)をお読みください。

関数セレクターは`4`バイトしかなく、非常に短いため、衝突しやすいという特徴があります。つまり、異なる2つの関数でも同じ関数セレクターを持つことがあります。例えば、`transferFrom(address,address,uint256)`と`gasprice_bit_ether(int128)`は同じセレクター`0x23b872dd`を持ちます。もちろん、スクリプトを書いてブルートフォース攻撃することも可能です。

![](./img/S02-1.png)

同じセレクターに対応する異なる関数を調べるには、以下の2つのウェブサイトを使用できます：

1. https://www.4byte.directory/
2. https://sig.eth.samczsun.com/

以下の`Power Clash`ツールを使用してブルートフォース攻撃を行うこともできます：

1. PowerClash: https://github.com/AmazingAng/power-clash

一方、ウォレットの公開鍵は`64`バイトあり、衝突する確率はほぼ`0`で、非常に安全です。

## `0xAA` スフィンクスの謎を解く

イーサリアムの人々が神々を怒らせ、神々は激怒しました。天后ヘラはイーサリアムの人々を罰するため、イーサリアムの崖の上にスフィンクスという人面獅身の女怪物を降らせました。彼女は崖を通りかかるすべてのイーサリアムユーザーに謎かけを出しました：「朝は四本足で歩き、昼は二本足で歩き、夕方は三本足で歩く。すべての生物の中で、異なる数の足で歩く唯一の生物は何か。足の数が最も多い時が、速度と力が最も小さい時である。」この神秘的で理解しがたい謎について、答えを当てた者は生き延び、当てられなかった者はすべて食べられてしまいました。通りかかる人々はすべてスフィンクスに食べられ、イーサリアムユーザーは恐怖に陥りました。スフィンクスはセレクター`0x10cd2dc7`を使って答えが正しいかどうかを検証していました。

ある日の朝、オイディプスがこの場所を通りかかり、女怪物に会い、この神秘的で不可思議な謎を当てました。彼は言いました：「これは`"function man()"`です！生命の朝において、彼は子供で、二本の脚と二本の手で這い回ります。生命の昼になると、彼は壮年となり、二本の脚だけで歩きます。生命の夕方になると、彼は年老いて体が衰え、杖の助けを借りて歩かなければならないので、三本足と呼ばれます。」謎が当てられた後、オイディプスは生き延びることができました。

その日の午後、`0xAA`がこの場所を通りかかり、女怪物に会い、この神秘的で不可思議な謎を当てました。彼は言いました：「これは`"function peopleLduohW(uint256)"`です！生命の朝において、彼は子供で、二本の脚と二本の手で這い回ります。生命の昼になると、彼は壮年となり、二本の脚だけで歩きます。生命の夕方になると、彼は年老いて体が衰え、杖の助けを借りて歩かなければならないので、三本足と呼ばれます。」謎が再び当てられた後、スフィンクスは怒り狂い、足を滑らせて高い崖から落ちて死んでしまいました。

![](./img/S02-2.png)

## 脆弱性コントラクトの例

### 脆弱性コントラクト

以下は脆弱性のあるコントラクトの例です。`SelectorClash`コントラクトには1つの状態変数`solved`があり、初期値は`false`で、攻撃者はこれを`true`に変更する必要があります。コントラクトには主に2つの関数があり、関数名はPoly Network脆弱性コントラクトから引用されています。

1. `putCurEpochConPubKeyBytes()` ：攻撃者がこの関数を呼び出すと、`solved`を`true`に変更でき、攻撃を完了できます。しかし、この関数は`msg.sender == address(this)`をチェックするため、呼び出し元はコントラクト自体である必要があります。他の関数を確認する必要があります。

2. `executeCrossChainTx()` ：これを通じてコントラクト内の関数を呼び出すことができますが、関数パラメータの型とターゲット関数は少し異なります：ターゲット関数のパラメータは`(bytes)`ですが、ここで呼び出される関数のパラメータは`(bytes,bytes,uint64)`です。

```solidity
contract SelectorClash {
    bool public solved; // 攻撃が成功したかどうか

    // 攻撃者が呼び出す必要がある関数だが、呼び出し元 msg.sender は本コントラクトである必要がある。
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // 脆弱性があり、攻撃者は _method 変数を変更して関数セレクターを衝突させ、ターゲット関数を呼び出して攻撃を完了できる。
    function executeCrossChainTx(bytes memory _method, bytes memory _bytes, bytes memory _bytes1, uint64 _num) public returns(bool success){
        (success, ) = address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), abi.encode(_bytes, _bytes1, _num)));
    }
}
```

### 攻撃方法

我々の目標は`executeCrossChainTx()`関数を利用してコントラクト内の`putCurEpochConPubKeyBytes()`を呼び出すことです。ターゲット関数のセレクターは`0x41973cd9`です。`executeCrossChainTx()`では`_method`パラメータと`"(bytes,bytes,uint64)"`を関数シグネチャとして使用してセレクターを計算していることがわかります。したがって、適切な`_method`を選択して、ここで計算されるセレクターが`0x41973cd9`と等しくなるようにし、セレクタークラッシュを通じてターゲット関数を呼び出すだけです。

Poly Networkハッキング事件では、ハッカーが衝突させた`_method`は`f1121318093`でした。つまり、`f1121318093(bytes,bytes,uint64)`のハッシュの最初の4桁も`0x41973cd9`で、関数を正常に呼び出すことができます。次に行うべきことは、`f1121318093`を`bytes`型に変換することです：`0x6631313231333138303933`、そしてこれをパラメータとして`executeCrossChainTx()`に入力します。`executeCrossChainTx()`関数の他の3つのパラメータは重要ではないので、`0x`、`0x`、`0`を入力します。

## `Remix`デモ

1. `SelectorClash`コントラクトをデプロイします。
2. `executeCrossChainTx()`を呼び出し、パラメータに`0x6631313231333138303933`、`0x`、`0x`、`0`を入力して攻撃を開始します。
3. `solved`変数の値を確認すると、`true`に変更されており、攻撃が成功したことがわかります。

## まとめ

今回は、セレクタークラッシュ攻撃について紹介しました。これは、クロスチェーンブリッジPoly Networkが6.1億ドルを盗まれた原因の一つです。この攻撃は以下のことを教えてくれます：

1. 関数セレクターは簡単に衝突させることができ、パラメータの型を変更しても、同じセレクターを持つ関数を構築することができます。

2. コントラクト関数の権限を適切に管理し、特別な権限を持つコントラクト関数がユーザーによって呼び出されないようにしてください。