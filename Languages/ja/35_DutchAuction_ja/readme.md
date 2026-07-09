---
title: 35. ダッチオークション
tags:
  - solidity
  - application
  - wtfacademy
  - ERC721
  - Dutch Auction
---

# WTF Solidity極簡入門: 35. ダッチオークション

私は最近Solidityを再学習し、詳細を固めながら「WTF Solidity極簡入門」を書いています。これは初心者向けです（プログラミング上級者は他のチュートリアルを参照してください）。毎週1-3講を更新します。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[WeChatグループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

----

この講義では、ダッチオークションについて紹介し、簡素化版`Azuki`ダッチオークションコードを通じて、`ダッチオークション`を使用して`ERC721`標準の`NFT`を発行する方法を説明します。

## ダッチオークション

ダッチオークション（`Dutch Auction`）は特殊なオークション形式です。「減価オークション」とも呼ばれ、オークション対象の競売価格が高値から順次下降し、最初の競買人が応価（底値に達するか超える）した時点で落札が成立するオークションを指します。

![ダッチオークション](./img/35-1.png)

暗号通貨の世界では、多くの`NFT`がダッチオークションを通じて発売されており、`Azuki`や`World of Women`が含まれ、その中で`Azuki`はダッチオークションを通じて`8000`枚を超える`ETH`を調達しました。

プロジェクト側がこのオークション形式を非常に好む主な理由は2つあります：

1. ダッチオークションの価格は最高値からゆっくりと下降し、プロジェクト側が最大の収益を得られます。

2. オークションが長時間続く（通常6時間以上）ため、`gas war`を避けることができます。

## `DutchAuction`コントラクト

コードは`Azuki`の[コード](https://etherscan.io/address/0xed5af388653567af2f388e6224dc7c4b3241c544#code)を簡素化したものです。`DutchAuction`コントラクトは、以前に紹介した`ERC721`および`Ownable`コントラクトを継承しています：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/AmazingAng/WTF-Solidity/blob/main/34_ERC721/ERC721.sol";

contract DutchAuction is Ownable, ERC721 {
```

### `DutchAuction`状態変数

コントラクトには合計`9`個の状態変数があり、そのうち`6`個がオークションに関連しています：

- `COLLECTION_SIZE`：NFTの総数
- `AUCTION_START_PRICE`：ダッチオークションの開始価格（最高価格）
- `AUCTION_END_PRICE`：ダッチオークションの終了価格（最低価格/フロア価格）
- `AUCTION_TIME`：オークションの持続時間
- `AUCTION_DROP_INTERVAL`：価格が下降する間隔
- `auctionStartTime`：オークションの開始時間（ブロックチェーンタイムスタンプ、`block.timestamp`）

```solidity
    uint256 public constant COLLECTION_SIZE = 10000; // NFTの総数
    uint256 public constant AUCTION_START_PRICE = 1 ether; // 開始価格（最高価格）
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // 終了価格（最低価格/フロア価格）
    uint256 public constant AUCTION_TIME = 10 minutes; // オークション時間、テストの便宜上10分に設定
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; // 価格が下降する間隔
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_TIME / AUCTION_DROP_INTERVAL); // 各価格下降ステップ

    uint256 public auctionStartTime; // オークション開始タイムスタンプ
    string private _baseTokenURI; // metadata URI
    uint256[] private _allTokens; // すべての存在するtokenIdを記録
```

### `DutchAuction`関数

ダッチオークションコントラクトには合計`9`個の関数があります。`ERC721`に関連する関数はここでは再度説明せず、オークションに関連する関数のみを紹介します。

- オークション開始時間の設定：コンストラクタで現在のブロック時間を開始時間として宣言し、プロジェクト側は`setAuctionStartTime()`関数を通じて調整することもできます：

```solidity
    constructor() ERC721("WTF Dutch Auction", "WTF Dutch Auction") {
        auctionStartTime = block.timestamp;
    }

    // auctionStartTime setter関数、onlyOwner
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }
```

- オークションリアルタイム価格の取得：`getAuctionPrice()`関数は現在のブロック時間とオークション関連の状態変数を通じてリアルタイムオークション価格を計算します。

`block.timestamp`が開始時間より小さい場合、価格は最高価格`AUCTION_START_PRICE`；

`block.timestamp`が終了時間より大きい場合、価格は最低価格`AUCTION_END_PRICE`；

`block.timestamp`が両者の間にある場合、現在の減衰価格を計算します。

```solidity
    // オークションリアルタイム価格を取得
    function getAuctionPrice()
        public
        view
        returns (uint256)
    {
        if (block.timestamp < auctionStartTime) {
        return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
        return AUCTION_END_PRICE;
        } else {
        uint256 steps = (block.timestamp - auctionStartTime) /
            AUCTION_DROP_INTERVAL;
        return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }
```

- ユーザーオークションと`NFT`ミント：ユーザーは`auctionMint()`関数を呼び出して`ETH`を支払い、ダッチオークションに参加して`NFT`をミントします。

この関数はまずオークションが開始されているか/ミントが`NFT`総数を超えていないかをチェックします。次に、コントラクトは`getAuctionPrice()`とミント数量を通じてオークションコストを計算し、ユーザーが支払った`ETH`が十分かをチェックします：十分であれば、`NFT`をユーザーにミントし、超過分の`ETH`を返金します；そうでなければ、トランザクションを戻します。

```solidity
    // オークションmint関数
    function auctionMint(uint256 quantity) external payable{
        uint256 _saleStartTime = uint256(auctionStartTime); // ローカル変数を作成、gas消費を削減
        require(
        _saleStartTime != 0 && block.timestamp >= _saleStartTime,
        "sale has not started yet"
        ); // 開始オークション時間が設定されているか、オークションが開始されているかをチェック
        require(
        totalSupply() + quantity <= COLLECTION_SIZE,
        "not enough remaining reserved for auction to support desired mint amount"
        ); // NFT上限を超えていないかをチェック

        uint256 totalCost = getAuctionPrice() * quantity; // mintコストを計算
        require(msg.value >= totalCost, "Need to send more ETH."); // ユーザーが十分なETHを支払っているかをチェック

        // NFTをミント
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }
        // 余剰ETHを返金
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost); //ここでリエントランシーのリスクがないか注意
        }
    }
