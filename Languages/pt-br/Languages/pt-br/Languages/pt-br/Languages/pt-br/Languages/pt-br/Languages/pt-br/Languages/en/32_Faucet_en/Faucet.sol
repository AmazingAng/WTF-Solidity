// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;

import "./IERC20.sol"; //import IERC20

contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;   // total supply of the token

    string public name;   // the name of the token
    string public symbol;  // the symbol of the token
    
    uint8 public decimals = 18; // decimal places of the token
    
    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // @dev Implements the `transfer` function, which handles token transfers logic.
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev Implements `approve` function, which handles token authorization logic.
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev Implements `transferFrom` function，which handles token authorized transfer logic.
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // @dev Creates tokens, transfers `amouont` of tokens from `0` address to caller's address.
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev Destroys tokens，transfers `amouont` of tokens from caller's address to `0` address.
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

// The faucet contract of the ERC20 token
contract Faucet {

    uint256 public amountAllowed = 100; // the allowed amount for each request is 100
    address public tokenContract;   // contract address of the token
    mapping(address => bool) public requestedAddress;   // a map contains requested address

    // Event SendToken
    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    // Set the ERC20'S contract address during deployment
    constructor(address _tokenContract) {
        tokenContract = _tokenContract; // set token contract
    }

    // Function for users to request tokens
    function requestTokens() external {
        require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!"); // Only one request per address
        IERC20 token = IERC20(tokenContract); // Create an IERC20 contract object
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); // Faucet is empty

        token.transfer(msg.sender, amountAllowed); // Send token
        requestedAddress[msg.sender] = true; // Record the requested address
        
        emit SendToken(msg.sender, amountAllowed); // Emit SendToken event
    }
}
