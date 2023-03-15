// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.0;

import "../31_ERC20_en/IERC20.sol";
import "../31_ERC20_en/ERC20.sol";

/**
 * @dev ERC20 token time lock contract. Beneficiaries can only remove tokens after a period of time in the lock.
 */
contract TokenLocker {
    // Event
    event TokenLockStart(
        address indexed beneficiary,
        address indexed token,
        uint256 startTime,
        uint256 lockTime
    );
    event Release(
        address indexed beneficiary,
        address indexed token,
        uint256 releaseTime,
        uint256 amount
    );

    // Locked ERC20 token contracts
    IERC20 public immutable token;
    // Beneficiary address
    address public immutable beneficiary;
    // Lockup time (seconds)
    uint256 public immutable lockTime;
    // Lockup start timestamp (seconds)
    uint256 public immutable startTime;

    /**
     * @dev Deploy the time lock contract, initialize the token contract address, beneficiary address and lock time.
     * @param token_: Locked ERC20 token contract
     * @param beneficiary_: Beneficiary address
     * @param lockTime_: Lockup time (seconds)
     */
    constructor(IERC20 token_, address beneficiary_, uint256 lockTime_) {
        require(lockTime_ > 0, "TokenLock: lock time should greater than 0");
        token = token_;
        beneficiary = beneficiary_;
        lockTime = lockTime_;
        startTime = block.timestamp;

        emit TokenLockStart(
            beneficiary_,
            address(token_),
            block.timestamp,
            lockTime_
        );
    }

    /**
     * @dev After the lockup time, the tokens are released to the beneficiaries.
     */
    function release() public {
        require(
            block.timestamp >= startTime + lockTime,
            "TokenLock: current time is before release time"
        );

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");

        token.transfer(beneficiary, amount);

        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
}
