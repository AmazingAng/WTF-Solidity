---
title: 50. Multisignature Wallet
tags:
  - Solidity
  - call
  - signature
  - ABI encoding

---

# WTF Solidity Crash Course: 50. Multisignature Wallet

I am currently relearning Solidity to solidify some of the details and create a "WTF Solidity Crash Course" for beginners (advanced programmers may want to find another tutorial). I will update 1-3 lessons weekly.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Official website wtf.academy](https://wtf.academy)

All code and tutorials are open source on Github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

-----

Vitalik once said that a multisig wallet is safer than a hardware wallet ([tweet](https://twitter.com/VitalikButerin/status/1558886893995134978?s=20&t=4WyoEWhwHNUtAuABEIlcRw)). In this lesson, we'll introduce multisig wallets and write a simple version of a multisig wallet contract. The teaching code (150 lines of code) is simplified from the Gnosis Safe contract (several thousand lines of code).

![Vitalik statement](./img/50-1.png)

## Multisig Wallet

A multisig wallet is an electronic wallet where transactions require authorization from multiple private key holders (multisig owners) before they can be executed. For example, if a wallet is managed by three multisig owners, each transaction requires authorization from at least two of them. Multisig wallets can prevent single-point failure (loss of private keys, individual misbehavior), have greater decentralized characteristics, and provide increased security. It is used by many DAOs.

Gnosis Safe is the most popular multisig wallet on Ethereum, managing nearly $40 billion in assets. The contract has undergone auditing and practical testing, supports multiple chains (Ethereum, BSC, Polygon, etc.), and provides comprehensive DAPP support. For more information, you can read the [Gnosis Safe tutorial](https://peopledao.mirror.xyz/nFCBXda8B5ZxQVqSbbDOn2frFDpTxNVtdqVBXGIjj0s) I wrote in December 2021.

## Multisig Wallet Contract

A multisig wallet on Ethereum is actually a smart contract, and it is a contract wallet. We'll write a simple version of the MultisigWallet contract, which has a simple logic:

1. Set multisig owners and threshold (on-chain): When deploying a multisig contract, we need to initialize a list of multisig owners and the execution threshold (at least n multisig owners need to sign and authorize a transaction before it can be executed). Gnosis Safe supports adding/removing multisig owners and changing the execution threshold, but we will not consider this feature in our simplified version.

2. Create transactions (off-chain): A transaction waiting for authorization contains the following information:
    - `to`: Target contract.
    - `value`: The amount of Ether sent in the transaction.
    - `data`: Calldata, which contains the function selector and parameters for the function call.
    - `nonce`: Initially set to `0`, the value of the nonce increases with each successfully executed transaction of the multisig contract, which can prevent replay attacks.
    - `chainid`: The chain id helps prevent replay attacks across different chains.

3. Collect multisig signatures (off-chain): The previous transaction is encoded using ABI and hashed to obtain the transaction hash. Then, the multisig individuals sign it and concatenate the signatures together to obtain the final signed transaction. For those who are not familiar with ABI encoding and hashing, you can refer to the WTF Solidity Tutorial [Lesson 27](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/27_ABIEncode_en/readme.md) and [Lesson 28](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/28_Hash_en/readme.md).

```solidity
Transaction hash: 0xc1b055cf8e78338db21407b425114a2e258b0318879327945b661bfdea570e66

Multisig person A signature: 0xd6a56c718fc16f283512f90e16f2e62f888780a712d15e884e300c51e5b100de2f014ad71bcb6d97946ef0d31346b3b71eb688831abedaf41b33486b416129031c

Multisig person B signature: 0x2184f70a17f14426865bda8ebe391508b8e3984d16ce6d90905ae8beae7d75fd435a7e51d837881d820414ebaf0ff16074204c75b33d66928edcf8dd398249861b

Packaged signatures:
0xd6a56c718fc16f283512f90e16f2e62f888780a712d15e884e300c51e5b100de2f014ad71bcb6d97946ef0d31346b3b71eb688831abedaf41b33486b416129031c2184f70a17f14426865bda8ebe391508b8e3984d16ce6d90905ae8beae7d75fd435a7e51d837881d820414ebaf0ff16074204c75b33d66928edcf8dd398249861b
```

4. Call the execution function of the multisig contract, verify the signature and execute the transaction (on-chain). If you are not familiar with verifying signatures and executing transactions, you can refer to the WTF Solidity Tutorial [Lesson 22](https://githhttps://github.com/AmazingAng/WTF-Solidity/tree/main/Languages/en/22_Call_en) and [Lesson 37](https://github.com/AmazingAng/WTF-Solidity/tree/main/Languages/en/37_Signature_en).

### Events

The `MultisigWallet` contract has two events, `ExecutionSuccess` and `ExecutionFailure`, which are triggered when the transaction is successfully executed or failed, respectively. The parameters are the transaction hash.

```solidity
    event ExecutionSuccess(bytes32 txHash);    // succeeded transaction event
    event ExecutionFailure(bytes32 txHash);    // failed transaction event
```

### State Variables

The `MultisigWallet` contract has five state variables:

  1. `owners`: An array of multisig owners.
  2. `isOwner`: A mapping from `address` to `bool` which tracks whether an address is a multisig holder.
  3. `ownerCount`: The total number of multisig owners.
  4. `threshold`: The minimum number of multisig owners required to execute a transaction.
  5. `nonce`: Initially set to 0, this variable increments with each successful transaction executed by the multisig contract, which can prevent signature replay attacks.

```solidity
    address[] public owners;                   // multisig owners array
    mapping(address => bool) public isOwner;   // check if an address is a multisig owner
    uint256 public ownerCount;                 // the count of multisig owners
    uint256 public threshold;                  // minimum number of signatures required for multisig execution
    uint256 public nonce;                      // nonce，prevent signature replay attack
```

### Functions

The `MultisigWallet` contract has `6` functions:

1. Constructor: calls `_setupOwners()` to initialize variables related to multisig owners and execution thresholds.

    ```solidity
    // constructor, initializes owners, isOwner, ownerCount, threshold 
    constructor(        
        address[] memory _owners,
        uint256 _threshold
    ) {
        _setupOwners(_owners, _threshold);
    }
    ```

2. `_setupOwners()`: Called by the constructor during contract deployment to initialize the `owners`, `isOwner`, `ownerCount`, and `threshold` state variables. The passed-in parameters must have a threshold greater than or equal to `1` and less than or equal to the number of multisignature owners. The multisignature addresses cannot be the zero addresses and cannot be duplicated.

```solidity
/// @dev Initialize owners, isOwner, ownerCount, threshold
/// @param _owners: Array of multisig owners
/// @param _threshold: Minimum number of signatures required for multisig execution
function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
    // If threshold was not initialized
    require(threshold == 0, "WTF5000");
    // multisig execution threshold is less than the number of multisig owners
    require(_threshold <= _owners.length, "WTF5001");
    // multisig execution threshold is at least 1
    require(_threshold >= 1, "WTF5002");

    for (uint256 i = 0; i < _owners.length; i++) {
        address owner = _owners[i];
        // multisig owners cannot be zero address, contract address, and cannot be repeated
        require(owner != address(0) && owner != address(this) && !isOwner[owner], "WTF5003");
        owners.push(owner);
        isOwner[owner] = true;
    }
    ownerCount = _owners.length;
    threshold = _threshold;
}
```

3. `execTransaction()`: After collecting enough multisig signatures, it verifies the signatures and executes the transaction. The parameters passed in include the target address `to`, the amount of Ethereum sent `value`, the data `data`, and the packaged signatures `signatures`. The packaged signature is the signature of the transaction hash collected by the multisig parties, packaged into a [bytes] data in the order of the multisig owners' addresses from small to large. This step calls `encodeTransactionData()` to encode the transaction and calls `checkSignatures()` to verify the validity of the signatures and whether the number of signatures reaches the execution threshold.

```solidity
/// @dev After collecting enough signatures from the multisig, execute the transaction
/// @param to Target contract address
/// @param value msg.value, ether paid
/// @param data calldata
/// @param signatures packed signatures, corresponding to the multisig address in ascending order, for easy checking ({bytes32 r}{bytes32 s}{uint8 v}) (signature of the first multisig, signature of the second multisig...)
function execTransaction(
    address to,
    uint256 value,
    bytes memory data,
    bytes memory signatures
) public payable virtual returns (bool success) {
    // Encode transaction data and compute hash
    bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
    // Increase nonce
    nonce++;  
    // Check signatures
    checkSignatures(txHash, signatures); 
    // Execute transaction using call and get transaction result
    (success, ) = to.call{value: value}(data);
    require(success , "WTF5004");
    if (success) emit ExecutionSuccess(txHash);
    else emit ExecutionFailure(txHash);
}
```

4. `checkSignatures()`: checks if the hash of the signature and transaction data matches, and if the number of signatures exceeds the threshold. If not, the transaction will revert. The length of a single signature is 65 bytes, so the length of the packed signatures must be greater than `threshold * 65`. This function roughly works in the following way:
    - Get signature address using ECDSA.
    - Determine if the signature comes from a different multisignature using `currentOwner > lastOwner` (multisignature addresses increase).
    - Determine if the signer is a multisignature holder using `isOwner[currentOwner]`.

    ```solidity
    /**
     * @dev checks if the hash of the signature and transaction data matches. if signature is invalid, transaction will revert
     * @param dataHash hash of transaction data
     * @param signatures bundles multiple multisig signature together
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // get multisig threshold
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");

        // checks if signature length is enough
        require(signatures.length >= _threshold * 65, "WTF5006");

        // checks if collected signatures are valid 
        // procedure:
        // 1. use ECDSA to verify if signatures are valid
        // 2. use currentOwner > lastOwner to make sure that signatures are from different multisig owners
        // 3. use isOwner[currentOwner] to make sure that current signature is from a multisig owner
        address lastOwner = address(0); 
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // use ECDSA to verify if signature is valid
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
            lastOwner = currentOwner;
        }
    }
    ```

5. `signatureSplit()` function: split a single signature from a packed signature. The function takes two arguments: the packed signature `signatures` and the position of the signature to be read `pos`. The function uses inline assembly to split the `r`, `s`, and `v` values of the signature.

```solidity
/// split a single signature from a packed signature.
/// @param signatures Packed signatures.
/// @param pos Index of the multisig.
function signatureSplit(bytes memory signatures, uint256 pos)
    internal
    pure
    returns (
        uint8 v,
        bytes32 r,
        bytes32 s
    )
{
    // signature format: {bytes32 r}{bytes32 s}{uint8 v}
    assembly {
        let signaturePos := mul(0x41, pos)
        r := mload(add(signatures, add(signaturePos, 0x20)))
        s := mload(add(signatures, add(signaturePos, 0x40)))
        v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
    }
}
```

6. `encodeTransactionData()`: Packs and calculates the hash of transaction data using the `abi.encode()` and `keccak256()` functions. This function can calculate the hash of a transaction, then allow the multisig to sign and collect it off-chain, and finally call the `execTransaction()` function to execute it.

    ```solidity
    /// @dev hash transaction data
    /// @param to target contract's address
    /// @param value msg.value eth to be paid
    /// @param data calldata
    /// @param _nonce nonce of the transaction
    /// @param chainid 
    /// @return bytes of transaction hash
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                )
            );
        return safeTxHash;
    }
    ```

## Demo of `Remix`

1. Deploy a multisig contract with 2 multisig addresses and set the execution threshold to `2`.

    ```solidity
    多签地址1: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    多签地址2: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    ```
    ![Transfer](./img/50-2.png)
2. Transfer `1 ETH` to the multisig contract address.

    ![Transfer](./img/50-3.png)

3. Call `encodeTransactionData()`, encode and calculate the transaction hash for transferring `1 ETH` to the address of the multisig with index 1.

```solidity
Parameter
to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
value: 1000000000000000000
data: 0x
_nonce: 0
chainid: 1

Result
Transaction hash: 0xb43ad6901230f2c59c3f7ef027c9a372f199661c61beeec49ef5a774231fc39b
```

![Calculate transaction hash](./img/50-4.png)

4. Use the note icon next to the ACCOUNT in Remix to sign the transaction. Input the above transaction hash and obtain the signature. Both wallets must be signed.

    ```
    多签地址1的签名: 0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11c

    多签地址2的签名: 0xbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c

    将两个签名拼接到一起，得到打包签名:  0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11cbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c
    ```

![Signature](./img/50-5-1.png)
![Signature](./img/50-5-2.png)
![Signature](./img/50-5-3.png)

5. Call the `execTransaction()` function to execute the transaction, passing in the transaction parameters from step 3 and the packaged signature as parameters. You can see that the transaction was executed successfully and `ETH` was transferred from the multisig wallet.

    ![Executing multisig wallet transaction](./img/50-6.png)

## Summary

In this lesson, we introduced the concept of a multisig wallet and wrote a minimal implementation of a multisig wallet contract, which is less than 150 lines of code.

I have had many opportunities to work with multisig wallets. In 2021, I learned about Gnosis Safe and wrote a tutorial on its usage in both Chinese and English because of the creation of the national treasury by PeopleDAO. Afterwards, I was lucky enough to maintain the assets of three treasury multisig wallets and now I am deeply involved in governing Safes as a guardian. I hope that everyone's assets will be even more secure.
