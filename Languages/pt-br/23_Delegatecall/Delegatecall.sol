// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// delegatecall e call são funções de baixo nível semelhantes.
// chamada: B chama C, o contexto é C (msg.sender = B, as variáveis de estado em C são afetadas)
// delegatecall: B delegatecall C, contexto é B (msg.sender = A, variáveis de estado em B são afetadas)
// Atenção: o layout de armazenamento dos dados de B e C deve ser o mesmo! Os tipos de variáveis e a ordem de declaração devem ser os mesmos, caso contrário o contrato será comprometido.

// Contrato C chamado
contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}

// Contrato B que faz uma chamada delegatecall
contract B {
    uint public num;
    address public sender;

    // Ao chamar a função setVars() em C usando call, as variáveis de estado do contrato C serão alteradas.
    function callSetVars(address _addr, uint _num) external payable{
        // chamar setVars()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
    // Ao chamar a função setVars() de C usando delegatecall, a variável de estado do contrato B será alterada.
    function delegatecallSetVars(address _addr, uint _num) external payable{
        // delegatecall setVars()
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
