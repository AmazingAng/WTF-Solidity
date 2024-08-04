// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Owner {
   address public owner; // define owner variable（所有者の変数を定義する）

   // constructor（コンストラクター）
   constructor() {
      owner = msg.sender; // set owner to the address of deployer when contract is being deployed
                          //（スマートコントラクトがデプロイされている際に、開発者のアドレス（「所有者アドレス」）を変数ownerに設定する）
   }

   // define modifier
   modifier onlyOwner {
      require(msg.sender == owner); // check whether caller is address of owner（実行する者がownerのアドレスかどうかチェックする）
      _; // if true，continue to run the body of function；otherwise throw an error and revert transaction
         //（もしtrueならば、関数本体を引き続き実行する; さもなければエラーを吐き、トランザクションを元に戻す）
   }

   // define a function with onlyOwner modifier（onlyOwner修飾子で関数を定義する）
   function changeOwner(address _newOwner) external onlyOwner{
      owner = _newOwner; // only owner address can run this function and change owner
                         //（所有者アドレスだけがこの関数を実行でき、所有者を変更できる）
   }
}