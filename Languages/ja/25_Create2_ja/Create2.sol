// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Pair {
    address public factory; // ファクトリコントラクト
    address public token0; // トークン1
    address public token1; // トークン2

    constructor() payable {
        factory = msg.sender;
    }

    // デプロイ時に一度呼び出される
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory2 {
    mapping(address => mapping(address => address)) public getPair; // トークンのアドレスからペアのアドレスを参照する用
    address[] public allPairs; // すべてのペアアドレスを保存する

    function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES"); // token Aとtoken Bが同じアドレスでないことを確認

        // token Aとtoken Bをソートして小さい方をtoken0に、大きい方をtoken1にする
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // token0、token1を使ってkeccak256でsaltを計算
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // create2をつかってコントラクトをデプロイする
        Pair pair = new Pair{salt: salt}();
        // 新しいコントラクトのinitialize関数を呼び出す
        pair.initialize(tokenA, tokenB);
        // アドレスのマップallPairsを更新
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }

    // ペアのアドレスをあらかじめ計算する関数
    function calculateAddr(address tokenA, address tokenB) public view returns (address predictedAddress) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES"); // token Aとtoken Bが同じアドレスでないことを確認

        // token Aとtoken Bをソートして小さい方をtoken0に、大きい方をtoken1にする
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // token0、token1を使ってkeccak256でsaltを計算
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // hash()を使ってコントラクトアドレスを計算する
        predictedAddress = address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(Pair).creationCode)))
                )
            )
        );
    }
}
