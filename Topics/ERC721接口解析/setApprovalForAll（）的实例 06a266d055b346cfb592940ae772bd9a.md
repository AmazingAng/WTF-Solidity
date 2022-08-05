# setApprovalForAll（）的实例

ERC721 标准合约是没有提供批量转移NFT到不同的地址中的接口，如果项目方想给白名单用户空投，代理合约配合setApprovalForAll（）函数提供了一种解决方案。

关于接口合约的基础介绍：

[Solidity8.0全面精通-42-接口合约_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1fS4y127BX/?spm_id_from=333.788&vd_source=8c3c6813b187818a0ba1a67277a795d2)

关于空投的原理可以参考以下两个视频

[https://www.youtube.com/watch?v=-0nU2usv4S4&t=2s](https://www.youtube.com/watch?v=-0nU2usv4S4&t=2s)

[https://www.youtube.com/watch?v=M7ThuAS47Cc](https://www.youtube.com/watch?v=M7ThuAS47Cc)

空投用到的合约源文件

```solidity
/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface BC_Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function symbol() external returns (string memory);
}

contract BanaCatBot {
    BC_Interface public BanaCat;
    string public symbol;
    // event safeTransferFrom(address from,address to, uint256 tokenId);

    // 给目标合约赋值
    function setInterfaceContract(BC_Interface _addr) external{
        BanaCat = _addr;
    }

// 将NFT列表批量转发给地址列表
    function bulkTransfer(address[] calldata addrList, uint[] calldata nftlist) external {
        require(addrList.length == nftlist.length, "length doesn't match");
        for (uint i = 0; i < addrList.length; i++){
            BanaCat.safeTransferFrom(msg.sender, addrList[i], nftlist[i]);
            // emit safeTransferFrom(msg.sender, addrList[i], nftlist[i]);
        }
    }
    function showSymbol() external{
        symbol = BanaCat.symbol();
    }

}
```

合约也已经开源到了Polygon网络上，可以直接拿来用。

[https://polygonscan.com/address/0x2A6dFC4C69a716b7F02b55CE76432226AefCB193#code](https://polygonscan.com/address/0x2A6dFC4C69a716b7F02b55CE76432226AefCB193#code)

# 使用方法

**注：以下过程中BanaCatNFT contract 均可以替换成自己想要批量转移NFT的目标主合约**

1. **在主合约中调用`setApprovalForAll（）`给提供批量转发NFT功能的代理合约授权；**

这一步是在NFT主合约中完成的，将自己地址下的所有NFT授权给代理合约，让它具备转发的资格。

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x92342888a4ecbe3775fe920c7efc9cab1eb5befe643c955d9a7bc786cc6e29a5)

 2. **在代理合约中调用`setInterfaceContract（）`函数将BanaCatNFT contract 的合约地址设置为代理合约的目标接口**

这一步的目的是让代理合约知道自己要从哪个NFT主合约中转移NFT

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x56f289faaab56c3cb1ac1401f970a23c9f79d0c193d0e76d9d3e049494c37f03#eventlog)

1. **构建`NFTList`，`addressList`发起交易**
    
    ![Untitled](Untitled%20111.png)
    

这里有个小问题需要注意一下，**`bulkTransfer（）`**函数的两个参数会因为函数的执行上下文的不容儿有所差别

1. 通过Remix部署，并在Remix后台发送交易，参数形式为：

addrList：[”address1”, “address2”, ……]（地址用双引号括起来，地址和地址之间用半角逗号分隔）例如

```solidity
["0x204Eb0dDD556Fc33805A53BA29572B349Ea3c288","0xcd06Db13ACff23EEa734f771ed52cE59642E52b1",……]
```

nftlist：[tokenID1,tokenID2,……]（tokenID之间通过半角逗号分隔）

```solidity
[1,2,3,……]
```

1. 部署之后通过本地RPC调用发起交易：同上
2. 在polyscan浏览器发起交易：

addrList：[address1, address2, ……]（地址不用双引号，地址和地址之间用半角逗号分隔）例如

```solidity
[0x204Eb0dDD556Fc33805A53BA29572B349Ea3c288,0xcd06Db13ACff23EEa734f771ed52cE59642E52b1,……]
```

nftlist：[tokenID1,tokenID2,……]（tokenID之间通过半角逗号分隔，‼️**tokenID之间不能有空格‼️**）

```solidity
[1,2,3,……]
```

最终发起的交易是长这样的

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0xa57405133607002ef92260f91ee8f56001fcabe0c34cd9c4c77661d9b893c2f0)