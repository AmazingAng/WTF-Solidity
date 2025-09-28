---
title: S10. ハニーポット
tags:
  - solidity
  - security
  - erc20
  - swap
---

# WTF Solidity 合約セキュリティ: S10. ハニーポット

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、ハニーポットコントラクトとその予防方法について紹介します（英語では蜜罐代幣honeypot tokenと呼ばれます）。

## ハニーポット入門

[貔貅（ピクシウ）](https://en.wikipedia.org/wiki/Pixiu)は中国の神獣で、天界で規則を破ったために玉皇大帝に懲罰され、肛門を塞がれてしまい、食べることしかできずに排泄できない、人々の財を集めることができる存在です。しかしWeb3の世界では、貔貅は不吉な獣、投資者の天敵となりました。ハニーポットの特徴：投資者は買うことしかできず売ることができない、プロジェクト方のアドレスのみが売却可能です。

通常、ハニーポットには以下のライフサイクルがあります：

1. 悪意のあるプロジェクト方がハニーポットトークンコントラクトをデプロイします。
2. ハニーポットトークンを宣伝して個人投資家を呼び込みます。買うことしかできないため、トークン価格は上昇し続けます。
3. プロジェクト方が`rug pull`で資金を持ち逃げします。

![](./img/S10-1.png)

ハニーポットコントラクトの原理を学ぶことで、より良く識別し、割られることを避け、しぶとい個人投資家になることができます！

## ハニーポットコントラクト

ここでは、極めてシンプルなERC20トークンハニーポットコントラクト`Pixiu`を紹介します。このコントラクトでは、コントラクトオーナーのみが`uniswap`でトークンを売却でき、他のアドレスはできません。

`Pixiu`は状態変数`pair`を持ち、`uniswap`中の`Pixiu-ETH LP`のペアアドレスを記録します。主に3つの関数があります：

1. コンストラクタ：トークンの名前とシンボルを初期化し、`uniswap`と`create2`の原理に基づいて`LP`コントラクトアドレスを計算します。詳細については[WTF Solidity 第25講: Create2](https://github.com/AmazingAng/WTF-Solidity/blob/main/25_Create2/readme.md)を参照してください。このアドレスは`_update()`関数で使用されます。
2. `mint()`：鋳造関数、`owner`アドレスのみが呼び出し可能で、`Pixiu`トークンを鋳造するために使用されます。
3. `_update()`：`ERC20`トークンが転送される前に呼び出される関数です。この中で、転送先アドレス`to`が`LP`の場合、つまり個人投資家が売却する場合に、取引が`revert`するように制限しています。呼び出し者が`owner`の場合のみ成功できます。これがハニーポットコントラクトの核心です。

```solidity
// 極簡ハニーポットERC20トークン、買うことのみ可能、売ることはできない
contract HoneyPot is ERC20, Ownable {
    address public pair;

    // コンストラクタ：トークンの名前とシンボルを初期化
    constructor() ERC20("HoneyPot", "Pi Xiu") {
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // goerli uniswap v2 factory
        address tokenA = address(this); // ハニーポットトークンアドレス
        address tokenB = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //  goerli WETH
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //tokenAとtokenBを大小順にソート
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // ペアアドレスを計算
        pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        salt,
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));
    }

    /**
     * 鋳造関数、コントラクトオーナーのみ呼び出し可能
     */
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20-_update}.
     * ハニーポット関数：コントラクトオーナーのみ売却可能
    */
    function _update(
      address from,
      address to,
      uint256 amount
  ) internal virtual override {
     if(to == pair){
        require(from == owner(), "Can not Transfer");
      }
      super._update(from, to, amount);
  }
}
```

## `Remix`での再現

`Goerli`テストネット上で`Pixiu`コントラクトをデプロイし、`uniswap`取引所でデモンストレーションを行います。

1. `Pixiu`コントラクトをデプロイします。
![](./img/S10-2.png)

2. `mint()`関数を呼び出し、自分に`100000`枚のハニーポットコインを鋳造します。
![](./img/S10-3.png)

3. [uniswap](https://app.uniswap.org/#/add/v2/ETH)取引所に入り、ハニーポットコインの流動性を作成し（v2）、`10000`ハニーポットコインと`0.1`ETHを提供します。
![](./img/S10-4.png)

4. `100`ハニーポットコインを売却すると、操作が成功します。
![](./img/S10-5.png)

5. 別のアカウントに切り替え、`0.01`ETHを使ってハニーポットコインを購入すると、操作が成功します。
![](./img/S10-6.png)

6. ハニーポットコインを売却しようとすると、取引がポップアップしません。
![](./img/S10-7.png)

## 潜在的な偽装

関連するハニーポット検査を回避するため、一部のハニーポットコントラクトは以下のような一連の偽装を行います：

1. 例えば、非特権ユーザーの転送に対して、リバートを行わずに状態を変更せずに保持し、表面上は取引が成功したように見せかけますが、実際にはユーザーの真の取引意図を実現していません。

2. 偽のイベントを発行し、存在しないイベントをemitしてイベントを監視しているウォレットやブラウザを誤導し、間違った表示を行わせ、ユーザーに間違った判断をさせます。

## 予防方法

ハニーポットコインは個人投資家がオンチェーンで全賭けする際に最も遭遇しやすい詐欺で、形式も多様で、予防は非常に困難です。以下の点をお勧めし、ハニーポットに割られるリスクを下げることができます：

1. ブロックチェーンエクスプローラー（例：[etherscan](https://etherscan.io/)）でコントラクトがオープンソースかどうかを確認し、オープンソースの場合はコードを分析してハニーポット脆弱性があるかどうかを確認します。

2. プログラミング能力がない場合は、ハニーポット識別ツールを使用できます。例：[Token Sniffer](https://tokensniffer.com/)や[Ave Check](https://ave.ai/check)で、スコアが低い場合は高確率でハニーポットです。

3. プロジェクトに監査レポートがあるかを確認します。

4. プロジェクトの公式サイトやソーシャルメディアを慎重に検査します。

5. 理解しているプロジェクトのみに投資し、十分な調査（DYOR）を行います。

6. tenderly、phalconフォークを使用してハニーポットの売却をシミュレートし、失敗した場合はハニーポットトークンであることを確定します。

## まとめ

このレッスンでは、ハニーポットコントラクトとハニーポットを予防する方法を紹介しました。ハニーポットはすべての個人投資家が通る道で、皆がそれを憎んでいます。また、最近ではハニーポット`NFT`も登場し、悪意のあるプロジェクト方が`ERC721`の転送や承認関数を修正することで、一般投資家がそれらを売却できないようにしています。ハニーポットコントラクトの原理と予防方法を理解することで、ハニーポットを購入する確率を大幅に減らし、資金をより安全にすることができます。皆さんは継続的に学習する必要があります。