```

- プロジェクト側による調達した`ETH`の引き出し：プロジェクト側は`withdrawMoney()`関数を通じてオークションで調達した`ETH`を引き出すことができます。

```solidity
    // 引き出し関数、onlyOwner
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}(""); // call関数の呼び出し方法は第22講を参照
        require(success, "Transfer failed.");
    }
```

## Remixデモ

1. コントラクトのデプロイ：まず、`DutchAuction.sol`コントラクトをデプロイし、`setAuctionStartTime()`関数を通じてオークション開始時間を設定します。
この例では、開始時間を2023年3月19日14:34（UTC時間1679207640に対応）に使用します。実験時にはツールウェブサイト（[こちら](https://tool.chinaz.com/tools/unixtime.aspx)など）で対応する時間を自分で確認できます。

![オークション開始時間の設定](./img/35-2.png)

2. ダッチオークション：その後、`getAuctionPrice()`関数を通じて**現在の**オークション価格を取得できます。オークション開始前の価格は`開始価格 AUCTION_START_PRICE`であることが観察でき、オークションが進行するにつれて、オークション価格は徐々に下降し、`フロア価格 AUCTION_END_PRICE`まで下降した後は変化しません。

![ダッチオークション価格の変化](./img/35-3.png)

3. Mint操作：`auctionMint()`関数を通じてmintを完了します。この例では、時間がすでにオークション時間を超えているため、`フロア価格`のみでオークションが完了したことが分かります。

![ダッチオークションの完了](./img/35-4.png)

4. `ETH`の引き出し：`withdrawMoney()`関数を通じて直接、調達した`ETH`を`call()`でコントラクト作成者のアドレスに送信できます。

## まとめ

この講義では、ダッチオークションを紹介し、簡素化版`Azuki`ダッチオークションコードを通じて、`ダッチオークション`を使用して`ERC721`標準の`NFT`を発行する方法を説明しました。私がオークションで手に入れた最も高価な`NFT`は、音楽家`Jonathan Mann`の音楽`NFT`です。あなたはどうですか？