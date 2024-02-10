// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Address Lib
library Address {
    // Uses extcodesize to determine whether an address is a contract address or not。
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
