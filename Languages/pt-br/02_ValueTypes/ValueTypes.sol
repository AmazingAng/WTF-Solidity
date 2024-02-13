// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ValueTypes{
    // Valores booleanos
    bool public _bool = true;
    // Operações booleanas
    //取非
    //e
    //ou
    //igual
    //não é igual


    // Número inteiro
    int public _int = -1;
    uint public _uint = 1;
    uint256 public _number = 20220330;
    // Operações com números inteiros
    // +, -, *, /
    // Índice
    // Pegar o resto da divisão
    // Comparar tamanhos


    // Endereço
    address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    // endereço pagável, você pode enviar e receber pagamentos, verificar o saldo
    // Membro do tipo de endereço
    // saldo do endereço
    
    
    // Matriz de bytes de comprimento fixo
    // bytes32: 0x4d696e69536f6c69646974790000000000000000000000000000000000000000
    // bytes1: 0x4d
    
    
    // Enum
    // Comprar, Manter, Vender
    enum ActionSet { Buy, Hold, Sell }
    // Criar uma variável enum chamada "action"
    ActionSet action = ActionSet.Buy;

    // enum pode ser convertido explicitamente para uint
    function enumToUint() external view returns(uint){
        return uint(action);
    }
}

