// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract InsertionSort {
    // if else
    function IfElseTest(uint256 _number) public returns (uint256) {
        //if(条件){
        //    ...;
        //}else{
        //    ...;
        //}
    }

    // for loop
    function ForLoopTest(uint256 i) public pure {
        uint256 n = 1;
        for (i = 0; i < n; i++) {
            //    ...;
        }
    }

    // while
    function WhileTest(uint256 i) public pure {
        uint256 n = 0;
        while (i < n) {
            //   ...;
        }
    }

    // do-while
    function DoWhileTest(uint256 i) public pure {
        uint256 n = 0;
        do {
            // ...;
        } while (i < n);
    }

    // 插入排序 错误版
    function insertionSortWrong(uint256[] memory a)
        public
        pure
        returns (uint256[] memory)
    {
        // note that uint can not take negative value
        for (uint256 i = 1; i < a.length; i++) {
            uint256 temp = a[i];
            uint256 j = i - 1;
            while ((j >= 0) && (temp < a[j])) {
                a[j + 1] = a[j];
                j--;
            }
            a[j + 1] = temp;
        }
        return (a);
    }

    // 插入排序 正确版
    function insertionSort(uint256[] memory a)
        public
        pure
        returns (uint256[] memory)
    {
        // note that uint can not take negative value
        for (uint256 i = 1; i < a.length; i++) {
            uint256 temp = a[i];
            uint256 j = i;
            while ((j >= 1) && (temp < a[j - 1])) {
                a[j] = a[j - 1];
                j--;
            }
            a[j] = temp;
        }
        return (a);
    }
}
