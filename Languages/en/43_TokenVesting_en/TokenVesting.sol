// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.0;

import "../31_ERC20_en/ERC20.sol";

/**
 * @title ERC20 token linear release"
 * @dev This contract releases the ERC20 tokens linearly to the beneficiary `_beneficiary`.
 * The released tokens can be one type or multiple types.The release period is defined by the start time `_start` and the duration `_duration`.
 * All tokens transferred to this contract will follow the same linear release cycle,And the beneficiary needs to call the `release()` function to extract.
 * The contract is simplified from OpenZeppelin's VestingWallet.
 */
contract TokenVesting {
    // Event
    event ERC20Released(address indexed token, uint256 amount); // Withdraw event

    // State variables
    mapping(address => uint256) public erc20Released; // Token address -> release amount mapping, recording the number of tokens the beneficiary has received
    address public immutable beneficiary; // Beneficiary address
    uint256 public immutable start; // Start timestamp
    uint256 public immutable duration; // Duration

    /**
     * @dev Initialize the beneficiary address,release duration (seconds),start timestamp (current blockchain timestamp)
     */
    constructor(address beneficiaryAddress, uint256 durationSeconds) {
        require(
            beneficiaryAddress != address(0),
            "VestingWallet: beneficiary is zero address"
        );
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    /**
     * @dev Beneficiary withdraws the released tokens.
     * Calls the vestedAmount() function to calculate the amount of tokens that can be withdrawn, then transfer them to the beneficiary.
     * Emit an {ERC20Released} event.
     */
    function release(address token) public {
        // Calls the vestedAmount() function to calculate the amount of tokens that can be withdrawn.
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) -
            erc20Released[token];
        // Updates the amount of tokens that have been released.
        erc20Released[token] += releasable;
        // Transfers the tokens to the beneficiary.
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    /**
     * @dev According to the linear release formula, calculate the released quantity. Developers can customize the release method by modifying this function.
     * @param token: Token address
     * @param timestamp: Query timestamp
     */
    function vestedAmount(
        address token,
        uint256 timestamp
    ) public view returns (uint256) {
        // Total amount of tokens received in the contract (current balance + withdrawn)
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) +
            erc20Released[token];
        // According to the linear release formula, calculate the released quantity
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}
