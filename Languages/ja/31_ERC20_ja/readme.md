---
title: 31. ERC20
tags:
  - solidity
  - application
  - wtfacademy
  - ERC20
  - OpenZeppelin
---

# WTF Solidity 超シンプル入門: 31. ERC20

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy\_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

今回、私たちはイーサリアム上の`ERC20`トークンスタンダードについて紹介し、自分用のテストトークンを発行します。

## ERC20

`ERC20`はイーサリアム上のトークンスタンダードです。2015 年 11 月に ビタリック氏が関与した[EIP20](https://eips.ethereum.org/EIPS/eip-20)から来ています。基本的なトークン転送ロジックを実装しています：

- アカウント残高(balanceOf())
- トークンの転送(transfer())
- アプルーブ後のトランスファ(transferFrom())
- アプルーブ(approve())
- トークンの総供給量(totalSupply())
- アプルーブした残高(allowance())
- トークンの情報（オプショナル）：トークン名(name())、シンボル(symbol())、小数点以下の桁数(decimals())

## IERC20

`IERC20`は`ERC20`トークンスタンダードのインターフェースです。`ERC20`トークンが実装すべき関数とイベントを定義しています。

インターフェースを定義した理由は、規格があることで、`ERC20`トークンが共通の関数名、入力パラメータ、出力パラメータを持つことができます。インターフェース関数は、関数名、入力パラメータ、出力パラメータを定義するだけで、内部の実装には関心がないためです。

これによって、関数は内部と外部の 2 つの部分に分かれます。片方は実装に重点を置き、もう一方は外部インターフェースを定義し、共通データを規定します。これが`ERC20.sol`と`IERC20.sol`の 2 つのファイルが必要な理由です。

### Event

`IERC20`が 2 つのイベントを定義しています：`Transfer`イベントと`Approval`イベント。これらはトランスファとアプルーブ時に放出されます。

```solidity
/**
    * @dev 放出条件： `value` 数量のトークンが (`from`)アカウントから (`to`)アカウントへ移動した時
    */
event Transfer(address indexed from, address indexed to, uint256 value);

/**
    * @dev 放出条件： `value` 数量のトークンが  (`owner`) アカウントからもう一個のアカウント(`spender`)へ権限委譲された時
    */
event Approval(address indexed owner, address indexed spender, uint256 value);
```

### 関数

`IERC20`が `6` つの関数を定義しています。これらは基本的なトークン転送機能を提供し、トークンが第三者によって使用されるための承認を可能にしています。

- `totalSupply()`：トークンの総供給量を返します。

  ```solidity
  /**
   * @dev トークンの総供給量を返却
   */
  function totalSupply() external view returns (uint256);
  ```

- `balanceOf()`：`account`が保持しているトークン数量を返します。

  ```solidity
  /**
   * @dev `account`所持のトークン数量を返却
   */
  function balanceOf(address account) external view returns (uint256);
  ```

- `transfer()`：トークンをトランスファ

  ```solidity
    /**
     * @dev  `amount` の数量のトークンをトランザクションのcallerから`to`アカウントへ転送
     *
     * もし成功した場合、`true`を返却
     *
     * ｛Transfer｝イベントを放出
     */
    function transfer(address to, uint256 amount) external returns (bool);
  ```

- `allowance()`：アプルーブした数量を返します

  ```solidity
  /**
   * @dev 返回`owner`账户授权给`spender`账户的额度，默认为0。
   *
   * 当{approve} 或 {transferFrom} 被调用时，`allowance`会改变.
   */
  function allowance(address owner, address spender) external view returns (uint256);
  ```

- `approve()`：一定の数量の権限を誰かに委任します

  ```solidity
    /**
     * @dev callerが`spender`に`amount`数量のトークンを委任する
     *
     * もし成功した場合、`true`を返却
     *
     * {Approval} イベントを放出
     */
    function approve(address spender, uint256 amount) external returns (bool);
  ```

- `transferFrom()`：委任された側がアプルーブされた数量を転送します

  ```solidity
    /**
     * @dev アプルーブのメカニズムを通じて、`from`アカウントから`to`アカウントへ`amount`数量のトークンを転送する。転送された部分は呼び出し者の`allowance`から差し引かれる。
     *
     * もし成功した場合、`true`を返却
     *
     * {Transfer} イベントを放出
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
  ```

## ERC20 の実装

今から、シンプルな`ERC20`を書いて、`IERC20`の関数を実装します。

### 状態変数

私たちは状態変数を使ってアカウントの残高を管理し、アプルーブ量とトークン情報を記録します。その中で、`balanceOf`、`allowance`、`totalSupply`は`public`型関数で、同名の`getter`関数が自動生成され、`IERC20`で定義された`balanceOf()`、`allowance()`、`totalSupply()`を実装します。

`name`、`symbol`、`decimals`はトークンの名前、シンボル、小数点以下桁数を表します。

**注意**：`override`がついている`public`変数は、親コントラクトから継承された同名の`getter`関数を上書きします。例えば、`IERC20`の`balanceOf()`関数です。

```solidity
mapping(address => uint256) public override balanceOf;

mapping(address => mapping(address => uint256)) public override allowance;

uint256 public override totalSupply;   // トークンの総供給量

string public name;   // 名前
string public symbol;  // シンボル

uint8 public decimals = 18; // 小数点以下桁数
```

### 関数

- コンストラクタ：トークン名、シンボルを初期化します。

  ```solidity
  constructor(string memory name_, string memory symbol_){
      name = name_;
      symbol = symbol_;
  }
  ```

- `transfer()`関数：`IERC20`の`transfer`関数を実装し、トークンの転送ロジックを提供します。呼び出し元の`amount`のトークンを差し引き、受信者が持っているトークンを増加させます。
- shitcoin はこの関数を改造し、税金、配当、抽選などのロジックを追加します。

  ```solidity
  function transfer(address recipient, uint amount) public override returns (bool) {
      balanceOf[msg.sender] -= amount;
      balanceOf[recipient] += amount;
      emit Transfer(msg.sender, recipient, amount);
      return true;
  }
  ```

- `approve()`関数：`IERC20`の`approve`関数を実装し、トークンの権限委任ロジックを提供します。`spender`に`amount`のトークンを委任します。
- `spender`は EOA アカウントでも、コントラクトアカウントでも構いません。たとえば、`uniswap`でトークンを取引するとき、`uniswap`コントラクトにトークンを委任する必要があります。

  ```solidity
  function approve(address spender, uint amount) public override returns (bool) {
      allowance[msg.sender][spender] = amount;
      emit Approval(msg.sender, spender, amount);
      return true;
  }
  ```

- `transferFrom()`関数：`IERC20`の`transferFrom`関数を実装し、アプルーブされた数量のトークンを転送する機能を提供します。委任された側がアプルーブされた`sender`のトークン数量を`recipient`に転送します。

  ```solidity
  function transferFrom(
      address sender,
      address recipient,
      uint amount
  ) public override returns (bool) {
      allowance[sender][msg.sender] -= amount;
      balanceOf[sender] -= amount;
      balanceOf[recipient] += amount;
      emit Transfer(sender, recipient, amount);
      return true;
  }
  ```

- `mint()`関数：トークンを鋳造する関数で、`IERC20`標準には含まれていません。ここでは、チュートリアルの便宜上、誰でも任意の数量のトークンを鋳造できますが、実際のアプリケーションでは権限管理がきちんとされていると`owner`だけがトークンを鋳造できます。

  ```solidity
  function mint(uint amount) external {
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);
  }
  ```

- `burn()`関数：トークンを焼却する関数で、`IERC20`標準には含まれていません。トークンを焼却することで、トークンの総供給量が減少します。

  ```solidity
  function burn(uint amount) external {
      balanceOf[msg.sender] -= amount;
      totalSupply -= amount;
      emit Transfer(msg.sender, address(0), amount);
  }
  ```

## `ERC20` トークンの発行

`ERC20`スタンダードが現れてから、イーサリアム上でのトークン発行が非常簡単になりました。今回は、自分用のテストトークンを発行します。

`Remix`で`ERC20`コントラクトをコンパイルし、デプロイ画面でコンストラクタのパラメータに`name_`と`symbol_`を入力し、両方を`WTF`に設定し、`transact`ボタンをクリックしてデプロイします。

![コントラクトのデプロイ](./img/31-1.png)

このように、`WTF`トークンを作成しました。続いて`Deployed Contract`にある`ERC20`コントラクトを開いて、`mint()`関数を実行します。自分に`100`個の`WTF`トークンをミントします。

右側の`Debug`ボタンをクリックして、ログを確認します。

中には 4 つの重要な情報が含まれています：

- イベント`Transfer`
- ミントアドレス`0x0000000000000000000000000000000000000000`
- 受取アドレス`0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`
- `100`

![トークンをミント](./img/31-2.png)

`balanceOf()`関数を使ってアカウントの残高を確認します。現在のアカウントを入力すると、残高が`100`に変わっていることがわかります。鋳造成功です。

アカウントの情報は画像の左側にあり、右側に関数の実行情報が表示されています。

![残高を確認](./img/31-3.png)

## まとめ

今回、私たちはイーサリアムにある`ERC20`スタンダード及びその実装について学び、自分用のテストトークンを発行しました。2015 年末に提案された`ERC20`トークンスタンダードは、イーサリアム上でのトークン発行の敷居を大幅に下げ、`ICO`の時代を迎えました。

投資する場合、プロジェクトのトークン契約を注意深く読むことで、投資リスクを回避し、投資成功率を高めることができるでしょう。
