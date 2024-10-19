// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Context.sol";
import "./ERC3525Mintable.sol";

contract ERC3525Burnable is Context, ERC3525Mintable {

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC3525Mintable(name_, symbol_, decimals_) {
    }

    function burn(uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: caller is not token owner nor approved");
        ERC3525._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: caller is not token owner nor approved");
        ERC3525._burnValue(tokenId_, burnValue_);
    }
}
