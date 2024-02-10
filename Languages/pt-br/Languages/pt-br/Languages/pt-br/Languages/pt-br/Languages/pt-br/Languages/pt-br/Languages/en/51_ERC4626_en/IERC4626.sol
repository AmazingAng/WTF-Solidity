// SPDX-License-Identifier: MIT
// Author: 0xAA from WTF Academy

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev ERC4626 "Tokenized Vaults Standard" interface contract
 * https://eips.ethereum.org/EIPS/eip-4626.
 */
interface IERC4626 is IERC20, IERC20Metadata {
    /*//////////////////////////////////////////////////////////////
                                 event
    //////////////////////////////////////////////////////////////*/
    // triggered when depositing
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    // triggered when withdrawing
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                            metadata
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev returns the address of the underlying asset token of the vault (used for deposit and withdrawal)
     * - has to be ERC20 token contract address
     * - cannot revert
     */
    function asset() external view returns (address assetTokenAddress);

    /*//////////////////////////////////////////////////////////////
                        deposit/withdraw logic
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev deposit function: user deposit ${assets} units of underlying asset to vault, 
     * and the contract mints ${shares} unit vault share to receiver's address
     *
     * - has to emit Deposit event
     * - if asset cannot be deposited succuessfully, must revert. e.g. when deposit amount exceeds limit
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev mint function: users deposit ${assets} units of the underlying asset 
     *      and the contract mints the corresponding amount of the vault's shares to the receiver's address
     * - has to emit Deposit event 
     * - if it cannot mint, must revert. e.g. minting amount exceeds limit
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev withdraw function: owner address burns ${share} units of the vault's shares, 
     *      and the contract transfers the corresponding amount of the underlying asset to the receiver address
     *
     * - emit Withdraw event
     * - if all assets cannot be withdrew, it will revert
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev redeem function: owner address burns ${share} units of the vault's shares, 
     *      and the contract transfers the corresponding amount of the underlying asset to the receiver address
     *
     * - emit Withdraw event
     * - if vault's share cannot be redeemed, then revert
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                            Accounting Logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev returns the total amount of underlying asset tokens managed in the vault
     *
     * - include interest
     * - include fee
     * - cannot revert
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev returns the amount of vault shares that can be obtained by using a certain amount of the underlying asset

     * - do not include fee
     * - do not include slippage
     * - cannot revert
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev returns the amount of underlying asset that can be obtained by using a certain amount of vault shares
     *
     * - do not include fee
     * - do not include slippage
     * - cannot revert
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev used by both on-chain and off-chain users to simulate the amount of vault shares they can obtain by depositing a certain amount of the underlying asset in the current on-chain environment
     *
     * - the return value should be close to and not greater than the vault amount obtained by depositing in the same transaction
     * - do not consider about restrictions like maxDeposit, assume that user deposit will succeed
     * - consider fee
     * - cannot revert
     * NOTE: use the difference of the return values of convertToAssets and previewDeposit to calculate slippage
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev used by both on-chain and off-chain users to simulate the amount of underlying asset needed to mint a certain amount of vault shares in the current on-chain environment
     * - the return value should be close to and not less than the deposit amount required to mint a certain amount of vault amount in the same transaction.
     * - do not consider about restrictions like maxMint, assume that user mint transaction will succeed
     * - consider fee
     * - cannot revert
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev used by both on-chain and off-chain users to simulate the amount of vault shares they need to redeem to withdraw a certain amount of the underlying asset in the current on-chain environment
     * - the return value should be close to and not greater than the vault share needed to redeem a certain amount of underlying asset withdrawn in the same transaction.
     * - do not consider about restrictions like maxWithdraw, assume that user withdraw transaction will succeed
     * - consider fee
     * - cannot revert
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev used by on-chain and off-chain users to simulate the amount of underlying asset they can redeem by burning a certain amount of vault shares in the current on-chain environment
     * - the return value should be close to and not less than the amount of underlying asset that can be redeemed by the vault amount burnt in the same transaction.
     * - do not consider about restrictions like maxRedeem, assume that user redeem transaction will succeed
     * - consider fee
     * - cannot revert
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                    deposit/widthdrawal limit logic
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev returns the maximum amount of underlying asset that can be deposited in a single transaction for a given user address.
     * - if there is max deposit limit, return value should be a finite value
     * - return value should not be greater than 2 ** 256 - 1 
     * - cannot revert
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev returns the maximum vault amount that can be minted in a single transaction for a given user address.
     * - f there is max mint limit, return value should be a finite value
     * - return value should not be greater than 2 ** 256 - 1 
     * - cannot revert
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev returns the maximum amount of underlying asset that can be withdrawn in a single transaction for a given user address.
     * - return value should be a finite value
     * - cannot revert
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev returns the maximum vault amount that can be redeemed in a single transaction for a given user address.
     * - return value should be a finite value
     * - if there are no other restrictions, the return value should be balanceOf(owner)
     * - cannot revert
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);
}