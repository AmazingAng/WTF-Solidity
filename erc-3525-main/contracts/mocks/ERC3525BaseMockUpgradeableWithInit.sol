// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7 <0.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ContextUpgradeableWithInit is ContextUpgradeable {
    constructor() payable initializer {
        __Context_init();
    }
}
import "../ERC3525Upgradeable.sol";

contract ERC3525UpgradeableWithInit is ERC3525Upgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __ERC3525_init(name_, symbol_, decimals_);
    }
}
import "../ERC3525BurnableUpgradeable.sol";

contract ERC3525BurnableUpgradeableWithInit is ERC3525BurnableUpgradeable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) payable initializer {
        __ERC3525Burnable_init(name_, symbol_, decimals_);
    }
}
import "../ERC3525MintableUpgradeable.sol";

contract ERC3525MintableUpgradeableWithInit is ERC3525MintableUpgradeable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) payable initializer {
        __ERC3525Mintable_init(name_, symbol_, decimals_);
    }
}
import "../ERC3525SlotApprovableUpgradeable.sol";

contract ERC3525SlotApprovableUpgradeableWithInit is ERC3525SlotApprovableUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __ERC3525SlotApprovable_init(name_, symbol_, decimals_);
    }
}
import "../ERC3525SlotEnumerableUpgradeable.sol";

contract ERC3525SlotEnumerableUpgradeableWithInit is ERC3525SlotEnumerableUpgradeable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) payable initializer {
        __ERC3525SlotEnumerable_init(name_, symbol_, decimals_);
    }
}
import "./ERC3525AllRoundMockUpgradeable.sol";

contract ERC3525AllRoundMockUpgradeableWithInit is ERC3525AllRoundMockUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __ERC3525AllRoundMock_init(name_, symbol_, decimals_);
    }
}
import "./ERC3525BaseMockUpgradeable.sol";

contract ERC3525BaseMockUpgradeableWithInit is ERC3525BaseMockUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __ERC3525BaseMock_init(name_, symbol_, decimals_);
    }
}
import "./NonReceiverMockUpgradeable.sol";

contract NonReceiverMockUpgradeableWithInit is NonReceiverMockUpgradeable {
    constructor() payable initializer {
        __NonReceiverMock_init();
    }
}
import "../periphery/ERC3525MetadataDescriptorUpgradeable.sol";

contract ERC3525MetadataDescriptorUpgradeableWithInit is ERC3525MetadataDescriptorUpgradeable {
    constructor() payable initializer {
        __ERC3525MetadataDescriptor_init();
    }
}
