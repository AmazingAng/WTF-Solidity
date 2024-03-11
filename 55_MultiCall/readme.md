---
title: 55. 多重调用
tags:
  - solidity
  - erc20
---

# WTF Solidity极简入门: 55. 多重调用

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity 极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

这一讲，我们将介绍 MultiCall 多重调用合约，它的设计目的在于一次交易中执行多个函数调用，这样可以显著降低交易费用并提高效率。

## MultiCall

在Solidity中，MultiCall（多重调用）合约的设计能让我们在一次交易中执行多个函数调用。它的优点如下：

1. 方便性：MultiCall能让你在一次交易中对不同合约的不同函数进行调用，同时这些调用还可以使用不同的参数。比如你可以一次性查询多个地址的ERC20代币余额。

2. 节省gas：MultiCall能将多个交易合并成一次交易中的多个调用，从而节省gas。

3. 原子性：MultiCall能让用户在一笔交易中执行所有操作，保证所有操作要么全部成功，要么全部失败，这样就保持了原子性。比如，你可以按照特定的顺序进行一系列的代币交易。


## MultiCall 合约

接下来让我们一起来研究一下MultiCall合约，它由 MakerDAO 的 [MultiCall](https://github.com/mds1/multicall/blob/main/src/Multicall3.sol) 简化而成。

MultiCall 合约定义了两个结构体:

- `Call`: 这是一个调用结构体，包含要调用的目标合约 `target`，指示是否允许调用失败的标记 `allowFailure`，和要调用的字节码 `call data`。

- `Result`: 这是一个结果结构体，包含了指示调用是否成功的标记 `success`和调用返回的字节码 `return data`。

该合约只包含了一个函数，用于执行多重调用：

- `multicall()`: 这个函数的参数是一个由Call结构体组成的数组，这样做可以确保传入的target和data的长度一致。函数通过一个循环来执行多个调用，并在调用失败时回滚交易。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    // Call结构体，包含目标合约target，是否允许调用失败allowFailure，和call data
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Result结构体，包含调用是否成功和return data
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice 将多个调用（支持不同合约/不同方法/不同参数）合并到一次调用
    /// @param calls Call结构体组成的数组
    /// @return returnData Result结构体组成的数组
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;
        
        // 在循环中依次调用
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // 如果 calli.allowFailure 和 result.success 均为 false，则 revert
            if (!(calli.allowFailure || result.success)){
                revert("Multicall: call failed");
            }
        }
    }
}
```

## Remix 复现

1. 我们先部署一个非常简单的ERC20代币合约 `MCERC20`，并记录下合约地址。

    ```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    contract MCERC20 is ERC20{
        constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

        function mint(address to, uint amount) external {
            _mint(to, amount);
        }
    }
    ```

2. 部署 `MultiCall` 合约。

3. 获取要调用的`calldata`。我们会给给2个地址分别铸造 50 和 100 单位的代币，你可以在 remix 的调用页面将`mint()` 的参数填入，然后点击 **Calldata** 按钮，将编码好的calldata复制下来。例子:

    ```solidity
    to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    amount: 50
    calldata: 0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032
    ```

    .[](./img/55-1.png)

    如果你不了解`calldata`，可以阅读WTF Solidity的[第29讲]。

4. 利用 `MultiCall` 的 `multicall()` 函数调用ERC20代币合约的 `mint()` 函数，给2个地址分别铸造 50 和 100 单位的代币。例子:

    ```solidity
    calls: [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x40c10f19000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb20000000000000000000000000000000000000000000000000000000000000064"]]
    ```

5. 利用 `MultiCall` 的 `multicall()` 函数调用ERC20代币合约的 `balanceOf()` 函数，查询刚才铸造2个地址的余额。`balanceOf()`函数的selector为`0x70a08231`。例子:

    ```solidity
    [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x70a082310000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x70a08231000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2"]]
    ```

    可以在`decoded output`中查看调用的返回值，两个地址的余额分别为 `0x0000000000000000000000000000000000000000000000000000000000000032` 和 `0x0000000000000000000000000000000000000000000000000000000000000064`，也就是 50 和 100，调用成功！
    .[](./img/55-2.png)

## 总结

这一讲，我们介绍了 MultiCall 多重调用合约，允许你在一次交易中执行多个函数调用。要注意的是，不同的 MultiCall 合约在参数和执行逻辑上有一些不同，使用时要仔细阅读源码。