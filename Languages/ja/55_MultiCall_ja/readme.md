---
title: 55. マルチコール
tags:
  - solidity
  - erc20
---

# WTF Solidity 超シンプル入門: 55. マルチコール

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、MultiCall マルチコールコントラクトについて紹介します。その設計目的は、1つのトランザクションで複数の関数呼び出しを実行することで、トランザクション手数料を大幅に削減し、効率性を向上させることです。

## MultiCall

Solidityにおいて、MultiCall（マルチコール）コントラクトの設計により、1つのトランザクションで複数の関数呼び出しを実行できます。その利点は以下の通りです：

1. 利便性：MultiCallにより、1つのトランザクションで異なるコントラクトの異なる関数を異なるパラメータで呼び出すことができます。例えば、複数のアドレスのERC20トークン残高を一度にクエリできます。

2. ガス節約：MultiCallは複数のトランザクションを1つのトランザクション内の複数の呼び出しに統合し、ガスを節約できます。

3. 原子性：MultiCallにより、ユーザーは1つのトランザクションですべての操作を実行でき、すべての操作が成功するか、すべて失敗するかを保証し、原子性を維持します。例えば、特定の順序で一連のトークン取引を行うことができます。

## MultiCall コントラクト

次に、MultiCallコントラクトを一緒に研究しましょう。これは MakerDAO の [MultiCall](https://github.com/mds1/multicall/blob/main/src/Multicall3.sol) を簡略化したものです。

MultiCall コントラクトは2つの構造体を定義しています：

- `Call`: これは呼び出し構造体で、呼び出すターゲットコントラクト `target`、呼び出し失敗を許可するかどうかを示すフラグ `allowFailure`、呼び出すバイトコード `call data` を含みます。

- `Result`: これは結果構造体で、呼び出しが成功したかどうかを示すフラグ `success` と呼び出しが返すバイトコード `return data` を含みます。

このコントラクトにはマルチコールを実行する関数が1つだけ含まれています：

- `multicall()`: この関数のパラメータはCall構造体で構成される配列で、targetとdataの長さが一致することを保証します。関数はループを通じて複数の呼び出しを実行し、呼び出しが失敗した際にトランザクションをロールバックします。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    // Call構造体、ターゲットコントラクトtarget、呼び出し失敗を許可するかallowFailure、call dataを含む
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Result構造体、呼び出しが成功したかとreturn dataを含む
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice 複数の呼び出し（異なるコントラクト/異なるメソッド/異なるパラメータに対応）を1つの呼び出しに統合
    /// @param calls Call構造体で構成される配列
    /// @return returnData Result構造体で構成される配列
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;

        // ループで順次呼び出し
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // calli.allowFailureとresult.successがともにfalseの場合、revert
            if (!(calli.allowFailure || result.success)){
                revert("Multicall: call failed");
            }
        }
    }
}
```

## Remix復現

1. まず、非常にシンプルなERC20トークンコントラクト `MCERC20` をデプロイし、コントラクトアドレスを記録します。

    ```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    contract MCERC20 is ERC20{
        constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

        function mint(address to, uint amount) external {
            _mint(to, amount);
        }
    }
    ```

2. `MultiCall` コントラクトをデプロイします。

3. 呼び出す`calldata`を取得します。2つのアドレスにそれぞれ50と100単位のトークンを鋳造します。remixの呼び出しページで`mint()`のパラメータを入力し、**Calldata** ボタンをクリックして、エンコードされたcalldataをコピーできます。例：

    ```solidity
    to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    amount: 50
    calldata: 0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032
    ```

    ![](./img/55-1.png)

    `calldata`について詳しくない場合は、WTF Solidityの[第29講]を読むことができます。

4. `MultiCall` の `multicall()` 関数を使用してERC20トークンコントラクトの `mint()` 関数を呼び出し、2つのアドレスにそれぞれ50と100単位のトークンを鋳造します。例：

    ```solidity
    calls: [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x40c10f19000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb20000000000000000000000000000000000000000000000000000000000000064"]]
    ```

5. `MultiCall` の `multicall()` 関数を使用してERC20トークンコントラクトの `balanceOf()` 関数を呼び出し、先ほど鋳造した2つのアドレスの残高をクエリします。`balanceOf()`関数のselectorは`0x70a08231`です。例：

    ```solidity
    [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x70a082310000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x70a08231000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2"]]
    ```

    `decoded output`で呼び出しの戻り値を確認できます。2つのアドレスの残高はそれぞれ `0x0000000000000000000000000000000000000000000000000000000000000032` と `0x0000000000000000000000000000000000000000000000000000000000000064`、つまり50と100で、呼び出し成功です！
    ![](./img/55-2.png)

## まとめ

今回は、MultiCall マルチコールコントラクトについて紹介しました。これにより、1つのトランザクションで複数の関数呼び出しを実行できます。注意すべきは、異なるMultiCallコントラクトでは、パラメータと実行ロジックに多少の違いがあるため、使用時にはソースコードを注意深く読む必要があることです。