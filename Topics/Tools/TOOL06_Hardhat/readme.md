# WTF Solidity极简入门-工具篇6：Hardhat以太坊开发环境

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

WTF技术社群discord，内有加微信群方法：[链接](https://discord.gg/5akcruXrsk)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Hardhat是以太坊最流行的开发环境，它可以帮你编译和部署智能合约，并且提供了Hardhat Network支持本地测试和运行Solidity。这一讲，我们将介绍如何安装Hardhat，使用Hardhat编写并编译合约，并运行简单的测试。

## Hardhat安装

### 安装node

可以使用 nvm 安装node

[GitHub - nvm-sh/nvm: Node Version Manager - POSIX-compliant bash script to manage multiple active node.js versions](https://github.com/nvm-sh/nvm)

### 安装Hardhat

打开命令行工具，输入：
```shell
mkdir hardhat-demo
cd hardhat-demo
npm init -y
npm install --save-dev hardhat
```

### 创建Hardhat项目
打开命令行工具，输入：

```shell
cd hardhat-demo
npx hardhat
```

选择第三项：创建空白项目配置 `Create an empty hardhat.config.js`

```shell
Welcome to Hardhat v2.22.2

? What do you want to do? ...
> Create a JavaScript project
  Create a TypeScript project
  Create a TypeScript project (with Viem)
  Create an empty hardhat.config.js
  Quit
```

### 安装插件
```shell
npm install --save-dev @nomicfoundation/hardhat-toolbox
```

将插件添加到你的hardhat配置文件中 `hardhat.config.js`

```js
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.21",
};
```

## 编写并编译合约
如果你用过remix，那么你直接在remix上点击保存的时候，会自动帮你编译的。但是在本地的hardhat开发环境中，你需要手动编译合约。

### 新建合约目录

新建`contracts`合约目录，并添加第31章节的ERC20合约。

### 编写合约
这里的合约直接使用[WTF Solidity第31讲](https://github.com/AmazingAng/WTFSolidity/blob/main/31_ERC20/readme.md]的ERC20合约

```js
// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

import "./IERC20.sol";

contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;   // 代币总供给

    string public name;   // 名称
    string public symbol;  // 符号
    
    uint8 public decimals = 18; // 小数位数

    // @dev 在合约部署的时候实现合约名称和符号
    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // @dev 实现`transfer`函数，代币转账逻辑
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev 实现 `approve` 函数, 代币授权逻辑
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev 实现`transferFrom`函数，代币授权转账逻辑
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // @dev 铸造代币，从 `0` 地址转账给 调用者地址
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev 销毁代币，从 调用者地址 转账给  `0` 地址
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

```

### 编译合约
```shell
npx hardhat compile
```

看到如下输出，说明合约编译成功：

```shell
Compiling 2 Solidity files successfully
```

成功后，你会在文件夹下看到`artifacts`目录，里面的`json`文件就是编译结果。

## 编写单元测试

这里的单元测试非常简单，仅包含部署合约并测试合约地址是否合法（是否部署成功）。

新建测试文件夹`test`，在其中新建`test.js`。单元测试中，我们会用到`chai`和`ethers.js`两个库，分别用于测试和链上交互。对`ethers.js`不了解的开发者，可以看下[WTF Ethers极简教程](https://github.com/WTFAcademy/WTF-Ethers)的前6讲。我们之后的教程会更详细的介绍`chai`和`mocha`。

```js
const { expect } = require('chai');
const { ethers } = require('hardhat');


describe("ERC20 合约测试", ()=>{
  it("合约部署", async () => {
     // ethers.getSigners,代表eth账号  ethers 是一个全局函数，可以直接调用
     const [owner, addr1, addr2] = await ethers.getSigners();
     // ethers.js 中的 ContractFactory 是用于部署新智能合约的抽象，因此这里的 ERC20 是我们代币合约实例的工厂。ERC20代表contracts 文件夹中的 ERC20.sol 文件
     const Token = await ethers.getContractFactory("ERC20");
     // 部署合约, 传入参数 ERC20.sol 中的构造函数参数分别是 name, symbol 这里我们都叫做WTF
     const hardhatToken = await Token.deploy("WTF", "WTF"); 
     await hardhatToken.waitForDeployment();
      // 获取合约地址
     const ContractAddress = await hardhatToken.target;
     expect(ContractAddress).to.properAddress;
  });
})
```

## 运行测试

在命令行输入以下内容运行测试：

```shell
npx hardhat test
# 如果有多个文件想跑指定文件可以使用
npx mocha test/test.js
```

看到如下输出，说明测试成功。

```shell
  ERC20 合约测试
    ✔ 合约部署 (1648ms)


  1 passing (2s)
```

## 部署合约

在remix中，我们只需要点击一下`deploy`就可以部署合约了，但是在本地hardhat中，我们需要编写一个部署脚本。

新建一个`scripts`文件夹，我们来编写部署合约脚本。并在该目录下新建一个`deploy.js`

输入以下代码

```js
// 我们可以通过 npx hardhat run <script> 来运行想要的脚本
// 这里你可以使用 npx hardhat run deploy.js 来运行
const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("ERC20");
  const token = await Contract.deploy("WTF","WTF");

  await token.waitForDeployment();

  console.log("成功部署合约:", token.target);
}

// 运行脚本
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

```

运行以下代码部署合约到本地测试网络

hardhat会提供一个默认的网络，参考：[hardhat默认网络](https://hardhat.org/hardhat-network/docs/overview)

```shell
npx hardhat run --network hardhat  scripts/deploy.js
```

看到如下输出，说明合约部署成功：

```shell
(node:45779) ExperimentalWarning: stream/web is an experimental feature. This feature could change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
成功部署合约: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

## 部署合约到Goerli测试网络 ｜ 网络配置

### 前期准备

1. 申请alchemy的api key
参考【[第4讲：Alchemy, 区块链API和节点基础设施](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Tools/TOOL04_Alchemy/readme.md)】 
2. 申请Goerli测试代币
[点击申请](https://goerlifaucet.com/) 登录alchemy账号每天可以领取0.2个代币
3. 导出私钥
因为需要把合约部署到Goerli测试网络，所以该测试账号中留有一定的测试代币。导出已有测试代币的账户的私钥，用于部署合约
4. 申请 etherscan 的 api key，用于验证合约
[点击申请](https://etherscan.io/myapikey)

### 配置网络

在`hardhat.config.js`中，我们可以配置多个网络，这里我们配置`Goerli`测试网络。


编辑 `hardhat.config.js`


```js
require("@nomicfoundation/hardhat-toolbox");

// 申请alchemy的api key
const ALCHEMY_API_KEY = "KEY";

//将此私钥替换为测试账号私钥
//从Metamask导出您的私钥，打开Metamask和进入“帐户详细信息”>导出私钥
//注意:永远不要把真正的以太放入测试帐户
const GOERLI_PRIVATE_KEY = "YOUR GOERLI PRIVATE KEY";

// 申请etherscan的api key
const ETHERSCAN_API_KEY = "YOUR_ETHERSCAN_API_KEY";

module.exports = {
  solidity: "0.8.21", // solidity的编译版本
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
```

配置完成运行

```shell
npx hardhat run --network goerli scripts/deploy.js
```

你就可以把你的合约部署到Goerli测试网络了。

看到如下信息，你就成功部署到Goerli测试网络了。

```shell
(node:46996) ExperimentalWarning: stream/web is an experimental feature. This feature could change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
(node:46999) ExperimentalWarning: stream/web is an experimental feature. This feature could change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
成功部署合约: 0xeEAcef71084Dd1Ae542***9D8F64E3c68e15****
```

可以通过[etherscan](https://etherscan.io/)查看合约部署情况

同理你也可以配置多个网络，比如`mainnet`，`rinkeby`等。

最后验证你的合约：

```shell
npx hardhat verify --network goerli DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"
```


## 总结

这一讲，我们介绍了Hardhat基础用法。通过Hardhat我们能够工程化solidity的项目，并提供了很多有用的脚手架。在后续的文章中，我们会介绍更多的Hardhat的高级用法，例如使用Hardhat的插件、测试框架等等。