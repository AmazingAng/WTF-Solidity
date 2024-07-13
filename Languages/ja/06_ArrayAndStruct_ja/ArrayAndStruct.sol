// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract ArrayTypes {

    // Fixed Length Array（固定長配列）
    uint[8] array1;
    bytes1[5] array2;
    address[100] array3;

    // Variable Length Array（可変長配列）
    uint[] array4;
    bytes1[] array5;
    address[] array6;
    bytes array7;

    // Initialize a variable-length Array（可変長配列の初期化）
    uint[] array8 = new uint[](5);
    bytes array9 = new bytes(9);
    //  Assign value to variable length array（可変長配列への代入）
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

pragma solidity ^0.8.21;
contract StructTypes {
    // Struct（構造体）
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student student; // Initially a student structure（Student構造体をインスタンス化したstudent）
    //  assign value to structure（構造体への値の代入）
    // Method 1: Create a storage struct reference in the function（関数内でstorage型の構造体の参照を作成する）
    function initStudent1() external{
        Student storage _student = student; // assign a copy of student（構造体studentのコピーを代入する）
        _student.id = 11;
        _student.score = 100;
    }

     // Method 2: Directly refer to the struct of the state variable（状態変数の構造体を直接参照する）
    function initStudent2() external{
        student.id = 1;
        student.score = 80;
    }

    // Method 3: struct constructor（構造体のコンストラクター）
    function initStudent3() external {
        student = Student(3, 90);
    }
    
    // Method 4: key value（キーと値）
    function initStudent4() external {
        student = Student({id: 4, score: 60});
    }
}
