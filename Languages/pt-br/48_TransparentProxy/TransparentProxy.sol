// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.4;

// Exemplo de conflito de seletor
// Após remover os comentários, o contrato não será compilado, pois as duas funções têm o mesmo seletor.
contract Foo {
    bytes4 public selector1 = bytes4(keccak256("burn(uint256)"));
    bytes4 public selector2 = bytes4(keccak256("collate_propagate_storage(bytes16)"));
    // function burn(uint256) external {}
    // function collate_propagate_storage(bytes16) external {}
}


// Código de ensino para um contrato transparente e atualizável, não utilizar em produção.
contract TransparentProxy {
    // Endereço do contrato lógico
    // Administrador
    // Strings, podem ser alterados por meio de funções de contrato lógico.

    // Construtor, inicializa os endereços do admin e do contrato lógico
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback function, delegates the call to the logic contract
    // Não pode ser chamado pelo admin para evitar conflitos de seletor inesperados
    fallback() external payable {
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // Função de atualização, altera o endereço do contrato lógico, só pode ser chamada pelo admin
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
}

// Contrato de lógica antigo
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

// Novo contrato lógico
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