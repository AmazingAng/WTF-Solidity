// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./console.sol";
import "./console2.sol";
import "./StdJson.sol";

abstract contract Script {
    bool public IS_SCRIPT = true;
    address constant private VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    Vm public constant vm = Vm(VM_ADDRESS);

    /// @dev Calcula o endereço em que um contrato será implantado para um determinado endereço de implantação e nonce
    /// @aviso adaptado da implementação Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
    function computeCreateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        // O inteiro zero é tratado como uma string de bytes vazia e, como resultado, possui apenas um prefixo de comprimento, 0x80, calculado através de 0x80 + 0.
        // Um inteiro de um byte usa seu próprio valor como prefixo de comprimento, não há um prefixo adicional "0x80 + comprimento" que o precede.
        if (nonce == 0x00)             return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))));
        if (nonce <= 0x7f)             return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))));

        // Nonces maiores que 1 byte seguem um esquema de codificação consistente, onde cada valor é precedido por um prefixo de 0x80 + comprimento.
        if (nonce <= 2**8 - 1)  return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))));
        if (nonce <= 2**16 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))));
        if (nonce <= 2**24 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))));

        // Mais detalhes sobre a codificação RLP podem ser encontrados aqui: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (prefixo RLP curto) + 0x16 (comprimento de: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = o comprimento de um endereço, 20 bytes, em hexadecimal)
        // 0x84 = 0x80 + 0x04 (0x04 = o comprimento dos bytes do nonce, 4 bytes, em hexadecimal)
        // Assumimos que ninguém pode ter um nonce grande o suficiente para exigir mais de 32 bytes.
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce))));
    }

    function addressFromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function deriveRememberKey(string memory mnemonic, uint32 index) internal returns (address who, uint256 privateKey) {
        privateKey = vm.deriveKey(mnemonic, index);
        who = vm.rememberKey(privateKey);
    }
}
