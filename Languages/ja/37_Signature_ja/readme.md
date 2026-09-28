---
title: 37. デジタル署名
tags:
  - Solidity
  - Application
  - WTF Academy
  - ERC721
  - Signature
---

# WTF Solidity極簡入門: 37. デジタル署名

私は最近Solidityを再学習し、詳細を固めながら「WTF Solidity極簡入門」を書いています。これは初心者向けです（プログラミング上級者は他のチュートリアルを参照してください）。毎週1-3講を更新します。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[WeChatグループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

-----

この講義では、イーサリアムのデジタル署名`ECDSA`について簡単に紹介し、それを使用して`NFT`ホワイトリストを発行する方法を説明します。コードで使用される`ECDSA`ライブラリは`OpenZeppelin`の同名ライブラリを簡素化したものです。

## デジタル署名

`opensea`で`NFT`を取引したことがあれば、署名は馴染みがあるでしょう。以下の画像は`metamask`ウォレットが署名する際にポップアップするウィンドウで、秘密鍵を公開することなく、秘密鍵を所有していることを証明できます。

![metamask署名](./img/37-1.png)

イーサリアムで使用されるデジタル署名アルゴリズムは楕円曲線デジタル署名アルゴリズム（`ECDSA`）と呼ばれ、楕円曲線の「秘密鍵-公開鍵」ペアに基づくデジタル署名アルゴリズムです。主に[3つの役割](https://en.wikipedia.org/wiki/Digital_signature)を果たします：

1. **身元認証**：署名者が秘密鍵の所有者であることを証明します。
2. **否認防止**：送信者がメッセージを送信したことを否定できません。
3. **完全性**：メッセージが送信中に変更されていないことを保証します。

## `ECDSA`コントラクト

`ECDSA`標準は2つの部分で構成されています：

1. 署名者が`秘密鍵`（非公開）を使用して`メッセージ`（公開）に対する`署名`（公開）を作成します。
2. 他の人が`メッセージ`（公開）と`署名`（公開）を使用して署名者の`公開鍵`（公開）を復元し、署名を検証します。

`ECDSA`ライブラリと一緒にこれら2つの部分を説明します。このチュートリアルで使用される`秘密鍵`、`公開鍵`、`メッセージ`、`イーサリアム署名メッセージ`、`署名`は以下の通りです：

```
秘密鍵: 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b
公開鍵: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
メッセージ: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
イーサリアム署名メッセージ: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
署名: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

### 署名の作成

**1. メッセージのパッキング：** イーサリアム`ECDSA`標準では、署名される`メッセージ`は一組のデータの`keccak256`ハッシュで、`bytes32`型です。署名したい内容は`abi.encodePacked()`関数を使用してパッキングし、`keccak256()`を使用してハッシュを計算して`メッセージ`とします。この例では、`メッセージ`は'uint256`型変数と`address`型変数から取得されます。

```solidity
/*
 * ミントアドレス（address型）とtokenId（uint256型）を連結してメッセージmsgHashを形成
 * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
 * _tokenId: 0
 * 対応するメッセージmsgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
 */
function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
    return keccak256(abi.encodePacked(_account, _tokenId));
}
```

![パッキングされたメッセージ](./img/37-2.png)

**2. イーサリアム署名メッセージの計算：** `メッセージ`は実行可能なトランザクションでも他の何でもかまいません。ユーザーが誤って悪意のあるトランザクションに署名することを防ぐため、`EIP191`は`メッセージ`の前に`"\x19Ethereum Signed Message:\n32"`文字を追加し、再度`keccak256`ハッシュを行って`イーサリアム署名メッセージ`を作成することを推奨しています。`toEthSignedMessageHash()`関数で処理されたメッセージはトランザクションの実行に使用できません。

```solidity
    /**
     * @dev イーサリアム署名メッセージハッシュを返します。
     * `hash`: ハッシュ化されるメッセージ
     * イーサリアム署名標準に従います: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * および `EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * 実行可能なトランザクションの署名を防ぐため"\x19Ethereum Signed Message:\n32"文字列を追加します。
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // ハッシュの長さは32
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
```

処理されたメッセージは：

```
イーサリアム署名メッセージ: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
```

![イーサリアム署名メッセージ](./img/37-3.png)

**3-1. ウォレットで署名：** 日常的な操作では、ほとんどのユーザーがこの方法でメッセージに署名します。署名が必要なメッセージを取得した後、`Metamask`ウォレットを使用して署名する必要があります。`Metamask`の`personal_sign`メソッドは自動的に`メッセージ`を`イーサリアム署名メッセージ`に変換してから署名を開始します。そのため、`メッセージ`と`署名者ウォレットアカウント`を入力するだけで済みます。なお、入力する`署名者ウォレットアカウント`は`Metamask`で現在接続されているアカウントと一致している必要があります。

したがって、まず例の`秘密鍵`を`Metamask`ウォレットにインポートし、ブラウザの`コンソール`ページを開く必要があります：`Chromeメニュー-その他のツール-開発者ツール-Console`。ウォレットに接続された状態で（OpenSeaなどに接続、そうでなければエラーが発生）、以下の手順を順番に入力して署名します：

```
ethereum.enable()
account = "0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2"
hash = "0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c"
ethereum.request({method: "personal_sign", params: [account, hash]})
```

作成された署名は返された結果（`PromiseResult`）で確認できます。異なるアカウントは異なる秘密鍵を持ち、作成される署名値も異なります。チュートリアルの秘密鍵を使用して作成された署名は以下の通りです：

```
0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![ブラウザコンソールでMetamaskを通じて署名](./img/37-4.jpg)

**3-2. web3.pyで署名：** バッチ呼び出しにおいては、コードでの署名が好まれます。以下はweb3.pyに基づく実装です。

これは`web3`ライブラリと`eth_account`モジュールを使用して、与えられた秘密鍵とイーサリアムアドレスでメッセージに署名するPythonコードです。Ankr ETH RPCエンドポイントに接続し、メッセージのkeccakハッシュと結果の署名を出力します。

実行結果は以下の通りです。計算されたメッセージ、署名、および以前の例は一致しています。

```
メッセージ：0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
署名：0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

### 署名の検証

署名を検証するには、検証者は`メッセージ`、`署名`、およびメッセージの署名に使用された`公開鍵`を持っている必要があります。署名を検証できるのは、`秘密鍵`の所有者のみがそのトランザクションに対してそのような署名を生成でき、他の誰もできないからです。

**4. 署名とメッセージから公開鍵を復元：** `署名`は数学的アルゴリズムによって生成されます。ここでは`rsv署名`を使用し、これは`r, s, v`の情報を含みます。次に、`r, s, v`と`イーサリアム署名メッセージ`から`公開鍵`を取得できます。以下の`recoverSigner()`関数は上記の手順を実装しています。`イーサリアム署名メッセージ _msgHash`と`署名 _signature`から`公開鍵`を復元します（シンプルなインラインアセンブリを使用）：

```solidity
   // @dev _msgHashと署名_signatureから署名者アドレスを復元
    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address) {
        // 署名の長さをチェック。65は標準的なr,s,v署名の長さ。
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 現在、アセンブリを使用してのみ署名からr,s,vの値を取得可能。
        assembly {
            /*
            最初の32バイトは署名の長さを保存（動的配列保存ルール）
            add(sig, 32) = 署名ポインタ + 32
            署名の最初の32バイトをスキップすることと等価
            mload(p) はメモリアドレスpから次の32バイトのデータをロード
            */
            // 長さデータの後の次の32バイトを読み取り
            r := mload(add(_signature, 0x20))
            // rの後の次の32バイトを読み取り
            s := mload(add(_signature, 0x40))
            // 最後のバイトを読み取り
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // ecrecover（グローバル関数）を使用してmsgHash、r,s,vから署名者アドレスを復元
        return ecrecover(_msgHash, v, r, s);
    }
```

パラメータは：

```
_msgHash：0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
_signature：0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![署名とメッセージによる公開鍵の復元](./img/37-8.png)

**5. 公開鍵の比較と署名の検証：** 次に、復元された`公開鍵`と署名者の公開鍵`_signer`を比較して等しいかどうかを判定するだけです：等しければ署名は有効、そうでなければ署名は無効です。

```solidity
/**
* @dev ECDSAを通じて署名アドレスが正しいかを検証します。正しければtrueを返します。
* _msgHashはメッセージのハッシュです。
* _signatureは署名です。
* _signerは署名者のアドレスです。
*/
function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns (bool) {
    return recoverSigner(_msgHash, _signature) == _signer;
}
```

パラメータは：

```
_msgHash：0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
_signature：0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
_signer：0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
```

![公開鍵の比較と署名の検証](./img/37-9.png)

## 署名を使用したNFTホワイトリストの発行

`NFT`プロジェクトは`ECDSA`の機能を使用してホワイトリストを発行できます。署名はオフチェーンで行われ、`gas`を必要としないため、このホワイトリスト発行モードは`マークルツリー`モードよりも経済的です。方法は非常にシンプルです。プロジェクトがプロジェクトアカウントを使用してホワイトリスト発行アドレスに署名します（アドレスがミントできる`tokenId`を追加可能）。そして、`ミント`時に`ECDSA`を使用して署名が有効かをチェックします。有効であれば`ミント`を許可します。

`SignatureNFT`コントラクトは署名を使用した`NFT`ホワイトリストの発行を実装しています。

### 状態変数

コントラクトには2つの状態変数があります：
- `signer`：`公開鍵`、プロジェクト署名アドレス。
- `mintedAddress`は`mapping`で、既に`ミント`されたアドレスを記録します。

### 関数

コントラクトには4つの関数があります：
- コンストラクタは`NFT`の名前とシンボル、`ECDSA`署名の`signer`アドレスを初期化します。
- `mint()`関数は3つのパラメータを受け取ります：アドレス`address`、`tokenId`、`_signature`、署名が有効かを検証します：有効であれば、`tokenId`の`NFT`を`address`アドレスにミントし、`mintedAddress`に記録します。`getMessageHash()`、`ECDSA.toEthSignedMessageHash()`、`verify()`関数を呼び出します。
- `getMessageHash()`関数は`ミント`アドレス（`address`型）と`tokenId`（`uint256`型）を組み合わせて`メッセージ`にします。
- `verify()`関数は`ECDSA`ライブラリの`verify()`関数を呼び出して`ECDSA`署名検証を行います。

```solidity
contract SignatureNFT is ERC721 {
    // ミントリクエストに署名するアドレス
    address immutable public signer;

    // ミントに既に使用されたアドレスを追跡するマッピング
    mapping(address => bool) public mintedAddress;

    // NFTコレクションの名前、シンボル、署名者アドレスを初期化するコンストラクタ関数
    constructor(string memory _name, string memory _symbol, address _signer)
    ERC721(_name, _symbol)
    {
        signer = _signer;
    }

    // ECDSAを使用して署名を検証し、指定されたアドレスに指定されたIDで新しいトークンをミント
    function mint(address _account, uint256 _tokenId, bytes memory _signature)
    external
    {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // アドレスとトークンIDを連結してメッセージハッシュを作成
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash); // イーサリアム署名メッセージハッシュを計算
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // ECDSAを使用して署名を検証
        require(!mintedAddress[_account], "Already minted!"); // アドレスがまだミントに使用されていないことを確認

        mintedAddress[_account] = true; // アドレスがミントに使用されたことを記録
        _mint(_account, _tokenId); // 指定されたアドレスに新しいトークンをミント
    }

    /*
     * アドレスとトークンIDを連結してメッセージハッシュを作成
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 対応するメッセージハッシュ: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // ECDSAライブラリを使用して署名を検証
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}
```

### `remix`検証

- イーサリアムで`署名`をオフチェーンで署名し、`tokenId = 0`で`_account`アドレスをホワイトリストに追加します。使用されるデータについては<`ECDSA`コントラクト>セクションを参照してください。

- 以下のパラメータで`SignatureNFT`コントラクトをデプロイします：

```
_name: WTF Signature
_symbol: WTF
_signer: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
```

SignatureNFTコントラクトのデプロイ。

ECDSA検証を使用してコントラクトに署名・ミントするために`mint()`関数を呼び出します。パラメータは以下の通りです：

```
_account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
_tokenId: 0
_signature: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![SignatureNFTコントラクトのデプロイ](./img/37-6.png)

- `ownerOf()`関数を呼び出すことで、`tokenId = 0`が正常にアドレス`_account`にミントされたことが確認でき、コントラクトが正常に実行されたことが分かります！

![tokenId 0の所有者が変更され、コントラクトが正常に実行されたことを示します！](./img/37-7.png)

## まとめ

この講義では、イーサリアムのデジタル署名`ECDSA`、`ECDSA`を使用した署名の作成と検証方法、`ECDSA`コントラクト、およびそれらを使用した`NFT`ホワイトリストの配布について紹介しました。コードの`ECDSA`ライブラリは`OpenZeppelin`の同じライブラリを簡素化したものです。

- 署名はオフチェーンで行われ、`gas`を必要としないため、このホワイトリスト配布モデルは`マークルツリー`モデルよりもコスト効率が良いです；
- ただし、ユーザーが署名を取得するために中央集権的なインターフェースにリクエストを送る必要があるため、必然的にある程度の分散化が犠牲になります；
- もう一つの利点は、ホワイトリストを動的に変更できることです。プロジェクトの中央バックエンドインターフェースが任意の新しいアドレスからのリクエストを受け入れ、ホワイトリスト署名を提供できるため、コントラクトに事前にハードコードする必要がありません。