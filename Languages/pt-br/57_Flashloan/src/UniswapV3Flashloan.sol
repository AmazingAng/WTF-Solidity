// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// Interface de retorno de chamada do empréstimo relâmpago UniswapV3
// Precisa implementar e sobrescrever a função uniswapV3FlashCallback()
interface IUniswapV3FlashCallback {
    /// No processo de implementação, você deve reembolsar os tokens enviados pelo flash e o valor calculado das taxas na piscina.
    /// O contrato que chama este método deve ser verificado pelo UniswapV3Pool implantado pela UniswapV3Factory oficial.
    /// @param fee0 Valor da taxa a ser paga em token0 para o pool quando o empréstimo relâmpago for encerrado
    /// @param fee1 Valor da taxa a ser paga em token1 para o pool quando o empréstimo relâmpago for encerrado
    /// @param data Dados passados pelo chamador através da chamada flash de IUniswapV3PoolActions.
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// Contrato de empréstimo relâmpago UniswapV3
contract UniswapV3Flashloan is IUniswapV3FlashCallback {
    address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant poolFee = 3000;

    IERC20 private constant weth = IERC20(WETH);
    IUniswapV3Pool private immutable pool;

    constructor() {
        pool = IUniswapV3Pool(getPool(DAI, WETH, poolFee));
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) public pure returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return PoolAddress.computeAddress(UNISWAP_V3_FACTORY, poolKey);
    }

    // Função de Empréstimo Relâmpago
    function flashloan(uint wethAmount) external {
        bytes memory data = abi.encode(WETH, wethAmount);
        IUniswapV3Pool(pool).flash(address(this), 0, wethAmount, data);
    }

    // Função de retorno do empréstimo relâmpago, só pode ser chamada pelo contrato DAI/WETH pair
    function uniswapV3FlashCallback(
        uint fee0,
        uint fee1,
        bytes calldata data
    ) external {
        // Confirm that the called contract is the DAI/WETH pair contract
        require(msg.sender == address(pool), "not authorized");
        
        // Decodificando calldata
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // lógica de flashloan, omitida aqui
        require(tokenBorrow == WETH, "token borrow != WETH");

        // Devolver empréstimo relâmpago
        weth.transfer(address(pool), wethAmount + fee1);
    }
}