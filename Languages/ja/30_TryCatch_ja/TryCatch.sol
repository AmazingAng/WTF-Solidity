// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OnlyEven {
    constructor(uint256 a) {
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns (bool success) {
        // 奇数の場合はrevertする
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}

contract TryCatch {
    // 成功イベント
    event SuccessEvent();
    // 失敗イベント
    event CatchEvent(string message);
    event CatchByte(bytes data);

    // OnlyEvenのコントラクト変数を宣言
    OnlyEven even;

    constructor() {
        even = new OnlyEven(2);
    }

    // external callの中でtry-catchを使用する
    // execute(0)の場合、成功してイベント`SuccessEvent`を放出
    // execute(1)の場合、失敗してイベント`CatchEvent`を放出
    function execute(uint256 amount) external returns (bool success) {
        try even.onlyEven(amount) returns (bool _success) {
            // callが成功した場合
            emit SuccessEvent();
            return _success;
        } catch Error(string memory reason) {
            // callが失敗した場合
            emit CatchEvent(reason);
        }
    }

    // コントラクト作成時にtry-catchを使用する（コントラクトの作成はexternal callとみなされる）
    // executeNew(0)の場合、失敗してイベント`CatchEvent`を放出
    // executeNew(1)の場合、失敗してイベント`CatchEvent`を放出
    // executeNew(2)の場合、成功してイベント`SuccessEvent`を放出
    function executeNew(uint256 a) external returns (bool success) {
        try new OnlyEven(a) returns (OnlyEven _even) {
            // callが成功した場合
            emit SuccessEvent();
            success = _even.onlyEven(a);
        } catch Error(string memory reason) {
            // revert("reasonString")やrequire(false, "reasonString")をキャッチする
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            // assert()のエラーをcatchでキャッチする
            // assert()の場合、エラーのタイプは`Panic(uint256)`なので、`Error(stiing)`とは異なる。だから、このcatchに入る
            emit CatchByte(reason);
        }
    }
}
