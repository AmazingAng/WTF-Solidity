// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 自定义error
error TransferNotOwner();

contract Errors{
    // A set of mappings that record the Owner of each TokenId
    mapping(uint256 => address) private _owners;

    // Error : gas cost 24445
    function transferOwner1(uint256 tokenId, address newOwner) public {
        if(_owners[tokenId] != msg.sender){
            revert TransferNotOwner();
        }
        _owners[tokenId] = newOwner;
    }

    // require : gas cost 24743
    function transferOwner2(uint256 tokenId, address newOwner) public {
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }

    // assert : gas cost 24446
    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
}   
