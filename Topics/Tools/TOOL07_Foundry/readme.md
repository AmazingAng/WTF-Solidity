# Solidity极简入门-工具篇7: Foundry -- 以太坊开发工具包

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

WTF技术社群discord，内有加微信群方法：[链接](https://discord.gg/5akcruXrsk)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## 什么是 Foundry?
来自 Foundry [官网 (getfoundry.sh) ](https://getfoundry.sh) 对该工具的介绍：`Foundry是 一个用 Rust编写的用于以太坊应用程序开发的极快、可移植和模块化的工具包 ( Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.)`

项目设施：
- 官网：[https://getfoundry.sh](https://getfoundry.sh)
- Github 仓库：[https://github.com/foundry-rs/foundry](https://github.com/foundry-rs/foundry)
- 文档：[https://book.getfoundry.sh](https://book.getfoundry.sh)

介绍的解释：
- **用 Rust 语言编写**： Foundry 完全采用 Rust 语言开发， [Github 上的源代码仓库](https://github.com/foundry-rs/foundry) 是一个 Rust 语言工程。我们可以通过获取 [Release 的二进制文件](https://github.com/foundry-rs/foundry/releases)，也可以通过 Rust 语言的 cargo 包管理[工具编译&构建安装](https://github.com/foundry-rs/foundry#installing-from-source);
- **用于以太坊应用程序开发**： Foundry 作为 以太坊（Solidity语言）项目/应用程序开发的 “工程化” 工具，提供专业 Solidity 开发环境与“工具链”。**通过它你可以快速、方便的完成依赖项管理、编译、运行测试、部署，并可以通过命令行和 Solidity 脚本与链进行交互**;
- **极快**： Foundry 利用 [ethers-solc](https://github.com/gakonst/ethers-rs/tree/master/ethers-solc/) 比较于传统通过 Node.js 辅助完成的测试用例/工程，Foundry 构建、测试的执行速度很快（创建一个工程，写一些测试用例跑一下会感受到震撼）;
- **可移植**: Foundry 工程支持与其他类型的工程集成（如：[与 Hardhat 集成](https://book.getfoundry.sh/config/hardhat)）;
- **模块化**：通过 git submodule & 构建目录映射，快速方便的引入依赖;

<!--👆TODO: some 🔗 LINKS can be added when our Hardhat tutorial is complete -->

## 为什么选择 Foundry？

如果你满足以下条件或有过类似体验，你一定要试试 Foundry：

- ~~如果你有 Rust “语言信仰”~~，如果你是个专业的 以太坊（Solidity语言）应用开发者；
- 你曾经用过类似 Hardhat.js 这样的工具；
- 你厌倦了大量测试用例的等待，需要有工具**更加快速**的跑完你的测试用例；
- 你觉得处理 BigNumber 稍微有一点点🤏麻烦;
- 有过**通过 Solidity 语言本身完成测试用例**（或测试合约的合约）的需求；
- 你觉得通过 git submodule 的方式管理依赖更加方便（而不是 npm）；
- ···


如果有以下情况 Foundry 可能不适合你：
- Solidity 初学者；
- 你的项目不需要写测试用例、不需要过多在 Solidity 工程方面的自动化操作；


## Foundry 的主要功能
> 该部分源于 Foundry book ([https://book.getfoundry.sh](https://book.getfoundry.sh))，让章节的理解更容易。

- [创建以太坊（Solidity）智能合约应用开发项目](https://book.getfoundry.sh/projects/creating-a-new-project)，[开发已有的项目](https://book.getfoundry.sh/projects/working-on-an-existing-project);
- [管理以太坊(Solidity)智能合约的依赖项目](https://book.getfoundry.sh/projects/dependencies);
- [创建由 Solidity 语言编写的测试用例（并且能很快速的执行测试用例）](https://book.getfoundry.sh/forge/writing-tests): 并且支持[模糊测试](https://book.getfoundry.sh/forge/fuzz-testing)与[差异测试](https://book.getfoundry.sh/forge/differential-ffi-testing)等方便、专业的测试方式;
- 通过 [Cheatcodes（作弊码）](https://book.getfoundry.sh/forge/cheatcodes) 在 Solidity语言 编写的测试用例中**进行 “EVM环境之外” 的 vm 功能进行交互与断言**：更换测试用例语句执行者的钱包地址（更换 `msg.sender`）、对 EVM 外的 Event 事件进行断言；
- 执行过程与错误追踪：[“函数堆栈”级的错误追踪（Traces）](https://book.getfoundry.sh/forge/traces)；
- [部署合约和自动化的完成scan上合约的开源验证](https://book.getfoundry.sh/forge/deploying)；
- 在项目中支持[完整的gas使用情况追踪](https://book.getfoundry.sh/forge/gas-tracking)：包括合约测试细节的gas用量和gas报告；
- 交互式[调试器](https://book.getfoundry.sh/forge/debugger)；

## Foundry 的组成

Foundry 项目由 `Forge`, `Cast`, `Anvil` 几个部分（命令行工具）组成

- Forge: Foundry 项目中**执行初始化项目、管理依赖、测试、构建、部署智能合约**的命令行工具;
- Cast: Foundry 项目中**与 RPC 节点交互**的命令行工具。可以进行智能合约的调用、发送交易数据或检索任何类型的链上数据;
- Anvil:  Foundry 项目中**启动的本地测试网/节点**的命令行工具。可以使用它配合测试前端应用与部署在该测试网的合约或通过 RPC 进行交互; 

## 快速使用 --- 创建一个 Foundry 项目

> 内容出自 Foundry book 的 Getting Start 部分

即将完成的过程：
1. 安装 Foundry;
2. 初始化一个 Foundry 项目;
3. 理解初始化过程中添加的智能合约、测试用例；
4. 执行构建&测试;
  
  
### 安装 Foundry

对于不同的环境：
- MacOS / Linux （等 Unix like 系统）：
  - 通过 `foundryup` 安装（👈Foundry 项目首页推荐的方式）;
  - 通过 源代码构建 安装;
- Windows
  - 通过 源代码构建 安装;
- Docker 环境
  - 参考 Foundry Package: [ https://github.com/gakonst/foundry/pkgs/container/foundry](https://github.com/gakonst/foundry/pkgs/container/foundry)
- Github Action： 用于构建完整的 Action 流程
  - 参考 [https://github.com/foundry-rs/foundry-toolchain](https://github.com/foundry-rs/foundry-toolchain)

---

#### 通过[脚本](https://raw.githubusercontent.com/foundry-rs/foundry/master/foundryup/install)快速安装
通过有`bash`的（或者类Unix环境）快速安装
```shell
$ curl -L https://foundry.paradigm.xyz | bash
```
执行后将会安装 `foundryup`，在此后执行它
```shell
$ foundryup
```
如果一切顺利，您现在可以使用三个二进制文件：`forge`、`cast` 和 `anvil`。



---

#### [通过源代码构建安装（需要你了解一点 Rust 环境）](https://book.getfoundry.sh/getting-started/installation#building-from-source)

要从源代码构建，您需要获取 `Rust` 和 `Cargo`。获得两者的最简单方法是使用 `rustup`。

```shell
# clone 项目目录至本地
git clone https://github.com/foundry-rs/foundry

# 进入项目目录
cd foundry

# 安装 cast + forge
cargo install --path ./cli --profile local --bins --locked --force

# 安装 anvil
cargo install --path ./anvil --profile local --locked --force
```

### 初始化一个 Foundry 项目

通过 `forge` 的 `forge init` 初始化项目 "hello_wtf"
```shell
$ forge init hello_wtf

Initializing /Users/username/hello_wtf...
Installing forge-std in "/Users/username/hello_wtf/lib/forge-std" (url: Some("https://github.com/foundry-rs/forge-std"), tag: None)
    Installed forge-std
    Initialized forge project.
```
该过程通过安装依赖`forge-std`初始化了一个 Foundry 项目

在项目目录中看到

```shell
$ tree -L 2 
.
├── foundry.toml        # Foundry 的 package 配置文件
├── lib                 # Foundry 的依赖库
│   └── forge-std       # 工具 forge 的基础依赖
├── script              # Foundry 的脚本
│   └── Counter.s.sol   # 示例合约 Counter 的脚本
├── src                 # 智能合约的业务逻辑、源代码将会放在这里
│   └── Counter.sol     # 示例合约
└── test                # 测试用例目录
    └── Counter.t.sol   # 示例合约的测试用例
```
提示：
- 依赖项作为 git submodule 在 `./lib` 目录中
- 关于 Foundry 的 package 配置文件请详细参考: [https://github.com/foundry-rs/foundry/blob/master/config/README.md#all-options](https://github.com/foundry-rs/foundry/blob/master/config/README.md#all-options)


### 理解初始化过程中添加的智能合约、测试用例

#### src 目录

主要由业务逻辑构成
`src` 目录中的 `./src/Counter.sol`:
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {          // 一个很简单的 Counter 合约
    uint256 public number;  // 维护一个 public 的 uint256 数字

    // 设置 number 变量的内容
    function setNumber(uint256 newNumber) public { 
        number = newNumber;
    }

    // 让 number 变量的内容自增
    function increment() public {
        number++;
    }
}
```

#### script 目录

参考 Foundry 项目文档中的 [Solidity-scripting](https://book.getfoundry.sh/tutorials/solidity-scripting) 该目录主要由“部署”脚本构成（也可通过该脚本调用 Foundry 提供的 `vm` 功能实现应用业务逻辑之外的高级功能，等同于 Hardhat.js 中的 scripts）

script 目录中的 `./script/Counter.s.sol`

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract CounterScript is Script {
    function setUp() public {}
    function run() public {
        vm.broadcast(); // 
    }
}
```

#### test 目录

主要由合约的测试用例构成

test 目录中的 `./test/Counter.t.sol`

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";        // 引入 forge-std 中用于测试的依赖
import "../src/Counter.sol";        // 引入用于测试的业务合约

// 基于 forge-std 的 test 合约依赖实现测试用例
contract CounterTest is Test {      
    Counter public counter;

    // 初始化测试用例
    function setUp() public { 
       counter = new Counter();
       counter.setNumber(0);
    }

    // 基于初始化测试用例
    // 断言测试自增后的 counter 的 number 返回值 同等于 1
    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    // 基于初始化测试用例
    // 执行差异测试测试
    // forge 测试的过程中
    // 为 testSetNumber 函数参数传递不同的 unit256 类型的 x
    // 达到测试 counter 的 setNumber 函数 为不同的 x 设置不同的数
    // 断言 number() 的返回值等同于差异测试的 x 参数
    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // 差异测试：参考 https://book.getfoundry.sh/forge/differential-ffi-testing
}
```

### 执行构建&测试

在项目目录中通过执行 `forge build` 完成构建
```shell
$ forge build

[⠒] Compiling...
[⠢] Compiling 10 files with 0.8.17
[⠰] Solc 0.8.17 finished in 1.06s
Compiler run successful
```

完成构建后 通过 `forge test` 完成测试
```shell
$ forge test

[⠢] Compiling...
No files changed, compilation skipped

Running 2 tests for test/Counter.t.sol:CounterTest
[PASS] testIncrement() (gas: 28312)
[PASS] testSetNumber(uint256) (runs: 256, μ: 27609, ~: 28387)
Test result: ok. 2 passed; 0 failed; finished in 9.98ms
```

至此，您已完成上手使用 Foundry 并且初始化一个项目。

<!--

  TODO: For foundry advanced useage ...

  We need cover: 
  
  - cli forge `test` : reference https://book.getfoundry.sh/forge/writing-tests
  - cheatcode.
  - Logs and traces levels.

... etc.

  


-->