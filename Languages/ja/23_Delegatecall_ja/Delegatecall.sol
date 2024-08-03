// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// delegatecallはcallと似ており、低レベル関数である
// callの場合、BがCをcallすると、コンテキストはCとなる。（msg.sender = B, Cの中の状態変数は影響を受ける）
// delegatecallの場合、BがCをdelegatecallすると、コンテキストはBとなる。（msg.sender = A, Bの中の状態変数が影響を受ける）
// 注意B和C的数据存储布局必须相同！变量类型、声明的前后顺序要相同，不然会搞砸合约。
// 注意したいのは、B, Cにあるストレージのストラクチャが同じでなければならないこと。そうでないとごちゃまぜになってしまいます。

// 呼び出されるコントラクトC
contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}

// delegatecallをする側のコントラクトB
contract B {
    uint public num;
    address public sender;

    // callを通じてCコントラクトを呼び出すと、Cのストレージが影響を受ける
    function callSetVars(address _addr, uint _num) external payable{
        // call setVars()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
    // delegatecallを通じてCのsetVars()関数を呼び出し、コントラクトBの状態変数が変更される
    function delegatecallSetVars(address _addr, uint _num) external payable{
        // delegatecall setVars()
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
