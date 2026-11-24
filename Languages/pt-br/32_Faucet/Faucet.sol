// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.34;

import "./IERC20.sol";

contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // @dev Implement the `transfer` function, logic for token transfer
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev Implement the `approve` function, token authorization logic
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev Implement the `transferFrom` function, which handles token transfer with authorization
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

    // @dev Cunhar tokens e transferir do endereço `0` para o endereço do chamador
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev Destruir tokens, transferindo-os do endereço do chamador para o endereço `0`
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

// Contrato de torneira para tokens ERC20
contract Faucet {

    uint256 public amountAllowed = 100;
    address public tokenContract;
    mapping(address => bool) public requestedAddress;

    // Evento SendToken
    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    // Ao implantar, defina o contrato de token ERC2.
    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    // Função para o usuário receber tokens
    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract);
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");
        requestedAddress[msg.sender] = true;
        require(token.transfer(msg.sender, amountAllowed), "Token transfer failed");
        emit SendToken(msg.sender, amountAllowed);
    }
}
