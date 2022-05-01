// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract InsertionSort {
    // if else
    function IfElseTest(uint256 _number) public returns(uint256){
        //if(条件){
        //    ...;
        //}else{
        //    ...;
        //}
    }

    // for loop
    function ForLoopTest(uint256 i) public{
        uint n = 1;
        for(i = 0; i < n; i++){
        //    ...;
        }
    }

    // while
    function WhileTest(uint256 i) public{
        uint n = 0;
        while(i < n){
         //   ...;
        }
    }

    // do-while
    function DoWhileTest(uint256 i) public{
        uint n = 0;
        do{
           // ...;

        }while(i < n);
    }

    // 插入排序 错误版
    function insertionSortWrong(uint[] memory a) public pure returns(uint[] memory) {
        // note that uint can not take negative value
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

    // 插入排序 正确版
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // note that uint can not take negative value
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
