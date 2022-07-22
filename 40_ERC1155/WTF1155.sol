// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.4;

import "./ERC1155.sol";

contract WTF1155 is ERC1155{
    // 构造函数
    constructor(string memory name_, string memory symbol_) ERC1155(name_, symbol_){
    }

    //BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }
    
    // 铸造函数
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        _mintBatch(to, ids, amounts, "");
    }
}