---
title: S06. 签名重放
tags:
  - solidity
  - security
  - signature
---

# WTF Solidity 合约安全: S06. 签名重放

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍智能合约的签名重放（Signature Replay）攻击和预防方法，它曾间接导致了著名做市商 Wintermute 被盗2000万枚 $OP。

## 签名重放

上学的时候，老师经常会让家长签字，有时候家长很忙，我就会很“贴心”照着以前的签字抄一遍。某种意义上来说，这就是签名重放。

在区块链中，数字签名可以用于识别数据签名者和验证数据完整性。发送交易时，用户使用私钥签名交易，使得其他人可以验证交易是由相应账户发出的。智能合约也能利用 `ECDSA` 算法验证用户将在链下创建的签名，然后执行铸造或转账等逻辑。更多关于数字签名的介绍请见[WTF Solidity第37讲：数字签名](https://github.com/AmazingAng/WTFSolidity/blob/main/37_Signature/readme.md)。

数字签名一般有两种常见的重放攻击：

1. 普通重放：将本该使用一次的签名多次使用。NBA官方发布的《The Association》系列 NFT 因为这类攻击被免费铸造了上万枚。
2. 跨链重放：将本该在一条链上使用的签名，在另一条链上重复使用。做市商 Wintermute 因为跨链重放攻击被盗2000万枚 $OP。

![](./img/S06-1.png)

## 漏洞合约例子

下面的`SigReplay`合约是一个`ERC20`代币合约，它的铸造函数有签名重放漏洞。它使用链下签名让白名单地址 `to` 铸造相应数量 `amount` 的代币。合约中保存了 `signer` 地址，来验证签名是否有效。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// 权限管理错误例子
contract SigReplay is ERC20 {

    address public signer;

    // 构造函数：初始化代币名称和代号
    constructor() ERC20("SigReplay", "Replay") {
        signer = msg.sender;
    }
    
    /**
     * 有签名重访漏洞的铸造函数
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * 签名： 0x5a4f1ad4d8bd6b5582e658087633230d9810a0b7b8afa791e3f94cc38947f6cb1069519caf5bba7b975df29cbfdb4ada355027589a989435bf88e825841452f61b
     */
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }

    /**
     * 将to地址（address类型）和amount（uint256类型）拼成消息msgHash
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * 对应的消息msgHash: 0xb4a4ba10fbd6886a312ec31c54137f5714ddc0e93274da8746a36d2fa96768be
     */
    function getMessageHash(address to, uint256 amount) public pure returns(bytes32){
        return keccak256(abi.encodePacked(to, amount));
    }

    /**
     * @dev 获得以太坊签名消息
     * `hash`：消息哈希 
     * 遵从以太坊签名标准：https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * 以及`EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * 添加"\x19Ethereum Signed Message:\n32"字段，防止签名的是可执行交易。
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // ECDSA验证
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool){
        return ECDSA.recover(_msgHash, _signature) == signer;
    }
```

**注意** 铸造函数 `badMint()` 没有对 `signature` 查重，导致同样的签名可以多次使用，无限铸造代币。

```solidity
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }
```

## `Remix` 复现

**1.** 部署 `SigReplay` 合约，签名者地址 `signer` 被初始化为部署钱包地址。

![](./img/S06-2.png)

**2.** 利用`getMessageHash`函数获取消息。

![](./img/S06-3.png)

**3.** 点击 `Remix` 部署面板的签名按钮，使用私钥给消息签名。

![](./img/S06-4.png)

**4.** 反复调用 `badMint` 进行签名重放攻击，铸造大量代币。

![](./img/S06-5.png)

## 预防办法

签名重放攻击主要有两种预防办法：

1. 将使用过的签名记录下来，比如记录下已经铸造代币的地址 `mintedAddress`，防止签名反复使用：

    ```solidity
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址
    
    function goodMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        // 检查该地址是否mint过
        require(!mintedAddress[to], "Already minted");
        // 记录mint过的地址
        mintedAddress[to] = true;
        _mint(to, amount);
    }
    ```solidity

2. 将 `nonce` （数值随每次交易递增）和 `chainid` （链ID）包含在签名消息中，这样可以防止普通重放和跨链重放攻击：

    ```solidity
    uint nonce;

    function nonceMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount, nonce, block.chainid)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
        nonce++;
    }
    ```

## 总结

这一讲，我们介绍了智能合约中的签名重放漏洞，并介绍了两个预防方法：

1. 将使用过的签名记录下来，防止二次使用。

2. 将 `nonce` 和 `chainid` 包含到签名消息中。