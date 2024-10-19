// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Events {
    // define _balances mapping variable to record number of tokens held at each address
    //（各アドレスで保有されているトークン数を記録するmapping変数として_balanceを定義します）
    mapping(address => uint256) public _balances;

    // define Transfer event to record transfer address, receiving address and transfer number of a transfer transfaction
    //（転送を行うトランザクションの送信元アドレスや受信アドレス、転送数を記録する為のTransferイベントを定義します）
    event Transfer(address indexed from, address indexed to, uint256 value);


    // define _transfer function，execute transfer logic
    //（_transfer関数を定義して、転送ロジックを実行する）
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {

        _balances[from] = 10000000; // give some initial tokens to transfer address（送信元アドレスにいくつかの初期トークンを付与します）

        _balances[from] -=  amount; // "from" address minus the number of transfer（"from"アドレスから転送数を減算します）
        _balances[to] += amount; // "to" address adds the number of transfer（"to"アドレスに転送数を加算します）

        // emit event
        emit Transfer(from, to, amount);
    }
}