// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Base1 {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}

contract Identifier is Base1 {

    // Calculate the value of a number divided by 2 and divided by 3, respectively, but the parameters passed in must be multiples of 2 and 3
    //（2で除算された数値と3で除算された数値をそれぞれ計算しますが、渡される引数は2と3の倍数でなければなりません）
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    // Calculate the value of a number divided by 2 and divided by 3, respectively
    //（2で除算された数値と3で除算された数値をそれぞれ計算します）
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }


    // Rewrite the modifier: when not rewriting, enter 9 to call getExactDividedBy2And3, it will be reverted because it cannot pass the check
    // Delete the following three lines of comments and rewrite the modifier function. At this time, enter 9 to call getExactDividedBy2And3, and the call will be successful.
    //（修飾子を書き換える: 書き換えない時には、getExactDividedBy2And3を呼び指す際に9を入れます。そうすればチェックを通らないので、リバーとされます。）
    //（次の3行のコメントを消して、修飾子関数を書き換えてください。この時にはgetExactDividedBy2And3に9を代入すれば、呼び出しは成功するでしょう。）
    
    // modifier exactDividedBy2And3(uint _a) override {
    //     _;
    // }
}

