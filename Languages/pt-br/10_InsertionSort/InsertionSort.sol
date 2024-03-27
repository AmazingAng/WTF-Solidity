// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract InsertionSort {
    // if else
    
        if (text.includes('zh')) {
            text = translate(text, 'zh', 'pt-br');
        } else {
            text = text;
        }
    }

    // for loop
    function forLoopTest() public pure returns(uint256){
        uint sum = 0;
        for(uint i = 0; i < 10; i++){
            sum += i;
        }
        return(sum);
    }

    // enquanto
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

    // Operador ternário/condicional
    function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
        // retornar o máximo entre x e y
        return x >= y ? x: y; 
    }


    // Inserção de classificação versão errada
    function insertionSortWrong(uint[] memory a) public pure returns(uint[] memory) {
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

    // Inserção de ordenação versão correta
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // observe que uint não pode receber valores negativos
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
