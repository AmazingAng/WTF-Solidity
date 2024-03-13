// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.21;

// O Proxy da UUPS é semelhante a um proxy comum.
// A função de atualização está dentro da função lógica, onde o administrador pode alterar o endereço do contrato lógico usando a função de atualização, alterando assim a lógica do contrato.
// Para fins de demonstração educacional, não utilizar em ambiente de produção.
contract UUPSProxy {
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
}

// Contrato lógico UUPS (função de atualização escrita dentro do contrato lógico)
contract UUPS1{
    // Variáveis de estado e contratos proxy são consistentes para evitar conflitos de slot
    address public implementation; 
    address public admin; 
    // Strings, podem ser alterados por meio de funções de contrato lógico.

    // Alterando a variável de estado no proxy, seletor: 0xc2985578
    function foo() public{
        words = "old";
    }

    // Função de atualização, altera o endereço do contrato lógico, só pode ser chamada pelo admin. Selector: 0x0900f010
    // Em UUPS, a função lógica deve incluir uma função de atualização, caso contrário, não será possível fazer mais atualizações.
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// Novo contrato lógico UUPS
contract UUPS2{
    // Variáveis de estado e contratos proxy são consistentes para evitar conflitos de slot
    address public implementation; 
    address public admin; 
    // Strings, podem ser alterados por meio de funções de contrato lógico.

    // Alterando a variável de estado no proxy, seletor: 0xc2985578
    function foo() public{
        words = "new";
    }

    // Função de atualização, altera o endereço do contrato lógico, só pode ser chamada pelo admin. Selector: 0x0900f010
    // Em UUPS, a função lógica deve incluir uma função de atualização, caso contrário, não será possível fazer mais atualizações.
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}


