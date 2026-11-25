// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @dev Library for interaction with secp256k1 elliptic curve,
/// described by equation `y² ≡ x³ + ax + b (mod P)`
/// where `a = 0` and `b = 7`.
/// @dev Curve parameters taken from:
/// - https://en.bitcoin.it/wiki/Secp256k1
/// - https://github.com/ethereum/go-ethereum/blob/v1.17.5/crypto/secp256k1/curve.go#L267
/// @dev Coordinate representations:
/// The affine point at infinity is represented as `(0, 0)`.
/// Projective inputs use homogeneous coordinates: `(X, Y, Z)` represents the affine point
/// `(X / Z, Y / Z)` over the secp256k1 base field. These are not Jacobian coordinates,
/// which use `(X / Z², Y / Z³)`.
/// For projective inputs, the point at infinity is `(0, y, 0)` for any non-zero `y`.
/// Projective results are normalized: finite points return `(x, y, 1)`, and the point
/// at infinity returns `(0, 1, 0)`.
/// `Vm.ecAffineToProjective` maps `(0, 0)` to `(0, 1, 0)` and finite points to `(x, y, 1)`.
/// `Vm.ecProjectiveToAffine` maps projective points at infinity to `(0, 0)` and normalizes
/// finite points to affine coordinates.
library StdSecp256k1 {
    /// @dev Curve parameter `a = 0`.
    uint256 internal constant A = 0x0000000000000000000000000000000000000000000000000000000000000000;
    /// @dev Curve parameter `b = 7`.
    uint256 internal constant B = 0x0000000000000000000000000000000000000000000000000000000000000007;
    /// @dev Field prime `P = 2^256 - 2^32 - 977`. Affine coordinates `(x, y)` are canonically in `[0, P)`.
    uint256 internal constant P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    /// @dev Group order `N`. Scalars are canonically in `[0, N)`; private keys in `[1, N)`.
    /// `Vm.ecMul*` reduces scalars modulo `N`, so any `uint256` scalar is accepted.
    uint256 internal constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    /// @dev X coordinate of generator point (`G`).
    uint256 internal constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    /// @dev Y coordinate of generator point (`G`).
    uint256 internal constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    /// @notice Returns whether the affine point `(x, y)` is the point at infinity `(0, 0)`.
    function isIdentityAffine(uint256 x, uint256 y) internal pure returns (bool) {
        return x == 0 && y == 0;
    }

    /// @notice Returns the secp256k1 point at infinity in affine coordinates as `(0, 0)`.
    function identityAffine() internal pure returns (uint256 x, uint256 y) {
        return (0, 0);
    }

    /// @notice Returns the secp256k1 generator point `G` in affine coordinates as `(GX, GY)`.
    function generatorAffine() internal pure returns (uint256 x, uint256 y) {
        return (GX, GY);
    }

    /// @notice Returns whether the projective point `(x, y, z)` is the point at infinity.
    /// @dev Homogeneous `(X / Z, Y / Z)`, not Jacobian `(X / Z², Y / Z³)`.
    /// `Vm` infinity is `(0, y, 0)` with `y != 0 && y < P` (normalized `(0, 1, 0)`).
    function isIdentityProjective(uint256 x, uint256 y, uint256 z) internal pure returns (bool) {
        return x == 0 && z == 0 && y != 0 && y < P;
    }

    /// @notice Returns the secp256k1 point at infinity in projective coordinates as `(0, 1, 0)`.
    function identityProjective() internal pure returns (uint256 x, uint256 y, uint256 z) {
        return (0, 1, 0);
    }

    /// @notice Returns the secp256k1 generator point `G` in projective coordinates as `(GX, GY, 1)`.
    function generatorProjective() internal pure returns (uint256 x, uint256 y, uint256 z) {
        return (GX, GY, 1);
    }

    /// @notice Returns whether the affine point `(x, y)` is on the curve `y² ≡ x³ + 7 (mod P)`.
    /// @dev Uses `mulmod`/`addmod` for field arithmetic.
    function isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        // https://github.com/ethereum/go-ethereum/blob/v1.17.5/crypto/secp256k1/curve.go#L75
        return mulmod(y, y, P) == addmod(mulmod(x, mulmod(x, x, P), P), B, P);
    }

    /// @notice Returns whether `scalar` is canonically valid (`scalar` in `[0, N)`).
    function isValidScalar(uint256 scalar) internal pure returns (bool) {
        return scalar < N;
    }

    /// @notice Returns whether `scalar` is a valid non-zero scalar (`scalar` in `[1, N)`).
    function isValidNonZeroScalar(uint256 scalar) internal pure returns (bool) {
        return scalar != 0 && scalar < N;
    }

    /// @notice Returns `y` parity: `0` if even, `1` if odd.
    function yParity(uint256 y) internal pure returns (uint256) {
        return y & 1;
    }

    /// @notice Returns Ethereum `yParity`: `27` if even, `28` if odd (as used in `ecrecover` / `v`).
    function yParityEthereum(uint256 y) internal pure returns (uint256) {
        // https://github.com/ethereum/go-ethereum/blob/v1.17.5/core/vm/contracts.go#L303
        unchecked {
            return yParity(y) + 27;
        }
    }

    /// @notice Returns compressed `y` prefix: `2` if even, `3` if odd (SEC 1 compressed point).
    function yCompressed(uint256 y) internal pure returns (uint256) {
        // https://github.com/ethereum/go-ethereum/blob/v1.17.5/crypto/secp256k1/libsecp256k1/src/eckey_impl.h#L46
        // https://github.com/ethereum/go-ethereum/blob/v1.17.5/crypto/secp256k1/libsecp256k1/include/secp256k1.h#L215-L217
        unchecked {
            return yParity(y) + 2;
        }
    }

    /// @notice Computes Ethereum address from full public key `(x, y)`
    /// as `address(uint160(uint256(keccak256(abi.encode(x, y)))))`.
    function toAddress(uint256 x, uint256 y) internal pure returns (address addr) {
        // https://github.com/ethereum/go-ethereum/blob/v1.17.5/core/vm/contracts.go#L322
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.7.0/contracts/utils/cryptography/Hashes.sol
        assembly ("memory-safe") {
            mstore(0x00, x)
            mstore(0x20, y)
            addr := and(keccak256(0x00, 0x40), sub(shl(160, 1), 1))
        }
    }
}
