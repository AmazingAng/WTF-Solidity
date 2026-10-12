---
title: 51. ERC4626 トークン化金庫標準
tags:
  - solidity
  - erc20
  - erc4626
  - defi
  - vault
  - openzepplin

---

# WTF Solidity 超シンプル入門: 51. ERC4626 トークン化金庫標準

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

DeFiはよく「マネーレゴ」と呼ばれ、複数のプロトコルを組み合わせて新しいプロトコルを作成できます。しかし、DeFiは標準が不足しているため、その組み合わせ可能性が深刻に影響を受けています。ERC4626は、ERC20トークン標準を拡張し、収益金庫の標準化を推進することを目的としています。今回は、DeFiの新世代標準ERC4626について紹介し、シンプルな金庫コントラクトを作成します。教学コードはopenzeppelinとsolmateのERC4626コントラクトを参考にしており、教学目的でのみ使用します。

## 金庫

金庫コントラクトはDeFiレゴの基盤であり、基礎資産（トークン）をコントラクトに質入れして一定の収益を得ることができます。以下の応用シナリオがあります：

- 収益農場：Yearn Financeでは、`USDT`を質入れして利息を得ることができます。
- 貸借：AAVEでは、`ETH`を貸し出して預金利息と貸出を得ることができます。
- 質入れ：Lidoでは、`ETH`を質入れしてETH 2.0質入れに参加し、利息が付く`stETH`を得ることができます。

## ERC4626

![](./img/51-1.png)

金庫コントラクトは標準が不足しているため、書き方が多様で、一つの収益アグリゲーターが異なるDeFiプロジェクトに対接するために多くのインターフェースを書く必要があります。ERC4626トークン化金庫標準（Tokenized Vault Standard）が登場し、DeFiが簡単に拡張できるようになりました。以下の利点があります：

1. トークン化：ERC4626はERC20を継承し、金庫に預金する際、同様にERC20標準に適合する金庫持分を得ます（例：ETHを質入れすると自動的にstETHを取得）。

2. より良い流動性：トークン化により、基礎資産を取り戻すことなく、金庫持分を使って他のことができます。LidoのstETHを例にすると、UniswapでETHを取り出すことなく流動性を提供したり取引したりできます。

3. より良い組み合わせ可能性：標準ができた後、一つのインターフェースですべてのERC4626金庫とやり取りでき、金庫ベースのアプリケーション、プラグイン、ツールの開発が簡単になります。

総じて、ERC4626のDeFiに対する重要性は、ERC721のNFTに対する重要性に劣りません。

### ERC4626 要点

ERC4626標準は主に以下のロジックを実装します：

1. ERC20：ERC4626はERC20を継承し、金庫持分はERC20トークンで表されます。ユーザーが特定のERC20基礎資産（例：WETH）を金庫に預けると、コントラクトは特定数量の金庫持分トークンを鋳造します。ユーザーが金庫から基礎資産を引き出すと、対応する数量の金庫持分トークンが破棄されます。`asset()`関数は金庫の基礎資産のトークンアドレスを返します。
2. 預金ロジック：ユーザーが基礎資産を預け、対応する数量の金庫持分を鋳造できるようにします。関連関数は`deposit()`と`mint()`です。`deposit(uint assets, address receiver)`関数はユーザーが`assets`単位の資産を預け、対応する数量の金庫持分を`receiver`アドレスに鋳造します。`mint(uint shares, address receiver)`はそれと似ていますが、鋳造される金庫持分をパラメータとして使用します。
3. 引き出しロジック：ユーザーが金庫持分を破棄し、金庫から対応する数量の基礎資産を引き出せるようにします。関連関数は`withdraw()`と`redeem()`で、前者は引き出す基礎資産数量をパラメータとし、後者は破棄する金庫持分をパラメータとします。
4. 会計と限度ロジック：ERC4626標準の他の関数は、金庫内の資産統計、預金/引き出し限度、預金/引き出しの基礎資産と金庫持分数量を統計するためのものです。

### IERC4626 インターフェースコントラクト

IERC4626インターフェースコントラクトには合計`2`つのイベントが含まれます：
- `Deposit`イベント：預金時にトリガー。
- `Withdraw`イベント：引き出し時にトリガー。

IERC4626インターフェースコントラクトには`16`の関数が含まれ、機能により`4`つの大カテゴリに分けられます：メタデータ、預金/引き出しロジック、会計ロジック、預金/引き出し限度ロジック。

