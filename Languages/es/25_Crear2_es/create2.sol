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

contract PairFactory2{
        mapping(address => mapping(address => address)) public getPair; // Encontrar la dirección del Pair por dos direcciones de token
        address[] public allPairs; // Guardar todas las direcciones de Pair

        function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //Evitar conflictos cuando tokenA y tokenB son iguales
            // Calcular salt con las direcciones de tokenA y tokenB
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //Ordenar tokenA y tokenB por tamaño
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // Desplegar el contrato con create2
            Pair pair = new Pair{salt: salt}(); 
            // Llamar a la función de inicialización del nuevo contrato
            pair.initialize(tokenA, tokenB);
            // Actualizar address map
            pairAddr = address(pair);
            allPairs.push(pairAddr);
            getPair[tokenA][tokenB] = pairAddr;
            getPair[tokenB][tokenA] = pairAddr;
        }

        // Calcular la dirección del contrato `Pair` de antemano
        function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //Evitar conflictos cuando tokenA y tokenB son iguales
            // Calcular salt con las direcciones de tokenA y tokenB
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //Ordenar tokenA y tokenB por tamaño
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // Calcular la dirección del contrato
            predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )))));
        }
}
