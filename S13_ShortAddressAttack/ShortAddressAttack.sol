// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Coin {
    address owner;
    mapping (address => uint256) public balances;

    modifier OwnerOnly() { 
        require(msg.sender == owner); _; 
    }

    function ICoin() public { 
        owner = msg.sender; 
    }

    function approve(address _to, uint256 _amount) public OwnerOnly { 
        balances[_to] += _amount; 
    }
    
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] > _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
}