// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Pair{
    address public factory; // factory contract address
    address public token0; // token1
    address public token1; // token2

    constructor() payable {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory{
    mapping(address => mapping(address => address)) public getPair; // get Pair's address based on 2 tokens' addresses
    address[] public allPairs; // store all Pairs' addresses

    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        // create a new contract
        Pair pair = new Pair(); 
        // call initialized method of the new contract
        pair.initialize(tokenA, tokenB);
        // update getPair and allPairs
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}
