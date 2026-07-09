---
title: 57. フラッシュローン
tags:
  - solidity
  - flashloan
  - defi
  - uniswap
  - aave
---

# WTF Solidity極簡入門: 57. フラッシュローン

私は最近Solidityを再学習しており、基礎を固めるために「WTF Solidity極簡入門」を執筆しています。これは初心者向けのガイドです（プログラミング上級者は他のチュートリアルをご参照ください）。毎週1-3レッスンを更新します。

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

コミュニティ: [Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのコードとチュートリアルはGitHubでオープンソース化されています: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

「フラッシュローン攻撃」という言葉をきっと聞いたことがあるでしょうが、フラッシュローンとは何でしょうか？フラッシュローンコントラクトをどのように作成するのでしょうか？このレッスンでは、ブロックチェーンにおけるフラッシュローンについて紹介し、Uniswap V2、Uniswap V3、およびAAVE V3をベースとしたフラッシュローンコントラクトを実装し、Foundryを使用してテストします。

## フラッシュローン

「フラッシュローン」という概念を初めて聞いたのはきっとWeb3でしょう。Web2にはこのような仕組みは存在しないからです。フラッシュローン（Flashloan）はDeFiの革新的な仕組みで、ユーザーが1つのトランザクション内で資金を借り入れて迅速に返済することを可能にし、担保を提供する必要がありません。

例えば、市場で突然裁定取引（アービトラージ）の機会を発見したとしましょう。しかし、裁定取引を完了するには100万USDの資金が必要です。Web2では銀行にローンを申請する必要がありますが、審査が必要で、裁定取引の機会を逃してしまう可能性があります。また、裁定取引が失敗した場合、利息を支払うだけでなく、損失した元本も返済する必要があります。

一方、Web3では、DeFiプラットフォーム（Uniswap、AAVE、Dodo）でフラッシュローンを利用して資金を調達できます。無担保で100万USDのトークンを借り、オンチェーン裁定取引を実行し、最後にローンと利息を返済することができます。

フラッシュローンはイーサリアムトランザクションのアトミック性を利用しています。1つのトランザクション（その中のすべての操作を含む）は完全に実行されるか、完全に実行されないかのどちらかです。ユーザーがフラッシュローンを使用しようとして、同じトランザクション内で資金を返済しなかった場合、トランザクション全体が失敗してロールバックされ、まるで何も起こらなかったかのようになります。そのため、DeFiプラットフォームは借り手が返済できないことを心配する必要がありません。返済できない場合は、お金が借り出されなかったことを意味するからです。同時に、借り手も裁定取引の失敗を心配する必要がありません。裁定取引が成功しなければ返済できず、それは借入が成功しなかったことを意味するからです。

![](./img/57-1.png)

## フラッシュローン実装

以下では、Uniswap V2、Uniswap V3、およびAAVE V3でのフラッシュローンコントラクトの実装方法をそれぞれ紹介します。

### 1. Uniswap V2フラッシュローン

[Uniswap V2 Pair](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol#L159)コントラクトの`swap()`関数はフラッシュローンをサポートしています。フラッシュローンビジネスに関連するコードは以下の通りです：

```solidity
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
    // その他のロジック...

    // 楽観的にトークンをtoアドレスに送信
    if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
    if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

    // toアドレスのコールバック関数uniswapV2Callを呼び出し
    if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

    // その他のロジック...

    // k=x*y公式を通じて、フラッシュローンが正常に返済されたかをチェック
    require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
}
```

`swap()`関数では：

1. まずプールからトークンを楽観的に`to`アドレスに転送します。
2. 渡された`data`の長さが`0`より大きい場合、`to`アドレスのコールバック関数`uniswapV2Call`を呼び出し、フラッシュローンロジックを実行します。
3. 最後に`k=x*y`でフラッシュローンが正常に返済されたかをチェックし、成功しなかった場合はトランザクションをロールバックします。

以下では、フラッシュローンコントラクト`UniswapV2Flashloan.sol`を完成させます。`IUniswapV2Callee`を継承し、フラッシュローンのコアロジックをコールバック関数`uniswapV2Call`に記述します。

全体のロジックは非常にシンプルです。フラッシュローン関数`flashloan()`では、Uniswap V2の`WETH-DAI`プールから`WETH`を借ります。フラッシュローンがトリガーされた後、コールバック関数`uniswapV2Call`がPairコントラクトによって呼び出されます。裁定取引は行わず、利息を計算した後にフラッシュローンを返済します。Uniswap V2フラッシュローンの利息は1回あたり`0.3%`です。

**注意**：コールバック関数では適切な権限制御を行い、UniswapのPairコントラクトのみが呼び出せるようにしてください。そうしないと、コントラクト内の資金がハッカーに盗まれる可能性があります。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV2フラッシュローンコールバックインターフェース
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// UniswapV2フラッシュローンコントラクト
contract UniswapV2Flashloan is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
    }

    // フラッシュローン関数
    function flashloan(uint wethAmount) external {
        // calldataの長さが1より大きい場合にフラッシュローンコールバック関数をトリガー
        bytes memory data = abi.encode(WETH, wethAmount);

        // amount0Outは借りるDAI、amount1Outは借りるWETH
        pair.swap(0, wethAmount, address(this), data);
    }

    // フラッシュローンコールバック関数、DAI/WETH pairコントラクトのみが呼び出し可能
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // DAI/WETH pairコントラクトからの呼び出しであることを確認
        address token0 = IUniswapV2Pair(msg.sender).token0(); // token0アドレスを取得
        address token1 = IUniswapV2Pair(msg.sender).token1(); // token1アドレスを取得
        assert(msg.sender == factory.getPair(token0, token1)); // msg.senderがV2ペアであることを確認

        // calldataをデコード
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // フラッシュローンロジック、ここでは省略
        require(tokenBorrow == WETH, "token borrow != WETH");

        // フラッシュローン手数料を計算
        // fee / (amount + fee) = 3/1000
        // 切り上げ
        uint fee = (amount1 * 3) / 997 + 1;
        uint amountToRepay = amount1 + fee;

        // フラッシュローンを返済
        weth.transfer(address(pair), amountToRepay);
    }
}
```

Foundryテストコントラクト`UniswapV2Flashloan.t.sol`：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapV2Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    UniswapV2Flashloan private flashloan;

    function setUp() public {
        flashloan = new UniswapV2Flashloan();
    }

    function testFlashloan() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e18);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        flashloan.flashloan(amountToBorrow);
    }

    // 手数料が不足している場合、リバートする
    function testFlashloanFail() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 3e17);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        // 手数料不足
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}
```

