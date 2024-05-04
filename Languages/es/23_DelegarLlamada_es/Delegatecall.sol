// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// delegatecall es similar a call, es una función de bajo nivel
// call: B llama a C, el contexto de ejecución es C (msg.sender = B, las variables de estado de C se ven afectadas)
// delegatecall: B delegatecall C, el contexto de ejecución es B (msg.sender = A, las variables de estado de B se ven afectadas)
// Se debe tener en cuenta que el diseño de almacenamiento de datos de B y C debe ser el mismo! El tipo de variable, el orden debe permanecer igual, de lo contrario, el contrato se arruinará.

// Contrato objetivo C
contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}

// contract B que usa tanto call como delegatecall para llamar al contrato C
contract B {
    uint public num;
    address public sender;

    // Llamar a setVars() de C con call, las variables de estado de C se cambiarán
    function callSetVars(address _addr, uint _num) external payable{
        // llamar setVars()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
    // Llamar a setVars() con delegatecall, las variables de estado del contrato B se cambiarán
    function delegatecallSetVars(address _addr, uint _num) external payable{
        // Delegar llamada a setVars()
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
