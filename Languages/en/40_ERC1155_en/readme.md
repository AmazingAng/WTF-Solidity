---
title: 40. ERC1155
tags:
  - solidity
  - application
  - wtfacademy
  - ERC1155
---

# WTF Solidity Crash Course: 40. ERC1155

I am currently relearning Solidity to reinforce my knowledge of its intricacies and write a "WTF Solidity Crash Course" for beginners (expert programmers may seek out other tutorials). Updates will be given on a weekly basis, covering 1-3 lessons per week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Discord: [WTF Academy](https://discord.gg/5akcruXrsk)

All code and tutorials are open source on Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lecture, we will learn about the `ERC1155` standard, which allows a contract to contain multiple types of tokens. We will also issue a modified version of the Boring Ape Yacht Club (BAYC) called `BAYC1155`, which contains 10,000 types of tokens with metadata identical to BAYC.

## `EIP1155`
Both the `ERC20` and `ERC721` standards correspond to a single token contract. For example, if we wanted to create a large game similar to World of Warcraft on Ethereum, we would need to deploy a contract for each piece of equipment. Deploying and managing thousands of contracts is very cumbersome. Therefore, the [Ethereum EIP1155](https://eips.ethereum.org/EIPS/eip-1155) proposes a multi-token standard called `ERC1155`, which allows a contract to contain multiple homogeneous and heterogeneous tokens. `ERC1155` is widely used in GameFi applications, and well-known blockchain games such as Decentraland and Sandbox use it.

In simple terms, `ERC1155` is similar to the previously introduced non-fungible token standard [ERC721](https://github.com/AmazingAng/WTFSolidity/tree/main/34_ERC721): in `ERC721`, each token has a `tokenId` as a unique identifier, and each `tokenId` corresponds to only one token; in `ERC1155`, each type of token has an `id` as a unique identifier, and each `id` corresponds to one type of token. This way, the types of tokens can be managed heterogeneously in the same contract, and each type of token has a URL `uri` to store its metadata, similar to `tokenURI` in `ERC721`. The following is the metadata interface contract `IERC1155MetadataURI` for `ERC1155`:

```solidity
/**
 * @dev Optional ERC1155 interface that adds the uri() function for querying metadata
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI of the token type `id`.
     */
    function uri(uint256 id) external view returns (string memory);
```

How to distinguish whether a type of token in `ERC1155` is a fungible or a non-fungible token? It's actually simple: if the total amount of a token corresponding to a specific `id` is `1`, then it is a non-fungible token, similar to `ERC721`; if the total amount of a token corresponding to a specific `id` is greater than `1`, then it is a fungible token, because these tokens share the same `id`, similar to `ERC20`.

## `IERC1155` Interface Contract

The `IERC1155` interface contract abstracts the functionalities required for `EIP1155` implementation, which includes `4` events and `6` functions. Unlike `ERC721`, since `ERC1155` includes multiple types of tokens, it implements batch transfer and batch balance query, allowing for simultaneous operation on multiple types of tokens.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev ERC1155标准的接口合约，实现了EIP1155的功能
 * 详见：https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev 单类代币转账事件
     * 当`value`个`id`种类的代币被`operator`从`from`转账到`to`时释放.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev 批量代币转账事件
     * ids和values为转账的代币种类和数量数组
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev 批量授权事件
     * 当`account`将所有代币授权给`operator`时释放
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev 当`id`种类的代币的URI发生变化时释放，`value`为新的URI
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev 持仓查询，返回`account`拥有的`id`种类的代币的持仓量
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev 批量持仓查询，`accounts`和`ids`数组的长度要想等。
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev 批量授权，将调用者的代币授权给`operator`地址。
     * 释放{ApprovalForAll}事件.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev 批量授权查询，如果授权地址`operator`被`account`授权，则返回`true`
     * 见 {setApprovalForAll}函数.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev 安全转账，将`amount`单位`id`种类的代币从`from`转账给`to`.
     * 释放{TransferSingle}事件.
     * 要求:
     * - 如果调用者不是`from`地址而是授权地址，则需要得到`from`的授权
     * - `from`地址必须有足够的持仓
     * - 如果接收方是合约，需要实现`IERC1155Receiver`的`onERC1155Received`方法，并返回相应的值
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev 批量安全转账
     * 释放{TransferBatch}事件
     * 要求：
     * - `ids`和`amounts`长度相等
     * - 如果接收方是合约，需要实现`IERC1155Receiver`的`onERC1155BatchReceived`方法，并返回相应的值
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
```

### `IERC1155` Events
- `TransferSingle` event: released during the transfer of a single type of token in a single token transfer.
- `TransferBatch` event: released during the transfer of multiple types of tokens in a multi-token transfer.
- `ApprovalForAll` event: released during a batch approval of tokens.
- `URI` event: released when the metadata address changes during a change of the `uri`.

### `IERC1155` Functions
- `balanceOf()`: checks the token balance of a single type returned as the amount of tokens owned by `account` for an `id`.
- `balanceOfBatch()`: checks the token balances of multiple types returned as amounts of tokens owned by `account` for an array of `ids`.
- `setApprovalForAll()`: grants approvals to an `operator` of all tokens owned by the caller.
- `isApprovedForAll()`: checks the authorization status of an `operator` for a given `account`.
- `safeTransferFrom()`: performs the transfer of a single type of safe `ERC1155` token from the `from` address to the `to` address. If the `to` address is a contract, it must implement the `onERC1155Received()` function.
- `safeBatchTransferFrom()`: similar to the `safeTransferFrom()` function, but allows for transfers of multiple types of tokens. The `amounts` and `ids` arguments are arrays with a length equal to the number of transfers. If the `to` address is a contract, it must implement the `onERC1155BatchReceived()` function.

## `ERC1155` Receive Contract

Similar to the `ERC721` standard, to prevent tokens from being sent to a "black hole" contract, `ERC1155` requires token receiving contracts to inherit from `IERC1155Receiver` and implement two receiving functions:

- `onERC1155Received()`: function called when receiving a single token transfer, must implement and return the selector `0xf23a6e61`.

- `onERC1155BatchReceived()`: This is the multiple token transfer receiving function which needs to be implemented and return its own selector `0xbc197c81` in order to accept ERC1155 safe multiple token transfers through the `safeBatchTransferFrom` function.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev ERC1155接收合约，要接受ERC1155的安全转账，需要实现这个合约
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev 接受ERC1155安全转账`safeTransferFrom` 
     * 需要返回 0xf23a6e61 或 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev 接受ERC1155批量安全转账`safeBatchTransferFrom` 
     * 需要返回 0xbc197c81 或 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
```

## Main Contract `ERC1155`

The `ERC1155` main contract implements the functions specified by the `IERC1155` interface contract, as well as the functions for minting and burning single/multiple tokens.

### Variables in `ERC1155`

The `ERC1155` main contract contains `4` state variables:

- `name`: token name
- `symbol`: token symbol
- `_balances`: token ownership mapping, which records the token balance `balances` of address `account` for token `id`
- `_operatorApprovals`: batch approval mapping, which records the approval situation of the holder address to another address.

### Functions in `ERC1155`

The `ERC1155` main contract contains `16` functions:

- Constructor: Initializes state variables `name` and `symbol`.
- `supportsInterface()`: Implements the `ERC165` standard to declare the interfaces supported by it, which can be checked by other contracts.
- `balanceOf()`: Implements `IERC1155`'s `balanceOf()` to query the token balance. Unlike the `ERC721` standard, it requires the address for which the balance is queried (`account`) and the token `id` to be provided.

- `balanceOfBatch()`: Implements `balanceOfBatch()` of `IERC1155`, which allows for batch querying of token balances.
- `setApprovalForAll()`: Implements `setApprovalForAll()` of `IERC1155`, which allows for batch authorization, and emits the `ApprovalForAll` event.
- `isApprovedForAll()`: Implements `isApprovedForAll()` of `IERC1155`, which allows for batch query of authorization information.
- `safeTransferFrom()`: Implements `safeTransferFrom()` of `IERC1155`, which allows for safe transfer of a single type of token, and emits the `TransferSingle` event. Unlike `ERC721`, this function not only requires the `from` (sender), `to` (recipient), and token `id`, but also the transfer amount `amount`.
- `safeBatchTransferFrom()`: Implements `safeBatchTransferFrom()` of `IERC1155`, which allows for safe transfer of multiple types of tokens, and emits the `TransferBatch` event.
- `_mint()`: Function for minting a single type of token.
- `_mintBatch()`: Function for minting multiple types of tokens.
- `_burn()`: Function for burning a single type of token.
- `_burnBatch()`: Function for burning multiple types of tokens.
- `_doSafeTransferAcceptanceCheck()`: Safety check for single type token transfers, called by `safeTransferFrom()`, ensures that the recipient has implemented the `onERC1155Received()` function when the recipient is a contract.
- `_doSafeBatchTransferAcceptanceCheck()`: Safety check for multiple types of token transfers, called by `safeBatchTransferFrom()`, ensures that the recipient has implemented the `onERC1155BatchReceived()` function when the recipient is a contract.
- `uri()`: Returns the URL where the metadata of the token of type `id` is stored for `ERC1155`, similar to `tokenURI` for `ERC721`.
- `baseURI()`: Returns the `baseURI`. `uri` is simply `baseURI` concatenated with `id`, and can be overwritten by developers.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/Address.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/String.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/IERC165.sol";

/**
 * @dev ERC1155多代币标准
 * 见 https://eips.ethereum.org/EIPS/eip-1155
 */
contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {
    using Address for address; // 使用Address库，用isContract来判断地址是否为合约
    using Strings for uint256; // 使用String库
    // Token名称
    string public name;
    // Token代号
    string public symbol;
    // 代币种类id 到 账户account 到 余额balances 的映射
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // address 到 授权地址 的批量授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * 构造函数，初始化`name` 和`symbol`, uri_
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev 持仓查询 实现IERC1155的balanceOf，返回account地址的id种类代币持仓量。
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev 批量持仓查询
     * 要求:
     * - `accounts` 和 `ids` 数组长度相等.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public view virtual override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    /**
     * @dev 批量授权，调用者授权operator使用其所有代币
     * 释放{ApprovalForAll}事件
     * 条件：msg.sender != operator
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev 查询批量授权.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev 安全转账，将`amount`单位的`id`种类代币从`from`转账到`to`
     * 释放 {TransferSingle} 事件.
     * 要求:
     * - to 不能是0地址.
     * - from拥有足够的持仓量，且调用者拥有授权
     * - 如果 to 是智能合约, 他必须支持 IERC1155Receiver-onERC1155Received.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        // 调用者是持有者或是被授权
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        // from地址有足够持仓
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        // 更新持仓量
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        // 释放事件
        emit TransferSingle(operator, from, to, id, amount);
        // 安全检查
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);    
    }

    /**
     * @dev 批量安全转账，将`amounts`数组单位的`ids`数组种类代币从`from`转账到`to`
     * 释放 {TransferSingle} 事件.
     * 要求:
     * - to 不能是0地址.
     * - from拥有足够的持仓量，且调用者拥有授权
     * - 如果 to 是智能合约, 他必须支持 IERC1155Receiver-onERC1155BatchReceived.
     * - ids和amounts数组长度相等
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        // 调用者是持有者或是被授权
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        // 通过for循环更新持仓  
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        // 安全检查
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);    
    }

    /**
     * @dev 铸造
     * 释放 {TransferSingle} 事件.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = msg.sender;

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev 批量铸造
     * 释放 {TransferBatch} 事件.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev 销毁
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev 批量销毁
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    // @dev ERC1155的安全转账检查
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    // @dev ERC1155的批量安全转账检查
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    /**
     * @dev 返回ERC1155的id种类代币的uri，存储metadata，类似ERC721的tokenURI.
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    /**
     * 计算{uri}的BaseURI，uri就是把baseURI和tokenId拼接在一起，需要开发重写.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
```

## `BAYC`, but as `ERC1155`

We have made some modifications to the boring apes `BAYC` by changing it to `BAYC1155` which now follows the `ERC1155` standard and allows for free minting. The `_baseURI()` function has been modified to ensure that the `uri` for `BAYC1155` is the same as the `tokenURI` for `BAYC`. This means that `BAYC1155` metadata will be identical to that of boring apes.

```solidity
// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.4;

import "./ERC1155.sol";

contract BAYC1155 is ERC1155{
    uint256 constant MAX_ID = 10000; 
    // 构造函数
    constructor() ERC1155("BAYC1155", "BAYC1155"){
    }

    //BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }
    
    // 铸造函数
    function mint(address to, uint256 id, uint256 amount) external {
        // id 不能超过10,000
        require(id < MAX_ID, "id overflow");
        _mint(to, id, amount, "");
    }

    // 批量铸造函数
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        // id 不能超过10,000
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
    }
}
```

## Remix Demo

### 1. Deploy the `BAYC1155` Contract
![Deploy](./img/40-1.jpg)

### 2. View Metadata `URI`
![View metadata](./img/40-2.jpg)

### 3. `mint` and view position changes
In the `mint` section, enter the account address, `id`, and quantity, and click the `mint` button to mint. If the quantity is `1`, it is a non-fungible token; if the quantity is greater than `1`, it is a fungible token.

![mint1](./img/40-3.jpg)

In the `blanceOf` section, enter the account address and `id` to view the corresponding position.

![mint2](./img/40-4.jpg)

### 4. Batch `mint` and view position changes

In the "mintBatch" section, input the "ids" array and corresponding quantity to be minted. The length of both arrays must be the same. 
To view the recently minted token "id" array, input it as shown. 

Similarly, in the "transfer" section, we transfer tokens from an address that already owns them to a new address. This address can be a normal address or a contract address; if it is a contract address, it will be verified whether it has implemented the "onERC1155Received()" receiving function. 
Here, we transfer tokens to a normal address by inputting the "ids" and corresponding "amounts" arrays. 
To view the changes in holdings of the address to which tokens were just transferred, select "view balances".

## Summary

In this lesson we learned about the `ERC1155` multi-token standard proposed by Ethereum's `EIP1155`. It allows for a contract to include multiple homogeneous or heterogeneous tokens. Additionally, we created a modified version of the Bored Ape Yacht Club (BAYC) - `BAYC1155`: an `ERC1155` token containing 10,000 tokens with the same metadata as BAYC. Currently, `ERC1155` is primarily used in GameFi. However, I believe that as metaverse technology continues to develop, this standard will become increasingly popular.