# OnChain Transaction Debugging: 4. Write your own POC - MEV Bot

Author: [Sun](https://twitter.com/1nf0s3cpt)

## Write PoC step by step - Take MEV Bot (BNB48) as an example

- Recap
    - On 20220913 A MEV Bot was exploited by an attacker and all the assets on the contract were transferred away, with a total loss of about $140K.
    - The attacker sends a private transaction through the BNB48 validator node, similar to Flashbot not putting the transaction into the public mempool to avoid being Front-running.
- Analysis
    - Attacker's [TXID](https://bscscan.com/tx/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2)，We can see that the MEV Bot contract was unverify which was not open source，How did the attacker exploit it?
    - Using [phalcon](https://phalcon.blocksec.com/tx/bsc/0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2) to check，from the part of funs flow within this transaction, MEV bot transferred 6 kinds of assets to the attacker’s wallet, How did the attacker exploit it?
![圖片](https://user-images.githubusercontent.com/52526645/211201079-e7c5cc3b-64f8-4146-ab0e-7dd46b535cc9.png)
    - Let’s look at the invocation process of Function call, and see that the `pancakeCall` function wss called exactly 6 times.
        - From: `0xee286554f8b315f0560a15b6f085ddad616d0601`
        - Attacker's contract: `0x5cb11ce550a2e6c24ebfc8df86c5757b596e69c1`
        - MEV Bot contract: `0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d`
 ![圖片](https://user-images.githubusercontent.com/52526645/211201456-8b6f7bca-677d-40a2-b81b-fd6af18f94fd.png)
    - Let's expand one of the `pancakeCall` to see, we can see that the callback to the attacker's contract reads the value of token0() as BSC-USD, and then transfers BSC-USD to the attacker's wallet, see this While we can know that the attacker may have the permission or use a vulnerability to move all the assets on the MEV Bot contract, the next step we need to find out how the attacker uses it?
    ![圖片](https://user-images.githubusercontent.com/52526645/211201744-9895803a-5f72-4f14-b147-b67b204bee75.png)
    - Because it was mentioned earlier that the MEV Bot contract is not open source, so here we can use [Lesson 1](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main/academy/onchain_debug/01_tools)introduced decompiler tool [Dedaub](https://library.dedaub.com/decompile), Let's analyze and see if we can find something. First copy the bytecodes of the contract from [Bscscan](https://bscscan.com/address/0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d#code) and paste to Dedaub to decompile it, As shown in the figure below, we can see that `pancakeCall` function permission is set to public, and everyone can call it. It is normal and should not be a big problem in the callback of Flash Loan, but you can see the red framed place, execute a `0x10a` function, and then let's look down.
    ![圖片](https://user-images.githubusercontent.com/52526645/211202573-b4a4847d-a617-42c8-84d0-0f2dbd38a632.png)
   - The logic of `0x10a` function is as shown in the figure below. You can see the key point in the red framed place. First read what token is in token0 on the attacker’s contract and then bring it into the transfer function `transfer`. In the function, the first parameter receiver address `address(MEM[varg0.data])` is in `pancakeCall` `varg3 (_data)` which can be controlled, so the key vulnerability problem is here.
          
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204177-fbebe377-23b0-4b0c-bb3e-dcb64dba2afc.png" alt="Cover" width="80%"/>
</div>

   - Looking back at the payload of the attacker calling `pancakeCall`, the first 32 bytes of the input value in `_data` is the wallet address of the payee.

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211453390-502db65b-cf82-4805-a463-04fc5c7e0dce.png" alt="Cover" width="80%"/>
</div>

- Writing POC
   - After analyzing the attack process above, the logic of writing the POC is to call the `pancakeCall` of the MEV bot contract and then bring in the corresponding parameters. The key is `_data` to specify the receiving wallet address, and then the contract must have token0, token1 Function to satisfy the contract logic. You can try to write it yourself.
    - Answer: [POC](https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/BNB48MEVBot_exp.sol).
    
<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211204852-4fa65835-17f7-4c91-80ab-79f5b46125df.png" alt="Cover" width="80%"/>
</div>

## Extended learning
- Foundry trace
    - The function traces of the transaction can also be listed using Foundry, as follows:
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211562868-12fde773-948c-47a9-acaf-6f744438925e.png" alt="Cover" width="80%"/>
</div>

- Foundry debug
    - You can also use Foundry to debug transaction, as follows:
    
    `cast run 0xd48758ef48d113b78a09f7b8c7cd663ad79e9965852e872fdfc92234c3e598d2 --quick --debug  --rpc-url https://rpc.ankr.com/bsc`

<div align=center>
<img src="https://user-images.githubusercontent.com/52526645/211565713-fdf3784f-da54-42e8-ad60-591ecac38c15.png" alt="Cover" width="80%"/>
</div>

## Resources

[Flashbots: Kings of The Mempool](https://noxx.substack.com/p/flashbots-kings-of-the-mempool?utm_source=profile&utm_medium=reader2)

[MEV Markets Part 1: Proof of Work](https://mirror.xyz/0xshittrader.eth/WiV8DM3I6abNMVsXf-DqioYb2NglnfjmM-zSsw2ruG8)

[MEV Markets Part 2: Proof of Stake](https://mirror.xyz/0xshittrader.eth/c6J_PCK87K3joTWmLEtG6qVN6BFXLBZxQniReYSEjLI)

[MEV Markets Part 3: Payment for Order Flow](https://mirror.xyz/0xshittrader.eth/f2VSuoZ91vAbCv82MtWM-Gosyf_DeUXfPlDx3EYV3RM)
