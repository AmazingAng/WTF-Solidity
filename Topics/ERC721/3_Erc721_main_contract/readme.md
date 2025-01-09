# WTF Solidity极简入门: ERC721专题：3. ERC721主合约

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

在进阶内容之前，我决定做一个`ERC721`的专题，把之前的内容综合运用，帮助大家更好的复习基础知识，并且更深刻的理解`ERC721`合约。希望在学习完这个专题之后，每个人都能发行自己的`NFT`

---

## ERC721主合约

我在ERC721前两讲介绍了它的相关库和接口，终于这讲可以介绍主合约了。ERC721主合约包含`6`个状态变量和`28`个函数，我们将会一一介绍。并且，我给ERC721代码增加了中文注释，方便大家使用。

### 状态变量

```Solidity
// 代币名称
string private _name;

// 代币代号
string private _symbol;

// tokenId到owner地址Mapping
mapping(uint256 => address) private _owners;

// owner地址到持币数量Mapping
mapping(address => uint256) private _balances;

// tokenId到授权地址Mapping
mapping(uint256 => address) private _tokenApprovals;

// owner地址到是否批量批准Mapping
mapping(address => mapping(address => bool)) private _operatorApprovals;
```

* `_name`和`_symbol`是两个string，存储代币的名称和代号。
* `_owners`是`tokenId`到`owner`地址的`Mapping`，存储每个代币的持有人。
* `_balances`是`owner`地址到持币数量的`Mapping`，存储每个地址的持仓量。
* `_tokenApprovals`是`tokenId`到授权地址的`Mapping`，存储每个`token`的授权信息。
* `_operatorApprovals`是`owner`地址到是否批量批准的`Mapping`，存储每个`owner`的批量授权信息。注意，批量授权会把你钱包持有这个系列的所有`nft`都授权给另一个地址，别人可以随意支配。

### 函数

* `constructor`：构造函数，设定`ERC721`代币的名字和代号（`_name`和`_symbol`变量）。

    ```Solidity
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    ```

