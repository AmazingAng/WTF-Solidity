---
title: 38. NFT Exchange
tags:
  - solidity
  - application
  - wtfacademy
  - ERC721
  - NFT Swap
---

# WTF Simplified Introduction to Solidity: 38. NFT Exchange

I have been revisiting Solidity lately to review the details and create a "WTF Simplified Introduction to Solidity" for beginners (professional programmers may find other tutorials more suitable), with 1-3 updates per week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Discord: [WTF Academy](https://discord.gg/5akcruXrsk)

All code and tutorials are open source on Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

"Opensea" is the largest NFT trading platform on Ethereum with a total trading volume of $30 billion. Opensea charges a fee of 2.5% on transactions, meaning it has made at least $750 million in profits through user transactions. Additionally, its operation is not decentralized, and it has no plans to issue coins to compensate users. NFT players have been frustrated with Opensea for a long time. Today, we use smart contracts to build a zero-fee decentralized NFT exchange: NFTSwap.

## Design Logic

- Seller: The party selling the NFT can list the item, revoke the listing, and update the price.
- Buyer: The party buying the NFT can purchase the item.
- Order: The on-chain NFT order published by the seller. A series of the same tokenId can have a maximum of one order, which includes the listing price and owner information. When an order is completed or revoked, the information is cleared.

## NFTSwap Contract

### Events
The contract includes four events corresponding to the actions of listing (list), revoking (revoke), updating the price (update), and purchasing (purchase) the NFT.

``` solidity
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);    
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);
```

### Order
An `NFT` order is abstracted as the `Order` structure, which contains information about the listing price (`price`) and the owner (`owner`). The `nftList` mapping records the `NFT` series (contract address) and `tokenId` information that the order corresponds to.

```solidity
    // 定义order结构体
    struct Order{
        address owner;
        uint256 price; 
    }
    // NFT Order映射
    mapping(address => mapping(uint256 => Order)) public nftList;
```

### Fallback Function
In `NFTSwap`, users purchase `NFT` using `ETH`. Therefore, the contract needs to implement the `fallback()` function to receive `ETH`.

```solidity
    fallback() external payable{}
```

### onERC721Received

The safe transfer function of `ERC721` checks whether the receiving contract has implemented the `onERC721Received()` function and returns the correct selector. After the user places an order, the `NFT` needs to be sent to the `NFTSwap` contract. Therefore, the `NFTSwap` contract inherits the `IERC721Receiver` interface and implements the `onERC721Received()` function.

This is a smart contract named "NFTSwap" that implements the interface "IERC721Receiver". The function "onERC721Received" is defined to receive ERC721 tokens. It takes four parameters: 
- "operator": the address that called the function 
- "from": the address that transferred the token to the contract 
- "tokenId": the ID of the ERC721 token that was transferred 
- "data": additional data that can be sent with the token transfer 

The function returns the selector of the "onERC721Received" function from "IERC721Receiver" interface.

### Trading

The contract implements `4` functions related to trading:

- Listing `list()`: The seller creates an `NFT`, creates an order, and releases the `List` event. The parameters are the `NFT` contract address `_nftAddr`, corresponding `_tokenId` of `NFT`, and listing price `_price` (**Note: the unit is `wei`**). After successful, the `NFT` will transfer from the seller to the `NFTSwap` contract.

```solidity
    // List: The seller lists NFT on sale, contract address is _nftAddr, tokenId is _tokenId, price is _price in ether (unit is wei)
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public{
        IERC721 _nft = IERC721(_nftAddr); // Declare an interface contract variable IERC721
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval"); // The contract is approved
        require(_price > 0); // The price is greater than 0

        Order storage _order = nftList[_nftAddr][_tokenId]; // Set the NFT holder and price
        _order.owner = msg.sender;
        _order.price = _price;
        // Transfer NFT to the contract
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Release List event
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }
```

- `revoke()`: Seller cancels the order and releases the `Revoke` event. Parameters include the `NFT` contract address `_nftAddr` and the corresponding `_tokenId`. After successful execution, the `NFT` will be returned to the seller from the `NFTSwap` contract.

```solidity
// cancel order: seller cancels the order
function revoke(address _nftAddr, uint256 _tokenId) public {
    Order storage _order = nftList[_nftAddr][_tokenId]; // get the order
    require(_order.owner == msg.sender, "Not Owner"); // must be initiated by the owner
    // declare IERC721 interface contract variables
    IERC721 _nft = IERC721(_nftAddr);
    require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT is in the contract
    
    // transfer NFT to seller
    _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    delete nftList[_nftAddr][_tokenId]; // delete order

    // emit Revoke event
    emit Revoke(msg.sender, _nftAddr, _tokenId);
}
```

- Modify price `update()`: The seller modifies the price of the NFT order and releases the `Update` event. The parameters are the NFT contract address `_nftAddr`, the corresponding `_tokenId` of the NFT, and the updated order price `_newPrice` (**Note: The unit is `wei`**).

```solidity
    // Adjust Price: Seller adjusts the listing price
    function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Invalid Price"); // NFT price must be greater than 0
        Order storage _order = nftList[_nftAddr][_tokenId]; // Get the Order
        require(_order.owner == msg.sender, "Not Owner"); // It must be initiated by the owner
        // Declare IERC721 interface contract variable
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT is in the contract
        
        // Adjust the NFT price
        _order.price = _newPrice;
      
        // Release Update event
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }
```

- Purchase: The buyer pays with `ETH` to purchase the `NFT` on the order, and triggers the `Purchase` event. The parameters are the `NFT` contract address `_nftAddr` and the corresponding `_tokenId` of the `NFT`. Upon success, the `ETH` will be transferred to the seller and the `NFT` will be transferred from the `NFTSwap` contract to the buyer.

```solidity
    // Purchase: A buyer purchases an NFT with ETH attached, the contract address is _nftAddr, tokenId is _tokenId
    function purchase(address _nftAddr, uint256 _tokenId) payable public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // Get Order
        require(_order.price > 0, "Invalid Price"); // The NFT price is greater than 0
        require(msg.value >= _order.price, "Increase price"); // The purchase price is greater than the asking price
        // Declare IERC721 interface contract variable
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // The NFT is in the contract

        // Transfer the NFT to the buyer
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // Transfer ETH to the seller, refund any excess ETH to the buyer
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value-_order.price);

        delete nftList[_nftAddr][_tokenId]; // Delete order

        // Release Purchase event
        emit Purchase(msg.sender, _nftAddr, _tokenId, msg.value);
    }
```

## Implementation in `Remix`

### 1. Deploy the NFT contract
Refer to the [ERC721](https://github.com/AmazingAng/WTFSolidity/tree/main/34_ERC721) tutorial to learn about NFTs and deploy the `WTFApe` NFT contract.

![Deploy the NFT contract](./img/38-1.png)

Mint the first NFT to yourself. This is done so that you can perform operations such as listing the NFT and modifying its price in the future.

The `mint(address to, uint tokenId)` function takes two parameters:

`to`: The address to which the NFT will be minted. This is usually your own wallet address.

`tokenId`: Since the `WTFApe` contract defines a total of 10,000 NFTs, the first two NFTs to be minted here have `tokenId` values of `0` and `1`, respectively.

![Mint NFT](./img/38-2.png)

In the `WTFApe` contract, use `ownerOf` to confirm that you own the NFT with `tokenId` equal to 0.

The `ownerOf(uint tokenId)` function takes one parameter:

`tokenId`: `tokenId` is the unique identifier of the NFT, and in this example, it refers to the `0` id generated during the minting process described above.

![Confirming NFT ownership](./img/38-3.png)

Using the above method, mint NFTs with `tokenId` `0` and `1` for yourself. For `tokenId` `0`, execute a purchase update operation, and for `tokenId` `1`, execute a delisting operation.

### 2. Deploying the `NFTSwap` contract
Deploy the `NFTSwap` contract.

![Deploying the `NFTSwap` contract](./img/38-4.png)

### 3. Authorizing the `NFTSwap` contract to list the NFT for sale
In the `WTFApe` contract, call the `approve()` authorization function to grant permission for the `NFTSwap` contract to list the `tokenId` `0` NFT that you own for sale.

The `approve(address to, uint tokenId)` method has 2 parameters:

`to`: The address `tokenId` will be authorized to be transferred to, in this case, the address of the `NFTSwap` contract.

`tokenId`: `tokenId` is the unique identifier of the NFT, and in this example, it refers to the `0` id generated during the minting process described above.

![](./img/38-5.png)

Following the method above, authorizes the NFT with `tokenId` of `1` to the `NFTSwap` contract address.

### 4. List the NFT for Sale
Call the `list()` function of the `NFTSwap` contract to list the NFT with `tokenId` of `0` that is held by the caller on the `NFTSwap`. Set the price to 1 `wei`.

The `list(address _nftAddr, uint256 _tokenId, uint256 _price)` method has 3 parameters:

`_nftAddr`: `_nftAddr` is the NFT contract address, which in this case is the `WTFApe` contract address.

`_tokenId`: `_tokenId` is the ID of the NFT, which in this case is the minted `0` ID mentioned above.

`_price`: `_price` is the price of the NFT, which in this case is 1 `wei`.

![](./img/38-6.png)

Following the above method, list the NFT with `tokenId` of `1` that is held by the caller on the `NFTSwap` and set the price to 1 `wei`.

### 5. View Listed NFTs.

Call the `nftList()` function of the `NFTSwap` contract to view the listed NFT.

`nftList`: is a mapping of NFT Orders with the following structure:

`nftList[_nftAddr][_tokenId]`: Input `_nftAddr` and `_tokenId`, and return an NFT order.

![](./img/38-7.png)

### 6. Update NFT Price

Call the `update()` function of the `NFTSwap` contract to update the price of NFT with `tokenId` 0 to 77 `wei`.

The `update(address _nftAddr, uint256 _tokenId, uint256 _newPrice)` method has three parameters:

`_nftAddr`: `_nftAddr` is the address of the NFT contract, which in this case is the `WTFApe` contract address.

`_tokenId`: `_tokenId` is the id of the NFT, which in this case is 0, the id of the minted NFT mentioned above.

`_newPrice`: `_newPrice` is the new price of the NFT, which in this case is 77 `wei`.

After executing `update()`, call `nftList` to view the updated price.

### 5. Dismantle NFT

Call the `revoke()` function of the `NFTSwap` contract to dismantle the NFT.

In the above article, we put up two NFTs with `tokenId` of `0` and `1`, respectively. In this method, we are dismantling the NFT with `tokenId` as `1`.

The `revoke(address _nftAddr, uint256 _tokenId)` function has 2 parameters:

`_nftAddr`: The `_nftAddr` is the address of the NFT contract, which is the `WTFApe` contract address in this example.

`_tokenId`: The `_tokenId` is the id of the NFT, which is the `1` Id for the minting in this example.

Call the `nftList()` function of the `NFTSwap` contract to see that the NFT has been dismantled. It will require reauthorization to put it up again.

**Note that after taking down the NFT, you need to start again from step 3, authorize and relist the NFT before purchasing.**

### 6. Purchase `NFT`

Switch to another account and call the `purchase()` function of the `NFTSwap` contract to buy an NFT. When purchasing, you need to input the `NFT` contract address, `tokenId`, and the amount of `ETH` you want to pay.

We took down the NFT with `tokenId` 1, but there is still an NFT with `tokenId` 0 available for purchase.

The `purchase(address _nftAddr, uint256 _tokenId, uint256 _wei)` method has three parameters:

`_nftAddr`: `_nftAddr` is the NFT contract address, which is the `WTFApe` contract address in this example.

`_tokenId`: `_tokenId` is the ID of the NFT, which is 0 as we minted it earlier.

`_wei`: `_wei` is the amount of `ETH` to be paid, which is 77 `wei` in this example.

![](./img/38-11.png)

### 7. Verify change of NFT owner.

After a successful purchase, calling the `ownerOf()` function of the `WTFApe` contract shows that the `NFT` owner has changed, indicating a successful purchase!

In summary, in this lecture, we built a zero-fee decentralized `NFT` exchange. Although `OpenSea` has made significant contributions to the development of `NFTs`, its disadvantages are also very obvious: high transaction fees, no reward for users, and trading mechanisms that can easily lead to phishing attacks, causing users to lose their assets. Currently, new `NFT` trading platforms such as `Looksrare` and `dydx` are challenging the position of `OpenSea`, and `Uniswap` is also researching new `NFT` exchanges. We believe that in the near future, we will have better `NFT` exchanges to use.