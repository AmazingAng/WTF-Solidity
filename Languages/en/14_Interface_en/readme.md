---
title: 14. Abstract and Interfaces
tags:
  - solidity
  - basic
  - wtfacademy
  - abstract
  - interface
---

# WTF Solidity Tutorial: 14. Abstract and Interfaces

Recently, I have been relearning Solidity, consolidating the finer details, and also writing a "WTF Solidity Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord, where you can find the way to join WeChat group: [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this section, we use the interface contract of `ERC721` as an example to introduce the `abstract` and `interface` in `solidity` to help you better understand the `ERC721` standard.

## Abstract

If there is at least one unimplemented function in a smart contract, that is, a function lacks the content in the body `{}`, 
the contract must be marked as `abstract`, otherwise the compilation will report an error; in addition, the unimplemented function requires `virtual` for subcontract rewriting. 
Take our previous [Insertion Sort Contract](https://github.com/AmazingAng/WTFSolidity/tree/main/07_InsertionSort) as an example, 
if we haven't figured out how to implement the insertion sort function, we can mark the contract as `abstract`, and then let others write it.

```solidity
abstract contract InsertionSort{
    function insertionSort(uint[] memory a) public pure virtual returns(uint[] memory);
}
```
## Interface

The `interface` is similar to an `abstract`, but it does not implement any functionality. Rules of Interface are as follows:

1. Cannot contain state variables
2. Cannot contain constructors
3. Cannot inherit other contracts except interfaces
4. All functions must be external and cannot have a function body
5. The contract that inherits the interface must implement all the functions defined by the interface

Although the interface does not implement any functionality, it is very important. An interface is the skeleton of a smart contract, 
defining what the contract does and how to trigger them: if a smart contract implements some kind of interface (like `ERC20` or `ERC721`), 
other Dapps and smart contracts know how to interact with it. Because the interface provides two important pieces of information:

1. The `bytes4` selector for each function in the contract, and the `function name (per parameter type)` based on their function signature.
2. Interface id (see [EIP165](https://eips.ethereum.org/EIPS/eip-165) for more information)

In addition, the interface is equivalent to the contract `ABI` (Application Binary Interface), 
and they can converte to each other: compiling the interface can get the `ABI` of the contract, 
using the [abi-to-sol tool](https://gnidan.github.io/ abi-to-sol/) can also convert `ABI json` files to `interface sol` files.

We take the `ERC721` interface contract `IERC721` as an example, it defines 3 `event` and 9 `function`, 
which is implemented by all `ERC721` standard NFT. We can see that the difference between an interface and a regular contract is that 
each function ends with `;` instead of the function body `{ }`.

```solidity
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data) external;
}
```

### IERC721 Event
`IERC721` contains 3 events, of which `Transfer` and `Approval` events are also available in `ERC20`.
- `Transfer` event: Released during transfer, records the sending address `from`, the receiving address `to` and `tokenid`.
- `Approval` event: Released upon authorization, record the authorization address `owner`, the authorized address `approved` and `tokenid`.
- `ApprovalForAll` event: Released during batch authorization, record the issuing address `owner` of batch authorization, the authorized address `operator` and the `approved` of authorization or not.

### IERC721 Function
- `balanceOf`：Returns the NFT holding `balance` of an address.
- `ownerOf`：Returns the owner `owner` of a `tokenId`.
- `transferFrom`：For ordinary transfers, the parameters are the outgoing address `from`, the receiving address `to` and `tokenId`.
- `safeTransferFrom`：Secure transfer (if the receiver is a contract address, it will be required to implement the `ERC721Receiver` interface). The parameters are the outgoing address `from`, the receiving address `to` and `tokenId`.
- `approve`：Authorize another address to use your NFT. The parameters are the authorized address `approve` and `tokenId`.
- `getApproved`: Query to which address the `tokenId` was approved.
- `setApprovalForAll`: Authorize the series of NFTs you hold to an address `operator` in batches.
- `isApprovedForAll`: Query whether the NFT of an address is authorized to another `operator` address in batches.
- `safeTransferFrom`: Overloaded function for safe transfer, which parameter contains `data`.


### When to use an interface?
If we know that a contract implements the `IERC721` interface, we can interact with it without knowing its specific code implementation.

The Bored Ape Yacht Club `BAYC` belongs to the `ERC721` token and implements the function of the `IERC721` interface. 
We don't need to know its source code, just know its contract address, and use the `IERC721` interface to interact with it. 
For example, use `balanceOf()` to query the `BAYC` balance of an address, or use `safeTransferFrom( )` to transfer `BAYC`.


```solidity
contract interactBAYC {
    // Use BAYC address to create interface contract variables (ETH Mainnet)
    IERC721 BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    // Call BAYC's balanceOf() to query the open interest through the interface
    function balanceOfBAYC(address owner) external view returns (uint256 balance){
        return BAYC.balanceOf(owner);
    }

    // Safe transfer by calling BAYC's safeTransferFrom() through the interface
    function safeTransferFromBAYC(address from, address to, uint256 tokenId) external{
        BAYC.safeTransferFrom(from, to, tokenId);
    }
}
```

## Remix demo
- Abstract example (simple demo code as shown)
  ![14-1](./img/14-1.png)
- Interface example (simple demo code as shown)
  ![14-2](./img/14-2.png)

## Summary
In this lecture, I introduce the `abstract` and `interface` in `solidity`, which can write templates and reduce code redundancy.
We also talk about the `ERC721` interface contract `IERC721` and how to use it to interact with the `BAYC` contract.
