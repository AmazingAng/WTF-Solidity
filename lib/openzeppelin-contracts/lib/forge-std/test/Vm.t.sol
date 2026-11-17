// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Test} from "../src/Test.sol";
import {Vm, VmSafe} from "../src/Vm.sol";

// These tests ensure that functions are never accidentally removed from a Vm interface, or
// inadvertently moved between Vm and VmSafe. These tests must be updated each time a function is
// added to or removed from Vm or VmSafe.
contract VmTest is Test {
    function test_VmInterfaceId() public pure {
        assertEq(type(Vm).interfaceId, bytes4(0xe835828d), "Vm");
    }

    function test_VmSafeInterfaceId() public pure {
        assertEq(type(VmSafe).interfaceId, bytes4(0x7f58f7be), "VmSafe");
    }
}
