// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Centralization is ERC20, Ownable {
    constructor() ERC20("Centralization", "Cent") {
        address exposedAccount = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
        transferOwnership(exposedAccount);
    }

    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }
}