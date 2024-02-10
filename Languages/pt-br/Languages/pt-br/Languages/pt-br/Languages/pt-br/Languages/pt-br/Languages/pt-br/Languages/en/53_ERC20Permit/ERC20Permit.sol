// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
* @dev ERC20 Permit extended interface that allows approval via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
  *
  * Added {permit} method to change an account's ERC20 balance via a message signed by the account (see {IERC20-allowance}). By not relying on {IERC20-approve}, token holders' accounts do not need to send transactions and therefore do not need to hold Ether at all.
 */
contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev initializes the name of EIP712 and the name and symbol of ERC20
     */
    constructor(string memory name, string memory symbol) EIP712(name, "1") ERC20(name, symbol){}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // Check deadline
         require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

         // Splice Hash
         bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
         bytes32 hash = _hashTypedDataV4(structHash);
        
         // Calculate the signer from the signature and message, and verify the signature
         address signer = ECDSA.recover(hash, v, r, s);
         require(signer == owner, "ERC20Permit: invalid signature");
        
         //Authorize
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consumption nonce": Returns the current `nonce` of the `owner` and increases it by 1.
      */
     function _useNonce(address owner) internal virtual returns (uint256 current) {
         current = _nonces[owner];
         _nonces[owner] += 1;
     }

     // @dev mint tokens
    function mint(uint amount) external {
        _mint(msg.sender, amount);
    }
}
