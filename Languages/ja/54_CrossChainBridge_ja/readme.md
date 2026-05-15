---
title: 54. クロスチェーンブリッジ
tags:
  - solidity
  - erc20
  - eip712
  - openzepplin
---

# WTF Solidity 超シンプル入門: 54. クロスチェーンブリッジ

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、資産をあるブロックチェーンから別のブロックチェーンに転送できる基盤インフラであるクロスチェーンブリッジについて紹介し、シンプルなクロスチェーンブリッジを実装します。

## 1. クロスチェーンブリッジとは

クロスチェーンブリッジは、2つ以上のブロックチェーン間でデジタル資産と情報を移動できるブロックチェーンプロトコルです。例えば、イーサリアムメインネット上で動作するERC20トークンは、クロスチェーンブリッジを通じて他のイーサリアム互換サイドチェーンや独立チェーンに転送できます。

同時に、クロスチェーンブリッジはブロックチェーンでネイティブにサポートされているわけではなく、クロスチェーン操作には信頼できる第三者が実行する必要があり、これもリスクをもたらします。近年、クロスチェーンブリッジに対する攻撃により、すでに**20億ドル**を超えるユーザー資産の損失が発生しています。

## 2. クロスチェーンブリッジの種類

クロスチェーンブリッジには主に以下の3つのタイプがあります：

- **Burn/Mint**: ソースチェーンでトークンを燃焼（burn）し、ターゲットチェーンで同等の数量のトークンを作成（mint）します。この方法の利点は、トークンの総供給量が変わらないことですが、クロスチェーンブリッジがトークンの鋳造権限を持つ必要があり、プロジェクト側が独自のクロスチェーンブリッジを構築するのに適しています。

    ![](./img/54-1.png)

- **Stake/Mint**: ソースチェーンでトークンをロック（stake）し、ターゲットチェーンで同等の数量のトークン（証明書）を作成（mint）します。ソースチェーンのトークンはロックされ、トークンがターゲットチェーンからソースチェーンに戻される際に再びアンロックされます。これは一般的なクロスチェーンブリッジで使用される方案で、権限は必要ありませんが、リスクも大きく、ソースチェーンの資産がハッカーに攻撃された場合、ターゲットチェーン上の証明書は価値のないものになります。

    ![](./img/54-2.png)

- **Stake/Unstake**: ソースチェーンでトークンをロック（stake）し、ターゲットチェーンで同等の数量のトークンを解放（unstake）します。ターゲットチェーン上のトークンはいつでもソースチェーンのトークンと交換できます。この方法では、クロスチェーンブリッジが両方のチェーンでロックされたトークンを持つ必要があり、閾値が高く、一般的にユーザーがクロスチェーンブリッジでトークンをロックするインセンティブが必要です。

    ![](./img/54-3.png)

## 3. シンプルなクロスチェーンブリッジの構築

このクロスチェーンブリッジをより良く理解するため、シンプルなクロスチェーンブリッジを構築し、GoerliテストネットとSepoliaテストネット間でのERC20トークン転送を実装します。burn/mint方式を使用し、ソースチェーン上のトークンが破棄され、ターゲットチェーン上で作成されます。このクロスチェーンブリッジは、スマートコントラクト（両方のチェーンにデプロイ）とEthers.jsスクリプトで構成されます。

> **注意してください**、これは非常にシンプルなクロスチェーンブリッジの実装で、教育目的のみです。トランザクション失敗、チェーンの再編成などの可能性のある問題を処理していません。本番環境では、専門的なクロスチェーンブリッジソリューションまたは他の十分にテストされ、監査されたフレームワークの使用を推奨します。

### 3.1 クロスチェーントークンコントラクト

まず、GoerliとSepoliaテストネットにERC20トークンコントラクト `CrossChainToken` をデプロイする必要があります。このコントラクトでは、トークンの名前、シンボル、総供給量を定義し、クロスチェーン転送用の `bridge()` 関数があります。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainToken is ERC20, Ownable {

    // Bridgeイベント
    event Bridge(address indexed user, uint256 amount);
    // Mintイベント
    event Mint(address indexed to, uint256 amount);

    /**
     * @param name トークン名
     * @param symbol トークンシンボル
     * @param totalSupply トークン供給量
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, totalSupply);
    }

    /**
     * Bridge関数
     * @param amount: 現在のチェーンでburnし、他のチェーンでmintするトークン数量
     */
    function bridge(uint256 amount) public {
        _burn(msg.sender, amount);
        emit Bridge(msg.sender, amount);
    }

    /**
     * Mint関数
     */
    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
        emit  Mint(to, amount);
    }
}
```

このコントラクトには3つの主要な関数があります：

- `constructor()`: コンストラクタで、コントラクトデプロイ時に一度呼び出され、トークンの名前、シンボル、総供給量を初期化します。

- `bridge()`: ユーザーがこの関数を呼び出してクロスチェーン転送を行います。指定された数量のトークンを破棄し、`Bridge`イベントを発行します。

- `mint()`: コントラクトの所有者のみが呼び出せる関数で、クロスチェーンイベントを処理し、`Mint`イベントを発行します。ユーザーが別のチェーンで`bridge()`関数を呼び出してトークンを破棄すると、スクリプトが`Bridge`イベントを監視し、ユーザーにターゲットチェーンでトークンを鋳造します。

### 3.2 クロスチェーンスクリプト

トークンコントラクトの後、クロスチェーンイベントを処理するサーバーが必要です。ethers.jsスクリプト（v6版）を書いて`Bridge`イベントを監視し、イベントがトリガーされた際にターゲットチェーンで同数のトークンを作成できます。Ethers.jsについて詳しくない場合は、[WTF Ethers極簡教程](https://github.com/WTFAcademy/WTF-Ethers)を読むことができます。

```javascript
import { ethers } from "ethers";

