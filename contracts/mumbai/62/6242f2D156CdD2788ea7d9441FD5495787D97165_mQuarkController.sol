// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
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
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Collection} from "../lib/mQuarkStructs.sol";

interface ImQuarkProject  {
  // Packed parameters for Create Collection functions
  event NewCollection(address _instance, uint _id);
  
  struct CreateCollectionParams {
    uint256 templateId;
    // uint256 collectionId;
    uint256 collectionPrice;
    uint16 totalSupply;
  }


  function createCollection(
    Collection calldata createParams,
    bool isDynamicUri,
    uint8 ERCimplementation,
    // address collectionCreationSigner,
    // bytes[] calldata signatures,
    string[] calldata uris,
    bytes32 merkeRoot
  ) external returns (address instance);

  function getCollectionAddress(uint16 collectionId) external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import './interfaces/ImQuarkProjectDeployer.sol';

import './ImQuarkProject.sol';

interface ImQuarkProjectDeployer{
    
    struct Parameters {
        address registry;
        address owner;
        uint64 id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import './interfaces/ImQuarkProjectDeployer.sol';

import './ImQuarkProject.sol';

interface ImQuarkRegistry {

  event ProjectRegistered(
    address project,
    address contractAddress,
    uint256 projectId,
    string projectName,
    string description,
    string thumbnail,
    string projectDefaultSlotURI,
    uint256 slotPrice
  );
  struct Project {
    // The creator address of the project
    address creator;
    // The createed contract address of the project's creator
    address contractAddress;
    // The unique ID of the project
    uint256 id;
    // The balance of the project
    uint256 balance;
    // The name of the project
    string name;
    // The description of the project
    string description;
    // The thumbnail image of the project
    string thumbnail;
    // The default URI for the project's tokens
    string projectSlotDefaultURI;
  }




  function setController(address _controller) external;

  function setSubscriber(address _subscriber) external;
  

  /**
   * Projets are registered to the contract
   *
   * @param projectName            Project name
   * @param thumbnail              Thumbnail url
   * @param projectSlotDefaultURI  The uri that will be assigned to project slot initially
   * @param slotPrice              Slot price for the project
   */
  function registerProject(
    string calldata projectName,
    string calldata description,
    string calldata thumbnail,
    string calldata projectSlotDefaultURI,
    uint256 slotPrice // ) external onlyRole(AUTHORIZED_REGISTERER_ROLE) {
  ) external;

  // Getter function to retrieve the project id
  function getProjectId(address contractAddress) external view returns (uint256);

  function getProjectAddress(uint64 projectId) external view returns (address);

  /**
   * Returns registered project
   *
   * @return contractAddress         Contract address
   * @return creator                 Creator address
   * @return id                      ID
   * @return balance                 Balance
   * @return name                    Name
   * @return description             Description
   * @return thumbnail               Thumbnail
   * @return projectSlotDefaultURI   Slot default URI
   * */
  function getRegisteredProject(
    uint256 projectId
  )
    external
    view
    returns (
      address contractAddress,
      address creator,
      uint256 id,
      uint256 balance,
      string memory name,
      string memory description,
      string memory thumbnail,
      string memory projectSlotDefaultURI
    );


  }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

  
struct CreateCollectionParams {
  uint256 templateId;
  // uint256 collectionId;
  uint256 collectionPrice;
  uint16 totalSupply;
}

  struct Collection {
    // the id of the project that the collection belongs to. This id is assigned by the contract.
    uint64 projectId;
    // the id of the template that the collection inherits from.
    uint256 templateId;
    // the created collection's id for a template id
    uint16 collectionId;
    // the number of minted tokens from the collection
    uint256 mintCount;
    // the URIs of the collection (minted tokens inherit one of the URI)
    string[] collectionURIs;
    // the total supply of the collection
    uint16 totalSupply;
    //0: static / 1: limited / 2: dynamic  | free - 3: static / 4: limited / 5: dynamic
    uint8 mintType;

    uint256 mintPrice;

    uint8 mintPerAccountLimit; //0: unlimited, 1: 1, 2: 2, ..

    string name;

    string symbol;

    address verifier;

    bool isWhitelisted;

    bool isFree;
  }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./mQuarkNFT.sol";
import "./Registry.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./mQuarkTemplate.sol";
contract mQuarkController is AccessControl {
  // Emitted when the prices of templates are set
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);
  //("");
  // struct Collection {
  //   mQuarkNFT collectionAddress;
  //   // the id of the project that the collection belongs to. This id is assigned by the contract.
  //   uint256 projectId;
  //   // the id of the template that the collection inherits from.
  //   uint256 templateId;
  //   // the created collection's id for a template id
  //   uint256 collectionId;
  //   // the number of minted tokens from the collection
  //   uint256 mintCount;
  //   // the URIs of the collection (minted tokens inherit one of the URI)
  //   string[] collectionURIs;
  //   // the total supply of the collection
  //   uint16 totalSupply;
  //   //0: static / 1: limited / 2: dynamic  | free - 3: static / 4: limited / 5: dynamic
  //   uint8 mintType;
  //   uint256 mintPrice;
  //   uint8 mintPerAccountLimit; //0: unlimited, 1: 1, 2: 2, ..
  // }

  /**
   * Mapping from 'template id' to 'mint price' in wei
   */
  mapping(uint256 => uint256) private _templateMintPrices;

  mapping(uint256 => uint256) private _projectBalances;

  // mapping(address => address) private _mintVerifier;



  //stores already mint accounts / eoa => contract => mint count
  // mapping(address => mapping(address => uint256)) private _mintCountsPerAccount;

  // mapping(address => bytes32) private _merkleRoots;

  // mapping(uint8 => address) private _implementations;

  //only mQuarNFT owner modifier
  function _onlyNFTOwner(mQuarkNFT nftContractAddress) internal view {
    if (nftContractAddress.owner() == msg.sender) revert("Not NFT Owner");
  }

  /**
   * Mapping from "project id" , "template id" ,"collection id"  to "collection price"
   */
  // mapping(address => Collection) private _collections;

  /// @dev    Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  mapping(bytes => bool) private _inoperativeSignatures;

  /// @dev The address of the verifier, who signs collection URIs
  address public verifier;

  /// @dev This role will be used to check the validity of signatures
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  /// @dev This role grants access to register projects
  bytes32 public constant AUTHORIZED_REGISTERER_ROLE = keccak256("AUTHORIZED_REGISTERER");

  /// @dev This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @dev This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  //todo use interface
  Registry public registeryContract;
  mQuarkTemplate public s_template;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  // function setMerkleRoot(address collectionAddress, bytes32 merkleRoot) external {
  //   _onlyNFTOwner(mQuarkNFT(collectionAddress));
  //   Collection storage collection = _collections[collectionAddress];
  //   if (collection.mintType % 2 != 0) revert("InvalidMintType");
  //   _merkleRoots[collectionAddress] = merkleRoot;
  // }

