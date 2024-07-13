// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Hash {
    bytes32 _msg = keccak256(abi.encodePacked("0xAA"));

    // ユニークな識別子
    function hash(uint256 _num, string memory _string, address _addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num, _string, _addr));
    }

    // 弱い抗衝突性

    function weak(string memory string1) public view returns (bool) {
        return keccak256(abi.encodePacked(string1)) == _msg;
    }

    // 強い抗衝突性
    function strong(string memory string1, string memory string2) public pure returns (bool) {
        return keccak256(abi.encodePacked(string1)) == keccak256(abi.encodePacked(string2));
    }
}
