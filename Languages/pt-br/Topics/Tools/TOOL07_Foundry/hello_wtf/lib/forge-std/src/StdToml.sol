// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmSafe} from "./Vm.sol";

// Helpers for parsing and writing TOML files
// To parse:
// ```
// using stdToml for string;
// string memory toml = vm.readFile("<some_path>");
// toml.readUint("<toml_path>");
// ```
// To write:
// ```
// using stdToml for string;
// string memory toml = "toml";
// toml.serialize("a", uint256(123));
// string memory semiFinal = toml.serialize("b", string("test"));
// string memory finalToml = toml.serialize("c", semiFinal);
// finalToml.write("<some_path>");
// ```

library stdToml {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Returns whether `key` exists in `toml`.
    function keyExists(string memory toml, string memory key) internal view returns (bool) {
        return vm.keyExistsToml(toml, key);
    }

    /// @notice ABI-encodes the TOML value selected by `key`.
    function parseRaw(string memory toml, string memory key) internal pure returns (bytes memory) {
        return vm.parseToml(toml, key);
    }

    /// @notice Reads a uint256 value at `key` from `toml`.
    function readUint(string memory toml, string memory key) internal pure returns (uint256) {
        return vm.parseTomlUint(toml, key);
    }

    /// @notice Reads a uint256 array at `key` from `toml`.
    function readUintArray(string memory toml, string memory key) internal pure returns (uint256[] memory) {
        return vm.parseTomlUintArray(toml, key);
    }

    /// @notice Reads an int256 value at `key` from `toml`.
    function readInt(string memory toml, string memory key) internal pure returns (int256) {
        return vm.parseTomlInt(toml, key);
    }

    /// @notice Reads an int256 array at `key` from `toml`.
    function readIntArray(string memory toml, string memory key) internal pure returns (int256[] memory) {
        return vm.parseTomlIntArray(toml, key);
    }

    /// @notice Reads a bytes32 value at `key` from `toml`.
    function readBytes32(string memory toml, string memory key) internal pure returns (bytes32) {
        return vm.parseTomlBytes32(toml, key);
    }

    /// @notice Reads a bytes32 array at `key` from `toml`.
    function readBytes32Array(string memory toml, string memory key) internal pure returns (bytes32[] memory) {
        return vm.parseTomlBytes32Array(toml, key);
    }

    /// @notice Reads a string value at `key` from `toml`.
    function readString(string memory toml, string memory key) internal pure returns (string memory) {
        return vm.parseTomlString(toml, key);
    }

    /// @notice Reads a string array at `key` from `toml`.
    function readStringArray(string memory toml, string memory key) internal pure returns (string[] memory) {
        return vm.parseTomlStringArray(toml, key);
    }

    /// @notice Reads an address value at `key` from `toml`.
    function readAddress(string memory toml, string memory key) internal pure returns (address) {
        return vm.parseTomlAddress(toml, key);
    }

    /// @notice Reads an address array at `key` from `toml`.
    function readAddressArray(string memory toml, string memory key) internal pure returns (address[] memory) {
        return vm.parseTomlAddressArray(toml, key);
    }

    /// @notice Reads a bool value at `key` from `toml`.
    function readBool(string memory toml, string memory key) internal pure returns (bool) {
        return vm.parseTomlBool(toml, key);
    }

    /// @notice Reads a bool array at `key` from `toml`.
    function readBoolArray(string memory toml, string memory key) internal pure returns (bool[] memory) {
        return vm.parseTomlBoolArray(toml, key);
    }

    /// @notice Reads a bytes value at `key` from `toml`.
    function readBytes(string memory toml, string memory key) internal pure returns (bytes memory) {
        return vm.parseTomlBytes(toml, key);
    }

    /// @notice Reads a bytes array at `key` from `toml`.
    function readBytesArray(string memory toml, string memory key) internal pure returns (bytes[] memory) {
        return vm.parseTomlBytesArray(toml, key);
    }

    /// @notice Reads a uint256 value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readUintOr(string memory toml, string memory key, uint256 defaultValue) internal view returns (uint256) {
        return keyExists(toml, key) ? readUint(toml, key) : defaultValue;
    }

    /// @notice Reads a uint256 array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readUintArrayOr(string memory toml, string memory key, uint256[] memory defaultValue)
        internal
        view
        returns (uint256[] memory)
    {
        return keyExists(toml, key) ? readUintArray(toml, key) : defaultValue;
    }

    /// @notice Reads an int256 value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readIntOr(string memory toml, string memory key, int256 defaultValue) internal view returns (int256) {
        return keyExists(toml, key) ? readInt(toml, key) : defaultValue;
    }

    /// @notice Reads an int256 array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readIntArrayOr(string memory toml, string memory key, int256[] memory defaultValue)
        internal
        view
        returns (int256[] memory)
    {
        return keyExists(toml, key) ? readIntArray(toml, key) : defaultValue;
    }

    /// @notice Reads a bytes32 value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readBytes32Or(string memory toml, string memory key, bytes32 defaultValue)
        internal
        view
        returns (bytes32)
    {
        return keyExists(toml, key) ? readBytes32(toml, key) : defaultValue;
    }

    /// @notice Reads a bytes32 array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readBytes32ArrayOr(string memory toml, string memory key, bytes32[] memory defaultValue)
        internal
        view
        returns (bytes32[] memory)
    {
        return keyExists(toml, key) ? readBytes32Array(toml, key) : defaultValue;
    }

    /// @notice Reads a string value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readStringOr(string memory toml, string memory key, string memory defaultValue)
        internal
        view
        returns (string memory)
    {
        return keyExists(toml, key) ? readString(toml, key) : defaultValue;
    }

    /// @notice Reads a string array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readStringArrayOr(string memory toml, string memory key, string[] memory defaultValue)
        internal
        view
        returns (string[] memory)
    {
        return keyExists(toml, key) ? readStringArray(toml, key) : defaultValue;
    }

    /// @notice Reads an address value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readAddressOr(string memory toml, string memory key, address defaultValue)
        internal
        view
        returns (address)
    {
        return keyExists(toml, key) ? readAddress(toml, key) : defaultValue;
    }

    /// @notice Reads an address array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readAddressArrayOr(string memory toml, string memory key, address[] memory defaultValue)
        internal
        view
        returns (address[] memory)
    {
        return keyExists(toml, key) ? readAddressArray(toml, key) : defaultValue;
    }

    /// @notice Reads a bool value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readBoolOr(string memory toml, string memory key, bool defaultValue) internal view returns (bool) {
        return keyExists(toml, key) ? readBool(toml, key) : defaultValue;
    }

    /// @notice Reads a bool array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readBoolArrayOr(string memory toml, string memory key, bool[] memory defaultValue)
        internal
        view
        returns (bool[] memory)
    {
        return keyExists(toml, key) ? readBoolArray(toml, key) : defaultValue;
    }

    /// @notice Reads a bytes value at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readBytesOr(string memory toml, string memory key, bytes memory defaultValue)
        internal
        view
        returns (bytes memory)
    {
        return keyExists(toml, key) ? readBytes(toml, key) : defaultValue;
    }

    /// @notice Reads a bytes array at `key` from `toml`, returning `defaultValue` if the key does not exist.
    function readBytesArrayOr(string memory toml, string memory key, bytes[] memory defaultValue)
        internal
        view
        returns (bytes[] memory)
    {
        return keyExists(toml, key) ? readBytesArray(toml, key) : defaultValue;
    }

    /// @notice Serializes a JSON object `rootObject` under `jsonKey` and returns the serialized string.
    /// @dev Values are accumulated as JSON in memory; conversion to TOML happens on `write`.
    function serialize(string memory jsonKey, string memory rootObject) internal returns (string memory) {
        return vm.serializeJson(jsonKey, rootObject);
    }

    /// @notice Serializes a bool `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, bool value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    /// @notice Serializes a bool array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, bool[] memory value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    /// @notice Serializes a uint256 `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, uint256 value) internal returns (string memory) {
        return vm.serializeUint(jsonKey, key, value);
    }

    /// @notice Serializes a uint256 array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, uint256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeUint(jsonKey, key, value);
    }

    /// @notice Serializes an int256 `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, int256 value) internal returns (string memory) {
        return vm.serializeInt(jsonKey, key, value);
    }

    /// @notice Serializes an int256 array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, int256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeInt(jsonKey, key, value);
    }

    /// @notice Serializes an address `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, address value) internal returns (string memory) {
        return vm.serializeAddress(jsonKey, key, value);
    }

    /// @notice Serializes an address array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, address[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeAddress(jsonKey, key, value);
    }

    /// @notice Serializes a bytes32 `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, bytes32 value) internal returns (string memory) {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    /// @notice Serializes a bytes32 array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, bytes32[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    /// @notice Serializes a bytes `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, bytes memory value) internal returns (string memory) {
        return vm.serializeBytes(jsonKey, key, value);
    }

    /// @notice Serializes a bytes array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, bytes[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes(jsonKey, key, value);
    }

    /// @notice Serializes a string `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, string memory value) internal returns (string memory) {
        return vm.serializeString(jsonKey, key, value);
    }

    /// @notice Serializes a string array `value` under `key` within `jsonKey` and returns the serialized string.
    function serialize(string memory jsonKey, string memory key, string[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    /// @notice Writes the serialized object `jsonKey` to `path` as a TOML file.
    function write(string memory jsonKey, string memory path) internal {
        vm.writeToml(jsonKey, path);
    }

    /// @notice Writes the value at `valueKey` from the serialized object `jsonKey` to `path` as a TOML file.
    function write(string memory jsonKey, string memory path, string memory valueKey) internal {
        vm.writeToml(jsonKey, path, valueKey);
    }
}
