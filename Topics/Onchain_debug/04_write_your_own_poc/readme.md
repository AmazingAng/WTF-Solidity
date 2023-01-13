# OnChain Transaction Debugging: 4. Write your own POC - MEV Bot

Author: [Sun](https://twitter.com/1nf0s3cpt)

## 手把手撰写 PoC - 以 MEV Bot (BNB48) 为例
- 前情提要
    - 20220913 有一个 MEV Bot 被攻击者发现漏洞进而将合约上的资产都转走，共损失约 $140K.

    - 攻击者透过 BNB48 验证节点发送隐私交易，类似于 Flashbot 不把交易放入公开 mempool 避免被抢跑攻击.
    
- 分析
    - 攻击者发动攻击的 [TXID](https://bscscan.com/tx/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2)，MEV Bot合约未开源，如何利用的?
    - 透过 [phalcon](https://phalcon.blocksec.com/tx/bsc/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2) 来分析看看，从金流的部分可到这笔交易将 MEV bot 转移了 6 种资产到攻击者钱包上，如何利用的?
![图片](https://user-images.githubusercontent.com/52526645/211201079-e7c5cc3b-64f8-4146-ab0e-7dd46b535cc9.png)
    - 再来换看看 Function call 调用流程，看到刚好也调用了 6 次 `pancakeCall` 函式.
        - From: `0xee286554f8b315f0560a15b6f085ddad616d0601`
        - 攻击者合约: `0x5cb11ce550a2e6c24ebfc8df86c5757b596e69c1`
        - MEV Bot合约: `0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d`
 ![图片](https://user-images.githubusercontent.com/52526645/211201456-8b6f7bca-677d-40a2-b81b-fd6af18f94fd.png)
    - 我们展开其中一个 `pancakeCall` 看看，可以看到回调到攻击者的合约读取了 token0()的值为 BSC-USD，紧接者就进行 transfer BSC-USD 到攻击者的钱包，看到这边可以知道攻击者可能有权限或透过漏洞把 MEV Bot 合约上的资产都搬走，接下来就要找出攻击者是怎么利用的?
    ![图片](https://user-images.githubusercontent.com/52526645/211201744-9895803a-5f72-4f14-b147-b67b204bee75.png)
    - 因为前面有提到 MEV Bot 合约未开源，所以这边我们可以使用[第一课](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools)介绍的反编译工具 [Dedaub](https://library.dedaub.com/decompile)，来分析看看可不可以发现到什么. 首先先到 [Bscscan](https://bscscan.com/address/0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d#code) 上把合约 bytecodes 贴到 Dedaub 反编译，如下图我们可以看到 `pancakeCall` 函式权限设定为 public，就是公开每个人都可以调用，在闪电贷的回调公开是很正常应该没太大问题，但是可以看到红色框起来的地方，执行了一个 `0x10a` 函示，再往下追看看.
    ![图片](https://user-images.githubusercontent.com/52526645/211202573-b4a4847d-a617-42c8-84d0-0f2dbd38a632.png)
   - `0x10a` 函示逻辑如下图，可以看到关键看到红色框起来的地方，先读取攻击者合约上的 token0 是什么代币然后带入转帐函式 `transfer`，在函式中第一个参数接收者地址 `address(MEM[varg0.data])` 是在 `pancakeCall` 的 `varg3 (_data)` 可被控制的，所以关键漏洞问题就在这边.
   
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204177-fbebe377-23b0-4b0c-bb3e-dcb64dba2afc.png" alt="Cover" width="80%"/>
</div>

   - 再来回头看看攻击者呼叫 `pancakeCall`的 payload，`_data` 带入的前 32 bytes 就是收款方的钱包地址.

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211453390-502db65b-cf82-4805-a463-04fc5c7e0dce.png" alt="Cover" width="80%"/>
</div>

- 开发 POC
    - 通过以上分析攻击流程后，开发 POC 的合约的逻辑就是呼叫 MEV bot 合约的 `pancakeCall` 然后带入对应的参数，关键是 `_data` 指定收款钱包地址，再来是合约中要有 token0，token1 函式来满足合约逻辑. 自己可以动手写写看. 
    - 解答: [POC](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/BNB48MEVBot_exp.sol) 参考.
    
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204852-4fa65835-17f7-4c91-80ab-79f5b46125df.png" alt="Cover" width="80%"/>
</div>

## 延伸学习
- Foundry trace
    - 使用 Foundry 也可以列出该笔交易的 function traces，使用方式如下:
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211562868-12fde773-948c-47a9-acaf-6f744438925e.png" alt="Cover" width="80%"/>
</div>

- Foundry debug
    - 也可以使用 Foundry 来 debug transaction，使用方式如下:  
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --debug  --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211565713-fdf3784f-da54-42e8-ad60-591ecac38c15.png" alt="Cover" width="80%"/>
</div>

## 学习资源

[Flashbots: Kings of The Mempool](https://noxx.substack.com/p/flashbots-kings-of-the-mempool?utm_source=profile&utm_medium=reader2)

[MEV Markets Part 1: Proof of Work](https://mirror.xyz/0xshittrader.eth/WiV8DM3I6abNMVsXf-DqioYb2NglnfjmM-zSsw2ruG8)

[MEV Markets Part 2: Proof of Stake](https://mirror.xyz/0xshittrader.eth/c6J_PCK87K3joTWmLEtG6qVN6BFXLBZxQniReYSEjLI)

[MEV Markets Part 3: Payment for Order Flow](https://mirror.xyz/0xshittrader.eth/f2VSuoZ91vAbCv82MtWM-Gosyf_DeUXfPlDx3EYV3RM)

[Ethers极简入门: 25. Flashbots](https://github.com/WTFAcademy/WTF-Ethers/tree/main/25_Flashbots)
