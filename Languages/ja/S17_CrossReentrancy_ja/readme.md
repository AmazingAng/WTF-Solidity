---
title: S17. "クロスサーバー"リエントランシー攻撃
tags:
  - solidity
  - security
  - fallback
  - modifier
  - ERC721
  - ERC777
---

# WTF Solidity 合約セキュリティ: S17. "クロスサーバー"リエントランシー攻撃

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

スマートコントラクトセキュリティの分野において、リエントランシー攻撃は常に注目される話題です。[リエントランシー攻撃](../S01_ReentrancyAttack/readme.md)のレッスンで、`0xAA`は教科書レベルの古典的なリエントランシー攻撃の考え方を生き生きと示しました。一方、本番環境では、より巧妙で複雑な実例が、新しい形で継続的に登場し、多くのプロジェクトに破壊をもたらすことに成功しています。これらの実例は、攻撃者がスマートコントラクトの脆弱性を利用して、精巧に計画された攻撃を組み合わせる方法を示しています。このレッスンでは、本番環境で実際に発生した「クロスサーバー」属性を持つリエントランシー攻撃事例を紹介します。いわゆる「クロスサーバー」は、この種の攻撃対象の生き生きとした概括で、共通の手段が1つの関数から始まるが、攻撃対象は他の関数/コントラクト/プロジェクトなどであることです。このレッスンでは、その操作を簡素化・抽出し、攻撃者の考え方、利用される脆弱性、対応する防御措置を探討します。これらの実例を理解することで、リエントランシー攻撃の本質をより良く理解し、安全なスマートコントラクトを書くスキルと意識を向上させることができます。

注：以下に示すコード例はすべて簡素化された`pseudo-code`で、主に攻撃の考え方を説明することを目的としています。内容は多くの`Web3 Security Researchers`が共有した監査事例から来ており、彼らの貢献に感謝します！


## 1. 関数間リエントランシー攻撃

*「あの年、私はリエントランシーロックを付けていて、敵が何者か知らなかった。あの日まで、あの男が天から降りてきて、それでも私の銀子を巻き上げていった...」-- ロック婆婆*

以下のコード例をご覧ください：
```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VulnerableBank {
  mapping(address => uint256) public balances;

  uint256 private _status; // リエントランシーロック

  // リエントランシーロック
  modifier nonReentrant() {
      // nonReentrantの最初の呼び出し時、_statusは0になります
       require(_status == 0, "ReentrancyGuard: reentrant call");
      // この後のnonReentrantへの呼び出しはすべて失敗します
      _status = 1;
      _;
      // 呼び出し終了時、_statusを0に復元
      _status = 0;
  }

  function deposit() external payable {
    require(msg.value > 0, "Deposit amount must ba greater than 0");
    balances[msg.sender] += msg.value;
  }

  function withdraw(uint256 _amount) external nonReentrant {
    uint256 balance = balances[msg.sender];
    require(balance >= _amount, "Insufficient balance");

    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Withdraw failed");

    balances[msg.sender] = balance - _amount;
  }

  function transfer(address _to, uint256 _amount) external {
    uint256 balance = balances[msg.sender];
    require(balance >= _amount, "Insufficient balance");

    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
  }
}
```

上記の`VulnerableBank`コントラクトでは、`ETH`転送のステップは`withdraw`関数内にのみ存在し、この関数はすでにリエントランシーロック`nonReentrant`を使用していることがわかります。では、このコントラクトに対してリエントランシー攻撃を行う他の方法はあるでしょうか？

以下の攻撃者コントラクトの例をご覧ください：

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../IVault.sol";

