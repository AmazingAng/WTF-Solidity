# OnChain Transaction Debugging: 6. Write Your Own PoC (Reentrancy)

Author: [gbaleeee](https://twitter.com/gbaleeeee)

社群 [Discord](https://discord.gg/Fjyngakf3h)

同步发表: XREX | [WTF Academy](https://github.com/AmazingAng/WTF-Solidity#%E9%93%BE%E4%B8%8A%E5%A8%81%E8%83%81%E5%88%86%E6%9E%90)


在本次教学中，我们将带你实际分析一个重入攻击事件，并逐步带你利用 Foundry 测试框架撰写代码，完成 Reproduce PoC。

## 在学习撰写 Reproduce PoC 之前，会需要具备的知识

1. 了解常见智能合约漏洞样态，可以参考 [DeFiVulnLabs](https://github.com/SunWeb3Sec/DeFiVulnLabs) 进行练习。
2. 了解 DeFi 基础建设如何运作，以及智能合约与智能合约之间如何互动。

## 重入攻击相关概念介绍

来自Consensys的一篇对重入攻击介绍的文章：[Reentrancy](https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/)

重入攻击是区块链世界中广泛存在一种攻击手法，在DeFiHackLabs库中搜索，你会发现几乎每月都会发生重入攻击的事件。同时有一个精彩的Github项目 [reentrancy-attacks](https://github.com/pcaversaccio/reentrancy-attacks)，专门收录现实中发生的重入攻击。  
对于重入攻击的攻击模式简单概括：当一个函数对另一个不受信任的合约进行外部调用时，重入攻击就有可能发生。

目前可以将重入攻击分为三种类型
1. 单函数重入 (Single Function Reentrancy)
2. 跨函数重入 (Cross-Function Reentrancy)
3. 跨合约重入 (Cross-Contract Reentrancy)

## 手把手撰写 PoC - 以 DFX Finance为例

- 信息来源  
  2022.11.11，根据Peckshield的 [推文](https://twitter.com/peckshield/status/1590831589004816384)，由于缺乏重入保护，DFX Finance的DEX池遭到攻击，损失约为$400万。其中一笔交易为 [TX](https://etherscan.io/tx/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7)

- 交易概览  
  根据这笔交易链接，我们能够在etherscan中观察到这笔交易的一些信息，但收获是有限的，只有交易的sender，调用的合约，代币转移过程中发出的事件等。不过值得注意的是，这笔交易被打上了MEV Transaction和Flashbots 的标签，这是攻击为避免自己的攻击交易被front-run机器人抢跑所采取的措施。  
  
  ![image](https://user-images.githubusercontent.com/53768199/215320542-a7798698-3fd4-4acf-90bf-263d37379795.png)  
  
  
- 交易分析  
  为了进一步分析这起攻击交易，可以使用BlockSec Team的 [Phalcon](https://phalcon.blocksec.com/tx/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7) 分析工具进行研究。  
  
  
  
- Balance 分析  
  在Balance Changes一栏我们可以看到这笔交易所带来的资金变化，被标记为receiver即攻击合约收获了大量的USDC，XIDR代币，命名为dfx-xidr-v2的合约损失了大量的USDC,XIDR代币，同时0x27e8开头的地址也收获了一些USDC,XIDR的代币，根据对这个地址的调查，我们可以知道，这个地址为DFX Finance项目的多签钱包地址。
  
  ![image](https://user-images.githubusercontent.com/53768199/215320922-72207a7f-cfac-457d-b69e-3fddc043206b.png)  
  
  通过对Balance Changes中的资金变化可以知道，这次攻击交易是攻击者对DFX Finance的dfx-xidr-v2合约进行了攻击，窃取了USDC,XIDR代币。对于多签钱包地址在攻击的过程中也收到了部分USDC,XIDR代币这一变化，根据经验分析，这往往是合约功能交互过程中收取手续费所造成的。  
  
- 资金流向  
  在对攻击交易的进一步分析之前，我们可以通过BlockSec Team的另一个工具 [metasleuth](https://metasleuth.io/result/eth/0x6bfd9e286e37061ed279e4f139fbc03c8bd707a2cdd15f7260549052cbba79b7)来分析这笔攻击交易中的资金流动，帮助我们观察其中的代币转移情况。
  ![image](https://user-images.githubusercontent.com/53768199/215321213-7ead5043-1410-4ab6-b247-1e710d931fe8.png)
  根据图中的信息，被标记为exploiter的地址先在1，2步操作中从被攻击的合约中借出大量USDC，XIDR代币，随后在3，4步操作中将USDC,XIDR代币发送回给被攻击合约，随后，名为dfx-xidr-v2的代币从0地址被铸造给攻击者，标记为DFX Finance的多签钱包地址也收到了USDC,XIDR代币。最后dfx-xidr-v2代币又发送给0地址销毁。  
  可以总结出攻击过程中的代币流向是  
  
  1.从被攻击合约中取出代币USDC,XIDR  
  2.将USDC,XIDR代币发送给被攻击合约  
  3.攻击者铸造名为dfx-xidr-v2的代币  
  4.多签钱包地址收到代币USDC,XIDR  
  5.攻击者销毁名为dfx-xidr-v2的代币  
  
  这些信息可以在接下来的Call Trace分析环节中进行分析与验证  
  
- Trace分析  
  在展开级别为2的情况下，对这笔交易的函数调用过程进行观察  
  
  ![image](https://user-images.githubusercontent.com/53768199/215321768-6aa93999-9a77-4af5-b758-dd91f7dc3973.png)  
  
  可以看出整个攻击交易中的函数执行流程为：  
  1.攻击者调用攻击合约中函数选择器Hash为0xb727281f的函数，在这个函数中执行攻击流程  
  2.staticcall调用dfx-xidr-v2合约中的viewDeposit函数  
  3.call调用dfx-xidr-v2合约中的flash函数，值得注意的是在这个函数调用内完成了对攻击合约中的一次函数选择器Hash为0xc3924ed6的回调操作  

  ![image](https://user-images.githubusercontent.com/53768199/215322039-59a46e1f-c8c5-449f-9cdd-5bebbdf28796.png)  
  
  4.call调用dfx-xidr-v2合约中的withdraw函数


- 详细分析  
  对于攻击者第一步调用viewDeposit函数的意图，可以通过viewDeposit Function的代码实现以及注释获得，攻击者希望获取存入200_000 * 1e18个稳定币(DFX Finance中为dfx-xidr-v2代币)所需要的两种代币的数量。  
  
  ![image](https://user-images.githubusercontent.com/53768199/215324532-b441691f-dae4-4bb2-aadb-7bd93d284270.png)  
  
  可以在下一步攻击者调用合约中的flash函数中观察到，攻击者将调用viewDeposit函数的返回值的相近值作为参数传入(不等原因后面解释)
  
  ![image](https://user-images.githubusercontent.com/53768199/215329296-97b6af11-32aa-4d0a-a7c4-019f355be04d.png)
  
  对于攻击者第二步调用被攻击合约flash函数，我们通过它的代码实现来了解其作用  
  
  ![image](https://user-images.githubusercontent.com/53768199/215329457-3a48399c-e2e1-43a8-ab63-a89375fbc239.png)  
  
  可以看出，flash函数是类似于Uniswap v2中闪电贷功能的实现，用户可以通过这个函数从合约中闪电贷出资金。同时可以看到，flash函数中存在一处对调用者的函数回调操作，对应代码为
  ```solidity
  IFlashCallback(msg.sender).flashCallback(fee0, fee1, data);
  ```
  这处代码的外部调用对应着之前Call Trace图中对于攻击合约的函数回调，可以通过计算这个函数的4Bytes Hash进行验证，正是0xc3924ed6 
  ![image](https://user-images.githubusercontent.com/53768199/215329899-a6f2cc00-f2ac-49c8-b4df-38bb24663f37.png)  
  
  ![image](https://user-images.githubusercontent.com/53768199/215329919-bbeb557d-41d0-47fb-bdf8-321e5217854e.png)  
  
  对于最后一步调用函数withdraw，根据被攻击合约中函数的实现代码以及注释可以看出，是完成了销毁稳定币，取回对应的两种代币的操作
  
  ![image](https://user-images.githubusercontent.com/53768199/215330132-7b54bf35-3787-495a-992d-ac2bcabb97d9.png)  
    
  
- POC撰写
  这时，我们能够写出POC代码的主要框架
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
  此时，很容易产生这样的疑问，攻击者是如何在只进行了闪电贷的情况下，调用了合约中的withdraw函数，将合约中的资金盗走？显而易见的，目前攻击者唯一能操作的地方，只有闪电贷过程中所执行的Callback回调，对其展开进行分析
  
  ![image](https://user-images.githubusercontent.com/53768199/215330695-1b1fa612-4f01-4c6a-a5be-7324f464ecb1.png)
  
  可以看见，攻击者正是在这一步调用了被攻击合约中的deposit函数，分析其代码及注释，可以看出它完成了一个发送铸造稳定币所需资产代币给合约后获取curves代币的操作，结合上图中USDC，XIDR的transferFrom函数调用，可知是将USDC，XIDR代币发送给了被攻击合约。  
  
  ![image](https://user-images.githubusercontent.com/53768199/215330576-d15642f7-5819-4e83-a8c8-1d3a48ad8c6d.png)
  
  此时，结合flash函数中对于闪电贷是否能够完成的判断语句代码，可知它是通过检查合约中对应的代币资产在闪电贷回调执行后是否大于等于执行之前来判定的，deposit函数执行流程中的USDC,XIDR代币发送操作正好满足了这一要求。
  ```solidity
  require(balance0Before.add(fee0) <= balance0After, 'Curve/insufficient-token0-returned');
  require(balance1Before.add(fee1) <= balance1After, 'Curve/insufficient-token1-returned');
  ```
  值得注意的是，为了满足flash函数中对于手续费收取的相关要求，攻击者存入的USDC,XIDR代币数量略高于之前从flash函数中闪电贷所得，多出的这一部分代币将在flash函数中的后续执行操作中，发送给DFX Finance的多签钱包。攻击者在发起这次攻击之前准备了一些USDC,XIDR代币作为flash手续费，通过deposit函数发送给被攻击合约的数量为flash闪电贷出的代币加上手续费代币之和，这样在完成deposit操作的同时也能够完成flash函数中的检查。
  如此，攻击者通过在闪电贷的回调函数中对被攻击合约的deposit操作，满足了闪电贷的检查条件，同时还在被攻击合约中记录为deposit后的状态，可以在后一步操作中进行withdraw操作取出代币。  
 
  对整个攻击流程进行梳理，它的步骤为  
  1.提前准备一些USDC,XIDR代币
  2.调用viewDeposit函数，获取后续deposit操作所需要的代币数量   
  3.根据上一步获取的数值，调用被攻击合约的flash函数获取USDC,XIDR代币  
  4.在flash函数中的回调中，调用被攻击合约的deposit函数，将USDC,XIDR代币发送回给被攻击合约，完成重入  
  5.由于上一步进行了deposit操作，直接调用被攻击合约的withdraw函数取走代币  

  完成整个POC代码：  
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
  
  更为详细完整的代码在DefiHackLabs库中：[DFX_exp.sol](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/DFX_exp.sol)
  
- 验证Fund flow  
  这时，我们可以通过攻击交易中代币发出的事件来对之前资金流动图进行验证
  
  ![image](https://user-images.githubusercontent.com/53768199/215331469-e1edd9b4-5147-4f82-9e38-64edce3cc91f.png)

  deposit函数执行过程中最后发出的事件验证之前dfx-xidr-v2的代币从0地址被铸造给攻击者
  
  ![image](https://user-images.githubusercontent.com/53768199/215331545-9730e5b0-564d-45d8-b169-3b7c8651962f.png)

  flash函数执行过程中最后USDC，XIDR的转移事件(闪电贷手续费收取)对应DFX Finance多签钱包收到一些USDC,XIDR代币
  
  ![image](https://user-images.githubusercontent.com/53768199/215331819-d80a1775-4056-4ddd-9083-6f5241d07213.png)

  withdraw函数执行过程中最后发出的事件对应之前dfx-xidr-v2代币发送给0地址销毁
  
- 总结  
  DFX Finance的重入攻击事件是一起典型的cross-function重入攻击，攻击者通过在falsh函数的回调操作中调用deposit函数完成了重入。值得一提的是，这次攻击的手法，正好对应了CTF damnvulnerabledefi中的第四题 [Side Entrance](https://www.damnvulnerabledefi.xyz/challenges/side-entrance/)，如果项目的开发人员之前有认真做过，或许这次攻击事件就不会发生🤣。在同年的12月中，[Deforst](https://github.com/SunWeb3Sec/DeFiHackLabs#20221223---defrost---reentrancy) 项目也被同样的手法所攻击。
  
## 学习资源  
[Reentrancy Attacks on Smart Contracts Distilled](https://blog.pessimistic.io/reentrancy-attacks-on-smart-contracts-distilled-7fed3b04f4b6)  
[C.R.E.A.M. Finance Post Mortem: AMP Exploit](https://medium.com/cream-finance/c-r-e-a-m-finance-post-mortem-amp-exploit-6ceb20a630c5)  
[Cross-Contract Reentrancy Attack](https://inspexco.medium.com/cross-contract-reentrancy-attack-402d27a02a15)  
[Sherlock Yield Strategy Bug Bounty Post-Mortem](https://mirror.xyz/0xE400820f3D60d77a3EC8018d44366ed0d334f93C/LOZF1YBcH1eBdxlC6HP223cAMeTpNgQ-Kc4EjQuxmGA)  
[Decoding $220K Read-only Reentrancy Exploit | QuillAudits](https://quillaudits.medium.com/decoding-220k-read-only-reentrancy-exploit-quillaudits-30871d728ad5)  


  

  
  
  
  


  




