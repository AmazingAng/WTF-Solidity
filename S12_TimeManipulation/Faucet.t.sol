// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Faucet.sol";

contract FaucetTest is Test {
    ERC20 public wtf;

    // Computes address for a given private key
    address alice = vm.addr(1);

    function setUp() public {
        wtf = new ERC20("WTF","WTF");
    }

    function testName() external {
        assertEq("WTF", wtf.name());
    }
    // forge test -vv --match-test  testRoulette
    function testMint() public {
        // Set block.timestamp
        vm.warp(6);
        console.log("block.timestamp % 7 != 0");
        // Sets all subsequent calls' msg.sender to be the input address
        // until `stopPrank` is called
        vm.startPrank(alice);
        console.log("token name: %s", wtf.name());
        console.log("alice balance after: %s", wtf.balanceOf(alice));
        wtf.mint(10000);
        console.log("alice balance after: %s", wtf.balanceOf(alice));
        // Resets subsequent calls' msg.sender to be `address(this)`

        console.log("block.timestamp % 7 == 0");
        vm.warp(7);
        console.log("token name: %s", wtf.name());
        console.log("alice balance after: %s", wtf.balanceOf(alice));
        wtf.mint(10000);
        console.log("alice balance after: %s", wtf.balanceOf(alice));
        vm.stopPrank();
    }
}
