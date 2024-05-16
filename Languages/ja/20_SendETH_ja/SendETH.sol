// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 3つの方法でETHを送金
// transfer: 2300 gas, revert
// send: 2300 gas, return bool
// call: all gas, return (bool, data)

error SendFailed(); // send関数の失敗error
error CallFailed(); // call関数の失敗error

contract SendETH {
    // payableなコンストラクター、デプロイ時にETHを送金できる
    constructor() payable {}
    // receive()関数は、コントラクトにETHを送信するときに呼び出される
    receive() external payable {}

    // transfer関数でETHを送金
    function transferETH(address payable _to, uint256 amount) external payable {
        _to.transfer(amount);
    }

    // send関数でETHを送金
    function sendETH(address payable _to, uint256 amount) external payable {
        // send()関数が失敗した場合、返り値の処理をしてrevertさせて、errorを放出
        bool success = _to.send(amount);
        if (!success) {
            revert SendFailed();
        }
    }

    // call()関数でETHを送金
    function callETH(address payable _to, uint256 amount) external payable {
        // call関数の返り値を処理し、失敗した場合、revertしてerrorを放出
        (bool success,) = _to.call{value: amount}("");
        if (!success) {
            revert CallFailed();
        }
    }
}

contract ReceiveETH {
    // ETHを受け取るときにイベントを発生させ、amountとgasを記録
    event Log(uint256 amount, uint256 gas);

    // receive関数は、コントラクトにETHを送信するときに呼び出される
    receive() external payable {
        emit Log(msg.value, gasleft());
    }

    // この関数は、コントラクトのETH残高を返す
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
