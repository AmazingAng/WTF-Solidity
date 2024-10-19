// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Constant {
	// The constant variable must be initialized when declared and cannot be changed after that
    //（constant変数は宣言時に初期化され、その後で変更することは出来ない）
    uint256 public constant CONSTANT_NUM = 10;
    string public constant CONSTANT_STRING = "0xAA";
    bytes public constant CONSTANT_BYTES = "WTF";
    address public constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
	
	// The immutable variable can be initialized in the constructor and cannot be changed after that
    //（immutable変数はコントラクターにおいて初期化され、その後で変更することは出来ない）
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;

	// The immutable variables are initialized with constructor, so that could use
    //（immutable変数はコンストラクターを用いて初期化されるので、次のようにすることが出来る）
    constructor(){
        IMMUTABLE_ADDRESS = address(this);
        IMMUTABLE_BLOCK = block.number;
        IMMUTABLE_TEST = test();
    }

    function test() public pure returns(uint256){
        uint256 what = 9;
        return(what);
    }
}
