// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // 构造函数，初始化NFT合集的名称、代号
    constructor() ERC721("", ""){}

    // 铸造函数：当区块时间能被7整除时才能mint成功
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}