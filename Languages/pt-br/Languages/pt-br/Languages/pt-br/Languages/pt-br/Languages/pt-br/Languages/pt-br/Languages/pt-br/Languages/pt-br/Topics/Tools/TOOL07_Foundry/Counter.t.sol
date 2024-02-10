// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";        // 引入 forge-std 中用于测试的依赖
import "../src/Counter.sol";        // 引入用于测试的业务合约

// 基于 forge-std 的 test 合约依赖实现测试用例
contract CounterTest is Test {      
    Counter public counter;

    // 初始化测试用例
    function setUp() public { 
       counter = new Counter();
       counter.setNumber(0);
    }

    // 基于初始化测试用例
    // 断言测试自增后的 counter 的 number 返回值 同等于 1
    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    // 基于初始化测试用例
    // 执行差异测试测试
    // forge 测试的过程中
    // 为 testSetNumber 函数参数传递不同的 unit256 类型的 x
    // 达到测试 counter 的 setNumber 函数 为不同的 x 设置不同的数
    // 断言 number() 的返回值等同于差异测试的 x 参数
    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // 差异测试：参考 https://book.getfoundry.sh/forge/differential-ffi-testing
}