contract Attack2Contract {
    address victim;
    address owner;

    constructor(address _victim, address _owner) {
        victim = _victim;
        owner = _owner;
    }

    function deposit() external payable {
        IVault(victim).deposit{value: msg.value}("");
    }

    function withdraw() external {
        Ivault(victim).withdraw();
    }

    receive() external payable {
        uint256 balance = Ivault(victim).balances[address(this)];
        Ivault(victim).transfer(owner, balance);
    }
}
```

上記のように、攻撃者はもはや`withdraw`関数にリエントラントするのではなく、ロックのない`transfer`関数にリエントラントします。`VulnerableBank`コントラクトの設計者の固有の思考では、`transfer`関数は`balances mapping`を変更するだけで`ETH`転送のステップがないため、リエントランシー攻撃の対象ではないはずなので、ロックを付けていませんでした。しかし攻撃者は`withdraw`を使って最初に`ETH`を転送し、転送完了時に`balances`がすぐに更新されず、ランダムに`transfer`関数を呼び出して、もはや存在しない残高を別のアドレス`owner`に成功転送しました。このアドレスは完全に攻撃者のサブアカウントである可能性があります。`transfer`関数は`ETH`を転送しないため、実行権を継続して譲渡することはなく、このリエントランシーは追加で1回攻撃しただけで終了します。結果として、攻撃者はこの部分のお金を「無から有に」生み出し、「二重支払い」の効果を実現しました。

ここで問題になります：

*改良して、コントラクト内の資産移動に関わるすべての関数にリエントランシーロックを付けたら、安全になるでしょうか？？？*

以下の上級事例をご覧ください...


## 2. コントラクト間リエントランシー攻撃

私たちの第二の被害者は、複数コントラクト組み合わせシステムで、分散型コントラクト取引プラットフォームです。問題が発生した重要な部分のみを見ると、2つのコントラクトに関連しています。第一のコントラクトは`TwoStepSwapManager`で、これはユーザー向けのコントラクトで、ユーザーが直接発起できるswap取引を提出する関数と、同様にユーザーが発起できる、実行待ちだが未実行のswap取引をキャンセルする関数を含みます。第二のコントラクトは`TwoStepSwapExecutor`で、これは管理役割のみが発起できる取引で、待機中のswap取引を実行するために使用されます。これら2つのコントラクトの*一部*の例コードは以下の通りです：

```
// Contracts to create and manage swap "requests"

contract TwoStepSwapManager {
    struct Swap {
        address user;
        uint256 amount;
        address[] swapPath;
        bool unwrapnativeToken;
    }

    uint256 swapNonce;
    mapping(uint256 => Swap) pendingSwaps;

    uint256 private _status; // リエントランシーロック

    // リエントランシーロック
    modifier nonReentrant() {
      // nonReentrantの最初の呼び出し時、_statusは0になります
        require(_status == 0, "ReentrancyGuard: reentrant call");
      // この後のnonReentrantへの呼び出しはすべて失敗します
        _status = 1;
        _;
      // 呼び出し終了時、_statusを0に復元
        _status = 0;
     }

    function createSwap(uint256 _amount, address[] _swapPath, bool _unwrapnativeToken) external nonReentrant {
        IERC20(swapPath[0]).safeTransferFrom(msg.sender, _amount);
        pendingSwaps[++swapNounce] = Swap({
            user: msg.sender,
            amount: _amount,
            swapPath: _swapPath,
            unwrapNativeToken: _unwrapNativeToken
        });
    }

    function cancelSwap(uint256 _id) external nonReentrant {
        Swap memory swap = pendingSwaps[_id];
        require(swap.user == msg.sender);
        delete pendingSwaps[_id];

        IERC20(swapPath[0]).safeTransfer(swap.user, swap.amount);
    }
}
```

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Contract to exeute swaps

contract TwoStepSwapExecutor {


    /*
        Logic to set prices etc...
    */


    uint256 private _status; // リエントランシーロック

    // リエントランシーロック
    modifier nonReentrant() {
      // nonReentrantの最初の呼び出し時、_statusは0になります
        require(_status == 0, "ReentrancyGuard: reentrant call");
      // この後のnonReentrantへの呼び出しはすべて失敗します
        _status = 1;
        _;
      // 呼び出し終了時、_statusを0に復元
        _status = 0;
    }

    function executeSwap(uint256 _id) external onlySwapExecutor nonReentrant {
        Swap memory swap = ISwapManager(swapManager).pendingSwaps(_id);

        // If a swapPath ends in WETH and unwrapNativeToken == true, send ether to the user
        ISwapManager(swapManager).swap(swap.user, swap.amount, swap.swapPath, swap.unwrapNativeToken);

        ISwapManager(swapManager).delete(pendingSwaps[_id]);
    }
}
```

上記2つのコントラクトの例コードから、すべての関連関数がリエントランシーロックを使用していることがわかります。しかし、あの男はまだロック婆婆にリエントランシー魔法を成功させ、再再再び本来彼のものではないお金を巻き上げました。今回、彼はどのようにしたのでしょうか？

