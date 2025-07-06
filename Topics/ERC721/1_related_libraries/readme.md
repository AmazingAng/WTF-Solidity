# WTF Solidity极简入门: ERC721专题：1. ERC721相关库

我最近在重新学 Solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新 1-3 讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.gg/5akcruXrsk)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在 github: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

在进阶内容之前，我决定做一个`ERC721`的专题，把之前的内容综合运用，帮助大家更好的复习基础知识，并且更深刻的理解`ERC721`合约。希望在学习完这个专题之后，每个人都能发行自己的`NFT`

---

## ERC721合约概览

`ERC721`主合约一共引用了7个合约：

```Solidity
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC165.sol";
```

他们分别是：

* 3个库合约：`Address.sol`, `Context.sol`和 `Strings.sol`
* 3个接口合约：`IERC721.sol`, `IERC721Receiver.sol`, `IERC721Metadata.sol`
* 1个`EIP165`合约：`ERC165.sol`
所以在讲`ERC721`的主合约之前，我们会花两讲在引用的库合约和接口合约上。

## ERC721相关库

### Address库

`Address`库是`Address`变量相关函数的合集，包括判断某地址是否为合约，更安全的function call。`ERC721`用到其中的`isContract()`：

```Solidity
function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
}
```

这个函数利用了非合约地址`account.code`的长度为0的特性，从而区分某个地址是否为合约地址。

ERC721主合约在`_checkOnERC721Received()`函数中调用了`isContract()`。

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

该函数的目的是在接收`ERC721`代币的时候判断该地址是否是合约地址；如果是合约地址，则继续检查是否实现了`IERC721Receiver`接口（`ERC721`的接收接口），防止有人误把代币转到了黑洞。

### Context库

`Context`库非常简单，封装了两个Solidity的`global`变量：`msg.sender`和`msg.data`

```Solidity
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
```

这两个函数只是单纯的返回`msg.sender`和`msg.data`。所以`Context`库就是为了用函数把`msg.sender`和`msg.data`关键词包装起来，应对Solidity未来某次升级换掉关键字的情况，没其他作用。

### Strings库

`Strings`库包含两个库函数：`toString()`和`toHexString()`。`toString()`把`uint256`直接转换成`string`，比如777变为”777”；而`toHexString()`把`uint256`先转换为`16进制`，再转换为`string`，比如170变为”0xaa”。`ERC721`调用了`toString()`函数：

```Solidity
function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
}
```

这个函数先确定了传入的`uint256`参数是几位数，并存在digits变量中。然后用循环把每一位数字的`ASCII码`转换成`bytes1`，存在`buffer`中，最后把`buffer`转换成`string`返回。

`ERC721`主合约在`tokenURI()`函数中调用了`toString()`：

```Solidity
function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
}
```

这个函数把`baseURI`和指定的`tokenId`拼接到一起，返回`ERC721 metadata`的网址，你花几十个ETH买的的jpeg就是存在这个网址上的。

## 总结

这一讲是`ERC721`专题的第一讲，我们概览了`ERC721`的合约，并介绍了`ERC721`主合约调用的3个库合约`Address`，`Context`和`String`。