- メタデータ

    - `asset()`：金庫の基礎資産トークンアドレスを返し、預金、引き出しに使用。
- 預金/引き出しロジック
    - `deposit()`：預金関数、ユーザーが金庫に`assets`単位の基礎資産を預け、その後コントラクトが`shares`単位の金庫持分を`receiver`アドレスに鋳造。`Deposit`イベントを発行。
    - `mint()`：鋳造関数（預金関数でもある）、ユーザーが希望する`shares`単位の金庫持分を指定し、関数が計算後に必要な`assets`単位の基礎資産数量を得て、その後コントラクトがユーザーアカウントから`assets`単位の基礎資産を転送し、`receiver`アドレスに指定数量の金庫持分を鋳造。`Deposit`イベントを発行。
    - `withdraw()`：引き出し関数、`owner`アドレスが`share`単位の金庫持分を破棄し、その後コントラクトが対応する数量の基礎資産を`receiver`アドレスに送信。
    - `redeem()`：償還関数（引き出し関数でもある）、`owner`アドレスが`shares`数量の金庫持分を破棄し、その後コントラクトが対応する単位の基礎資産を`receiver`アドレスに送信。
- 会計ロジック
    - `totalAssets()`：金庫で管理されている基礎資産トークンの総額を返す。
    - `convertToShares()`：一定数額の基礎資産で交換できる金庫持分を返す。
    - `convertToAssets()`：一定数額の金庫持分で交換できる基礎資産を返す。
    - `previewDeposit()`：現在のオンチェーン環境で一定数額の基礎資産を預金して得られる金庫持分をユーザーがシミュレートするため。
    - `previewMint()`：現在のオンチェーン環境で一定数額の金庫持分を鋳造するのに必要な基礎資産数量をユーザーがシミュレートするため。
    - `previewWithdraw()`：現在のオンチェーン環境で一定数額の基礎資産を引き出すのに必要な金庫持分をユーザーがシミュレートするため。
    - `previewRedeem()`：現在のオンチェーン環境で一定数額の金庫持分を破棄して償還できる基礎資産数量をオンチェーンとオフチェーンユーザーがシミュレートするため。
- 預金/引き出し限度ロジック
    - `maxDeposit()`：あるユーザーアドレスの一回の預金で預けられる最大基礎資産数額を返す。
    - `maxMint()`：あるユーザーアドレスの一回の鋳造で鋳造できる最大金庫持分を返す。
    - `maxWithdraw()`：あるユーザーアドレスの一回の引き出しで引き出せる最大基礎資産持分を返す。
    - `maxRedeem()`：あるユーザーアドレスの一回の償還で破棄できる最大金庫持分を返す。

