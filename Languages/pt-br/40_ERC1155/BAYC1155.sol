// SPDX-License-Identifier: MIT
// por 0xAA
pragma solidity ^0.8.4;

import "./ERC1155.sol";

contract BAYC1155 is ERC1155{
    uint256 constant MAX_ID = 10000; 
    // Construtor
    constructor() ERC1155("BAYC1155", "BAYC1155"){
    }

    //O baseURI do BAYC é ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns (string memory) {
        //QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    }
    
    // Função de construção
    function mint(address to, uint256 id, uint256 amount) external {
        // id não pode ser superior a 10.000
        require(id < MAX_ID, "id overflow");
        _mint(to, id, amount, "");
    }

    // Função de fundição em lote
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        // id não pode ser superior a 10.000
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
    }

}