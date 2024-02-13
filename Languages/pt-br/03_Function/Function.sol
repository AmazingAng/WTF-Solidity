// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract FunctionTypes{
    uint256 public number = 5;
    
    constructor() payable {}

    // Tipo de função
    // função (<tipos de parâmetros>) {interno|externo} [puro|visualização|pagável] [retorna (<tipos de retorno>)]
    // função padrão
    function add() external{
        number = number + 1;
    }

    // puro: puro boi cavalo
    function addPure(uint256 _number) external pure returns(uint256 new_number){
        new_number = _number+1;
    }
    
    // view: Espectador
    function addView() external view returns(uint256 new_number) {
        new_number = number + 1;
    }

    // internal: Função interna
    function minus() internal {
        number = number - 1;
    }

    // As funções dentro do contrato podem chamar funções internas.
    function minusCall() external {
        minus();
    }

    // payable: função que permite enviar ETH para o contrato
    function minusPayable() external payable returns(uint256 balance) {
        minus();    
        balance = address(this).balance;
    }
}