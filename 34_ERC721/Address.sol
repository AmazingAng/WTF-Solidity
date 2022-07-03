// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Address库
library Address {
    // 利用extcodesize判断一个地址是否为合约地址
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
