// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Storage {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    bytes32 private DOMAIN_SEPARATOR;
    uint256 number;
    address owner;

    constructor(){
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            // type hash
            // name
            // versão
            // chain id
            // endereço do contrato
        ));
        owner = msg.sender;
    }

    /**
     * @dev Armazena o valor na variável
     */
    function permitStore(uint256 _num, bytes memory _signature) public {
        // Verificando o comprimento da assinatura, 65 é o comprimento padrão da assinatura r,s,v.
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Atualmente, só é possível obter os valores r, s e v da assinatura usando assembly (inline assembly).
        assembly {
            /*
            Os primeiros 32 bytes armazenam o comprimento da assinatura (regra de armazenamento de array dinâmico)
            add(sig, 32) = ponteiro de sig + 32
            Equivalente a pular os primeiros 32 bytes da assinatura
            mload(p) carrega os próximos 32 bytes de dados a partir do endereço de memória p
            */
            // Lendo os 32 bytes de dados de comprimento
            r := mload(add(_signature, 0x20))
            // Ler os próximos 32 bytes
            s := mload(add(_signature, 0x40))
            // Ler o último byte
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Obter o hash da mensagem de assinatura
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
        )); 
        
        // Restaurando o assinante
        // Verificar assinatura

        // Modificar a variável de estado
        number = _num;
    }

    /**
     * @dev Retorna o valor 
     * @return valor de 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }    
}
