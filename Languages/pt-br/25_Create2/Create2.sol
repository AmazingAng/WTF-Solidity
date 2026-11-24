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

contract PairFactory2{
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // Calcular o salt usando os endereços tokenA e tokenB
        //Ordenar tokenA e tokenB em ordem crescente
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // Use create2 to deploy a new contract
        Pair pair = new Pair{salt: salt}(); 
        // Chamando o método initialize do novo contrato
        pair.initialize(tokenA, tokenB);
        // Atualizando mapa de endereços
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }

    // Calcular antecipadamente o endereço do contrato pair
    function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // Calcular o salt usando os endereços tokenA e tokenB
        //Ordenar tokenA e tokenB em ordem crescente
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // calcular o endereço do contrato usando o método hash()
        predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(type(Pair).creationCode)
        )))));
    }
}
