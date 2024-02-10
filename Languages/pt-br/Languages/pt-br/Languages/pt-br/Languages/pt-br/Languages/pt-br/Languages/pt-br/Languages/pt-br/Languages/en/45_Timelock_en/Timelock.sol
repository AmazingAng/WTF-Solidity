// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Timelock {
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

    // State variables
    address public admin; // Admin address
    uint public constant GRACE_PERIOD = 7 days; // Transaction validity period, expired transactions are void
    uint public delay; // Transaction lock time (seconds)
    mapping(bytes32 => bool) public queuedTransactions; // Record all transactions in the timelock queue

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
}
