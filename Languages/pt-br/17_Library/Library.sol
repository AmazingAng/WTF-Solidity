// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converte um `uint256` para sua representação decimal em `string` ASCII.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspirado na implementação da OraclizeAPI - licença MIT
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
     * @dev Converte um `uint256` para sua representação hexadecimal em `string` ASCII.
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
     * @dev Converte um `uint256` para sua representação hexadecimal `string` ASCII com comprimento fixo.
     */
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// Usando uma função para chamar um contrato de biblioteca externa
contract UseLibrary{    
    // Usando a instrução 'using' para utilizar uma biblioteca
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        // A biblioteca de funções adicionará automaticamente membros para variáveis do tipo uint256.
        return _number.toHexString();
    }

    // Chamada direta pelo nome do contrato da biblioteca
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }
}
