---
title: 18. Import
tags:
  - solidity
  - advanced
  - wtfacademy
  - import
---

# WTF Solidity Tutorial: 18. Import

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`solidity` supports the use of the `import` keyword to import global symbols in other contracts 
(simply understood as external source code), making development more modular. Generally, 
if not specified, all global symbols of the imported file will be imported into the current global scope.

## Usage of `import`

- Import by relative location of source file. For example：

```
Hierarchy
├── Import.sol
└── Yeye.sol

// Import by relative location of source file
import './Yeye.sol';
```

- Import the global symbols of contracts on the Internet through the source file URL. For example：
```
// Import by URL
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
```

- Import via the `npm` directory. For example:
```solidity
import '@openzeppelin/contracts/access/Ownable.sol';
```

- Import contract-specific global symbols by specifying `global symbols`. For example:：
```solidity
import {Yeye} from './Yeye.sol';
```

- The location of the reference (`import`) in the code: after declaring the version, and before the rest of the code.

## Test `import`

We can use the following code to test whether the external source code was successfully imported:

```solidity
contract Import {
    // Successfully import the Address library
    using Address for address;
    // declare variable "yeye"
    Yeye yeye = new Yeye();

    // Test whether the function of "yeye" can be called
    function test() external{
        yeye.hip();
    }
}
```

![result](./img/18-1.png)

## Summary
In this lecture, we introduced the method of importing external source code using the `import` keyword. Through the `import`, 
you can refer to contracts or functions in other files written by us, 
or directly import code written by others, which is very convenient.
