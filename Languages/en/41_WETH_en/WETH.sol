// SPDX-License-Identifier: MIT
// author: 0xAA
// original contract on ETH: https://rinkeby.etherscan.io/token/0xc778417e063141139fce010982780140aa0cd5ab?a=0xe16c1623c1aa7d919cd2241d8b36d9e79c1be2a2#code
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20{
    // Events: deposits and withdrawals
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    // Constructor, initialize the name and code of ERC20
    constructor() ERC20("WETH", "WETH"){
    }

    // Callback function, when the user transfers ETH to the WETH contract, the deposit() function will be triggered
    fallback() external payable {
        deposit();
    }
    // Callback function, when the user transfers ETH to the WETH contract, the deposit() function will be triggered
    receive() external payable {
        deposit();
    }

    // Deposit function, when the user deposits ETH, mint the same amount of WETH for him
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

// Withdrawal function, the user destroys WETH and gets back the same amount of ETH
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
}
