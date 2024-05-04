// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Pair{
    address public factory; // Dirección del contrato Factory 
    address public token0; // token1
    address public token1; // token2

    constructor() payable {
        factory = msg.sender;
    }

    // Se llama una vez al factory en el momento del despliegue
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // Suficiente comprobación
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory{
    mapping(address => mapping(address => address)) public getPair; // Obtener la dirección del Pair basada en las direcciones de 2 tokens
    address[] public allPairs; // Almaenar todas las direcciones de Pair

    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        // Crear un nuevo contrato
        Pair pair = new Pair(); 
        // Llamar a la función de inicialización del nuevo contrato
        pair.initialize(tokenA, tokenB);
        // Actualizar getPair y allPairs
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}