俗に言う「灯台下暗し」、答えは最も表面上にあり、かえって見落とされやすいのです --- これは2つのコントラクトだからです...ロックの状態は相互に通じていません！管理者が`executeSwap`を呼び出して攻撃者が提出したswapを実行すると、このコントラクトのリエントランシーロックが有効になり`1`になります。中間の`swap()`ステップを実行する時、`ETH`転送が発起され、実行権が攻撃者の悪意のあるコントラクトの`fallback`関数に渡され、そこで`TwoStepSwapManager`コントラクトの`cancelSwap`関数の呼び出しが設定されます。この時、このコントラクトのリエントランシーロックはまだ`0`なので、`cancelSwap`が実行を開始し、このコントラクトのリエントランシーロックが有効になり`1`になりますが、すでに手遅れです...攻撃者は`executeSwap`が送信したswapされた`ETH`を受け取ると同時に、`cancelSwap`が返金した最初に送出したswap用の元本トークンも受け取りました。彼は再び「無から有に」しました！


### グローバルリエントランシーロック

このようなコントラクト間リエントランシー攻撃を防ぐため、ここでリエントランシーロックのアップグレード版 -- グローバルリエントランシーロックを皆さんにお贈りします。今後の複数コントラクトシステムの構築に適しています。以下の簡易コード思路をご覧ください：

```
pragma solidity ^0.8.0;

import "../data/Keys.sol";
import "../data/DataStore.sol";

abstract contract GlobalReentrancyGuard{
    uint256 private constant NOT_ENTERED = 0;
    uint256 private constant ENTERED = 1;

    DataStore public immutable dataStore;

    constructor(DataStore _datastore) {
        dataStore = _dataStore;
    }

    modifier globalNonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        uint256 status = dataStore.getUint(Keys.REENTRANCY_GUARD_STATUS);

        require(status == NOT_ENTERED, "ReentrancyGuard: reentrant call");

        dataStore.setUint(Keys.REENTRANCY_GUARD_STATUS, ENTERED);
    }

    function _nonReentrantAfter() private {
        dataStore.setUint(Keys.REENTRANCY_GUARD_STATUS, NOT_ENTERED);
    }
}
```

このグローバルリエントランシーロックの核心を一言で概括すると、リエントランシー状態を保存する独立したコントラクトを確立し、あなたのシステム内のすべてのコントラクトの関連関数が実行される時、すべて同じ場所に来て現在のリエントランシー状態を確認するようにすることで、あなたのすべてのコントラクトがリエントランシー保護されるということです。

美しく見えますが、まだ終わりではありません...攻撃者にはグローバルリエントランシーロックでも防げない新しい手法があります。続きをご覧ください:...


## 3. プロジェクト間リエントランシー攻撃

ますます大きくなってきました...いわゆるプロジェクト間のリエントランシー攻撃の核心は、上記2例と実際かなり似ています。本質は、あるプロジェクトコントラクトのある状態変数がまだ更新されていない時に、受け取った実行権を利用して外部関数呼び出しを発起することです。第三者協力プロジェクトのコントラクトが、前述したプロジェクトコントラクト内のこの状態変数の値に依存して何らかの決定を行う場合、攻撃者はこの協力プロジェクトのコントラクトを攻撃できます。この時点で読み取るのは期限切れの状態値で、間違った行為を実行させて攻撃者が利益を得ることになります。通常、協力プロジェクトのコントラクトは一部の`getter`関数やその他の公開読み取り専用関数の呼び出しを通じて情報を伝達するため、この種の攻撃は通常`読み取り専用リエントランシー攻撃 Read-Only Reentrancy`として現れます。

