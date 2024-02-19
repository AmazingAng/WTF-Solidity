// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ArrayTypes {

    // Array de comprimento fixo
    uint[8] array1;
    bytes1[5] array2;
    address[100] array3;

    // Array de comprimento variável
    uint[] array4;
    bytes1[] array5;
    address[] array6;
    bytes array7;

    // Inicializando um Array de comprimento variável
    uint[] array8 = new uint[](5);
    bytes array9 = new bytes(9);
    // Atribuindo valores a um array de comprimento variável
    function initArray() external pure returns(uint[] memory){
        uint[] memory x = new uint[](3);
        x[0] = 1;
        x[1] = 3;
        x[2] = 4;
        return(x);
    }  
    function arrayPush() public returns(uint[] memory){
        uint[2] memory a = [uint(1),2];
        array4 = a;
        array4.push(3);
        return array4;
    }
}

pragma solidity ^0.8.4;
contract StructTypes {
    // Estrutura Struct
    struct Student{
        uint256 id;
        uint256 score; 
    }
    // Inicialize uma estrutura de dados chamada "student"
    // Atribuindo valores a uma estrutura
    // Método 1: Criar uma referência struct para storage dentro da função
    function initStudent1() external{
        // atribuir uma cópia do estudante
        _student.id = 11;
        _student.score = 100;
    }

    // Método 2: Referenciando diretamente a struct da variável de estado
    function initStudent2() external{
        student.id = 1;
        student.score = 80;
    }
    
    // Método 3: Construtor funcional
    function initStudent3() external {
        student = Student(3, 90);
    }

    // Método 4: chave valor
    function initStudent4() external {
        student = Student({id: 4, score: 60});
    }
}

pragma solidity ^0.8.4;
contract EnumTypes {
    // Comprar, Manter, Vender
    enum ActionSet { Buy, Hold, Sell }
    // Criar uma variável enum chamada "action"
    ActionSet action = ActionSet.Buy;

    // enum pode ser convertido explicitamente para uint
    function enumToUint() external view returns(uint){
        return uint(action);
    }
}
