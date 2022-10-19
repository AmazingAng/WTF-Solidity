# WTF Solidity极简入门-工具篇7: Foundry，以Solidity为中心的开发工具包

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
## Foundry入门

[WTF Solidity极简入门-工具篇7: Foundry，以Solidity为中心的开发工具包](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)


## Foundry 的组成

Foundry 项目由 `Forge`, `Cast`, `Anvil` 几个部分（命令行工具）组成

-   Forge: Foundry 项目中**执行初始化项目、管理依赖、测试、构建、部署智能合约**的命令行工具;
-   Cast: Foundry 项目中**与 RPC 节点交互**的命令行工具。可以进行智能合约的调用、发送交易数据或检索任何类型的链上数据;
-   Anvil: Foundry 项目中**启动的本地测试网/节点**的命令行工具。可以使用它配合测试前端应用与部署在该测试网的合约或通过 RPC 进行交互;

