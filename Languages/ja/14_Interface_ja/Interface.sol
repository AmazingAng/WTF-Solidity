// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

abstract contract InsertionSort{
    function insertionSort(uint[] memory a) public pure virtual returns(uint[] memory);
}

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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

contract interactBAYC {
    // Use BAYC address to create interface contract variables (ETH Mainnet)
    //（インターフェースコントラクト変数を作成する為にBAYCアドレスを使用します(ETH Mainnet)）
    IERC721 BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    // Call BAYC's balanceOf() to query the open interest through the interface
    //（インターフェースを通してopen interest"所有者の残高(保有数)"を照会する為にBAYCのbalanceOf()を呼び出します）
    function balanceOfBAYC(address owner) external view returns (uint256 balance){
        return BAYC.balanceOf(owner);
    }

    // Safe transfer by calling BAYC's safeTransferFrom() through the interface
    //（インターフェースを通してBAYCのsafeTransferFrom()を呼び出すことによって安全な転送を実現します）
    function safeTransferFromBAYC(address from, address to, uint256 tokenId) external{
        BAYC.safeTransferFrom(from, to, tokenId);
    }
}
