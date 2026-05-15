---
title: S06. 署名リプレイ
tags:
  - solidity
  - security
  - signature
---

# WTF Solidity 合約セキュリティ: S06. 署名リプレイ

私は最近Solidityを学び直して詳細を固めており、「WTF Solidity 合約セキュリティ」を書いています。初心者向けの内容で（プログラミング上級者は他のチュートリアルをお探しください）、毎週1-3講座を更新しています。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、スマートコントラクトの署名リプレイ（Signature Replay）攻撃と予防方法について紹介します。この攻撃は間接的に著名なマーケットメーカーWintermuteが2000万枚の$OPを盗まれる原因となりました。

## 署名リプレイ

学生時代、先生はよく親の署名を求めましたが、時々親が忙しい時、私は「親切に」以前の署名を真似して書き写していました。ある意味で、これが署名リプレイです。

ブロックチェーンにおいて、デジタル署名はデータの署名者を特定し、データの完全性を検証するために使用できます。取引を送信する際、ユーザーは秘密鍵で取引に署名し、他の人が取引が対応するアカウントから発行されたことを検証できるようにします。スマートコントラクトも`ECDSA`アルゴリズムを利用して、ユーザーがオフチェーンで作成した署名を検証し、その後ミントや転送などのロジックを実行できます。デジタル署名の詳細については、[WTF Solidity第37講：デジタル署名](https://github.com/AmazingAng/WTF-Solidity/blob/main/37_Signature/readme.md)をご覧ください。

デジタル署名には一般的に2つのリプレイ攻撃があります：

1. 通常のリプレイ：本来一度だけ使用すべき署名を複数回使用する。NBA公式が発行した《The Association》シリーズNFTがこの攻撃により上万枚が無料でミントされました。
2. クロスチェーンリプレイ：本来一つのチェーンで使用すべき署名を、別のチェーンで再利用する。マーケットメーカーWintermuteがクロスチェーンリプレイ攻撃により2000万枚の$OPを盗まれました。

![](./img/S06-1.png)

## 脆弱性コントラクトの例

以下の`SigReplay`コントラクトは`ERC20`トークンコントラクトで、ミント関数に署名リプレイ脆弱性があります。これはオフチェーン署名を使用してホワイトリストアドレス`to`が対応する数量`amount`のトークンをミントできるようにします。コントラクト内には`signer`アドレスが保存されており、署名が有効かどうかを検証します。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// アクセス制御エラーの例
contract SigReplay is ERC20 {

    address public signer;

    // コンストラクタ：トークン名と記号を初期化
    constructor() ERC20("SigReplay", "Replay") {
        signer = msg.sender;
    }

    /**
     * 署名リプレイ脆弱性があるミント関数
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * 署名： 0x5a4f1ad4d8bd6b5582e658087633230d9810a0b7b8afa791e3f94cc38947f6cb1069519caf5bba7b975df29cbfdb4ada355027589a989435bf88e825841452f61b
     */
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }

    /**
     * toアドレス（address型）とamount（uint256型）をメッセージmsgHashに結合
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * 対応するメッセージmsgHash: 0xb4a4ba10fbd6886a312ec31c54137f5714ddc0e93274da8746a36d2fa96768be
     */
    function getMessageHash(address to, uint256 amount) public pure returns(bytes32){
        return keccak256(abi.encodePacked(to, amount));
    }

    /**
     * @dev イーサリアム署名メッセージを取得
     * `hash`：メッセージハッシュ
     * イーサリアム署名標準に準拠：https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * および`EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * "\x19Ethereum Signed Message:\n32"フィールドを追加し、実行可能な取引への署名を防ぐ。
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // ECDSA検証
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool){
        return ECDSA.recover(_msgHash, _signature) == signer;
    }
```

**注意** ミント関数`badMint()`は`signature`の重複チェックを行っていないため、同じ署名を複数回使用でき、無限にトークンをミントできます。

```solidity
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }
```

## `Remix`再現

**1.** `SigReplay`コントラクトをデプロイし、署名者アドレス`signer`がデプロイウォレットアドレスに初期化されます。

![](./img/S06-2.png)

**2.** `getMessageHash`関数を利用してメッセージを取得します。

![](./img/S06-3.png)

**3.** `Remix`デプロイパネルの署名ボタンをクリックし、秘密鍵でメッセージに署名します。

![](./img/S06-4.png)

**4.** `badMint`を繰り返し呼び出して署名リプレイ攻撃を行い、大量のトークンをミントします。

![](./img/S06-5.png)

## 予防方法

署名リプレイ攻撃には主に2つの予防方法があります：

1. 使用済みの署名を記録する。例えば、既にトークンをミントしたアドレス`mintedAddress`を記録し、署名の再利用を防ぐ：

    ```solidity
    mapping(address => bool) public mintedAddress;   // 既にmintしたアドレスを記録

    function goodMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        // そのアドレスが既にmintしたかチェック
        require(!mintedAddress[to], "Already minted");
        // mintしたアドレスを記録
        mintedAddress[to] = true;
        _mint(to, amount);
    }
    ```

2. `nonce`（取引毎に増加する数値）と`chainid`（チェーンID）を署名メッセージに含める。これにより、通常のリプレイとクロスチェーンリプレイ攻撃を防ぐことができる：

    ```solidity
    uint nonce;

    function nonceMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount, nonce, block.chainid)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
        nonce++;
    }
    ```

3. ユーザーが`signature`を入力するシナリオでは、`signature`の長さを検証し、長さが`65bytes`であることを確認する必要がある。そうでなければ署名リプレイ問題が発生する：

    ```solidity
    function mint(address to, uint amount, bytes memory signature) public {
        require(signature.length == 65, "Invalid signature length");
        ...
    }
    ```

## まとめ

今回は、スマートコントラクトにおける署名リプレイ脆弱性について紹介し、3つの予防方法を紹介しました：

1. 使用済みの署名を記録し、二度目の使用を防ぐ。

2. `nonce`と`chainid`を署名メッセージに含める。

3. ユーザーが`signature`を入力するシナリオでは、`signature`の長さを検証し、長さが`65bytes`であることを確認する。そうでなければ署名リプレイ問題が発生する。