テストコントラクトでは、手数料が充分な場合と不足している場合をそれぞれテストしています。Foundryインストール後、以下のコマンドラインでテストできます（RPCを他のイーサリアムRPCに変更できます）：

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/UniswapV2Flashloan.t.sol -vv
```

### 2. Uniswap V3フラッシュローン

Uniswap V2が`swap()`交換関数でフラッシュローンを間接的にサポートするのとは異なり、Uniswap V3は[Poolプールコントラクト](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L791C1-L835C1)に`flash()`関数を追加してフラッシュローンを直接サポートしています。コアコードは以下の通りです：

```solidity
function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
) external override lock noDelegateCall {
    // その他のロジック...

    // 楽観的にトークンをtoアドレスに送信
    if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
    if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

    // toアドレスのコールバック関数uniswapV3FlashCallbackを呼び出し
    IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);

    // フラッシュローンが正常に返済されたかをチェック
    uint256 balance0After = balance0();
    uint256 balance1After = balance1();
    require(balance0Before.add(fee0) <= balance0After, 'F0');
    require(balance1Before.add(fee1) <= balance1After, 'F1');

    // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
    uint256 paid0 = balance0After - balance0Before;
    uint256 paid1 = balance1After - balance1Before;

    // その他のロジック...
}
```

以下では、フラッシュローンコントラクト`UniswapV3Flashloan.sol`を完成させます。`IUniswapV3FlashCallback`を継承し、フラッシュローンのコアロジックをコールバック関数`uniswapV3FlashCallback`に記述します。

全体のロジックはV2と類似しており、フラッシュローン関数`flashloan()`では、Uniswap V3の`WETH-DAI`プールから`WETH`を借ります。フラッシュローンがトリガーされた後、コールバック関数`uniswapV3FlashCallback`がPoolコントラクトによって呼び出されます。裁定取引は行わず、利息を計算した後にフラッシュローンを返済します。Uniswap V3のフラッシュローン手数料は取引手数料と同じです。

**注意**：コールバック関数では適切な権限制御を行い、UniswapのPairコントラクトのみが呼び出せるようにしてください。そうしないと、コントラクト内の資金がハッカーに盗まれる可能性があります。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV3フラッシュローンコールバックインターフェース
// uniswapV3FlashCallback()関数を実装・オーバーライドする必要があります
interface IUniswapV3FlashCallback {
    /// 実装では、flashで送信されたトークンと計算された手数料を
    /// プールに返済する必要があります。
    /// このメソッドを呼び出すコントラクトは、公式UniswapV3Factoryで
    /// デプロイされたUniswapV3Poolによってチェックされる必要があります。
    /// @param fee0 フラッシュローン終了時にプールに支払うtoken0の手数料
    /// @param fee1 フラッシュローン終了時にプールに支払うtoken1の手数料
    /// @param data IUniswapV3PoolActions#flash呼び出しで呼び出し元から渡された任意のデータ
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// UniswapV3フラッシュローンコントラクト
contract UniswapV3Flashloan is IUniswapV3FlashCallback {
    address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant poolFee = 3000;

    IERC20 private constant weth = IERC20(WETH);
    IUniswapV3Pool private immutable pool;

    constructor() {
        pool = IUniswapV3Pool(getPool(DAI, WETH, poolFee));
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) public pure returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return PoolAddress.computeAddress(UNISWAP_V3_FACTORY, poolKey);
    }

    // フラッシュローン関数
    function flashloan(uint wethAmount) external {
        bytes memory data = abi.encode(WETH, wethAmount);
        IUniswapV3Pool(pool).flash(address(this), 0, wethAmount, data);
    }

    // フラッシュローンコールバック関数、DAI/WETH pairコントラクトのみが呼び出し可能
    function uniswapV3FlashCallback(
        uint fee0,
        uint fee1,
        bytes calldata data
    ) external {
        // DAI/WETH pairコントラクトからの呼び出しであることを確認
        require(msg.sender == address(pool), "not authorized");

        // calldataをデコード
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // フラッシュローンロジック、ここでは省略
        require(tokenBorrow == WETH, "token borrow != WETH");

        // フラッシュローンを返済
        weth.transfer(address(pool), wethAmount + fee1);
    }
}
```

