// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OnlyEven{
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns(bool success){
        // Ao inserir um número ímpar, reverta
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}

contract TryCatch {
    // Evento de sucesso
    event SuccessEvent();
    // Evento de falha
    event CatchEvent(string message);
    event CatchByte(bytes data);

    // Declarando a variável do contrato OnlyEven
    OnlyEven even;

    constructor() {
        even = new OnlyEven(2);
    }
    
    // Usando try-catch em chamadas externas
    // execute(0) será bem-sucedido e liberará o `SuccessEvent`
    // execute(1) falhará e liberará `CatchEvent`
    function execute(uint amount) external returns (bool success) {
        try even.onlyEven(amount) returns(bool _success){
            // Em caso de sucesso na chamada
            emit SuccessEvent();
            return _success;
        } catch Error(string memory reason){
            // Em caso de falha na chamada
            emit CatchEvent(reason);
        }
    }

    // Ao usar try-catch em contratos criados (a criação de contratos é considerada uma chamada externa)
    // executeNew(0) falhará e liberará `CatchEvent`
    // executeNew(1) falhará e liberará `CatchByte`
    // executeNew(2) será bem-sucedido e liberará `SuccessEvent`
    function executeNew(uint a) external returns (bool success) {
        try new OnlyEven(a) returns(OnlyEven _even){
            // Em caso de sucesso na chamada
            emit SuccessEvent();
            success = _even.onlyEven(a);
        } catch Error(string memory reason) {
            // catch revert("reasonString") e require(false, "reasonString")
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            // catch failed assert assert failed error type is Panic(uint256) not Error(string) type, so it will enter this branch
            emit CatchByte(reason);
        }
    }
}
