# OnChain Transaction Debugging: 6. Write Your Own PoC (Reentrancy)

Author: [gbaleeee](https://twitter.com/gbaleeeee)

Translation: [Spark](https://twitter.com/SparkToday00)

In this article, we will learn reentrancy by demonstrating a real-world attack and using Foundry to conduct tests and reproduce the attack.

## Prerequisite
1. Understand common attack vectors in the smart contract. [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs) is a great resource to get started.
2. Know how the basic Defi model work and how smart contracts interact with others.

## What Is Reentrancy Attack

Source from: [Reentrancy](https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/) by Consensys.

Reentrancy Attack is a popular attack vector. It almost happens every month if we look into the [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs) database. For more information, there is another great repo that maintains a collection of [reentrancy-attacks](https://github.com/pcaversaccio/reentrancy-attacks),

In short, if one function invokes an untrusted external call, there could be a risk of the reentrancy attack.

Reentrancy Attacks can be mainly identified into three types:
1. Single Function Reentrancy
2. Cross-Function Reentrancy
3. Cross-Contract Reentrancy


## Hands-on PoC - DFX Finance

- Source：[Pckshield alert 11/11/2022](https://twitter.com/peckshield/status/1590831589004816384)
  > It seems @DFXFinance's DEX pool (named Curve) is hacked (w/ loss of 3000 ETH or $~4M) due to the lack of proper reentrancy protection. Here comes an example tx: https://etherscan.io/tx/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7. The stolen funds are being deposited into @TornadoCash

- Transaction Overview

  Based on the transaction above, we can observe limited info from etherscan. It includes information about the sender (exploiter), the exploiter's contract, events during the transaction, etc. The transaction is labeled as an "MEV Transaction" and "Flashbots," indicating that the exploiter attempted to evade the impact of front-run bots.
  
  ![image](https://user-images.githubusercontent.com/53768199/215320542-a7798698-3fd4-4acf-90bf-263d37379795.png)  
  
- Transaction Analysis
  We can use [Phalcon from Blocksec](https://phalcon.blocksec.com/tx/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7) to do the further investigation.

- Balance Analysis
  In the *Balance Changes* section, we can see the alteration in funds with this transaction. The attack contract(receiver) collected a large amount of `USDC`, and `XIDR` tokens as profit, and the contract named `dfx-xidr-v2` lost a large amount of `USDC` and `XIDR` tokens. At the same time, the address starting with `0x27e8` also obtained some `USDC` and `XIDR` tokens. According to the investigation of this address, this is the DFX Finance: Governance Multi-Signature wallet address.

  ![image](https://user-images.githubusercontent.com/53768199/215320922-72207a7f-cfac-457d-b69e-3fddc043206b.png)  

  Based on the aforementioned observations, the victim is DFX Finance's `dfx-xidr-v2` contract and loss assets are `USDC` and `XIDR` tokens. The DFX multi-signature address also receives some tokens during the process. Based on our experience, it should relate to the fee logic.

- Asset Stream Analysis
  We can use another tool from Blocksec called [metasleuth](https://metasleuth.io/result/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7) to analyze the asset flow.

  ![image](https://user-images.githubusercontent.com/53768199/215321213-7ead5043-1410-4ab6-b247-1e710d931fe8.png)

  Based on the graph above, the exploiter borrowed a large amount of `USDC`，`XIDR` tokens from the victim contract in step [1] and [2]. In step [3] and [4], the borrowed assets were sent back to the victim contract. After that, `dfx-xidr-v2` token are minted to the exploiter in step [5] and the DFX multi-sig wallet receives the fee in both  `USDC` and `XIDR` in step [6] and [7]. In the end, `dfx-xidr-v2` tokens are burned from the exploiter's address.

  As a summary, the asset stream is:
  1. The attacker borrowed `USDC`，`XIDR` tokens from the victim contract.
  2. The attacker sent the `USDC`，`XIDR` tokens back to the victim contract.
  3. The attacker minted `dfx-xidr-v2` tokens.
  4. DFX multi-sig wallet received `USDC`，`XIDR` tokens.
  5. The attacker burned `dfx-xidr-v2` tokens.

  This information can be verified with the following trace analysis.

- Trace Analysis

  Let's observe the transaction under expand level 2.

  ![image](https://user-images.githubusercontent.com/53768199/215321768-6aa93999-9a77-4af5-b758-dd91f7dc3973.png) 

  The complete attack transaction's function execution flow can be viewed as:

  1. The attacker invoked function `0xb727281f` for the attack.
  2. The attacker called `viewDeposit` in `dfx-xidr-v2` contract via `staticcall`.
  3. The attacker triggered `flash` function in `dfx-xidr-v2` contract with `call`. It is worth noting that in this trace, the function `0xc3924ed6` in the attack contract was used as a callback.

  ![image](https://user-images.githubusercontent.com/53768199/215322039-59a46e1f-c8c5-449f-9cdd-5bebbdf28796.png) 

  4. The attacker called `withdraw` function in `dfx-xidr-v2` contract.

- Detail Analysis

  The attacker's intention of calling the viewDeposit function in the first step can be found in the comment for `viewDeposit` function. The exploiter wants to obtain the number of `USDC`，`XIDR` tokens to mint 200_000 * 1e18 `dfx-xidr-v2` token.

  ![image](https://user-images.githubusercontent.com/53768199/215324532-b441691f-dae4-4bb2-aadb-7bd93d284270.png)  

  And at the next step attack using the return value from `viewDeposit` function as a similar value for the input of `flash` function invocation(the value is not exactly the same, more details later)
  
  ![image](https://user-images.githubusercontent.com/53768199/215329296-97b6af11-32aa-4d0a-a7c4-019f355be04d.png)

  The attacker invokes `flash` function in the victim contract as the second step. We can get some insight from the code:
  
  ![image](https://user-images.githubusercontent.com/53768199/215329457-3a48399c-e2e1-43a8-ab63-a89375fbc239.png)  

  As you can see, the `flash` function is similar to the flash loan in Uniswap V2. User can borrow assets via this function. And the `flash` function has a callback function for the user. The code is:
  ```solidity
  IFlashCallback(msg.sender).flashCallback(fee0, fee1, data);
  ```
  This invocation corresponds to the callback function in the attacker's contract in the previous trace analysis section. If we do the 4Bytes Hash verification, it is `0xc3924ed6` 

  ![image](https://user-images.githubusercontent.com/53768199/215329899-a6f2cc00-f2ac-49c8-b4df-38bb24663f37.png)  
  
  ![image](https://user-images.githubusercontent.com/53768199/215329919-bbeb557d-41d0-47fb-bdf8-321e5217854e.png)  
  
  The last step is calling `withdraw` function, and it will burn the stable token(`dfx-xidr-v2`) and withdraw paired assets(`USDC`，`XIDR`).

  ![image](https://user-images.githubusercontent.com/53768199/215330132-7b54bf35-3787-495a-992d-ac2bcabb97d9.png)  
  
- POC Implementation

  Based on the analysis above we can implement the PoC skeleton below:

  ```solidity
  contract EXP {
      uint256 amount;
      function testExploit() public{
        uint[] memory XIDR_USDC = new uint[](2);
        XIDR_USDC[0] = 0;
        XIDR_USDC[1] = 0;
        ( , XIDR_USDC) = dfx.viewDeposit(200_000 * 1e18);
        dfx.flash(address(this), XIDR_USDC[0] * 995 / 1000, XIDR_USDC[1] * 995 / 1000, new bytes(1)); // 5% fee
        dfx.withdraw(amount, block.timestamp + 60);
    }
  
    function flashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external{
        /*
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        */
    }
  }
  ```
  It is likely to raise the question of how an attacker steals assets with `withdraw` function in a flash loan. Obviously, this is the only part the attacker can work on. Now let's dive into the callback function: 
  
  ![image](https://user-images.githubusercontent.com/53768199/215330695-1b1fa612-4f01-4c6a-a5be-7324f464ecb1.png)

  As you can see, the attacker called `deposit` function in the victim contract and it will receive the numeraire assets that the pool supports and mint curves token. As mentioned in the graph above, `USDC` and `XIDR` are sent to the victim via `transferFrom`.
  
  ![image](https://user-images.githubusercontent.com/53768199/215330576-d15642f7-5819-4e83-a8c8-1d3a48ad8c6d.png)
  
  At this point, it is known that the completion of the flash loan is determined by checking whether the corresponding token assets in the contract are greater than or equal to the state before the execution of the flash loan callback. And `depoit` function will make this validation complete.

  ```solidity
  require(balance0Before.add(fee0) <= balance0After, 'Curve/insufficient-token0-returned');
  require(balance1Before.add(fee1) <= balance1After, 'Curve/insufficient-token1-returned');
  ```

  It should be noticed that the attacker prepared some `USDC` and `XIDR` tokens for the flash loan fee mechanism before the attack. This is why the attacker's deposit is relatively higher than the borrowed amount. So the total amount for `deposit` invocation is the amount borrowed with flash loan plus the fee. The validation in the `flash` function can be passed with this.

  As a result, the attacker invoked `deposit` in the callback function, bypassed the validation in the flash loan and left the record for deposit. After all these operations, attacker withdrew tokens.

  In summary, the whole attack flow is:
  1. Prepare some `USDC` and `XIDR` tokens in advance.
  2. Using `viewDeposit()` to get the number of assets for later `deposit()`.
  3. Flash `USDC` and `XIDR` tokens based on the return value in step 2.
  4. Invoke `deposit()` function in the flash loan callback .
  5. Since we have a deposit record in the previous step, now withdraw tokens.
  


  The full PoC implementation：  
  ```solidity
  contract EXP {
      uint256 amount;
      function testExploit() public{
        uint[] memory XIDR_USDC = new uint[](2);
        XIDR_USDC[0] = 0;
        XIDR_USDC[1] = 0;
        ( , XIDR_USDC) = dfx.viewDeposit(200_000 * 1e18);
        dfx.flash(address(this), XIDR_USDC[0] * 995 / 1000, XIDR_USDC[1] * 995 / 1000, new bytes(1)); // 5% fee
        dfx.withdraw(amount, block.timestamp + 60);
    }

      function flashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external{
        (amount, ) = dfx.deposit(200_000 * 1e18, block.timestamp + 60);
    }
  }
  ```

  More detailed codebase can be found in the DefiHackLabs repo： [DFX_exp.sol](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/DFX_exp.sol)

- Verify Fund Flow  
  
  Now, we can verify the asset stream graph with token events during the transaction.
  
  ![image](https://user-images.githubusercontent.com/53768199/215331469-e1edd9b4-5147-4f82-9e38-64edce3cc91f.png)


  At the end of the `deposit` function, `dfx-xidr-v2` tokens were minted to the exploiter. 

  ![image](https://user-images.githubusercontent.com/53768199/215331545-9730e5b0-564d-45d8-b169-3b7c8651962f.png)

  In the `flash` function, the transfer event shows the fee collection(`USDC` and `XIDR`) for the DFX multi-sig wallet.

  ![image](https://user-images.githubusercontent.com/53768199/215331819-d80a1775-4056-4ddd-9083-6f5241d07213.png)

  The `withdraw` function burned `dfx-xidr-v2` tokens that were minted in the previous steps.

- Summary

  DFX Finance reentrancy attack is a typical cross-function reentrancy attack, where the attacker completes the reentrancy by calling the `deposit` function in the flash loan callback function. 
  
  It is worth mentioning that the technique of this attack corresponds exactly to the fourth question in CTF damnvulnerabledefi [Side Entrance. If the project developers had done it carefully before, perhaps this attack would not have happened 🤣. In December of the same year, the [Deforst](https://github.com/SunWeb3Sec/DeFiHackLabs#20221223---defrost---reentrancy) project was also attacked due to a similar issue.



## Learning Material
[Reentrancy Attacks on Smart Contracts Distilled](https://blog.pessimistic.io/reentrancy-attacks-on-smart-contracts-distilled-7fed3b04f4b6)  
[C.R.E.A.M. Finance Post Mortem: AMP Exploit](https://medium.com/cream-finance/c-r-e-a-m-finance-post-mortem-amp-exploit-6ceb20a630c5)  
[Cross-Contract Reentrancy Attack](https://inspexco.medium.com/cross-contract-reentrancy-attack-402d27a02a15)  
[Sherlock Yield Strategy Bug Bounty Post-Mortem](https://mirror.xyz/0xE400820f3D60d77a3EC8018d44366ed0d334f93C/LOZF1YBcH1eBdxlC6HP223cAMeTpNgQ-Kc4EjQuxmGA)  
[Decoding $220K Read-only Reentrancy Exploit | QuillAudits](https://quillaudits.medium.com/decoding-220k-read-only-reentrancy-exploit-quillaudits-30871d728ad5)  
