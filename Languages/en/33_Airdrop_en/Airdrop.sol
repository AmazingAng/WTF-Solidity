// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;

import "./IERC20.sol"; //import IERC20

/// @notice Transfer ERC20 tokens to multiple addresses
contract Airdrop {
    /// @notice Transfer ERC20 tokens to multiple addresses, authorization is required before use
    ///
    /// @param _token The address of ERC20 token for transfer
    /// @param _addresses The array of airdrop addresses
    /// @param _amounts The array of amount of tokens (airdrop amount for each address)
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
        ) external {
        // Check: The length of _addresses array should be equal to the length of _amounts array
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 token = IERC20(_token); // Declare IERC contract variable
        uint _amountSum = getSum(_amounts); // Calculate the total amount of airdropped tokens
        // Check: The authorized amount of tokens should be greater than or equal to the total amount of airdropped tokens
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");
        
        // for loop, use transferFrom function to send airdrops
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    /// Transfer ETH to multiple addresses
    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) public payable {
        // Check: _addresses and _amounts arrays should have the same length
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        // Calculate total amount of ETH to be airdropped
        uint _amountSum = getSum(_amounts);
        // Check: transferred ETH should equal total amount
        require(msg.value == _amountSum, "Transfer amount error");
        // Use a for loop to transfer ETH using transfer function
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }


    // sum function for arrays
    function getSum(uint256[] calldata _arr) public pure returns(uint sum)
    {
        for(uint i = 0; i < _arr.length; i++)
            sum = sum + _arr[i];
    }
}


// The contract of ERC20 token 
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
