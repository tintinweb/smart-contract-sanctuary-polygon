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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkSubscriber.sol";
import "./interfaces/IImportedContracts.sol";
import "./mQuarkProjectDeployer.sol";
import "./utils/noDelegateCall.sol";

/**
 * @title ImportedContracts
 * @dev This contract is used to manage the external collections.
 *      It is used by the subscriber contract to subscribe to a project.
*/
contract ImportedContracts is AccessControl, IImportedContracts {
  modifier onlySubscriber() {
    if (s_controller.getSubscriberContract() != msg.sender) revert NotAuthorized();
    _;
  }

  mapping(address => mapping(uint256 => mapping(uint256 => TokenSubscriptionInfo))) private s_tokenSubscriptions;

  ImQuarkController public s_controller;

  constructor(address _controller) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    s_controller = ImQuarkController(_controller);
  }

  function subscribeToProject(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint64 _projectId,
    string calldata _projectDefaultUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner(_tokenId);
    s_tokenSubscriptions[_contract][_tokenId][_projectId] = TokenSubscriptionInfo(true, _projectDefaultUri);
  }

    /**
   * Adds multiple URI slots to a single token in a batch operation.
   *
   * @notice Reverts if the number of projects is more than 256.
   *          Slots' initial state will be pre-filled with the given default URI values.
   *
   * @param _tokenId                The ID of the token to which the slots will be added.
   * @param _projectIds             An array of IDs for the slots that will be added.
   * @param _projectDefaultUris An array of default URI values for the added
   */
  function subscribeToProjects(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint64[] calldata _projectIds,
    string[] calldata _projectDefaultUris
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner(_tokenId);
    uint256 m_numberOfProjects = _projectIds.length;
    for (uint256 i = 0; i < m_numberOfProjects; ) {
      s_tokenSubscriptions[_contract][_tokenId][_projectIds[i]] = TokenSubscriptionInfo(true, _projectDefaultUris[i]);
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
   * @param _owner          The address of the owner of the token.
   * @param _projectId      The ID of the project.
   * @param _tokenId        The ID of the token.
   * @param _updatedUri     The updated, signed URI value.
   */
  function updateURISlot(
    address _contract,
    address _owner,
    uint64 _projectId,
    uint256 _tokenId,
    string calldata _updatedUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner(_tokenId);
    if ((s_tokenSubscriptions[_contract][_tokenId][_projectId].isSubscribed)) revert Unsubscribed(_tokenId, _projectId);
    s_tokenSubscriptions[_contract][_tokenId][_projectId].uri = _updatedUri;
  }

  function transferTokenProjectURI(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint64 _projectId,
    string calldata _transferredUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner(_tokenId);
    if ((s_tokenSubscriptions[_contract][_tokenId][_projectId].isSubscribed)) revert Unsubscribed(_tokenId, _projectId);
    s_tokenSubscriptions[_contract][_tokenId][_projectId].uri = _transferredUri;
  }

  function resetSlotToDefault(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint64 _projectId,
    string calldata _projectDefaultUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner(_tokenId);
    if ((s_tokenSubscriptions[_contract][_tokenId][_projectId].isSubscribed)) revert Unsubscribed(_tokenId, _projectId);
    s_tokenSubscriptions[_contract][_tokenId][_projectId].uri = _projectDefaultUri;
  }

  function tokenProjectURI(
    address _contract,
    uint256 _tokenId,
    uint256 _projectId
  ) external view returns (string memory) {
    return s_tokenSubscriptions[_contract][_tokenId][_projectId].uri;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Collection} from "../lib/mQuarkStructs.sol";

interface IImportedContracts {
  struct TokenSubscriptionInfo {
    // status of the upgradibilty
    bool isSubscribed;
    // the project token uri
    string uri;
  }

  function subscribeToProject(
    address _contract,
    address owner,
    uint256 tokenId,
    uint64 projectId,
    string calldata projectSlotDefaultUri
  ) external;

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
  function subscribeToProjects(
    address _contract,
    address owner,
    uint256 tokenId,
    uint64[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external;

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
    address _contract,
    address owner,
    uint64 projectId,
    uint256 tokenId,
    string calldata updatedUri
  ) external;

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
  function tokenProjectURI(address _contract, uint256 tokenId, uint256 projectId) external view returns (string memory);

  function transferTokenProjectURI(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint64 projectId,
    string calldata _soldUri
  ) external;

  function resetSlotToDefault(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint64 projectId,
    string calldata _defaultUri
  ) external;

  error InvalidVariation(uint256 variationId);
  error CollectionURIZero();
  error CollectionIsSoldOut();
  error WrongMintType(uint8 mintType);
  error InvalidPayment();
  error NoPaymentRequired();
  error VerificationFailed();
  error NotWhitelisted();
  error NotOwner(uint256 tokenId);
  error Unsubscribed(uint256 tokenId, uint64 projectId);
  error InoperativeSignature();
  error NotAuthorized();
  error InsufficientBalance();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Collection} from "../lib/mQuarkStructs.sol";

interface IInitialisable {
   function initilasiable(
    Collection calldata _collection,
    address _collectionOwner,
    address _controller,
    bytes32 _merkleRoot,
    uint256 _mintRoyalty
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../mQuarkTemplate.sol";
import "./ImQuarkRegistry.sol";

interface ImQuarkController {
  function setTemplatePrices(uint256[] calldata templateIds, uint256[] calldata prices) external;

  function setTemplateContractAddress(address template) external;

  function setRegistryContract(address registry) external;

  function setRoyalty(uint256 _royalty) external;

  function validateAuthorization(address caller) external view returns (bool);

  function getTemplateMintPrice(uint256 templateId) external view returns (uint256);

  function getSubscriberContract() external view returns (address);

  function getProjectBalance(uint256 _projectId) external view returns (uint256);

  function getImplementaion(uint8 implementation) external view returns (address);

  function getRoyalty() external view returns (uint256);

  function getWithdrawalAddress() external view returns (address);

  function getRoyaltyAndMintPrice(uint256 templateId) external view returns (uint256, uint256);

  error ArrayLengthMismatch();
  error TemplateIdNotExist();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Collection} from "../lib/mQuarkStructs.sol";

interface ImQuarkNFT {
  struct TokenSubscriptionInfo {
    // status of the upgradibilty
    bool isSubscribed;
    // the project token uri
    string uri;
  }

  struct MintRoyalty {
    uint256 royalty;
    uint256 withdrawnAmountByOwner;
    uint256 withdrawnAmountByProtocol;
    uint256 savedAmountOwner;
    uint256 savedAmountProtocol;
    uint256 totalWithdrawn;
  }

  /**
   * @notice Performs a single NFT mint without any slots.(Static and Limited Dynamic).
   *
   */
  function mint(uint256 variationId) external payable;

  function mintWithURI(
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  function mintWhitelist(bytes32[] memory _merkleProof, uint256 _variationId) external payable;

  /**
   * Checks the validity of given parameters and whether paid ETH amount is valid
   * Makes a call to mQuark contract to mint single NFT with given validated URI.
   *
   * @param signer       Registered project address of the given collection
   * @param signature    Signed data by project's owner wallet
   * @param uri          The metadata URI that will represent the template.
   */
  //payable - dynamic variation - unlimited - no whitelist
  function mintWithURIWhitelist(
    bytes32[] memory merkleProof,
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Performs a batch mint operation. (Static and Limited Dynamic).
   *
   */
  // function mintBatch(address to, string calldata uri, uint256 amount) external;

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
  function subscribeToProject(
    address owner,
    uint256 tokenId,
    uint64 projectId,
    string calldata projectSlotDefaultUri
  ) external;

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
  function subscribeToProjects(
    address owner,
    uint256 tokenId,
    uint64[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external;

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
  function updateURISlot(address owner, uint64 projectId, uint256 tokenId, string calldata updatedUri) external;

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
  /// @dev a new new name suggestion: tokenSlotURI
  function tokenProjectURI(uint256 tokenId, uint256 projectId) external view returns (string memory);

   function initilasiable(
    Collection calldata _collection,
    address _collectionOwner,
    address _controller,
    bytes32 _merkleRoot,
    uint256 _mintRoyalty
  ) external;

  function transferTokenProjectURI(
    address _owner,
    uint256 _tokenId,
    uint64 projectId,
    string calldata _soldUri
  ) external;

  function resetSlotToDefault(address _owner, uint256 _tokenId, uint64 projectId, string calldata _defaultUri) external;

  function withdraw() external;

  function protocolWithdraw() external;

 error InvalidVariation(string reason, uint256 variationId);
  error CollectionURIZero(string reason);
  error CollectionIsSoldOut(string reason);
  error WrongMintType(string reason,uint8 mintType);
  error InvalidPayment(string reason);
  error NoPaymentRequired(string reason);
  error VerificationFailed(string reason);
  error NotWhitelisted(string reason);
  error NotOwner(string reason,uint256 tokenId);
  error Unsubscribed(string reason,uint256 tokenId, uint64 projectId);
  error InoperativeSignature(string reason);
  error NotAuthorized(string reason);
  error InsufficientBalance(string reason);
  error MintLimitReached(string reason);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Collection} from "../lib/mQuarkStructs.sol";

interface ImQuarkProject {
  struct CollectionParams {
    uint256 templateId;
    string[] collectionURIs;
    uint256 totalSupply;
    uint256 mintPrice;
    uint8 mintPerAccountLimit;
    string name;
    string symbol;
    address verifier;
    bool isWhitelisted;
  }

  function createCollection(
    CollectionParams calldata collectionParams,
    bool isDynamicUri,
    uint8 ERCimplementation,
    bytes32 merkeRoot
  ) external returns (address instance);

   function getLastCollectionId() external view returns (uint64);

  function getCollectionAddress(uint64 collectionId) external view returns (address);

  error InvalidURILength(uint256 uriLength);
  error InvalidTemplate(uint256 templateId);
  error InvalidCollectionPrice(uint256 mintPrice);
  error NotCollectionOwner(address collectionAddress);
  error NoERC165Support(address collectionAddress);
  error NoERC721Support(address collectionAddress);
  error NotExternal(address collectionAddress);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import './interfaces/ImQuarkProjectDeployer.sol';

import './ImQuarkProject.sol';

interface ImQuarkProjectDeployer{

    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address registry,
            address subscriber,
            address owner,
            uint64 id
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ImQuarkProject.sol";

interface ImQuarkRegistry {
  function setController(address _controller) external;

  function setSubscriber(address _subscriber) external;

  function setImplementation(uint8 _id, address _implementation) external;

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

  function getSubscriber() external view returns (address);

  function getContoller() external view returns (address);

  function getProjectSlotPrice(uint256 _projectId) external view returns (uint256);

  function getLastProjectId() external view returns (uint64);

  function getImplementaion(uint8 _implementation) external view returns (address);

  function getControllerAndSubscriber() external view returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {BuyOrder, SellOrder} from "../lib/mQuarkStructs.sol";

interface ImQuarkSubscriber {
  struct Collection {
    uint64 projectId;
    uint64 collectionId;
    uint256 templateId;
    bool free;
    bool isExternal;
    address contractAddress;
  }

  struct ProjectConfig {
    uint64 projectId;
    uint256 subscriptionPrice;
    address signer;
    string defaultURI;
    bool set;
  }

  function initializeProject(
    address _contract,
    uint64 projectId,
    address signer,
    string calldata defaultURI,
    uint256 price
  ) external;

  function setRegistery(address _registery) external;

  function setRoyalty(uint256 _royalty) external;

  function setController(address _controller) external;

  function setDefaultURI(uint64 projectId, string calldata defaultURI) external;

  function setSubscriptionPrice(uint64 projectId, uint256 price) external;

  function setSigner(uint64 _projectId, address _signer) external;

  function setCollection(
    bool _free,
    bool _external,
    uint64 _projectId,
    uint256 _templateId,
    uint64 _collectionId,
    address _collectionAddress
  ) external;

  function subscribe(uint256 _tokenId, address _tokenContract, uint64 _subscriptionId) external payable;

  function subscribeBatch(
    uint256 _tokenId,
    address _tokenContract,
    uint64[] calldata _subscriptionIds
  ) external payable;

  function unlockToken(uint256 _tokenId, address _tokenContract) external payable;

  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable;

  function updateURISlot(bytes calldata _signature, bytes calldata _updateInfo) external;

  function getIsSubscribed(
    uint256 _tokenId,
    address _tokenContract,
    uint64 _subscriptionId
  ) external view returns (bool);

  function getProjectConfig(
    uint64 _projectId
  )
    external
    view
    returns (uint64 projectId, uint256 subscriptionPrice, string memory defaultURI, bool uriSet, address signer);

  function getCollection(
    address _contractAddress
  )
    external
    view
    returns (uint64 projectId, uint256 templateId, uint64 collectionId, bool free, address collectionAddress);

  function getIsUnlocked(uint256 _tokenId, address _tokenContract) external view returns (bool);

  function getProjectBalance(uint64 _projectId) external view returns (uint256);

  function getIsAddressRegisteredAsProject(address _address) external view returns (bool);

  function calculateBatchSubscriptionPrice(uint64[] calldata _subscriptionIds) external view returns (uint256);

  function withdraw(uint64 _projectId, uint256 _amount) external;

  function withdrawProtocol(uint256 _amount) external;

  error Unauthorized(address caller);
  error NotRegistry(address caller);
  error NotProjectOwner(uint64 projectId);
  error NotCollectionOwner(address collectionAddress);
  error AlreadySubscribed(uint64 _subscriptionId, address InvalidTokenContract, uint256 tokenId);
  error Unexist(uint64 projectId);
  error TokenLocked(address contractAddress, uint256 tokenId);
  error InvalidPayment(uint256 amount);
  error InvalidTokenContract(address contractAddress);
  error Unsubscribed(uint64 projectId);
  error VerificationFailed();
  error UnknownCollection();
  error NotFreeCollection();
  error AlreadyUnlocked(uint256 tokenId);
  error SignatureInoperative();
  error InsufficientBalance();
  error NotOwner(uint256 tokenId);
  error UnauthorizedToTransfer();
  error PriceMismatch();
  error InvalidSentAmount();
  error TokenMismatch();
  error GivenProjectIdMismatch();
  error SellerAddressMismatch();
  error UriMismatch();
  error SellerIsNotTheSigner();
  error BuyerIsNotTheSigner();
  error FailedToSentEther();
  error InvalidCollection(address tokenContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface ImQuarkTemplate  {
  /**
   *  @notice Creates a new template with the given URI, which will be inherited by collections.
   *
   * @param _uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata _uri) external;

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   *
   * @param _uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata _uris) external ;

  /**
   * Templates defines what a token is. Every template id has its own properties and attributes.
   * Collections are created by templates. Inherits the properties and attributes of the template.
   *
   * @param _templateId  Template ID
   * @return            Template's URI
   * */
  function templateUri(uint256 _templateId) external view returns (string memory);

  /**
   * @notice This function returns the total number of templates that have been created.
   *
   * @return The total number of templates that have been created
   */
  function getLastTemplateId() external view returns (uint256);

  function isTemplateIdExist(uint256 _templateId) external view returns(bool exist);

  error ExceedsLimit();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IOwnable {

  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct CreateCollectionParams {
  uint256 templateId;
  uint256 collectionPrice;
  uint256 totalSupply;
}

struct Collection {
  uint64 projectId;
  uint64 collectionId;
  uint8 mintType;
  uint8 mintPerAccountLimit;
  bool isWhitelisted;
  bool isFree;
  uint256 templateId;
  uint256 mintCount;
  uint256 totalSupply;
  uint256 mintPrice;
  string[] collectionURIs;
  string name;
  string symbol;
  address verifier;
}

struct SellOrder {
  // the order maker (the person selling the URI)
  address payable seller;
  // the "from" token contract address
  address fromContractAddress;
  // the token id whose project URI will be sold
  uint256 fromTokenId;
  // the project's id whose owner is selling the URI
  uint64 projectId;
  // the URI that will be sold
  string slotUri;
  // the price required for the URI
  uint256 sellPrice;
  bytes salt;
}
struct BuyOrder {
  // the order executer (the person buying the URI)
  address buyer;
  // the order maker (the person selling the URI)
  address seller;
  // the "from" token contract address
  address fromContractAddress;
  // the token id whose project URI will be sold
  uint256 fromTokenId;
  // the "to" token contract address
  address toContractAddress;
  // the token id whose project URI will be sold
  uint256 toTokenId;
  // the project's id whose owner is selling the URI
  uint64 projectId;
  // the URI that will be bought
  string slotUri;
  // the price required for the URI
  uint256 buyPrice;
  bytes salt;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library EnumerableStringSet {
    
  struct StringSet {
    // Storage of set values
    string[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(string => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(StringSet storage set, string memory value) internal returns (bool) {
    if (!contains(set, value)) {
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
  function remove(StringSet storage set, string memory value) internal returns (bool) {
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
        string memory lastvalue = set._values[lastIndex];

        // Move the last value to the index where the value to delete is
        set._values[toDeleteIndex] = lastvalue;
        // Update the index for the moved value
        set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
  function contains(StringSet storage set, string memory value) internal view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(StringSet storage set) internal view returns (uint256) {
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
  function at(StringSet storage set, uint256 index) internal view returns (string memory) {
    return set._values[index];
  }

  function values(StringSet storage set) internal view returns (string[] memory) {
    return set._values;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IOwnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/ImQuarkTemplate.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkRegistry.sol";
import "./utils/noDelegateCall.sol";

contract mQuarkController is AccessControl, ImQuarkController, NoDelegateCall {
  event SubscriberContractAddressSet(address subscriber);
  event TemplateContractAddressSet(address template);
  event RegisteryContractAddressSet(address registry);
  event RoyaltySet(uint256 royalty);
  // Emitted when the prices of templates are set
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);

  /**
   * Mapping from 'template id' to 'mint price' in wei
   */
  mapping(uint256 => uint256) private s_templateMintPrices;

  mapping(uint256 => uint256) private s_projectBalances;

  //only mQuarNFT owner modifier
  function _onlyNFTOwner(IOwnable _nftContractAddress) internal view {
    if (_nftContractAddress.owner() == msg.sender) revert("Not NFT Owner");
  }

  /// @dev    Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  mapping(bytes => bool) private s_inoperativeSignatures;

  /// @dev This role will be used to check the validity of signatures
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  /// @dev This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @dev This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  ImQuarkRegistry public s_registeryContract;
  ImQuarkTemplate public s_template;
  address public s_subscriberContract;
  /// @dev The address of the verifier, who signs collection URIs
  address public s_verifier;
  uint256 public s_royalty;
  address private s_withdrawelAddress;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
  }

  /**
   * Sets Templates mint prices(wei)
   *
   * @notice Collections inherit the template's mint price
   *
   * @param _templateIds  IDs of Templates which are categorized NFTs
   * @param _prices        Prices of each given templates in wei unit
   * */
  function setTemplatePrices(
    uint256[] calldata _templateIds,
    uint256[] calldata _prices
  ) external onlyRole(CONTROL_ROLE) noDelegateCall {
    if (_templateIds.length != _prices.length) revert ArrayLengthMismatch();
    uint256 m_numberOfIds = _templateIds.length;
    for (uint256 i = 0; i < m_numberOfIds; ) {
      if (!s_template.isTemplateIdExist(_templateIds[i])) revert TemplateIdNotExist();
      s_templateMintPrices[_templateIds[i]] = _prices[i];
      unchecked {
        ++i;
      }
    }
    emit TemplatePricesSet(_templateIds, _prices);
  }

  function setTemplateContractAddress(address _template) external onlyRole(CONTROL_ROLE) noDelegateCall {
    s_template = mQuarkTemplate(_template);
    emit TemplateContractAddressSet(_template);
  }

  function setSubscriberContract(address _addr) external onlyRole(CONTROL_ROLE) noDelegateCall {
    s_subscriberContract = _addr;
    emit SubscriberContractAddressSet(_addr);
  }

  function setRegistryContract(address _addr) external onlyRole(CONTROL_ROLE) noDelegateCall {
    s_registeryContract = ImQuarkRegistry(_addr);
    emit RegisteryContractAddressSet(_addr);
  }

  //ROYALTY sensitivity is 1 000 000
  function setRoyalty(uint256 _royalty) external onlyRole(CONTROL_ROLE) noDelegateCall {
    s_royalty = _royalty;
    emit RoyaltySet(_royalty);
  }

  function setAuthorizedWithdrawer(address _addr) external onlyRole(CONTROL_ROLE) noDelegateCall {
    s_withdrawelAddress = _addr;
  }

  //get template mint price
  function getTemplateMintPrice(uint256 _templateId) external view returns (uint256) {
    return s_templateMintPrices[_templateId];
  }

  function getImplementaion(uint8 _implementation) external view returns (address)  {
    return s_registeryContract.getImplementaion(_implementation);
  }

  function getSubscriberContract() external view returns (address) {
    return s_subscriberContract;
  }

  function getRoyalty() external view returns (uint256) {
    return s_royalty;
  }

  function getWithdrawalAddress() external view returns (address) {
    return s_withdrawelAddress;
  }

  function getRoyaltyAndMintPrice(uint256 templateId) external view returns (uint256, uint256) {
    return (s_royalty, s_templateMintPrices[templateId]);
  }

  function validateAuthorization(address caller) external view returns (bool) {
    return s_withdrawelAddress == caller;
  }

  function getProjectBalance(uint256 _projectId) external view noDelegateCall returns (uint256) {
    return s_projectBalances[_projectId];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ImQuarkNFT.sol";
import "./interfaces/ImQuarkRegistry.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkSubscriber.sol";
import "./interfaces/ImQuarkProjectDeployer.sol";
import "./interfaces/ImQuarkProject.sol";
import "./interfaces/IInitialisable.sol";
import "./utils/noDelegateCall.sol";
import "./interfaces/IOwnable.sol";
import {mQuarkController} from "./mQuarkController.sol";
import {Collection} from "./lib/mQuarkStructs.sol";

contract mQuarkProject is ImQuarkProject, Ownable, NoDelegateCall {
  event CollectionCreated(
    address instanceAddress,
    uint64 projectId,
    uint256 templateId,
    uint64 collectionId,
    bytes32 merkleRoot,
    uint256 royalty,
    address controller,
    bool free
  );

  event ExternalCollectionCreated(address collectionAddress, uint64 projectId, uint256 templateId, uint64 collectionId);

  address public immutable s_registry;

  address public immutable s_subscriber;

  address public immutable s_owner;

  uint64 public immutable s_ID;

  /// @dev uint16 is a very small amount for collection limit of upto 65535. we should increase this.
  uint64 private s_lastCollectionId;

  mapping(uint256 => address) private s_allCollections;

  constructor() {
    (s_registry, s_subscriber, s_owner, s_ID) = ImQuarkProjectDeployer(msg.sender).parameters();
    _transferOwnership(s_owner);
  }

  function createCollection(
    CollectionParams memory _collectionParams,
    bool _isDynamicUri,
    uint8 _ERCimplementation,
    bytes32 _merkelRoot
  ) external noDelegateCall returns (address _instance) {
    (address m_controller, address m_subscriber)= ImQuarkRegistry(s_registry).getControllerAndSubscriber();
    (uint256 m_royalty, uint256 m_limitMintPrice) = ImQuarkController(m_controller).getRoyaltyAndMintPrice(_collectionParams.templateId);

    if (_collectionParams.collectionURIs.length > 1 && _isDynamicUri)
      revert InvalidURILength(_collectionParams.collectionURIs.length);
    if (m_limitMintPrice == 0) revert InvalidTemplate(_collectionParams.templateId);
    if ((_collectionParams.mintPrice < m_limitMintPrice) && (_collectionParams.mintPrice != 0))
      revert InvalidCollectionPrice(_collectionParams.mintPrice);
    uint8 m_mintType;
    /// @notice Paid collection
    if (_collectionParams.mintPrice > 0) {
      if (_collectionParams.collectionURIs.length > 1) {
        m_mintType = _collectionParams.isWhitelisted ? 0 : 1;
        /// @notice 0 => paid | limited variation | whitelist
        /// @notice 1 => paid | limited variation | no whitelist
      } else {
        if (_isDynamicUri) {
          m_mintType = _collectionParams.isWhitelisted ? 2 : 3;
          /// @notice 2 => paid | dynamic variation | whitelist
          /// @notice 3 => paid | dynamic variation | no whitelist
        } else {
          m_mintType = _collectionParams.isWhitelisted ? 4 : 5;
          /// @notice 4 => paid | static variation | whitelist
          /// @notice 5 => paid | static variation | no whitelist
        }
      }
    } else {
      if (_collectionParams.collectionURIs.length > 1) {
        m_mintType = _collectionParams.isWhitelisted ? 6 : 7;
        /// @notice 6 => free | limited variation | whitelist
        /// @notice 7 => free | limited variation | no whitelist
      } else {
        if (_isDynamicUri) {
          m_mintType = _collectionParams.isWhitelisted ? 8 : 9;
          /// @notice 8 => free | dynamic variation | whitelist
          /// @notice 9 => free | dynamic variation | no whitelist
        } else {
          m_mintType = _collectionParams.isWhitelisted ? 10 : 11;
          /// @notice 10 => free | static variation | whitelist
          /// @notice 11 => free | static variation | no whitelist
        }
      }
    }

    string[] memory m_uris;
    bool m_free = _collectionParams.mintPrice == 0 ? true : false;

    m_uris = _isDynamicUri ? new string[](1) : _collectionParams.collectionURIs;

    _instance = Clones.clone(ImQuarkRegistry(s_registry).getImplementaion(_ERCimplementation));

    Collection memory m_collection = Collection({
      collectionId: ++s_lastCollectionId,
      projectId: s_ID,
      templateId: _collectionParams.templateId,
      collectionURIs: _isDynamicUri ? new string[](1) : _collectionParams.collectionURIs,
      totalSupply: _collectionParams.totalSupply,
      mintPrice: _collectionParams.mintPrice,
      mintCount: 0,
      mintPerAccountLimit: _collectionParams.mintPerAccountLimit,
      name: _collectionParams.name,
      symbol: _collectionParams.symbol,
      verifier: _collectionParams.verifier,
      mintType: m_mintType,
      isWhitelisted: _collectionParams.isWhitelisted,
      isFree: m_free
    });

    IInitialisable(_instance).initilasiable(m_collection, msg.sender, m_controller, _merkelRoot, m_royalty);

    s_allCollections[m_collection.collectionId] = _instance;

    ImQuarkSubscriber(m_subscriber).setCollection(
      m_free,
      false,
      m_collection.projectId,
      _collectionParams.templateId,
      m_collection.collectionId,
      _instance
    );

    emit CollectionCreated(
      _instance,
      m_collection.projectId,
      m_collection.templateId,
      m_collection.collectionId,
      _merkelRoot,
      m_royalty,
      m_controller,
      m_collection.isFree
    );
  }

  function registerExternalCollection(uint256 _templateId, address _collectionAddress) external noDelegateCall {
    if (IOwnable(_collectionAddress).owner() != msg.sender) revert NotCollectionOwner(_collectionAddress);
    try IERC165(_collectionAddress).supportsInterface(type(IERC721).interfaceId) returns (bool result) {
      if (result) {
        if(IERC165(_collectionAddress).supportsInterface(type(ImQuarkNFT).interfaceId)) revert NotExternal(_collectionAddress);
        address m_subscriber = ImQuarkRegistry(s_registry).getSubscriber();
        uint64 _projectId = s_ID;
        uint64 _collectionId = ++s_lastCollectionId;
        ImQuarkSubscriber(m_subscriber).setCollection(
          true,
          true,
          _projectId,
          _templateId,
          _collectionId,
          _collectionAddress
        );
        emit ExternalCollectionCreated(_collectionAddress, _projectId, _templateId, _collectionId);
      } else {
        revert NoERC721Support(_collectionAddress);
      }
    } catch {
      revert NoERC165Support(_collectionAddress);
    }
  }

  function getCollectionAddress(uint64 collectionId) external view noDelegateCall returns (address) {
    return s_allCollections[collectionId];
  }

  function getLastCollectionId() external view noDelegateCall returns (uint64) {
    return s_lastCollectionId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./mQuarkProject.sol";

contract mQuarkProjectDeployer is ImQuarkProjectDeployer {

  struct Parameters {
      address registry;
      address owner;
      address subscriber;
      uint64 id;
  }

  Parameters public override parameters;

  /**
   * @dev This function deploys a project using the provided parameters. It does so by temporarily setting the
   *      parameters storage slot and then clearing it once the project has been deployed.
   *
   * @param _registry              The registry address of the mQuark protocol
   * @param _subscriber            The subscriber address of the mQuark protocol
   * @param _owner                 The EOA address that is creating the project
   * @param _id                    The uint value of the project ID
   */
  function deploy(
    address _registry,
    address _subscriber,
    address _owner,
    uint64 _id
  ) internal returns (address project) {
    parameters = Parameters({registry: _registry, subscriber: _subscriber, owner: _owner, id: _id});
    project = address(new mQuarkProject{salt: keccak256(abi.encode(_registry, _owner, _id))}());
    delete parameters;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./lib/StringSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ImQuarkTemplate.sol";

contract mQuarkTemplate is AccessControl, ImQuarkTemplate {
  event CategoryCreated(string category,uint256 id, bytes4 selector, string uri);
  event TemplateCreated(uint256 templateId, string uri);
  event CategoriesSet(string category, uint256[] templateIds);
  event CategoryRemoved(string category, uint256 templateId);

  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using EnumerableStringSet for EnumerableStringSet.StringSet;

  struct Category {
    uint256 id;
    bytes4 selector;
    string name;
    string uri;
  }

  /// @dev Mapping from 'category name' to 'category'
  mapping (string => Category) public categoriesByName;

  /// @dev Mapping from 'category id' to 'category'
  mapping (uint256 => Category) public categoriesById;

  /// @dev Mapping from 'selector' to 'category'
  mapping (bytes4 => Category) public categoriesBySelector;


  /// @dev Mapping from 'category' to  'template ids'
  mapping(string => EnumerableSet.UintSet) private categoryTemplates;

  /// @dev Mapping from 'template id' to 'categories'
  mapping(uint256 => EnumerableStringSet.StringSet) private templateCategories;

  /// @dev Stores the ids of created templates
  EnumerableSet.UintSet private s_templateIds;

  /// @dev Keeps track of the last created template id
  uint256 public s_templateIdCounter;

  uint256 public s_categoryCounter;

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
  mapping(uint256 => string) private s_templateURIs;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
  }

  /**
   *  @notice Creates a new template with the given URI, which will be inherited by collections.
   *
   * @param _uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata _uri) external onlyRole(CONTROL_ROLE) {
    uint256 m_templateId = ++s_templateIdCounter;

    s_templateURIs[m_templateId] = _uri;

    s_templateIds.add(m_templateId);

    emit TemplateCreated(m_templateId, _uri);
  }

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   *
   * @param _uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata _uris) external onlyRole(CONTROL_ROLE) {
    uint256 m_numberOfUris = _uris.length;
    if (m_numberOfUris > 255) revert ExceedsLimit();
    uint256 _templateId = s_templateIdCounter;
    for (uint8 i = 0; i < m_numberOfUris; ) {
      ++_templateId;
      s_templateURIs[_templateId] = _uris[i];
      s_templateIds.add(_templateId);
      emit TemplateCreated(_templateId, _uris[i]);

      unchecked {
        ++i;
      }
    }
    s_templateIdCounter = _templateId;
  }

  
  /// @param name category name
  /// @param uri category uri
  function createCategory(string calldata name, string calldata uri) external onlyRole(CONTROL_ROLE) {
    uint256 m_categoryId = ++s_categoryCounter;
    bytes4 selector = bytes4(keccak256(bytes(name)));
    Category memory m_category = Category(m_categoryId, selector, name, uri);
    categoriesByName[name] = m_category;
    categoriesById[m_categoryId] = m_category;
    categoriesBySelector[selector] = m_category;
    emit CategoryCreated(name, m_categoryId, selector, uri);
  }

  /// Sets given templates to a category
  /// @param category category name for the template (e.g. "vehicle")
  /// @param templateIds_ template ids that will be set to the given category(1,2,3..)
  function setTemplateCategory(string calldata category, uint256[] calldata templateIds_) external onlyRole(CONTROL_ROLE) {
    //check if the category is exist
    require(categoriesByName[category].id != 0, "unexisting category");
    uint256 templateLength = templateIds_.length;
    for (uint256 i = 0; i < templateLength; ) {
      require(s_templateIds.contains(templateIds_[i]) == true, "unexisting template");
      categoryTemplates[category].add(templateIds_[i]);
      templateCategories[templateIds_[i]].add(category);
      {
        ++i;
      }
    }
    emit CategoriesSet(category, templateIds_);
  }

  /// Removes given template from a given category.
  /// @param category category name for the template (e.g. "vehicle")
  /// @param templateId template id that will be set to the given category(1,2,3.. etc.)
  function removeCategoryFromTemplate(string memory category, uint256 templateId) external onlyRole(CONTROL_ROLE) {
    categoryTemplates[category].remove(templateId);
    templateCategories[templateId].remove(category);
    emit CategoryRemoved(category, templateId);
  }

  /**
   * Templates defines what a token is. Every template id has its own properties and attributes.
   * Collections are created by templates. Inherits the properties and attributes of the template.
   *
   * @param _templateId  Template ID
   * @return             Template's URI
   * */
  function templateUri(uint256 _templateId) external view returns (string memory) {
    return s_templateURIs[_templateId];
  }

  /**
   * @notice This function returns the total number of templates that have been created.
   *
   * @return The total number of templates that have been created
   */
  function getLastTemplateId() external view returns (uint256) {
    return s_templateIds.length();
  }

  function isTemplateIdExist(uint256 _templateId) external view returns (bool exist) {
    exist = s_templateIds.contains(_templateId);
  }


    /// @notice If array stores too much templates, it will be too expensive to return all of them.
  /// thus, it is better to return the template ids in batches.
  /// Because this function may start to revert after a point
  /// @param category the name of the category
  /// @return all the templates that is in the given category
  function getAllCategoryTemplates(string memory category) public view returns (uint256[] memory) {
    return categoryTemplates[category].values();
  }

  /// For the concers of the gas, it is better to return the template ids in batches.
  /// @notice If the batch size is too big, it will revert.
  /// @notice If the start index and the batch size exceeds the current category length,
  /// returned array will be shorter than the batch size.
  /// @param category the name of the category
  /// @param startIndex the index of the array that will start to search
  /// @param batchLength the returned length of the query array.
  /// @return the templates that is in the given category
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) public view returns (uint256[] memory) {
    uint16 endIndex = startIndex + batchLength;
    if (batchLength + startIndex > categoryTemplates[category].length())
      endIndex = uint16(categoryTemplates[category].length());
    uint256[] memory _templateIds = new uint256[](endIndex - startIndex);
    unchecked {
      for (uint16 i = startIndex; i < endIndex; ) {
        _templateIds[i - startIndex] = categoryTemplates[category].at(i);
        ++i;
      }
    }
    return _templateIds;
  }

  /// @return the lentgh of the templates that the given category has
  /// @dev if the template is not in any category, it will return an empty array
  function getTemplatesCategory(uint256 templateId) public view returns (string[] memory) {
    return templateCategories[templateId].values();
  }

  /// @return the lentgh of the categories that the given template is in
  function getCategoryTemplateLength(string calldata category) public view returns (uint256) {
    return categoryTemplates[category].length();
  }

  //get category by name
  function getCategoryByName(string calldata name) external view returns (Category memory) {
    return categoriesByName[name];
  }

  //get category by id
  function getCategoryById(uint256 id) external view returns (Category memory) {
    return categoriesById[id];
  }

  //get category by selector
  function getCategoryBySelector(bytes4 selector) external view returns (Category memory) {
    return categoriesBySelector[selector];
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract NoDelegateCall {
  // adding no deligate call here for global access
  address private immutable s_original;


  constructor() {
    s_original = address(this);
  }



  function testNoDelegateCall() private view {
    require(address(this) == s_original);
  }



  /**
   * Prevents delegatecall into the modified method
   */
  modifier noDelegateCall() {
    testNoDelegateCall();
    _;
  }
}