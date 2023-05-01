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
     using Address for address; // use the Address library, use isContract to determine whether the address is a contract
     using Strings for uint256; // use the String library
     // Token name
     string public name;
     // Token code name
     string public symbol;
     // mapping from token type id to account account to balances
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
     function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
         return
             interfaceId == type(IERC1155).interfaceId ||
             interfaceId == type(IERC1155MetadataURI).interfaceId ||
             interfaceId == type(IERC165).interfaceId;
     }

     /**
      * @dev Position query Implement balanceOf of IERC1155, and return the amount of token holdings of the id type of the account address.
      */
     function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
         require(account != address(0), "ERC1155: address zero is not a valid owner");
         return _balances[id][account];
     }

     /**
      * @dev Batch position query
      * Require:
      * - `accounts` and `ids` arrays are of equal length.
      */
     function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
         public view virtual override
         returns (uint256[] memory)
     {
         require(accounts. length == ids. length, "ERC1155: accounts and ids length mismatch");
         uint256[] memory batchBalances = new uint256[](accounts. length);
         for (uint256 i = 0; i < accounts. length; ++i) {
             batchBalances[i] = balanceOf(accounts[i], ids[i]);
         }
         return batchBalances;
     }

     /**
      * @dev Batch authorization, the caller authorizes the operator to use all its tokens
      * Release {ApprovalForAll} event
      * Condition: msg.sender != operator
      */
     function setApprovalForAll(address operator, bool approved) public virtual override {
         require(msg.sender != operator, "ERC1155: setting approval status for self");
         _operatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAll(msg. sender, operator, approved);
     }

     /**
      * @dev Query batch authorization.
      */
     function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
         return _operatorApprovals[account][operator];
     }

     /**
      * @dev Secure transfer, transfer `id` type token of `amount` unit from `from` to `to`
      * Release the {TransferSingle} event.
      * Require:
      * - to cannot be 0 address.
      * - from has enough positions and the caller has authorization
      * - If to is a smart contract, it must support IERC1155Receiver-onERC1155Received.
      */
     function safeTransferFrom(
         address from,
         address to,
         uint256 id,
         uint256amount,
         bytes memory data
     ) public virtual override {
         address operator = msg. sender;
         // The caller is the holder or authorized
         require(
             from == operator || isApprovedForAll(from, operator),
             "ERC1155: caller is not token owner nor approved"
         );
         require(to != address(0), "ERC1155: transfer to the zero address");
         // from address has enough positions
         uint256 fromBalance = _balances[id][from];
         require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
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
      * @dev Batch security transfer, transfer tokens of the `ids` array type in the `amounts` array unit from `from` to `to`
      * Release the {TransferSingle} event.
      * Require:
      * - to cannot be 0 address.
      * - from has enough positions and the caller has authorization
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
         address operator = msg. sender;
         // The caller is the holder or authorized
         require(
             from == operator || isApprovedForAll(from, operator),
             "ERC1155: caller is not token owner nor approved"
         );
         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
         require(to != address(0), "ERC1155: transfer to the zero address");

         // Update positions through for loop
         for (uint256 i = 0; i < ids. length; ++i) {
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
         // Security check
         _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
     }

     /**
      * @dev casting
      * Release the {TransferSingle} event.
      */
     function _mint(
         address to,
         uint256 id,
         uint256amount,
         bytes memory data
     ) internal virtual {
         require(to != address(0), "ERC1155: mint to the zero address");

         address operator = msg. sender;

         _balances[id][to] += amount;
         emit TransferSingle(operator, address(0), to, id, amount);

         _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
     }

     /**
      * @dev batch casting
      * Release the {TransferBatch} event.
      */
     function _mintBatch(
         address to,
         uint256[] memory ids,
         uint256[] memory amounts,
         bytes memory data
     ) internal virtual {
         require(to != address(0), "ERC1155: mint to the zero address");
         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

         address operator = msg. sender;

         for (uint256 i = 0; i < ids. length; i++) {
             _balances[ids[i]][to] += amounts[i];
         }

         emit TransferBatch(operator, address(0), to, ids, amounts);

         _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
     }

     /**
      * @dev destroy
      */
     function _burn(
         address from,
         uint256 id,
         uint256 amount
     ) internal virtual {
         require(from != address(0), "ERC1155: burn from the zero address");

         address operator = msg. sender;

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
         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

         address operator = msg. sender;

         for (uint256 i = 0; i < ids. length; i++) {
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

     // @dev ERC1155 security transfer check
     function _doSafeTransferAcceptanceCheck(
         address operator,
         address from,
         address to,
         uint256 id,
         uint256amount,
         bytes memory data
     ) private {
         if (to. isContract()) {
             try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
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
         if (to. isContract()) {
             try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                 bytes4 response
             ) {
                 if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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
     function uri(uint256 id) public view virtual override returns (string memory) {
         string memory baseURI = _baseURI();
         return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
     }

     /**
      * Calculate the BaseURI of {uri}, uri is splicing baseURI and tokenId together, which needs to be rewritten by development.
      */
     function _baseURI() internal view virtual returns (string memory) {
         return "";
     }
}