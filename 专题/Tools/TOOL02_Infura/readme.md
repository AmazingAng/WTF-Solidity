# Solidity极简入门-工具篇2：Infura, 连接链下与链上的桥梁

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

WTF技术社群discord，内有加微信群方法：[链接](https://discord.gg/5akcruXrsk)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
`Infura`是Consensys(小狐狸钱包母公司)开发的区块链基础设施，帮助用户/开发者更好的与以太坊区块链交互。

## 连接应用和区块链

![链下链上交互](./img/infura1.png)

在以太坊上开发的Dapp应用（链下）需要与区块链（链上）交互。早期，以太坊上的基础设施很少，开发者需要在本地部署以太坊节点来完成链下和链上的交互，非常麻烦，且耗时数日。

`Infura`在链下、链上之间搭了一座桥，让两者的交互变的简单。它为用户提供对以太坊和IPFS网络的即时、可扩展的`API`访问。开发者在`Infura`官网注册后，就可以免费申请的以太坊`API KEY`，就可以利用`Infura`的节点与区块链交互。另外，小狐狸`metamask`钱包内置了`Infura`服务，方便用户访问以太坊网络。

## 创建`Infura` API Key

### 1. 打开Infura官网并注册

网址：[infura.io](https://infura.io)
![Infura官网](./img/infura2.png)

### 2. 创建API Key
注册后，进入控制台Dashboard，并点击右上角的 **CREATE NEW KEY** 按钮。

![创建API Key](./img/infura3.png)

### 3. 填写API Key信息

`NETWORK`选择 Web3 API (Formerly Ethereum)，`NAME`随便填一个，我填的`WTF`，之后点击**CREATE**按钮。

![填写信息](./img/infura4.png)

### 4. API Key创建完毕

回到控制台Dashboard，可以看到名为`WTF`的API Key已经创建完毕。在控制台Dashboard，点击  **MANAGE KEY** 按钮，可以查看API Key详情。


![API Key创建完毕](./img/infura5.png)

### 5. 查看API Key详情

进入API Key详情页，我们可以看到我们的API Key（图中`174d`开头的一组密钥）。在下面的 **NETWORK ENDPOINT** 栏中，可以查到以太网主网/测试网的rpc节点链接，用于访问链上数据并交互。另外，你可以申请免费的Layer2 rpc节点，包括`Polygon`，`Optimism`和`Arbitrum`，但是需要绑定`visa`卡。领`Optimism`空投那次，公开rpc节点卡爆了，而使用`Infura`的私人rpc节点的人可以正常领取。

![查看信息](./img/infura6.png)

## 使用`Infura` API Key 
### Javascript (`ethers.js`)
在`ether.js`中，我们可以利用`Infura` API Key来创建`JsonRpcProvider`，与链上交互。

```javascript
const { ethers } = require("ethers");
// 填上你的Infura API Key
const INFURA_ID = '' 
const provider = new ethers.providers.JsonRpcProvider(`https://mainnet.infura.io/v3/${INFURA_ID}`)
```

### `Metamask`小狐狸钱包

进入小狐狸钱包设置 **Setting** 页面，点击网络 **Netowrk**，点击添加网络 **Add Network**。你可以利用下面的参数在小狐狸中添加`Optimism` Layer2链：

```
网络名称（Network Name）: Optimism
RPC URL：填在Infura申请的optimism rpc链接
链ID (Chain ID): 10
符号 (Chain Symbol): ETH
区块链浏览器URL (Blockchain Explorer URL): https://optimistic.etherscan.io
```

![小狐狸配置私人rpc](./img/infura7.png)

## 总结

这一讲，我们介绍了如何创建并使用`Infura` API Key便捷访问以太坊区块链。