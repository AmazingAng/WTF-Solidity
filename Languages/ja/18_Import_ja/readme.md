---
title: 18. Import
tags:
  - solidity
  - advanced
  - wtfacademy
  - import
---

# WTF Solidity 超シンプル入門: 18. import

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy\_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

Solidity において、`import`文を使うことで、別のファイルの内容を参照することができ、コードの再利用性と構造化を向上させることができます。このチュートリアルでは、Solidity で`import`文の使い方について説明します。

## `import`の使い方

- 相対パスを使う場合、例：

  ```text
  ファイル構造
  ├── Import.sol
  └── Yeye.sol

  // 相対パスを使ってimport
  import './Yeye.sol';
  ```

- ソースファイルの URL を使って、インターネット上のコントラクトを`グローバルシンボル`（`global symbols`）として import する例：

  ```text
  // URL を使ってimport
  import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
  ```

- `npm`のディレクトリを使って import する例：

  ```solidity
  import '@openzeppelin/contracts/access/Ownable.sol';
  ```

- `グローバルシンボル`（`global symbols`）を指定し、特定のコントラクトを import する例：

  ```solidity
  import {Yeye} from './Yeye.sol';
  ```

- コード中の`import`のポジション：バージョン番号を宣言した後にあり、コード本体の前にある。

## `import`のテスト

以下のテストコードを使って、外部ソースコードが正常にインポートされたかどうかをテストできます：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 相対パスを使ってimport
import './Yeye.sol';
// グローバルシンボルを使って特定のコントラクトをimport
import {Yeye} from './Yeye.sol';
// URL を使ってimport
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
// OpenZeppelinコントラクトのライブラリをimport
import '@openzeppelin/contracts/access/Ownable.sol';

contract Import {
    // Addressライブラリを正常にimportできた
    using Address for address;
    // yeye変数を宣言
    Yeye yeye = new Yeye();

    // yeyeの関数を呼び出せるかテスト
    function test() external{
        yeye.hip();
    }
}
```

![result](./img/18-1.png)

## まとめ

今回、私たちは`import`文を使って外部ソースコードをインポートする方法について説明しました。`import`文を使うことで、他のファイルに書かれたコントラクトや関数を参照することができ、他の人が書いたコードを直接インポートすることもできます。非常に便利です。
