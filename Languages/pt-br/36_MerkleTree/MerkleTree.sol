// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.4;

import "../34_ERC721/ERC721.sol";


/**
 * Usando a árvore de Merkle para verificar uma lista branca (gerar a árvore de Merkle na página: https://lab.miguelmota.com/merkletreejs/example/)
 * Selecione Keccak-256, hashLeaves e sortPairs
 * 4 endereços de folha:
    [
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
    ]
 * Prova de Merkle para o primeiro endereço:
    [
    "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",
    "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c"
    ]
 * Raiz de Merkle: 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
 */


/**
 * @dev Verifica o contrato da árvore de Merkle.
 *
 * A prova pode ser gerada usando a biblioteca JavaScript:
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Observe: o hash é feito com keccak256 e a ordenação de pares está ativada.
 * Veja um exemplo em JavaScript em `https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/cryptography/MerkleProof.test.js`.
 */
library MerkleProof {
    /**
     * @dev Quando o `root` reconstruído a partir do `proof` e `leaf` é igual ao `root` fornecido, retorna `true`, indicando que os dados são válidos.
     * Durante a reconstrução, os pares de nós folha e elementos são ordenados.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Retorna a `root` calculada usando a árvore de Merkle com `leaf` e `proof`. O `proof` só é válido quando a `root` reconstruída é igual à `root` fornecida.
     * Durante a reconstrução, os pares de nós folha e elementos são ordenados.
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    // Sorted Pair Hash
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}

contract MerkleTree is ERC721 {
    // Raiz da árvore de Merkle
    // Registre os endereços já mintados

    // Construtor, inicializa o nome, código e raiz da árvore Merkle da coleção NFT.
    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

    // Usando a árvore de Merkle para verificar o endereço e fazer a mintagem
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        // Merkle verificação aprovada
        // O endereço não foi mintado antes.
        
        // Registre os endereços que foram mintados
        // mint
    }

    // Calcular o valor de hash das folhas da árvore de Merkle
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // Verificação da árvore de Merkle, chamando a função verify() da biblioteca MerkleProof
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
