// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract Pair{
    address public factory;
    address public token0;
    address public token1;

    constructor() payable {
        factory = msg.sender;
    }

    // chamado uma vez pela fábrica no momento da implantação
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory{
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

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
