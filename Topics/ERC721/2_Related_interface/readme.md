# WTF Solidity极简入门: ERC721专题：2. ERC721相关接口

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

在进阶内容之前，我决定做一个`ERC721`的专题，把之前的内容综合运用，帮助大家更好的复习基础知识，并且更深刻的理解`ERC721`合约。希望在学习完这个专题之后，每个人都能发行自己的`NFT`

---

## ERC721相关接口

ERC721的主合约一共引用了4个接口合约：`IERC721.sol`, `IERC721Receiver.sol`, `IERC721Metadata.sol`，和间接引用的`ERC165`的`IERC165.sol`。这一讲我们将逐个介绍这4个接口合约。

### IERC165接口

首先我们介绍一下`EIP165`（`以太坊改进建议第165条`），他的目的是创建一个标准方法来发布和检测智能合约实现的接口。讲一个去年年底发生的真实事件，`PeopleDAO`有个朋友错转了4000w枚PEOPLE到代币合约。但合约没有实现转出代币的功能，只能进不能出，这些代币直接锁死在里面销毁了。试想一下，如果在转账的时候自动判断接收方合约是否实现了相应的接口，没实现的话就`revert`交易，很多错转代币的悲剧都不会发生。`EIP165`就是干这个的，而`ERC165`就是`EIP165`的实现。

`IERC165`是`ERC165`的接口合约，只有一个函数`supportsInterface()`，输入想查询的接口的`interfaceId`，返回一个`bool`告诉你合约是否实现了该接口。

```Solidity
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```

`ERC721`主合约对`supportsInterface()`的实现如下：

```Solidity
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
}
```

可以看到，ERC721实现了`IERC721`，`IERC721Metadata`和`IERC165`的接口，查询的时候会返回`true`；否则返回`false`。我会在进阶内容中更详细的介绍`function selector`和`interfaceId`。

### IERC721

`IERC721`是ERC721的接口合约，里面包括3个`event`和9个`function`：

```Solidity
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}
```

其中`event`包括：

1. `Transfer`事件：在转账时被释放，记录代币的发出地址`from`，接收地址`to`和`tokenid`。
2. `Approval`事件：在授权时释放，记录`approve`的发出地址`owner`
3. `ApprovalForAll`事件：在批量授权时释放，记录`approve`的发出地址`owner`，被授权地址`operator`和是否被授权`approved。

其中`function`包括：

1. `balanceOf`：参数为要查询的`address`，返回该地址的`NFT`持有量`balance`。
2. `ownerOf`：参数为要查询的`tokenId`，返回这个`tokenId`的主人`owner`。
3. `safeTransferFrom`：安全转账（如果接收方是合约地址，会要求实现`ERC721`的接收接口）。参数为转出地址`from`，接收地址`to`和`tokenId`。
4. `transferFrom`：普通转账（不检查对方是否实现`ERC721`的接收接口），参数为转出地址`from`，接收地址`to`和`tokenId`。
5. `approve`：授权，批准另一个地址使用你的`NFT`。参数为被授权地址`to`和`tokenId`。
6. `getApproved`：查询`NFT`被批准给了哪个地址，参数为`tokenId`，返回被批准的地址`operator`。
7. `setApprovalForAll`：将自己持有的这类`NFT`批量授权给某个地址，参数为被授权的地址`operator`和是否授权`approved`。
8. `isApprovedForAll`：查询某人的`NFT`是否批量授权给了某个地址，参数为授权方`owner`和被授权地址`operator`，返回`bool`。
9. `safeTransferFrom`：安全转账，与`3.`不同的地方在于参数里面包含了`data`，可以做额外处理。

### IERC721Receiver

```Solidity
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
```

`IERC721Receiver`接口包含了一个函数`onERC721Received()`。这个函数会在`safeTransferFrom()`中被调用，代币的接收合约必须实现这个接口才能转账成功。

### IERC721Metadata

```Solidity
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
```

`IERC721Metadata`是`ERC721`的拓展接口，实现了`3`个查询`metadata`的常用函数：

1. `name()`：返回代币名称。
2. `symbol()`：返回代币代号
3. `tokenURI()`：通过`tokenId`查询`metadata`所在`url`。

## 总结

本文是`ERC721`专题的第二讲，我们介绍了`ERC721`主合约调用的4个接口合约`IERC165`，`IERC721`，`IERC721Receiver`和`IERC721Metadata`。下一讲终于该介绍ERC721主合约了！LFG！

## 延伸阅读

- [EIP165](https://eips.ethereum.org/EIPS/eip-165)
- [ERC721](https://eips.ethereum.org/EIPS/eip-721)
- [中文分析EIP165](https://learnblockchain.cn/docs/eips/eip-165.html)