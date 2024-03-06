// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {
        console2.log("setup ");
    }

    function run() public {
        vm.startBroadcast();

        Counter c = new Counter();

        vm.stopBroadcast();
    }

    // function someFunction(uint256 x) public {
    //     console2.log("alguma outra func");
    //     console2.log(x);
    // }
}
