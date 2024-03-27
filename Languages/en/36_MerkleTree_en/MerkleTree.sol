// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.21;

import "../34_ERC721/ERC721.sol";


/**
 * Verify whitelist using Merkle tree (you can generate Merkle tree with a webpage: https://lab.miguelmota.com/merkletreejs/example/)
 * Choose Keccak-256, hashLeaves and sortPairs options
 * 4 leaf addresses:
    [
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
    ]
 * Merkle proof for the first address:
    [
    "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",
    "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c"
    ]
 * Merkle root: 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
 */


/**
 * @dev Contract for verifying Merkle tree.
 *
 * Proof can be generated using the JavaScript library:
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: Hash with keccak256 and turn on pair sorting.
 * See the JavaScript example in `https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/cryptography/MerkleProof.test.js`.
 */
library MerkleProof {
    /**
     * @dev Returns `true` when the `root` reconstructed from `proof` and `leaf` equals to the given `root`, meaning the data is valid.
     * During reconstruction, both the leaf node pairs and element pairs are sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the `root` of the Merkle tree computed from a `leaf` and a `proof`.
     * The `proof` is only valid when the reconstructed `root` equals to the given `root`.
     * During reconstruction, both the leaf node pairs and element pairs are sorted.
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
    bytes32 immutable public root; // Root of the Merkle tree
    mapping(address => bool) public mintedAddress;   // Record the address that has already been minted

    // Constructor, initialize the name and symbol of the NFT collection, and the root of the Merkle tree
    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

    // Use the Merkle tree to verify the address and mint
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // Merkle verification passed
        require(!mintedAddress[account], "Already minted!"); // Address has not been minted
        
        mintedAddress[account] = true; // Record the minted address
        _mint(account, tokenId); // Mint
    }

    // Calculate the hash value of the Merkle tree leaf
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle tree verification, call the verify() function of the MerkleProof library
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
