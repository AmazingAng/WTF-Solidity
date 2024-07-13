// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract InitialValue {
    // Value Types（値型）
    bool public _bool; // false
    string public _string; // ""
    int public _int; // 0
    uint public _uint; // 0
    address public _address; // 0x0000000000000000000000000000000000000000

    enum ActionSet { Buy, Hold, Sell}
    ActionSet public _enum; // first element 0（最初の要素は0です）

    function fi() internal{} // internal blank equation （internalな空の関数）
    function fe() external{} // external blank equation （externalな空の関数）

    // Reference Types
    uint[8] public _staticArray; // A static array which all members set to their default values[0,0,0,0,0,0,0,0]
                                 // 全てのメンバーがデフォルトの初期値[0,0,0,0,0,0,0,0]に設定された静的配列
    uint[] public _dynamicArray; // `[]`
    mapping(uint => address) public _mapping; // A mapping which all members set to their default values
                                              // 全てのメンバーがデフォルト値に設定されたマッピング
    // A struct which all members set to their default values 0, 0（全てのメンバーがデフォルト値0, 0に設定された構造体）
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student public student;

    // delete operator（delete演算子）
    bool public _bool2 = true; 

    function d_bool() external {    
        delete _bool2; // delete will make _bool2 change to default(false)（deleteは_bool2をデフォルト値(false)に変更します）
    }

    function d_address() external {
        delete _address; // delete will make _bool2 change to default(false)（deleteは_bool2をデフォルト値(false)に変更します）
    }

    function d_enum() external {
        delete _enum; // delete will make _bool2 change to default(false)（deleteは_bool2をデフォルト値(false)に変更します）
    }

    function d_student() external {
        delete student; // delete will make _bool2 change to default(false)（deleteは_bool2をデフォルト値(false)に変更します）
    }

    function d_staticArray() external {
        delete _staticArray; // delete will make _bool2 change to default(false)（deleteは_bool2をデフォルト値(false)に変更します）
    }

}