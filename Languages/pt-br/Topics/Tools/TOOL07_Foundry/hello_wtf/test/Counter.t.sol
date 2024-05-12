// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "../src/Counter.sol";



contract CounterTest is Test {
    Counter public counter;
    uint256 public testNumber;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
        testNumber = 42;
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        console2.log("testNumber: %s==============", x);
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testNumberIs42() public {
        emit log("test");
        assertEq(testNumber, 42);
    }
}
