    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.21;

    contract DataStorage {
        // The data location of x is storage.（データ格納場所xはストレージです。）
        // This is the only place where the
        // data location can be omitted.（データ格納場所を省略できるのはここだけである。）
        uint[] x = [1,2,3];

        function fStorage() public{
            //Declare a storage variable xStorage, pointing to x. Modifying xStorage also affects x
            //（格納変数xStorageを宣言し、xを指しています。xStorageを編集することはxにも影響を与えます。）
            uint[] storage xStorage = x;
            xStorage[0] = 100;
        }

        function fMemory() public view{
            //Declare a variable xMemory of Memory, copying x. Modifying xMemory does not affect x
            //（Memoryの変数xMemoryを宣言し、xをコピーしています。xMemoryを編集することはxには影響を与えません。）
            uint[] memory xMemory = x;
            xMemory[0] = 100;
            xMemory[1] = 200;
            uint[] memory xMemory2 = x;
            xMemory2[0] = 300;
        }

        function fCalldata(uint[] calldata _x) public pure returns(uint[] calldata){
            //The parameter is the calldata array, which cannot be modified（）
            //（引数はcalldateの配列であり、書き換えることはできません）
            // _x[0] = 0 //This modification will report an error（この書き換えはエラーを吐きます）
            return(_x);
        }
    }

    contract Variables {
        uint public x = 1;
        uint public y;
        string public z;

        function foo() external{
            // You can change the value of the state variable in the function
            // （関数内で状態変数の値を変えることができます）
            x = 5;
            y = 2;
            z = "0xAA";
        }

        function bar() external pure returns(uint){
            uint xx = 1;
            uint yy = 3;
            uint zz = xx + yy;
            return(zz);
        }

        function global() external view returns(address, uint, bytes memory){
            address sender = msg.sender;
            uint blockNum = block.number;
            bytes memory data = msg.data;
            return(sender, blockNum, data);
        }
    }