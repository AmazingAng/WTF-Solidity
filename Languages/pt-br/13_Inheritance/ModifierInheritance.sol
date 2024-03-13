// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Base1 {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}

contract Identifier is Base1 {

    //Calcular o valor de um número dividido por 2 e por 3, mas o parâmetro fornecido deve ser um múltiplo de 2 e 3.
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    //Calcular o valor de um número dividido por 2 e por 3
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }

    //Sobrescrevendo o modificador: Se não for sobrescrito, ao chamar getExactDividedBy2And3 com entrada 9, ocorrerá um revert, pois não passará na verificação.
    //Remova as três linhas de comentário abaixo e reescreva o Modificador. Quando você digitar 9 e chamar getExactDividedBy2And3, a chamada será bem-sucedida.
    // modifier exactDividedBy2And3(uint _a) override {
    modifier exatoDivididoPor2E3(uint _a) override {
    // }
}

