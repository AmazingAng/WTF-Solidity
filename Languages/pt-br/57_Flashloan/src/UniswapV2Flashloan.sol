// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// Interface de retorno de chamada do empréstimo relâmpago UniswapV2
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// Contrato de empréstimo relâmpago UniswapV2
contract UniswapV2Flashloan is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
    }

    // Função de Empréstimo Relâmpago
    function flashloan(uint wethAmount) external {
        // O comprimento do calldata deve ser maior que 1 para acionar a função de callback do empréstimo relâmpago.
        bytes memory data = abi.encode(WETH, wethAmount);

        // amount0Out é o valor de DAI a ser emprestado, amount1Out é o valor de WETH a ser emprestado
        pair.swap(0, wethAmount, address(this), data);
    }

    // Função de retorno do empréstimo relâmpago, só pode ser chamada pelo contrato DAI/WETH pair
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // Confirm that the called contract is the DAI/WETH pair contract
        // Obter o endereço do token0
        // Obter endereço do token1
        // garantir que msg.sender é um par V2

        // Decodificando calldata
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // lógica de flashloan, omitida aqui
        require(tokenBorrow == WETH, "token borrow != WETH");

        // Calcular o custo do flashloan
        // taxa / (valor + taxa) = 3/1000
        // Arredondar para cima
        uint fee = (amount1 * 3) / 997 + 1;
        uint amountToRepay = amount1 + fee;

        // Devolver empréstimo relâmpago
        weth.transfer(address(pair), amountToRepay);
    }
}
