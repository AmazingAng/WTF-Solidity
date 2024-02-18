---
title: 56. Exchange Descentralizada
tags:
  - solidity
  - erc20
  - defi
---

# WTF Introdução Simples ao Solidity: 56. Exchange Descentralizada

Recentemente, tenho estudado Solidity novamente para revisar os detalhes e escrever um "WTF Introdução Simples ao Solidity" para iniciantes (programadores experientes podem procurar outros tutoriais). Serão lançadas de 1 a 3 aulas por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta aula, vamos apresentar o Constant Product Automated Market Maker (CPAMM), que é o mecanismo central das exchanges descentralizadas (DEX) como Uniswap, PancakeSwap, entre outras. O contrato de ensino é uma simplificação do contrato [Uniswap-v2](https://github.com/Uniswap/v2-core), incluindo as funcionalidades centrais do CPAMM.

## Market Maker Automatizado

O Market Maker Automatizado (Automated Market Maker, AMM) é um algoritmo ou um contrato inteligente que permite a negociação descentralizada de ativos digitais. A introdução do AMM criou uma nova forma de negociação, sem a necessidade de correspondência de pedidos entre compradores e vendedores tradicionais, mas sim através de uma fórmula matemática predefinida (como a fórmula do produto constante) que cria uma pool de liquidez, permitindo que os usuários negociem a qualquer momento.

![](./img/56-1.png)

A seguir, vamos usar o mercado de Coca-Cola ($COLA) e dólar ($USD) como exemplo para explicar o AMM. Para facilitar, vamos definir os seguintes símbolos: $x$ e $y$ representam a quantidade total de Coca-Cola e dólar no mercado, $\Delta x$ e $\Delta y$ representam a variação da quantidade de Coca-Cola e dólar em uma transação, $L$ e $\Delta L$ representam a liquidez total e a variação da liquidez.

### Market Maker Automatizado com Soma Constante

O Market Maker Automatizado com Soma Constante (Constant Sum Automated Market Maker, CSAMM) é o modelo mais simples de AMM, e vamos começar por ele. A restrição durante a negociação é:

$$k=x+y$$

onde $k$ é uma constante. Isso significa que a soma das quantidades de Coca-Cola e dólar no mercado permanece constante antes e depois da negociação. Por exemplo, se houver 10 garrafas de Coca-Cola e $10 de dólar na liquidez do mercado, então $k=20$ e o preço da Coca-Cola é de $1 por garrafa. Se eu estiver com sede e quiser trocar $2 por Coca-Cola, a quantidade total de dólar no mercado será reduzida para $12, mantendo a restrição $k=20$, e a quantidade de Coca-Cola será reduzida para 8 garrafas, mantendo o preço de $1 por garrafa. Eu recebi 2 garrafas de Coca-Cola por $2, ou seja, $1 por garrafa.

A vantagem do CSAMM é que ele garante que o preço relativo dos tokens permaneça constante, o que é importante em trocas de stablecoins, onde todos esperam que 1 USDT possa sempre ser trocado por 1 USDC. No entanto, a desvantagem é que a liquidez é facilmente esgotada: eu só preciso de $10 para esgotar a liquidez de Coca-Cola no mercado, e outros usuários que queiram comprar Coca-Cola não poderão mais fazer isso.

A seguir, vamos apresentar o Market Maker Automatizado com Produto Constante, que possui "liquidez infinita".

### Market Maker Automatizado com Produto Constante

O Market Maker Automatizado com Produto Constante (Constant Product Automated Market Maker, CPAMM) é o modelo mais popular de AMM, e foi adotado pela primeira vez pelo Uniswap. A restrição durante a negociação é:

$$k=x*y$$

onde $k$ é uma constante. Isso significa que o produto das quantidades de Coca-Cola e dólar no mercado permanece constante antes e depois da negociação. Usando o mesmo exemplo anterior, se houver 10 garrafas de Coca-Cola e $10 de dólar na liquidez do mercado, então $k=100$ e o preço da Coca-Cola é de $1 por garrafa. Se eu estiver com sede e quiser trocar $10 por Coca-Cola, a quantidade total de dólar no mercado será aumentada para $20, mantendo a restrição $k=100$, e a quantidade de Coca-Cola será reduzida para 5 garrafas, resultando em um preço de $20/5 = 4 por garrafa. Eu recebi 5 garrafas de Coca-Cola por $10, ou seja, $2 por garrafa.

A vantagem do CPAMM é que ele possui "liquidez infinita": o preço relativo dos tokens varia de acordo com as compras e vendas, e quanto mais escasso for um token, maior será o seu preço relativo, evitando que a liquidez seja esgotada. No exemplo acima, a negociação fez com que o preço da Coca-Cola subisse de $1 para $4 por garrafa, evitando que a Coca-Cola fosse comprada até esgotar a liquidez do mercado.

A seguir, vamos construir uma exchange descentralizada extremamente simples baseada no CPAMM.

## Exchange Descentralizada

Agora, vamos escrever um contrato chamado `SimpleSwap` que representa uma exchange descentralizada, permitindo que os usuários negociem um par de tokens.

`SimpleSwap` herda o padrão de contrato ERC20 para facilitar o registro da liquidez fornecida pelos provedores de liquidez. No construtor, especificamos os endereços dos dois tokens que a exchange suporta. `reserve0` e `reserve1` registram as reservas dos tokens no contrato.

```solidity
contract SimpleSwap is ERC20 {
    // Contrato do token
    IERC20 public token0;
    IERC20 public token1;

    // Reservas dos tokens
    uint public reserve0;
    uint public reserve1;
    
    // Construtor, inicializa os endereços dos tokens
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }
}
```

A exchange tem dois tipos de participantes: provedores de liquidez (Liquidity Providers, LP) e traders. A seguir, vamos implementar as funcionalidades para cada um desses participantes.

### Provedores de Liquidez

Os provedores de liquidez fornecem liquidez ao mercado, permitindo que os traders obtenham melhores preços e liquidez, e recebem uma taxa em troca.

Primeiro, precisamos implementar a funcionalidade de adicionar liquidez. Quando um usuário adiciona liquidez à pool de tokens, o contrato deve registrar a participação do LP. De acordo com o Uniswap V2, a participação do LP é calculada da seguinte forma:

1. Quando a pool de tokens é adicionada pela primeira vez, a participação do LP $\Delta{L}$ é determinada pela raiz quadrada do produto das quantidades de tokens adicionadas:

    $$\Delta{L}=\sqrt{\Delta{x} *\Delta{y}}$$

2. Quando a liquidez é adicionada posteriormente, a participação do LP é determinada pela proporção das quantidades de tokens adicionadas em relação às reservas dos tokens (a proporção é calculada para cada token e a menor proporção é usada):

    $$\Delta{L}=L*\min{(\frac{\Delta{x}}{x}, \frac{\Delta{y}}{y})}$$

Como o contrato `SimpleSwap` herda o padrão ERC20, após calcular a participação do LP, podemos emitir tokens para o usuário representando sua participação.

A função `addLiquidity()` a seguir implementa a funcionalidade de adicionar liquidez, com as seguintes etapas:

1. Transferir os tokens adicionados pelo usuário para o contrato. O usuário precisa aprovar o contrato antecipadamente.
2. Calcular a participação de liquidez adicionada e verificar a quantidade de tokens a serem emitidos.
3. Atualizar as reservas dos tokens no contrato.
4. Emitir tokens LP para o provedor de liquidez.
5. Emitir o evento `Mint`.

```solidity
event Mint(address indexed sender, uint amount0, uint amount1);

// Adicionar liquidez, transferir tokens e emitir tokens LP
// @param amount0Desired Quantidade de token0 a ser adicionada
// @param amount1Desired Quantidade de token1 a ser adicionada
function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
    // Transferir a liquidez adicionada para o contrato Swap, o usuário precisa aprovar o contrato Swap antecipadamente
    token0.transferFrom(msg.sender, address(this), amount0Desired);
    token1.transferFrom(msg.sender, address(this), amount1Desired);
    // Calcular a liquidez adicionada
    uint _totalSupply = totalSupply();
    if (_totalSupply == 0) {
        // Se for a primeira vez que a liquidez é adicionada, emitir tokens LP (liquidity provider) na quantidade de L = sqrt(x * y)
        liquidity = sqrt(amount0Desired * amount1Desired);
    } else {
        // Se não for a primeira vez que a liquidez é adicionada, emitir tokens LP com base na proporção das quantidades de tokens adicionadas, usando a menor proporção entre os dois tokens
        liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
    }

    // Verificar a quantidade de tokens LP emitidos
    require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

    // Atualizar as reservas dos tokens
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    // Emitir tokens LP para o provedor de liquidez, representando a liquidez fornecida
    _mint(msg.sender, liquidity);
    
    emit Mint(msg.sender, amount0Desired, amount1Desired);
}
```

A seguir, precisamos implementar a funcionalidade de remover liquidez. Quando um usuário remove uma quantidade $\Delta{L}$ de liquidez da pool, o contrato deve queimar os tokens LP e devolver a proporção correspondente dos tokens para o usuário. A fórmula para calcular a quantidade de tokens a serem devolvidos é a seguinte:

$$\Delta{x}={\frac{\Delta{L}}{L} * x}$$ 
$$\Delta{y}={\frac{\Delta{L}}{L} * y}$$ 

A função `removeLiquidity()` a seguir implementa a funcionalidade de remover liquidez, com as seguintes etapas:

1. Obter o saldo dos tokens no contrato.
2. Calcular a quantidade de tokens a serem transferidos com base na proporção dos tokens LP.
3. Verificar a quantidade de tokens.
4. Queimar os tokens LP.
5. Transferir os tokens correspondentes para o usuário.
6. Atualizar as reservas dos tokens no contrato.
7. Emitir o evento `Burn`.

```solidity
// Remover liquidez, queimar tokens LP e transferir tokens
// Quantidade a ser transferida = (liquidity / totalSupply_LP) * reserve
// @param liquidity Quantidade de liquidez a ser removida
function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
    // Obter o saldo
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));
    // Calcular a quantidade de tokens a serem transferidos com base na proporção dos tokens LP
    uint _totalSupply = totalSupply();
    amount0 = liquidity * balance0 / _totalSupply;
    amount1 = liquidity * balance1 / _totalSupply;
    // Verificar a quantidade de tokens
    require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
    // Queimar os tokens LP
    _burn(msg.sender, liquidity);
    // Transferir os tokens
    token0.transfer(msg.sender, amount0);
    token1.transfer(msg.sender, amount1);
    // Atualizar as reservas dos tokens
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    emit Burn(msg.sender, amount0, amount1);
}
```

Agora, as funcionalidades relacionadas aos provedores de liquidez estão concluídas. A seguir, vamos implementar as funcionalidades de negociação.

### Negociação

Na exchange `SimpleSwap`, os usuários podem trocar um token por outro. Quanto de token1 posso obter ao trocar $\Delta{x}$ unidades de token0? Vamos fazer uma breve dedução.

De acordo com a fórmula do produto constante, antes da negociação:

$$k=x*y$$

Após a negociação, temos:

$$k=(x+\Delta{x})*(y+\Delta{y})$$

Como o valor de $k$ não muda antes e depois da negociação, podemos combinar as duas equações acima:

$$\Delta{y}=-\frac{\Delta{x}*y}{x+\Delta{x}}$$

Portanto, a quantidade de token1 $\Delta{y}$ que podemos obter é determinada por $\Delta{x}$, $x$ e $y$. Observe que os sinais de $\Delta{x}$ e $\Delta{y}$ são opostos, porque adicionar aumenta a reserva de tokens e remover diminui.

A função `getAmountOut()` a seguir implementa o cálculo da quantidade de tokens a serem obtidos, dado um valor de entrada e as reservas dos tokens.

```solidity
// Dado um valor de entrada e as reservas dos tokens, calcular a quantidade de tokens a serem obtidos
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
    require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
    amountOut = amountIn * reserveOut / (reserveIn + amountIn);
}
```

Com essa fórmula central, podemos implementar a funcionalidade de negociação. A função `swap()` a seguir implementa a funcionalidade de troca de tokens, com as seguintes etapas:

1. O usuário especifica a quantidade de tokens a serem trocados, o endereço do token a ser trocado e a quantidade mínima do outro token a ser obtida.
2. Verificar se é uma troca de token0 por token1 ou de token1 por token0.
3. Usar a fórmula acima para calcular a quantidade de tokens a serem obtidos.
4. Verificar se a quantidade de tokens obtidos atende à quantidade mínima especificada pelo usuário (semelhante ao slippage em uma negociação).
5. Transferir os tokens do usuário para o contrato.
6. Transferir os tokens trocados do contrato para o usuário.
7. Atualizar as reservas dos tokens no contrato.
8. Emitir o evento `Swap`.

```solidity
// Trocar tokens
// @param amountIn Quantidade de tokens a serem trocados
// @param tokenIn Endereço do token a ser trocado
// @param amountOutMin Quantidade mínima do outro token a ser obtida
function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
    require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
    require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
    
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));

    if(tokenIn == token0){
        // Se for uma troca de token0 por token1
        tokenOut = token1;
        // Calcular a quantidade de token1 a ser obtida
        amountOut = getAmountOut(amountIn, balance0, balance1);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        // Realizar a troca
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }else{
        // Se for uma troca de token1 por token0
        tokenOut = token0;
        // Calcular a quantidade de token1 a ser obtida
        amountOut = getAmountOut(amountIn, balance1, balance0);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        // Realizar a troca
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }

    // Atualizar as reservas dos tokens
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

(tokenIn), amountOut, address(tokenOut));
}
```

## Contrato Swap

O código completo do `SimpleSwap` é o seguinte:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {
    // Contrato do token
    IERC20 public token0;
    IERC20 public token1;

    // Reservas dos tokens
    uint public reserve0;
    uint public reserve1;
    
    // Eventos 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    // Construtor, inicializa os endereços dos tokens
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    // Função auxiliar para retornar o menor valor entre dois números
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // Função auxiliar para calcular a raiz quadrada usando o método babilônico (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

    // Adicionar liquidez, transferir tokens e emitir tokens LP
    // @param amount0Desired Quantidade de token0 a ser adicionada
    // @param amount1Desired Quantidade de token1 a ser adicionada
    function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
        // Transferir a liquidez adicionada para o contrato Swap, o usuário precisa aprovar o contrato Swap antecipadamente
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        // Calcular a liquidez adicionada
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // Se for a primeira vez que a liquidez é adicionada, emitir tokens LP (liquidity provider) na quantidade de L = sqrt(x * y)
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            // Se não for a primeira vez que a liquidez é adicionada, emitir tokens LP com base na proporção das quantidades de tokens adicionadas, usando a menor proporção entre os dois tokens
            liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

        // Verificar a quantidade de tokens LP emitidos
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // Atualizar as reservas dos tokens
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // Emitir tokens LP para o provedor de liquidez, representando a liquidez fornecida
        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    // Remover liquidez, queimar tokens LP e transferir tokens
    // Quantidade a ser transferida = (liquidity / totalSupply_LP) * reserve
    // @param liquidity Quantidade de liquidez a ser removida
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        // Obter o saldo
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        // Calcular a quantidade de tokens a serem transferidos com base na proporção dos tokens LP
        uint _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        // Verificar a quantidade de tokens
        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        // Queimar os tokens LP
        _burn(msg.sender, liquidity);
        // Transferir os tokens
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        // Atualizar as reservas dos tokens
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    // Dado um valor de entrada e as reservas dos tokens, calcular a quantidade de tokens a serem obtidos
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    // Trocar tokens
    // @param amountIn Quantidade de tokens a serem trocados
    // @param tokenIn Endereço do token a ser trocado
    // @param amountOutMin Quantidade mínima do outro token a ser obtida
    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if(tokenIn == token0){
            // Se for uma troca de token0 por token1
            tokenOut = token1;
            // Calcular a quantidade de token1 a ser obtida
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // Realizar a troca
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            // Se for uma troca de token1 por token0
            tokenOut = token0;
            // Calcular a quantidade de token1 a ser obtida
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // Realizar a troca
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        // Atualizar as reservas dos tokens
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}
```

## Reproduzindo no Remix

1. Implante dois contratos ERC20 (token0 e token1) e registre seus endereços de contrato.

2. Implante o contrato `SimpleSwap` e preencha os endereços dos tokens acima.

3. Chame a função `approve()` dos contratos ERC20 para permitir que o contrato `SimpleSwap` gaste 1000 unidades de cada token.

4. Chame a função `addLiquidity()` do contrato `SimpleSwap` para adicionar liquidez à exchange. Adicione 100 unidades de cada token.

5. Chame a função `balanceOf()` do contrato `SimpleSwap` para verificar a participação do LP. Deve ser 100. ($\sqrt{100*100}=100$)

6. Chame a função `swap()` do contrato `SimpleSwap` para realizar uma troca de tokens. Use 100 unidades do token0.

7. Chame as funções `reserve0` e `reserve1` do contrato `SimpleSwap` para verificar as reservas de tokens no contrato. Deve ser 200 e 50, respectivamente. Na etapa anterior, usamos 100 unidades do token0 para trocar por 50 unidades do token1 ($\frac{100*100}{100+100}=50$).

## Conclusão

Nesta aula, apresentamos o Market Maker Automatizado com Produto Constante e escrevemos uma exchange descentralizada extremamente simples. No contrato `SimpleSwap`, há muitos aspectos que não foram considerados, como taxas de negociação e governança. Se você estiver interessado em exchanges descentralizadas, recomendamos a leitura de [Programming DeFi: Uniswap V2](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) e [Uniswap v3 book](https://y1cunhui.github.io/uniswapV3-book-zh-cn/) para um estudo mais aprofundado.

