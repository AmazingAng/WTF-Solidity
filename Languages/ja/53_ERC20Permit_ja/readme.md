---
title: 53. ERC-2612 ERC20Permit
tags:
  - solidity
  - erc20
  - eip712
  - openzepplin
---

# WTF Solidity 超シンプル入門: 53. ERC-2612 ERC20Permit

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、ERC20 トークンの拡張である ERC20Permit について紹介します。これは署名を使用した承認をサポートし、ユーザーエクスペリエンスを改善します。EIP-2612 で提案され、イーサリアム標準に組み込まれ、`USDC`、`ARB` などのトークンで使用されています。

## ERC20

[31講](https://github.com/AmazingAng/WTF-Solidity/blob/main/31_ERC20/readme.md)でERC20について紹介しました。これはイーサリアムで最も人気のあるトークン標準です。人気の主な理由の一つは、`approve` と `transferFrom` の2つの関数を組み合わせて使用することで、トークンが外部所有アカウント（EOA）間での転送だけでなく、他のコントラクトでも使用できることです。

しかし、ERC20の `approve` 関数はトークン所有者のみが呼び出すことができるという制限があります。これは、すべての `ERC20` トークンの初期操作が `EOA` によって実行される必要があることを意味します。例えば、ユーザーAが分散型取引所で `USDT` を `ETH` と交換する場合、2つのトランザクションを完了する必要があります：最初にユーザーAが `approve` を呼び出して `USDT` をコントラクトに承認し、次にユーザーAがコントラクトを呼び出して交換を行います。非常に面倒で、ユーザーはトランザクションのガス代を支払うために `ETH` を持っている必要があります。

## ERC20Permit

EIP-2612は ERC20Permit を提案し、ERC20標準を拡張して `permit` 関数を追加しました。これにより、ユーザーは `msg.sender` ではなく EIP-712 署名を通じて承認を修正できます。これには2つの利点があります：

1. 承認のステップはユーザーのオフチェーン署名のみが必要で、1つのトランザクションを削減できます。
2. 署名後、ユーザーは第三者に後続のトランザクションを委託でき、ETHを持つ必要がありません：ユーザーAは署名をガスを持つ第三者Bに送信し、Bに後続のトランザクションの実行を委託できます。

![](./img/53-1.png)

## コントラクト

### IERC20Permit インターフェースコントラクト

まず、ERC20Permit のインターフェースコントラクトについて学びましょう。これは3つの関数を定義しています：

- `permit()`: `owner` の署名に基づいて、`owner` のERC20トークン残高を `spender` に承認し、数量は `value` です。要件：

    - `spender` はゼロアドレスであってはいけません。
    - `deadline` は将来のタイムスタンプである必要があります。
    - `v`、`r`、`s` は `owner` による関数パラメータのEIP712形式の有効な `keccak256` 署名である必要があります。
    - 署名は `owner` の現在のnonceを使用する必要があります。

- `nonces()`: `owner` の現在のnonceを返します。`permit()` 関数の署名を生成するたびに、この値を含める必要があります。`permit()` 関数の呼び出しが成功するたびに、`owner` のnonceが1増加し、同じ署名の再利用を防ぎます。

- `DOMAIN_SEPARATOR()`: [EIP712](https://github.com/AmazingAng/WTF-Solidity/blob/main/52_EIP712/readme.md) で定義された通り、`permit()` 関数の署名をエンコードするために使用されるドメインセパレータを返します。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC20 Permit拡張のインターフェース、https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]で定義された署名による承認を許可
 */
interface IERC20Permit {
    /**
     * @dev ownerの署名に基づいて、`owner`のERC20残高を`spender`に承認、数量は`value`
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev `owner`の現在のnonceを返す。{permit}の署名を生成する際に、この値を含める必要がある。
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev {permit}の署名をエンコードするために使用されるドメインセパレータを返す
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
```

### ERC20Permit コントラクト

次に、シンプルなERC20Permitコントラクトを書きます。これはIERC20Permitで定義されたすべてのインターフェースを実装します。コントラクトには2つの状態変数が含まれています：

- `_nonces`: `address -> uint` のマッピング、すべてのユーザーの現在のnonce値を記録します。
- `_PERMIT_TYPEHASH`: 定数、`permit()` 関数の型ハッシュを記録します。

コントラクトには5つの関数が含まれています：

- コンストラクタ: トークンの `name` と `symbol` を初期化します。
- **`permit()`**: ERC20Permitの最も核心的な関数で、IERC20Permitの `permit()` を実装します。まず署名が期限切れかどうかをチェックし、次に `_PERMIT_TYPEHASH`、`owner`、`spender`、`value`、`nonce`、`deadline` を使って署名メッセージを復元し、署名が有効かどうかを検証します。署名が有効であれば、ERC20の `_approve()` 関数を呼び出して承認操作を行います。
- `nonces()`: IERC20Permitの `nonces()` 関数を実装します。
- `DOMAIN_SEPARATOR()`: IERC20Permitの `DOMAIN_SEPARATOR()` 関数を実装します。
- `_useNonce()`: `nonce` を消費する関数で、ユーザーの現在の `nonce` を返し、1増加させます。

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @dev ERC20 Permit拡張のインターフェース、https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]で定義された署名による承認を許可。
 *
 * {permit}メソッドを追加し、アカウント署名されたメッセージによってアカウントのERC20残高（{IERC20-allowance}を参照）を変更可能。{IERC20-approve}に依存しないため、トークンホルダーのアカウントはトランザクションを送信する必要がなく、Etherを全く持つ必要がない。
 */
contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev EIP712のnameおよびERC20のnameとsymbolを初期化
     */
    constructor(string memory name, string memory symbol) EIP712(name, "1") ERC20(name, symbol){}

    /**
     * @dev {IERC20Permit-permit}を参照。
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // deadlineをチェック
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        // ハッシュを構築
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);

        // 署名とメッセージからsignerを計算し、署名を検証
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        // 承認
        _approve(owner, spender, value);
    }

    /**
     * @dev {IERC20Permit-nonces}を参照。
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev {IERC20Permit-DOMAIN_SEPARATOR}を参照。
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "nonceを消費": `owner`の現在の`nonce`を返し、1増加させる。
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }
}
```

## Remix 復現

1. `ERC20Permit` コントラクトをデプロイし、`name` と `symbol` をともに `WTFPermit` に設定します。

2. `signERC20Permit.html` を実行し、`Contract Address` をデプロイした `ERC20Permit` コントラクトアドレスに変更し、その他の情報は以下で提供します。その後、順番に `Connect Metamask` と `Sign Permit` ボタンをクリックして署名し、コントラクト検証のために `r`、`s`、`v` を取得します。署名にはコントラクトをデプロイしたウォレットを使用する必要があります。例えば Remix テストウォレット：

    ```js
    owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4    spender: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    value: 100
    deadline: 115792089237316195423570985008687907853269984665640564039457584007913129639935
    private_key: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
    ```

![](./img/53-2.png)

3. コントラクトの `permit()` メソッドを呼び出し、対応するパラメータを入力して承認を行います。

4. コントラクトの `allowance()` メソッドを呼び出し、対応する `owner` と `spender` を入力すると、承認が成功したことがわかります。

## セキュリティに関する注意

ERC20Permitはオフチェーン署名による承認でユーザーに利便性をもたらしましたが、同時にリスクも生じました。一部のハッカーはこの特性を利用してフィッシング攻撃を行い、ユーザーの署名を騙し取って資産を盗みます。2023年4月のUSDCに対する署名[フィッシング攻撃](https://twitter.com/0xAA_Science/status/1652880488095440897?s=20)では、あるユーザーが228万Uの資産を失いました。

**署名時は、署名内容を慎重に読むことが重要です！**

同時に、一部のコントラクトが`permit`を統合する際にも、DoS（サービス拒否）のリスクをもたらします。`permit`は実行時に現在の`nonce`値を使用するため、コントラクトの関数に`permit`操作が含まれている場合、攻撃者は先行実行で`permit`を実行し、`nonce`が占有されるため目標トランザクションがロールバックされることがあります。

## まとめ

今回は、ERC20PermitというERC20トークン標準の拡張について紹介しました。これにより、ユーザーはオフチェーン署名による承認操作を使用でき、ユーザーエクスペリエンスが改善され、多くのプロジェクトで採用されています。しかし同時に、より大きなリスクももたらし、一つの署名であなたの資産が持ち去られる可能性があります。署名時にはより慎重になることが重要です。