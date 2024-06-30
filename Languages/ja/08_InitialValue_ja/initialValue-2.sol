// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract InitialValue {

    bool public _bool2 = true;

    address public _address = address(1);

    enum ActionSet { Buy, Hold, Sell}
    ActionSet public _enum = ActionSet.Buy;

    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student public student = Student(10, 255);
    
    uint[8] public _staticArray = [1, 2, 3, 4, 5, 6, 7, 8];

    function d_bool() external {    
        delete _bool2; // delete will make _bool2 change to default(false)
                       //（deleteは_bool2をデフォルト値(false)に変更します）
    }
    
    function d_address() external {
        delete _address; // delete will make _address change to default(address(0))
                         //（deleteは_addressをデフォルト値(address(0))に変更します）
    }

    function d_enum() external {
        delete _enum; // delete will make _enum change to default(The subscript(0) of the first enumeration(Buy))
                      //（deleteは_enumをデフォルト値(最初の列挙型(Buy)の添え字(0))に変更します）
    }

    function d_student() external {
        delete student; // delete will make student change to default(student(0,0))
                        //（deleteはstudentをデフォルト値(student(0,0))に変更します）
    }

    function d_staticArray() external {
        delete _staticArray; // delete will make _staticArray change to default([0, 0, 0, 0, 0, 0, 0, 0])
                             //（deleteは_staticArrayをデフォルト値([0, 0, 0, 0, 0, 0, 0, 0])に変更します）
    }


}