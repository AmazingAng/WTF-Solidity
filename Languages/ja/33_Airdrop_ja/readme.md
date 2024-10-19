---
title: 33. エアドロコントラクト
tags:
  - solidity
  - application
  - wtfacademy
  - ERC20
  - airdrop
---

# WTF Solidity 超シンプル入門: 33. エアドロップのコントラクト

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy\_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

仮想通貨の世界で最も嬉しいことの一つは、エアドロップをもらうことです。タダでトークンを手に入れられるからです。このレッスンでは、スマートコントラクトを使用して`ERC20`トークンのエアドロップを送信する方法を学びます。

## エアドロップ Airdrop

エアドロップは仮想通貨界隈でのマーケティング戦略の一つで、プロジェクトチームが特定のユーザーグループに無料でトークンを配布します。エアドロップの資格を得るために、ユーザーは通常、製品のテスト、ニュースの共有、友人の紹介など、いくつかの簡単なタスクを完了する必要があります。プロジェクトチームはエアドロップを通じてシードユーザーを獲得し、ユーザーはトークン（価値）を得ることができるため、双方にとって利益があります。

エアドロップを受け取るユーザーが多いため、プロジェクトチームが一つ一つ取引を行うことは不可能です。スマートコントラクトを利用して`ERC20`トークンを一括で配布することで、エアドロップの効率を大幅に向上させることができます。

### エアドロップトークンコントラクト

`Airdrop`エアドロップコントラクトのロジックは非常にシンプルです：ループを使用して、1 回の取引で複数のアドレスに`ERC20`トークンを送信します。コントラクトには 2 つの関数が含まれています：

- `getSum()`関数：`uint`配列の合計を返します。

  ```solidity
  // 配列の合計を計算する関数
  function getSum(uint256[] calldata _arr) public pure returns(uint sum){
      for(uint i = 0; i < _arr.length; i++)
          sum = sum + _arr[i];
  }
  ```

- `multiTransferToken()`関数：`ERC20`トークンのエアドロップを送信します。3 つのパラメータがあります：

  - `_token`：トークンコントラクトアドレス（`address`型）
  - `_addresses`：エアドロップを受け取るユーザーアドレスの配列（`address[]`型）
  - `_amounts`：エアドロップ量の配列、`_addresses`の各アドレスに対応する量（`uint[]`型）

  この関数には 2 つのチェックがあります：最初の`require`は`_addresses`と`_amounts`の 2 つの配列の長さが等しいかをチェックします。2 つ目の`require`はエアドロップコントラクトの承認額がエアドロップするトークンの総量よりも大きいかをチェックします。

  ```solidity
  /// @notice 複数のアドレスにERC20トークンを転送します。使用前にapproveが必要です
  ///
  /// @param _token 転送するERC20トークンのアドレス
  /// @param _addresses エアドロップアドレスの配列
  /// @param _amounts トークン量の配列（各アドレスのエアドロップ量）
  function multiTransferToken(
      address _token,
      address[] calldata _addresses,
      uint256[] calldata _amounts
      ) external {
      // チェック：_addressesと_amountsの配列の長さが等しいこと
      require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
      IERC20 token = IERC20(_token); // IERCコントラクト変数を宣言
      uint _amountSum = getSum(_amounts); // エアドロップするトークンの総量を計算
      // チェック：承認されたトークン量 >= エアドロップするトークンの総量
      require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");

      // forループを使用し、transferFrom関数でエアドロップを送信
      for (uint8 i; i < _addresses.length; i++) {
          token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
      }
  }
  ```

- `multiTransferETH()`関数：`ETH`エアドロップを送信します。2 つのパラメータがあります：

  - `_addresses`：エアドロップを受け取るユーザーアドレスの配列（`address[]`型）
  - `_amounts`：エアドロップ量の配列、`_addresses`の各アドレスに対応する量（`uint[]`型）

  ```solidity
  /// 複数のアドレスにETHを転送
  function multiTransferETH(
      address payable[] calldata _addresses,
      uint256[] calldata _amounts
  ) public payable {
      // チェック：_addressesと_amountsの配列の長さが等しいこと
      require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
      uint _amountSum = getSum(_amounts); // エアドロップするETHの総量を計算
      // 送金されたETHがエアドロップの総量と等しいことをチェック
      require(msg.value == _amountSum, "Transfer amount error");
      // forループを使用し、call関数でETHを送信
      for (uint256 i = 0; i < _addresses.length; i++) {
          // コメントアウトされたコードにはDoS攻撃のリスクがあり、transferも推奨されない書き方です
          // DoS攻撃については https://github.com/AmazingAng/WTF-Solidity/blob/main/S09_DoS/readme.md を参照してください
          // _addresses[i].transfer(_amounts[i]);
          (bool success, ) = _addresses[i].call{value: _amounts[i]}("");
          if (!success) {
              failTransferList[_addresses[i]] = _amounts[i];
          }
      }
  }
  ```

### エアドロップの実践

1. `ERC20`トークンコントラクトをデプロイし、自分に 10000 トークンをミントします。
   ![`ERC20`をデプロイ](./img/33-1.png)
2. `Airdrop`エアドロップコントラクトをデプロイします。
   ![ミント](./img/33-2.png)
3. `ERC20`トークンコントラクトの`approve()`関数を使用して、`Airdrop`エアドロップコントラクトに 10000 単位のトークンを承認します。
   ![`Airdrop`コントラクトをデプロイ](./img/33-3.png)
4. `Airdrop`コントラクトの`multiTransferToken()`関数を実行してエアドロップを行います。`_token`に`ERC20`トークンアドレスを入力し、`_addresses`と`_amounts`は以下のように入力します：
   ![`Airdrop`コントラクトを承認](./img/33-4.png)
5. `ERC20`トークンコントラクトの`balanceOf()`関数を使用して、トークンの残高を確認します。100 から 200 になっていることを確認でき、エアドロが成功していることがわかります。
   ![`Airdrop`コントラクトを承認](./img/33-5.png)

## まとめ

今回は、`Solidity`を使用して`ERC20`トークンのエアドロップを送信する方法を学びました。これにより、エアドロップの効率を大幅に向上させることができます。私が一番最初にもらったエアドロップップは`ENS`でした。あなたたちはどうですか。
