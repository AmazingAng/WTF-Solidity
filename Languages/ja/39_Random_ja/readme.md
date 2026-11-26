---
title: 39. Chainlinkランダム性
tags:
  - solidity
  - application
  - wtfacademy
  - ERC721
  - random
  - chainlink
---

# WTF Solidity極簡入門: 39. Chainlinkランダム性

私は最近Solidityを再学習し、詳細を固めながら「WTF Solidity極簡入門」を書いています。これは初心者向けです（プログラミング上級者は他のチュートリアルを参照してください）。毎週1-3講を更新します。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[WeChatグループ](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

多くのイーサリアムアプリケーションは乱数の使用を必要とします。例えば、NFTランダムtokenId選択、ブラインドボックス抽選、ゲームファイでの戦闘勝者のランダム決定などです。しかし、イーサリアム上のすべてのデータが公開で決定論的であるため、他のプログラミング言語のような乱数生成方法を開発者に提供できません。このチュートリアルでは、オンチェーン（ハッシュ関数）とオフチェーン（Chainlinkオラクル）の2つの乱数生成方法を紹介し、それらを使用してtokenIdランダムミントNFTを作成します。

## オンチェーン乱数生成

いくつかのオンチェーングローバル変数をシードとして使用し、`keccak256()`ハッシュ関数を使用して疑似乱数を取得できます。これは、ハッシュ関数が感度と均一性を持ち、「見た目に」ランダムな結果を生成できるためです。以下の`getRandomOnchain()`関数は、グローバル変数`block.timestamp`、`msg.sender`、`blockhash(block.number-1)`をシードとして乱数を取得します：

```solidity
/**
 * チェーン上で疑似乱数を生成します。
 * keccak256()を使用していくつかのオンチェーングローバル変数/カスタム変数をパッキングします。
 * 返す際にuint256型に変換されます。
*/
function getRandomOnchain() public view returns(uint256){
     // Remixでblockhashを生成するとエラーになります。
     bytes32 randomBytes = keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number-1)));

     return uint256(randomBytes);
}
```

**注意**：この方法は安全ではありません：
- 第一に、`block.timestamp`、`msg.sender`、`blockhash(block.number-1)`などの変数はすべて公開されています。ユーザーはこれらのシードによって生成される乱数を予測し、望む出力を選択してスマートコントラクトを実行できます。
- 第二に、マイナーは`blockhash`と`block.timestamp`を操作して、自分の利益に適した乱数を生成できます。

しかし、この方法は最も便利なオンチェーン乱数生成方法であり、多くのプロジェクト側がこれに依存して安全でない乱数を生成しています。`meebits`や`loots`などの有名なプロジェクトも含まれます。もちろん、これらのプロジェクトはすべて攻撃を受けました：攻撃者はランダムに抽選するのではなく、望む希少な`NFT`を偽造できます。

## オフチェーン乱数生成

オフチェーンで乱数を生成し、オラクルを通じてチェーンにアップロードできます。ChainlinkはVRF（Verifiable Random Function）サービスを提供しており、オンチェーン開発者はLINKトークンを支払って乱数を取得できます。Chainlink VRFには2つのバージョンがあります。第2バージョンは公式ウェブサイトでの登録と前払い手数料が必要で、使用方法は似ているため、ここでは第1バージョンVRF v1のみを紹介します。

### `Chainlink VRF`使用手順

![Chainlnk VRF](./img/39-1.png)

簡単なコントラクトを使用してChainlink VRFの使用手順を紹介します。`RandomNumberConsumer`コントラクトはVRFから乱数をリクエストし、状態変数`randomResult`に保存できます。

**1. ユーザーコントラクトが`VRFConsumerBase`を継承し、`LINK`トークンを転送**

VRFを使用して乱数を取得するには、コントラクトは`VRFConsumerBase`コントラクトを継承し、コンストラクタで`VRF Coordinator`アドレス、`LINK`トークンアドレス、一意の識別子`Key Hash`、使用料`fee`を初期化する必要があります。

**注意：** 異なるチェーンは異なるパラメータに対応します。詳細は[こちら](https://docs.chain.link/docs/vrf-contracts/v1/)を参照してください。

チュートリアルでは、`Rinkeby`テストネットを使用します。コントラクトをデプロイした後、ユーザーはいくつかの`LINK`トークンをコントラクトに転送する必要があります。テストネット`LINK`トークンは[LINKフォーセット](https://faucets.chain.link/)から取得できます。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomNumberConsumer is VRFConsumerBase {

    bytes32 internal keyHash; // VRF一意識別子
    uint256 internal fee; // VRF使用料

uint256 public randomResult; // 乱数を保存

     /**
      * chainlink VRFを使用する際、コンストラクタはVRFConsumerBaseを継承する必要があります
      * 異なるチェーンのパラメータは異なって記入されます。
      *ネットワーク: Rinkebyテストネット
      * Chainlink VRF Coordinatorアドレス: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
      * LINKトークンアドレス: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
      * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
      */
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
fee = 0.1 * 10 ** 18; // 0.1 LINK（VRF使用料、Rinkebyテストネットワーク）
    }
```

**2. ユーザーがコントラクトを通じて乱数をリクエスト**

ユーザーは`VRFConsumerBase`コントラクトから継承された`requestRandomness()`を呼び出して乱数をリクエストし、リクエスト識別子`requestId`を受け取ることができます。このリクエストは`VRF`コントラクトに渡されます。

```solidity
    /**
     * VRFコントラクトから乱数をリクエスト
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        // コントラクトに十分なLINKが必要
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");

        return requestRandomness(keyHash, fee);
    }
```

3. `Chainlink`ノードがオフチェーンで乱数とデジタル署名を生成し、`VRF`コントラクトに送信します。

4. `VRF`コントラクトが署名の有効性を検証します。

5. ユーザーコントラクトが乱数を受信して使用します。

`VRF`コントラクトで署名の有効性を検証した後、ユーザーコントラクトのコールバック関数`fulfillRandomness()`が自動的に呼び出され、オフチェーンで生成された乱数が送信されます。乱数を消費するロジックはこの関数で実装する必要があります。

注意：ユーザーが乱数をリクエストするために呼び出す`requestRandomness()`関数と、`VRF`コントラクトが乱数を返す際に呼び出されるコールバック関数`fulfillRandomness()`は2つの別々のトランザクションで、ユーザーコントラクトと`VRF`コントラクトがそれぞれ呼び出し元となります。後者は前者より数分遅れます（チェーンごとに遅延が異なります）。

```solidity
    /**
* VRFコントラクトのコールバック関数で、乱数が有効であることを検証した後に自動的に呼び出されます。
      * 乱数を消費するロジックはここに書きます
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
```

## `tokenId`ランダムミント`NFT`

このセクションでは、オンチェーンとオフチェーンの乱数を使用して`tokenId`ランダムミント`NFT`を作成します。`Random`コントラクトは`ERC721`と`VRFConsumerBase`コントラクトの両方を継承しています。

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "https://github.com/AmazingAng/WTF-Solidity/blob/main/34_ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Random is ERC721, VRFConsumerBase{
```

### 状態変数

- `NFT`関連
    - `totalSupply`：`NFT`の総供給量。
    - `ids`：`ミント`可能な`tokenId`を計算するために使用される配列、`pickRandomUniqueId()`関数を参照。
    - `mintCount`：`ミント`された`NFT`の数。
- `Chainlink VRF`関連
    - `keyHash`：`VRF`の一意識別子。
    - `fee`：`VRF`手数料。
    - `requestToSender`：ミントのために`VRF`を申請したユーザーアドレスを記録。

```solidity
    // NFT関連
    uint256 public totalSupply = 100; // 総供給量
    uint256[100] public ids; // ミント可能なtokenIdを計算するために使用
    uint256 public mintCount; // ミントされたトークン数
    // Chainlink VRF関連
    bytes32 internal keyHash; // Chainlink VRFのキーハッシュ
    uint256 internal fee; // Chainlink VRFの手数料
    // VRFリクエスト識別子に対応するミントアドレスを記録
    mapping(bytes32 => address) public requestToSender;
```

### コンストラクタ

継承された`VRFConsumerBase`と`ERC721`コントラクトの関連変数を初期化します。

```
/**
  * Chainlink VRFを使用するため、コンストラクタはVRFConsumerBaseを継承する必要があります
  * 異なるチェーンのパラメータは異なって記入されます
  * ネットワーク: Rinkebyテストネット
  * Chainlink VRF Coordinatorアドレス: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
  * LINKトークンアドレス: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
  * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
**/
constructor()
    VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
    )
    ERC721("WTF Random", "WTF")
{
    keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    fee = 0.1 * 10 ** 18; // 0.1 LINK（VRF使用料、Rinkebyテストネットワーク）
}
```

### その他の関数

コンストラクタ関数に加えて、コントラクトは他に5つの関数を定義しています：

- `pickRandomUniqueId()`：乱数を受け取り、ミントに使用できる`tokenId`を返します。

- `getRandomOnchain()`：オンチェーン乱数を返します（安全ではない）。

- `mintRandomOnchain()`：オンチェーン乱数を使用してNFTをミントし、`getRandomOnchain()`と`pickRandomUniqueId()`を呼び出します。

- `mintRandomVRF()`：`Chainlink VRF`から乱数をリクエストしてNFTをミントします。乱数を使用したミントのロジックはコールバック関数`fulfillRandomness()`にあり、これは`VRF`コントラクトによって呼び出されるため、NFTをミントするユーザーではないため、ここの関数は`requestToSender`状態変数を使用して`VRF`リクエスト識別子に対応するユーザーアドレスを記録する必要があります。

- `fulfillRandomness()`：`VRF`のコールバック関数で、乱数の真正性を検証した後に`VRF`コントラクトによって自動的に呼び出されます。返されたオフチェーン乱数を使用してNFTをミントします。

```solidity
    /**
     * uint256数値を入力し、ミント可能なtokenIdを返します
     * アルゴリズムプロセスは次のように理解できます：totalSupply個の空のカップ（0で初期化されたids）が一列に並んでおり、各カップの隣にボールが置かれ、[0, totalSupply - 1]で番号が付けられています。
     フィールドからボールをランダムに取る度に（ボールはカップの隣にある可能性があり、これは初期状態；カップの中にある可能性もあり、カップの隣のボールが取られたことを示し、この時はカップに最後から新しいボールを入れる）
     そして最後のボール（まだカップの中またはカップの隣にある可能性がある）を取り出されたボールのカップに入れ、totalSupply回ループします。従来のランダム配列と比較して、ids[]の初期化のgasが省略されます。
     */
    function pickRandomUniqueId(
        uint256 random
    ) private returns (uint256 tokenId) {
        // 最初に減算を計算してから++を計算し、(a++, ++a)の違いに注意
        uint256 len = totalSupply - mintCount++; // ミント数量
        require(len > 0, "mint close"); // すべてのtokenIdがミント完了
        uint256 randomIndex = random % len; // チェーン上の乱数を取得

        // 乱数を剰余してtokenIdを配列の添字として取得し、同時にlen-1として値を記録。剰余で取得した値が既に存在する場合、tokenIdは配列添字の値を取る
        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex; // tokenIdを取得
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1]; // idsリストを更新
        ids[len - 1] = 0; // 最後の要素を削除、gasを返還可能
    }

    /**
     * チェーン上疑似乱数生成
     * keccak256(abi.encodePacked() チェーン上のいくつかのグローバル変数/カスタム変数を記入
     * 返す際にuint256型に変換
     */
    function getRandomOnchain() public view returns (uint256) {
        /*
         * この場合、チェーン上のランダム性はブロックハッシュ、呼び出し元アドレス、ブロック時間にのみ依存します、
         * ランダム性を向上させたい場合、nonce等の属性を追加できますが、セキュリティ問題を根本的に解決することはできません
         */
        bytes32 randomBytes = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                block.timestamp
            )
        );
        return uint256(randomBytes);
    }

    // チェーン上の疑似乱数を使用してNFTをキャスト
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain()); // チェーン上の乱数を使用してtokenIdを生成
        _mint(msg.sender, _tokenId);
    }

    /**
     * VRFを呼び出して乱数を取得しNFTをミント
     * requestRandomness()関数を呼び出して取得し、乱数を消費するロジックはVRFコールバック関数fulfillRandomness()に書かれています
     * 呼び出し前にこのコントラクトにLINKトークンを転送してください
     */
    function mintRandomVRF() public returns (bytes32 requestId) {
        // コントラクト内のLINK残高をチェック
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        // requestRandomnessを呼び出して乱数を取得
        requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    /**
     * VRFコールバック関数、VRF Coordinatorによって呼び出される
     * 乱数を消費するロジックはこの関数に書かれています
     */
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        address sender = requestToSender[requestId]; // requestToSenderからミンターユーザーアドレスを取得
        uint256 _tokenId = pickRandomUniqueId(randomness); // VRFが返した乱数を使用してtokenIdを生成
        _mint(sender, _tokenId);
    }
