---
title: 53. ERC-2612 ERC20Permit
tags:
  - solidity
  - erc20
  - eip712
  - openzepplin
---

# WTF A simple introduction to Solidity: 53. ERC-2612 ERC20Permit

I'm recently re-learning solidity, consolidating the details, and writing a "WTF Solidity Minimalist Introduction" for novices (programming experts can find another tutorial), updating 1-3 lectures every week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) |[Official website wtf.academy](https://wtf.academy)

All codes and tutorials are open source on github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lecture, we introduce an extension of ERC20 tokens, ERC20Permit, which supports the use of signatures for authorization and improves user experience. It was proposed in EIP-2612, has been incorporated into the Ethereum standard, and is used by tokens such as `USDC`, `ARB`, etc.

## ERC20

We introduced ERC20, the most popular token standard in Ethereum, in [Lecture 31](https://github.com/WTFAcademy/WTF-Solidity/blob/main/Languages/en/31_ERC20_en/readme.md). One of the main reasons for its popularity is that the two functions `approve` and `transferFrom` are used together so that tokens can not only be transferred between externally owned accounts (EOA) but can also be used by other contracts.

However, the `approve` function of ERC20 is restricted to be called only by the token owner, which means that all initial operations of `ERC20` tokens must be performed by `EOA`. For example, if user A uses `USDT` to exchange `ETH` on a decentralized exchange, two transactions must be completed: in the first step, user A calls `approve` to authorize `USDT` to the contract, and in the second step, user A calls `approve` to authorize `USDT` to the contract. Contracts are exchanged. Very cumbersome, and users must hold `ETH` to pay for the gas of the transaction.

## ERC20Permit

EIP-2612 proposes ERC20Permit, which extends the ERC20 standard by adding a `permit` function that allows users to modify authorization through EIP-712 signatures instead of through `msg.sender`. This has two benefits:

1. The authorization step only requires the user to sign off the chain, reducing one transaction.
2. After signing, the user can entrust a third party to perform subsequent transactions without holding ETH: User A can send the signature to a third party B who has gas, and entrust B to execute subsequent transactions.

![](./img/53-1.png)

## Contract

### IERC20Permit interface contract

First, let us study the interface contract of ERC20Permit, which defines 3 functions:

- `permit()`: Authorize the ERC20 token balance of `owner` to `spender` according to the signature of `owner`, and the amount is `value`. Require:
 
     - `spender` cannot be a zero address.
     - `deadline` must be a timestamp in the future.
     - `v`, `r` and `s` must be valid `secp256k1` signatures of the `owner` on function arguments in EIP712 format.
     - The signature must use the current nonce of the `owner`.


- `nonces()`: Returns the current nonce of `owner`. This value must be included every time you generate a signature for the `permit()` function. Each successful call to the `permit()` function will increase the `owner` nonce by 1 to prevent the same signature from being used multiple times.

- `DOMAIN_SEPARATOR()`: Returns the domain separator used to encode the signature of the `permit()` function, such as [EIP712](https://github.com/AmazingAng/WTF-Solidity/blob/main /52_EIP712/readme.md).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC20 Permit extended interface that allows approval via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
  */
interface IERC20Permit {
     /**
      * @dev Authorizes `owner`’s ERC20 balance to `spender` based on the owner’s signature, the amount is `value`
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
     *@dev Returns the current nonce of `owner`. This value must be included every time you generate a signature for {permit}.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used to encode the signature of {permit}
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
```

### ERC20Permit Contract

Next, let us write a simple ERC20Permit contract, which implements all interfaces defined by IERC20Permit. The contract contains 2 state variables:

- `_nonces`: `address -> uint` mapping, records the current nonce values of all users,
- `_PERMIT_TYPEHASH`: Constant, records the type hash of the `permit()` function.

The contract contains 5 functions:

- Constructor: Initialize the `name` and `symbol` of the token.
- **`permit()`**: The core function of ERC20Permit, which implements the `permit()` of IERC20Permit. It first checks whether the signature has expired, then restores the signed message using `_PERMIT_TYPEHASH`, `owner`, `spender`, `value`, `nonce`, and `deadline` and verifies whether the signature is valid. If the signature is valid, the `_approve()` function of ERC20 is called to perform the authorization operation.
- `nonces()`: Implements the `nonces()` function of IERC20Permit.
- `DOMAIN_SEPARATOR()`: Implements the `DOMAIN_SEPARATOR()` function of IERC20Permit.
- `_useNonce()`: A function that consumes `nonce`, returns the user's current `nonce`, and increases it by 1.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/*** @dev ERC20 Permit extended interface that allows approval via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
  *
  * Added {permit} method to change an account's ERC20 balance via a message signed by the account (see {IERC20-allowance}). By not relying on {IERC20-approve}, token holders' accounts do not need to send transactions and therefore do not need to hold Ether at all.
 */
contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev initializes the name of EIP712 and the name and symbol of ERC20
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
        // Check deadline
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        // Splice Hash
         bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
         bytes32 hash = _hashTypedDataV4(structHash);
        
         // Calculate the signer from the signature and message, and verify the signature
         address signer = ECDSA.recover(hash, v, r, s);
         require(signer == owner, "ERC20Permit: invalid signature");
        
         //Authorize
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
     * @dev "Consumption nonce": Returns the current `nonce` of the `owner` and increases it by 1.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }
}
```

## Remix Reappearance

1. Deploy the `ERC20Permit` contract and set both `name` and `symbol` to `WTFPermit`.

2. Run `signERC20Permit.html` and change the `Contract Address` to the deployed `ERC20Permit` contract address. Other information is given below. Then click the `Connect Metamask` and `Sign Permit` buttons in sequence to sign, and obtain `r`, `s`, and `v` for contract verification. To sign, use the wallet that deploys the contract, such as the Remix test wallet:

    ```js
    owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4    spender: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    value: 100
    deadline: 115792089237316195423570985008687907853269984665640564039457584007913129639935
    private_key: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
    ```

![](./img/53-2.png)


3. Call the `permit()` method of the contract, enter the corresponding parameters, and authorize.

4. Call the `allance()` method of the contract, enter the corresponding `owner` and `spender`, and you can see that the authorization is successful.

## Safety Note

ERC20Permit uses off-chain signatures for authorization, which brings convenience to users but also brings risks. Some hackers will use this feature to conduct phishing attacks to deceive user signatures and steal assets. A signature [phishing attack] (https://twitter.com/0xAA_Science/status/1652880488095440897?s=20) targeting USDC in April 2023 caused a user to lose 228w u of assets.

**When signing, be sure to read the signature carefully! **

## Summary

In this lecture, we introduced ERC20Permit, an extension of the ERC20 token standard, which supports users to use off-chain signatures for authorization operations, improves user experience, and is adopted by many projects. But at the same time, it also brings greater risks, and your assets can be swept away with just one signature. Everyone must be more careful when signing.
