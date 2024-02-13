# WTF Introdução Simples ao Solidity: 56. Exchange Descentralizada

Recentemente, tenho revisado meu conhecimento em Solidity, consolidando os detalhes e escrevendo uma "Introdução Simples ao Solidity" para uso de iniciantes (os programadores experientes podem buscar outros tutoriais), atualizando de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

Nesta lição, vamos introduzir o Constant Product Automated Market Maker (CPAMM), que é o mecanismo central das exchanges descentralizadas, sendo adotado por várias DEXs como Uniswap e PancakeSwap. O contrato de ensino foi simplificado a partir do contrato [Uniswap-v2](https://github.com/Uniswap/v2-core), incluindo as funcionalidades principais do CPAMM.

## Automated Market Maker

Automated Market Maker (AMM) é um algoritmo ou contrato inteligente que opera na blockchain, permitindo a troca descentralizada de ativos digitais. A introdução do AMM criou um novo método de negociação, sem a necessidade de correspondência de pedidos tradicionais entre compradores e vendedores, usando uma fórmula matemática predefinida (como a fórmula do produto constante) para criar um pool de liquidez que permite aos usuários negociar a qualquer momento.

![](./img/56-1.png)

Na próxima parte, usando o mercado de cola ($COLA) e dólar ($USD) como exemplo, explicaremos o AMM. Para facilitar, estabelecemos alguns símbolos: $x$ e $y$ representam a quantidade total de cola e dólares no mercado, e $\Delta x$ e $\Delta y$ representam a quantidade de cola e dólares envolvidos em uma negociação, respectivamente. $L$ e $\Delta L$ representam a liquidez total e a mudança na liquidez.

### Constant Sum Automated Market Maker (CSAMM)

O Constant Sum Automated Market Maker (CSAMM) é o modelo mais simples de AMM, é a partir dele que começamos. A restrição da negociação é dada pela seguinte equação:

$$k=x+y$$

Onde $k$ é uma constante. Ou seja, antes e depois da negociação, a soma total de cola e dólares no mercado permanece a mesma. Por exemplo, se houver 10 garrafas de cola e 10 dólares no mercado, teremos $k=20$ e o preço da cola será de 1 dólar por garrafa. Se eu estou com sede e quero trocar 2 dólares por cola, após a transação, teremos 12 dólares no mercado, de acordo com a restrição $k=20$, haverá 8 garrafas de cola, com o preço de 1 dólar por garrafa. Na transação, eu adquiri 2 garrafas de cola, com o preço de 1 dólar por garrafa.

A vantagem do CSAMM é que ele pode garantir a estabilidade dos preços relativos de tokens, o que é importante em trocas de stablecoins, onde todos querem trocar 1 USDT por 1 USDC. No entanto, a desvantagem é que a liquidez pode ser facilmente esgotada: eu só preciso de 10 dólares para esgotar a liquidez da cola no mercado, impedindo que outros usuários que queiram beber cola possam fazer negócios.

A seguir, vamos apresentar o Constant Product Automated Market Maker com "liquidez infinita".

### Constant Product Automated Market Maker

O Constant Product Automated Market Maker (CPAMM) é o modelo mais popular de AMM, que foi adotado inicialmente pelo Uniswap. A restrição da negociação é dada pela seguinte equação:

$$k=x*y$$

Onde $k$ é uma constante. Ou seja, antes e depois da negociação, o produto da quantidade de cola e dólares no mercado permanece o mesmo. No exemplo anterior, com 10 garrafas de cola e 10 dólares no mercado, teríamos $k=100$, com o preço da cola sendo de 1 dólar por garrafa. Se eu quiser trocar 10 dólares por cola, com 20 dólares no mercado, de acordo com a restrição $k=100$, haverá 5 garrafas de cola, com o preço de $20/5 = 4$ dólares por garrafa. Na transação, adquiri 5 garrafas de cola, com o preço de $10/5 = 2$ dólares por garrafa.

A vantagem do CPAMM é a "liquidez infinita": os preços relativos dos tokens irão variar com as compras e vendas, sendo que quanto mais escasso um token, maior será o preço relativo, evitando que a liquidez seja esgotada. No exemplo mencionado acima, a transação fez com que o preço da cola subisse de 1 dólar por garrafa para 4 dólares por garrafa, evitando que a cola no mercado fosse comprada por completo.

A seguir, vamos criar uma exchange descentralizada simples baseada no CPAMM.

## Exchange Descentralizada

Abaixo, escreveremos um contrato `SimpleSwap` que permite aos usuários negociar um par de tokens.

O `SimpleSwap` herda o padrão ERC20 para facilitar o registro dos fornecedores de liquidez que fornecem liquidez ao mercado. No construtor, especificamos os endereços dos pares de tokens `token0` e `token1` que a exchange suportará, e registramos as reservas de token.

```solidity
contract SimpleSwap is ERC20 {
    // Contrato dos tokens
    IERC20 public token0;
    IERC20 public token1;

    // Quantidade de reserva dos tokens
    uint public reserve0;
    uint public reserve1;
    
    // Construtor, inicializa os endereços dos tokens
    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }
}
```

A exchange é composta por dois tipos de participantes: fornecedores de liquidez (LP) e negociadores. A seguir, implementaremos as funcionalidades para cada um deles.

### Fornecedores de Liquidez

Os fornecedores de liquidez oferecem liquidez ao mercado para fornecer melhores cotações e liquidez aos negociadores, e em troca, recebem uma taxa.

Primeiramente, precisamos implementar a funcionalidade de adicionar liquidez. Quando um usuário adiciona liquidez ao pool de tokens, o contrato deve registrar a quantidade de LP fornecida pelo usuário. De acordo com o Uniswap V2, a quantidade de LP é calculada da seguinte maneira:

1. Quando a liquidez é adicionada pela primeira vez ao pool de tokens, a quantidade de LP $\Delta{L}$ é determinada pela raiz quadrada do produto da quantidade de tokens adicionados:

    $$\Delta{L}=\sqrt{\Delta{x} *\Delta{y}}$$

2. Quando a liquidez não é adicionada pela primeira vez, a quantidade de LP é determinada pela proporção da quantidade de tokens adicionados em relação às reservas existentes dos tokens no pool de tokens (a proporção é calculada com base no token com menos quantidade):

    $$\Delta{L}=L*\min{(\frac{\Delta{x}}{x}, \frac{\Delta{y}}{y})}$$

Como o contrato `SimpleSwap` herda o padrão ERC20, após calcular a quantidade de LP, podemos criar tokens de LP para o usuário.

A função `addLiquidity()` a seguir implementa a funcionalidade de adicionar liquidez:

1. Os tokens adicionados pelo usuário são transferidos para o contrato, sendo necessário que o usuário tenha concedido autorização ao contrato anteriormente.
2. A quantidade de LP a ser adicionada é calculada com base na fórmula acima, e a quantidade de tokens LP criada é verificada.
3. As reservas de tokens do contrato são atualizadas.
4. Tokens de LP são criados para o fornecedor de liquidez.
5. O evento `Mint` é emitido.

```solidity
event Mint(address indexed sender, uint amount0, uint amount1);

// Adiciona liquidez, transfere os tokens, cria tokens de LP
// @param amount0Desired Quantidade de token0 a ser adicionada
// @param amount1Desired Quantidade de token1 a ser adicionada
function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
    // Transfere a liquidez adicionada para o contrato, sendo necessário autorizar previamente
    token0.transferFrom(msg.sender, address(this), amount0Desired);
    token1.transferFrom(msg.sender, address(this), amount1Desired);
    // Calcula a liquidez adicionada
    uint _totalSupply = totalSupply();
    if (_totalSupply == 0) {
        // Se for a primeira vez adicionando liquidez, cria L = sqrt(x * y) unidades do token de LP
        liquidity = sqrt(amount0Desired * amount1Desired);
    } else {
        // Se não for a primeira vez, cria o token de LP conforme a proporção dos tokens adicionados em relação às reservas existentes
        liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
    }

    // Verifica a quantidade de LP criada
    require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

    // Atualiza as reservas dos tokens
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    // Cria tokens de LP representando a liquidez fornecida
    _mint(msg.sender, liquidity);
    
    emit Mint(msg.sender, amount0Desired, amount1Desired);
}
```

A seguir, precisamos implementar a funcionalidade de remover liquidez. Quando um usuário retira uma quantidade de LP $\Delta{L}$ do pool, o contrato deve destruir os tokens de LP do usuário e devolver os tokens correspondentes. O cálculo para devolução dos tokens é dado pela fórmula:

$$\Delta{x}={\frac{\Delta{L}}{L} * x}$$ 
$$\Delta{y}={\frac{\Delta{L}}{L} * y}$$ 

A função `removeLiquidity()` a seguir implementa a funcionalidade de remover liquidez:

1. O saldo dos tokens no contrato é obtido.
2. A quantidade de tokens a ser transferida é calculada com base na proporção dos tokens LP.
3. Os tokens são verificados.
4. Os tokens de LP são destruídos.
5. Os tokens correspondentes são transferidos para o usuário.
6. As reservas de tokens são atualizadas.
7. O evento `Burn` é emitido.

```solidity
// Remove liquidez, destrói tokens de LP, transfere os tokens
// Quantidade a ser transferida = (liquidez / total de tokens LP) * reservas
// @param liquidity Quantidade de liquidez a ser removida
function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
    // Obtém o saldo
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));
    // Calcula a quantidade a ser transferida baseada na proporção dos tokens LP
    uint _totalSupply = totalSupply();
    amount0 = liquidity * balance0 / _totalSupply;
    amount1 = liquidity * balance1 / _totalSupply;
    // Verifica os tokens
    require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
    // Destroi os tokens de LP
    _burn(msg.sender, liquidity);
    // Transfere os tokens
    token0.transfer(msg.sender, amount0);
    token1.transfer(msg.sender, amount1);
    // Atualiza as reservas
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    emit Burn(msg.sender, amount0, amount1);
}
```

Até aqui, as funcionalidades relacionadas aos fornecedores de liquidez foram implementadas. Em seguida, abordaremos a parte relativa às negociações.

### Negociações

No contrato `SimpleSwap`, os usuários podem trocar um tipo de token por outro. Quanto de um token consigo trocar por outro, se eu trocar $\Delta{x}$ unidades de token0? Vamos derivar isso de forma simples.

De acordo com a fórmula do produto constante, antes da negociação temos:

$$k=x*y$$

E após a negociação, temos:

$$k=(x+\Delta{x})*(y+\Delta{y})$$

Como $k$ não muda antes e depois da negociação, podemos resolver as equações e obter:

$$\Delta{y}=-\frac{\Delta{x}*y}{x+\Delta{x}}$$

Portanto, a quantidade de tokens $\Delta{y}$ que podemos trocar depende de $\Delta{x}$, $x$, e $y$. É importante observar que os sinais de $\Delta{x}$ e $\Delta{y}$ são opostos, pois adicionar aumenta a quantidade de tokens, e remover diminui.

A função `getAmountOut()` a seguir calcula a quantidade de um token que podemos receber ao trocar uma quantidade específica de outro token, considerando as reservas dos tokens.

```solidity
// Dada uma quantidade de um ativo e as reservas dos tokens, calcula a quantidade para trocar por outro token
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
    require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
    amountOut = amountIn * reserveOut / (reserveIn + amountIn);
}
```

Com essa fórmula principal em mente, podemos agora implementar a funcionalidade de negociações. A função `swap()` a seguir implementa a negociação de tokens:

1. O usuário especifica a quantidade de um token para a troca, o endereço do token a ser trocado e a quantidade mínima de tokens a serem recebidos.
2. Verificamos se é o token0 sendo trocado pelo token1 ou vice-versa.
3. Usamos a fórmula acima para calcular a quantidade de tokens a serem recebidos na troca.
4. Verificamos se a quantidade de tokens recebidos atende ao mínimo especificado pelo usuário, semelhante a um limite de deslizamento na negociação.
5. Os tokens do usuário são transferidos para o contrato.
6. Os tokens negociados são transferidos para o usuário.
7. As reservas dos tokens no contrato são atualizadas.
8. O evento `Swap` é emitido.

```solidity
// Troca de tokens
// @param amountIn Quantidade de um token para trocar
// @param tokenIn Endereço do token a ser trocado
// @param amountOutMin Quantidade mínima do outro token a ser recebida
function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
    require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
    require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
    
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));

    if(tokenIn == token0){
        // Se é o token0 sendo trocado pelo token1
        tokenOut = token1;
        // Calcula a quantidade de token1 que será trocada
        amountOut = getAmountOut(amountIn, balance0, balance1);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        // Realiza a troca
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }else{
        // Se é o token1 sendo trocado pelo token0
        tokenOut = token0;
        // Calcula a quantidade de token1 que será trocada
        amountOut = getAmountOut(amountIn, balance1, balance0);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        // Realiza a troca
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }

    // Atualiza as reservas
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));

    emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
}
```

## Contrato UniSwap

O código completo para o `SimpleSwap` é apresentado abaixo:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->