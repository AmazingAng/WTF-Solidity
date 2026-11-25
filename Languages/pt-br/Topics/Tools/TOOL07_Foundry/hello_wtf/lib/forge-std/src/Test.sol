// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

// 💬 ABOUT
// Forge Std's default Test.

// 🧩 MODULES
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {safeconsole} from "./safeconsole.sol";
import {StdAssertions} from "./StdAssertions.sol";
import {StdChains} from "./StdChains.sol";
import {StdCheats} from "./StdCheats.sol";
import {StdConstants} from "./StdConstants.sol";
import {stdError} from "./StdError.sol";
import {StdInvariant} from "./StdInvariant.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorage} from "./StdStorage.sol";
import {StdStyle} from "./StdStyle.sol";
import {stdToml} from "./StdToml.sol";
import {StdUtils} from "./StdUtils.sol";
import {Vm} from "./Vm.sol";

// 📦 BOILERPLATE
import {TestBase} from "./Base.sol";

/// @notice Default base contract for Forge tests.
/// @dev Includes assertions, cheatcodes, invariant helpers, chain helpers, utility helpers, and console modules.
abstract contract Test is TestBase, StdAssertions, StdChains, StdCheats, StdInvariant, StdUtils {
    /// @notice Marker used by Forge to identify test contracts.
    /// @dev The generated `IS_TEST()` getter must return true.
    bool public IS_TEST = true;
}
