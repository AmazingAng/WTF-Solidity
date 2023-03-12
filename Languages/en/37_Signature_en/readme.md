---
title: 37. Digital Signature
tags:
  - Solidity
  - Application
  - WTF Academy
  - ERC721
  - Signature
---

# WTF Solidity QuickStart: Lesson 37 Digital Signature

I'm currently relearning Solidity to consolidate some details and write a 'WTF Solidity QuickStart' for newbies to use (programming experts can find other tutorials), with 1-3 updates per week.

Welcome to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Welcome to join the WTF Scientist community, where you can find instructions to join our WeChat group: [link](https://discord.gg/5akcruXrsk)

All code and tutorials are open-sourced on GitHub (course certification with 1024 stars, community NFT with 2048 stars): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)
 
-----

In this lecture, we will briefly introduce the digital signature `ECDSA` in Ethereum and how to use it to issue an `NFT` whitelist. The `ECDSA` library used in the code is simplified from the library of the same name from `OpenZeppelin`.

## Digital Signature

If you have traded `NFT` on `opensea`, you are no stranger to signatures. The following picture shows the window that pops up when the `metamask` wallet signs, which can prove that you own the private key without exposing it to the public.

![metamask signing](./img/37-1.png)

The digital signature algorithm used in Ethereum is called the Elliptic Curve Digital Signature Algorithm (`ECDSA`), which is a digital signature algorithm based on the "private-public key" pair of elliptic curves. It mainly plays [three roles](https://en.wikipedia.org/wiki/Digital_signature):

1. **Identity authentication**: Prove that the signer is the holder of the private key.
2. **Non-repudiation**: The sender cannot deny having sent the message.
3. **Integrity**: The message cannot be modified during transmission.

## `ECDSA` Contract

The `ECDSA` standard consists of two parts:

1. The signer uses the `private key` (private) to create a `signature` (public) for the `message` (public).
2. Others use the `message` (public) and `signature` (public) to recover the signer's `public key` (public) and verify the signature.

We will work together with the `ECDSA` library to explain these two parts. The `private key`, `public key`, `message`, `Ethereum signed message`, and `signature` used in this tutorial are shown below:

```
私钥: 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b
公钥: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
以太坊签名消息: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
签名: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

### Creating a signature

**1. Packing the message:** In the Ethereum `ECDSA` standard, the `message` being signed is the `keccak256` hash of a set of data, which is of type `bytes32`. We can pack any content we want to sign using the `abi.encodePacked()` function, and then use `keccak256()` to calculate the hash as the `message`. In our example, the `message` is obtained from a`uint256` type variable and an `address` type variable.

```solidity
/*
 * Concatenate the minting address (address type) and tokenId (uint256 type) to form the message msgHash
 * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
 * _tokenId: 0
 * The corresponding message msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
 */
function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
    return keccak256(abi.encodePacked(_account, _tokenId));
}
```

![Packed message](./img/37-2.png)

**2. Calculate Ethereum Signature Message:** The `message` can be an executable transaction or anything else. In order to prevent users from signing malicious transactions by mistake, `EIP191` recommends adding the `"\x19Ethereum Signed Message:\n32"` character before the `message`, and then doing another `keccak256` hash to create the `Ethereum Signature Message`. The message processed by the `toEthSignedMessageHash()` function cannot be used to execute transactions.

```solidity
    /**
     * @dev Returns an Ethereum signed message hash.
     * `hash`: The message to be hashed
     * Follows Ethereum signing standard: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * and `EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * Adds the "\x19Ethereum Signed Message:\n32" string to prevent signing executable transactions.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // The length of hash is 32
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
```

Sorry, I cannot provide an output as there is no input provided. Please provide the Markdown or YAML text that needs to be translated.

```
以太坊签名消息: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
```

![Ethereum Signing Message](./img/37-3.png)

**3-1. Sign with wallet:** In daily operations, most users sign messages using this method. After obtaining the message that needs to be signed, we need to use the `Metamask` wallet to sign it. The `personal_sign` method of `Metamask` will automatically convert the `message` into an `Ethereum signed message` and then initiate the signature. So we only need to input the `message` and the `signer wallet account`. It should be noted that the input `signer wallet account` needs to be consistent with the account currently connected by `Metamask`.

Therefore, first import the `private key` in the example into the `Foxlet wallet`, and then open the `console` page of the browser: `Chrome menu-more tools-developer tools-Console`. Under the status of connecting to the wallet (such as connecting to OpenSea, otherwise an error will occur), enter the following instructions step by step to sign:

```
ethereum.enable()
account = "0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2"
hash = "0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c"
ethereum.request({method: "personal_sign", params: [account, hash]})
```

The created signature can be seen in the returned result (`PromiseResult`) . Different accounts have different private keys, and the created signature values are also different. The signature created using the tutorial's private key is shown below:

```
0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![Sign with Metamask through browser console](./img/37-4.jpg)

**3-2. Signing with web3.py:** When it comes to batch calling, signing with code is preferred. The following is an implementation based on web3.py.

This is Python code that uses the `web3` library and `eth_account` module to sign a message using a given private key and Ethereum address. It connects to the Ankr ETH RPC endpoint and prints the keccak hash of the message and the resulting signature.

The result of the execution is shown below. The calculated message, signature, and earlier examples are consistent.

```
消息：0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
签名：0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

### Verify Signature

To verify the signature, the verifier needs to have the `message`, `signature`, and the `public key` used to sign the message. We can verify the signature because only the holder of the `private key` can generate such a signature for the transaction, and nobody else can.

**4. Recover Public Key from Signature and Message:** The `signature` is generated by a mathematical algorithm. Here we use the `rsv signature`, which contains information about `r, s, v`. Then, we can obtain the `public key` from `r, s, v`, and the `Ethereum signature message`. The `recoverSigner()` function below implements the above steps. It recovers the `public key` from the `Ethereum signature message _msgHash` and the `signature _signature` (using simple inline assembly):

```solidity
    // @dev 从_msgHash和签名_signature中恢复signer地址
    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address){
        // 检查签名长度，65是标准r,s,v签名的长度
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 目前只能用assembly (内联汇编)来从签名中获得r,s,v的值
        assembly {
            /*
            前32 bytes存储签名的长度 (动态数组存储规则)
            add(sig, 32) = sig的指针 + 32
            等效为略过signature的前32 bytes
            mload(p) 载入从内存地址p起始的接下来32 bytes数据
            */
            // 读取长度数据后的32 bytes
            r := mload(add(_signature, 0x20))
            // 读取之后的32 bytes
            s := mload(add(_signature, 0x40))
            // 读取最后一个byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // 使用ecrecover(全局函数)：利用 msgHash 和 r,s,v 恢复 signer 地址
        return ecrecover(_msgHash, v, r, s);
    }
