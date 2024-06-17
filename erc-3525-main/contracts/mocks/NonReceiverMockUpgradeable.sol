// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NonReceiverMockUpgradeable is Initializable {
    function __NonReceiverMock_init() internal onlyInitializing {
    }

    function __NonReceiverMock_init_unchained() internal onlyInitializing {
    }
    

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}