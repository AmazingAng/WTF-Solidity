// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Selector{
    // event 返回msg.data
    event Log(bytes data);

    // 输入参数 to: 0x2c44b726ADF1963cA47Af88B284C06f30380fC78
    function mint(address to) external{
        emit Log(msg.data);
    } 

    // 输出selector
    // "mint(address)"： 0x6a627842
    function mintSelector() external pure returns(bytes4 mSelector){
        return bytes4(keccak256("mint(address)"));
    }

    // 使用selector来调用函数
    function callWithSignature() external returns(bool, bytes memory){
        // 只需要利用`abi.encodeWithSelector`将`mint`函数的`selector`和参数打包编码
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0x6a627842, "0x2c44b726ADF1963cA47Af88B284C06f30380fC78"));
        return(success, data);
    }
}
