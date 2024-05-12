// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Selector {
    // event returns msg.data
    event Log(bytes data);

    // input parameter to: 0x2c44b726ADF1963cA47Af88B284C06f30380fC78
    function mint(
        address /*to*/
    ) external {
        emit Log(msg.data);
    }

    // output selector
    // "mint(address)"： 0x6a627842
    function mintSelector() external pure returns (bytes4 mSelector) {
        return bytes4(keccak256("mint(address)"));
    }

    // use selector to call function
    function callWithSignature() external returns (bool, bytes memory) {
        //  use `abi.encodeWithSelector` to pack and encode the `mint` function's `selector` and parameters
        (bool success, bytes memory data) = address(this).call(
            abi.encodeWithSelector(
                0x6a627842,
                "0x2c44b726ADF1963cA47Af88B284C06f30380fC78"
            )
        );
        return (success, data);
    }
}
