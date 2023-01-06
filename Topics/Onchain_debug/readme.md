# OnChain Transaction Debugging: 1. Tools

Author: [SunSec](https://twitter.com/1nf0s3cpt)

当初我在学习链上交易分析时，很少相关教学文章，只能自己慢慢地收集资料从中挖掘如何分析到测试。我们将推出一系列 Web3 安全的教学文章, 帮助更多人加入 Web3 安全，共创安全网路。

第一个系列我们将介绍如何进行链上分析到撰写攻击重现。此技能将能帮助你分析攻击过程和漏洞原因甚至套利机器人如何套利！

## 工欲善其事，必先利其器
在进入分析之前，我先介绍一些常用工具，正确的工具可以帮助你做研究时更有效率。
### Transaction debugging tools
[Phalcon](https://phalcon.blocksec.com/) | [Tx.viewer](https://tx.eth.samczsun.com/) | [Cruise](https://cruise.supremacy.team/) | [Ethtx](https://ethtx.info/) | [Tenderly](https://dashboard.tenderly.co/explorer)

Transaction Viewer 这类工具是最常用的，可以帮助我们针对想要分析的交易 Transaction，以可视化列出函数呼叫的流程以及每个函数带入了什么的参数等。
每个工具大同小异，只差异在链的支援度不同和辅助功能，我个人是比较常用 Phalcon 和 Sam 的 Transaction Viewer，如果遇到不支援的链则会使用 Tenderly，Tenderly 支援最多链，但是可读性就不是这么方便，需要 Debug 慢慢分析。不过我最初在研究链上分析是先学习 Ethtx 和 Tenderly。

#### 链支援度比较

Phalcon： `Ethereum、BSC、Cronos、Avalanche C-Chain、Polygon`

Sam's Transaction viewer： `Ethereum、Polygon、BSC、Avalanche C-Chain、Fantom、Arbitrum、Optimism`

Cruise： `Ethereum、BSC 、Polygon、Arbitrum、Fantom、Optimism、Avalanche、Celo、Gnosis`

Ethtx： `Ethereum、Goerli testnet`

Tendery： `Ethereum、Polygon、BSC、Sepolia、Goerli、Gnosis、POA、RSK、Avalanche C-Chain、Arbitrum、Optimism
、Fantom、Moonbeam、Moonriver`

#### 实务操作
以 JayPeggers - Insufficient validation + Reentrancy [事件](https://github.com/SunWeb3Sec/DeFiHackLabs/#20221229---jay---insufficient-validation--reentrancy)来当例子 [TXID](https://phalcon.blocksec.com/tx/eth/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6)
使用 Blocksec 开发的 Phalcon 工具来说明，下图可以看到该交易的基本资讯和余额变化，从余额变化可以快速看出攻击者大概获利多少，以这个例子攻击者获利 15.32 ETH。

![210571234-402d96aa-fe5e-4bc4-becc-190bd5a78e68-2](https://user-images.githubusercontent.com/107249780/210686382-cc02cc6a-b8ec-4cb7-ac19-402cd8ff86f6.png)

Invocation Flow 可视化函数调用流程: 可以让我们知道这一笔交易调用流程和函数呼叫的层级，有没有使用闪电贷、涉及了哪些项目、呼叫了哪些函数带入了什么参数和原始 data 等等

![图片](https://user-images.githubusercontent.com/52526645/210572053-eafdf62a-7ebe-4caa-a905-045e792add2b.png)

Phalcon 2.0 新增了资金流向和 Debug + 源代码分析可以在 Trace 的过程中边看程式执行的片段、参数、返回值，分析上方便了不少。

![image](https://user-images.githubusercontent.com/107249780/210821062-d1da8d1a-9615-4f1f-838d-34f27b9c3f41.png)

换 Sam 的 Transaction Viewer 来看看 [TXID](https://tx.eth.samczsun.com/ethereum/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6)
跟 Phalcon 类似但 Sam 整合了许多小工具在里面，如下图的眼睛点下去可以看到 Storage 的变化和每个呼叫所消耗的 Gas。

![210574290-790f6129-aa82-4152-b3e1-d21820524a0a-2](https://user-images.githubusercontent.com/107249780/210686653-f964a682-d2a7-4b49-bafc-c9a2b0fa2c55.png)

点击最左边的 Call，可以把原始 Input data 尝试 Decode。

![图片](https://user-images.githubusercontent.com/52526645/210575619-89c8e8de-e2f9-4243-9646-0661b9483913.png)

再来换 Tendery 来看看 [TXID](https://dashboard.tenderly.co/tx/mainnet/0xd4fafa1261f6e4f9c8543228a67caf9d02811e4ad3058a2714323964a8db61f6)
在 Tendery 介面上，一样可以看到基本资讯，但在 Debug 的部分就不是可视化，需要一步一步 Debug 走下去分析，不过好处是可以边 Debug 边看程式码还有 Input data 的转换过程。

![图片](https://user-images.githubusercontent.com/52526645/210577802-c455545c-80d7-4f35-974a-dadbe59c626e.png)

到这边就可以帮我们厘清大概这笔交易做了哪些事情，在还没有开始写 Poc 时，如果想要快速重放攻击可以吗? 可以! 可以使用Tendery 或 Phalcon，这两个工具另外支援了模拟交易重现，在上图右上角有一个按钮 Re-Simulate，工具会自动帮你带上该交易的参数值如下图
从图中的栏位可以依照需求任意改变如改block number, From, Value, Input data 等

![图片](https://user-images.githubusercontent.com/52526645/210580340-f2abf864-e540-4881-8482-f28030e5e35b.png)

### Ethereum Signature Database

[4byte](https://www.4byte.directory/) | [sig.eth](https://sig.eth.samczsun.com/) | [etherface](https://www.etherface.io/hash)

在原始 Input data，前面 4bytes 为 Function Signature. 有时遇到 Etherscan 或分析工具无法解出来时，可以透过 Signature Database 来查看看可能是什么 Function。

以下举例假设我们不知道 `0xac9650d8` 是什么 Function
![图片](https://user-images.githubusercontent.com/52526645/210582149-61a6d973-b458-432f-b586-250c94c3ae24.png)

透过 sig.eth 查询，可以看到这个 4 bytes signature 为 `multicall(bytes[])`
![图片](https://user-images.githubusercontent.com/52526645/210583416-c31bbe07-fa03-4701-880d-0ae485b171f7.png)

### Useful tools

[ABI to interface](https://gnidan.github.io/abi-to-sol/) | [Get ABI for unverified contracts](https://abi.w1nt3r.xyz/) | [ETH Calldata Decoder](https://apoorvlathey.com/eth-calldata-decoder/) | [ETHCMD - Guess ABI](https://www.ethcmd.com/)

ABI to interface: 在开发 Poc 时需要呼叫其他合约时要有 Interface 接口，我们可以透过这个工具帮你快速产生你要的接口。
先去 Etherscan 把 ABI 复制下来，贴过去工具上就可以看到产生出来的 Interface。
[例子](https://etherscan.io/address/0xb3da8d6da3ede239ccbf576ca0eaa74d86f0e9d3#code)

![图片](https://user-images.githubusercontent.com/52526645/210587442-e7853d8b-0613-426e-8a27-d70c80e2a42d.png)
![图片](https://user-images.githubusercontent.com/52526645/210587682-5fb07a01-2b21-41fa-9ed5-e7f45baa0b3e.png)

ETH Calldata Decoder: 有时候在没有 ABI 的情况下想要解看看 Input data 可以试试看 ETH Calldata Decoder，在前面介绍到 Sam 的工具就有支援 Input data decode。

![图片](https://user-images.githubusercontent.com/52526645/210585761-efd8b6f1-b901-485f-ae66-efaf9c84869c.png)

Get ABI for unverified contracts: 如果遇到未开源的合约，可以透过这个工具尝试列举出这个合约中存在的 Function Signature.
[例子](https://abi.w1nt3r.xyz/mainnet/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704)

![图片](https://user-images.githubusercontent.com/52526645/210588945-701b0e22-7390-4539-9d2f-e13479b52824.png)

### Decompile tools
[Etherscan-decompile bytecode](https://etherscan.io/address/0xaE9C73fd0Fd237c1c6f66FE009d24ce969e98704#code) | [Dedaub](https://library.dedaub.com/decompile) | [heimdall-rs](https://github.com/Jon-Becker/heimdall-rs)

Etherscan 内建有一个反编译功能但可读性偏差，个人比较常使用 Dedaub，可读性好一点，也是常常最多人DM 问我都使用哪个工具反编译。
我们拿一个 MEV Bot 被攻击来当[例子](https://twitter.com/1nf0s3cpt/status/1577594615104172033)
可以自己试试解看看 [例子](https://bscscan.com/address/0x64dd59d6c7f09dc05b472ce5cb961b6e10106e1d#code)

首先把未开源合约的 Bytecodes 复制下来贴到 Dedaub 上，点 Decompile 即可。
![截图 2023-01-05 上午10 33 15](https://user-images.githubusercontent.com/107249780/210688395-927c6126-b6c1-4c6d-a0c7-a3fea3db9cdb.png)

![图片](https://user-images.githubusercontent.com/52526645/210591478-6fa928f3-455d-42b5-a1ac-6694f97386c2.png)

第一课分享就先到这边，想学更多可以参考以下学习资源。
---
## 学习资源
[samczsun's eth txn explorer and vscode extension](https://www.youtube.com/watch?v=HXgu239mPBc)

[Vulnerabilities in DeFi by Daniel V.F.](https://www.youtube.com/watch?v=9fcOffCg2ig)

[Tenderly.co - Debug Transaction](https://www.youtube.com/watch?v=90GN9Ut8LhU)

[Reversing The EVM: Raw Calldata](https://degatchi.com/articles/reading-raw-evm-calldata)

https://web3sec.xrex.io/
