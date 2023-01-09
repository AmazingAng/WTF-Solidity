# OnChain Transaction Debugging: 2. Warm up

Author: [Sun](https://twitter.com/1nf0s3cpt)

Translation: Helen

Community [Discord](https://discord.gg/3y3d9DMQ)

This article is published on XREX and [WTF Academy](https://github.com/AmazingAng/WTF-Solidity#%E9%93%BE%E4%B8%8A%E5%A8%81%E8%83%81%E5%88%86%E6%9E%90)

On-chain data can include simple one-time transfers, interactions with one DeFi contract or multiple DeFi contracts, flash loan arbitrage, governance proposals, cross-chain transactions, and more. In this section, let’s begin with a simple start.
I will introduce on BlockChain Explorer - Etherscan what we are interested in, and then use [Phalcon](https://phalcon.blocksec.com/) to compare the differences between these transaction function calls: Assets transfer, swap on UniSWAP, increase liquidity on Curve 3pool, Compound proposals, Uniswap Flashswap.

## Start to warm up

- The first step is to install [Foundry](https://github.com/foundry-rs/foundry) in the environment. Please follow the installation [instructions](https://book.getfoundry.sh/getting-started/installation).
  - Forge is a Major test tool on the Foundry platform.If it is your first time to use Foundry, you can refer to [Foundry book](https://book.getfoundry.sh/), [Foundry @EthCC](https://www.youtube.com/watch?v=wJnywGB33O4), [WTF Solidity - Foundry](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md).
- Each chain has its own blockchain explorer. In this section, we will use Ethereum's blockchain network as a case study.
- Typical information I usually refer to includes:
  - Transaction Action: Since the transfer of complex ERC-20 tokens can be difficult to discern, Transaction Action can provide the key behavior of the transfer. However, not all transactions include this information.
  - From: msg.sender, the source wallet address that executes this transaction.
  - Interacted With (To): Which contract to interact with
  - ERC-20 Token Transfer: Token Transfer Process
  - Input Data: The raw input data of the transaction. You can see what Function was called and what Value was brought in.
- If you don't know what tools are commonly used, you can view the transaction analysis tools in [the first lesson](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools/en).

## Assets transfer

![圖片](https://user-images.githubusercontent.com/52526645/211021954-6c5828be-7293-452b-8ef6-a268db54b932.png)
The following can be derived from the [Etherscan](https://etherscan.io/tx/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) example above:

- From: This transaction's source EOA wallet address
- Interacted With (To): Tether USD (USDT) Contract
- ERC-20 Tokens Transferred: Transfer 651.13 USDT from user A's wallet to user B
- Input Data: Called transfer function

According to [Phalcon](https://phalcon.blocksec.com/tx/eth/0x836ef3d01a52c4b9304c3d683f6ff2b296c7331b6fee86e3b116732ce1d5d124) "Invocation Flow" :

- There is only one ''Call USDT.transfer''. However, you should pay attention to the "Value".Because the Ethereum Virtual Machine (EVM) does not support floating-point operations, decimals representation is used instead.
- Each token has its own precision, the number of decimal places used to represent the value of the token. In ERC-20 tokens, the decimals are usually 18 digits, while USDT has 6 digits. If the precision of the token is not handled properly, problems will arise.
- You can query it on the Etherscan [token contract](https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7).

![圖片](https://user-images.githubusercontent.com/52526645/211123692-d7224ced-bc0b-47a1-a876-2af086e2fce9.png)

![圖片](https://user-images.githubusercontent.com/52526645/211022964-f819b35c-d442-488c-9645-7733af219d1c.png)

## Uniswap Swap

![圖片](https://user-images.githubusercontent.com/52526645/211029091-c24963c7-d2f8-44f4-ad6a-a9185f98ec85.png)

The following can be derived from the [Etherscan](https://etherscan.io/tx/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) example above:

- Transaction Action: A user performs Swap on Uniswap V2, exchanging 12,716 USDT for 7,118 UNDEAD.
- From: This transaction's source wallet address
- Interacted With (To): A MEV Bot contract called Uniswap contract for Swap.
- ERC-20 Tokens Transferred: Token exchange process

According to [Phalcon](https://phalcon.blocksec.com/tx/eth/0x1cd5ceda7e2b2d8c66f8c5657f27ef6f35f9e557c8d1532aa88665a37130da84) "Invocation Flow" :

- MEV Bot calls the Uniswap V2 USDT/UNDEAD trading pair contract to call the swap function to perform token exchange.

![圖片](https://user-images.githubusercontent.com/52526645/211029737-4a606d32-2c96-41e9-aef7-82fe1fb4b21d.png)

### Foundry

We use Foundry to simulate the operation of using 1BTC to exchange for DAI in Uniswap.

- [Sample code reference](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2.sol), execute the following command:
```sh
forge test --contracts ./src/test/Uniswapv2.sol -vvvv
```
- According to the figure - we swap 1 BTC to 16,788 DAI by calling the Uniswap\_v2\_router.[swapExactTokensForTokens](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#swapexacttokensfortokens) function.

![圖片](https://user-images.githubusercontent.com/52526645/211143644-6ed295f0-e0d8-458b-a6a7-71b2da8a5baa.png)

## Curve 3pool - DAI/USDC/USDT

![圖片](https://user-images.githubusercontent.com/52526645/211030934-14fccba9-5239-480c-b431-21de393a6308.png)

The following can be derived from the [Etherscan](https://etherscan.io/tx/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) example above:

- The purpose of this transaction is to add Liquidity at Curve three pools.
- From: This transaction's source wallet address
- Interacted With (To): Curve.fi: DAI/USDC/USDT Pool
- ERC-20 Tokens Transferred: User A transferred 3,524,968.44 USDT to the Curve 3 pools, and then Curve minted 3,447,897.54 3Crv tokens for User A.

According to [Phalcon](https://phalcon.blocksec.com/tx/eth/0x667cb82d993657f2779507a0262c9ed9098f5a387e8ec754b99f6e1d61d92d0b) "Invocation Flow" :

- Based on the call sequence, three steps were executed:
1.add\_liquidity 2.transferFrom 3.mint.

![圖片](https://user-images.githubusercontent.com/52526645/211032540-b8ad83af-44cf-48ea-b22c-6c79d4dac1af.png)


## Compound propose

![圖片](https://user-images.githubusercontent.com/52526645/211033609-60713c9d-1760-45d4-957f-a74e08abf9a5.png)

The following can be derived from the [Etherscan](https://etherscan.io/tx/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) example above:

- The user submitted a proposal on the Compound. The contents of the proposal can be viewed by clicking "Decode Input Data" on Etherscan.

![圖片](https://user-images.githubusercontent.com/52526645/211033906-e3446f69-404e-4347-a0c6-e1b622039c5a.png)

According to [Phalcon](https://phalcon.blocksec.com/tx/eth/0xba69b455c511c500e0be9453cf70319bc61e29eb4235a6e5ca5fe6ddf1934159) "Invocation Flow" :

- Submitting a proposal through the propose function results in proposal number 44.

![圖片](https://user-images.githubusercontent.com/52526645/211034346-a600cbf4-eed9-47ca-8b5a-88232808f3a3.png)

## Uniswap Flashswap

Here we use Foundry to simulate operations - how to use flash loans on Uniswap. [Official Flash swap introduction](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)

- [Sample Code](https://github.com/SunWeb3Sec/DeFiLabs/blob/main/src/test/Uniswapv2_flashswap.sol) Reference, execute the following command:

```sh
forge test --contracts ./src/test/Uniswapv2_flashswap.sol -vv
```

![圖片](https://user-images.githubusercontent.com/52526645/211125357-695c3fd0-4a56-4a70-9c98-80bac65586b8.png)

- In this example, a flash loan of 100 WETH is borrowed through the Uniswap UNI/WETH exchange. Note that a 0.3% fee must be paid on repayments.
- According to the figure - call flow, flashswap calls swap, and then repays by calling back uniswapV2Call.

![圖片](https://user-images.githubusercontent.com/52526645/211038895-a1bc681a-41cd-4900-a745-3d3ddd0237d4.png)

- Further Introduction to Flashloan and Flashswap:

  - A. Common points:
Both can lend Tokens without collateralizing assets, and they need to be returned in the same block, otherwise the transaction fails.

  - B. The difference:
If token0 is borrowed through Flashloan token0/token1, token0 must be returned. Flashswap lends token0, and you can return token0 or token1, which is more flexible.

For more DeFi basic operations, please refer to [DeFiLab](https://github.com/SunWeb3Sec/DeFiLabs).

## Foundry cheatcodes

Foundry's cheatcodes are essential for conducting chain analysis. Here, I will introduce some commonly used functions. More information can be found in the [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/).

- createSelectFork: Specifies a network and block height to copy for testing. Must include the RPC for each chain in [foundry.toml](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/foundry.toml).
- deal: Sets the balance of a test wallet.
  - Set ETH balance:  `deal(address(this), 3 ether);`
  - Set Token balance: `deal(address(USDC), address(this), 1 * 1e18);`
- prank: Simulate the identity of a specified wallet. It is only effective for the next call and will set the msg.sender to the specified wallet address. Such as simulating a transfer from a whale wallet.
- startPrank: Simulate the identity of a specified wallet. It will set the msg.sender to the specified wallet address for all calls until `stopPrank()` is executed.
- label: Labels a wallet address for improved readability when using Foundry debug.
- roll: Adjusts the block height.
- warp: Adjusts the block timestamp.

Thanks for following along! Time to jump into the next lesson.

## Resources

[Foundry book](https://book.getfoundry.sh/)

[Awesome-foundry](https://github.com/crisgarner/awesome-foundry)

[Flashloan vs Flashswap](https://blog.infura.io/post/build-a-flash-loan-arbitrage-bot-on-infura-part-i)
