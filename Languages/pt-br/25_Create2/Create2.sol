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

contract PairFactory2{
    // Traduzindo o texto para 'pt-br':
    // Encontre o endereço do par através de dois endereços de tokens

    function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
        //Evite conflitos entre tokenA e tokenB se forem iguais
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
        //Evite conflitos entre tokenA e tokenB se forem iguais
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
