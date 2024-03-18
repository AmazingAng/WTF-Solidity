---
title: 27. ABI Encoding and Decoding
tags:
  - solidity
  - advanced
  - wtfacademy
  - abi encoding
  - abi decoding
---

# Solidity Minimalist Tutorial: 27. ABIEncode&Decode

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`ABI`(Application Binary Interface) is the standard for interacting with Ethereum smart contracts. Data is encoded based on its type, and because the encoded result doesn't contain type information, it is necessary to indicate their types when decoding.

In Solidity, `ABI encode` has four functions: `abi.encode`, `abi.encodePacked`, `abi.encodeWithSignature`, `abi.encodeWithSelector`. While `ABI decode` has one function: `abi.decode`, which is used to decode the data of `abi.encode`.

In this chapter, We will learn how to use these functions.

## ABI encode
We will encode four variables, their types are `uint256` (alias `uint`), `address`, `string`, `uint256[2]`:
```solidity
    uint x = 10;
    address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    string name = "0xAA";
    uint[2] array = [5, 6]; 
```

### `abi.encode`
Use [ABI rules](https://learnblockchain.cn/docs/solidity/abi-spec.html) to encode the given parameters. `ABI` is designed to interact with smart contracts by filling each parameter with 32-byte data and splicing them together. If you want to interact with contracts, you should use `abi.encode`.
```solidity
    function encode() public view returns(bytes memory result) {
        result = abi.encode(x, addr, name, array);
    }
```
The result of encoding is`0x000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000007a58c0be72be218b41c608b7fe7c5bb630736c7100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000043078414100000000000000000000000000000000000000000000000000000000`. Since `abi.encode` fills each data with 32 bytes data, there are a lot of `0` in middle

### `abi.encodePacked`
Encode given parameters according to their minimum required space. It is similar to `abi.encode`, but omits a lot of `0` filled in. For example, only 1 byte is used to encode the `uint` type. You can use `abi.encodePacked` when you want to save space and don't interact with contracts. For example when computing `hash` of some data.
```solidity
    function encodePacked() public view returns(bytes memory result) {
        result = abi.encodePacked(x, addr, name, array);
    }
```
The result of encoding is`0x000000000000000000000000000000000000000000000000000000000000000a7a58c0be72be218b41c608b7fe7c5bb630736c713078414100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000006`. Because `abi.encodePacked` compacts encoding, the length of result is much shorter than `abi.encode`.

### `abi.encodeWithSignature`
Similar to `abi.encode` function, the first parameter is `function signatures`, such as `"foo(uint256, address, string, uint256[2])"`. It can be used when calling other contracts.
```solidity
    function encodeWithSignature() public view returns(bytes memory result) {
        result = abi.encodeWithSignature("foo(uint256,address,string,uint256[2])", x, addr, name, array);
    }
```
The result of encoding is`0xe87082f1000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000007a58c0be72be218b41c608b7fe7c5bb630736c7100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000043078414100000000000000000000000000000000000000000000000000000000`. This is equivalent to adding 4 bytes `function selector` to the front of result of `abi.encode`[^note].
[^note]: Function selectors identify functions by signature processing(Keccak–Sha3) using function names and arguments, which can be used for function calls between different contracts.

### `abi.encodeWithSelector`
Similar to `abi.encodeWithSignature`, except that the first argument is a `function selector`, the first 4 bytes of `function signature` Keccak hash.

```solidity
    function encodeWithSelector() public view returns(bytes memory result) {
        result = abi.encodeWithSelector(bytes4(keccak256("foo(uint256,address,string,uint256[2])")), x, addr, name, array);
    }
```

The result of encoding is`0xe87082f1000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000007a58c0be72be218b41c608b7fe7c5bb630736c7100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000043078414100000000000000000000000000000000000000000000000000000000`. The result is the same as `abi.encodeWithSignature`

## ABI decode
### `abi.decode`
`abi.decode` is used to decode the binary code generated by `abi.encode` and restore it to its original parameters.

```solidity
    function decode(bytes memory data) public pure returns(uint dx, address daddr, string memory dname, uint[2] memory darray) {
        (dx, daddr, dname, darray) = abi.decode(data, (uint, address, string, uint[2]));
    }
```
We input binary encoding of `abi.encode` into `decode`, which will decode the original parameters:

![](https://images.mirror-media.xyz/publication-images/jboRaaq0U57qVYjmsOgbv.png?height=408&width=624)

## 在remix上验证
- deploy the contract to check the encoding result of `abi.encode`
![](./img/27-1_en.png)

- compare and verify the similarities and differences of the four encoding functions
![](./img/27-2_en.png)

- check the decoding result of `abi.decode`
![](./img/27-3_en.png)

## ABI的使用场景
1. In contract development, ABI is often paired with a call to implement a low-level call to contract.
```solidity  
    bytes4 selector = contract.getValue.selector;

    bytes memory data = abi.encodeWithSelector(selector, _x);
    (bool success, bytes memory returnedData) = address(contract).staticcall(data);
    require(success);

    return abi.decode(returnedData, (uint256));
```
2. ABI is often used in ethers.js to implement contract import and function calls.
```solidity
    const wavePortalContract = new ethers.Contract(contractAddress, contractABI, signer);
    /*
        * Call the getAllWaves method from your Smart Contract
        */
    const waves = await wavePortalContract.getAllWaves();
```
3. After decompiling a non-open source contract, some functions cannot find function signatures but can be called through ABI.
- 0x533ba33a() is a function which shows after decompiling, we can only get function-encoded results, and can't find the function signature.
![](./img/27-4_en.png)
![](./img/27-5_en.png)
- in this case we can't call through constructing an interface or contract
![](./img/27-6_en.png)

In this case, we can call through the ABI function selector.
```solidity
    bytes memory data = abi.encodeWithSelector(bytes4(0x533ba33a));

    (bool success, bytes memory returnedData) = address(contract).staticcall(data);
    require(success);

    return abi.decode(returnedData, (uint256));
```

## Summary
In Ethereum, data must be encoded into bytecode to interact with smart contracts. In this chapter, we introduced four `abi encoding` functions and one `abi decoding` function.
