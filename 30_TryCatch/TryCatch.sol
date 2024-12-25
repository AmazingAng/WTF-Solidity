// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OnlyEven {
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns (bool success){
        // 输入奇数时revert
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}

contract OnlyEven2 {
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns (uint256 success){
        // 输入奇数时revert
        require(b % 2 == 0, "Ups! Reverting");
        success = b;
    }
}

contract TryCatch {
    // 成功event
    event SuccessEvent();
    // 失败event
    event CatchEvent(string message);
    event CatchByte(bytes data);

    // 声明OnlyEven合约变量
    OnlyEven even;

    constructor() {
        even = new OnlyEven(2);
    }

    // 在external call中使用try-catch
    // execute(0)会成功并释放`SuccessEvent`
    // execute(1)会失败并释放`CatchEvent`
    function execute(uint amount) external returns (bool success) {
        try even.onlyEven(amount) returns (bool _success){
            // call成功的情况下
            emit SuccessEvent();
            return _success;
        } catch Error(string memory reason){
            // call不成功的情况下
            emit CatchEvent(reason);
        }
    }

    // 在创建新合约中使用try-catch （合约创建被视为external call）
    // executeNew(0)会失败并释放`CatchEvent`
    // executeNew(1)会失败并释放`CatchByte`
    // executeNew(2)会成功并释放`SuccessEvent`
    function executeNew(uint a) external returns (bool success) {
        try new OnlyEven(a) returns (OnlyEven _even){
            // call成功的情况下
            emit SuccessEvent();
            success = _even.onlyEven(a);
        } catch Error(string memory reason) {
            // catch revert("reasonString") 和 require(false, "reasonString")
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            // catch失败的assert assert失败的错误类型是Panic(uint256) 不是Error(string)类型 故会进入该分支
            emit CatchByte(reason);
        }
    }

    // 调用非合约的方法，这里无法被try-catch捕获，会导致revert
    function executeRevert() external {
        try OnlyEven(address(0)).onlyEven(1){
            // call成功的情况下
            emit SuccessEvent();
        } catch Error(string memory reason){
            // catch revert("reasonString") 和 require(false, "reasonString")
            emit CatchEvent(reason);
        } catch (bytes memory reason){
            // catch失败的assert assert失败的错误类型是Panic(uint256) 不是Error(string)类型 故会进入该分支
            emit CatchByte(reason);
        }
    }

    // 调用返回值不一致的方法，这里无法被try-catch捕获，会导致revert
    function executeRevert2() external returns (bool success){
        address onlyEven2 = address(new OnlyEven2(2));
        uint256 amount = 2;
        try OnlyEven(onlyEven2).onlyEven(amount) returns (bool _success){
            // call成功的情况下
            emit SuccessEvent();
            return _success;
        } catch Error(string memory reason){
            // call不成功的情况下
            emit CatchEvent(reason);
        }
    }
}
