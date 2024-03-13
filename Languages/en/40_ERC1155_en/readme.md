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

import "../34_ERC721_en/IERC165.sol";

/**
 * @dev ERC1155 standard interface contract, realizes the function of EIP1155
 * See: https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev single-type token transfer event
     * Released when `value` tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev multi-type token transfer event
     * ids and values are arrays of token types and quantities transferred
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev volume authorization event
     * Released when `account` authorizes all tokens to `operator`
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Released when the URI of the token of type `id` changes, `value` is the new URI
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Balance inquiry, returns the position of the token of `id` type owned by `account`
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev Batch balance inquiry, the length of `accounts` and `ids` arrays have to wait.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Batch authorization, authorize the caller's tokens to the `operator` address.
     * Release the {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Batch authorization query, if the authorization address `operator` is authorized by `account`, return `true`
     * See {setApprovalForAll} function.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @dev Secure transfer, transfer `amount` unit `id` type token from `from` to `to`.
     * Release {TransferSingle} event.
     * Require:
     * - If the caller is not a `from` address but an authorized address, it needs to be authorized by `from`
     * - `from` address must have enough open positions
     * - If the receiver is a contract, it needs to implement the `onERC1155Received` method of `IERC1155Receiver` and return the corresponding value
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Batch security transfer
     * Release {TransferBatch} event
     * Require:
     * - `ids` and `amounts` are of equal length
     * - If the receiver is a contract, it needs to implement the `onERC1155BatchReceived` method of `IERC1155Receiver` and return the corresponding value
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

import "../34_ERC721_en/IERC165.sol";

/**
 * @dev ERC1155 receiving contract, to accept the secure transfer of ERC1155, this contract needs to be implemented
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev accept ERC1155 safe transfer `safeTransferFrom`
     * Need to return 0xf23a6e61 or `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev accept ERC1155 batch safe transfer `safeBatchTransferFrom`
     * Need to return 0xbc197c81 or `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
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
import "../34_ERC721_en/Address.sol";
import "../34_ERC721_en/String.sol";
import "../34_ERC721_en/IERC165.sol";

/**
 * @dev ERC1155 multi-token standard
 * See https://eips.ethereum.org/EIPS/eip-1155
 */
contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {
    using Address for address; // use the Address library, isContract to determine whether the address is a contract
    using Strings for uint256; // use the String library
    // Token name
    string public name;
    // Token code name
    string public symbol;
    // Mapping from token type id to account account to balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Batch authorization mapping from initiator address to authorized address operator to whether to authorize bool
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * Constructor, initialize `name` and `symbol`, uri_
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Balance query function implements balanceOf of IERC1155 and returns the number of token holdings of the id type of the account address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _balances[id][account];
    }

    /**
     * @dev Batch balance query
     * Require:
     * - `accounts` and `ids` arrays are of equal length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    /**
     * @dev Batch authorization function, the caller authorizes the operator to use all its tokens
     * Release {ApprovalForAll} event
     * Condition: msg.sender != operator
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Batch authorization query.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Secure transfer function, transfer `id` type token of `amount` unit from `from` to `to`
     * Release the {TransferSingle} event.
     * Require:
     * - to cannot be 0 address.
     * - from has enough balance and the caller has authorization
     * - If to is a smart contract, it must support IERC1155Receiver-onERC1155Received.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        // The caller is the holder or authorized
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        // from address has enough balance
        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        // update position
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        // release event
        emit TransferSingle(operator, from, to, id, amount);
        // Security check
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev Batch security transfer function, transfer tokens of the `ids` array type in the `amounts` array unit from `from` to `to`
     * Release the {TransferSingle} event.
     * Require:
     * - to cannot be 0 address.
     * - from has enough balance and the caller has authorization
     * - If to is a smart contract, it must support IERC1155Receiver-onERC1155BatchReceived.
     * - ids and amounts arrays have equal length
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        // The caller is the holder or authorized
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        // Update balance through for loop
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        // Security check
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Mint function
     * Release the {TransferSingle} event.
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

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev Batch mint function
     * Release the {TransferBatch} event.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev destroy
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
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
     * @dev batch destruction
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    // @dev ERC1155 security transfer check
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155 Receiver implementer");
            }
        }
    }

    // @dev ERC1155 batch security transfer check
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155 Receiver implementer");
            }
        }
    }

    /**
     * @dev Returns the uri of the id type token of ERC1155, stores metadata, similar to the tokenURI of ERC721.
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }

    /**
     * Calculate the BaseURI of {uri}, uri is splicing baseURI and tokenId together, which needs to be rewritten by development.
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