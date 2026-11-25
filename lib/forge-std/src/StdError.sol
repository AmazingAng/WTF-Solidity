// SPDX-License-Identifier: MIT OR Apache-2.0
// Panics work for versions >=0.8.0, but we lowered the pragma to make this compatible with Test
pragma solidity >=0.8.13 <0.9.0;

/// @notice Pre-encoded Solidity panic error selectors for use in test assertions.
library stdError {
    /// @notice Panic caused by `assert(false)` or an assertion failure (0x01).
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);

    /// @notice Panic caused by arithmetic overflow or underflow (0x11).
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);

    /// @notice Panic caused by division or modulo by zero (0x12).
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);

    /// @notice Panic caused by converting a value that is too large or negative into an enum type (0x21).
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);

    /// @notice Panic caused by accessing incorrectly encoded storage data (0x22).
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);

    /// @notice Panic caused by calling `.pop()` on an empty array (0x31).
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);

    /// @notice Panic caused by accessing an array, bytesN, or slice at an out-of-bounds index (0x32).
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);

    /// @notice Panic caused by allocating too much memory or creating an array that is too large (0x41).
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);

    /// @notice Panic caused by calling a zero-initialized variable of internal function type (0x51).
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
}
