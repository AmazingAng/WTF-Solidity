// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MCERC20 is ERC20{
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}