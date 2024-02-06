// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
contract Events {
    // Definir la variable _balance de tipo mapping para registrar el número de tokens que posee cada dirección
    mapping(address => uint256) public _balances;

    // Definir el evento Transfer para guardar la dirección de transferencia, la dirección que recibe y el valor transferido.
    event Transfer(address indexed from, address indexed to, uint256 value);


    // definir _transfer function，execute transfer logic
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {

        _balances[from] = 10000000; // dar unos tokens iniciales para transferir

        _balances[from] -=  amount; // la dirección `from` resta el valor a transferir
        _balances[to] += amount; // la dirección `to` suma el valor a transferir

        // emitir evento
        emit Transfer(from, to, amount);
    }
}