以下の例コードをご覧ください：

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VulnerableBank {
  mapping(address => uint256) public balances;

  uint256 private _status; // リエントランシーロック

  // リエントランシーロック
  modifier nonReentrant() {
      // nonReentrantの最初の呼び出し時、_statusは0になります
       require(_status == 0, "ReentrancyGuard: reentrant call");
      // この後のnonReentrantへの呼び出しはすべて失敗します
      _status = 1;
      _;
      // 呼び出し終了時、_statusを0に復元
      _status = 0;
  }

  function deposit() external payable {
    require(msg.value > 0, "Deposit amount must ba greater than 0");
    balances[msg.sender] += msg.value;
  }

  function withdraw(uint256 _amount) external nonReentrant {
    require(_amount > 0, "Withdrawal amount must be greater than 0");
    require(isAllowedToWithdraw(msg.sender, _amount), "Insufficient balance");

    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Withdraw failed");

    balances[msg.sender] -= _amount;
  }

  function isAllowedToWithdraw(address _user, uint256 _amount) public view returns(bool) {
    return balances[_user] >= _amount;
  }
}
```

コードに示すように、このコントラクトでは、攻撃者がリエントランシーを発揮する余地がもうありません。しかし、ここにはなくても、他の場所にはないということではありません...コントラクト内に公開の読み取り専用関数`isAllowedToWithdraw`があることがわかります。この種の関数は情報提供を目的としています。多くのプロジェクトのコントラクトには多かれ少なかれこの種の関数があり、この種の関数は他のプロジェクトのコントラクトによって呼び出されて情報を取得し、最終的にDefi世界のレゴブロックを完成させます。この重要な`withdraw`関数はすでにロックされており、リエントランシー攻撃はできませんが、その実行過程の`ETH`転送ステップで、`ETH`がちょうど転送され、攻撃者がこの時点で`isAllowedToWithdraw`関数を呼び出そうとした場合、`_amount`値が大きくても、攻撃者の預金が実際には空になっているにもかかわらず、この時点では帳簿がまだ更新されていないため、返り値は依然として`true`になることが予見できます。そうすると、攻撃者は悪意のあるコントラクトの`fallback`関数に外部関数呼び出しを設定し、`isAllowedToWithdraw`関数の返り結果に基づいて操作を決定する他のプロジェクトのコントラクトを攻撃することができます。

上記のコントラクト自体は攻撃されず、協力パートナーのコントラクトが攻撃されます...典型的な：

*「私は伯仁を殺していないが、伯仁は私のために死んだ...」-- ロック婆婆*

`Read-Only Reentrancy`に対して、[Euler Finance](https://github.com/euler-xyz/euler-contracts/commit/91adeee39daf8ece00584b6f7ec3e60a1d226bc9#diff-05f47d885ccf959493d5c53203672966544d73232f5410184d5484a7aedf0c5eR260)は`read-only reentrancy guard`を採用し、ロックされていない時のみ読み取りを許可します。同時に、ロックの可視性を`public`に設定して他のプロジェクトが使用できるようにします。

## 4. ERC721 & ERC777 Reentrancy

これら2つのトークン標準はそれぞれコールバック関数を規定しています：

ERC721: `function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4);`

ERC777: `function tokensReceived(address _operator, address _from, address _to, uint256 _amount, bytes calldata _userData, bytes calldata _operatorData) external;`

コールバック関数の存在はコード実行権を受け取る機会があることを意味し、同時にリエントランシー攻撃の可能性も生み出します。この状況についてはコード例を示しませんが、上記のいくつかの事例と組み合わせると、今では理解しやすくなったはずです。そして、実際に無限の花様を演出できます。


## まとめ

以上で、実際に発生したさまざまな花様のリエントランシー攻撃のロジック本体とその簡易コードを確認しました。皆さんは、これらのコントラクトが攻撃されたのは、すべて共通の欠陥があるためであることが容易にわかるでしょう。それは、これらのコントラクトの設計がリエントランシー攻撃の防止において、直接的なツール（リエントランシーロック）の保護に過度に依存し、もう一つの良い設計習慣である*チェック-エフェクト-インタラクションパターン*を貫徹していないことです。シンプルなツールは決して完璧な防御にはなりません。貫徹した方法論こそがあなたの永遠の後ろ盾です*（報告、このセクションのコード授業の思政任務は伝達済み、検収をお願いします）*

したがって、小さなツールを使うか、方法論を使うかの選択について、私たちsolidity devsとしての答えは：両方...そして...であるべきだと思います！関数間の攻撃から、コントラクト間、プロジェクト間の攻撃まで、devsとauditorsにこの巨大になるレゴ間の千糸万縷の関係を覚えることを要求するのは、いささか無理があります。そこで、構築過程の各ステップで、標準的に複数の異なる防御メカニズムを配置することで、安心してより良い結果を得ることができます。

![](./img/S17-1.png)