// 2つのチェーンのproviderを初期化
const providerGoerli = new ethers.JsonRpcProvider("Goerli_Provider_URL");
const providerSepolia = new ethers.JsonRpcProvider("Sepolia_Provider_URL://eth-sepolia.g.alchemy.com/v2/RgxsjQdKTawszh80TpJ-14Y8tY7cx5W2");

// 2つのチェーンのsignerを初期化
// privateKeyに管理者ウォレットの秘密鍵を入力
const privateKey = "Your_Key";
const walletGoerli = new ethers.Wallet(privateKey, providerGoerli);
const walletSepolia = new ethers.Wallet(privateKey, providerSepolia);

// コントラクトアドレスとABI
const contractAddressGoerli = "0xa2950F56e2Ca63bCdbA422c8d8EF9fC19bcF20DD";
const contractAddressSepolia = "0xad20993E1709ed13790b321bbeb0752E50b8Ce69";

const abi = [
    "event Bridge(address indexed user, uint256 amount)",
    "function bridge(uint256 amount) public",
    "function mint(address to, uint amount) external",
];

// コントラクトインスタンスを初期化
const contractGoerli = new ethers.Contract(contractAddressGoerli, abi, walletGoerli);
const contractSepolia = new ethers.Contract(contractAddressSepolia, abi, walletSepolia);

const main = async () => {
    try{
        console.log(`クロスチェーンイベントの監視を開始`)

        // chain SepoliaのBridgeイベントを監視し、Goerli上でmint操作を実行してクロスチェーンを完了
        contractSepolia.on("Bridge", async (user, amount) => {
            console.log(`Chain SepoliaでBridgeイベント: ユーザー ${user} が ${amount} トークンをburn`);

            // Goerli上でmint操作を実行
            let tx = await contractGoerli.mint(user, amount);
            await tx.wait();

            console.log(`Chain Goerliで ${user} に ${amount} トークンをmint`);
        });

        // chain GoerliのBridgeイベントを監視し、Sepolia上でmint操作を実行してクロスチェーンを完了
        contractGoerli.on("Bridge", async (user, amount) => {
            console.log(`Chain GoerliでBridgeイベント: ユーザー ${user} が ${amount} トークンをburn`);

            // Sepolia上でmint操作を実行
            let tx = await contractSepolia.mint(user, amount);
            await tx.wait();

            console.log(`Chain Sepoliaで ${user} に ${amount} トークンをmint`);
        });
    } catch(e) {
        console.log(e);
    }
}

main();
```

## Remix復現

1. GoerliとSepoliaテストチェーンでそれぞれ`CrossChainToken`コントラクトをデプロイし、コントラクトが自動的に10000枚のトークンを鋳造します

    ![](./img/54-4.png)

2. クロスチェーンスクリプト `crosschain.js` のRPCノードURLと管理者秘密鍵を補完し、GoerliとSepoliaにデプロイしたトークンコントラクトアドレスを対応する場所に記入し、スクリプトを実行します。

3. Goerliチェーン上のトークンコントラクトの`bridge()`関数を呼び出し、100枚のトークンをクロスチェーンします。

    ![](./img/54-6.png)

4. スクリプトがクロスチェーンイベントを監視し、Sepoliaチェーン上で100枚のトークンを鋳造します。

    ![](./img/54-7.png)

5. Sepoliaチェーン上で`balance()`を呼び出して残高を確認すると、トークン残高が10100枚になり、クロスチェーンが成功しました！

    ![](./img/54-8.png)

## まとめ

今回はクロスチェーンブリッジについて紹介しました。これは2つ以上のブロックチェーン間でデジタル資産と情報を移動できるもので、ユーザーがマルチチェーンで資産を操作する際の利便性を提供します。同時に、大きなリスクもあり、近年クロスチェーンブリッジに対する攻撃により、すでに**20億ドル**を超えるユーザー資産の損失が発生しています。本チュートリアルでは、シンプルなクロスチェーンブリッジを構築し、GoerliテストネットとSepoliaテストネット間でのERC20トークン転送を実装しました。このチュートリアルを通じて、クロスチェーンブリッジについてより深く理解していただけると信じています。