  // function registerCollection(
  //   address collectionAddress,
  //   uint256 templateId,
  //   uint64 projectId,
  //   uint16 collectionId,
  //   uint256 collectionPrice,
  //   uint256 totalSupply,
  //   bytes[] calldata signatures,
  //   string[] calldata uris,
  //   uint8 mintPerWallet,
  //   bool isWhitelistEnabled,
  //   bool isDynamicUri
  // ) public {
  //   // register collection
  //   if (uris.length > 1 && isDynamicUri) revert("InvalidURIs();");
  //   if (_templateMintPrices[templateId] == 0) revert("InvalidTemplate(createParams.templateIds[i]);");
  //   if ((collectionPrice < _templateMintPrices[templateId]) && (collectionPrice != 0))
  //     revert("InvalidCollectionPrice();");
  //   if (!isDynamicUri) {
  //     for (uint256 i = 0; i < signatures.length; ) {
  //       bool isVerified = _verifySignature(
  //         signatures[i],
  //         verifier,
  //         projectId,
  //         templateId,
  //         collectionId,
  //         uris[i],
  //         "0x01"
  //       );
  //       if (!isVerified) revert("VerificationFailed();");
  //       _inoperativeSignatures[signatures[i]] = true;
  //       unchecked {
  //         ++i;
  //       }
  //     }
  //   }

  //   uint8 mintType;
  //   //paid
  //   if (collectionPrice > 0) {
  //     if (uris.length > 1) {
  //       mintType = isWhitelistEnabled ? 0 : 1;
  //       //0 => paid | limited variation | whitelist
  //       //1 => paid | limited variation | no whitelist
  //     } else {
  //       if (isDynamicUri) {
  //         mintType = isWhitelistEnabled ? 2 : 3;
  //         //0 => paid | dynamic variation | whitelist
  //         //1 => paid | dynamic variation | no whitelist
  //       } else {
  //         mintType = isWhitelistEnabled ? 4 : 5;
  //         //0 => paid | static variation | whitelist
  //         //1 => paid | static variation | no whitelist
  //       }
  //     }
  //   } else {
  //     if (uris.length > 1) {
  //       mintType = isWhitelistEnabled ? 6 : 7;
  //       //0 => free | limited variation | whitelist
  //       //1 => free | limited variation | no whitelist
  //     } else {
  //       if (isDynamicUri) {
  //         mintType = isWhitelistEnabled ? 8 : 9;
  //         //0 => free | dynamic variation | whitelist
  //         //1 => free | dynamic variation | no whitelist
  //       } else {
  //         mintType = isWhitelistEnabled ? 10 : 11;
  //         //0 => free | static variation | whitelist
  //         //1 => free | static variation | no whitelist
  //       }
  //     }
  //   }
  //   string[] memory _uris;
  //   _uris = isDynamicUri ? uris : new string[](1);

  //   _collections[collectionAddress] = Collection(
  //     mQuarkNFT(collectionAddress),
  //     projectId,
  //     templateId,
  //     collectionId,
  //     0,
  //     _uris,
  //     uint16(totalSupply),
  //     mintType,
  //     collectionPrice,
  //     mintPerWallet
  //   );
  // }

  // /**
  //  * Checks the validity of given parameters and whether paid ETH amount is valid
  //  * Makes a call to mQuark contract to mint single NFT.
  //  *
  //  * paramprojectId      Collection owner's project id
  //  * paramtemplateId     Collection's inherited template's id
  //  * paramcollectionId   Collection id for its template
  //  * paramvariationId    Variation id for the collection. (0 for the static typed collection)
  //  */
  // //static and limited mint - payable - no whitelist -
  // //unlimited mint(this one is optional can be put as a check in functions, for now let's create another function for limited mints for now)
  // //1-9
  // // function mint(uint256 projectId, uint256 templateId, uint256 collectionId, uint256 variationId) external payable {
  // function mint(address contractAddress, uint256 variationId) external payable {
  //   Collection memory _tempData = _collections[contractAddress];
  //   if (
  //     _tempData.mintPerAccountLimit > 0 &&
  //     _mintCountsPerAccount[msg.sender][contractAddress] <= _tempData.mintPerAccountLimit
  //   ) revert("MintLimitReached();");
  //   if (_tempData.mintType != 1 && _tempData.mintType != 5 && _tempData.mintType != 7 && _tempData.mintType != 11)
  //     revert("WrongMintType();");
  //   //paid
  //   if (_tempData.mintType < 6) {
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     // if (_tempData.mintType != 5 || _tempData.mintType != 7) revert("WrongMintType();");
  //     if (msg.value == 0) revert("SentAmountIsZero();");
  //     if (msg.value != _tempData.mintPrice) revert("InvalidSentAmount();");
  //     if (_tempData.collectionURIs.length <= variationId) revert("InvalidVariation();");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _tempData.collectionAddress.mint(msg.sender, _tempData.collectionURIs[variationId]);
  //     _collections[contractAddress].mintCount++;
  //     _projectBalances[_tempData.projectId] += msg.value;
  //   }
  //   //free
  //   else {
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     // if (_tempData.mintType != 5 || _tempData.mintType != 7) revert("WrongMintType();");
  //     if (msg.value != 0) revert("NoPaymentRequired;");
  //     // if (msg.value != _tempData.mintPrice) revert("InvalidSentAmount();");
  //     if (_tempData.collectionURIs.length <= variationId) revert("InvalidVariation();");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _tempData.collectionAddress.mint(msg.sender, _tempData.collectionURIs[variationId]);
  //     _collections[contractAddress].mintCount++;
  //     // _projectBalances[_tempData.projectId] += msg.value;
  //   }
  //   ++_mintCountsPerAccount[msg.sender][contractAddress];
  //   // adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;
  //   // emit FundsDeposit(msg.value, projectPercentage, projectId);
  // }

  // /**
  //  * Checks the validity of given parameters and whether paid ETH amount is valid
  //  * Makes a call to mQuark contract to mint single NFT with given validated URI.
  //  *
  //  * @param signer       Registered project address of the given collection
  //  * @param signature    Signed data by project's wallet
  //  * @param uri          The metadata URI that will represent the template.
  //  */
  // //payable - dynamic variation - unlimited - no whitelist
  // function mintWithURI(
  //   address contractAddress,
  //   address signer,
  //   bytes calldata signature,
  //   string calldata uri,
  //   bytes calldata salt
  // ) external payable {
  //   Collection memory _tempData = _collections[contractAddress];
  //   if (
  //     _tempData.mintPerAccountLimit > 0 &&
  //     _mintCountsPerAccount[msg.sender][contractAddress] <= _tempData.mintPerAccountLimit
  //   ) revert("MintLimitReached();");
  //   if (_tempData.mintType != 3 && _tempData.mintType != 9) revert("WrongMintType();");
  //   //paid
  //   if (_tempData.mintType < 6) {
  //     if (msg.value == 0) revert("SentAmountIsZero();");
  //     if (msg.value != _tempData.mintPrice) revert("InvalidSentAmount();");
  //     if (_mintVerifier[address(_tempData.collectionAddress)] != signer) revert("ProjectIdAndSignerMismatch();");
  //     if (
  //       !_verifySignature(
  //         signature,
  //         signer,
  //         _tempData.projectId,
  //         _tempData.templateId,
  //         _tempData.collectionId,
  //         uri,
  //         salt
  //       )
  //     ) revert("VerificationFailed();");
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");

