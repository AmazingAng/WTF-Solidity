// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Hash {
    bytes32 _msg = keccak256(abi.encodePacked("0xAA"));

    // Identificador único
    function hash(
        uint _num,
        string memory _string,
        address _addr
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num, _string, _addr));
    }

    // Debil resistencia a colisiones
    function weak(string memory string1) public view returns (bool) {
        return keccak256(abi.encodePacked(string1)) == _msg;
    }

    // Fuerte resistencia a colisiones
    function strong(string memory string1, string memory string2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(string1)) ==
            keccak256(abi.encodePacked(string2));
    }
}
