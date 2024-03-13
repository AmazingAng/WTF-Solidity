// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

import "./ERC1155.sol";

contract BAYC1155 is ERC1155 {
    uint256 constant MAX_ID = 10000;

    // Constructor
    constructor() ERC1155("BAYC1155", "BAYC1155") {}

    // BAYC's baseURI is ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    // Mint function
    function mint(address to, uint256 id, uint256 amount) external {
        // id cannot exceed 10,000
        require(id < MAX_ID, "id overflow");
        _mint(to, id, amount, "");
    }

    // Batch mint function
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        // id cannot exceed 10,000
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
    }
}
