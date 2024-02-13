// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.0;

import "../31_ERC20/IERC20.sol";
import "../31_ERC20/ERC20.sol";

/**
 * @dev Contrato de bloqueio de tempo para tokens ERC20. O beneficiário só pode retirar os tokens após um período de bloqueio.
 */
contract TokenLocker {

    // Eventos
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);

    // Contrato de token ERC20 bloqueado
    IERC20 public immutable token;
    // Endereço do beneficiário
    address public immutable beneficiary;
    // Tempo de bloqueio (segundos)
    uint256 public immutable lockTime;
    // Tempo de início de bloqueio (em segundos)
    uint256 public immutable startTime;

    /**
     * @dev Deploy the time lock contract, initialize the token contract address, beneficiary address, and lock time.
     * @param token_: ERC20 token contract to be locked
     * @param beneficiary_: Beneficiary address
     * @param lockTime_: Lock time (in seconds)
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 lockTime_
    ) {
        require(lockTime_ > 0, "TokenLock: lock time should greater than 0");
        token = token_;
        beneficiary = beneficiary_;
        lockTime = lockTime_;
        startTime = block.timestamp;

        emit TokenLockStart(beneficiary_, address(token_), block.timestamp, lockTime_);
    }

    /**
     * @dev Após o período de bloqueio, os tokens serão liberados para o beneficiário.
     */
    function release() public {
        require(block.timestamp >= startTime+lockTime, "TokenLock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");

        token.transfer(beneficiary, amount);

        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
}