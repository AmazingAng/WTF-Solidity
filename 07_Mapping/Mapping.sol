// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Mapping {
    mapping(uint256 => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址

    // 规则1. _KeyType不能是非值类型 下面这个例子会报错
    // 我们定义一个结构体 Struct
    // struct Student{
    //    uint256 id;
    //    uint256 score;
    //}
    // mapping(Struct => uint) public testVar;

    function getValueMap(uint256 _Key) external view returns (address) {
        // 规则2 存储位置必须是storage,下面会报错
        // mapping(uint => address) memory testVar;

        // 规则3 可以通过key查询Value 验证:可通过下面下面writeMap方法设置后在调用
        return idToAddress[_Key];
    }

    function writeMap(uint256 _Key, address _Value) public {
        //规则4 给映射新增的键值对
        idToAddress[_Key] = _Value;
    }
}
