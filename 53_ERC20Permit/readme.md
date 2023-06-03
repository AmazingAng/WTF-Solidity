---
title: 53. ERC-2612 ERC20Permit
tags:
  - solidity
  - erc20
  - eip712
  - openzepplin
---

# WTF Solidity极简入门: 53. ERC-2612 ERC20Permit

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们介绍 ERC20 代币的一个拓展，ERC20Permit，支持使用签名进行授权，改善用户体验。它在 EIP-2612 中被提出，已纳入以太坊标准，并被 `USDC`，`ARB` 等代币使用。

## ERC20

我们在[31讲](https://github.com/AmazingAng/WTF-Solidity/blob/main/31_ERC20/readme.md)中介绍了ERC20，以太坊最流行的代币标准。它流行的一个主要原因是 `approve` 和 `transferFrom` 两个函数搭配使用，使得代币不仅可以在外部拥有账户（EOA）之间转移，还可以被其他合约使用。

但是，ERC20的 `approve` 函数限制了只有代币所有者才能调用，这意味着所有 `ERC20` 代币的初始操作必须由 `EOA` 执行。举个例子，用户 A 在去中心化交易所使用 `USDT` 交换 `ETH`，必须完成两个交易：第一步用户 A 调用 `approve` 将 `USDT` 授权给合约，第二步用户 A 调用合约进行交换。非常麻烦，并且用户必须持有 `ETH` 用于支付交易的 gas。

## ERC20Permit

EIP-2612 提出了 ERC20Permit，扩展了 ERC20 标准，添加了一个 `permit` 函数，允许用户通过 EIP-712 签名修改授权，而不是通过 `msg.sender`。这有两点好处：

1. 授权这步仅需用户在链下签名，减少一笔交易。
2. 签名后，用户可以委托第三方进行后续交易，不需要持有 ETH：用户 A 可以将签名发送给 拥有gas的第三方 B，委托 B 来执行后续交易。

![](./img/53-1.png)

## 合约

### IERC20Permit 接口合约

首先，让我们学习下 ERC20Permit 的接口合约，它定义了 3 个函数：

- `permit()`: 根据 `owner` 的签名, 将 `owenr` 的ERC20代币余额授权给 `spender`，数量为 `value`。要求：
 
    - `spender` 不能是零地址。
    - `deadline` 必须是未来的时间戳。
    - `v`，`r` 和 `s` 必须是 `owner` 对 EIP712 格式的函数参数的有效 `secp256k1` 签名。
    - 签名必须使用 `owner` 当前的 nonce。


- `nonces()`: 返回 `owner` 的当前 nonce。每次为 `permit()` 函数生成签名时，都必须包括此值。每次成功调用 `permit()` 函数都会将 `owner` 的 nonce 增加 1，防止多次使用同一个签名。

- `DOMAIN_SEPARATOR()`: 返回用于编码 `permit()` 函数的签名的域分隔符（domain separator），如 [EIP712](https://github.com/AmazingAng/WTF-Solidity/blob/main/52_EIP712/readme.md) 所定义。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC20 Permit 扩展的接口，允许通过签名进行批准，如 https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]中定义。
 */
interface IERC20Permit {
    /**
     * @dev 根据owner的签名, 将 `owenr` 的ERC20余额授权给 `spender`，数量为 `value`
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev 返回 `owner` 的当前 nonce。每次为 {permit} 生成签名时，都必须包括此值。
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev 返回用于编码 {permit} 的签名的域分隔符（domain separator）
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
```

### ERC20Permit 合约

下面，让我们写一个简单的 ERC20Permit 合约，它实现了 IERC20Permit 定义的所有接口。合约包含 2 个状态变量:

- `_nonces`: `address -> uint` 的映射，记录了所有用户当前的 nonce 值，
- `_PERMIT_TYPEHASH`:  常量，记录了 `permit()` 函数的类型哈希。

合约包含 5 个函数:

- 构造函数: 初始化代币的 `name` 和 `symbol`。
- **`permit()`**: ERC20Permit 最核心的函数，实现了 IERC20Permit 的 `permit()` 。它首先检查签名是否过期，然后用 `_PERMIT_TYPEHASH`, `owner`, `spender`, `value`, `nonce`, `deadline` 还原签名消息，并验证签名是否有效。如果签名有效，则调用ERC20的 `_approve()` 函数进行授权操作。
- `nonces()`: 实现了 IERC20Permit 的 `nonces()` 函数。
- `DOMAIN_SEPARATOR()`: 实现了 IERC20Permit 的 `DOMAIN_SEPARATOR()` 函数。
- `_useNonce()`: 消费 `nonce` 的函数，返回用户当前的 `nonce`，并增加 1。

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @dev ERC20 Permit 扩展的接口，允许通过签名进行批准，如 https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]中定义。
 *
 * 添加了 {permit} 方法，可以通过帐户签名的消息更改帐户的 ERC20 余额（参见 {IERC20-allowance}）。通过不依赖 {IERC20-approve}，代币持有者的帐户无需发送交易，因此完全不需要持有 Ether。
 */
contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev 初始化 EIP712 的 name 以及 ERC20 的 name 和 symbol
     */
    constructor(string memory name, string memory symbol) EIP712(name, "1") ERC20(name, symbol){}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // 检查 deadline
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        // 拼接 Hash
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        
        // 从签名和消息计算 signer，并验证签名
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        
        // 授权
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "消费nonce": 返回 `owner` 当前的 `nonce`，并增加 1。
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }
}
```

## Remix 复现

1. 部署 `ERC20Permit` 合约，将 `name` 和 `symbol` 均设为 `WTFPermit`。

2. 运行 `signERC20Permit.html`，将 `Contract Address` 改为部署的 `ERC20Permit` 合约地址，其他信息下面给出。然后依次点击 `Connect Metamask` 和 `Sign Permit` 按钮签名，并获取 `r`，`s`，`v`，用于合约验证。签名要使用部署合约的钱包，比如 Remix 测试钱包：

    ```js
    owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4    spender: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    value: 100
    deadline: 115792089237316195423570985008687907853269984665640564039457584007913129639935
    private_key: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
    ```

![](./img/53-2.png)


3. 调用合约的 `permit()` 方法，输入相应参数，进行授权。

4. 调用合约的 `allance()` 方法，输入相应的 `owner` 和 `spender`，可以看到授权成功。

## 安全注意

ERC20Permit 利用链下签名进行授权给用户带来了便利，同时带来了风险。一些黑客会利用这一特性进行钓鱼攻击，骗取用户签名并盗取资产。2023年4月的一起针对 USDC 的签名[钓鱼攻击](https://twitter.com/0xAA_Science/status/1652880488095440897?s=20)让一位用户损失了 228w u 的资产。

**签名时，一定要谨慎的阅读签名内容！**

## 总结

这一讲，我们介绍了 ERC20Permit，一个 ERC20 代币标准的拓展，支持用户使用链下签名进行授权操作，改善了用户体验，被很多项目采用。但同时，它也带来了更大的风险，一个签名就能将你的资产卷走。大家在签名时一定要更加谨慎。
