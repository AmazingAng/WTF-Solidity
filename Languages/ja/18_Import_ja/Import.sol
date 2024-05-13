// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 通过文件相对位置import
import "./Yeye.sol";
// 通过`全局符号`导入特定的合约
import {Yeye} from "./Yeye.sol";
// 通过网址引用
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
// 引用OpenZeppelin合约
import "@openzeppelin/contracts/access/Ownable.sol";

contract Import {
    // Addressライブラリをimportできた
    using Address for address;
    // yeye変数を宣言

    Yeye yeye = new Yeye();

    // yeyeの関数を呼び出すテスト
    function test() external {
        yeye.hip();
    }
}
