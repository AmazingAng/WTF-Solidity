// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Convierte un `uint256` a su representación decimal ASCII `string`.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspirado en la implementación de OraclizeAPI - licencia MIT
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Convierte un `uint256` a su representación hexadecimal ASCII `string`.
     */
    function toHexString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Convierte un `uint256` a su representación hexadecimal ASCII `string` con longitud fija.
     */
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: insuficiente longitud hexadecimal");
        return string(buffer);
    }
}


// Llamando a otro contrato de biblioteca con una función
contract UseLibrary{    
    // Usando la biblioteca con el comando "using for" 
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        // Las funciones de la biblioteca se agregan automáticamente como miembros de las variables de tipo uint256
        return _number.toHexString();
    }

    // Llamado directamente por el nombre del contrato 
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }
}
