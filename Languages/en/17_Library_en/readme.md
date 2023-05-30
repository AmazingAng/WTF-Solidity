---
title: 17. Library 
tags:
  - solidity
  - advanced
  - wtfacademy
  - library
  - using for
---

# WTF Solidity Tutorial: 17. Library : Standing on the shoulders of giants

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this section, we use the library contract `String` referenced by `ERC721` as an example to introduce the library contract in `solidity`, 
and then summarize the commonly used library functions.

## Library Functions

A library function is a special contract that exists to improve the reusability of `solidity` and reduce `gas` consumption. 
Library contracts are generally a collection of useful functions (`library functions`), 
which are created by the masters or the project party. 
We only need to stand on the shoulders of giants and use those functions.

![Library contracts：Standing on the shoulders of giants](https://images.mirror-media.xyz/publication-images/HJC0UjkALdrL8a2BmAE2J.jpeg?height=300&width=388)

It differs from ordinary contracts in the following points:

1. State variables are not allowed 
2. Cannot inherit or be inherited
3. Cannot receive ether
4. Cannot be destroyed

## String Library Contract

`String Library Contract` is a code library that converts a `uint256` to the corresponding `string` type. The sample code is as follows:

```solidity
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
```

It mainly contains two functions, `toString()` converts `uint256` to `string`, 
`toHexString()` converts `uint256` to `hexadecimal`, and then converts it to `string`.

### How to use library contracts
We use the toHexString() function in String library function to demonstrate two ways of using the functions in the library contract.

**1. `using for` command**

Command `using A for B` can be used to attach library functions (from library A) to any type (B). After the instruction, 
the function in the library `A` will be automatically added as a member of the `B` type variable,
which can be called directly. Note: When calling, this variable will be passed to the function as the first parameter:

```solidity
    // Using the library with the "using for" 
    {
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        // Library functions are automatically added as members of uint256 variables
        return _number.toHexString();
    }
```
**2. Called directly by the library contract name**
```solidity
    // Called directly by the library contract name
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }
```
We deploy the contract and enter `170` to test, 
both methods can return the correct `hexadecimal string` "0xaa", 
proving that we call the library function successfully!

![Call library function successfully](https://images.mirror-media.xyz/publication-images/bzB_JDC9f5VWHRjsjQyQa.png?height=750&width=580)

## Summary

In this lecture, we use the referenced library function `String` of `ERC721` as an example to introduce the library function (`Library`) in `solidity`. 
99% of developers have no need to write library contracts themselves, 
who can use the ones written by masters. 
The only thing we need to know is that which library contract to use and where the library is suitable.

Some commonly used libraries are:
1. [String](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Strings.sol)：Convert `uint256` to `String`
2. [Address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Address.sol)：Determine whether an address is a contract address
3. [Create2](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Create2.sol)：Safer use of `Create2 EVM opcode`
4. [Arrays](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Arrays.sol)：Library functions related to arrays
