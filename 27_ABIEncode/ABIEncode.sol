// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract ABIEncode{
    uint x = 10;
    address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    string name = "0xAA";
    uint[2] array = [5, 6]; 

    function encode() public view returns(bytes memory result) {
        result = abi.encode(x, addr, name, array);
    }

    function encodePacked() public view returns(bytes memory result) {
        result = abi.encodePacked(x, addr, name, array);
    }

    // 动态类型没有边界时，encodePacked 可能把不同输入拼成同一字节序列
    function collisionPacked() public pure returns(bool) {
        return keccak256(abi.encodePacked("ab", "c")) == keccak256(abi.encodePacked("a", "bc"));
    }

    // abi.encode 保留类型和长度边界，适合为动态参数构造哈希
    function safeHash() public pure returns(bool) {
        return keccak256(abi.encode("ab", "c")) != keccak256(abi.encode("a", "bc"));
    }

    function encodeWithSignature() public view returns(bytes memory result) {
        result = abi.encodeWithSignature("foo(uint256,address,string,uint256[2])", x, addr, name, array);
    }

    function encodeWithSelector() public view returns(bytes memory result) {
        result = abi.encodeWithSelector(bytes4(keccak256("foo(uint256,address,string,uint256[2])")), x, addr, name, array);
    }
    function decode(bytes memory data) public pure returns(uint dx, address daddr, string memory dname, uint[2] memory darray) {
        (dx, daddr, dname, darray) = abi.decode(data, (uint, address, string, uint[2]));
    }
}
