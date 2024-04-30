// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OnlyEven{
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns(bool success){
        // revertir cuando se ingresa un número impar
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}

contract TryCatch {
    // evento de éxito
    event SuccessEvent();
    // evento de falla
    event CatchEvent(string message);
    event CatchByte(bytes data);

    // declarar la variable de contrato OnlyEven
    OnlyEven even;

    constructor() {
        even = new OnlyEven(2);
    }
    
    // usar try-catch en llamada externa
    // execute(0) va a tener éxito y emitir `SuccessEvent`
    // execute(1) va a fallar y emitir `CatchEvent`
    function execute(uint amount) external returns (bool success) {
        try even.onlyEven(amount) returns(bool _success){
            // if call succeeds
            emit SuccessEvent();
            return _success;
        } catch Error(string memory reason){
            // if call fails
            emit CatchEvent(reason);
        }
    }

    // usar try-catch cuando se crea un nuevo contrato (la creación del contrato se considera una llamada externa)
    // executeNew(0) va a fallar y emitir `CatchEvent`
    // executeNew(1) va a fallar y emitir `CatchByte`
    // executeNew(2) va a tener éxito y emitir `SuccessEvent`
    function executeNew(uint a) external returns (bool success) {
        try new OnlyEven(a) returns(OnlyEven _even){
            // if call succeeds
            emit SuccessEvent();
            success = _even.onlyEven(a);
        } catch Error(string memory reason) {
            // atrapar revert("reasonString") y require(false, "reasonString")
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            // atrapar assert() o falla, el tipo de error de assert es Panic(uint256) en lugar de Error(string), por lo que irá a esta rama
            emit CatchByte(reason);
        }
    }
}
