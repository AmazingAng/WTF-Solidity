---
title: 52. EIP712 类型化数据签名
tags:
  - solidity
  - erc20
  - eip712
  - openzepplin
---

# WTF Solidity极简入门: 52. EIP712 类型化数据签名

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们介绍一种更丰富、安全的签名方法，EIP712 类型化数据签名。

## EIP712

之前我们介绍了 [EIP191 签名标准（personal sign）](https://github.com/AmazingAng/WTFSolidity/blob/main/37_Signature/readme.md) ，它可以给一段消息签名。但是它过于简单，当签名数据比较复杂时，用户只能看到一串十六进制字符串（数据的哈希），无法核实签名内容是否与预期相符。

![](./img/52-1.png)

[EIP712类型化数据签名](https://eips.ethereum.org/EIPS/eip-712)是一种更高级、更安全的签名方法。当支持 EIP712 签名的 Dapp 请求签名时，钱包会向用户展示数据哈希的原始数据，用户可以在验证数据符合预期之后再签名。

![](./img/52-2.png)

## EIP712 使用方法

EIP712 的应用一般包含链下签名（前端或脚本）和链上验证（合约）两部分，下面我们用一个简单的例子 `EIP712Storage` 来介绍 EIP712 的使用方法。`EIP712Storage` 合约有一个状态变量 `number`，需要验证 EIP712 签名才可以更改。

### 链下签名

1. EIP712 签名必须包含一个 EIP712Domain 部分，它包含了合约的 name，version（一般约定为 “1”），chainId，和 verifyingContract（验证签名的合约地址）。

    ```js
    EIP712Domain: [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
    ]
    ```

    这些信息会在用户签名时显示，并确保只有特定链的特定合约才能验证签名。你需要在脚本中传入相应参数。

    ```js
    const domain = {
        name: "EIP712Storage",
        version: "1",
        chainId: "1",
        verifyingContract: "0xf8e81D47203A594245E36C48e151709F0C19fBe8",
    };
    ```

2. 你需要根据使用场景自定义一个签名的数据类型，他要与合约匹配。在 `EIP712Storage` 例子中，我们定义了一个 `Storage` 类型，它有两个成员: `address` 类型的 `spender`，指定了可以修改变量的调用者；`uint256` 类型的 `number`，指定了变量修改后的值。

    ```js
    const types = {
        Storage: [
            { name: "spender", type: "address" },
            { name: "number", type: "uint256" },
        ],
    };
    ```

3. 创建一个 `message` 变量，传入要被签名的类型化数据。

    ```js
    const message = {
        spender: "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        number: "100",
    };
    ```

4. 调用钱包对象的 `signTypedData()` 方法，传入前面步骤中的 `domain`，`types`，和 `message` 变量进行签名（这里使用 `ethersjs v6`）。

    ```js
    // 获得provider
    const provider = new ethers.BrowserProvider(window.ethereum)
    // 获得signer后调用signTypedData方法进行eip712签名
    const signature = await signer.signTypedData(domain, types, message);
    console.log("Signature:", signature);
    ```

### 链上验证