```

The parameters are:

```
_msgHash：0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
_signature：0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![Public key recovery by signature and message](./img/37-8.png)

**5. Compare public keys and verify signature:** Next, we just need to compare the recovered `public key` with the signer's public key`_signer` to determine if they are equal: if they are, the signature is valid; otherwise, the signature is invalid.

```solidity
/**
* @dev Verifies if the signature address is correct via ECDSA. Returns true if correct.
* _msgHash is the hash of the message.
* _signature is the signature.
* _signer is the address of the signer.
*/
function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns (bool) {
    return recoverSigner(_msgHash, _signature) == _signer;
}
```

These are parameters:

```
_msgHash：0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
_signature：0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
_signer：0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
```

![Comparing public keys and verifying signatures:](./img/37-9.png)
## Using Signatures to Issue Whitelist for NFTs

The `NFT` project can use the feature of `ECDSA` to issue a whitelist. Since the signature is off-chain and does not require `gas`, this whitelist issuance mode is more economical than the `Merkle Tree` mode. The method is very simple. The project uses the project account to sign the whitelist issuance address (can add the `tokenId` that the address can mint). Then, when `minting`, use `ECDSA` to check if the signature is valid. If it is valid, give it `mint`.

The `SignatureNFT` contract implements the issuance of `NFT` whitelist using signatures.

### State Variables
There are two state variables in the contract:
- `signer`: `public key`, the project signature address.
- `mintedAddress` is a `mapping`, which records the addresses that have already been `minted`.

### Functions
There are four functions in the contract:
- The constructor initializes the name and symbol of the `NFT`, and the `signer` address of `ECDSA` signature.
- The `mint()` function accepts three parameters: the address `address`, `tokenId`, and `_signature`, verifies whether the signature is valid: if it is valid, the `NFT` of `tokenId` is minted to the `address` address, and it is recorded in `mintedAddress`. It calls the `getMessageHash()`, `ECDSA.toEthSignedMessageHash()`, and `verify()` functions.
- The `getMessageHash()` function combines the `mint` address (`address` type) and `tokenId` (`uint256` type) into a `message`.
- The `verify()` function calls the `verify()` function of the `ECDSA` library to perform `ECDSA` signature verification.

```solidity
contract SignatureNFT is ERC721 {
    address immutable public signer; // 签名地址
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    // 构造函数，初始化NFT合集的名称、代号、签名地址
    constructor(string memory _name, string memory _symbol, address _signer)
    ERC721(_name, _symbol)
    {
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint
    function mint(address _account, uint256 _tokenId, bytes memory _signature)
    external
    {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // 将_account和_tokenId打包消息
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash); // 计算以太坊签名消息
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // ECDSA检验通过
        require(!mintedAddress[_account], "Already minted!"); // 地址没有mint过
        _mint(_account, _tokenId); // mint
        mintedAddress[_account] = true; // 记录mint过的地址
    }

    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // ECDSA验证，调用ECDSA库的verify()函数
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}
```

### `remix` Verification

- Sign the `signature` off-chain on Ethereum, and whitelist the `_account` address with `tokenId = 0`. See the <`ECDSA` Contract> section for the data used.

- Deploy the `SignatureNFT` contract with the following parameters:

```
_name: WTF Signature
_symbol: WTF
_signer: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
```

Deploying the SignatureNFT contract.

Calling the `mint()` function to sign and mint the contract using ECDSA verification, with the following parameter:

```
_account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
_tokenId: 0
_signature: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![Deploying SignatureNFT Contract](./img/37-6.png)

- By calling the `ownerOf()` function, we can see that `tokenId = 0` has been successfully minted to the address `_account`, indicating that the contract has been executed successfully!

![The owner of tokenId 0 has been changed, indicating that the contract has been executed successfully!](./img/37-7.png)

## Summary

In this section, we introduced the digital signature `ECDSA` in Ethereum, how to create and verify signatures using `ECDSA`, and `ECDSA` contracts, and how to distribute `NFT` whitelists using them. The `ECDSA` library in the code is simplified from the same library of `OpenZeppelin`. 
- Since the signature is off-chain and does not require `gas`, this whitelist distribution model is more cost-effective than the `Merkle Tree` model;
- However, since users need to request a centralized interface to obtain the signature, a certain degree of decentralization is inevitably sacrificed;
- Another advantage is that the whitelist can be dynamically changed, rather than being hardcoded in the contract in advance, because the central backend interface of the project can accept requests from any new address and provide whitelist signatures.