---
title: 52. EIP712 Typed Data Signature
tags:
   - solidity
   - erc20
   - eip712
   - openzepplin
---

# WTF Solidity Minimalist Introduction: 52. EIP712 Typed Data Signature

I'm recently re-learning solidity, consolidating the details, and writing a "WTF Solidity Minimalist Introduction" for novices (programming experts can find another tutorial), updating 1-3 lectures every week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) |[Official website wtf.academy](https://wtf.academy)

All codes and tutorials are open source on github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lecture, we introduce a more advanced and secure signature method, EIP712 typed data signature.

## EIP712

Previously we introduced [EIP191 signature standard (personal sign)](https://github.com/AmazingAng/WTFSolidity/blob/main/37_Signature/readme.md), which can sign a message. But it is too simple. When the signature data is complex, the user can only see a string of hexadecimal strings (the hash of the data) and cannot verify whether the signature content is as expected.

![](./img/52-1.png)

[EIP712 Typed Data Signature](https://eips.ethereum.org/EIPS/eip-712) is a more advanced and more secure signature method. When an EIP712-enabled Dapp requests a signature, the wallet displays the original data of the signed message and the user can sign after verifying that the data meets expectations.

![](./img/52-2.png)

## How to use EIP712

The application of EIP712 generally includes two parts: off-chain signature (front-end or script) and on-chain verification (contract). Below we use a simple example `EIP712Storage` to introduce the use of EIP712. The `EIP712Storage` contract has a state variable `number`, which needs to be verified by the EIP712 signature before it can be changed.

### Off-chain signature

1. The EIP712 signature must contain an `EIP712Domain` part, which contains the name of the contract, version (generally agreed to be "1"), chainId, and verifyingContract (the contract address to verify the signature).

    ```js
    EIP712Domain: [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
    ]
    ```

   This information is displayed when the user signs and ensures that only specific contracts for a specific chain can verify the signature. You need to pass in the corresponding parameters in the script.

    ```js
    const domain = {
        name: "EIP712Storage",
        version: "1",
        chainId: "1",
        verifyingContract: "0xf8e81D47203A594245E36C48e151709F0C19fBe8",
    };
    ```

2. You need to customize a signature data type according to the usage scenario, and it must match the contract. In the `EIP712Storage` example, we define a `Storage` type, which has two members: `spender` of type `address`, which specifies the caller who can modify the variable; `number` of type `uint256`, which specifies The modified value of the variable.

    ```js
    const types = {
        Storage: [
            { name: "spender", type: "address" },
            { name: "number", type: "uint256" },
        ],
    };
    ```
3. Create a `message` variable and pass in the typed data to be signed.

    ```js
    const message = {
        spender: "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        number: "100",
    };
    ```
    ![](./img/52-3.png)

4. Call the `signTypedData()` method of the wallet object, passing in the `domain`, `types`, and `message` variables from the previous step for signature (`ethersjs v6` is used here).

    ```js
    // Get provider
     const provider = new ethers.BrowserProvider(window.ethereum)
     // After obtaining the signer, call the signTypedData method for eip712 signature
     const signature = await signer.signTypedData(domain, types, message);
     console.log("Signature:", signature);
     ```
     ![](./img/52-4.png)

### On-chain verification

Next is the `EIP712Storage` contract part, which needs to verify the signature and, if passed, modify the `number` state variable. It has `5` state variables.

1. `EIP712DOMAIN_TYPEHASH`: The type hash of `EIP712Domain`, which is a constant.
2. `STORAGE_TYPEHASH`: The type hash of `Storage`, which is a constant.
3. `DOMAIN_SEPARATOR`: This is the unique value of each domain (Dapp) mixed in the signature, consisting of `EIP712DOMAIN_TYPEHASH` and `EIP712Domain` (name, version, chainId, verifyingContract), initialized in `constructor()`.
4. `number`: The state variable that stores the value in the contract can be modified by the `permitStore()` method.
5. `owner`: Contract owner, initialized in `constructor()`, and verify the validity of the signature in the `permitStore()` method.

In addition, the `EIP712Storage` contract has `3` functions.

1. Constructor: Initialize `DOMAIN_SEPARATOR` and `owner`.
2. `retrieve()`: Read the value of `number`.
3. `permitStore`: Verify the EIP712 signature and modify the value of `number`. First, it breaks the signature into `r`, `s`, and `v`. The signed message text `digest` is then spelt out using `DOMAIN_SEPARATOR`, `STORAGE_TYPEHASH`, the caller address, and the `_num` parameter entered. Finally, use the `recover()` method of `ECDSA` to recover the signer's address. If the signature is valid, update the value of `number`.

```solidity
// SPDX-License-Identifier: MIT
// By 0xAA 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Storage {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    bytes32 private DOMAIN_SEPARATOR;
    uint256 number;
    address owner;

    constructor(){
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH, // type hash
            keccak256(bytes("EIP712Storage")), // name
            keccak256(bytes("1")), // version
            block.chainid, // chain id
            address(this) // contract address
        ));
        owner = msg.sender;
    }

    /**
     * @dev Store value in variable
     */
   function permitStore(uint256 _num, bytes memory _signature) public {
         // Check the signature length, 65 is the length of the standard r, s, v signature
         require(_signature.length == 65, "invalid signature length");
         bytes32 r;
         bytes32 s;
         uint8 v;
         // Currently only assembly (inline assembly) can be used to obtain the values of r, s, v from the signature
         assembly {
             /*
             The first 32 bytes store the length of the signature (dynamic array storage rules)
             add(sig, 32) = pointer to sig + 32
             Equivalent to skipping the first 32 bytes of signature
             mload(p) loads the next 32 bytes of data starting from memory address p
             */
             // Read the 32 bytes after length data
             r := mload(add(_signature, 0x20))
             //32 bytes after reading
             s := mload(add(_signature, 0x40))
             //Read the last byte
             v := byte(0, mload(add(_signature, 0x60)))
        }

        //Get signed message hash
         bytes32 digest = keccak256(abi.encodePacked(
             "\x19\x01",
             DOMAIN_SEPARATOR,
             keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
         ));
        
         address signer = digest.recover(v, r, s); //Recover the signer
         require(signer == owner, "EIP712Storage: Invalid signature"); // Check signature

         //Modify state variables
         number = _num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }    
}
```

## Remix Reappearance

1. Deploy the `EIP712Storage` contract.

2. Run `eip712storage.html`, change the `Contract Address` to the deployed `EIP712Storage` contract address, and then click the `Connect Metamask` and `Sign Permit` buttons to sign. To sign, use the wallet that deploys the contract, such as the Remix test wallet:

     ```js
     public_key: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     private_key: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
     ```

3. Call the `permitStore()` method of the contract, enter the corresponding `_num` and signature, and modify the value of `number`.

4. Call the `retrieve()` method of the contract and see that the value of `number` has changed.

## Summary

In this lecture, we introduce EIP712 typed data signature, a more advanced and secure signature standard. When requesting a signature, the wallet displays the original data of the signed message and the user can sign after verifying the data. This standard is widely used and is used in Metamask, Uniswap token pairs, DAI stable currency and other scenarios. I hope everyone can master it.