  //     _inoperativeSignatures[signature] = true;
  //     _tempData.collectionAddress.mint(msg.sender, uri);
  //     _collections[contractAddress].mintCount++;
  //     _projectBalances[_tempData.projectId] += msg.value;
  //   }
  //   //free
  //   else {
  //     if (msg.value != 0) revert("NoPaymentRequired;");
  //     if (
  //       !_verifySignature(
  //         signature,
  //         signer,
  //         _tempData.projectId,
  //         _tempData.templateId,
  //         _tempData.collectionId,
  //         uri,
  //         salt
  //       )
  //     ) revert("VerificationFailed();");
  //     if (_mintVerifier[address(_tempData.collectionAddress)] != signer) revert("ProjectIdAndSignerMismatch();");
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _inoperativeSignatures[signature] = true;
  //     _tempData.collectionAddress.mint(msg.sender, uri);
  //     _collections[contractAddress].mintCount++;
  //   }
  //   ++_mintCountsPerAccount[msg.sender][contractAddress];
  //   // adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;
  //   // emit FundsDeposit(msg.value, projectPercentage, projectId);
  // }

  // function mintWhitelist(bytes32[] memory merkleProof, address contractAddress, uint256 variationId) external payable {
  //   Collection memory _tempData = _collections[contractAddress];
  //   if (
  //     _tempData.mintPerAccountLimit > 0 &&
  //     _mintCountsPerAccount[msg.sender][contractAddress] <= _tempData.mintPerAccountLimit
  //   ) revert("MintLimitReached();");
  //   if (_tempData.mintType != 1 && _tempData.mintType != 5 && _tempData.mintType != 7 && _tempData.mintType != 11)
  //     revert("WrongMintType();");
  //   bytes32 node = keccak256(abi.encodePacked(msg.sender));
  //   require(MerkleProof.verify(merkleProof, _merkleRoots[contractAddress], node), "Not whitelisted");

  //   //paid
  //   if (_tempData.mintType < 6) {
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     if (msg.value == 0) revert("SentAmountIsZero();");
  //     if (msg.value != _tempData.mintPrice) revert("InvalidSentAmount();");
  //     if (_tempData.collectionURIs.length <= variationId) revert("InvalidVariation();");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _tempData.collectionAddress.mint(msg.sender, _tempData.collectionURIs[variationId]);
  //     _collections[contractAddress].mintCount++;
  //     _projectBalances[_tempData.projectId] += msg.value;
  //   }
  //   //free
  //   else {
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     if (msg.value != 0) revert("NoPaymentRequired;");
  //     if (_tempData.collectionURIs.length <= variationId) revert("InvalidVariation();");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _tempData.collectionAddress.mint(msg.sender, _tempData.collectionURIs[variationId]);
  //     _collections[contractAddress].mintCount++;
  //   }
  //   ++_mintCountsPerAccount[msg.sender][contractAddress];
  //   // adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;
  //   // emit FundsDeposit(msg.value, projectPercentage, projectId);
  // }

  // /**
  //  * Checks the validity of given parameters and whether paid ETH amount is valid
  //  * Makes a call to mQuark contract to mint single NFT with given validated URI.
  //  *
  //  * @param signer       Registered project address of the given collection
  //  * @param signature    Signed data by project's wallet
  //  * @param uri          The metadata URI that will represent the template.
  //  */
  // //payable - dynamic variation - unlimited - no whitelist
  // function mintWithURIWhitelist(
  //   bytes32[] memory merkleProof,
  //   address contractAddress,
  //   address signer,
  //   bytes calldata signature,
  //   string calldata uri,
  //   bytes calldata salt
  // ) external payable {
  //   Collection memory _tempData = _collections[contractAddress];
  //   if (
  //     _tempData.mintPerAccountLimit > 0 &&
  //     _mintCountsPerAccount[msg.sender][contractAddress] <= _tempData.mintPerAccountLimit
  //   ) revert("MintLimitReached();");
  //   if (_tempData.mintType != 2 && _tempData.mintType != 8) revert("WrongMintType();");
  //   bytes32 node = keccak256(abi.encodePacked(msg.sender));
  //   require(MerkleProof.verify(merkleProof, _merkleRoots[contractAddress], node), "Not whitelisted");
  //   //paid
  //   if (_tempData.mintType < 6) {
  //     if (msg.value == 0) revert("SentAmountIsZero();");
  //     if (msg.value != _tempData.mintPrice) revert("InvalidSentAmount();");
  //     if (_mintVerifier[address(_tempData.collectionAddress)] != signer) revert("ProjectIdAndSignerMismatch();");
  //     if (
  //       !_verifySignature(
  //         signature,
  //         signer,
  //         _tempData.projectId,
  //         _tempData.templateId,
  //         _tempData.collectionId,
  //         uri,
  //         salt
  //       )
  //     ) revert("VerificationFailed();");
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _inoperativeSignatures[signature] = true;
  //     _tempData.collectionAddress.mint(msg.sender, uri);
  //     _collections[contractAddress].mintCount++;
  //     _projectBalances[_tempData.projectId] += msg.value;
  //   }
  //   //free
  //   else {
  //     if (msg.value != 0) revert("NoPaymentRequired;");
  //     if (
  //       !_verifySignature(
  //         signature,
  //         signer,
  //         _tempData.projectId,
  //         _tempData.templateId,
  //         _tempData.collectionId,
  //         uri,
  //         salt
  //       )
  //     ) revert("VerificationFailed();");
  //     if (_mintVerifier[address(_tempData.collectionAddress)] != signer) revert("ProjectIdAndSignerMismatch();");
  //     if (address(_tempData.collectionAddress) == address(0)) revert("WrongParameters");
  //     if (_tempData.totalSupply <= _tempData.mintCount) revert("CollectionIsSoldOut();");
  //     _inoperativeSignatures[signature] = true;
  //     _tempData.collectionAddress.mint(msg.sender, uri);
  //     _collections[contractAddress].mintCount++;
  //   }
  //   ++_mintCountsPerAccount[msg.sender][contractAddress];
  //   // adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;
  //   // emit FundsDeposit(msg.value, projectPercentage, projectId);
  // }

  /**
   * Sets Templates mint prices(wei)
   *
   * @notice Collections inherit the template's mint price
   *
   * @param templateIds_  IDs of Templates which are categorized NFTs
   * @param prices        Prices of each given templates in wei unit
   * */
  function setTemplatePrices(
    uint256[] calldata templateIds_,
    uint256[] calldata prices // onlyRole(CONTROL_ROLE)
  ) external {
    if (templateIds_.length != prices.length) revert("ArrayLengthMismatch();");
    uint256 _templateIdsLength = templateIds_.length;
    for (uint256 i = 0; i < _templateIdsLength; ) {
      if(!s_template.isTemplateIdExist(templateIds_[i])) revert("TemplateIdNotExist");
      _templateMintPrices[templateIds_[i]] = prices[i];
      unchecked {
        ++i;
      }
    }
    emit TemplatePricesSet(templateIds_, prices);
  }

