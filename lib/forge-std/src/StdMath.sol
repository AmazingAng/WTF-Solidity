// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @notice Mathematical utility functions for unsigned and signed integers.
library stdMath {
    int256 private constant _INT256_MIN =
        -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @notice Computes the absolute value of a signed integer.
    /// @param a The signed integer to compute the absolute value of.
    /// @return The absolute value as an unsigned integer.
    function abs(int256 a) internal pure returns (uint256) {
        // Required or it will fail when `a = type(int256).min`
        if (a == _INT256_MIN) {
            return 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        }

        return uint256(a > 0 ? a : -a);
    }

    /// @notice Computes the absolute difference between two unsigned integers.
    /// @param a The first unsigned integer.
    /// @param b The second unsigned integer.
    /// @return The absolute difference between `a` and `b`.
    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /// @notice Computes the absolute difference between two signed integers.
    /// @param a The first signed integer.
    /// @param b The second signed integer.
    /// @return The absolute difference between `a` and `b`.
    function delta(int256 a, int256 b) internal pure returns (uint256) {
        // a and b are of the same sign
        // this works thanks to two's complement, the left-most bit is the sign bit
        if ((a ^ b) > -1) {
            return delta(abs(a), abs(b));
        }

        // a and b are of opposite signs
        return abs(a) + abs(b);
    }

    /// @notice Computes the percentage difference between two unsigned integers, scaled by 1e18.
    /// @param a The value to compare.
    /// @param b The reference value (divisor). Must not be zero.
    /// @return The percentage difference scaled by 1e18 (1e18 represents 100%).
    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        // Prevent division by zero
        require(b != 0, "stdMath percentDelta(uint256,uint256): Divisor is zero");
        uint256 absDelta = delta(a, b);

        return absDelta * 1e18 / b;
    }

    /// @notice Computes the percentage difference between two signed integers, scaled by 1e18.
    /// @param a The value to compare.
    /// @param b The reference value (divisor). Its absolute value must not be zero.
    /// @return The percentage difference scaled by 1e18 (1e18 represents 100%).
    function percentDelta(int256 a, int256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        uint256 absB = abs(b);
        // Prevent division by zero
        require(absB != 0, "stdMath percentDelta(int256,int256): Divisor is zero");

        return absDelta * 1e18 / absB;
    }
}
