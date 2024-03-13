// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Declaración de error TransferNotOwner
error TransferNotOwner();

contract Errors{
    // Un mapping que registra el propietario  para cada TokenId
    mapping(uint256 => address) private _owners;

    // Error : precio de gas 24445
    function transferOwner1(uint256 tokenId, address newOwner) public {
        if(_owners[tokenId] != msg.sender){
            revert TransferNotOwner();
        }
        _owners[tokenId] = newOwner;
    }

    // requirer : precio de gas 24743
    function transferOwner2(uint256 tokenId, address newOwner) public {
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }

    // Afirmar : precio de gas 24446
    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
}   
