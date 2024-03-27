
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC4626} from "./IERC4626.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Contrato ERC4626 "Padrão de Tesouraria Tokenizada", apenas para uso educacional, não utilizar em produção
 */
contract ERC4626 is ERC20, IERC4626 {
    //////////////////////////////////////////////////////////////
                    状态变量
    //////////////////////////////////////////////////////////////*/
    //
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();

    }

    /** @dev Veja {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /**
     * Veja {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    //////////////////////////////////////////////////////////////
                        存款/提款逻辑
    //////////////////////////////////////////////////////////////*/
    /** @dev Veja {IERC4626-depositar}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Utilizando o previewDeposit() para calcular a participação no cofre que será obtida
        shares = previewDeposit(assets);

        // Primeiro transferir e depois criar, para evitar reentrância
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // Liberar o evento de Depósito
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /** @dev Veja {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        // Usando previewMint() para calcular a quantidade de ativos básicos necessários para depósito
        assets = previewMint(shares);

        // Primeiro transferir e depois criar, para evitar reentrância
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // Liberar o evento de Depósito
        emit Deposit(msg.sender, receiver, assets, shares);

    }

    /** @dev Veja {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        // Utilizando o previewWithdraw() para calcular a quantidade de ações do cofre a serem destruídas.
        shares = previewWithdraw(assets);

        // Se o chamador não for o proprietário, verifique e atualize a autorização
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Primeiro destrua e depois transfira para evitar reentrância
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // Liberar a função Withdraw
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /** @dev Veja {IERC4626-resgatar}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // Usando previewRedeem() para calcular a quantidade de ativos básicos que podem ser resgatados
        assets = previewRedeem(shares);

        // Se o chamador não for o proprietário, verifique e atualize a autorização
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Primeiro destrua e depois transfira para evitar reentrância
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // Liberando a função Withdraw
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    //////////////////////////////////////////////////////////////
                            会计逻辑
    //////////////////////////////////////////////////////////////*/
    /** @dev Veja {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256){
        // Retorna a posição do ativo subjacente no contrato
        return _asset.balanceOf(address(this));
    }

    /** @dev Veja {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // Se o fornecimento for 0, então a cota do cofre será de 1:1.
        // Se o fornecimento não for zero, então cunhe proporcionalmente.
        return supply == 0 ? assets : assets * supply / totalAssets();
    }

    /** @dev Veja {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // Se o fornecimento for 0, então resgate os ativos subjacentes na proporção de 1:1.
        // Se o fornecimento não for zero, resgate proporcionalmente.
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }

    /** @dev Veja {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev Veja {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /** @dev Veja {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev Veja {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    //////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/
    /** @dev Veja {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev Veja {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }
    
    /** @dev Veja {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }
    
    /** @dev Veja {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}