// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract InsertionSort {
    // if else
    function ifElseTest(uint256 _number) public pure returns(bool){
        if(_number == 0){
            return(true);
        }else{
            return(false);
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

    // Ternary/Conditional operator（三項演算子/条件演算子）
    function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
        // return the max of x and y（xとyの最大値を返す）
        return x >= y ? x: y; 
    }


    // Insertion Sort(Wrong version）（挿入ソート(間違いバージョン)）
    function insertionSortWrong(uint[] memory a) public pure returns(uint[] memory) {
        // note that uint can not take negative value（uint型は負の数を取れないことに注意すること）
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

    // Insertion Sort（Correct Version）（挿入ソート(正確なバージョン)）
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // note that uint can not take negative value（uint型は負の数を取れないことに注意すること）
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