```solidity
// SPDX-License-Identifier: MIT
// Author: 0xAA from WTF Academy

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev ERC4626 "トークン化金庫標準"のインターフェースコントラクト
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    /*//////////////////////////////////////////////////////////////
                                 イベント
    //////////////////////////////////////////////////////////////*/
    // 預金時にトリガー
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    // 引き出し時にトリガー
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                            メタデータ
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 金庫の基礎資産トークンアドレスを返す（預金、引き出しに使用）
     * - ERC20トークンコントラクトアドレスである必要があります
     * - revertしてはいけません
     */
    function asset() external view returns (address assetTokenAddress);

    /*//////////////////////////////////////////////////////////////
                        預金/引き出しロジック
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 預金関数：ユーザーが金庫にassets単位の基礎資産を預け、その後コントラクトがshares単位の金庫持分をreceiverアドレスに鋳造
     *
     * - Depositイベントを発行する必要があります
     * - 資産が預けられない場合、revertする必要があります（預金数額が上限を大幅に上回る場合など）
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev 鋳造関数：ユーザーがassets単位の基礎資産を預ける必要があり、その後コントラクトがreceiverアドレスにshare数量の金庫持分を鋳造
     * - Depositイベントを発行する必要があります
     * - すべての金庫持分が鋳造できない場合、revertする必要があります（鋳造数額が上限を大幅に上回る場合など）
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev 引き出し関数：ownerアドレスがshare単位の金庫持分を破棄し、その後コントラクトがassets単位の基礎資産をreceiverアドレスに送信
     * - Withdrawイベントを発行
     * - すべての基礎資産が引き出せない場合、revert
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev 償還関数：ownerアドレスがshares数量の金庫持分を破棄し、その後コントラクトがassets単位の基礎資産をreceiverアドレスに送信
     * - Withdrawイベントを発行
     * - 金庫持分がすべて破棄できない場合、revert
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                            会計ロジック
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev 金庫で管理されている基礎資産トークンの総額を返す
     * - 利息を含める必要があります
     * - 手数料を含める必要があります
     * - revertしてはいけません
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev 一定数額の基礎資産で交換できる金庫持分を返す
     * - 手数料を含めないでください
     * - スリッページを含めません
     * - revertしてはいけません
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev 一定数額の金庫持分で交換できる基礎資産を返す
     * - 手数料を含めないでください
     * - スリッページを含めません
     * - revertしてはいけません
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev 現在のオンチェーン環境で一定数額の基礎資産を預金して得られる金庫持分をオンチェーンとオフチェーンユーザーがシミュレートするため
     * - 戻り値は同じトランザクションで預金して得られる金庫持分に近く、それを超えてはいけません
     * - maxDepositなどの制限を考慮せず、ユーザーの預金トランザクションが成功すると仮定
     * - 手数料を考慮してください
     * - revertしてはいけません
     * NOTE: convertToAssetsとpreviewDeposit戻り値の差でスリッページを計算できます
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev 現在のオンチェーン環境でshares数額の金庫持分を鋳造するのに必要な基礎資産数量をオンチェーンとオフチェーンユーザーがシミュレートするため
     * - 戻り値は同じトランザクションで一定数額の金庫持分を鋳造するのに必要な預金数量に近く、それを下回ってはいけません
     * - maxMintなどの制限を考慮せず、ユーザーの預金トランザクションが成功すると仮定
     * - 手数料を考慮してください
     * - revertしてはいけません
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev 現在のオンチェーン環境でassets数額の基礎資産を引き出すのに必要な金庫持分をオンチェーンとオフチェーンユーザーがシミュレートするため
     * - 戻り値は同じトランザクションで一定数額の基礎資産を引き出すのに必要な償還金庫持分に近く、それを超えてはいけません
     * - maxWithdrawなどの制限を考慮せず、ユーザーの引き出しトランザクションが成功すると仮定
     * - 手数料を考慮してください
     * - revertしてはいけません
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev 現在のオンチェーン環境でshares数額の金庫持分を破棄して償還できる基礎資産数量をオンチェーンとオフチェーンユーザーがシミュレートするため
     * - 戻り値は同じトランザクションで一定数額の金庫持分を破棄して償還できる基礎資産数量に近く、それを下回ってはいけません
     * - maxRedeemなどの制限を考慮せず、ユーザーの償還トランザクションが成功すると仮定
     * - 手数料を考慮してください
     * - revertしてはいけません
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                     預金/引き出し限度ロジック
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev あるユーザーアドレスの一回の預金で預けられる最大基礎資産数額を返す
     * - 預金上限がある場合、戻り値は有限値であるべきです
     * - 戻り値は2 ** 256 - 1を超えてはいけません
     * - revertしてはいけません
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev あるユーザーアドレスの一回の鋳造で鋳造できる最大金庫持分を返す
     * - 鋳造上限がある場合、戻り値は有限値であるべきです
     * - 戻り値は2 ** 256 - 1を超えてはいけません
     * - revertしてはいけません
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev あるユーザーアドレスの一回の引き出しで引き出せる最大基礎資産持分を返す
     * - 戻り値は有限値であるべきです
     * - revertしてはいけません
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev あるユーザーアドレスの一回の償還で破棄できる最大金庫持分を返す
     * - 戻り値は有限値であるべきです
     * - 他の制限がない場合、戻り値はbalanceOf(owner)であるべきです
     * - revertしてはいけません
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);
}
```

### ERC4626 コントラクト

以下では、極簡版のトークン化金庫コントラクトを実装します：
- コンストラクタは基礎資産のコントラクトアドレス、金庫持分のトークン名とシンボルを初期化します。注意：金庫持分のトークン名とシンボルは基礎資産と関連付ける必要があります（例：基礎資産が`WTF`の場合、金庫持分は`vWTF`が良い）。
- 預金時、ユーザーが金庫に`x`単位の基礎資産を預けると、`x`単位（等量）の金庫持分が鋳造されます。
- 引き出し時、ユーザーが`x`単位の金庫持分を破棄すると、`x`単位（等量）の基礎資産が引き出されます。

