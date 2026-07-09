---
title: 38. NFT取引所
tags:
  - solidity
  - application
  - wtfacademy
  - ERC721
  - NFT Swap
---

# WTF Solidity極簡入門: 38. NFT取引所

私は最近Solidityを再学習し、詳細を固めながら「WTF Solidity極簡入門」を書いています。これは初心者向けです（プログラミング上級者は他のチュートリアルを参照してください）。毎週1-3講を更新します。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[WeChatグループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

-----

「Opensea」はイーサリアム上で最大のNFT取引プラットフォームで、総取引額は300億ドルです。Openseaは取引に2.5%の手数料を課しており、つまりユーザーの取引を通じて少なくとも7億5000万ドルの利益を得ています。さらに、その運営は分散化されておらず、ユーザーに補償するトークンを発行する計画もありません。NFTプレイヤーはOpenseaに長い間不満を抱いています。今日、私たちはスマートコントラクトを使用して手数料ゼロの分散型NFT取引所：NFTSwapを構築します。

## 設計ロジック

- 売り手：NFTを売る側で、商品を出品、出品を取り消し、価格を更新できます。
- 買い手：NFTを買う側で、商品を購入できます。
- 注文：売り手が発行するオンチェーンNFT注文。同じtokenIdのシリーズは最大1つの注文を持つことができ、出品価格と所有者情報が含まれます。注文が完了または取り消されると、情報はクリアされます。

## NFTSwapコントラクト

### イベント

コントラクトには、NFTの出品（list）、取り消し（revoke）、価格更新（update）、購入（purchase）の動作に対応する4つのイベントが含まれています。

```solidity
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);
```

### 注文

`NFT`注文は`Order`構造として抽象化され、出品価格（`price`）と所有者（`owner`）の情報が含まれます。`nftList`マッピングは注文が対応する`NFT`シリーズ（コントラクトアドレス）と`tokenId`情報を記録します。

```solidity
    // 注文構造を定義
    struct Order{
        address owner;
        uint256 price;
    }
    // NFT注文マッピング
    mapping(address => mapping(uint256 => Order)) public nftList;
```

### フォールバック関数

`NFTSwap`では、ユーザーは`ETH`を使用して`NFT`を購入します。そのため、コントラクトは`ETH`を受信するために`fallback()`関数を実装する必要があります。

```solidity
    fallback() external payable{}
```

### onERC721Received

`ERC721`の安全転送関数は、受信コントラクトが`onERC721Received()`関数を実装し、正しいセレクタを返すかをチェックします。ユーザーが注文を出した後、`NFT`は`NFTSwap`コントラクトに送信される必要があります。そのため、`NFTSwap`コントラクトは`IERC721Receiver`インターフェースを継承し、`onERC721Received()`関数を実装します。

これは「NFTSwap」という名前のスマートコントラクトで、「IERC721Receiver」インターフェースを実装しています。関数「onERC721Received」はERC721トークンを受信するために定義されています。4つのパラメータを取ります：
- 「operator」：関数を呼び出したアドレス
- 「from」：トークンをコントラクトに転送したアドレス
- 「tokenId」：転送されたERC721トークンのID
- 「data」：トークン転送と一緒に送信できる追加データ

関数は「IERC721Receiver」インターフェースの「onERC721Received」関数のセレクタを返します。

### 取引

コントラクトは取引に関連する`4`つの関数を実装しています：

- 出品`list()`：売り手が`NFT`を作成し、注文を作成し、`List`イベントを発行します。パラメータは`NFT`コントラクトアドレス`_nftAddr`、`NFT`の対応する`_tokenId`、出品価格`_price`（**注意：単位は`wei`**）です。成功後、`NFT`は売り手から`NFTSwap`コントラクトに転送されます。

```solidity
    // 出品：売り手がNFTを販売に出品、コントラクトアドレスは_nftAddr、tokenIdは_tokenId、価格は_price（単位はwei）
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public{
        IERC721 _nft = IERC721(_nftAddr); // インターフェースコントラクト変数IERC721を宣言
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval"); // コントラクトが承認されている
        require(_price > 0); // 価格が0より大きい

        Order storage _order = nftList[_nftAddr][_tokenId]; // NFT所有者と価格を設定
        _order.owner = msg.sender;
        _order.price = _price;
        // NFTをコントラクトに転送
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Listイベントを発行
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }
```

- `revoke()`：売り手が注文をキャンセルし、`Revoke`イベントを発行します。パラメータには`NFT`コントラクトアドレス`_nftAddr`と対応する`_tokenId`が含まれます。実行成功後、`NFT`は`NFTSwap`コントラクトから売り手に返還されます。

```solidity
// 注文キャンセル：売り手が注文をキャンセル
function revoke(address _nftAddr, uint256 _tokenId) public {
    Order storage _order = nftList[_nftAddr][_tokenId]; // 注文を取得
    require(_order.owner == msg.sender, "Not Owner"); // 所有者によって開始される必要がある
    // IERC721インターフェースコントラクト変数を宣言
    IERC721 _nft = IERC721(_nftAddr);
    require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFTがコントラクト内にある

    // NFTを売り手に転送
    _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    delete nftList[_nftAddr][_tokenId]; // 注文を削除

    // Revokeイベントを発行
    emit Revoke(msg.sender, _nftAddr, _tokenId);
}
```

- 価格変更`update()`：売り手がNFT注文の価格を変更し、`Update`イベントを発行します。パラメータはNFTコントラクトアドレス`_nftAddr`、NFTの対応する`_tokenId`、更新された注文価格`_newPrice`（**注意：単位は`wei`**）です。

```solidity
    // 価格調整：売り手が出品価格を調整
    function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Invalid Price"); // NFT価格は0より大きい必要がある
        Order storage _order = nftList[_nftAddr][_tokenId]; // 注文を取得
        require(_order.owner == msg.sender, "Not Owner"); // 所有者によって開始される必要がある
        // IERC721インターフェースコントラクト変数を宣言
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFTがコントラクト内にある

        // NFT価格を調整
        _order.price = _newPrice;

        // Updateイベントを発行
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }
```

- 購入：買い手が`ETH`を支払って注文の`NFT`を購入し、`Purchase`イベントをトリガーします。パラメータは`NFT`コントラクトアドレス`_nftAddr`と`NFT`の対応する`_tokenId`です。成功すると、`ETH`は売り手に転送され、`NFT`は`NFTSwap`コントラクトから買い手に転送されます。

```solidity
    // 購入：買い手がNFTを購入、コントラクトは_nftAddr、tokenIdは_tokenId、関数呼び出し時にETHが必要
    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        Order storage _order = nftList[_nftAddr][_tokenId]; // 注文を取得
        require(_order.price > 0, "Invalid Price"); // NFT価格が0より大きい
        require(msg.value >= _order.price, "Increase price"); // 購入価格が出品価格より大きい
        // IERC721インターフェースコントラクト変数を宣言
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFTがコントラクト内にある

        // NFTを買い手に転送
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // ETHを売り手に転送し、余剰のETHを買い手に返金
        payable(_order.owner).transfer(_order.price);
        if (msg.value > _order.price) {
            payable(msg.sender).transfer(msg.value - _order.price);
        }

        // Purchaseイベントを発行
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);

        delete nftList[_nftAddr][_tokenId]; // 注文を削除
    }
```

## `Remix`での実装

### 1. NFTコントラクトのデプロイ

NFTについて学び、`WTFApe` NFTコントラクトをデプロイするには、[ERC721](https://github.com/AmazingAng/WTF-Solidity/tree/main/34_ERC721)チュートリアルを参照してください。

![NFTコントラクトのデプロイ](./img/38-1.png)

最初のNFTを自分にミントします。これは将来NFTの出品や価格変更などの操作を実行できるようにするためです。

`mint(address to, uint tokenId)`関数は2つのパラメータを取ります：

`to`：NFTがミントされるアドレス。これは通常自分のウォレットアドレスです。

`tokenId`：`WTFApe`コントラクトが合計10,000個のNFTを定義しているため、ここでミントされる最初の2つのNFTの`tokenId`値はそれぞれ`0`と`1`です。

![NFTのミント](./img/38-2.png)

`WTFApe`コントラクトで、`ownerOf`を使用して`tokenId`が0のNFTを所有していることを確認します。

`ownerOf(uint tokenId)`関数は1つのパラメータを取ります：

`tokenId`：`tokenId`はNFTの一意の識別子で、この例では上述のミントプロセスで生成された`0` idを指します。

![NFT所有権の確認](./img/38-3.png)

上記の方法を使用して、`tokenId` `0`と`1`のNFTを自分にミントします。`tokenId` `0`には購入更新操作を実行し、`tokenId` `1`には出品取り消し操作を実行します。

### 2. `NFTSwap`コントラクトのデプロイ

`NFTSwap`コントラクトをデプロイします。

![`NFTSwap`コントラクトのデプロイ](./img/38-4.png)

### 3. `NFTSwap`コントラクトに出品のためのNFTを承認

`WTFApe`コントラクトで、`approve()`承認関数を呼び出して、所有している`tokenId` `0`のNFTを`NFTSwap`コントラクトが出品できるように許可を与えます。

`approve(address to, uint tokenId)`メソッドは2つのパラメータを持ちます：

`to`：`tokenId`が転送を承認されるアドレス、この場合は`NFTSwap`コントラクトのアドレス。

`tokenId`：`tokenId`はNFTの一意の識別子で、この例では上述のミントプロセスで生成された`0` idを指します。

![](./img/38-5.png)

上記の方法に従って、`tokenId`が`1`のNFTを`NFTSwap`コントラクトアドレスに承認します。

### 4. NFTを販売に出品

`NFTSwap`コントラクトの`list()`関数を呼び出して、呼び出し者が所有する`tokenId`が`0`のNFTを`NFTSwap`に出品します。価格を1 `wei`に設定します。

`list(address _nftAddr, uint256 _tokenId, uint256 _price)`メソッドは3つのパラメータを持ちます：

`_nftAddr`：`_nftAddr`はNFTコントラクトアドレスで、この場合は`WTFApe`コントラクトアドレス。

`_tokenId`：`_tokenId`はNFTのIDで、この場合は上述でミントされた`0` ID。

`_price`：`_price`はNFTの価格で、この場合は1 `wei`。

![](./img/38-6.png)

上記の方法に従って、呼び出し者が所有する`tokenId`が`1`のNFTを`NFTSwap`に出品し、価格を1 `wei`に設定します。

### 5. 出品されたNFTを表示

`NFTSwap`コントラクトの`nftList()`関数を呼び出して出品されたNFTを表示します。

`nftList`：以下の構造を持つNFT注文のマッピングです：

`nftList[_nftAddr][_tokenId]`：`_nftAddr`と`_tokenId`を入力すると、NFT注文を返します。

![](./img/38-7.png)

### 6. NFT価格の更新

`NFTSwap`コントラクトの`update()`関数を呼び出して、`tokenId` 0のNFTの価格を77 `wei`に更新します。

`update(address _nftAddr, uint256 _tokenId, uint256 _newPrice)`メソッドは3つのパラメータを持ちます：

`_nftAddr`：`_nftAddr`はNFTコントラクトのアドレスで、この場合は`WTFApe`コントラクトアドレス。

`_tokenId`：`_tokenId`はNFTのidで、この場合は上述でミントされたNFTの0というid。

`_newPrice`：`_newPrice`はNFTの新しい価格で、この場合は77 `wei`。

`update()`実行後、`nftList`を呼び出して更新された価格を表示します。

### 5. NFTの出品取り消し

`NFTSwap`コントラクトの`revoke()`関数を呼び出してNFTの出品を取り消します。

上記の記事で、私たちは`tokenId`が`0`と`1`のNFTをそれぞれ出品しました。この方法では、`tokenId`が`1`のNFTを出品取り消しします。

`revoke(address _nftAddr, uint256 _tokenId)`関数は2つのパラメータを持ちます：

`_nftAddr`：`_nftAddr`はNFTコントラクトのアドレスで、この例では`WTFApe`コントラクトアドレス。

`_tokenId`：`_tokenId`はNFTのidで、この例ではミントの`1` Id。

`NFTSwap`コントラクトの`nftList()`関数を呼び出すと、NFTが出品取り消しされたことが確認できます。再度出品するには再承認が必要です。

**NFTを出品取り消しした後、購入前にステップ3から再度承認して出品する必要があることに注意してください。**

### 6. `NFT`の購入

別のアカウントに切り替えて、`NFTSwap`コントラクトの`purchase()`関数を呼び出してNFTを購入します。購入時には、`NFT`コントラクトアドレス、`tokenId`、支払いたい`ETH`の金額を入力する必要があります。

私たちは`tokenId` 1のNFTを出品取り消ししましたが、`tokenId` 0のNFTはまだ購入可能です。

`purchase(address _nftAddr, uint256 _tokenId, uint256 _wei)`メソッドは3つのパラメータを持ちます：

`_nftAddr`：`_nftAddr`はNFTコントラクトアドレスで、この例では`WTFApe`コントラクトアドレス。

`_tokenId`：`_tokenId`はNFTのIDで、上記でミントした0。

`_wei`：`_wei`は支払う`ETH`の金額で、この例では77 `wei`。

![](./img/38-11.png)

### 7. NFT所有者の変更を確認

購入成功後、`WTFApe`コントラクトの`ownerOf()`関数を呼び出すと、`NFT`所有者が変更されており、購入が成功したことが示されます！

まとめると、この講義では手数料ゼロの分散型`NFT`取引所を構築しました。`OpenSea`は`NFT`の発展に大きく貢献しましたが、その欠点も非常に明白です：高い取引手数料、ユーザーへの報酬なし、フィッシング攻撃を招きやすい取引メカニズムなど、ユーザーが資産を失う原因となっています。現在、`Looksrare`や`dydx`などの新しい`NFT`取引プラットフォームが`OpenSea`の地位に挑戦しており、`Uniswap`も新しい`NFT`取引所を研究しています。近い将来、より優れた`NFT`取引所が利用できるようになると信じています。