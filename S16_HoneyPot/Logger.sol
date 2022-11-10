// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//日志器合约，不会被部署
contract Logger {
    event Log(address caller, string action);
    function log(
        address _caller,
        string memory _action
    ) public {
        emit Log(_caller, _action);
    }
}