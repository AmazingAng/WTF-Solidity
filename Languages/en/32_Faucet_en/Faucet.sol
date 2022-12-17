// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;

import "./IERC20.sol"; //import IERC20

contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;   //Total supply of tokens 

    string public name;   // token name
    string public symbol;  //token symbol
    
    uint8 public decimals = 18; // decimal digits

    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // @dev Implement`transfer`function, logic of token transfer
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev Implement `approve` function, logic of token approval
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev Implement`transferFrom` function, logic of token approved transfer
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

    // @dev to mint tokens, transfer from the address '0'  to the caller's address
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev to burn tokens, transfer from the caller's address to the address '0'
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

// the contract of token faucet
contract Faucet {

    uint256 public amountAllowed = 100; // to collect 100 units token
    address public tokenContract;   // the address of token contract
    mapping(address => bool) public requestedAddress;   // to record the address where the token was received

    // SendToken event   
    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    // set the ERC20 token contract when deploying
    constructor(address _tokenContract) {
        tokenContract = _tokenContract; // set token contract
    }

    // function for users to claim tokens
    function requestTokens() external {
        require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!"); // Each address can only receive tokens once
        IERC20 token = IERC20(tokenContract); // Create IERC20 contract object
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); // Faucet is empty

        token.transfer(msg.sender, amountAllowed); // transfer token
        requestedAddress[msg.sender] = true; // to record the address where the token was received 
        
        emit SendToken(msg.sender, amountAllowed); // emit SendToken event
    }
}