// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.21;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    using Strings for uint256; // Stringsライブラリを使用

    // トークン名
    string public override name;
    // トークンシンボル
    string public override symbol;
    // tokenId から owner address への所有者マッピング
    mapping(uint => address) private _owners;
    // address から保有数量への保有量マッピング
    mapping(address => uint) private _balances;
    // tokenID から承認アドレスへの承認マッピング
    mapping(uint => address) private _tokenApprovals;
    // ownerアドレス から operatorアドレスへの一括承認マッピング
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // エラー 無効な受信者
    error ERC721InvalidReceiver(address receiver);

    /**
     * コンストラクタ、`name` と`symbol` を初期化 .
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // IERC165インターフェースsupportsInterfaceを実装
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

    // IERC721のbalanceOfを実装、_balances変数を使用してownerアドレスのbalanceをクエリ。
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // IERC721のownerOfを実装、_owners変数を使用してtokenIdのownerをクエリ。
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // IERC721のisApprovedForAllを実装、_operatorApprovals変数を使用してownerアドレスが保有するNFTをoperatorアドレスに一括承認しているかをクエリ。
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // IERC721のsetApprovalForAllを実装、保有トークンを全てoperatorアドレスに承認。_setApprovalForAll関数を呼び出し。
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // IERC721のgetApprovedを実装、_tokenApprovals変数を使用してtokenIdの承認アドレスをクエリ。
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 承認関数。_tokenApprovalsを調整して、to アドレスに tokenId の操作を承認し、同時にApprovalイベントを発行。
    function _approve(
        address owner,
        address to,
        uint tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // IERC721のapproveを実装、tokenIdを to アドレスに承認。条件：toはownerではなく、msg.senderはownerまたは承認アドレス。_approve関数を呼び出し。
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    // spenderアドレスがtokenIdを使用できるかをクエリ（ownerまたは承認アドレスである必要がある）
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
     * 転送関数。_balancesと_owner変数を調整して tokenId を from から to に転送し、同時にTransferイベントを発行。
     * 条件:
     * 1. tokenId が from によって所有されている
     * 2. to が0アドレスではない
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

    // IERC721のtransferFromを実装、非安全転送、推奨されません。_transfer関数を呼び出し
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
     * 安全転送、tokenId トークンを from から to に安全に転送し、コントラクト受信者がERC721プロトコルを理解しているかをチェックしてトークンが永続的にロックされることを防止。_transfer関数と_checkOnERC721Received関数を呼び出し。条件：
     * from は0アドレスではない.
     * to は0アドレスではない.
     * tokenId トークンが存在し、from によって所有されている.
     * to がスマートコントラクトの場合、IERC721Receiver-onERC721Receivedをサポートする必要がある.
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    /**
     * IERC721のsafeTransferFromを実装、安全転送、_safeTransfer関数を呼び出し。
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

    // safeTransferFromオーバーロード関数
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * ミント関数。_balancesと_owners変数を調整してtokenIdをミントし、to に転送、同時にTransferイベントを発行。ミント関数。_balancesと_owners変数を調整してtokenIdをミントし、to に転送、同時にTransferイベントを発行。
     * このmint関数は誰でも呼び出すことができ、実際の使用では開発者が書き直して条件を追加する必要があります。
     * 条件:
     * 1. tokenIdがまだ存在しない。
     * 2. toが0アドレスではない.
     */
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // バーン関数、_balancesと_owners変数を調整してtokenIdを破棄し、同時にTransferイベントを発行。条件：tokenIdが存在する。
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approve(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // _checkOnERC721Received：関数、to がコントラクトの場合にIERC721Receiver-onERC721Receivedを呼び出し、tokenId が誤ってブラックホールに転送されることを防ぐ。
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * IERC721MetadataのtokenURI関数を実装、metadataをクエリ。
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * {tokenURI}のBaseURIを計算、tokenURIはbaseURIとtokenIdを連結したもので、開発者が書き直す必要がある。
     * BAYCのbaseURIは ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}