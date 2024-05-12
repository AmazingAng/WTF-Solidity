// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

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
