
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Logger.sol";
contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    uint256 public override totalSupply;   // 代币总供给

    string public name;   // 名称
    string public symbol;  // 符号
    
    uint8 public decimals = 18; // 小数位数
    Logger logger;

    // @dev 在合约部署的时候实现合约名称和符号
    constructor(string memory name_, string memory symbol_,Logger _logger){
        name = name_;
        symbol = symbol_;
        logger = Logger(_logger);
    }

    // @dev 实现`transfer`函数，代币转账逻辑
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        logger.log(msg.sender, "transfer");
        return true;
    }

    // @dev 铸造代币，从 `0` 地址转账给 调用者地址
    function mint(uint amount) external payable{
        require(msg.value == amount*0.01 ether,"insufficient ETH");
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        logger.log(msg.sender, "mint");
    }

}