Foundryテストコントラクト`UniswapV3Flashloan.t.sol`：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/UniswapV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV3FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    UniswapV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new UniswapV3Flashloan();
    }

    function testFlashloan() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e18);

        uint balBefore = weth.balanceOf(address(flashloan));
        console2.logUint(balBefore);
        // フラッシュローン借入金額
        uint amountToBorrow = 1 * 1e18;
        flashloan.flashloan(amountToBorrow);
    }

    // 手数料が不足している場合、リバートする
    function testFlashloanFail() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e17);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        // 手数料不足
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}
```

テストコントラクトでは、手数料が充分な場合と不足している場合をそれぞれテストしています。Foundryインストール後、以下のコマンドラインでテストできます（RPCを他のイーサリアムRPCに変更できます）：

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/UniswapV3Flashloan.t.sol -vv
```

### 3. AAVE V3フラッシュローン

AAVEは分散型貸出プラットフォームで、その[Poolコントラクト](https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/pool/Pool.sol#L424)は`flashLoan()`と`flashLoanSimple()`の2つの関数を通じて単一資産と複数資産のフラッシュローンをサポートしています。ここでは、`flashLoanSimple()`を利用して単一資産（`WETH`）のフラッシュローンを実装します。

以下では、フラッシュローンコントラクト`AaveV3Flashloan.sol`を完成させます。`IFlashLoanSimpleReceiver`を継承し、フラッシュローンのコアロジックをコールバック関数`executeOperation`に記述します。

全体のロジックはV2と類似しており、フラッシュローン関数`flashloan()`では、AAVE V3の`WETH`プールから`WETH`を借ります。フラッシュローンがトリガーされた後、コールバック関数`executeOperation`がPoolコントラクトによって呼び出されます。裁定取引は行わず、利息を計算した後にフラッシュローンを返済します。AAVE V3フラッシュローンの手数料はデフォルトで1回あたり`0.05%`で、Uniswapより低くなっています。

**注意**：コールバック関数では適切な権限制御を行い、AAVEのPoolコントラクトのみが呼び出し、開始者がこのコントラクトであることを確認してください。そうしないと、コントラクト内の資金がハッカーに盗まれる可能性があります。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

interface IFlashLoanSimpleReceiver {
    /**
    * @notice フラッシュローン資産受信後の操作実行
    * @dev コントラクトが債務＋追加手数料を返済できることを確認してください。
    *      例：十分な資金を持ち、プールから総額を引き出すための承認を行っている
    * @param asset フラッシュローン資産のアドレス
    * @param amount フラッシュローン資産の数量
    * @param premium フラッシュローン資産の手数料
    * @param initiator フラッシュローンを開始したアドレス
    * @param params フラッシュローン初期化時に渡されたバイトエンコードパラメータ
    * @return 操作実行が成功した場合はTrue、失敗した場合はFalseを返す
    */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// AAVE V3フラッシュローンコントラクト
contract AaveV3Flashloan {
    address private constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILendingPool public aave;

    constructor() {
        aave = ILendingPool(AAVE_V3_POOL);
    }

    // フラッシュローン関数
    function flashloan(uint256 wethAmount) external {
        aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
    }

    // フラッシュローンコールバック関数、poolコントラクトのみが呼び出し可能
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
        external
        returns (bool)
    {
        // poolコントラクトからの呼び出しであることを確認
        require(msg.sender == AAVE_V3_POOL, "not authorized");
        // フラッシュローン開始者がこのコントラクトであることを確認
        require(initiator == address(this), "invalid initiator");

        // フラッシュローンロジック、ここでは省略

        // フラッシュローン手数料を計算
        // fee = 5/1000 * amount
        uint fee = (amount * 5) / 10000 + 1;
        uint amountToRepay = amount + fee;

        // フラッシュローンを返済
        IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

        return true;
    }
}
```

Foundryテストコントラクト`AaveV3Flashloan.t.sol`：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AaveV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract AaveV3FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    AaveV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new AaveV3Flashloan();
    }

    function testFlashloan() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e18);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        flashloan.flashloan(amountToBorrow);
    }

    // 手数料が不足している場合、リバートする
    function testFlashloanFail() public {
        // WETHに交換し、フラッシュローンコントラクトに転送して手数料として使用
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 4e16);
        // フラッシュローン借入金額
        uint amountToBorrow = 100 * 1e18;
        // 手数料不足
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}
```

テストコントラクトでは、手数料が充分な場合と不足している場合をそれぞれテストしています。Foundryインストール後、以下のコマンドラインでテストできます（RPCを他のイーサリアムRPCに変更できます）：

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/AaveV3Flashloan.t.sol -vv
```

## まとめ

このレッスンでは、フラッシュローンについて紹介しました。フラッシュローンは、ユーザーが1つのトランザクション内で資金を借り入れて迅速に返済することを可能にし、担保を提供する必要がない仕組みです。そして、Uniswap V2、Uniswap V3、およびAAVEのフラッシュローンコントラクトをそれぞれ実装しました。

フラッシュローンを通じて、私たちは無担保で大量の資金を活用してリスクフリーの裁定取引や脆弱性攻撃を行うことができます。あなたはフラッシュローンで何をする予定ですか？