  /**
   * Sets given address as verifier, this address is sent to mQuark contract to verify signatures
   */
  // function setVerifierAddress(address addr) external onlyRole(CONTROL_ROLE) {
  //   verifier = addr;
  //   // emit VerifierAddressSet(addr);
  // }
  
  function setTemplateContractAddress(mQuarkTemplate template) external onlyRole(CONTROL_ROLE) {
    s_template = template;
  }

  // function verifyCreateCollection(address signer) external view returns (bool) {
  //   return signer == verifier ? true : false;
  // }

  // function setCollectionMintConfiguration(address uriVerifier, mQuarkNFT contractAddress) external {
  //   if (msg.sender != contractAddress.owner()) revert("NotAuthorized();");
  //   uint256 _id = registeryContract.getProjectId(address(contractAddress));
  //   if (_id == 0) revert("ProjectIdIsZero();");
  //   _mintVerifier[address(contractAddress)] = uriVerifier;
  // }

  // function setImplementation(uint8 id, address implementation)  external onlyRole(DEFAULT_ADMIN_ROLE){
  //   _implementations[id] = implementation;
  // }

  function setRegisteryContract(Registry _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    registeryContract = _addr;
  }

  //get template mint price
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256) {
    return _templateMintPrices[templateId];
  }

  function getImplementaion(uint8 implementation) external view returns (address) {
    return registeryContract.getImplementaion(implementation);
  }

  /**
   * @notice This function checks the validity of a given signature by verifying that it is signed by the given signer.
   *
   * @param signature    The signature to verify
   * @param projectId    The ID of the project associated with the signature
   * @param templateId   The ID of the template associated with the signature
   * @param collectionId The ID of the collection associated with the signature
   * @param uri          The URI associated with the signature
   * @param salt         The salt value
   * @return             "true" if the signature is valid
   */
  // function _verifySignature(
  //   bytes memory signature,
  //   address verifier_,
  //   uint256 projectId,
  //   uint256 templateId,
  //   uint256 collectionId,
  //   string memory uri,
  //   bytes memory salt
  // ) internal view returns (bool) {
  //   if (_inoperativeSignatures[signature]) revert("UsedSignature()");
  //   bytes32 _messageHash = keccak256(abi.encode(verifier_, projectId, templateId, collectionId, uri, salt));
  //   address _signer = _getHashSigner(_messageHash, signature);
  //   return (_signer == verifier);
  // }

