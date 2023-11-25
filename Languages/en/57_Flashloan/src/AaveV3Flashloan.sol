// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

interface IFlashLoanSimpleReceiver {
     /**
     * @notice performs operations after receiving flash loan assets
     * @dev ensures that the contract can pay off the debt + additional fees, e.g. with
     * Sufficient funds to repay and Pool has been approved to withdraw the total amount
     * @param asset The address of the flash loan asset
     * @param amount The amount of flash loan assets
     * @param premium The fee for lightning borrowing assets
     * @param initiator The address where flash loans are initiated
     * @param params byte encoding parameters passed when initializing flash loan
     * @return True if the operation is executed successfully, False otherwise
     */
     function executeOperation(
         address asset,
         uint256 amount,
         uint256 premium,
         address initiator,
         bytes calldata params
     ) external returns (bool);
}

// AAVE V3 flash loan contract
contract AaveV3Flashloan {
     address private constant AAVE_V3_POOL =
         0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

     address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

     ILendingPool public aave;

     constructor() {
         aave = ILendingPool(AAVE_V3_POOL);
     }

     // Flash loan function
     function flashloan(uint256 wethAmount) external {
         aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
     }

     // Flash loan callback function can only be called by the pool contract
     function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
         external
         returns (bool)
     {
         // Confirm that the call is DAI/WETH pair contract
         require(msg.sender == AAVE_V3_POOL, "not authorized");
         // Confirm that the initiator of the flash loan is this contract
         require(initiator == address(this), "invalid initiator");

         // flashloan logic, omitted here

         // Calculate flashloan fees
         // fee = 5/1000 * amount
         uint fee = (amount * 5) / 10000 + 1;
         uint amountToRepay = amount + fee;

         //Repay flash loan
         IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

         return true;
     }
}