**注意**：実際の使用時には、会計ロジック関連関数の計算が切り上げか切り下げか特に注意する必要があります。[openzeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)と[solmate](https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)の実装を参考にできます。本節の教学例では考慮しません。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC4626} from "./IERC4626.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev ERC4626 "トークン化金庫標準"コントラクト、教学用のみ、本番使用不可
 */
contract ERC4626 is ERC20, IERC4626 {
    /*//////////////////////////////////////////////////////////////
                    状態変数
    //////////////////////////////////////////////////////////////*/
    ERC20 private immutable _asset;
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();

    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /**
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                        預金/引き出しロジック
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // previewDeposit()を利用して得られる金庫持分を計算
        shares = previewDeposit(assets);

        // 先transfer後mint、再入攻撃を防ぐ
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // Depositイベントを発行
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        // previewMint()を利用して預金が必要な基礎資産数額を計算
        assets = previewMint(shares);

        // 先transfer後mint、再入攻撃を防ぐ
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // Depositイベントを発行
        emit Deposit(msg.sender, receiver, assets, shares);

    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        // previewWithdraw()を利用して破棄される金庫持分を計算
        shares = previewWithdraw(assets);

        // 呼び出し者がownerでない場合、承認をチェックして更新
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // 先破棄後transfer、再入攻撃を防ぐ
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // Withdrawイベントを発行
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // previewRedeem()を利用して償還できる基礎資産数額を計算
        assets = previewRedeem(shares);

        // 呼び出し者がownerでない場合、承認をチェックして更新
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // 先破棄後transfer、再入攻撃を防ぐ
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // Withdrawイベントを発行
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            会計ロジック
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256){
        // コントラクト内の基礎資産持有量を返す
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // supplyが0の場合、1:1で金庫持分を鋳造
        // supplyが0でない場合、比例して鋳造
        return supply == 0 ? assets : assets * supply / totalAssets();
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // supplyが0の場合、1:1で基礎資産を償還
        // supplyが0でない場合、比例して償還
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     預金/引き出し限度ロジック
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}
```

もちろん、本文の`ERC4626`コントラクトは教学デモンストレーション用のみで、実際の使用時には`Inflation Attack`、`Rounding Direction`などの問題も考慮する必要があります。本番では、`openzeppelin`の具体的な実装を使用することをお勧めします。

## `Remix`デモ

**注意：** 以下の実行例ではremixの第二アカウント、つまり`0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`を使用してコントラクトをデプロイし、コントラクトメソッドを呼び出します。

1. `ERC20`トークンコントラクトをデプロイし、トークン名とシンボルを共に`WTF`に設定し、自分に`10000`トークンを鋳造。
![](./img/51-2-1.png)
![](./img/51-2-2.png)

2. `ERC4626`トークンコントラクトをデプロイし、基礎資産のコントラクトアドレスを`WTF`のアドレスに設定し、名前とシンボルを共に`vWTF`に設定。
![](./img/51-3.png)

3. `ERC20`コントラクトの`approve()`関数を呼び出し、トークンを`ERC4626`コントラクトに承認。
![](./img/51-4.png)

4. `ERC4626`コントラクトの`deposit()`関数を呼び出し、`1000`枚のトークンを預金。その後`balanceOf()`関数を呼び出し、自分の金庫持分が`1000`になったことを確認。
![](./img/51-5.png)

5. `ERC4626`コントラクトの`mint()`関数を呼び出し、`1000`枚のトークンを預金。その後`balanceOf()`関数を呼び出し、自分の金庫持分が`2000`になったことを確認。
![](./img/51-6.png)

6. `ERC4626`コントラクトの`withdraw()`関数を呼び出し、`1000`枚のトークンを引き出し。その後`balanceOf()`関数を呼び出し、自分の金庫持分が`1000`になったことを確認。
![](./img/51-7.png)

7. `ERC4626`コントラクトの`redeem()`関数を呼び出し、`1000`枚のトークンを引き出し。その後`balanceOf()`関数を呼び出し、自分の金庫持分が`0`になったことを確認。
![](./img/51-8.png)

## まとめ

今回は、トークン化金庫標準ERC4626について紹介し、基礎資産を1:1で金庫持分トークンに変換できるシンプルな金庫コントラクトを作成しました。ERC4626はDeFiの流動性と組み合わせ可能性を向上させ、今後徐々に普及していくでしょう。あなたはERC4626でどのようなアプリケーションを作りますか？