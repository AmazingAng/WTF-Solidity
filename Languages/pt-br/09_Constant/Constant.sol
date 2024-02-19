// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Constant {
    // As constantes devem ser inicializadas no momento da declaração e não podem ser alteradas posteriormente.
    uint256 public constant CONSTANT_NUM = 10;
    string public constant CONSTANT_STRING = "0xAA";
    bytes public constant CONSTANT_BYTES = "WTF";
    address public constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;

    // As variáveis imutáveis podem ser inicializadas no construtor e não podem ser alteradas posteriormente.
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;

    // Utilizando o construtor para inicializar variáveis imutáveis, portanto é possível utilizar
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
