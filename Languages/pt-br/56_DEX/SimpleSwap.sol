// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {
    // Contrato de token
    IERC20 public token0;
    IERC20 public token1;

    // Reserva de tokens
    uint public reserve0;
    uint public reserve1;
    
    // Evento
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    // Construtor, inicializa o endereço do token
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    // Pegue o valor mínimo entre dois números
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // Calcular a raiz quadrada pelo método babilônico (https://pt.wikipedia.org/wiki/M%C3%A9todos_de_c%C3%A1lculo_de_raiz_quadrada#M%C3%A9todo_babil%C3%B4nico)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Adicionar liquidez, trocar tokens, criar LP.
    // Se for a primeira vez que está sendo adicionado, a quantidade de LP criada será igual a sqrt(amount0 * amount1)
    // Se não for a primeira vez, a quantidade de LPs criados = min(amount0/reserve0, amount1/reserve1) * totalSupply_LP
    // @param amount0Desired Quantidade de token0 a ser adicionada
    // @param amount1Desired Quantidade de token1 a ser adicionada
    function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
        // Transfer the added liquidity to the Swap contract, authorization to the Swap contract must be given in advance.
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        // Calcular a liquidez adicionada
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // Se for a primeira vez que a liquidez é adicionada, crie tokens LP (provedores de liquidez) com uma quantidade de L = sqrt(x * y) unidades.
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            // Se não for a primeira vez que a liquidez é adicionada, cunhe LP com base na proporção da quantidade de tokens adicionados, usando a proporção do menor dos dois tokens.
            liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

        // Verificando a quantidade de LP fundidos
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // Atualizar estoque
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // Dar aos provedores de liquidez a capacidade de criar tokens LP que representam a liquidez fornecida.
        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    // Remover a liquidez, destruir LP, transferir tokens.
    // A quantidade transferida = (liquidez / totalSupply_LP) * reserva
    // @param liquidity Quantidade de liquidez a ser removida
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        // Obter saldo
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        // Calcular a quantidade de tokens a serem transferidos com base na proporção de LP
        uint _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        // Verificando a quantidade de tokens
        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        // Destruir LP
        _burn(msg.sender, liquidity);
        // Transferir tokens
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        // Atualizar estoque
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    // Dado a quantidade de um ativo e as reservas de um par de tokens, calcula a quantidade de troca para outro token
    // Devido ao produto ser constante
    // Antes da troca: k = x * y
    // Troca: k = (x + delta_x) * (y + delta_y)
    // Pode-se obter delta_y = - delta_x * y / (x + delta_x)
    // O sinal de mais/menos representa entrada/saída
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    // swap tokens
    // @param amountIn Quantidade de tokens para troca
    // @param tokenIn Endereço do contrato de token a ser trocado
    // @param amountOutMin Quantidade mínima de troca para a outra moeda
    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if(tokenIn == token0){
            // Se for uma troca de token0 por token1
            tokenOut = token1;
            // Calcular a quantidade de token1 que pode ser trocada
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // Realizar troca
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            // Se for token1, troque por token0
            tokenOut = token0;
            // Calcular a quantidade de token1 que pode ser trocada
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // Realizar troca
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        // Atualizar estoque
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}