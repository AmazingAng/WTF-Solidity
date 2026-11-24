// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmSafe} from "./Vm.sol";

library StdStyle {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    string constant RED = "\u001b[91m";
    string constant GREEN = "\u001b[92m";
    string constant YELLOW = "\u001b[93m";
    string constant BLUE = "\u001b[94m";
    string constant MAGENTA = "\u001b[95m";
    string constant CYAN = "\u001b[96m";
    string constant BOLD = "\u001b[1m";
    string constant DIM = "\u001b[2m";
    string constant ITALIC = "\u001b[3m";
    string constant UNDERLINE = "\u001b[4m";
    string constant INVERSE = "\u001b[7m";
    string constant RESET = "\u001b[0m";

    function _styleConcat(string memory style, string memory self) private pure returns (string memory) {
        return string(abi.encodePacked(style, self, RESET));
    }

    /// @notice Returns `self` wrapped in red ANSI color codes.
    function red(string memory self) internal pure returns (string memory) {
        return _styleConcat(RED, self);
    }

    /// @notice Returns the string representation of `self` wrapped in red ANSI color codes.
    function red(uint256 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in red ANSI color codes.
    function red(int256 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in red ANSI color codes.
    function red(address self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in red ANSI color codes.
    function red(bool self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in red ANSI color codes.
    function redBytes(bytes memory self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in red ANSI color codes.
    function redBytes32(bytes32 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in green ANSI color codes.
    function green(string memory self) internal pure returns (string memory) {
        return _styleConcat(GREEN, self);
    }

    /// @notice Returns the string representation of `self` wrapped in green ANSI color codes.
    function green(uint256 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in green ANSI color codes.
    function green(int256 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in green ANSI color codes.
    function green(address self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in green ANSI color codes.
    function green(bool self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in green ANSI color codes.
    function greenBytes(bytes memory self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in green ANSI color codes.
    function greenBytes32(bytes32 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in yellow ANSI color codes.
    function yellow(string memory self) internal pure returns (string memory) {
        return _styleConcat(YELLOW, self);
    }

    /// @notice Returns the string representation of `self` wrapped in yellow ANSI color codes.
    function yellow(uint256 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in yellow ANSI color codes.
    function yellow(int256 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in yellow ANSI color codes.
    function yellow(address self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in yellow ANSI color codes.
    function yellow(bool self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in yellow ANSI color codes.
    function yellowBytes(bytes memory self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in yellow ANSI color codes.
    function yellowBytes32(bytes32 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in blue ANSI color codes.
    function blue(string memory self) internal pure returns (string memory) {
        return _styleConcat(BLUE, self);
    }

    /// @notice Returns the string representation of `self` wrapped in blue ANSI color codes.
    function blue(uint256 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in blue ANSI color codes.
    function blue(int256 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in blue ANSI color codes.
    function blue(address self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in blue ANSI color codes.
    function blue(bool self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in blue ANSI color codes.
    function blueBytes(bytes memory self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in blue ANSI color codes.
    function blueBytes32(bytes32 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in magenta ANSI color codes.
    function magenta(string memory self) internal pure returns (string memory) {
        return _styleConcat(MAGENTA, self);
    }

    /// @notice Returns the string representation of `self` wrapped in magenta ANSI color codes.
    function magenta(uint256 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in magenta ANSI color codes.
    function magenta(int256 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in magenta ANSI color codes.
    function magenta(address self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in magenta ANSI color codes.
    function magenta(bool self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in magenta ANSI color codes.
    function magentaBytes(bytes memory self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in magenta ANSI color codes.
    function magentaBytes32(bytes32 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in cyan ANSI color codes.
    function cyan(string memory self) internal pure returns (string memory) {
        return _styleConcat(CYAN, self);
    }

    /// @notice Returns the string representation of `self` wrapped in cyan ANSI color codes.
    function cyan(uint256 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in cyan ANSI color codes.
    function cyan(int256 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in cyan ANSI color codes.
    function cyan(address self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in cyan ANSI color codes.
    function cyan(bool self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in cyan ANSI color codes.
    function cyanBytes(bytes memory self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in cyan ANSI color codes.
    function cyanBytes32(bytes32 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in bold ANSI style codes.
    function bold(string memory self) internal pure returns (string memory) {
        return _styleConcat(BOLD, self);
    }

    /// @notice Returns the string representation of `self` wrapped in bold ANSI style codes.
    function bold(uint256 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in bold ANSI style codes.
    function bold(int256 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in bold ANSI style codes.
    function bold(address self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in bold ANSI style codes.
    function bold(bool self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in bold ANSI style codes.
    function boldBytes(bytes memory self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in bold ANSI style codes.
    function boldBytes32(bytes32 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in dim ANSI style codes.
    function dim(string memory self) internal pure returns (string memory) {
        return _styleConcat(DIM, self);
    }

    /// @notice Returns the string representation of `self` wrapped in dim ANSI style codes.
    function dim(uint256 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in dim ANSI style codes.
    function dim(int256 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in dim ANSI style codes.
    function dim(address self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in dim ANSI style codes.
    function dim(bool self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in dim ANSI style codes.
    function dimBytes(bytes memory self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in dim ANSI style codes.
    function dimBytes32(bytes32 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in italic ANSI style codes.
    function italic(string memory self) internal pure returns (string memory) {
        return _styleConcat(ITALIC, self);
    }

    /// @notice Returns the string representation of `self` wrapped in italic ANSI style codes.
    function italic(uint256 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in italic ANSI style codes.
    function italic(int256 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in italic ANSI style codes.
    function italic(address self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in italic ANSI style codes.
    function italic(bool self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in italic ANSI style codes.
    function italicBytes(bytes memory self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in italic ANSI style codes.
    function italicBytes32(bytes32 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in underline ANSI style codes.
    function underline(string memory self) internal pure returns (string memory) {
        return _styleConcat(UNDERLINE, self);
    }

    /// @notice Returns the string representation of `self` wrapped in underline ANSI style codes.
    function underline(uint256 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in underline ANSI style codes.
    function underline(int256 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in underline ANSI style codes.
    function underline(address self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in underline ANSI style codes.
    function underline(bool self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in underline ANSI style codes.
    function underlineBytes(bytes memory self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in underline ANSI style codes.
    function underlineBytes32(bytes32 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    /// @notice Returns `self` wrapped in inverse ANSI style codes.
    function inverse(string memory self) internal pure returns (string memory) {
        return _styleConcat(INVERSE, self);
    }

    /// @notice Returns the string representation of `self` wrapped in inverse ANSI style codes.
    function inverse(uint256 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in inverse ANSI style codes.
    function inverse(int256 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in inverse ANSI style codes.
    function inverse(address self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in inverse ANSI style codes.
    function inverse(bool self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in inverse ANSI style codes.
    function inverseBytes(bytes memory self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    /// @notice Returns the string representation of `self` wrapped in inverse ANSI style codes.
    function inverseBytes32(bytes32 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }
}
