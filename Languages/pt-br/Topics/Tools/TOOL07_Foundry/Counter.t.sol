// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Importando dependências de teste do forge-std
// Importar contrato de negócio para teste

// Test cases for the contract dependency based on forge-std
contract CounterTest is Test {      
    Counter public counter;

    // Inicializando casos de teste
    function setUp() public { 
       counter = new Counter();
       counter.setNumber(0);
    }

    // Com base no caso de teste inicial
    // Assegura que o valor retornado do número do contador após o incremento seja igual a 1
    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    // Com base no caso de teste inicial
    // Executando teste de diferenças
    // Durante o processo de teste do forge
    // Para testar a função testSetNumber, passe diferentes valores do tipo unit256 como argumento para x
    // Alcançar o teste da função setNumber do contador para definir números diferentes para diferentes valores de x
    // Assegura que o valor retornado por number() é igual ao parâmetro x do teste de diferença.
    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // Teste de diferenças: consulte https://book.getfoundry.sh/forge/differential-ffi-testing
}