  // /**
  //  * @return _signer the singer of the given signature
  //  */
  // function _getHashSigner(bytes32 _hash, bytes memory signature) internal pure returns (address _signer) {
  //   bytes32 _signed = ECDSA.toEthSignedMessageHash(_hash);
  //   _signer = ECDSA.recover(_signed, signature);
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./SolmateNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract mQuarkNFT is ERC721, Ownable {
  /// @dev  Mapping from a 'token id' to TokenInfo struct.
  mapping(uint256 => string) private _tokenUris;

  /// @dev  Mapping from a 'token id' and 'project id' to a 'project slot URI'
  mapping(uint256 => mapping(uint256 => TokenSubscriptionInfo)) private _tokenSubscriptions;//formerly _tokenProjectURIs

  struct TokenSubscriptionInfo {
    // status of the upgradibilty
    bool isSubscribed;
    // the project token uri
    string uri;
  }

  uint16 immutable ID;
  bool immutable public freeMintCollection;
  uint128 public currentTokenId;
  address private _royaltyReceiver;
  uint16 private _royaltyPercentage;
  address immutable private _controller;

  constructor(bool freeMint, uint16 _id, address controller) ERC721("",""){
    freeMintCollection = freeMint;
    ID = _id;
    _controller = controller;
  }


   /**
   * @notice Performs a single NFT mint without any slots.(Static and Limited Dynamic).
   *
   */
  function mint(
    address to,
    string calldata uri
  ) external returns (uint128) {
    _onlymQuarkControl();
    uint128 _tokenId = currentTokenId++;
    _mint(to, _tokenId);
    _tokenUris[_tokenId] = uri;
    return _tokenId;
  }

     /**
   * @notice Performs a batch mint operation. (Static and Limited Dynamic).
   *
   */
  function mintBatch(
    address to,
    string calldata uri,
    uint256 amount
  ) external {
    _onlymQuarkControl();
    uint256 _tokenId;
    uint128 _currentTokenId = currentTokenId;
    for(uint256 i = 0; i < amount; i++){
      _tokenId = _currentTokenId++;
      _mint(to, currentTokenId);
      _tokenUris[_tokenId] = uri;
    }
    currentTokenId = _currentTokenId;
  }

  //we may remove this function because it may be used very rarely
  //  function mintBatchWithURISlot(


    /**
   *
   * Adds a single URI slot to a single non-fungible token (NFT).
   * Initializes the added slot with the given project's default URI.
   *
   * @notice Reverts if the number of given projects is more than 256.
   *         The added slot's initial state will be pre-filled with the project's default URI.
   *
   * @param tokenId                The ID of the token to which the slot will be added.
   * @param projectId              The ID of the slot's project.
   * @param projectSlotDefaultUri The project's default URI that will be set to the added slot.
   */
  //a new name suggestion: subscribeToProject
  function addURISlotToNFT(
    address owner,
    uint256 tokenId,
    uint64 projectId,
    //todo make this variable dynamic on the subscriber contract, project owner should be able to set default URI for their contracts?
    string calldata projectSlotDefaultUri
  ) public {
    if(ownerOf(tokenId) != owner) revert ("Not owner");
    _tokenSubscriptions[tokenId][projectId] = TokenSubscriptionInfo(true , projectSlotDefaultUri);
  }

    /**
   * Adds multiple URI slots to a single token in a batch operation.
   *
   * @notice Reverts if the number of projects is more than 256.
   *          Slots' initial state will be pre-filled with the given default URI values.
   *
   * @param tokenId                The ID of the token to which the slots will be added.
   * @param projectIds             An array of IDs for the slots that will be added.
   * @param projectSlotDefaultUris An array of default URI values for the added
   */
  function addBatchURISlotsToNFT(
    address owner,
    uint256 tokenId,
    uint64[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) public {
    if(ownerOf(tokenId) != owner) revert ("Not owner");
    uint256 projectCount = projectIds.length;
    for (uint256 i = 0; i < projectCount; ) {
       _tokenSubscriptions[tokenId][projectIds[i]] = TokenSubscriptionInfo(true , projectSlotDefaultUris[i]);
      unchecked {
        ++i;
      }
    }
  }

    /**
   * Updates the URI slot of a single token.
   *
   * @notice The project must sign the new URI with its wallet address.
   *
   * @param owner          The address of the owner of the token.
   * @param projectId      The ID of the project.
   * @param tokenId        The ID of the token.
   * @param updatedUri     The updated, signed URI value.
   */
  function updateURISlot(
    address owner,
    uint256 projectId,
    uint256 tokenId,
    string calldata updatedUri
  ) external {
    // _onlymQuarkControl();
    if (ownerOf(tokenId) != owner) revert ("Not owner");
    if ((_tokenSubscriptions[tokenId][projectId].isSubscribed)) revert ("Unsubscribed");
    _tokenSubscriptions[tokenId][projectId].uri = updatedUri;
  }

  // function exchangeURISlot(
  //   address owner,
  //   uint256 projectId,
  //   uint256 tokenId,
  //   string calldata updatedUri
  // ) external {
  //   // _onlymQuarkControl();
  //   if (ownerOf(tokenId) != owner) revert ("Not owner");
  //   if ((_tokenSubscriptions[tokenId][projectId].isSubscribed)) revert ("Unsubscribed");
  //   _tokenSubscriptions[tokenId][projectId].uri = updatedUri;
  // }



  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return _tokenUris[id];
  }

    /**
   * Every project will be able to place a slot to tokens if owners want
   * These slots will store the uri that refers 'something' on the project
   * Slots are viewable by other projects but modifiable only by the owner of
   * the token who has a valid signature by the project
   *
   * @notice Returns the project URI for the given token ID
   *
   * @param tokenId        The ID of the token whose project URI is to be returned
   * @param projectId      The ID of the project associated with the given token
   *
   * @return           The URI of the given token's project slot
   */
  function tokenProjectURI(
    uint256 tokenId,
    uint256 projectId
  ) external view returns (string memory) {
    return _tokenSubscriptions[tokenId][projectId].uri;
  }

  /**
   * @return receiver        The royalty receiver address
   * @return royaltyAmount   The percentage of royalty
   */
  function royaltyInfo(
    uint256 , /*_tokenId*/
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    royaltyAmount = (_royaltyPercentage * _salePrice) / 1000;
    receiver = _royaltyReceiver;
  }

  function setRoyaltyInfo(uint16 royaltyPercentage, address receiver) external onlyOwner {
    _royaltyPercentage = royaltyPercentage;
    _royaltyReceiver = receiver;
  }

  /**
   * @notice This function checks if the caller of the function is the mQuark Control contract.
   * @dev This function should be called at the beginning of functions that are only allowed to be called by the mQuark Control contract.
   *    */
  function _onlymQuarkControl() internal view {
    if (msg.sender != _controller) revert ("CallerNotAuthorized();");
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/ImQuarkRegistry.sol";
import "./interfaces/ImQuarkProjectDeployer.sol";
import "./interfaces/ImQuarkProject.sol";
import {mQuarkNFT} from "./mQuarkNFT.sol";
import {mQuarkController} from "./mQuarkController.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Subscriber.sol";
import {Collection} from "./lib/mQuarkStructs.sol";

contract mQuarkProject is ImQuarkProject, Ownable {
  /// @dev    Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  // mapping(bytes => bool) private _inoperativeSignatures;

  Registry public immutable s_registry;

  address public immutable s_owner;

  uint64 public immutable s_ID;

  mQuarkController public s_controllerAddress;
  uint16 public s_lastCollectionId;

  address[] public s_allCollections;
  mapping(uint256 => address) private s_createdCollectionAddresses;

  //todo use interfaces
  mQuarkSubscriber public immutable s_subscriber;

  // address public immutable s_ERC721Implementation;

  constructor(address registryAddress, address subscriber, address owner, uint64 id) {
    s_subscriber = mQuarkSubscriber(subscriber);
    (s_registry, s_owner, s_ID) = (Registry(registryAddress), owner, id);
    transferOwnership(s_owner);
  }

  function createCollection(
    Collection memory createParams,
    bool isDynamicUri,
    uint8 ERCimplementation,
    // address collectionCreationSigner,
    // bytes[] calldata signatures,
    string[] calldata uris,
    bytes32 merkelRoot
  ) public returns (address instance) {
    uint256 limitMintPrice = s_controllerAddress.getTemplateMintPrice(createParams.templateId);
    // if (signatures.length != uris.length) revert("ArrayLengthMismatch");
    if (uris.length > 1 && isDynamicUri) revert("InvalidURIs();");
    if (limitMintPrice == 0) revert("InvalidTemplate(createParams.templateIds[i]);");
    if ((createParams.mintPrice < limitMintPrice) && (createParams.mintPrice != 0)) revert("InvalidCollectionPrice();");
    // if (!isDynamicUri) {
    //   for (uint256 i = 0; i < signatures.length; ) {
    //     bool isVerified = _verifySignature(
    //       signatures[i],
    //       collectionCreationSigner,
    //       createParams.projectId,
    //       createParams.templateId,
    //       createParams.collectionId,
    //       uris[i],
    //       "0x01"
    //     );
    //     if (!isVerified) revert("VerificationFailed();");
    //     _inoperativeSignatures[signatures[i]] = true;
    //     unchecked {
    //       ++i;
    //     }
    //   }
    // }
    uint8 mintType;
    //paid
    if (createParams.mintPrice > 0) {
      if (uris.length > 1) {
        mintType = createParams.isWhitelisted ? 0 : 1;
        //0 => paid | limited variation | whitelist
        //1 => paid | limited variation | no whitelist
      } else {
        if (isDynamicUri) {
          mintType = createParams.isWhitelisted ? 2 : 3;
          //2 => paid | dynamic variation | whitelist
          //3 => paid | dynamic variation | no whitelist
        } else {
          mintType = createParams.isWhitelisted ? 4 : 5;
          //4 => paid | static variation | whitelist
          //5 => paid | static variation | no whitelist
        }
      }
    } else {
      if (uris.length > 1) {
        mintType = createParams.isWhitelisted ? 6 : 7;
        //6 => free | limited variation | whitelist
        //7 => free | limited variation | no whitelist
      } else {
        if (isDynamicUri) {
          mintType = createParams.isWhitelisted ? 8 : 9;
          //8 => free | dynamic variation | whitelist
          //9 => free | dynamic variation | no whitelist
        } else {
          mintType = createParams.isWhitelisted ? 10 : 11;
          //10 => free | static variation | whitelist
          //11 => free | static variation | no whitelist
        }
      }
    }
    string[] memory _uris;
    bool free = createParams.mintPrice == 0 ? true : false;

    _uris = isDynamicUri ? new string[](1) : createParams.collectionURIs;
    createParams.collectionId = ++s_lastCollectionId;

    instance = Clones.clone(s_registry.getImplementaion(ERCimplementation));

    /// @dev: changing the initizing values based on Yasir's updates.
    (bool success, ) = instance.call(
      abi.encodeWithSignature("initilasiable(Collection,address,bytes32)", createParams, msg.sender,merkelRoot)
    );

    s_allCollections.push(instance);
    s_createdCollectionAddresses[createParams.collectionId] = instance;
    emit NewCollection(instance, createParams.collectionId);

    /// @dev should we not update the s_lastCollectionId after this?
    /// @dev we already update it everytime ++s_lastCollectionId.

    s_subscriber.setCollection(
      free,
      createParams.projectId,
      createParams.templateId,
      createParams.collectionId,
      instance
    );

    // mQuarkNFT nft = new mQuarkNFT(free, _collectionId, address(controller));
    // controller.registerCollection(
    //   address(nft),
    //   createParams.templateId,
    //   s_ID,
    //   _collectionId,
    //   createParams.mintPrice,
    //   createParams.totalSupply,
    //   signatures,
    //   uris,
    //   mintPerWallet,
    //   isWhitelistEnabled,
    //   isDynamicUri
    // );
  }

  function getCollectionAddress(uint16 collectionId) external view returns (address) {
    return s_createdCollectionAddresses[collectionId];
  }

  // function _verifySignature(
  //   bytes memory signature,
  //   address signer,
  //   uint256 projectId,
  //   uint256 templateId,
  //   uint256 collectionId,
  //   string memory uri,
  //   bytes memory salt
  // ) internal view returns (bool) {
  //   if (_inoperativeSignatures[signature]) revert("UsedSignature()");
  //   bytes32 _messageHash = keccak256(abi.encode(signer, projectId, templateId, collectionId, uri, salt));
  //   address _signer = _getHashSigner(_messageHash, signature);
  //   bool verificationStatus = s_controllerAddress.verifyCreateCollection(_signer);
  //   return verificationStatus;
  // }

  // /**
  //  * @return _signer the singer of the given signature
  //  */
  // function _getHashSigner(bytes32 _hash, bytes memory signature) internal pure returns (address _signer) {
  //   bytes32 _signed = ECDSA.toEthSignedMessageHash(_hash);
  //   _signer = ECDSA.recover(_signed, signature);
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import './interfaces/ImQuarkProjectDeployer.sol';

import "./mQuarkProject.sol";

contract mQuarkProjectDeployer is ImQuarkProjectDeployer {
  // struct Parameters {
  //     address registry;
  //     address owner;
  //     uint64 id;
  // }

  Parameters public parameters;

  /**
   * @dev This function deploys a project using the provided parameters. It does so by temporarily setting the
   *      parameters storage slot and then clearing it once the project has been deployed.
   *
   * @param registry       The controller address of the mQuark protocol
   * @param owner                   The EOA address that is creating the project
   * @param id                      The uint value of the project ID
   */
  function deploy(
    address registry,
    address subscriberAdress,
    address owner,
    uint64 id
  ) internal returns (address project) {
    parameters = Parameters({registry: registry, owner: owner, id: id});
    project = address(new mQuarkProject(registry, subscriberAdress, owner, id));
    delete parameters;
    //  parameters = Parameters({registry: registry, owner: owner, id: id});
    //     project = address(new mQuarkProject{salt: keccak256(abi.encode(registry, owner, id))}());
    //     delete parameters;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract mQuarkTemplate is AccessControl {
  using EnumerableSet for EnumerableSet.UintSet;

  /// @dev Stores the ids of created templates
  EnumerableSet.UintSet private templateIds;

  /// @dev Keeps track of the last created template id
  uint256 public templateIdCounter;

  /// @dev This role will be used to check the validity of signatures
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  /// @dev This role grants access to register projects
  bytes32 public constant AUTHORIZED_REGISTERER_ROLE = keccak256("AUTHORIZED_REGISTERER");

  /// @dev This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @dev This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  /**
   *  Mapping from a 'template id' to a 'template URI'
   */
  mapping(uint256 => string) private _templateURIs;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
  }

  /**
   *  @notice Creates a new template with the given URI, which will be inherited by collections.
   *
   * @param uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata uri) external onlyRole(CONTROL_ROLE) {
    uint256 _templateId = ++templateIdCounter;

    _templateURIs[_templateId] = uri;

    templateIds.add(_templateId);

    // emit TemplateCreated(_templateId, uri);
  }

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   *
   * @param uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata uris) external onlyRole(CONTROL_ROLE) {
    uint256 _urisLength = uris.length;
    if (_urisLength > 255) revert("ExceedsLimit();");
    uint256 _templateId = templateIdCounter;
    for (uint8 i = 0; i < _urisLength; ) {
      ++_templateId;
      _templateURIs[_templateId] = uris[i];
      templateIds.add(_templateId);
      // emit TemplateCreated(_templateId, uris[i]);
      unchecked {
        ++i;
      }
    }
    templateIdCounter = _templateId;
  }

  /**
   * Templates defines what a token is. Every template id has its own properties and attributes.
   * Collections are created by templates. Inherits the properties and attributes of the template.
   *
   * @param templateId  Template ID
   * @return            Template's URI
   * */
  function templateUri(uint256 templateId) external view returns (string memory) {
    return _templateURIs[templateId];
  }

  /**
   * @notice This function returns the total number of templates that have been created.
   *
   * @return The total number of templates that have been created
   */
  function getLastTemplateId() external view returns (uint256) {
    return templateIds.length();
  }

  function isTemplateIdExist(uint256 templateId) external view returns(bool exist){
    exist = templateIds.contains(templateId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./mQuarkProjectDeployer.sol";
import "./mQuarkController.sol";
import {mQuarkProject} from "./mQuarkProject.sol";
import "./Subscriber.sol";

/**
 * @title Canonical mQuark Registry
 * @notice Deploys mQuark projects, manages project ownerships, protocol fees and their collection's EIP1167 master-copy implementations
 */
contract Registry is AccessControl, mQuarkProjectDeployer {
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using EnumerableSet for EnumerableSet.AddressSet;
  event ProjectRegistered(
    address project,
    address contractAddress,
    uint256 projectId,
    string projectName,
    string description,
    string thumbnail,
    string projectDefaultSlotURI,
    uint256 slotPrice
  );
  struct Project {
    // The creator address of the project
    address creator;
    // The createed contract address of the project's creator
    address contractAddress;
    // The unique ID of the project
    uint256 id;
    // The balance of the project
    uint256 balance;
    // The name of the project
    string name;
    // The description of the project
    string description;
    // The thumbnail image of the project
    string thumbnail;
    // The default URI for the project's tokens
    string projectSlotDefaultURI;
  }
  /// @dev The contract addresses of projects registered
  EnumerableSet.AddressSet private projectContracts;
  /**
   * Mapping from 'project id' to 'project struct'
   */
  mapping(uint256 => Project) private _registeredProjects;
  /**
   * Mapping from project address to 'project id'
   */
  mapping(address => uint256) private _projectIds;

    mapping(uint8 => address) private s_implementations;

  /// @dev The last registered project ID
  uint64 public lastProjectId;

  //todo use interfaces
  mQuarkController public controller;
  mQuarkSubscriber public subscriber;

  /**
   * Mapping from 'project id' to 'project uri slot price' in wei
   */
  mapping(uint256 => uint256) private _projectSlotPrices;

  address private immutable original;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    original = address(this);
  }

  function testNoDelegateCall() private view {
    require(address(this) == original);
  }

  /**
   * Prevents delegatecall into the modified method
   */
  modifier noDelegateCall() {
    testNoDelegateCall();
    _;
  }

  function setController(address _controller) external onlyRole(DEFAULT_ADMIN_ROLE) {
    controller = mQuarkController(_controller);
  }

  function setSubscriber(address _subscriber) external onlyRole(DEFAULT_ADMIN_ROLE) {
    subscriber = mQuarkSubscriber(_subscriber);
  }

  /**
   * Projets are registered to the contract
   *
   * @param projectName            Project name
   * @param thumbnail              Thumbnail url
   * @param projectSlotDefaultURI  The uri that will be assigned to project slot initially
   * @param slotPrice              Slot price for the project
   */
  function registerProject(
    string calldata projectName,
    string calldata description,
    string calldata thumbnail,
    string calldata projectSlotDefaultURI,
    uint256 slotPrice
  ) external noDelegateCall {
    // if (projectWallets.contains(project)) revert ProjectAlreadyRegistered(project);
    // if (projectContracts.contains(project)) revert("Project Already Registered");
    uint64 _projectId = lastProjectId++;
    address creator = msg.sender;

    address _project = deploy(address(this), address(subscriber), creator, _projectId);

    address contractAddress = address(_project);

    _registeredProjects[_projectId] = Project(
      creator,
      contractAddress,
      _projectId,
      _registeredProjects[_projectId].balance,
      projectName,
      description,
      thumbnail,
      projectSlotDefaultURI
    );
    // projectContracts.add(address(_project));

    _projectIds[contractAddress] = _projectId;
    _projectSlotPrices[_projectId] = slotPrice;
    subscriber.initializeProject(contractAddress, _projectId, msg.sender, projectSlotDefaultURI, slotPrice);

    emit ProjectRegistered(
      creator,
      contractAddress,
      _projectId,
      projectName,
      description,
      thumbnail,
      projectSlotDefaultURI,
      slotPrice
    );
  }

  // Getter function to retrieve the project id
  function getProjectId(address contractAddress) public view returns (uint256) {
    return _projectIds[contractAddress];
  }

  function getProjectAddress(uint64 projectId) public view returns (address) {
    return _registeredProjects[projectId].contractAddress;
  }

  function getImplementaion(uint8 implementation) external view returns (address) {
    return s_implementations[implementation];
  }


  /**
   * Returns registered project
   *
   * @return contractAddress         Contract address
   * @return creator                 Creator address
   * @return id                      ID
   * @return balance                 Balance
   * @return name                    Name
   * @return description             Description
   * @return thumbnail               Thumbnail
   * @return projectSlotDefaultURI   Slot default URI
   * */
  function getRegisteredProject(
    uint256 projectId
  )
    external
    view
    returns (
      address contractAddress,
      address creator,
      uint256 id,
      uint256 balance,
      string memory name,
      string memory description,
      string memory thumbnail,
      string memory projectSlotDefaultURI
    )
  {
    return (
      _registeredProjects[projectId].contractAddress,
      _registeredProjects[projectId].creator,
      _registeredProjects[projectId].id,
      _registeredProjects[projectId].balance,
      _registeredProjects[projectId].name,
      _registeredProjects[projectId].description,
      _registeredProjects[projectId].thumbnail,
      _registeredProjects[projectId].projectSlotDefaultURI
    );
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // unchecked {
        //     _balanceOf[from]--;

        //     _balanceOf[to]++;
        // }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        // unchecked {
        //     _balanceOf[to]++;
        // }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        // unchecked {
        //     _balanceOf[owner]--;
        // }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Registry} from "./Registry.sol";
import "./mQuarkNFT.sol";
import "./mQuarkController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {mQuarkProject} from "./mQuarkProject.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract mQuarkSubscriber is AccessControl {
  struct Collection {
    uint64 projectId;
    uint256 templateId;
    uint16 collectionId;
    bool free;
    address contractAddress;
    mapping(uint256 => bool) unlocked;
  }

  struct ProjectConfig {
    uint64 projectId;
    uint256 subscriptionPrice;
    string defaultURI;
    bool uriSet;
    address signer;
    mapping(address => mapping(uint256 => bool)) subscribed;
  }

  /// @dev    Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  mapping(bytes => bool) private _inoperativeSignatures;

  mapping(address => Collection) private collections;

  mapping(address => bool) public authorizedContracts;
  //mapping admin balance
  mapping(address => uint256) public adminBalance;
  //mapping project balance
  mapping(uint64 => uint256) public projectBalance;
  //project default uri
  mapping(uint64 => ProjectConfig) public projectConfig;

  //create a modifer that checks if the contract is authorized
  modifier onlyAuthorizedContract() {
    require(authorizedContracts[msg.sender], "Not Authorized");
    _;
  }

  //create a modifer that checks if the caller is registry
  modifier onlyRegistery() {
    require(msg.sender == address(registry), "Not Registry");
    _;
  }
   modifier onlyProjectOwner(uint64 projectId) {
    _onlyProjectOwner(projectId);
    _;
  }

  //create a modifier that checks if the caller is owner of the registry
  function _onlyProjectOwner(uint64 projectId) internal view {
    address projectContractAddress = registry.getProjectAddress(projectId);
    if (mQuarkProject(projectContractAddress).owner() != msg.sender) revert("Not Registry Owner");
  }

  //only mQuarNFT owner modifier
  function _onlyNFTOwner(mQuarkNFT nftContractAddress) internal view {
    if (nftContractAddress.owner() == msg.sender) revert("Not NFT Owner");
  }

  //todo use interfaces
  Registry public registry;
  mQuarkController public controller;

  address public admin;

  constructor(address _registry, address _controller) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    admin = msg.sender;
    registry = Registry(_registry);
    controller = mQuarkController(_controller);
  }

  //set registry contract
  function setRegistery(address _registery) public onlyRole(DEFAULT_ADMIN_ROLE) {
    registry = Registry(_registery);
  }

  //set controller contract
  function setController(address _controller) public onlyRole(DEFAULT_ADMIN_ROLE) {
    controller = mQuarkController(_controller);
  }

  //sets authorized contract
  function initializeProject(
    address _contract,
    uint64 projectId,
    address signer,
    string calldata defaultURI,
    uint256 price
  ) public onlyRegistery {
    authorizedContracts[_contract] = true;
    projectConfig[projectId].projectId = projectId;
    projectConfig[projectId].signer = signer;
    projectConfig[projectId].defaultURI = defaultURI;
    projectConfig[projectId].subscriptionPrice = price;
    projectConfig[projectId].uriSet = true;
  }

  // function registerProject(uint64 projectId, address signer) public onlyRegistery {
  //   projectConfig[projectId].projectId = projectId;
  //   projectConfig[projectId].signer = signer;
  // }

  //change default uri
  function setDefaultURI(uint64 projectId, string calldata defaultURI) external onlyProjectOwner(projectId){
    // address projectContractAddress = registry.getProjectAddress(projectId);
    // onlyProjectOwner(mQuarkProject(projectContractAddress));
    projectConfig[projectId].defaultURI = defaultURI;
    projectConfig[projectId].uriSet = true;
  }

  function setSubscriptionPrice(uint64 projectId, uint256 price) external onlyProjectOwner(projectId){
    // address projectContractAddress = registry.getProjectAddress(projectId);
    // onlyProjectOwner(mQuarkProject(projectContractAddress));
    projectConfig[projectId].subscriptionPrice = price;
  }

  function setSigner(uint64 projectId, address signer) external onlyProjectOwner(projectId){
    // address projectContractAddress = registry.getProjectAddress(projectId);
    // onlyProjectOwner(mQuarkProject(projectContractAddress));
    projectConfig[projectId].signer = signer;
  }

  //set collection
  function setCollection(
    bool free,
    uint64 projectId,
    uint256 templateId,
    uint16 collectionId,
    address collectionAddress
  ) external onlyAuthorizedContract {
    collections[collectionAddress].projectId = projectId;
    collections[collectionAddress].templateId = templateId;
    collections[collectionAddress].collectionId = collectionId;
    collections[collectionAddress].free = free;
    collections[collectionAddress].contractAddress = collectionAddress;
  }
  //addURISLotToNFT
  function subscribe(uint256 tokenId, address tokenContract, uint64 subscriptionId) public payable {
    Collection storage collection = collections[tokenContract];
    ProjectConfig storage _projectConfig = projectConfig[subscriptionId];
    if (_projectConfig.subscribed[tokenContract][tokenId]) revert("Already Subscribed");
    if (_projectConfig.uriSet == false) revert("URI Not Set");
    if (collection.free) {
      if (!collection.unlocked[tokenId]) revert("Not Unlocked");
    }
    require(msg.value == _projectConfig.subscriptionPrice, "Wrong Amount");
    projectConfig[subscriptionId].subscribed[tokenContract][tokenId] = true;
    mQuarkNFT(tokenContract).addURISlotToNFT(msg.sender, tokenId, subscriptionId, _projectConfig.defaultURI);
    //update contract balance
    projectBalance[subscriptionId] += msg.value;
  }

  function subscribeBatch(uint256 tokenId, address tokenContract, uint64[] calldata subscriptionIds) public payable {
    Collection storage collection = collections[tokenContract];
    if (collection.free) {
      if (!collection.unlocked[tokenId]) revert("Not Unlocked");
    }
    if (calculateBatchSubscriptionPrice(subscriptionIds) != msg.value) revert("Wrong Amount");
    string[] memory uris = new string[](subscriptionIds.length);

    for (uint i = 0; i < subscriptionIds.length; i++) {
      if (projectConfig[subscriptionIds[i]].uriSet == false) revert("URI Not Set");
      uris[i] = projectConfig[subscriptionIds[i]].defaultURI;
    }
    mQuarkNFT(tokenContract).addBatchURISlotsToNFT(msg.sender, tokenId, subscriptionIds, uris);

    //update project balances
    for (uint i = 0; i < subscriptionIds.length; i++) {
      projectBalance[subscriptionIds[i]] += projectConfig[subscriptionIds[i]].subscriptionPrice;
    }
  }

  /**
   * "updateInfo" is used as bytes because token owners will have only one parameter rather than five parameters.
   * Makes a call to mQuark contract to update a given uri slot
   * Updates the project's slot uri of a single token
   * @notice Project should sign the upated URI with their wallet
   * @param signature  Signed data by project's wallet
   * @param updateInfo Encoded data
   * * project       Address of the project that is responsible for the slot
   * * projectId     ID of the project
   * * tokenContract Contract address of the given token.(External contract or mQuark)
   * * tokenId       Token ID
   * * updatedUri    The newly generated URI for the token
   */
  function updateURISlot(bytes calldata signature, bytes calldata updateInfo) external {
    (address signer, uint64 projectId, address tokenContract, uint256 tokenId, string memory updatedUri) = abi.decode(
      updateInfo,
      (address, uint64, address, uint, string)
    );
    ProjectConfig storage project = projectConfig[projectId];
    if (project.projectId == 0) revert("InvalidProjectId();");
    if (collections[tokenContract].contractAddress != tokenContract) revert("InvalidTokenContract();");
    if (project.subscribed[tokenContract][tokenId] == false) revert("NotSubscribed();");

    if (!_verifyUpdateTokenURISignature(signature, signer, projectId, tokenContract, tokenId, updatedUri))
      revert("VerificationFailed();");

    _inoperativeSignatures[signature] = true;
    mQuarkNFT(tokenContract).updateURISlot(msg.sender, projectId, tokenId, updatedUri);
  }

  //unlock free mint token
  function unlockFreeMintToken(uint256 tokenId, address tokenContract) public payable {
    Collection storage collection = collections[tokenContract];
    if (collection.projectId == 0) revert("Unknown Collection");
    require(collection.free, "Not Free");
    require(!collection.unlocked[tokenId], "Already Unlocked");
    uint256 limitPrice = controller.getTemplateMintPrice(collection.templateId);
    require(msg.value == limitPrice, "Wrong Amount");
    //update admin balance
    adminBalance[admin] += msg.value;
    collections[tokenContract].unlocked[tokenId] = true;
  }

  //get collection
  function getCollection(
    address contractAddress
  )
    public
    view
    returns (uint64 projectId, uint256 templateId, uint16 collectionId, bool free, address collectionAddress)
  {
    return (
      collections[contractAddress].projectId,
      collections[contractAddress].templateId,
      collections[contractAddress].collectionId,
      collections[contractAddress].free,
      collections[contractAddress].contractAddress
    );
  }

  function getIsSubscribed(uint256 tokenId, address tokenContract, uint64 subscriptionId) public view returns (bool) {
    return projectConfig[subscriptionId].subscribed[tokenContract][tokenId];
  }

  //todo get project
  function getProject(uint64 projectId) public view returns (uint256 subscriptionPrice, string memory defaultURI) {
    return (projectConfig[projectId].subscriptionPrice, projectConfig[projectId].defaultURI);
  }

  //calculate batch subscription price
  function calculateBatchSubscriptionPrice(uint64[] calldata subscriptionIds) public view returns (uint256) {
    uint256 price = 0;
    for (uint256 i = 0; i < subscriptionIds.length; i++) {
      price += projectConfig[subscriptionIds[i]].subscriptionPrice;
    }
    return price;
  }

  /**
   * @notice This function checks the validity of a given signature by verifying that it is signed by the given project address.
   *
   * @param signature  The signature to verify
   * @param project    The address of the project that signed the signature
   * @param projectId  The ID of the project associated with the signature
   * @param tokenId    The ID of the token associated with the signature
   * @param _uri       The URI associated with the signature
   * @return           "true" if the signature is valid
   *    */
  function _verifyUpdateTokenURISignature(
    bytes memory signature,
    address project,
    uint64 projectId,
    address tokenContract,
    uint256 tokenId,
    string memory _uri
  ) internal view returns (bool) {
    if (_inoperativeSignatures[signature]) revert("SignatureInoperative();");
    bytes32 _messageHash = keccak256(abi.encode(project, projectId, tokenContract, tokenId, _uri));
    bytes32 _signed = ECDSA.toEthSignedMessageHash(_messageHash);
    address _signer = ECDSA.recover(_signed, signature);
    return (projectConfig[projectId].signer == _signer);
  }

  //todo withdraw functions

  //   function isContract(address _address) public view returns (bool) {
  //     uint32 size;
  //     assembly {
  //       size := extcodesize(_address)
  //     }
  //     return (size > 0);
  //   }
}