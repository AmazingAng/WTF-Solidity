// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OtherContract {
    uint256 private _x = 0; // 状態変数x
    // ethを受け取るイベント、amountやgasを記録

    event Log(uint256 amount, uint256 gas);

    // contractの残高を示す
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 状態変数の_xを設定できる。ETHも送金できる(payable)
    function setX(uint256 x) external payable {
        _x = x;
        // もしETHを送金したら、Logイベントを発行
        if (msg.value > 0) {
            emit Log(msg.value, gasleft());
        }
    }

    // xの値を取得
    function getX() external view returns (uint256 x) {
        x = _x;
    }
}

contract CallContract {
    function callSetX(address _Address, uint256 x) external {
        OtherContract(_Address).setX(x);
    }

    function callGetX(OtherContract _Address) external view returns (uint256 x) {
        x = _Address.getX();
    }

    function callGetX2(address _Address) external view returns (uint256 x) {
        OtherContract oc = OtherContract(_Address);
        x = oc.getX();
    }

    function setXTransferETH(address otherContract, uint256 x) external payable {
        OtherContract(otherContract).setX{value: msg.value}(x);
    }
}
