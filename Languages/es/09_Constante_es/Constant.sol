// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Constant {
	// Una variable de tipo constante debe ser inicializada cuando es declarada, ya que después no se puede modificar
    uint256 public constant CONSTANT_NUM = 10;
    string public constant CONSTANT_STRING = "0xAA";
    bytes public constant CONSTANT_BYTES = "WTF";
    address public constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
	
	// Las variables inmutables pueden ser inicializadas en el constructor y no se pueden modificar después
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;

	// Las variables inmutables son inicializadas en el constructor, por lo que se pueden usar en el resto del contrato
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
