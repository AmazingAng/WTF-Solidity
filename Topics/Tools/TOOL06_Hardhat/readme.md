# WTF Solidity极简入门-工具篇6：Hardhat以太坊开发环境

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

五个命令即可运行本章配套项目，环境使用 Node.js 22.12 或更新版本、Hardhat 3.22.0、Solidity 0.8.39 和 ethers 6.17.0。

```sh
npm ci
npx hardhat compile
npm test
npx hardhat run scripts/deploy.js
npx hardhat node
```

[ERC20.sol](./contracts/ERC20.sol) 沿用第 31 讲的 ERC-20。Hardhat 会根据
[配置](./hardhat.config.js) 编译 `contracts/`。配置的 `plugins` 数组启用 ethers
和 Mocha，项目通过 `"type": "module"` 使用 ESM 导入。

[测试](./test/test.js) 调用 `network.create()` 获取独立的本地连接。连接上的
`ethers.deployContract` 用合约名称和构造参数部署 ERC-20。测试等待部署交易确认，
再读取代币名称和符号。

[部署脚本](./scripts/deploy.js) 打印部署地址。不带 `--network` 时，
它使用一次性的本地模拟链。若要和已启动的本地节点共享状态，在另一个终端运行
`npx hardhat run scripts/deploy.js --network localhost`。

## 部署到 Sepolia

在当前终端设置 `SEPOLIA_RPC_URL` 和 `SEPOLIA_PRIVATE_KEY`。私钥使用专用测试账户，
账户需要少量 Sepolia ETH 支付交易费用。然后执行：

```sh
npx hardhat run scripts/deploy.js --network sepolia
```

[Hardhat 3 官方文档](https://hardhat.org/docs)包含配置变量、模拟网络和插件的用法。
