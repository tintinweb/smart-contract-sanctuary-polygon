// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
import "@openzeppelin/contracts/utils/Context.sol";

pragma solidity 0.8.17;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract EZRContext  {
    function msgSender() internal view  returns (address) {
        if (isContract(msg.sender)) {
            return tx.origin;
        } else {
            return msg.sender;
        }
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IYousovStructs {
    enum AccountType {
        REGULAR,
        PSEUDO
     }
    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
    enum UserStatus {
        OPT_IN,
        OPT_OUT

    }
    enum UserRole {
        SENIOR,
        JUNIOR,
        STANDARD,
        DENIED
    }
    enum RecoveryStatus {
        CREATED,
        IN_PROGRESS,
        OVER
    }
    enum RecoveryRole{
        QUESTION_AGENT,
        ANSWER_AGENT
    }
    struct AnswerAgentsDetails{
        string initialAnswer;
        string actualAnswer;
        bool answer;
    }
    struct PII {
        string firstName;
        string middelName;
        string lastName;
        string cityOfBirth;
        string countryOfBirth;
        string countryOfCitizenship;
        string uid;
        uint256 birthDateTimeStamp;
        Gender gender;
    }
    struct Wallet{
        address publicAddr;
        string walletPassword;
        string privateKey;
    }
    struct Challenge {
        string question;
        string answer;
        string id;
    }
    enum TransactionType {
        TRANSACTION_IN, TRANSACTION_OUT
    }
    struct Transaction {
    TransactionType transactionType;
    uint256 transactionDate;
    uint256 amount;
    address from;
    address to;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
pragma experimental ABIEncoderV2;
import "../../interface/IYousovStructs.sol";
interface IUser is IYousovStructs {
    function pseudonym() view external returns (string memory pseudonym);
    function userChallenges() view external returns(string[] memory _userChallenges) ;
    function setSecret(string memory newSecret) external ;
    function setPseudoym(string memory newPseudonym) external ;
    function setPII(PII memory newPII) external ;
    function setWallet(string memory walletPassword) external ;
    function getWalletDetails() external view  returns (Wallet memory);
    function setAccountType(AccountType newAccountType) external;
    function getAccountType() external view  returns (AccountType);
    function setThreashold(uint256 newThreashold) external;
    function getPII() external view  returns (PII memory);
    function switchUserStatus(UserStatus newStatus) external;
    function updateUserAccountTypeFromPiiToPseudo(string memory pseudo) external;
    function updateUserAccountTypeFromPseudoToPii(PII memory newPII) external;
    function setChallenges(Challenge[] memory newChallenges , uint256 newThreashold ) external;
    function checkWalletPassword(string memory walletPassword) view external  returns (Wallet memory wallet);
    event SecretUpdated();
    event PseudonymUpdated();
    event PIIUpdated();
    event ChallengesUpdated();
    event WalletUpdated();
    event AccountTypeUpdated();
    event ThreasholdUpdated();
    event StatusUpdated();
    event UpdateUserIdentityFromPIIToPseudo();
    event UpdateUserIdentityFromPseudoToPII();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUserFactory is IYousovStructs {
    function yousovUserList() external view returns (address[] memory );
    function userContract(address) external view returns (address);
    function newUser(PII memory pii , Wallet memory wallet, Challenge[] memory challenges, string memory pseudonym , AccountType accountType, uint256 threashold ) external;
    function deleteUser() external;
    function checkUnicity(AccountType userAccountTpe , PII memory userPII , string memory userPseudo) external view returns(bool exists, address userContractAddr);
    event UserCreated();
    event UserDeleted(address userDeletedAddress);
   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;
import "./interface/IUser.sol";
import "../EZR/EZRContext.sol";
import "../YousovAccessControl.sol";

import "../YousovRoles.sol";
// import "hardhat/console.sol";
contract User is IUser, EZRContext, YousovRoles {
    PII public pii;
    string public pseudonym;
    string[] public challenges;
    mapping(string => Challenge) public challengeDetails;
    Wallet public wallet;
    string public secret;
    uint256 public threashold;
    AccountType public accountType;
    UserStatus public userStatus;
    address public yousovAccessControl;
    string[5] oldWalletPasswords;   
    uint8 public indexToStoreNextPassword; 
    constructor(
        address _yousovAccessControl,
        PII memory _pii,
        Wallet memory _wallet,
        Challenge[] memory _challenges,
        string memory _pseudonym,
        AccountType _accountType,
        uint256 _threashold
    ) {
        if (_accountType == AccountType.PSEUDO) {
            pseudonym = _pseudonym;
        }
        if (_accountType == AccountType.REGULAR) {
            pii = _pii;
        }
        wallet = _wallet;
        accountType = _accountType;
        threashold = _threashold;
        yousovAccessControl = _yousovAccessControl;
        for (uint i = 0; i < _challenges.length; i++) {
            challenges.push(_challenges[i].id);
            challengeDetails[_challenges[i].id] = _challenges[i];
        }
        userStatus = UserStatus.OPT_IN;
        savePassword(wallet.walletPassword);
    }

    modifier onlyUser() {
        require(
            tx.origin == wallet.publicAddr &&
                YousovAccessControl(yousovAccessControl).hasRole(
                    YOUSOV_USER_ROLE,
                    tx.origin
                ),
            "Yousov : Update not authorized"
        );
        _;
    }

    /*******************************************************************************
     **	@notice Set the secret of a user. This may only be called by the user.
     **	@param newSecret The new secret of the user. The previous secret will be replaced by the new secret. 
     *******************************************************************************/
    function setSecret(string memory newSecret) external override onlyUser {
        secret = newSecret;
        emit SecretUpdated();
    }

    /*******************************************************************************
     **	@notice Set the challenges and the threashold of a user. This may only be called by the user.
     **	@param newChallenges The new challenges of the user (array of challenge that contains (question, answer, id).
     **	@param newThreashold The new threashold of the user. It sets the minimum correct answers needed to access to the vault.
     *******************************************************************************/
    function setChallenges(
        Challenge[] memory newChallenges,
        uint256 newThreashold
    ) external override onlyUser {
        delete challenges;
        for (uint i = 0; i < newChallenges.length; ++i) {
            challenges.push(newChallenges[i].id);
            challengeDetails[newChallenges[i].id] = newChallenges[i];
        }
        emit ChallengesUpdated();
        this.setThreashold(newThreashold);
    }

    /*******************************************************************************
     **	@notice Set the pseudonym of a user. This may only be called by the user.
     **	@param newPseudonym The new pseudonym of the user. The previous pseudonym will be replaced by the new pseudonym. 
     *******************************************************************************/
    function setPseudoym(
        string memory newPseudonym
    ) external override onlyUser {
        require(
            accountType == AccountType.PSEUDO,
            "Yousov : Update not authorized"
        );
        pseudonym = newPseudonym;
        emit PseudonymUpdated();
    }

    /*******************************************************************************
     **	@notice Set the pii of a user. This may only be called by the user.
     **	@param newPII The new pii of the user that contains (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender). The previous pii will be replaced by the new pii. 
     *******************************************************************************/
    function setPII(PII memory newPII) external override onlyUser {
        require(
            accountType == AccountType.REGULAR,
            "Yousov : Update not authorized"
        );
        pii = newPII;
        emit PIIUpdated();
    }

    /*******************************************************************************
     **	@notice Check if the new wallet password of a user was already used, return true if the new wallet password is not in the oldWalletPasswords array.
     **	@param newWalletPassword The new wallet password of the user. 
     *******************************************************************************/
    function checkValidNewWalletPassword(string memory newWalletPassword) view private returns(bool) {
        for (uint i=0; i < oldWalletPasswords.length; ++i) {
            if (keccak256(abi.encodePacked(newWalletPassword)) == keccak256(abi.encodePacked(oldWalletPasswords[i]))) {
                return false;
            }
        }
        return true;
    }

    /*******************************************************************************
     **	@notice Save the wallet password of a user. Only the oldWalletPasswords.length most recent passwords are kept.
     **	@param newWalletPassword The new wallet password of the user. 
     *******************************************************************************/
    function savePassword(string memory newWalletPassword) private {
        oldWalletPasswords[indexToStoreNextPassword] = newWalletPassword;
        indexToStoreNextPassword = uint8((indexToStoreNextPassword + 1) % oldWalletPasswords.length);
    }

    /*******************************************************************************
     **	@notice Set the wallet password of a user. This may only be called by the user.
     **	@param walletPassword The new wallet password of the user. The previous wallet password will be replaced by the new one.
     *******************************************************************************/
    function setWallet(
        string memory walletPassword
    ) external override onlyUser {
        require(checkValidNewWalletPassword(walletPassword), "Yousov : Please do not use an already used password");
        wallet.walletPassword = walletPassword;
        savePassword(walletPassword);
        emit WalletUpdated();
    }

    /*******************************************************************************
     **	@notice Set the account type of a user. This may only be called by the user.
     **	@param newAccountType The new account type the user (example: AccountType.REGULAR or AccountType.PSEUDO).
     *******************************************************************************/
    function setAccountType(AccountType newAccountType) external override onlyUser {
        accountType = newAccountType;
        emit AccountTypeUpdated();
    }

    /*******************************************************************************
     **	@notice Set the threashold of a user. This may only be called by the user.
     **	@param newThreashold The new threashold of the user. It sets the minimum correct answers needed to access to the vault.
     *******************************************************************************/
    function setThreashold(uint256 newThreashold) external override onlyUser {
        threashold = newThreashold;
        emit ThreasholdUpdated();
    }

    /*******************************************************************************
     **	@notice Get the wallet details of a user (publicAddr, walletPassword, privateKey).
     *******************************************************************************/
    function getWalletDetails() external view override returns (Wallet memory) {
        return wallet;
    }

    /*******************************************************************************
     **	@notice Get the account type a user.
     *******************************************************************************/
    function getAccountType() external view override returns (AccountType) {
        return accountType;
    }

    /*******************************************************************************
     **	@notice Get the pii a user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     *******************************************************************************/
    function getPII() external view override returns (PII memory) {
        return pii;
    }

    /*******************************************************************************
     **	@notice Switch from regular account type to pseudo account type and set the pseudonym of a user. This may only be called by the user.
     **	@param pseudo The new pseudonym of the user. The previous pseudonym will be replaced by the new pseudonym. 
     *******************************************************************************/
    function updateUserAccountTypeFromPiiToPseudo(
        string memory pseudo
    ) external override onlyUser {
        require(accountType == AccountType.REGULAR, "Yousov : Update not authorized");
        _switchAccountType();
        this.setPseudoym(pseudo);
        emit UpdateUserIdentityFromPIIToPseudo();
    }

    /*******************************************************************************
     **	@notice Switch from pseudo account type to regular account type and set the pii of a user. This may only be called by the user.
     **	@param newPII The new pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender). The previous pii will be replaced by the new pii.
     *******************************************************************************/
    function updateUserAccountTypeFromPseudoToPii(
        PII memory newPII
    ) external override onlyUser {
        require(accountType == AccountType.PSEUDO, "Yousov : Update not authorized");
        _switchAccountType();
        this.setPII(newPII);
        emit UpdateUserIdentityFromPseudoToPII();
    }

    /*******************************************************************************
     **	@notice Check the wallet password. Return the user wallet if the wallet password is correct, revert if it is uncorrect.
     **	@param walletPassword The wallet password the user.
     *******************************************************************************/
    function checkWalletPassword(string memory walletPassword) external view override returns (Wallet memory userWallet) {
        if (
            keccak256(abi.encodePacked(walletPassword)) ==
            keccak256(abi.encodePacked(wallet.walletPassword))
        ) {
            return wallet;
        } else {
            revert("Yousov : Wrong password");
        }
    }

    /*******************************************************************************
     **	@notice Set the status of a user. This may only be called by the user.
     **	@param newStatus The new status of the user (OPT_IN, OPT_OUT). The previous pii will be replaced by the new pii.
     *******************************************************************************/
    function switchUserStatus(UserStatus newStatus) external override onlyUser {
        userStatus = newStatus;
        emit StatusUpdated();
    }

    /*******************************************************************************
     **	@notice Switch the account type of a user.
     *******************************************************************************/
    function _switchAccountType() internal {
        if (accountType == AccountType.PSEUDO) {
            accountType = AccountType.REGULAR;
        } else {
            accountType = AccountType.PSEUDO;
        }
    }

    function userChallenges()
        external
        view
        override
        returns (string[] memory _userChallenges)
    {
        return challenges;
    }
    // function setAsQuestionAgent(string memory question) external override {
    //     recoveryRole = RecoveryRole.QUESTION_AGENT;

    //     emit ThreasholdUpdated();
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IUserFactory.sol";
import "./User.sol";
import "../YousovAccessControl.sol";
import "../YousovRoles.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

contract UserFactory is IUserFactory, YousovRoles, ERC2771Context {
    address[] public userList;
    mapping(address => address) public userContract;
    address public yousovAccessControl;
    
    constructor(address _yousovAccessControl,MinimalForwarder forwarder) ERC2771Context(address(forwarder)) {
        yousovAccessControl = _yousovAccessControl;
        YousovAccessControl(_yousovAccessControl).setUserFactory(address(this));
    }

    modifier onlyAdminRole() {
        YousovAccessControl(yousovAccessControl).checkRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _;
    }

    /*******************************************************************************
     **	@notice Create a new user. This may only be called by the forwarder.
     **	@param pii The pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     **	@param wallet The wallet of the user (publicAddr, walletPassword, privateKey).
     **	@param challenges The challenges of the user (array of challenge that contains (question, answer, id).
     **	@param newPseudonym The new pseudonym of the user.
     **	@param accountType The account type of the user (example: AccountType.REGULAR or AccountType.PSEUDO).
     **	@param threashold The threashold fixed by the user. It sets the minimum correct answers needed to access to the vault.
     *******************************************************************************/
    function newUser(
        PII memory pii,
        Wallet memory wallet,
        Challenge[] memory challenges,
        string memory newPseudonym,
        AccountType accountType,
        uint256 threashold) external override
    {
        require(
            isTrustedForwarder(msg.sender),
            "Yousov : Operation not authorized, not the trustedForwarder"
        );
        (bool userExist, address userAddressContract) = this.checkUnicity(
            accountType,
            pii,
            newPseudonym
        );
        if (userExist) {
            if (accountType == AccountType.REGULAR) {
                revert("Yousov : User already exist");
            } else {
                revert("Yousov : User already exist");
            }
        }
        address newUserContract = address(
            new User(
                yousovAccessControl,
                pii,
                wallet,
                challenges,
                newPseudonym,
                accountType,
                threashold
            )
        );
      
        YousovAccessControl(yousovAccessControl).grantRole(YOUSOV_USER_ROLE, wallet.publicAddr);

        userList.push(newUserContract);

        userContract[wallet.publicAddr] = newUserContract;

        emit UserCreated();

    }



    /*******************************************************************************
     **	@notice Delete a user. This may only be called by the user.
     *******************************************************************************/
    function deleteUser() external override {
        bool _userToDeleteExists;
        for (uint i = 0; i < userList.length; ++i) {
            if (
                tx.origin == IUser(userList[i]).getWalletDetails().publicAddr
            ) {
                _userToDeleteExists = true;
                userList[i] = userList[userList.length - 1];
                userList.pop();
                delete userContract[tx.origin];
                YousovAccessControl(yousovAccessControl).revokeRole(YOUSOV_USER_ROLE, tx.origin);
                emit UserDeleted(tx.origin);
                break;
            }
        }
        if(!_userToDeleteExists){
            revert("YOUSOV : User don't exist");
        }
    }

    /*******************************************************************************
     **	@notice Check the unicity of the user. Returns true if the pii or pseudo already exists, return false instead.
     **	@param userAccountType The account type of the user (AccountType.REGULAR or AccountType.PSEUDO).
     **	@param userPII The pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     **	@param userPseudo The pseudo of the user.
     *******************************************************************************/
    function checkUnicity(
        AccountType userAccountTpe,
        PII memory userPII,
        string memory userPseudo
    ) external view override returns (bool exists, address userContractAddr) {
        for (uint i = 0; i < userList.length; ++i) {
            IUser _currentUser = IUser(userList[i]);

            if (userAccountTpe == AccountType.REGULAR) {
                if (
                    keccak256(
                        abi.encodePacked(
                            userPII.firstName,
                            userPII.middelName,
                            userPII.lastName,
                            userPII.cityOfBirth,
                            userPII.countryOfBirth,
                            userPII.countryOfCitizenship,
                            userPII.uid,
                            userPII.birthDateTimeStamp,
                            userPII.gender
                        )
                    ) ==
                    keccak256(
                        abi.encodePacked(
                            _currentUser.getPII().firstName,
                            _currentUser.getPII().middelName,
                            _currentUser.getPII().lastName,
                            _currentUser.getPII().cityOfBirth,
                            _currentUser.getPII().countryOfBirth,
                            _currentUser.getPII().countryOfCitizenship,
                            _currentUser.getPII().uid,
                            _currentUser.getPII().birthDateTimeStamp,
                            _currentUser.getPII().gender
                        )
                    )
                ) {
                    return (true, userList[i]);
                }
            }
            else if (userAccountTpe == AccountType.PSEUDO) {
                if (
                    keccak256(abi.encodePacked(userPseudo)) ==
                    keccak256(abi.encodePacked(_currentUser.pseudonym()))
                ) {
                    return (true, userList[i]);
                }
            }
        }
        return (false, address(0));
    }

    /*******************************************************************************
     **	@notice Get the user list.
     *******************************************************************************/
    function yousovUserList()
        external
        view
        override
        returns (address[] memory)
    {
        return userList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./YousovRoles.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
 
 contract YousovAccessControl is Context, IAccessControl, ERC165, YousovRoles {
    address userFactory;
    
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor (address _defaultAdmin, address _ezrMinter, address _ezrPauser) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(PAUSER_ROLE, _defaultAdmin);
        _setupRole(MANAGER_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _ezrMinter);
        _setupRole(PAUSER_ROLE, _ezrPauser);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function checkRole(bytes32 role, address sender) public view {
        _checkRoleAccount(role, sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRoleAccount(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,tx.origin) || msg.sender == userFactory );
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,tx.origin) || msg.sender == userFactory);
        _revokeRole(role, account);
    }
    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == tx.origin, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }


    function setAgentPayrolWalletAddressAsMinter(address _apwAddress) public {
        require(msg.sender == _apwAddress, "Yousov: Incorrect Address");
        _setupRole(MINTER_ROLE, _apwAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _apwAddress);
    }
    function setUserFactory(address newUserFactoryAddress)  public{
        require(msg.sender == newUserFactoryAddress, "Yousov: Incorrect Address");
        userFactory = newUserFactoryAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract YousovRoles {
    bytes32 public constant YOUSOV_USER_ROLE = keccak256("YOUSOV_USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant TEMPORARY_YOUSOV_USER_ROLE = keccak256("TEMPORARY_YOUSOV_USER_ROLE");
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
}