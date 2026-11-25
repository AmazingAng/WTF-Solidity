// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {VmSafe} from "./Vm.sol";

// Helpers for parsing and writing JSON files.
// `key` parameters use the same selector syntax as the `vm.parseJson*` cheatcodes,
// for example `.a` for a nested field or `$` for the root object.
// To parse:
// ```
// using stdJson for string;
// string memory json = vm.readFile("<some_path>");
// uint256 value = json.readUint(".a");
// bytes memory encoded = json.parseRaw("$");
// ```
// To write:
// ```
// using stdJson for string;
// string memory json = "json";
// json.serialize("a", uint256(123));
// string memory semiFinal = json.serialize("b", string("test"));
// string memory finalJson = json.serialize("c", semiFinal);
// finalJson.write("<some_path>");
// ```

library stdJson {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Returns whether `key` exists in `json`.
    /// @dev `key` uses the same selector syntax as `vm.parseJson*`, such as `.a` or `$`.
    function keyExists(string memory json, string memory key) internal view returns (bool) {
        return vm.keyExistsJson(json, key);
    }

    /// @notice ABI-encodes the JSON value selected by `key`.
    /// @dev `key` uses the same selector syntax as `vm.parseJson*`, such as `.a` or `$`.
    /// @dev The value's type is inferred, not declared. A hex string of exactly 20 bytes is encoded
    /// as an `address` and one of exactly 32 bytes as a `bytes32`; every other length is encoded as
    /// dynamic `bytes`. Decoding those two lengths as `bytes` therefore reverts, so prefer
    /// `readBytes` when the value is meant to be byte data.
    function parseRaw(string memory json, string memory key) internal pure returns (bytes memory) {
        return vm.parseJson(json, key);
    }

    /// @notice Reads a uint256 value at `key` from `json`.
    function readUint(string memory json, string memory key) internal pure returns (uint256) {
        return vm.parseJsonUint(json, key);
    }

    /// @notice Reads a uint256 array at `key` from `json`.
    function readUintArray(string memory json, string memory key) internal pure returns (uint256[] memory) {
        return vm.parseJsonUintArray(json, key);
    }

    /// @notice Reads an int256 value at `key` from `json`.
    function readInt(string memory json, string memory key) internal pure returns (int256) {
        return vm.parseJsonInt(json, key);
    }

    /// @notice Reads an int256 array at `key` from `json`.
    function readIntArray(string memory json, string memory key) internal pure returns (int256[] memory) {
        return vm.parseJsonIntArray(json, key);
    }

    /// @notice Reads a bytes32 value at `key` from `json`.
    function readBytes32(string memory json, string memory key) internal pure returns (bytes32) {
        return vm.parseJsonBytes32(json, key);
    }

    /// @notice Reads a bytes32 array at `key` from `json`.
    function readBytes32Array(string memory json, string memory key) internal pure returns (bytes32[] memory) {
        return vm.parseJsonBytes32Array(json, key);
    }

    /// @notice Reads a string value at `key` from `json`.
    function readString(string memory json, string memory key) internal pure returns (string memory) {
        return vm.parseJsonString(json, key);
    }

    /// @notice Reads a string array at `key` from `json`.
    function readStringArray(string memory json, string memory key) internal pure returns (string[] memory) {
        return vm.parseJsonStringArray(json, key);
    }

    /// @notice Reads an address value at `key` from `json`.
    function readAddress(string memory json, string memory key) internal pure returns (address) {
        return vm.parseJsonAddress(json, key);
    }

    /// @notice Reads an address array at `key` from `json`.
    function readAddressArray(string memory json, string memory key) internal pure returns (address[] memory) {
        return vm.parseJsonAddressArray(json, key);
    }

    /// @notice Reads a bool value at `key` from `json`.
    function readBool(string memory json, string memory key) internal pure returns (bool) {
        return vm.parseJsonBool(json, key);
    }

    /// @notice Reads a bool array at `key` from `json`.
    function readBoolArray(string memory json, string memory key) internal pure returns (bool[] memory) {
        return vm.parseJsonBoolArray(json, key);
    }

    /// @notice Reads a bytes value at `key` from `json`.
    function readBytes(string memory json, string memory key) internal pure returns (bytes memory) {
        return vm.parseJsonBytes(json, key);
    }

    /// @notice Reads a bytes array at `key` from `json`.
    function readBytesArray(string memory json, string memory key) internal pure returns (bytes[] memory) {
        return vm.parseJsonBytesArray(json, key);
    }

    /// @notice Reads a uint256 value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readUintOr(string memory json, string memory key, uint256 defaultValue) internal view returns (uint256) {
        return keyExists(json, key) ? readUint(json, key) : defaultValue;
    }

    /// @notice Reads a uint256 array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readUintArrayOr(string memory json, string memory key, uint256[] memory defaultValue)
        internal
        view
        returns (uint256[] memory)
    {
        return keyExists(json, key) ? readUintArray(json, key) : defaultValue;
    }

    /// @notice Reads an int256 value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readIntOr(string memory json, string memory key, int256 defaultValue) internal view returns (int256) {
        return keyExists(json, key) ? readInt(json, key) : defaultValue;
    }

    /// @notice Reads an int256 array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readIntArrayOr(string memory json, string memory key, int256[] memory defaultValue)
        internal
        view
        returns (int256[] memory)
    {
        return keyExists(json, key) ? readIntArray(json, key) : defaultValue;
    }

    /// @notice Reads a bytes32 value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readBytes32Or(string memory json, string memory key, bytes32 defaultValue)
        internal
        view
        returns (bytes32)
    {
        return keyExists(json, key) ? readBytes32(json, key) : defaultValue;
    }

    /// @notice Reads a bytes32 array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readBytes32ArrayOr(string memory json, string memory key, bytes32[] memory defaultValue)
        internal
        view
        returns (bytes32[] memory)
    {
        return keyExists(json, key) ? readBytes32Array(json, key) : defaultValue;
    }

    /// @notice Reads a string value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readStringOr(string memory json, string memory key, string memory defaultValue)
        internal
        view
        returns (string memory)
    {
        return keyExists(json, key) ? readString(json, key) : defaultValue;
    }

    /// @notice Reads a string array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readStringArrayOr(string memory json, string memory key, string[] memory defaultValue)
        internal
        view
        returns (string[] memory)
    {
        return keyExists(json, key) ? readStringArray(json, key) : defaultValue;
    }

    /// @notice Reads an address value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readAddressOr(string memory json, string memory key, address defaultValue)
        internal
        view
        returns (address)
    {
        return keyExists(json, key) ? readAddress(json, key) : defaultValue;
    }

    /// @notice Reads an address array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readAddressArrayOr(string memory json, string memory key, address[] memory defaultValue)
        internal
        view
        returns (address[] memory)
    {
        return keyExists(json, key) ? readAddressArray(json, key) : defaultValue;
    }

    /// @notice Reads a bool value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readBoolOr(string memory json, string memory key, bool defaultValue) internal view returns (bool) {
        return keyExists(json, key) ? readBool(json, key) : defaultValue;
    }

    /// @notice Reads a bool array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readBoolArrayOr(string memory json, string memory key, bool[] memory defaultValue)
        internal
        view
        returns (bool[] memory)
    {
        return keyExists(json, key) ? readBoolArray(json, key) : defaultValue;
    }

    /// @notice Reads a bytes value at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readBytesOr(string memory json, string memory key, bytes memory defaultValue)
        internal
        view
        returns (bytes memory)
    {
        return keyExists(json, key) ? readBytes(json, key) : defaultValue;
    }

    /// @notice Reads a bytes array at `key` from `json`, returning `defaultValue` if the key does not exist.
    function readBytesArrayOr(string memory json, string memory key, bytes[] memory defaultValue)
        internal
        view
        returns (bytes[] memory)
    {
        return keyExists(json, key) ? readBytesArray(json, key) : defaultValue;
    }

    /// @notice Serializes a JSON object `rootObject` under `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory rootObject) internal returns (string memory) {
        return vm.serializeJson(jsonKey, rootObject);
    }

    /// @notice Serializes a bool `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, bool value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    /// @notice Serializes a bool array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, bool[] memory value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    /// @notice Serializes a uint256 `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, uint256 value) internal returns (string memory) {
        return vm.serializeUint(jsonKey, key, value);
    }

    /// @notice Serializes a uint256 array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, uint256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeUint(jsonKey, key, value);
    }

    /// @notice Serializes an int256 `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, int256 value) internal returns (string memory) {
        return vm.serializeInt(jsonKey, key, value);
    }

    /// @notice Serializes an int256 array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, int256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeInt(jsonKey, key, value);
    }

    /// @notice Serializes an address `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, address value) internal returns (string memory) {
        return vm.serializeAddress(jsonKey, key, value);
    }

    /// @notice Serializes an address array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, address[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeAddress(jsonKey, key, value);
    }

    /// @notice Serializes a bytes32 `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, bytes32 value) internal returns (string memory) {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    /// @notice Serializes a bytes32 array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, bytes32[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    /// @notice Serializes a bytes `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, bytes memory value) internal returns (string memory) {
        return vm.serializeBytes(jsonKey, key, value);
    }

    /// @notice Serializes a bytes array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, bytes[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes(jsonKey, key, value);
    }

    /// @notice Serializes a string `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, string memory value) internal returns (string memory) {
        return vm.serializeString(jsonKey, key, value);
    }

    /// @notice Serializes a string array `value` under `key` within `jsonKey` and returns the serialized JSON string.
    function serialize(string memory jsonKey, string memory key, string[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    /// @notice Writes the serialized JSON object `jsonKey` to `path`.
    function write(string memory jsonKey, string memory path) internal {
        vm.writeJson(jsonKey, path);
    }

    /// @notice Writes the value at `valueKey` from the serialized JSON object `jsonKey` to `path`.
    function write(string memory jsonKey, string memory path, string memory valueKey) internal {
        vm.writeJson(jsonKey, path, valueKey);
    }
}
