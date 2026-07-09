// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Free mint取引をフロントランニングしてみる
contract FreeMint is ERC721 {
    uint256 public totalSupply;

    // コンストラクタ、NFTコレクションの名前、シンボルを初期化
    constructor() ERC721("Free Mint NFT", "FreeMint"){}

    // ミント関数
    function mint() external {
        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}