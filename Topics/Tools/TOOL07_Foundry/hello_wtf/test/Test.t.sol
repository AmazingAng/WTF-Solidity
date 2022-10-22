// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";
// 导入IERC20的接口，通过该接口可以调用对应的方法
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IERC20Test is Test {
  // 声明Counter合约对象变量
  Counter public counter;
  // 声明一个地址变量
  address public alice;
  // 声明一个msgSender
  address public msgSender;
  // 声明帮助合约函数
  Helper public h;

  //定义一个IERC20 合约对象
  IERC20 public dai;


   event  MyEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 d, uint256 e);

  function setUp() public {
    // new测试合约对象
    counter = new Counter();
    // 调用对象方法
    counter.setNumber(0);
    // new helper对象
    h = new Helper();

    alice = address(10086);
    console2.log(alice);
    // 通过 vm.envAddress 获取环境变量中的地址
    dai = IERC20(vm.envAddress("DAI"));
  }


  // 测试给合约地址转账
  function testCheatCode() public {
    console2.log("before:", dai.balanceOf(alice));
    deal(address(dai), alice,1 ether);
    console2.log("after:", dai.balanceOf(alice));
  }
  // 测试改变合约msg.sender
  function testCheatAddress() public {
    console2.log("before:", h.whoCalled());
    vm.prank(address(1));
    console2.log("after:", h.whoCalled());
  }

  function testCodeFork() public {
    console2.log(address(dai));
    string memory rpc = vm.envString("ETH_RPC_URL");
    uint256 mainnet = vm.createFork(rpc);
    vm.selectFork(mainnet);
    // 这边下面开始就是直接fork网络了
    console2.log("before:",dai.balanceOf(alice));
    deal(address(dai),alice,1 ether);
    console2.log("after:",dai.balanceOf(alice));
  }

  function testEmit() public {
    vm.expectEmit(true,true,true,true);
    emit MyEvent(1,2,3,4,5);
    h.emitIt();
  }

}


contract Helper {

  event  MyEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 d, uint256 e);

  function whoCalled() public view returns (address) {
    return msg.sender;
  }

  function emitIt() public {
    emit MyEvent(1,2,3,4,5);
  }

}