* `supportsInterface`：实现`IERC165`接口`supportsInterface`，详见[ERC721专题第二讲](https://github.com/AmazingAng/WTF-Solidity/tree/main/Topics/ERC721/2_Related_interface/readme.md)

    ```Solidity
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    ```

* `balanceOf`：实现`IERC721`的`balanceOf`，利用`_balances`变量查询`owner`地址的`balance`。

    ```Solidity
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    ```

* `ownerOf`：实现`IERC721`的`ownerOf`，利用`_owners`变量查询`tokenId`的`owner`

    ```Solidity
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    ```

* `name`：实现`IERC721Metadata`的`name`，查询代币名称。

    ```Solidity
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    ```

* `symbol`：实现`IERC721Metadata`的`symbol`，查询代币代号。

    ```Solidity
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    ```

* `tokenURI`：实现`IERC721Metadata`的`tokenURI`，查询代币`metadata`存放的网址。Opensea还有小狐狸钱包显示你`NFT`的图片，调用的就是这个函数。

    ```Solidity
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    ```

* `_baseURI`：基`URI`，会被`tokenURI()`调用，跟`tokenId`拼成`tokenURI`，默认为空，需要子合约重写这个函数。

    ```Solidity
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    ```

* `approve`：实现`IERC721`的`approve`，将`tokenId`授权给`to`地址。条件：`to`不`owner`，且`msg.sender`是`owner`或授权地址。调用`_approve`函数。

    ```Solidity
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    ```

* `getApproved`：实现`IERC721`的`getApproved`，利用`_tokenApprovals`变量查询`tokenId`的授权地址。

    ```Solidity
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    ```

* `setApprovalForAll`：实现`IERC721`的`setApprovalForAll`，将持有代币全部授权给`operator`地址。调用`_setApprovalForAll`函数。

    ```Solidity
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    ```

* `isApprovedForAll`：实现`IERC721`的`isApprovedForAll`，利用`_operatorApprovals`变量查询`owner`地址是否将所持`NFT`批量授权给了`operator`地址。

    ```Solidity
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    ```
* `transferFrom`：实现`IERC721`的`transferFrom`，非安全转账，不建议使用。调用`_transfer`函数。

    ```Solidity
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    ```

* `safeTransferFrom`：实现`IERC721`的`safeTransferFrom`，安全转账，调用了`_safeTransfer`函数。

    ```Solidity
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    ```

* `_safeTransfer`：安全转账，安全地将`tokenId`代币从`from`转移到`to`，会检查合约接收者是否了解`ERC721`协议，以防止代币被永久锁定。调用了`_transfer`函数和`_checkOnERC721Received`函数。条件：
  * `from` 不能是0地址。
  * `to` 不能是0地址。
  * `tokenId` 代币必须存在，并且被`from`拥有。
  * 如果`to`是智能合约, 他必须支持`IERC721Receiver-onERC721Received`。

    ```Solidity
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    ```

* `_exists`：查询`tokenId`是否存在（等价于查询他的`owner`是否为非0地址）。

    ```Solidity
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    ```

* `_isApprovedOrOwner`：查询`spender`地址是否被可以使用`tokenId`（他是`owner`或被授权地址）。

    ```Solidity
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    ```

* `_safeMint`：安全`mint`函数，铸造`tokenId`并转账给`to`地址。条件：
  * `tokenId`尚不存在。
  * 如果`to`是智能合约, 他必须支持`IERC721Receiver-onERC721Received`。

  ```Solidity
  function _safeMint(address to, uint256 tokenId) internal virtual {
      _safeMint(to, tokenId, "");
  }
  ```

* `_safeMint`的实现，调用了`_checkOnERC721Received`函数和`_mint`函数。

    ```Solidity
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    ```

* `_mint`：`internal`铸造函数。通过调整`_balances`和`_owners`变量来铸造`tokenId`并转账给`to`，同时释放`Transfer`事件。条件:
  * `tokenId`尚不存在。
  * `to`不是0地址。

    ```Solidity
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }
    ```

* `_burn`：`internal`销毁函数，通过调整`_balances`和`_owners`变量来销毁`tokenId`，同时释放`Transfer`事件。条件：`tokenId`存在。

    ```Solidity
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // 清空授权
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }
    ```

* `_transfer`：转账函数。通过调整`_balances`和`_owner`变量将 `tokenId` 从 `from` 转账给 `to`，同时释放`Transfer`事件。条件:
  * `tokenId` 被`from`拥有
  * `to`不是0地址

  ```Solidity
  function _transfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual {
      require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
      require(to != address(0), "ERC721: transfer to the zero address");

      _beforeTokenTransfer(from, to, tokenId);

      // 清空授权
      _approve(address(0), tokenId);

      _balances[from] -= 1;
      _balances[to] += 1;
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);

      _afterTokenTransfer(from, to, tokenId);
  }
  ```

* `_approve`：授权函数。通过调整`_tokenApprovals`来，授权 `to` 地址操作 `tokenId`，同时释放`Approval`事件。

    ```Solidity
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    ```

* `_setApprovalForAll`：批量授权函数。通过调整`_operatorApprovals`变量，批量授权 `to` 来操作 `owner`全部代币，同时释放`ApprovalForAll`事件。

    ```Solidity
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    ```

* `_checkOnERC721Received`：在转账时被调用，用于在 `to` 为合约的时候调用`IERC721Receiver-onERC721Received`，以防 `tokenId` 被不小心转入黑洞。

    ```Solidity
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    ```

* `_beforeTokenTransfer`：这个函数在转账之前会被调用（包括`mint`和`burn`）。默认为空，子合约可以选择重写。

    ```Solidity
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    ```

* `_afterTokenTransfer`：这个函数在转账之后会被调用（包括`mint`和`burn`）。默认为空，子合约可以选择重写。

    ```Solidity
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    ```

## 总结

本文是`ERC721`专题的第三讲，我介绍了`ERC721`主合约的全部变量和函数，并给出了合约的中文注释。有了`ERC721`标准，NFT项目方只需要把`mint`函数包装一下，就可以发行`NFT`了。下一讲，我们会介绍无聊猿`BAYC`的合约，了解一下最火`NFT`在标准`ERC721`合约上做了什么改动。
