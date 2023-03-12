---
title: 45. Time Lock
tags:
  - solidity
  - application

---

# WTF Solidity Quick Start: 45. Time Lock

I've been relearning Solidity recently to strengthen some details and write a "WTF Solidity Quick Start" for beginners (programming experts can find other tutorials), updated weekly with 1-3 lessons.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://wechat.wtf.academy)｜[wtf.academy](https://wtf.academy)

All code and tutorials are open-sourced on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lesson, we introduce time locks and time lock contracts. The code is based on the simplified version of the [Timelock contract](https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol) of Compound.

## Timelock

![Timelock](./img/45-1.jpeg)

A timelock is a locking mechanism commonly found in bank vaults and other high-security containers. It is a timer designed to prevent a safe or vault from being opened before a predetermined time, even if the person unlocking it knows the correct password.

In blockchain, timelocks are widely used in DeFi and DAO. It is a piece of code that can lock certain functions of a smart contract for a period of time. It can greatly improve the security of a smart contract. For example, if a hacker hacks the multi-signature of Uniswap and intends to withdraw the funds from the vault, but the vault contract has a timelock of 2 days, the hacker needs to wait for 2 days from creating the withdrawal transaction to actually withdraw the money. During this period, the project party can find countermeasures, and investors can sell tokens in advance to reduce losses.

## Timelock contract

Next, we will introduce the Timelock contract. Its logic is not complicated:

- When creating a Timelock contract, the project party can set the lock-in period and set the contract's administrator to itself.

- The Timelock mainly has three functions:
    - Create a transaction and add it to the timelock queue.
    - Execute the transaction after the lock-in period of the transaction.
    - Regret, cancel some transactions in the timelock queue.

- The project party generally sets the timelock contract as the administrator of important contracts, such as the vault contract, and then operates them through the timelock.

- The administrator of a timelock contract is usually a multi-signature wallet of the project, ensuring decentralization.

### Events
There are 4 events in the `Timelock` contract.
- `QueueTransaction`: Event when a transaction is created and enters the timelock queue.
- `ExecuteTransaction`: Event when a transaction is executed after the lockup period ends.
- `CancelTransaction`: Event when a transaction is cancelled.
- `NewAdmin`: Event when the administrator's address is modified.

```Solidity
    // Events
    // Event triggered when a transaction is cancelled
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // Event triggered when a transaction is executed
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // Event triggered when a transaction is created and added to the queue
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    // Event triggered when the admin address is changed
    event NewAdmin(address indexed newAdmin);
```

### State Variables
There are a total of 4 state variables in the `Timelock` contract.

- `admin`: The address of the administrator.
- `delay`: The lock up period.
- `GRACE_PERIOD`: The time period until a transaction expires. If a transaction is scheduled to be executed but it is not executed within `GRACE_PERIOD`, it will expire.
- `queuedTransactions`: A mapping of `txHash` identifier to `bool` that records all the transactions in the timelock queue.

```solidity
    // 状态变量
    address public admin; // 管理员地址
    uint public constant GRACE_PERIOD = 7 days; // 交易有效期，过期的交易作废
    uint public delay; // 交易锁定时间 （秒）
    mapping (bytes32 => bool) public queuedTransactions; // txHash到bool，记录所有在时间锁队列中的交易
```

### Modifiers
There are `2` modifiers in the `Timelock` contract.
- `onlyOwner()`: the function it modifies can only be executed by the administrator.
- `onlyTimelock()`: the function it modifies can only be executed by the timelock contract.

```solidity
    // onlyOwner modifier
    // ensures that the caller is the admin
    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    // onlyTimelock modifier
    // ensures that the caller is the Timelock contract itself
    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;
    }
```

### Functions
There are a total of 7 functions in the `Timelock` contract.

- Constructor: Initializes the transaction locking time (in seconds) and the administrator address.
- `queueTransaction()`: Creates a transaction and adds it to the time lock queue. The parameters are complicated because they describe a complete transaction:
    - `target`: the target contract address
    - `value`: the amount of ETH sent
    - `signature`: the function signature being called
    - `data`: the call data of the transaction
    - `executeTime`: the blockchain timestamp when the transaction will be executed.
    
    When calling this function, it is necessary to ensure that the expected execution time `executeTime` is greater than the current blockchain timestamp + the lock time `delay`. The unique identifier for the transaction is the hash value of all the parameters, calculated using the `getTxHash()` function. Transactions that enter the queue will update the `queuedTransactions` variable and release a `QueueTransaction` event.
