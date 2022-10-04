---
title: 18. Import
tags:
  - solidity
  - advanced
  - wtfacademy
  - import
---

# WTF Solidity极简入门: 18. Import

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

欢迎加入WTF科学家社区，内有加微信群方法：[链接](https://discord.gg/5akcruXrsk)

所有代码和教程开源在github（1024个star发课程认证，2048个star发社群NFT）: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`solidity`支持利用`import`关键字导入其他合约中的全局符号（简单理解为外部源代码），让开发更加模块化。一般不具体指定则将导入文件的所有全局符号到当前全局作用域中。

## `import`用法

- 通过源文件相对位置导入，例子：

```
文件结构
├── Import.sol
└── Yeye.sol

// 通过文件相对位置import
import './Yeye.sol';
```

- 通过源文件网址导入网上的合约的全局符号，例子：
```
// 通过网址引用
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
```

- 通过`npm`的目录导入，例子：
```solidity
import '@openzeppelin/contracts/access/Ownable.sol';
```

- 通过指定`全局符号`导入合约特定的全局符号，例子：
```solidity
import {Yeye} from './Yeye.sol';
```

- 引用(`import`)在代码中的位置为：在声明版本号之后，在其余代码之前。

## 测试导入结果

我们可以用下面这段代码测试是否成功导入了外部源代码：
```solidity
contract Import {
    // 成功导入Address库
    using Address for address;
    // 声明yeye变量
    Yeye yeye = new Yeye();

    // 测试是否能调用yeye的函数
    function test() external{
        yeye.hip();
    }
}
```

![result](./img/18-1.png)

## 总结
这一讲，我们介绍了利用`import`关键字导入外部源代码的方法。通过`import`关键字，可以引用我们写的其他文件中的合约或者函数，也可以直接导入别人写好的代码，非常方便。
