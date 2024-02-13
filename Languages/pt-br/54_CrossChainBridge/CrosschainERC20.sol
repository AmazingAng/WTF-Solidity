// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainToken is ERC20, Ownable {
    
    // Evento de Ponte
    event Bridge(address indexed user, uint256 amount);
    // Evento Mint
    event Mint(address indexed to, uint256 amount);

    /**
     * @param name Nome do Token
     * @param symbol Símbolo do Token
     * @param totalSupply Suprimento do Token
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }

    /**
     * Função de ponte
     * @param amount: quantidade de tokens a serem queimados na cadeia atual e criados na outra cadeia
     */
    function bridge(uint256 amount) public {
        _burn(msg.sender, amount);
        emit Bridge(msg.sender, amount);
    }

    /**
     * Função de criação
     */
    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }
}