- `executeTransaction()`: Executes a transaction. Its parameters are the same as `queueTransaction()`. The transaction to be executed must be in the time lock queue, reach its execution time, and not be expired. The `call` member function of `solidity` is used to execute the transaction, which was introduced in [Lesson 22](https://github.com/AmazingAng/WTFSolidity/blob/main/22_Call/readme.md).
- `cancelTransaction()`: Cancels a transaction. Its parameters are the same as `queueTransaction()`. The transaction to be cancelled must be in the queue. The `queuedTransactions` will be updated and a `CancelTransaction` event will be released.
- `changeAdmin()`: Changes the administrator address and can only be called by the `Timelock` contract.
- `getBlockTimestamp()`: Gets the current blockchain timestamp.
- `getTxHash()`: Returns the identifier of the transaction, which is the `hash` of many transaction parameters.

```solidity
    /**
     * @dev 构造函数，初始化交易锁定时间 （秒）和管理员地址
     */
    constructor(uint delay_) {
        delay = delay_;
        admin = msg.sender;
    }

    /**
     * @dev 改变管理员地址，调用者必须是Timelock合约。
     */
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }

    /**
     * @dev 创建交易并添加到时间锁队列中。
     * @param target: 目标合约地址
     * @param value: 发送eth数额
     * @param signature: 要调用的函数签名（function signature）
     * @param data: call data，里面是一些参数
     * @param executeTime: 交易执行的区块链时间戳
     *
     * 要求：executeTime 大于 当前区块链时间戳+delay
     */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns (bytes32) {
        // 检查：交易执行时间满足锁定时间
        require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        // 计算交易的唯一识别符：一堆东西的hash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 将交易添加到队列
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, executeTime);
        return txHash;
    }

    /**
     * @dev 取消特定交易。
     *
     * 要求：交易在时间锁队列中
     */
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner{
        // 计算交易的唯一识别符：一堆东西的hash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 检查：交易在时间锁队列中
        require(queuedTransactions[txHash], "Timelock::cancelTransaction: Transaction hasn't been queued.");
        // 将交易移出队列
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }

    /**
     * @dev 执行特定交易。
     *
     * 要求：
     * 1. 交易在时间锁队列中
     * 2. 达到交易的执行时间
     * 3. 交易没过期
     */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 检查：交易是否在时间锁队列中
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        // 检查：达到交易的执行时间
        require(getBlockTimestamp() >= executeTime, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        // 检查：交易没过期
       require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
        // 将交易移出队列
        queuedTransactions[txHash] = false;

        // 获取call data
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // 利用call执行交易
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);

        return returnData;
    }

    /**
     * @dev 获取当前区块链时间戳
     */
    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev 将一堆东西拼成交易的标识符
     */
    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, executeTime));
    }
```

## `Remix` Demo
### 1. Deploy the `Timelock` contract with a lockup period of `120` seconds.

![`Remix` Demo](./img/45-1.jpg)

### 2. Calling `changeAdmin()` directly will result in an error.

![`Remix` Demo](./img/45-2.jpg)

### 3. Creating a transaction to change the administrator.
To construct the transaction, we need to fill in the following parameters:
address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime
- `target`: Since we are calling a function of `Timelock`, we fill in the contract address.
- `value`: No need to transfer ETH, fill in `0` here.
- `signature`: The function signature of `changeAdmin()` is: `"changeAdmin(address)"`.
- `data`: Fill in the parameter to be passed, which is the address of the new administrator. But the address needs to be padded to 32 bytes of data to meet the [Ethereum ABI Encoding Standard](https://github.com/AmazingAng/WTFSolidity/blob/main/27_ABIEncode/readme.md). You can use the [hashex](https://abi.hashex.org/) website to encode the parameters to ABI. Example:

    ```solidity
    编码前地址：0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    编码后地址：0x000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2
    ```

- `executeTime`: First, call `getBlockTimestamp()` to obtain the current time of the blockchain, and then add 150 seconds to it and fill it in.
- Call `queueTransaction` to add the transaction to the time-lock queue.
- Calling `executeTransaction` within the locking period will fail.
- Calling `executeTransaction` after the locking period has expired will result in a successful transaction.
- Check the new `admin` address.
- Conclusion

A time lock can lock certain functions of a smart contract for a period of time, greatly reducing the chance of rug pulls and hacking attacks by project parties, and increasing the security of decentralized applications. It has been widely adopted by DeFi and DAO, including Uniswap and Compound. Does the project you are investing in use a time lock?