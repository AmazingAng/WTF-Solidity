// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

// 💬 ABOUT
// Forge Std's default Script.

// 🧩 MODULES
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {safeconsole} from "./safeconsole.sol";
import {StdChains} from "./StdChains.sol";
import {StdCheatsSafe} from "./StdCheats.sol";
import {StdConstants} from "./StdConstants.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorageSafe} from "./StdStorage.sol";
import {StdStyle} from "./StdStyle.sol";
import {StdUtils} from "./StdUtils.sol";
import {VmSafe} from "./Vm.sol";

// 📦 BOILERPLATE
import {ScriptBase} from "./Base.sol";

/// @notice Default base contract for Forge scripts.
/// @dev Includes safe cheatcodes, chain helpers, utility helpers, and console modules.
abstract contract Script is ScriptBase, StdChains, StdCheatsSafe, StdUtils {
    /// @notice Marker used by Forge to identify script contracts.
    /// @dev The generated `IS_SCRIPT()` getter must return true.
    bool public IS_SCRIPT = true;
}
