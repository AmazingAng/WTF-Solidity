// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract InsertionSort {
    // if else
    function ifElseTest(uint256 _number) public pure returns(bool){
        if(_number == 0){
            return(true);
        }else{
            return(false);
        }
    }

    // bucle for
    function forLoopTest() public pure returns(uint256){
        uint sum = 0;
        for(uint i = 0; i < 10; i++){
            sum += i;
        }
        return(sum);
    }

    // while
    function whileTest() public pure returns(uint256){
        uint sum = 0;
        uint i = 0;
        while(i < 10){
            sum += i;
            i++;
        }
        return(sum);
    }

    // do-while
    function doWhileTest() public pure returns(uint256){
        uint sum = 0;
        uint i = 0;
        do{
            sum += i;
            i++;
        }while(i < 10);
        return(sum);
    }

    // Operador Ternario/Condicional
    function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
        // devuelve el máximo entre x e y
        return x >= y ? x: y; 
    }


    // Ordenamiento por Inserción (Versión incorrecta)
    function insertionSortWrong(uint[] memory a) public pure returns(uint[] memory) {
        // nota que uint no puede tomar valor negativo
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i];
            uint j=i-1;
            while( (j >= 0) && (temp < a[j])){
                a[j+1] = a[j];
                j--;
            }
            a[j+1] = temp;
        }
        return(a);
    }

    // Ordenamiento por Inserción (Versión Correcta)
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // nota que uint no puede tomar valor negativo
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i];
            uint j=i;
            while( (j >= 1) && (temp < a[j-1])){
                a[j] = a[j-1];
                j--;
            }
            a[j] = temp;
        }
        return(a);
    }
}
