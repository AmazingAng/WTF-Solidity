// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ArrayTypes {

    // Arreglos de longitud fija
    uint[8] array1;
    bytes1[5] array2;
    address[100] array3;

    // Arreglo de longitud variable
    uint[] array4;
    bytes1[] array5;
    address[] array6;
    bytes array7;

    // Inicializar un array de longitud variable
    uint[] array8 = new uint[](5);
    bytes array9 = new bytes(9);
    
    // Asignar valor a un array de longitud variable
    function initArray() external pure returns(uint[] memory){
        uint[] memory x = new uint[](3);
        x[0] = 1;
        x[1] = 3;
        x[2] = 4;
        return(x);
    }

    function arrayPush() public  returns(uint[] memory){
        uint[2] memory a = [uint(1),2];
        array4 = a;
        array4.push(3);
        return array4;
    }
}

pragma solidity ^0.8.4;
contract StructTypes {
    // Struct
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student student; // Iniciar una struct de estudiante
    // Asignar el valor a una struct
    // Método 1: Se crea una referencia storage struct en la función
    function initStudent1() external{
        Student storage _student = student; // Asignar una copia de estudiante
        _student.id = 11;
        _student.score = 100;
    }

     // Método 2: Referir directamente al struct de la variable de estado
    function initStudent2() external{
        student.id = 1;
        student.score = 80;
    }

    // Método 3: Constructor struct
    function initStudent3() external {
        student = Student(3, 90);
    }
    
    // Método 4: clave valor
    function initStudent4() external {
        student = Student({id: 4, score: 60});
    }
}
