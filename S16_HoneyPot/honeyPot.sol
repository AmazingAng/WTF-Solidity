// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//这段合约代码位于一个单独的文件中，使得其他人无法读取它
contract HoneyPot {
    function log(
        address _caller,
        string memory _action
    ) public pure {
        //如果用户调用`transfer()`函数，强制回滚
        if (equal(_action, "transfer")) {
            revert("untransferable!");
        }
    }

    // 用keccak256比较字符串
    function equal(string memory _a, string memory _b) public pure returns (bool) {
        return keccak256(abi.encode(_a)) == keccak256(abi.encode(_b));
    }
}