// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// Contrato simples e atualizável, onde o administrador pode alterar o endereço do contrato lógico através da função de atualização, modificando assim a lógica do contrato.
// Para fins de demonstração educacional, não utilizar em ambiente de produção.
contract SimpleUpgrade {
    // Endereço do contrato lógico
    // admin address
    // Strings, podem ser alterados por meio de funções de contrato lógico.

    // Construtor, inicializa os endereços do admin e do contrato lógico
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback function, delegates the call to the logic contract
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // Função de atualização, altera o endereço do contrato lógico, só pode ser chamada pelo admin
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// Contrato lógico 1
contract Logic1 {
    // Variáveis de estado e contratos proxy são consistentes para evitar conflitos de slot
    address public implementation; 
    address public admin; 
    // Strings, podem ser alterados por meio de funções de contrato lógico.

    // Alterando a variável de estado no proxy, seletor: 0xc2985578
    function foo() public{
        words = "old";
    }
}

// Contrato lógico 2
contract Logic2 {
    // Variáveis de estado e contratos proxy são consistentes para evitar conflitos de slot
    address public implementation; 
    address public admin; 
    // Strings, podem ser alterados por meio de funções de contrato lógico.

    // Alterando a variável de estado no proxy, seletor: 0xc2985578
    function foo() public{
        words = "new";
    }
}

