// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

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

contract PairFactory2{
        mapping(address => mapping(address => address)) public getPair; // Find the Pair address by two token addresses
        address[] public allPairs; // Save all Pair addresses

        function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //Avoid conflicts when tokenA and tokenB are the same
            // Calculate salt with tokenA and tokenB addresses
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //Sort tokenA and tokenB by size
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // Deploy new contract with create2
            Pair pair = new Pair{salt: salt}(); 
            // call initialize function of the new contract
            pair.initialize(tokenA, tokenB);
            // Update address map
            pairAddr = address(pair);
            allPairs.push(pairAddr);
            getPair[tokenA][tokenB] = pairAddr;
            getPair[tokenB][tokenA] = pairAddr;
        }

        // Calculate `Pair` contract address beforehand
        function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //Avoid conflicts when tokenA and tokenB are the same
            // Calculate salt with tokenA and tokenB addresses
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //Sort tokenA and tokenB by size
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // Calculate contract address
            predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )))));
        }
}