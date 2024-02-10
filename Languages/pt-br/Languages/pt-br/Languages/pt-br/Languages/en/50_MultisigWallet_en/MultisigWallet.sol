// SPDX-License-Identifier: MIT
// author: @0xAA_Science from wtf.academy
pragma solidity ^0.8.4;

/// 基于签名的多签钱包，由gnosis safe合约简化而来，教学使用。
contract MultisigWallet {
    event ExecutionSuccess(bytes32 txHash); // succeeded transaction event
    event ExecutionFailure(bytes32 txHash); // failed transaction event

    address[] public owners; // multisig owners array
    mapping(address => bool) public isOwner; // check if an address is a multisig owner
    uint256 public ownerCount; // the count of multisig owners
    uint256 public threshold; // minimum number of signatures required for multisig execution
    uint256 public nonce; // nonce，prevent signature replay attack

    receive() external payable {}

    // 构造函数，初始化owners, isOwner, ownerCount, threshold
    // constructor, initializes owners, isOwner, ownerCount, threshold
    constructor(address[] memory _owners, uint256 _threshold) {
        _setupOwners(_owners, _threshold);
    }

    /// @dev Initialize owners, isOwner, ownerCount, threshold
    /// @param _owners: Array of multisig owners
    /// @param _threshold: Minimum number of signatures required for multisig execution
    function _setupOwners(
        address[] memory _owners,
        uint256 _threshold
    ) internal {
        // If threshold was not initialized
        require(threshold == 0, "WTF5000");
        // multisig execution threshold is less than the number of multisig owners
        require(_threshold <= _owners.length, "WTF5001");
        // multisig execution threshold is at least 1
        require(_threshold >= 1, "WTF5002");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            // multisig owners cannot be zero address, contract address, and cannot be repeated
            require(
                owner != address(0) &&
                    owner != address(this) &&
                    !isOwner[owner],
                "WTF5003"
            );
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev After collecting enough signatures from the multisig, execute transaction
    /// @param to Target contract address
    /// @param value msg.value, ether paid
    /// @param data calldata
    /// @param signatures packed signatures, corresponding to the multisig address in ascending order, for easy checking ({bytes32 r}{bytes32 s}{uint8 v}) (signature of the first multisig, signature of the second multisig...)
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        // Encode transaction data and compute hash
        bytes32 txHash = encodeTransactionData(
            to,
            value,
            data,
            nonce,
            block.chainid
        );
        // Increase nonce
        nonce++;
        // Check signatures
        checkSignatures(txHash, signatures);
        // Execute transaction using call and get transaction result
        (success, ) = to.call{value: value}(data);
        require(success, "WTF5004");
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    /**
     * @dev checks if the hash of the signature and transaction data matches. if signature is invalid, transaction will revert
     * @param dataHash hash of transaction data
     * @param signatures bundles multiple multisig signature together
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // get multisig threshold
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");

        // checks if signature length is enough
        require(signatures.length >= _threshold * 65, "WTF5006");

        // checks if collected signatures are valid
        // procedure:
        // 1. use ECDSA to verify if signatures are valid
        // 2. use currentOwner > lastOwner to make sure that signatures are from different multisig owners
        // 3. use isOwner[currentOwner] to make sure that current signature is from a multisig owner
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // use ECDSA to verify if signature is valid
            currentOwner = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        dataHash
                    )
                ),
                v,
                r,
                s
            );
            require(
                currentOwner > lastOwner && isOwner[currentOwner],
                "WTF5007"
            );
            lastOwner = currentOwner;
        }
    }

    /// split a single signature from a packed signature.
    /// @param signatures Packed signatures.
    /// @param pos Index of the multisig.
    function signatureSplit(
        bytes memory signatures,
        uint256 pos
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // signature format: {bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /// @dev hash transaction data
    /// @param to target contract's address
    /// @param value msg.value eth to be paid
    /// @param data calldata
    /// @param _nonce nonce of the transaction
    /// @param chainid chainid
    /// @return bytes of transaction hash
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash = keccak256(
            abi.encode(to, value, keccak256(data), _nonce, chainid)
        );
        return safeTxHash;
    }
}
