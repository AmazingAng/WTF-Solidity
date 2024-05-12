// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Base1 {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}

contract Identifier is Base1 {

    //计算一个数分别被2除和被3除的值，但是传入的参数必须是2和3的倍数
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    //计算一个数分别被2除和被3除的值
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }

    //重写Modifier: 不重写时，输入9调用getExactDividedBy2And3，会revert，因为无法通过检查
    //删掉下面三行注释重写Modifier，这时候输入9调用getExactDividedBy2And3， 会调用成功
    // modifier exactDividedBy2And3(uint _a) override {
    //     _;
    // }
}

