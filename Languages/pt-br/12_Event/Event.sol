// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Events {
    // Definir a variável de mapeamento _balances para registrar a quantidade de tokens detidos por cada endereço
    mapping(address => uint256) public _balances;

    // Definir evento de Transferência, registrando o endereço de envio, o endereço de recebimento e a quantidade transferida da transação de transferência
    event Transfer(address indexed from, address indexed to, uint256 value);


    // Definir a função _transfer, que executa a lógica de transferência de fundos
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {

        // Dê alguns tokens iniciais para o endereço de transferência

        // Subtrair a quantidade de transferência do endereço de origem
        // Adicione a quantidade de transferência ao endereço de destino

        // Liberar evento
        emit Transfer(from, to, amount);
    }
}
