---
title: 28. Hash
tags:
  - solidity
  - advanced
  - wtfacademy
  - hash
---
# WTF Solidity Tutorial: 28. Hash

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.wtf.academy)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Hash function is a cryptographic concept. It can convert a message of arbitrary length into a fixed-length value. This value is also called  hash. In this lecture, we briefly introduce the hash function and its application in solidity.

## Properties of Hash

A good hash function should have the following properties:

- One-way: The forward operation from the input message to its hash is simple and uniquely determined, while the reverse is very difficult and can only be enumerated by brute force.
- Sensitivity: A little change in the input message changes its hash a lot.
- Efficiency: The operation from the input message to the hash is efficient.
- Uniformity: The probability of each hash value being taken should be basically equal.
- Collision resistance:
  - Weak collision resistance: given a message `x`, it is difficult to find another message `x` such that `hash(x) = hash(x')`.
  - Strong collision resistance: finding arbitrary `x` and `x` such that `hash(x) = hash(x')` is difficult.

## Hash application

- Unique identifier for generated data
- Cryptographic signature
- Secure encryption

## Keccak256

The `Keccak256` function is the most commonly used hash function in `solidity`, and its usage is very simple:

```solidity
hash = keccak256(data);
```

### Keccak256 and sha3

Here's an interesting thing:

1. sha3 is standardized by keccak. Keccak and SHA3 are synonymous on many occasions. But when SHA3 was finally standardized in August 2015, NIST adjusted the padding algorithm.
   So SHA3 is different from the result calculated by keccak. We should be paid attention to this point in actual development.
2. sha3 was still being standardized when Ethereum was developing so Ethereum used keccak. In other words, SHA3 in Ethereum and Solidity smart contract code refers to Keccak256, not standard NIST-SHA3. In order to avoid confusion, it is clearest that we write Keccak256 directly in the contract code.

### Generate unique identifier of the data

We can use `keccak256` to generate a unique identifier for data. For example we have several different types of data: `uint`, `string`, `address`. We can first use the `abi.encodePacked` method to pack and encode them, and then use `keccak256` to generate a unique identifier.

### Weak collision resistance

We use `keccak256` to show the weak collision resistance that given a message `x`, it is difficult to find another message `x' such that `hash(x) = hash(x')`.

We define a message named `0xAA` and try to find another message which's hash value is equal to the message `0xAA`.

```solidity
    // Weak collision resistance
    function weak(
        string memory string1
    )public view returns (bool){
        return keccak256(abi.encodePacked(string1)) == _msg;
    }
```

You can try it 10 times and see if you can get lucky.

### Strong collision resistance

We use `keccak256` to show the strong collision resistance that finding arbitrarily different `x` and `x'` such that `hash(x) = hash(x')` is difficult.

We define a function called `strong` that receive two parameters of string type named `string1` and `string2`. Then check if their hashed are the same.

```solidity
    // Strong collision resistance
    function strong(
        string memory string1,
        string memory string2
    )public pure returns (bool){
        return keccak256(abi.encodePacked(string1)) == keccak256(abi.encodePacked(string2));
    }
```

You can try it 10 times and see if you can get lucky.

## Example from Remix

- Deploy the contract and view the generated result of the unique identifier.
  ![img](./img/28-1.png)
- Verify the sensitivity of the hash function, as well as strong and weak collision resistance
  ![img](./img/28-2.png)

## Summary

In this section, we introduced what a hash function is and how to use `keccak256`, the most commonly used hash function in `solidity`.
