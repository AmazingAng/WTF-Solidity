# Solidity极简入门: 30. Import

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

所有代码开源在github(64个star开微信交流群，已开[填表加入](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform)；128个star录教学视频): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`solidity`支持利用`import`关键字导入其他源代码中的合约，让开发更加模块化。

## `import`用法

- 通过源文件相对位置导入，例子：

```
文件结构
├── Import.sol
└── Yeye.sol

// 通过文件相对位置import
import './Yeye.sol';
```

- 通过源文件网址导入网上的合约
```
// 通过网址引用
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
```

- 通过`npm`的目录导入
```
import '@openzeppelin/contracts/access/Ownable.sol';
```

- 通过`全局符号`导入特定的合约
```
import {Yeye} from './Yeye.sol';
```

## 测试导入结果

我们可以用下面这段代码测试是否成功导入了外部源代码：
```
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

## 总结
这一讲，我们介绍了利用`import`关键字导入外部源代码的方法。`import`可以让我们直接导入别人写好的代码，非常方便。
