# OnChain Transaction Debugging: 2. Warm up

Author: [Sun](https://twitter.com/1nf0s3cpt)

链上交易数据包含从简单的单笔交易转帐、1 个 DeFi 合约交互、多个 DeFi 合约交互、闪电贷套利、治理提案、跨链交易等等，这一节我们先来热身一下，先从简单的开始。我将介绍通常使用区块链浏览器 Etherscan 哪些讯息是我们所在意的，再来我们会使用交易分析工具 [Phalcon](https://phalcon.blocksec.com/) 看一下这些交易从简单的转帐、UniSWAP上 Swap、Curve 3pool 增加流动性、Compound 治理提案、闪电贷的调用差异。

## 开始进入热身篇
- 首先环境上需要先安装 [Foundry](https://github.com/foundry-rs/foundry)，安装方法请参考 [instructions](https://book.getfoundry.sh/getting-started/installation.html).
    - 测试主要会用到 [Forge test](https://book.getfoundry.sh/reference/forge/forge-test)，如果第一次使用 Foundry，可以参考 [Foundry book](https://book.getfoundry.sh/)、[Foundry @EthCC](https://www.youtube.com/watch?v=wJnywGB33O4)、[WTF Solidity - Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)
- 每条链上都有专属的区块链浏览器，这节我们都会使用 Ethereum 主网来当案例所以可以透过 Etherscan 来分析.
- 通常我会特别想看的栏位包含:
    -  Transaction Action: 因为复杂的交易中 ERC-20 Tokens Transferred 会很复杂，可读性不好，所以可以透过 Transaction Action 看一下关键行为但不一定每笔交易都有
    -  From: msg.sender 执行这笔交易的来源钱包地址
    -  Interacted With (To): 跟哪个合约交互
    -  ERC-20 Tokens Transferred: 代币转移流程
    -  Input Data: 交易的原始 Input 资料，可以看到呼叫什么 Function 和带入什么 Value
- 如果还不知道常用工具有哪些可以回顾第一课交易分析[工具篇](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools)

## 链上转帐
![图片](https://user-images.githubusercontent.com/52526645/211021954-6c5828be-7293-452b-8ef6-a268db54b932.png)
从上图[例子](https://etherscan.io/tx/0x96a3fdd23fc5052d99b4be0ac55dc9b0eeff888fba447cce6b4dce1743497ad1) 可以解读为:

From: 发送这笔交易的来源钱包地址

Interacted With (To): Tether USD (USDT) 合约

ERC-20 Tokens Transferred: 从用户A 钱包转 651.13 USDT 到用户 B

Input Data: 呼叫了 transfer function

透过 [phalcon](https://phalcon.blocksec.com/tx/eth/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) 来看: 从调用流程来看就只有一个 `Call USDT.transfer`，要注意的是 Value. 因为 EVM 不支持浮点数的运算，所以使用精度代表，每个 Token 都要注意它的精度大小，标准 ERC-20 代币精度为 18，但也有特例，如 USDT 为例，精度是 6 所以 Value 带入的值为 651130000，如果精度处理不当就容易造成问题。精度的查询方式可以到 [Etherscan](https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7) 代币合约上看到。

![图片](https://user-images.githubusercontent.com/52526645/211123692-d7224ced-bc0b-47a1-a876-2af086e2fce9.png)

![图片](https://user-images.githubusercontent.com/52526645/211022964-f819b35c-d442-488c-9645-7733af219d1c.png)

## Uniswap Swap

![图片](https://user-images.githubusercontent.com/52526645/211029091-c24963c7-d2f8-44f4-ad6a-a9185f98ec85.png)

从上图[例子](https://etherscan.io/tx/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) 可以解读为:

Transaction Action: 很直觉就可以知道用户在 Uniswap 上进行 Swap，将 12,716 USDT 换成 7,118 UNDEAD。

From: 发送这笔交易的来源钱包地址

Interacted With (To): 这个例子是一个 MEV Bot 合约呼叫 Uniswap 合约进行 Swap

ERC-20 Tokens Transferred: Token 交换的过程

透过 [phalcon](https://phalcon.blocksec.com/tx/eth/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) 来看: MEV Bot 呼叫 Uniswap V2 USDT/UNDEAD 交易对合约呼叫 [swap](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/pair#swap-1) 函示来进行代币兑换。

![图片](https://user-images.githubusercontent.com/52526645/211029737-4a606d32-2c96-41e9-aef7-82fe1fb4b21d.png)

我们使用 Foundry 来模拟操作使用 1BTC 在 Uniswap 换成 DAI，[范例程式码](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2.sol)参考，执行以下指令
```sh
forge test --contracts ./src/test/Uniswapv2.sol -vvvv
```

如下图所示我们透过呼叫 Uniswap_v2_router.[swapExactTokensForTokens](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#swapexacttokensfortokens) 函式，将 1BTC 换到 16,788 DAI.

![圖片](https://user-images.githubusercontent.com/52526645/211143644-6ed295f0-e0d8-458b-a6a7-71b2da8a5baa.png)

## Curve 3pool - DAI/USDC/USDT

![图片](https://user-images.githubusercontent.com/52526645/211030934-14fccba9-5239-480c-b431-21de393a6308.png)

从上图[例子](https://etherscan.io/tx/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b)可以解读为:

在 Curve 3pool 增加流动性

From: 发送这笔交易的来源钱包地址

Interacted With (To): Curve.fi: DAI/USDC/USDT Pool

ERC-20 Tokens Transferred: 用户 A 转入 3,524,968.44 USDT 到 Curve 3 pool，然后 Curve 铸造 3,447,897.54 3Crv 代币给用户 A.

透过 [phalcon](https://phalcon.blocksec.com/tx/eth/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) 来看: 从调用流程来看执行了三个步骤 1.add_liquidity 2.transferFrom 3.mint

![图片](https://user-images.githubusercontent.com/52526645/211032540-b8ad83af-44cf-48ea-b22c-6c79d4dac1af.png)

## Compound propose

![图片](https://user-images.githubusercontent.com/52526645/211033609-60713c9d-1760-45d4-957f-a74e08abf9a5.png)

从上图[例子](https://etherscan.io/tx/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159)可以解读为: 用户在 Compound 治理合约上提交了一个提案，从 Etherscan 上可以点击 Decode Input Data 就可以看到提案内容。

![图片](https://user-images.githubusercontent.com/52526645/211033906-e3446f69-404e-4347-a0c6-e1b622039c5a.png)

透过 [phalcon](https://phalcon.blocksec.com/tx/eth/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) 来看: 透过呼叫 propose 函式来提交 proposal 得到编号 44 号提案。

![图片](https://user-images.githubusercontent.com/52526645/211034346-a600cbf4-eed9-47ca-8b5a-88232808f3a3.png)

## Uniswap Flashswap

这里我们使用 Foundry 来模拟操作看看如何在 Uniswap 上使用闪电贷，[官方Flash swap介绍](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)

[范例程式码](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2_flashswap.sol)参考

![图片](https://user-images.githubusercontent.com/52526645/211125357-695c3fd0-4a56-4a70-9c98-80bac65586b8.png)

```sh
forge test --contracts ./src/test/Uniswapv2_flashswap.sol -vv
```
以这个例子透过 Uniswap UNI/WETH 交易兑上进行闪电贷借出 100 颗 WETH，再还回去给 Uniswap. 注意还款时要付 0.3% 手续费。

从下图调用流程可以看出，呼叫 swap 进行 flashswap 然后透过 callback uniswapV2Call 来还款。

![图片](https://user-images.githubusercontent.com/52526645/211038895-a1bc681a-41cd-4900-a745-3d3ddd0237d4.png)

简单区分一下 Flashloan 和 Flashswap 的差异，两种都是无需抵押资产就可以借出 Token，且需要在同一个区块内还回去不然交易就会失败，假如透过 token0/token1 进行 Flashloan 借出 token0 就要还 token0回去，Flashswap 借出 token0 可以还 token0 或 token1 回去，比较弹性。

更多 DeFi 基本操作可以参考 [DeFiLabs](https://github.com/SunWeb3Sec/DeFiLabs)


## Foundry cheatcodes

Foundry 的 cheatcodes 在我们做链上分析必须使用到的，这边我介绍一下常用到的函式，更多介绍可以参考 [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

- createSelectFork: 指定这次测试要复制哪个网路和区块高度，注意每条链的 RPC 要写在 [foundry.toml](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/foundry.toml)
- deal: 设定测试钱包余额 
    -  设定 ETH 余额 `deal(address(this), 3 ether);`
    -  设定 Token 余额 `deal(address(USDC), address(this), 1 * 1e18);`
- prank: 模拟指定钱包身份，只有在下一个呼叫有效，下一个 msg.sender 是会所指定的钱包，例如使用巨鲸钱包转帐
- startPrank: 模拟指定钱包身份，在没有执行`stopPrank()`之前，所有 msg.sender 都会是指定的钱包地址
- label: 将钱包地址标签化，方便在使用 Foundry debug 时提高可读性
- roll: 调整区块高度
- warp: 调整 block.timestamp

谢谢收看，我们准备进入下一课

## Resources
[Foundry book](https://book.getfoundry.sh/)

[Awesome-foundry](https://github.com/crisgarner/awesome-foundry)

[Foundry @EthCC](https://www.youtube.com/watch?v=wJnywGB33O4) | [Slides](https://docs.google.com/presentation/d/1AuQojnFMkozOiR8kDu5LlWT7vv1EfPytmVEeq1XMtM0/edit#slide=id.g13d8bd167cb_0_0)

[WTF Solidity - Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)

[Flashloan vs Flashswap](https://blog.infura.io/post/build-a-flash-loan-arbitrage-bot-on-infura-part-i)
