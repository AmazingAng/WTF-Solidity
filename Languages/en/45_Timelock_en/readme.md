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

---

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
    // Event
    // transaction cancel event
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint executeTime
    );
    // transaction execution event
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint executeTime
    );
    // transaction created and queued event
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint executeTime
    );
    // Event to change administrator address
    event NewAdmin(address indexed newAdmin);
```

### State Variables

There are a total of 4 state variables in the `Timelock` contract.

- `admin`: The address of the administrator.
- `delay`: The lock up period.
- `GRACE_PERIOD`: The time period until a transaction expires. If a transaction is scheduled to be executed but it is not executed within `GRACE_PERIOD`, it will expire.
- `queuedTransactions`: A mapping of `txHash` identifier to `bool` that records all the transactions in the timelock queue.

```solidity
    // State variables
    address public admin; // Admin address
    uint public constant GRACE_PERIOD = 7 days; // Transaction validity period, expired transactions are void
    uint public delay; // Transaction lock time (seconds)
    mapping(bytes32 => bool) public queuedTransactions; // Record all transactions in the timelock queue
```

### Modifiers

There are `2` modifiers in the `Timelock` contract.

- `onlyOwner()`: the function it modifies can only be executed by the administrator.
- `onlyTimelock()`: the function it modifies can only be executed by the timelock contract.

```solidity
    // onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    // onlyTimelock modifier
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
     * @dev Constructor, initialize transaction lock time (seconds) and administrator address
     */
    constructor(uint delay_) {
        delay = delay_;
        admin = msg.sender;
    }

    /**
     * @dev To change the administrator address, the caller must be a Timelock contract.
     */
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }

    /**
     * @dev Create a transaction and add it to the timelock queue.
     * @param target: Target contract address
     * @param value: Send eth value
     * @param signature: The function signature to call (function signature)
     * @param data: call data, which contains some parameters
     * @param executeTime: Blockchain timestamp of transaction execution
     *
     * Requirement: executeTime is greater than the current blockchain timestamp + delay
     */
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner returns (bytes32) {
        // Check: transaction execution time meets lock time
        require(
            executeTime >= getBlockTimestamp() + delay,
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );
        // Calculate the unique identifier for the transaction
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // Add transaction to queue
        queuedTransactions[txHash] = true;

        emit QueueTransaction(
            txHash,
            target,
            value,
            signature,
            data,
            executeTime
        );
        return txHash;
    }

    /**
     * @dev Cancel a specific transaction.
     *
     * Requirement: the transaction is in the timelock queue
     */
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public onlyOwner {
        // Calculate the unique identifier for the transaction
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // Check: transaction is in timelock queue
        require(
            queuedTransactions[txHash],
            "Timelock::cancelTransaction: Transaction hasn't been queued."
        );
        // dequeue the transaction
        queuedTransactions[txHash] = false;

        emit CancelTransaction(
            txHash,
            target,
            value,
            signature,
            data,
            executeTime
        );
    }

    /**
     * @dev Execute a specific transaction
     *
     * 1. The transaction is in the timelock queue
     * 2. The execution time of the transaction is reached
     * 3. The transaction has not expired
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executeTime
    ) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // Check: Is the transaction in the timelock queue
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        // Check: the execution time of the transaction is reached
        require(
            getBlockTimestamp() >= executeTime,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        // Check: the transaction has not expired
        require(
            getBlockTimestamp() <= executeTime + GRACE_PERIOD,
            "Timelock::executeTransaction: Transaction is stale."
        );
        // remove the transaction from the queue
        queuedTransactions[txHash] = false;

        // get callData
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }
        // Use call to execute transactions
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        emit ExecuteTransaction(
            txHash,
            target,
            value,
            signature,
            data,
            executeTime
        );


        return returnData;
    }

    /**
     * @dev Get the current blockchain timestamp
     */
    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev transaction identifier
     */
    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(target, value, signature, data, executeTime));
    }
```

## `Remix` Demo

### 1. Deploy the `Timelock` contract with a lockup period of `120` seconds

![`Remix` Demo](./img/45-1.jpg)

### 2. Calling `changeAdmin()` directly will result in an error

![`Remix` Demo](./img/45-2.jpg)

### 3. Creating a transaction to change the administrator

To construct the transaction, we need to fill in the following parameters:
address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime

- `target`: Since we are calling a function of `Timelock`, we fill in the contract address.
- `value`: No need to transfer ETH, fill in `0` here.
- `signature`: The function signature of `changeAdmin()` is: `"changeAdmin(address)"`.
- `data`: Fill in the parameter to be passed, which is the address of the new administrator. But the address needs to be padded to 32 bytes of data to meet the [Ethereum ABI Encoding Standard](https://github.com/AmazingAng/WTFSolidity/blob/main/27_ABIEncode/readme.md). You can use the [hashex](https://abi.hashex.org/) website to encode the parameters to ABI. Example:

  ```solidity
  Address before encoding：0xd9145CCE52D386f254917e481eB44e9943F39138
  encoded address：0x000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2
  ```

- `executeTime`: First, call `getBlockTimestamp()` to obtain the current time of the blockchain, and then add 150 seconds to it and fill it in.
  ![`Remix` Demo](./img/45-3.jpg)

### 4. Call `queueTransaction` to add the transaction to the time-lock queue

![`Remix` Demo](./img/45-4.jpg)

### 5. Calling `executeTransaction` within the locking period will fail

![`Remix` Demo](./img/45-5.jpg)

### 6. Calling `executeTransaction` after the locking period has expired will result in a successful transaction

![`Remix` Demo](./img/45-6.jpg)

### 7. Check the new `admin` address

![`Remix` Demo](./img/45-7.jpg)

## Conclusion

A time lock can lock certain functions of a smart contract for a period of time, greatly reducing the chance of rug pulls and hacking attacks by project parties, and increasing the security of decentralized applications. It has been widely adopted by DeFi and DAO, including Uniswap and Compound. Does the project you are investing in use a time lock?
