// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    using Address for address; // Uses Address library and uses isContract to check whether an address is a contract
    using Strings for uint256; // Uses String library

    // Token name
    string public override name;
    // Token symbol
    string public override symbol;
    // Mapping from token ID to owner address
    mapping(uint => address) private _owners;
    // Mapping owner address to balance of the token
    mapping(address => uint) private _balances;
    // Mapping from tokenId to approved address
    mapping(uint => address) private _tokenApprovals;
    //  Mapping from owner to operator addresses' batch approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Implements the supportsInterface of IERC165
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Implements the balanceOf function of IERC721, which uses `_balances` variable to check the balance of tokens in `owner`'s account.
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // Implements the ownerOf function of IERC721, which uses `_owners` variable to check `tokenId`'s owner.
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // Implements the isApprovedForAll function of IERC721, which uses `_operatorApprovals` variable to check whether `owner` address's NFTs are authorized in batch to be held by another `operator` address.    
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // Implements the setApprovalForAll function of IERC721, which approves all holding tokens to `operator` address. Invokes `_setApprovalForAll` function.
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Implements the getApproved function of IERC721, which uses `_tokenApprovals` variable to check authorized address of `tokenId`.
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }
     
    // The approve function, which updates `_tokenApprovals` variable to approve `to` address to use `tokenId` and emits an Approval event.
    function _approve(
        address owner,
        address to,
        uint tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // Implements the approve function of IERC721, which approves `tokenId` to `to` address. 
    // Requirements: `to` is not `owner` and msg.sender is `owner` or an approved address. Invokes the _approve function.
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    // Checks whether the `spender` address can use `tokenId` or not. (`spender` is `owner` or an approved address)
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) private view returns (bool) {
        return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }

    /*
     * The transfer function, which transfers `tokenId` from `from` address to `to` address by updating the `_balances` and `_owner` variables, emits a Transfer event.
     * Requirements:
     * 1. `tokenId` token must be owned by `from`.
     * 2. `to` cannot be the zero address.
     * 3. `from` cannot be the zero address.
     */
    function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");

        _approve(owner, address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    // Implements the transferFrom function of IERC721, we should not use it as it is not a safe transfer. Invokes the _transfer function.
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    /**
     * Safely transfers `tokenId` token from `from` to `to`, this function will check that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked. It invokes the _transfer 
     * and _checkOnERC721Received functions. 
     * Requirements:     
     * 1. `from` cannot be the zero address.
     * 2. `to` cannot be the zero address.
     * 3. `tokenId` token must exist and be owned by `from`.
     * 4. If `to` refers to a smart contract, it must support {IERC721Receiver-onERC721Received}.
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "not ERC721Receiver");
    }

    /**
     * Implements the safeTransferFrom function of IERC721 to safely transfer. It invokes the _safeTransfe function.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    // an overloaded function for safeTransferFrom
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** 
     * The mint function, which updates `_balances` and `_owners` variables to mint `tokenId` and transfers it to `to`. It emits an Transfer event.
     * This mint function can be used by anyone, developers need to rewrite this function and add some requirements in practice.
     * Requirements: 
     * 1. `tokenId` must not exist.
     * 2. `to` cannot be the zero address.
     */
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // The destroy function, which destroys `tokenId` by updating `_balances` and `_owners` variables. It emits an Transfer event. Requirements: `tokenId` must exist.
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approve(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // It invokes IERC721Receiver-onERC721Received when `to` address is a contract to prevent `tokenId` from being forever locked.    
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }

    /**
     * Implements the tokenURI function of IERC721Metadata to query metadata.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * Base URI for computing {tokenURI}, which is the combination of `baseURI` and `tokenId`. Developers should rewrite this function accordingly.
     * BAYC's baseURI is ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