```

## `remix`検証

### 1. `Rinkeby`テストネットで`Random`コントラクトをデプロイ

![コントラクトのデプロイ](./img/39-2.png)

### 2. `Chainlink`フォーセットを使用して`Rinkeby`テストネットで`LINK`と`ETH`を取得

![RinkebyテストネットでLINKとETHを取得](./img/39-3.png)

### 3. `LINK`トークンを`Random`コントラクトに転送

コントラクトがデプロイされた後、コントラクトアドレスをコピーし、通常の転送と同じように`LINK`をコントラクトアドレスに転送します。

![LINKトークンの転送](./img/39-4.png)

### 4. オンチェーン乱数を使用してNFTをミント

`remix`インターフェースで、左側のオレンジ色の関数`mintRandomOnchain`をクリック![mintOnchain](./img/39-5-1.png)し、ポップアップの`Metamask`で確認をクリックして、オンチェーン乱数を使用したミントトランザクションを開始します。

![オンチェーン乱数を使用してNFTをミント](./img/39-5.png)

### 5. `Chainlink VRF`オフチェーン乱数を使用してNFTをミント

同様に、`remix`インターフェースで左側のオレンジ色の関数`mintRandomVRF`をクリックし、ポップアップの小さな狐ウォレットで確認をクリックします。`Chainlink VRF`オフチェーン乱数を使用してNFTをミントするトランザクションが開始されました。

注意：`VRF`を使用して`NFT`をミントする際、トランザクションの開始とミントの成功は同じブロックではありません。

![VRFミントのトランザクション開始](./img/39-6.png)
![VRFミントのトランザクション成功](./img/39-7.png)

### 6. `NFT`がミントされたことを確認

上記のスクリーンショットから、この例では`tokenId=87`の`NFT`がオンチェーンでランダムにミントされ、`tokenId=77`の`NFT`が`VRF`を使用してミントされたことが分かります。

## 結論

`Solidity`で乱数を生成することは、他のプログラミング言語ほど簡単ではありません。このチュートリアルでは、オンチェーン（ハッシュ関数使用）とオフチェーン（`Chainlink`オラクル）の2つの乱数生成方法を紹介し、それらを使用してランダムに割り当てられた`tokenId`を持つ`NFT`を作成しました。両方の方法にはそれぞれ利点と欠点があります：オンチェーン乱数の使用は効率的ですが安全ではなく、オフチェーン乱数の生成はサードパーティのオラクルサービスに依存しますが、比較的安全で、それほど簡単で経済的ではありません。プロジェクトチームは具体的なビジネスニーズに応じて適切な方法を選択する必要があります。

これらの方法に加えて、他の組織もRNG（Random Number Generation）の新しい方法を試しています。例えば[randao](https://github.com/randao/randao)は、DAOパターンでオンチェーンで真のランダム性サービスを提供することを提案しています。