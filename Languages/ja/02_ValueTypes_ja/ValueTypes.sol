// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract ValueTypes{
    // Boolean（真偽値型）
    bool public _bool = true;
    // Boolean operators（論理演算子）
    bool public _bool1 = !_bool; // logical NOT　　　　　（否定）
    bool public _bool2 = _bool && _bool1; // logical AND（論理積）
    bool public _bool3 = _bool || _bool1; // logical OR （論理和）
    bool public _bool4 = _bool == _bool1; // equality  （等価）
    bool public _bool5 = _bool != _bool1; // inequality（不等価）


    // Integer（整数型）
    int public _int = -1;
    uint public _uint = 1;
    uint256 public _number = 20220330;
    // Integer operators（整数型の演算子）
    uint256 public _number1 = _number + 1; // +，-，*，/
    uint256 public _number2 = 2**2; // exponent　　　　　（べき乗）
    uint256 public _number3 = 7 % 2; // modulo (modulus)（剰余(モジュロ)）
    bool public _numberbool = _number2 > _number3; // greater than（大なり）


    // Address data type（アドレス型）
    address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    address payable public _address1 = payable(_address); // payable address (allows for token transfer and balance checking)
                                                          //（ペイアブルなアドレス(トークンの移動や残高の確認が可能)）
    // Members of addresses（アドレスのメンバ）
    uint256 public balance = _address1.balance; // balance of address（アドレスの残高）
    
    
    // Fixed-size byte arrays（固定長配列）
    bytes32 public _byte32 = "MiniSolidity"; // bytes32: 0x4d696e69536f6c69646974790000000000000000000000000000000000000000
    bytes1 public _byte = _byte32[0]; // bytes1: 0x4d
    
    
    // Enumeration（列挙型）
    // Let uint 0， 1， 2 represent Buy, Hold, Sell（uint型の0,1,2がBuy,Hold,Sellを表すとする）
    enum ActionSet { Buy, Hold, Sell }
    // Create an enum variable called action（actionという列挙型変数を作成）
    ActionSet action = ActionSet.Buy;

    // Enum can be converted into uint（列挙型はuint型に変換出来る）
    function enumToUint() external view returns(uint){
        return uint(action);
    }
}

