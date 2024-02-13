// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Pair{
    // Endereço do contrato da fábrica
    // Token 1
    // Token 2

    constructor() payable {
        factory = msg.sender;
    }

    // chamado uma vez pela fábrica no momento da implantação
    function initialize(address _token0, address _token1) external {
        // verificação suficiente
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory{
    // Traduzindo o texto para 'pt-br':
    // Encontre o endereço do par através de dois endereços de tokens

    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        // Criar novo contrato
        Pair pair = new Pair(); 
        // Chamando o método initialize do novo contrato
        pair.initialize(tokenA, tokenB);
        // Atualizando mapa de endereços
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}
