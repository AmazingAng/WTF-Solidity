// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC4626} from "./IERC4626.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev ERC4626 "Tokenized Vaults Standard" contract. 
 * FOR TEACHING PURPOSE ONLY, DO NOT USE IN PRODUCTION
 */
contract ERC4626 is ERC20, IERC4626 {
    /*//////////////////////////////////////////////////////////////
                            state variables
    //////////////////////////////////////////////////////////////*/
    ERC20 private immutable _asset; // 
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();

    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /**
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                        deposit/withdrawal logic
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // use previewDeposit() to calculate vault share to be retained
        shares = previewDeposit(assets);
        
        // transfer first then mint, prevent reentrancy attack
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // emit Deposit event
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        // use previewDeposit() to calculate amount of underlyting asset that needs to be deposited
        assets = previewMint(shares);

        // transfer first then mint, prevent reentrancy attack
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // emit Deposit event
        emit Deposit(msg.sender, receiver, assets, shares);

    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        // use previewWithdraw() to calculate vault share that will be burnt
        shares = previewWithdraw(assets);

        // if caller is not owner,  check and update allownance
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // burn first then transfer, prevent reentrancy attack
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // emit Withdraw event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // use previewRedeem() to calculate the amount of underlying asset that can be redeemed
        assets = previewRedeem(shares);

        // if caller is not owner, check and update allownance
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // burn first then transfer, prevent reentrancy attack
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // emit Withdraw event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            accounting logic
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256){
        // returns balance of underlying asset for this contract
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // if supply is 0, then mint vault share at 1:1 ratio
        // if supply is not 0, then mint vault share at actual ratio
        return supply == 0 ? assets : assets * supply / totalAssets();
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // if supply is 0, then redeem underlying asset at 1:1 ratio
        // if supply is not 0, then redeem underlying asset at actual ratio
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }
    
    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }
    
    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}