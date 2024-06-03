// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Pair {
    address public factory; // ファクトリコントラクト
    address public token0; // トークン1
    address public token1; // トークン2

    constructor() payable {
        factory = msg.sender;
    }

    // デプロイ時に一度呼ばれる初期化関数
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory {
    mapping(address => mapping(address => address)) public getPair; // トークン1, 2によってpairのアドレスを調べれるようにするマップ変数
    address[] public allPairs; // すべてのpairのアドレスを格納する配列

    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        // 新しいPairコントラクトをデプロイする
        Pair pair = new Pair();
        // Pairコントラクトの初期化関数を呼び出す
        pair.initialize(tokenA, tokenB);
        // マップ変数を更新する
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}
