// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Context.sol";
import "./ERC3525SlotEnumerable.sol";
import "./extensions/IERC3525SlotApprovable.sol";

contract ERC3525SlotApprovable is Context, ERC3525SlotEnumerable, IERC3525SlotApprovable {

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC3525SlotEnumerable(name_, symbol_, decimals_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC3525SlotEnumerable) returns (bool) {
        return
            interfaceId == type(IERC3525SlotApprovable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) public payable virtual override {
        require(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()), "ERC3525SlotApprovable: caller is not owner nor approved for all");
        _setApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function isApprovedForSlot(
        address owner_,
        uint256 slot_,
        address operator_
    ) public view virtual override returns (bool) {
        return _slotApprovals[owner_][slot_][operator_];
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override(IERC721, ERC3525) {
        address owner = ERC3525.ownerOf(tokenId_);
        uint256 slot = ERC3525.slotOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            _msgSender() == owner || 
            ERC3525.isApprovedForAll(owner, _msgSender()) ||
            ERC3525SlotApprovable.isApprovedForSlot(owner, slot, _msgSender()),
            "ERC3525: approve caller is not owner nor approved for all/slot"
        );

        _approve(to_, tokenId_);
    }

    function _setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "ERC3525SlotApprovable: approve to owner");
        _slotApprovals[owner_][slot_][operator_] = approved_;
        emit ApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual override returns (bool) {
        _requireMinted(tokenId_);
        address owner = ERC3525.ownerOf(tokenId_);
        uint256 slot = ERC3525.slotOf(tokenId_);
        return (
            operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            ERC3525.isApprovedForAll(owner, operator_) ||
            ERC3525SlotApprovable.isApprovedForSlot(owner, slot, operator_)
        );
    }
}