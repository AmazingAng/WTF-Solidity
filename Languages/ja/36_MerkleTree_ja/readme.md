---
title: 36. マークルツリー
tags:
  - solidity
  - application
  - wtfacademy
  - ERC721
  - Merkle Tree
---

# WTF Solidity極簡入門: 36. マークルツリー

私は最近Solidityを再学習し、詳細を固めながら「WTF Solidity極簡入門」を書いています。これは初心者向けです（プログラミング上級者は他のチュートリアルを参照してください）。毎週1-3講を更新します。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[WeChatグループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

-----

この講義では、`マークルツリー`について紹介し、それを使用して`NFT`ホワイトリストを配布する方法を説明します。

## `マークルツリー`

`マークルツリー`は、メルクルツリーまたはハッシュツリーとも呼ばれ、ブロックチェーンの基本的な暗号技術であり、ビットコインやイーサリアムブロックチェーンで広く使用されています。`マークルツリー`は下から上に構築される暗号化ツリーで、各リーフは対応するデータのハッシュに対応し、各非リーフは2つの子ノードのハッシュを表します。

![マークルツリー](./img/36-1.png)

`マークルツリー`は大規模データ構造の内容を効率的かつ安全に検証（`マークル証明`）することを可能にします。`N`個のリーフノードを持つ`マークルツリー`において、指定されたデータが有効か（`マークルツリー`のリーフノードに属するか）を検証するのに必要なのは`log(N)`個のデータ（`proofs`）のみであり、非常に効率的です。データが間違っているか、与えられた`proof`が間違っている場合、`root`の根の値を復元することはできません。

以下の例では、リーフ`L1`の`マークル証明`は`Hash 0-1`と`Hash 1`です：これら2つの値を知ることで、`L1`の値が`マークルツリー`のリーフにあるかどうかを検証できます。なぜでしょうか？
リーフ`L1`を通じて`Hash 0-0`を計算でき、`Hash 0-1`も知っているので、`Hash 0-0`と`Hash 0-1`を組み合わせて`Hash 0`を計算でき、`Hash 1`も知っているので、`Hash 0`と`Hash 1`を組み合わせて`Top Hash`（根ノードのハッシュ）を計算できるからです。

![マークル証明](./img/36-2.png)

## `マークルツリー`の生成

[ウェブページ](https://lab.miguelmota.com/merkletreejs/example/)またはJavascriptライブラリ[merkletreejs](https://github.com/miguelmota/merkletreejs)を使用して`マークルツリー`を生成できます。

ここでは、ウェブページを使用して`4`つのアドレスをリーフノードとする`マークルツリー`を生成します。リーフノードの入力：

```solidity
    [
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
    ]
```

メニューで`Keccak-256`、`hashLeaves`、`sortPairs`オプションを選択し、`Compute`をクリックすると、`マークルツリー`が生成されます。`マークルツリー`は以下のように展開されます：

```
└─ Root: eeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
   ├─ 9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65
   │  ├─ Leaf0：5931b4ed56ace4c46b68524cb5bcbf4195f1bbaacbe5228fbd090546c88dd229
   │  └─ Leaf1：999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb
   └─ 4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c
      ├─ Leaf2：04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54
      └─ Leaf3：dfbe3e504ac4e35541bebad4d0e7574668e16fefa26cd4172f93e18b59ce9486
```

![マークルツリーの生成](./img/36-3.png)

## `マークル証明`の検証

ウェブサイトを通じて、`アドレス0`の`proof`を以下のように取得できます。これは図2の青いノードのハッシュ値です：

```solidity
[
  "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",
  "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c"
]
```

`MerkleProof`ライブラリを使用して検証します：

```solidity
library MerkleProof {
    /**
     * @dev `proof`と`leaf`から再構築された`root`が与えられた`root`と等しい場合、`true`を返します。データが有効であることを意味します。
     * 再構築中、リーフノードペアと要素ペアの両方がソートされます。
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev `leaf`と`proof`から計算された`マークルツリー`の`root`を返します。
     * `proof`は再構築された`root`が与えられた`root`と等しい場合のみ有効です。
     * 再構築中、リーフノードペアと要素ペアの両方がソートされます。
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    // ソート済みペアハッシュ
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}
```

`MerkleProof`ライブラリには3つの関数が含まれています：

1. `verify()`関数：`proof`を使用して`leaf`が`root`を根とする`マークルツリー`に属するかを検証します。属する場合は`true`を返します。`processProof()`関数を呼び出します。

2. `processProof()`関数：`proof`と`leaf`を順番に使用して`マークルツリー`の`root`を計算します。`_hashPair()`関数を呼び出します。

3. `_hashPair()`関数：`keccak256()`関数を使用して非根ノードに対応する2つの子ノードのハッシュ（ソート済み）を計算します。

`verify()`関数に`アドレス0`、`root`、および対応する`proof`を入力すると、`true`を返します。なぜなら`アドレス0`は`root`を根とする`マークルツリー`にあり、`proof`が正しいからです。これらの値のいずれかを変更すると、`false`を返します。

`マークルツリー`を使用したNFTホワイトリストの配布：

800個のアドレスのホワイトリストを更新すると、ガス手数料で1 ETH以上を簡単に消費する可能性があります。しかし、`マークルツリー`検証を使用すると、`leaf`と`proof`はバックエンドに存在でき、チェーン上には`root`の値を1つだけ保存すればよく、非常にガス効率的です。多くの`ERC721` NFTや`ERC20`標準トークンのホワイトリスト/エアドロップは`マークルツリー`を使用して発行されており、Optimismのエアドロップなどがあります。

ここでは、`MerkleTree`コントラクトを使用してNFTホワイトリストを配布する方法を紹介します：

```solidity
contract MerkleTree is ERC721 {
    bytes32 immutable public root; // マークルツリーの根
    mapping(address => bool) public mintedAddress; // 既にミントされたアドレスを記録

    // コンストラクタ、NFTコレクションの名前とシンボル、マークルツリーの根を初期化
    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

    // マークルツリーを使用してアドレスを検証し、ミント
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // マークル検証が通過
        require(!mintedAddress[account], "Already minted!"); // アドレスがまだミントされていない

        mintedAddress[account] = true; // ミントされたアドレスを記録
        _mint(account, tokenId); // ミント
    }

    // マークルツリーのリーフのハッシュ値を計算
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // マークルツリー検証、MerkleProofライブラリのverify()関数を呼び出し
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
```

`MerkleTree`コントラクトは`ERC721`標準を継承し、`MerkleProof`ライブラリを利用しています。

### 状態変数

コントラクトには2つの状態変数があります：
- `root`は`マークルツリー`の根を保存し、コントラクトデプロイ時に割り当てられます。
- `mintedAddress`は`mapping`で、ミントされたアドレスを記録します。ミント成功後に値が割り当てられます。

### 関数

コントラクトには4つの関数があります：
- コンストラクタ：NFTの名前とシンボル、`マークルツリー`の`root`を初期化します。
- `mint()`関数：ホワイトリストを使用してNFTをミントします。引数として`account`（ホワイトリストアドレス）、`tokenId`（ミントされるID）、`proof`を取ります。関数はまず`address`がホワイトリストにあるかを検証します。検証が通過すると、ID `tokenId`のNFTがアドレスにミントされ、`mintedAddress`に記録されます。このプロセスは`_leaf()`関数と`_verify()`関数を呼び出します。
- `_leaf()`関数：`マークルツリー`のリーフアドレスのハッシュを計算します。
- `_verify()`関数：`MerkleProof`ライブラリの`verify()`関数を呼び出して`マークルツリー`を検証します。

### `Remix`検証

上記の例の4つのアドレスをホワイトリストとして使用し、`マークルツリー`を生成します。3つの引数で`MerkleTree`コントラクトをデプロイします：

```solidity
name = "WTF MerkleTree"
symbol = "WTF"
merkleroot = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
```

![MerkleTreeコントラクトのデプロイ](./img/36-5.png)

次に、`mint`関数を実行してアドレス0のために`NFT`をミントします。3つのパラメータを使用します：

```solidity
account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
tokenId = 0
proof = ["0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb", "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c"]
```

`ownerOf`関数を使用して、NFTの`tokenId` 0がアドレス0にミントされたことを検証でき、コントラクトが正常に実行されたことが確認できます。

`tokenId`の保有者を0に変更しても、コントラクトは正常に実行されます。

この時点で再度`mint`関数を呼び出すと、アドレスは`マークル証明`検証を通過できますが、アドレスが既に`mintedAddress`に記録されているため、`"Already minted!"`によりトランザクションが中止されます。

この講義では、`マークルツリー`の概念、簡単な`マークルツリー`の生成方法、スマートコントラクトを使用した`マークルツリー`の検証方法、およびそれを使用して`NFT`ホワイトリストを配布する方法を紹介しました。

実際の使用では、複雑な`マークルツリー`はJavascriptの`merkletreejs`ライブラリを使用して生成・管理でき、チェーン上には1つの根の値のみを保存すればよく、非常にガス効率的です。多くのプロジェクトチームが`マークルツリー`を使用してホワイトリストを配布することを選択しています。