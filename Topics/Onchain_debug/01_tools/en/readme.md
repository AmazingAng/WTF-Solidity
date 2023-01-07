# OnChain Transaction Debugging: 1. Tools

Author: [SunSec](https://twitter.com/1nf0s3cpt)

Online resources were scarce when I started learning on-chain transaction analysis. Although slowly, l was able to piece together bits and pieces of information to perform tests and analysis.

From my studies, we will launch a series of Web3 security articles to entice more people to join Web3 security and create a secure network together.

In the first series, we will introduce how to conduct an on-chain analysis, and then we will reproduce on-chain attack(s). This skill will aid us in understanding the attack process, the root cause of the vulnerability, and even how the arbitrage robot arbitrages!

## Tools can greatly improve efficiency
Before getting into the analysis, allow me to introduce some common tools. The right tools can help you do research more efficiently.

### Transaction debugging tools
[Phalcon](https://phalcon.blocksec.com/) | [Tx.viewer](https://tx.eth.samczsun.com/) | [Cruise](https://cruise.supremacy.team/) | [Ethtx](https://ethtx.info/) | [Tenderly](https://dashboard.tenderly.co/explorer)

Transaction Viewer is the most commonly used tool, it is able to list the stack trace of function calls and the input data in each function during the transaction. Transaction viewer tools are all similar; the major difference is the chain support and auxiliary functions support. I personally use Phalcon and Sam’s Transaction Viewer. If I encounter unsupported chains, I will use Tenderly. Tenderly supports most chains, But the readability is limited, and analysis can be slow using its Debug feature. It is however one of the first tools I learned along with Ethtx.

#### Chain support comparison

Phalcon： `Ethereum、BSC、Cronos、Avalanche C-Chain、Polygon`

Sam's Transaction viewer： `Ethereum、Polygon、BSC、Avalanche C-Chain、Fantom、Arbitrum、Optimism`

Cruise： `Ethereum、BSC 、Polygon、Arbitrum、Fantom、Optimism、Avalanche、Celo、Gnosis`

Ethtx： `Ethereum、Goerli testnet`

Tendery： `Ethereum、Polygon、BSC、Sepolia、Goerli、Gnosis、POA、RSK、Avalanche C-Chain、Arbitrum、Optimism
、Fantom、Moonbeam、Moonriver`

#### Lab
We will look at JayPeggers - Insufficient validation + Reentrancy [Incident](https://github.com/SunWeb3Sec/DeFiHackLabs/#20221229---jay---insufficient-validation--reentrancy) as an example transaction [TXID](https://phalcon.blocksec.com/tx/eth/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6) to dissect.

First I use the Phalcon tool developed by Blocksec to illustrate. The basic information and balance changes of the transaction can be seen in the figure below. From the balance changes, we can quickly see how much profit the attacker has made. In this example, the attacker made a profit of 15.32 ETH.

![210571234-402d96aa-fe5e-4bc4-becc-190bd5a78e68-2](https://user-images.githubusercontent.com/107249780/210686382-cc02cc6a-b8ec-4cb7-ac19-402cd8ff86f6.png)

Invocation Flow Visualization - Is function invocation with trace-level information and event logs. It shows us the call invocation, the function call level of this transaction, whether flash loan is used, which projects are involved, which functions are called, and what parameters and raw data are brought in, etc.

![圖片](https://user-images.githubusercontent.com/52526645/210572053-eafdf62a-7ebe-4caa-a905-045e792add2b.png)

Phalcon 2.0 added funds flow, and Debug + source code analysis directly shows the source code, parameters, and return values along with the trace, which is more convenient for analysis.  

![image](https://user-images.githubusercontent.com/107249780/210821062-d1da8d1a-9615-4f1f-838d-34f27b9c3f41.png)

Now let's try Sam's Transaction Viewer on the same [TXID](https://tx.eth.samczsun.com/ethereum/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6). Sam integrates many tools in it, as shown in the picture below, you can see the change in Storage and the Gas consumed by each call.

![210574290-790f6129-aa82-4152-b3e1-d21820524a0a-2](https://user-images.githubusercontent.com/107249780/210686653-f964a682-d2a7-4b49-bafc-c9a2b0fa2c55.png)

Click Call on the left to decode the raw Input data.

![圖片](https://user-images.githubusercontent.com/52526645/210575619-89c8e8de-e2f9-4243-9646-0661b9483913.png)

Let's now switch to Tendery to analyze the same [TXID](https://dashboard.tenderly.co/tx/mainnet/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6), you can see the basic information like other tools. But using the Debug feature, it is not visualized and needs to be analyzed step by step. However, the advantage is that you can view the code and the conversion process of Input data while Debugging.

![圖片](https://user-images.githubusercontent.com/52526645/210577802-c455545c-80d7-4f35-974a-dadbe59c626e.png)

This can help us clarify all the things this transaction did. Before writing the POC, can we run a replay attack? Yes! Both Tendery or Phalcon support simulated transactions, you can find a button Re-Simulate in the upper right corner in the figure above. The tool will automatically fill the parameter values from the transaction for you as shown in the figure below. Parameters can be changed arbitrarily according to simulation needs, such as changing block number, From, Gas, Input data, etc.

![圖片](https://user-images.githubusercontent.com/52526645/210580340-f2abf864-e540-4881-8482-f28030e5e35b.png)

### Ethereum Signature Database

[4byte](https://www.4byte.directory/) | [sig.eth](https://sig.eth.samczsun.com/) | [etherface](https://www.etherface.io/hash)

In the Raw Input data, the first 4 bytes are Function Signatures. Sometimes if Etherscan or analysis tools cannot identify the function, we may check the possible Functions through the Signature Database.

The following example assumes that we do not know what Function `0xac9650d8` is

![圖片](https://user-images.githubusercontent.com/52526645/210582149-61a6d973-b458-432f-b586-250c94c3ae24.png)

Through a sig.eth query, we find that the 4 bytes signature is `multicall(bytes[])` 

![圖片](https://user-images.githubusercontent.com/52526645/210583416-c31bbe07-fa03-4701-880d-0ae485b171f7.png)

### Useful tools

[ABI to interface](https://gnidan.github.io/abi-to-sol/) | [Get ABI for unverified contracts](https://abi.w1nt3r.xyz/) | [ETH Calldata Decoder](https://apoorvlathey.com/eth-calldata-decoder/) | [ETHCMD - Guess ABI](https://www.ethcmd.com/)

ABI to interface: When developing POC, you need to call other contracts but you need an interface. We can use this tool to help you quickly generate the interfaces. Go to Etherscan to copy the ABI, and paste it on the tool to see the generated Interface. [Example](https://etherscan.io/address/0xb3da8d6da3ede239ccbf576ca0eaa74d86f0e9d3#code).

![圖片](https://user-images.githubusercontent.com/52526645/210587442-e7853d8b-0613-426e-8a27-d70c80e2a42d.png)
![圖片](https://user-images.githubusercontent.com/52526645/210587682-5fb07a01-2b21-41fa-9ed5-e7f45baa0b3e.png)

ETH Calldata Decoder: If you want to decode Input data without the ABI, this is the tool you need. Sam's transaction viewer I introduced earlier also supports Input data decoding. 

![圖片](https://user-images.githubusercontent.com/52526645/210585761-efd8b6f1-b901-485f-ae66-efaf9c84869c.png)

Obtain ABI for unverified contracts: If you encounter a contract that is not verified, you can use this tool to try to work out the function signatures. [Example](https://abi.w1nt3r.xyz/mainnet/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704)

![圖片](https://user-images.githubusercontent.com/52526645/210588945-701b0e22-7390-4539-9d2f-e13479b52824.png)

### Decompile tools
[Etherscan-decompile bytecode](https://etherscan.io/address/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704#code) | [Dedaub](https://library.dedaub.com/decompile) | [heimdall-rs](https://github.com/Jon-Becker/heimdall-rs)

Etherscan has a built-in decompilation feature, but the readability of the result is often poor. Personally, I often use Dedaub, which produces better decompiled code. It is my recommended decompiler. Let's use a MEV Bot being attacked as an example You can try to decompile it for yourself using this [contract](https://twitter.com/1nf0s3cpt/status/1577594615104172033).

First, copy the Bytecodes of the unverified contract and paste it on Dedaub, and click Decompile. 

![截圖 2023-01-05 上午10 33 15](https://user-images.githubusercontent.com/107249780/210688395-927c6126-b6c1-4c6d-a0c7-a3fea3db9cdb.png)

![圖片](https://user-images.githubusercontent.com/52526645/210591478-6fa928f3-455d-42b5-a1ac-6694f97386c2.png)

If you want to learn more, you can refer to the following videos.

## Resources
[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/

