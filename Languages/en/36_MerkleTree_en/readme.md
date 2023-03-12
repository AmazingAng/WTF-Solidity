---
title: 36. Merkle Tree
tags:
  - solidity
  - application
  - wtfacademy
  - ERC721
  - Merkle Tree
---

# WTF Solidity Beginner's Guide: 36. Merkle Tree

Recently, I have been reviewing solidity in order to consolidate some details and write a "WTF Solidity Beginner's Guide" for novices (programming experts can find other tutorials). I will update 1-3 lessons weekly.

Welcome to follow me on Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Welcome to join the WTF Scientist community, which includes methods for adding WeChat groups: [link](https://discord.gg/5akcruXrsk)

All code and tutorials are open source on Github (1024 stars will issue course certification, 2048 stars will issue community NFTs): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lecture, I will introduce the `Merkle Tree` and how to use it to distribute a `NFT` whitelist.

## `Merkle Tree`
`Merkle Tree`, also known as Merkel tree or hash tree, is a fundamental encryption technology in blockchain and is widely used in Bitcoin and Ethereum blockchains. `Merkle Tree` is an encrypted tree constructed from the bottom up, where each leaf corresponds to the hash of the corresponding data, and each non-leaf represents the hash of its two child nodes.

![Merkle Tree] (./img/36-1.png)

`Merkle Tree` allows for efficient and secure verification (`Merkle Proof`) of the contents of large data structures. For a `Merkle Tree` with `N` leaf nodes, verifying whether a given data is valid (belonging to a `Merkle Tree` leaf node) only requires `log(N)` data (`proofs`), which is very efficient. If the data is incorrect, or if the `proof` given is incorrect, the root value of the `root` cannot be restored.
In the example below, the `Merkle proof` of leaf `L1` is `Hash 0-1` and `Hash 1`: Knowing these two values, we can verify whether the value of `L1` is in the leaves of the `Merkle Tree` or not. Why?
Because through the leaf `L1` we can calculate `Hash 0-0`, we also know `Hash 0-1`, then `Hash 0-0` and `Hash 0-1` can be combined to calculate `Hash 0`, we also know `Hash 1`, and `Hash 0` and `Hash 1` can be combined to calculate `Top Hash`, which is the hash of the root node.

![Merkle Proof] (./img/36-2.png)

## Generating a `Merkle Tree`

We can use the [webpage] (https://lab.miguelmota.com/merkletreejs/example/) or the Javascript library [merkletreejs](https://github.com/miguelmota/merkletreejs) to generate a `Merkle Tree`.

Here we use a webpage to generate a `Merkle Tree` with `4` addresses as the leaf nodes. Leaf node input:

```solidity
    [
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
    ]
```

Select the `Keccak-256`, `hashLeaves`, and `sortPairs` options in the menu, then click `Compute`, and the `Merkle Tree` will be generated. The `Merkle Tree` expands to:

```
└─ 根: eeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
   ├─ 9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65
   │  ├─ 叶子0：5931b4ed56ace4c46b68524cb5bcbf4195f1bbaacbe5228fbd090546c88dd229
   │  └─ 叶子1：999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb
   └─ 4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c
      ├─ 叶子2：04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54
      └─ 叶子3：dfbe3e504ac4e35541bebad4d0e7574668e16fefa26cd4172f93e18b59ce9486
```

![Generating Merkle Tree](./img/36-3.png)

## Verification of `Merkle Proof`
Through the website, we can obtain the `proof` of `address 0` as follows, which is the hash value of the blue node in Figure 2:

```solidity
[
  "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",
  "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c"
]
```

We use the `MerkleProof` library for verification:

```solidity
library MerkleProof {
    /**
     * @dev 当通过`proof`和`leaf`重建出的`root`与给定的`root`相等时，返回`true`，数据有效。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns 通过Merkle树用`leaf`和`proof`计算出`root`. 当重建出的`root`和给定的`root`相同时，`proof`才是有效的。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    // Sorted Pair Hash
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}
```

The `MerkleProof` library contains three functions:

1. The `verify()` function: It uses the `proof` to verify whether the `leaf` belongs to the `Merkle Tree` with the root of `root`. If it does, it returns `true`. It calls the `processProof()` function.

2. The `processProof()` function: It calculates the `root` of the `Merkle Tree` using the `proof` and `leaf` in sequence. It calls the `_hashPair()` function.

3. The `_hashPair()` function: It uses the `keccak256()` function to calculate the hash (sorted) of the two child nodes corresponding to the non-root node.

We input `address 0`, `root`, and the corresponding `proof` to the `verify()` function, which will return `true` because `address 0` is in the `Merkle Tree` with the root of `root`, and the `proof` is correct. If any of these values are changed, it will return `false`.

Using `Merkle Tree` to distribute NFT whitelists:

Updating an 800-address whitelist can easily cost more than 1 ETH in gas fees. However, using the `Merkle Tree` verification, the `leaf` and `proof` can exist on the backend, and only one value of `root` needs to be stored on the chain, making it very gas-efficient. Many `ERC721` NFT and `ERC20` standard token whitelists/airdrops are issued using `Merkle Tree`, such as the airdrop on Optimism.

Here, we introduce how to use the `MerkleTree` contract to distribute NFT whitelists:

```solidity
contract MerkleTree is ERC721 {
    bytes32 immutable public root; // Merkle树的根
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    // 构造函数，初始化NFT合集的名称、代号、Merkle树的根
    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

    // 利用Merkle树验证地址并完成mint
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // Merkle检验通过
        require(!mintedAddress[account], "Already minted!"); // 地址没有mint过
        _mint(account, tokenId); // mint
        mintedAddress[account] = true; // 记录mint过的地址
    }

    // 计算Merkle树叶子的哈希值
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle树验证，调用MerkleProof库的verify()函数
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
```

The `MerkleTree` contract inherits the `ERC721` standard and utilizes the `MerkleProof` library.

### State Variables
The contract has two state variables:
- `root` stores the root of the `Merkle Tree`, assigned during contract deployment.
- `mintedAddress` is a `mapping` that records minted addresses. It is assigned a value after a successful mint.

### Functions
The contract has four functions:
- Constructor: Initializes the name and symbol of the NFT, and the `root` of the `Merkle Tree`.
- `mint()` function: Mints an NFT using a whitelist. Takes `account` (whitelisted address), `tokenId` (minted ID), and `proof` as arguments. The function first verifies whether the `address` is whitelisted. If verification passes, the NFT with ID `tokenId` is minted for the address, which is then recorded in `mintedAddress`. This process calls the `_leaf()` and `_verify()` functions.
- `_leaf()` function: Calculates the hash of the leaf address of the `Merkle Tree`.
- `_verify()` function: Calls the `verify()` function of the `MerkleProof` library to verify the `Merkle Tree`.

### `Remix` Verification
We use the four addresses in the example above as the whitelist and generate a `Merkle Tree`. We deploy the `MerkleTree` contract with three arguments:

```solidity
name = "WTF MerkleTree"
symbol = "WTF"
merkleroot = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
```

![Deploying MerkleTree contract](./img/36-5.png)

Next, run the `mint` function to mint an `NFT` for address 0, using three parameters:

```solidity
account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
tokenId = 0
proof = [   "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",   "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c" ]
```

We can use the `ownerOf` function to verify that the `tokenId` of 0 for the NFT has been minted to address 0, and the contract has run successfully.

If we change the holder of the `tokenId` to 0, the contract will still run successfully.

If we call the `mint` function again at this point, although the address can pass the `Merkle Proof` verification, because the address has already been recorded in `mintedAddress`, the transaction will be aborted due to `"Already minted!"`.

In this lesson, we introduced the concept of `Merkle Tree`, how to generate a simple `Merkle Tree`, how to use smart contracts to verify `Merkle Tree`, and how to use it to distribute `NFT` whitelist.

In practical use, complex `Merkle Tree` can be generated and managed using the `merkletreejs` library in Javascript, and only one root value needs to be stored on the chain, which is very gas-efficient. Many project teams choose to use `Merkle Tree` to distribute the whitelist.