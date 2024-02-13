// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract InitialValue {
    // Tipos de Valor
    // false
    // ""
    // 0
    // 0
    // 0x0000000000000000000000000000000000000000

    enum ActionSet { Buy, Hold, Sell}
    // O primeiro elemento 0

    // internal equação em branco
    // external equação em branco

    // Tipos de Referência
    // Todos os membros definidos como seus valores padrão do array estático [0,0,0,0,0,0,0,0]
    // `[]`
    // Mapeamento com todos os elementos em seus valores padrão
    // Todos os membros da estrutura são definidos como seus valores padrão 0, 0
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student public student;

    // delete operador
    bool public _bool2 = true; 
    function d() external {
        // delete fará com que _bool2 retorne ao valor padrão, false
    }
}
