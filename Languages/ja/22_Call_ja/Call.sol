// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OtherContract {
    uint256 private _x = 0; // 状態変数_x
    // ethを受け取るイベント、amountとgasを記録

    event Log(uint256 amount, uint256 gas);

    fallback() external payable {}

    // コントラクトのETH残高を返す関数
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // _xの値を設定できる関数。同時にコントラクトへETHを送信することもできる(payable)
    function setX(uint256 x) external payable {
        _x = x;
        // もしETHの送信がある場合のみLogイベントを放出
        if (msg.value > 0) {
            emit Log(msg.value, gasleft());
        }
    }

    // xの値を取得する関数
    function getX() external view returns (uint256 x) {
        x = _x;
    }
}

contract Call {
    // Response イベントは`call`の結果`success`と`data`を出力します
    event Response(bool success, bytes data);

    function callSetX(address payable _addr, uint256 x) public payable {
        // setX()をcallし、ETHを送信
        (bool success, bytes memory data) = _addr.call{value: msg.value}(abi.encodeWithSignature("setX(uint256)", x));

        emit Response(success, data); // イベントを放出
    }

    function callGetX(address _addr) external returns (uint256) {
        // call getX()
        (bool success, bytes memory data) = _addr.call(abi.encodeWithSignature("getX()"));

        emit Response(success, data); // イベントを放出
        return abi.decode(data, (uint256));
    }

    function callNonExist(address _addr) external {
        // 存在しない関数を呼び出す
        (bool success, bytes memory data) = _addr.call(abi.encodeWithSignature("foo(uint256)"));

        emit Response(success, data); // イベントを放出
    }
}
