// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
// Token ERC20 de Pixiu extremamente simples, apenas para compra, não é possível vender.
contract HoneyPot is ERC20, Ownable {
    address public pair;
    // Construtor: inicializa o nome e o código do token
    constructor() ERC20("HoneyPot", "Pi Xiu") Ownable(msg.sender){
        // goerli uniswap v2 factory
        // Endereço do token Pixiu
        // goerli WETH
        //Ordenar tokenA e tokenB em ordem crescente
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // calcular endereço do par
        pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        salt,
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        )))));
    }
    
    /**
     * Função de construção, apenas o proprietário do contrato pode chamar
     */
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

  /**
     * @dev Veja {ERC20-_update}.
     * Função Pixiu: apenas o proprietário do contrato pode vender
    */
    function _update(
      address from,
      address to,
      uint256 amount
  ) internal virtual override {
     if(to == pair){
        require(from == owner(), "Can not Transfer");
      }
      super._update(from, to, amount);
  }
}