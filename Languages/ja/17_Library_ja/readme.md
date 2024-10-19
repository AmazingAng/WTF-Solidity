---
title: 17. ライブラリコントラクト
tags:
  - solidity
  - advanced
  - wtfacademy
  - library
  - using for
---

# WTF Solidity 超シンプル入門: 17. ライブラリコントラクト - 巨人の肩に乗る

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy\_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、`ERC721`の参照として使用される`String`ライブラリコントラクトを例に、`Solidity`のライブラリコントラクト（`Library`）について説明し、一般的なライブラリの使い方をまとめました。

## ライブラリコントラクト

ライブラリコントラクトは特別なコントラクトであり、`Solidity`コードの再利用性を高め、`gas`を削減するために存在します。ライブラリコントラクトは、大御所やプロジェクトチームによって作成された一連の関数の集合体であり、私たちは巨人たちの肩に乗って、使うことができますので、非常に便利です。

![ライブラリコントラクト：巨人の肩に乗る](https://images.mirror-media.xyz/publication-images/HJC0UjkALdrL8a2BmAE2J.jpeg?height=300&width=388)

普通のコントラクトとは異なり、ライブラリコントラクトは以下の制限があります。

1. 状態変数は存在してはならない
2. 継承したり継承されたりすることはない
3. イーサリアムは受け取れない
4. `selfdestruct`されない（コントラクトは消滅できない）

## String ライブラリコントラクト

`Stringライブラリコントラクト`は`uint256`を`string`に変換するためのコードライブラリで、サンプルコードは以下の通り：

```solidity
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
```

ライブラリは主に 2 個の関数を含んでいます：`toString()`は`uint256`を`string`に変換し、`toHexString()`は`uint256`を`16進数`に変換し、`string`に変換します。

### ライブラリコントラクトの使い方

`String`ライブラリコントラクトの`toHexString()`を使って、2 つのライブラリコントラクトの関数を使う方法を示します。

1. `using for`を使うケース

   コマンドの`using A for B;`は、ライブラリ`A`を任意の型`B`に追加するために使用できます。コマンドを追加すると、ライブラリ`A`の関数は自動的に`B`型変数のメンバーとして追加され、直接呼び出すことができます。注意：呼び出す際、この変数は関数に第 1 引数として渡されます。

   ```solidity
   // using forを使ってuint256型の変数にStringライブラリを適用
   using Strings for uint256;
   function getString1(uint256 _number) public pure returns(string memory){
       // ライブラリコントラクトの関数は自動的にuint256型変数のメンバーとして追加されます
       return _number.toHexString();
   }
   ```

2. ライブラリ名を使用して関数を呼び出す

   ```solidity
   // ライブラリ名を使用して関数を呼び出す
   function getString2(uint256 _number) public pure returns(string memory){
       return Strings.toHexString(_number);
   }
   ```

コントラクトをデプロイし、`170`を入力してテストすると、2 つの方法で正しい`16進数string`「0xaa」が返されることがわかります。ライブラリコントラクトの呼び出しに成功したことをわかります。

![コントラクトの呼び出しに成功する](https://images.mirror-media.xyz/publication-images/bzB_JDC9f5VWHRjsjQyQa.png?height=750&width=580)

## まとめ

今回、私たちは`ERC721`の参照として使用される`String`ライブラリコントラクトを例に、`Solidity`のライブラリコントラクト（`Library`）について説明し、一般的なライブラリの使い方を説明しました。99%の開発者はライブラリコントラクトを自分で書く必要はありません。巨人たちが書いたものを使えば十分です。私たちが知っておくべきことは、どのような状況でどのライブラリコントラクトを使用するかです。一般的に使用されるライブラリコントラクトは以下の通り：

1. [String](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Strings.sol)：`uint256`を`string`に変換するためのライブラリ
2. [Address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Address.sol)：アドレス関連のライブラリ、アドレスがコントラクトアドレスかどうかを判断するためのライブラリ
3. [Create2](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Create2.sol)：`CREATE2`関数を提供するライブラリ
4. [Arrays](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Arrays.sol)：配列関連のライブラリ、配列の操作を提供するライブラリ
