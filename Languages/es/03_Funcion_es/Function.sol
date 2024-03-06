// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract FunctionTypes{
    uint256 public number = 5;
    
    constructor() payable {}

    // Tipo de función
    // function (<tipos de los parámetros>) {internal|external} [pure|view|payable] [returns (<tipos de retorno>)]
    // función default
    function add() external{
        number = number + 1;
    }

    // pure: no solo la función no guarda ningún dato en la cadena de bloques, sino que tampoco lee ningún dato de la cadena de bloques.
    function addPure(uint256 _number) external pure returns(uint256 new_number){
        new_number = _number+1;
    }
    
    // view: ningun dato será cambiado
    function addView() external view returns(uint256 new_number) {
        new_number = number + 1;
    }

    // internal:  la función solo puede ser llamada dentro del propio contrato y cualquier contrato derivado.
    function minus() internal {
        number = number - 1;
    }

    // external: la función puede ser llamada por EOA/otro contrato
    function minusCall() external {
        minus();
    }

    //payable: dinero (ETH) puede ser enviado al contrato por medio de esta función
    function minusPayable() external payable returns(uint256 balance) {
        minus();    
        balance = address(this).balance;
    }
}