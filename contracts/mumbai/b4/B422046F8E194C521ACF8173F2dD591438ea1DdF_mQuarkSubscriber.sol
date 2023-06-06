// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

interface IImportedContracts {
  /**
   * @notice Represents the subscription information for a token.
   */
  struct TokenSubscriptionInfo {
    bool isSubscribed; // Indicates whether the token is subscribed or not.
    string uri; // The URI associated with the token.
  }

  /**
   * @notice Subscribes a token to an entity.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity.
   * @param entitySlotDefaultUri The default URI for the entity slot.
   */
  function subscribeToEntity(
    address _contract,
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata entitySlotDefaultUri
  ) external;

  /**
   * @notice Subscribes multiple tokens to entities.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityIds The IDs of the entities.
   * @param entitySlotDefaultUris The default URIs for the entity slots.
   */
  function subscribeToEntities(
    address _contract,
    address owner,
    uint256 tokenId,
    uint64[] calldata entityIds,
    string[] calldata entitySlotDefaultUris
  ) external;

  /**
   * @notice Updates the URI slot of a single token.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param entityId The ID of the entity.
   * @param tokenId The ID of the token.
   * @param updatedUri The updated, signed URI value.
   */
  function updateURISlot(
    address _contract,
    address owner,
    uint256 entityId,
    uint256 tokenId,
    string calldata updatedUri
  ) external;

  /**
   * @notice Returns the entity URI for the given token ID.
   * @param _contract The address of the contract.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @return The URI of the given token's entity slot.
   */
  function tokenEntityURI(address _contract, uint256 tokenId, uint256 entityId) external view returns (string memory);

  /**
   * @notice Transfers the token entity URI.
   * @param _contract The address of the contract.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token.
   * @param entityId The ID of the entity.
   * @param _soldUri The URI to be transferred.
   */
  function transferTokenEntityURI(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint256 entityId,
    string calldata _soldUri
  ) external;

  /**
   * @notice Resets the slot to the default URI.
   * @param _contract The address of the contract.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token.
   * @param entityId The ID of the entity.
   * @param _defaultUri The default URI to be set.
   */
  function resetSlotToDefault(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint256 entityId,
    string calldata _defaultUri
  ) external;

  /// Throws if the provided variation ID is invalid.
  error InvalidVariation(uint256 variationId);

  /// Throws if the collection URI is empty.
  error CollectionURIZero();

  /// Throws if the collection is sold out.
  error CollectionIsSoldOut();

  /// Throws if the mint type is wrong.
  error WrongMintType(uint8 mintType);

  /// Throws if the payment is invalid.
  error InvalidPayment();

  /// Throws if no payment is required.
  error NoPaymentRequired();

  /// Throws if the verification failed.
  error VerificationFailed();

  /// Throws if the entity is not whitelisted.
  error NotWhitelisted();

  /// Throws if the caller is not the owner of the token.
  error NotOwner(uint256 tokenId);

  /// Throws if the token is unsubscribed from the entity.
  error Unsubscribed(uint256 tokenId, uint256 entityId);

  /// Throws if the signature is inoperative.
  error InoperativeSignature();

  /// Throws if the caller is not authorized.
  error NotAuthorized();

  /// Throws if the balance is insufficient.
  error InsufficientBalance();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "../mQuarkTemplate.sol";
import "./ImQuarkRegistry.sol";

interface ImQuarkController {
  /**
   * @notice Emitted when the address of the subscriber contract is set.
   * @param subscriber The address of the subscriber contract.
   */
  event SubscriberContractAddressSet(address subscriber);

  /**
   * @notice Emitted when the address of the template contract is set.
   * @param template The address of the template contract.
   */
  event TemplateContractAddressSet(address template);

  /**
   * @notice Emitted when the address of the registry contract is set.
   * @param registry The address of the registry contract.
   */
  event RegistryContractAddressSet(address registry);

  /**
   * @notice Emitted when the royalty percentage is set.
   * @param royalty The royalty percentage.
   */
  event RoyaltySet(uint256 royalty);

  /**
   * @notice Emitted when the prices of templates are set.
   * @param templateIds The IDs of the templates.
   * @param prices The corresponding prices for the templates.
   */
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);

  /**
   * @notice Emitted when the authorized withdrawal address is set.
   * @param authorizedWithdrawal The authorized withdrawal address.
   */
  event AuthorizedWithdrawalSet(address authorizedWithdrawal);

  /**
   * @notice Sets the prices for multiple templates.
   * @param templateIds The IDs of the templates.
   * @param prices The corresponding prices for the templates.
   */
  function setTemplatePrices(uint256[] calldata templateIds, uint256[] calldata prices) external;

  /**
   * @notice Sets the address of the template contract.
   * @param template The address of the template contract.
   */
  function setTemplateContractAddress(address template) external;

  /**
   * @notice Sets the address of the registry contract.
   * @param registry The address of the registry contract.
   */
  function setRegistryContract(address registry) external;

  /**
   * @notice Sets the royalty percentage.
   * @param _royalty The royalty percentage to set.
   */
  function setRoyalty(uint256 _royalty) external;

  /**
   * @notice Validates the authorization of a caller.
   * @param caller The address of the caller.
   * @return True if the caller is authorized, otherwise false.
   */
  function validateAuthorization(address caller) external view returns (bool);

  /**
   * @notice Retrieves the mint price for a template.
   * @param templateId The ID of the template.
   * @return The mint price of the template.
   */
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256);

  /**
   * @notice Retrieves the address of the subscriber contract.
   * @return The address of the subscriber contract.
   */
  function getSubscriberContract() external view returns (address);

  /**
   * @notice Retrieves the balance of an entity.
   * @param _entityId The ID of the entity.
   * @return The balance of the entity.
   */
  function getEntityBalance(uint256 _entityId) external view returns (uint256);

  /**
   * @notice Retrieves the implementation address for a given implementation type.
   * @param implementation The implementation type.
   * @return The implementation address.
   */
  function getImplementation(uint8 implementation) external view returns (address);

  /**
   * @notice Retrieves the royalty percentage.
   * @return The royalty percentage.
   */
  function getRoyalty() external view returns (uint256);

  /**
   * @notice Retrieves the authorized withdrawal address.
   * @return The authorized withdrawal address.
   */
  function getWithdrawalAddress() external view returns (address);

  /**
   * @notice Retrieves the royalty percentage and mint price for a template.
   * @param templateId The ID of the template.
   * @return The royalty percentage and mint price of the template.
   */
  function getRoyaltyAndMintPrice(uint256 templateId) external view returns (uint256, uint256);

  /// Throws if the lengths of the input arrays do not match.
  error ArrayLengthMismatch();

  /// Throws if the provided template ID does not exist.
  error TemplateIdNotExist();

  /// Throws if the provided royalty percentage is too high.
  error RoyaltyIsTooHigh();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

interface ImQuarkEntity {
  /**
   * @notice Emitted when a collection is created.
   * @param instanceAddress The address of the created collection contract instance.
   * @param verifier The address of the verifier contract.
   * @param controller The address of the controller contract.
   * @param entityId The ID of the entity associated with the collection.
   * @param collectionId The ID of the collection.
   * @param templateId The ID of the template associated with the collection.
   * @param mintPrice The price of minting a token in the collection.
   * @param totalSupply The total supply of tokens in the collection.
   * @param mintLimitPerWallet The maximum number of tokens that can be minted per wallet.
   * @param royalty The royalty percentage for the collection.
   * @param collectionURIs The URIs associated with the collection.
   * @param mintType The minting type of the collection.
   * @param dynamic A flag indicating if the collection has dynamic URIs.
   * @param free A flag indicating if the collection is free.
   * @param whiteListed A flag indicating if the collection is whitelisted.
   */
  event CollectionCreated(
    address instanceAddress,
    address verifier,
    address controller,
    uint256 entityId,
    uint64 collectionId,
    uint256 templateId,
    uint256 mintPrice,
    uint256 totalSupply,
    uint256 mintLimitPerWallet,
    uint256 royalty,
    string[] collectionURIs,
    uint8 mintType,
    bool dynamic,
    bool free,
    bool whiteListed
  );

  /**
   * @notice Emitted when an external collection is created.
   * @param collectionAddress The address of the created external collection contract.
   * @param entityId The ID of the entity associated with the collection.
   * @param templateId The ID of the template associated with the collection.
   * @param collectionId The ID of the collection.
   */
  event ExternalCollectionCreated(address collectionAddress, uint256 entityId, uint256 templateId, uint64 collectionId);

  /**
   * @notice Represents the parameters required to create a collection.
   */
  struct CollectionParams {
    uint256 templateId; // The ID of the template associated with the collection
    string[] collectionURIs; // The URIs associated with the collection
    uint256 totalSupply; // The total supply of tokens in the collection
    uint256 mintPrice; // The price of minting a token in the collection
    uint8 mintPerAccountLimit; // The maximum number of tokens that can be minted per wallet
    string name; // The name of the collection
    string symbol; // The symbol of the collection
    address verifier; // The address of the verifier contract
    bool isWhitelisted; // A flag indicating if the collection is whitelisted
  }

  /**
   * @notice Creates a new collection with the provided parameters.
   * @param collectionParams The parameters to create the collection.
   * @param isDynamicUri A flag indicating if the collection has dynamic URIs.
   * @param ERCimplementation The implementation type of the ERC721 contract.
   * @param merkeRoot The Merkle root of the collection.
   * @return instance The address of the created collection contract instance.
   */
  function createCollection(
    CollectionParams calldata collectionParams,
    bool isDynamicUri,
    uint8 ERCimplementation,
    bytes32 merkeRoot
  ) external returns (address instance);

  function importExternalCollection(
    uint256 _templateId,
    address _collectionAddress
  ) external;

  function addNewCollection(address _collectionAddress) external returns (uint64);

  function transferCollection(address _entity, uint64 _collectionId) external returns (uint64);

  /**
   * @notice Retrieves the ID of the last created collection.
   * @return The ID of the last created collection.
   */
  function getLastCollectionId() external view returns (uint64);

  /**
   * @notice Retrieves the address of a collection with the given collection ID.
   * @param collectionId The ID of the collection.
   * @return The address of the collection contract.
   */
  function getCollectionAddress(uint64 collectionId) external view returns (address);

  /**
   * @notice Retrieves the ID of a collection with the given entity address.
   * @param entity The Address of the entity.
   * @return The ID of the collection contract.
   */
  // function getEntityId(address entity) external view returns (uint256); 

  /// Throws if the provided URI length is invalid.
  error InvalidURILength(uint256 uriLength);

  /// Throws if the provided template ID is invalid.
  error InvalidTemplate(uint256 templateId);

  /// Throws if the provided collection price is invalid.
  error InvalidCollectionPrice(uint256 mintPrice);

  /// Throws if the caller is not the owner of the collection.
  error NotCollectionOwner(address collectionAddress);

  /// Throws if the collection contract does not support the ERC165 interface.
  error NoERC165Support(address collectionAddress);

  /// Throws if the collection contract does not support the ERC721 interface.
  error NoERC721Support(address collectionAddress);

  /// Throws if the collection address is not an external collection.
  error NotExternal(address collectionAddress);

  /// Throws if the total supply of the collection is zero.
  error TotalSupplyIsZero();

  /// Throws if the given collection ID is invalid.
  error InvalidCollection(uint64 collectionId);

  /// Throws if the given entity address is invalid.
  error InvalidEntity(address entity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

/**
 * @title ImQuarkNFT
 * @author Unbounded team
 * @notice Interface smart contract of the mQuark NFT protocol.
 */
interface ImQuarkNFT {
  /**
   * @notice Signals the minting of a new token.
   * @dev This event is emitted when a new token is created and assigned to the specified address.
   * @param tokenId ID of the newly minted token
   * @param to Address to which the token is assigned
   * @param entityId ID of the associated entity
   * @param templateId ID of the token's template
   * @param collectionId ID of the token's collection
   * @param amount Amount of tokens minted
   * @param uri URI associated with the token's metadata
   */
  event TokenMint(
    uint256 tokenId,
    address to,
    uint256 entityId,
    uint256 templateId,
    uint64 collectionId,
    uint256 amount,
    string uri
  );

  event CollectionTransferred(uint64 newCollectionId, uint64 previousCollectionId, address newEntityAddress);

  /**
   * @notice Signals the withdrawal of protocol funds.
   * @dev This event is emitted when funds are withdrawn from the protocol by the specified address.
   * @param to Address that receives the withdrawn funds
   * @param amount Amount of funds withdrawn
   * @param savedAmountOwner Amount of funds saved by the owner
   * @param totalWithdrawn Total amount of funds withdrawn so far
   */
  event WithdrawProtocol(address to, uint256 amount, uint256 savedAmountOwner, uint256 totalWithdrawn);

  /**
   * @notice Signals the withdrawal of funds.
   * @dev This event is emitted when funds are withdrawn by the specified address.
   * @param to Address that receives the withdrawn funds
   * @param amount Amount of funds withdrawn
   * @param royalty Royalty amount associated with the withdrawal
   * @param totalWithdrawn Total amount of funds withdrawn so far
   */
  event Withdraw(address to, uint256 amount, uint256 royalty, uint256 totalWithdrawn);

  /**
   * @notice Signals the update of royalty information.
   * @dev This event is emitted when the royalty percentage and receiver address are updated.
   * @param percentage Royalty percentage
   * @param receiver Address of the royalty receiver
   */
  event RoyaltyInfoUpdated(uint16 percentage, address receiver);

  /**
   * @notice Represents the subscription information for a token.
   */
  struct TokenSubscriptionInfo {
    bool isSubscribed; // Flag indicating if the token is subscribed
    string uri; // URI associated with the token
  }

  /**
   * @notice Represents royalty information for minted tokens.
   */
  struct MintRoyalty {
    uint256 royalty; // Royalty amount for the token
    uint256 withdrawnAmountByOwner; // Amount withdrawn by the owner
    uint256 withdrawnAmountByProtocol; // Amount withdrawn by the protocol
    uint256 savedAmountOwner; // Amount saved by the owner
    uint256 totalWithdrawn; // Total amount withdrawn for the token
  }

  /**
   * @notice Mints a token with the given variation ID.
   * @dev Emits an {TokenMint} event.
   * @param variationId The ID of the token variation to mint.
   */
  function mint(uint256 variationId) external payable;

  /**
   * @notice Mints a token with a specified URI and signature.
   * @dev Emits an {TokenMint} event.
   * @param signer The address of the signer for the signature verification.
   * @param signature The signature used to verify the authenticity of the minting request.
   * @param uri The URI associated with the minted token.
   * @param salt The salt value used for the minting process.
   */
  function mintWithURI(
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Mints a token with a whitelist verification using Merkle proofs.
   * @dev Emits an {TokenMint} event.
   * @param merkleProof The array of Merkle proofs used for whitelist verification.
   * @param variationId The ID of the token variation to mint.
   */
  function mintWhitelist(bytes32[] memory merkleProof, uint256 variationId) external payable;

  /**
   * @notice Mints a token with a whitelist verification, specified URI, and signature.
   * @dev Emits an {TokenMint} event.
   * @param merkleProof The array of Merkle proofs used for whitelist verification.
   * @param signer The address of the signer for the signature verification.
   * @param signature The signature used to verify the authenticity of the minting request.
   * @param uri The URI associated with the minted token.
   * @param salt The salt value used for the minting process.
   */
  function mintWithURIWhitelist(
    bytes32[] memory merkleProof,
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Subscribes an owner to a single entity for a specific token.
   * @param owner The address of the owner to subscribe.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity to subscribe to.
   * @param entitySlotDefaultUri The default URI associated with the entity slot.
   */
  function subscribeToEntity(
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata entitySlotDefaultUri
  ) external;

  /**
   * @notice Subscribes an owner to multiple entities for a specific token.
   * @param owner The address of the owner to subscribe.
   * @param tokenId The ID of the token.
   * @param entityIds The array of entity IDs to subscribe to.
   * @param entitySlotDefaultUris The array of default URIs associated with the entity slots.
   */
  function subscribeToEntities(
    address owner,
    uint256 tokenId,
    uint64[] calldata entityIds,
    string[] calldata entitySlotDefaultUris
  ) external;

  /**
   * @notice Updates the URI slot of a single token.
   * @dev The entity must sign the new URI with its wallet address.
   * @param owner The address of the token owner.
   * @param entityId The ID of the entity.
   * @param tokenId The ID of the token.
   * @param updatedUri The updated, signed URI value.
   */
  function updateURISlot(address owner, uint256 entityId, uint256 tokenId, string calldata updatedUri) external;

  /**
   * @notice Returns the entity URI for the given token ID.
   * @dev Each entity can assign slots to tokens, storing a URI that refers to something on the entity.
   * @dev Slots are viewable by other entities but modifiable only by the token owner with a valid signature from the entity.
   * @param tokenId  The ID of the token for which the entity URI is to be returned.
   * @param entityId The ID of the entity associated with the given token.
   * @return The URI of the entity slot for the given token.
   */
  function tokenEntityURI(uint256 tokenId, uint256 entityId) external view returns (string memory);
  
  // todo: add documentation
  function transferCollectionOwnership(address newOwner) external;

  /**
   * @notice Initializes the contract with the specified parameters.
   * @dev This function is used to initialize the contract's state variables.
   * @param collection The Collection object representing the collection.
   * @param collectionOwner The address of the collection owner.
   * @param controller The address of the controller.
   * @param merkleRoot The root hash of the Merkle tree used for whitelist verification.
   * @param mintRoyalty The royalty percentage to be applied during token minting.
   */
  function initilasiable(
    Collection calldata collection,
    address collectionOwner,
    address controller,
    bytes32 merkleRoot,
    uint256 mintRoyalty
  ) external;

  /**
   * @notice Transfers the entity URI of a token to a new owner with the specified URI.
   * @dev This function is used to transfer the ownership of the entity URI associated with a token.
   * @param owner The address of the new owner of the token.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @param soldUri The URI to be transferred to the new owner.
   */
  function transferTokenEntityURI(address owner, uint256 tokenId, uint256 entityId, string calldata soldUri) external;

  /**
   * @notice Resets the entity slot of a token to its default URI.
   * @dev This function is used to reset the entity slot of a token to its default URI.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @param defaultUri The default URI to be set for the entity slot.
   */
  function resetSlotToDefault(address owner, uint256 tokenId, uint256 entityId, string calldata defaultUri) external;

  /**
   * @notice Retrieves information about the collection.
   * @dev This function returns various information about the collection.
   * @return entityId The ID of the entity associated with the collection.
   * @return collectionId The ID of the collection.
   * @return mintType The type of minting allowed for the collection.
   * @return mintPerAccountLimit The maximum number of tokens that can be minted per account.
   * @return isWhitelisted A flag indicating whether the collection is whitelisted.
   * @return isFree A flag indicating whether the minting is free for the collection.
   * @return templateId The ID of the collection template.
   * @return mintCount The current count of minted tokens in the collection.
   * @return totalSupply The total supply of tokens in the collection.
   * @return mintPrice The price of minting a token in the collection.
   * @return collectionURIs An array of URIs associated with the collection.
   * @return verifier The address of the verifier for the collection.
   */
  function getCollectionInfo()
    external
    view
    returns (
      uint256 entityId,
      uint64 collectionId,
      uint8 mintType,
      uint8 mintPerAccountLimit,
      bool isWhitelisted,
      bool isFree,
      uint256 templateId,
      uint256 mintCount,
      uint256 totalSupply,
      uint256 mintPrice,
      string[] memory collectionURIs,
      address verifier
    );

  /**
   * @notice Withdraws the available balance for the caller.
   */
  function withdraw() external;

  /**
   * @notice Allows the protocol to withdraw its available balance.
   */
  function protocolWithdraw() external;

  /// Thrown when attempting to access an invalid variation.
  error InvalidVariation(string reason, uint256 variationId);
  /// Thrown when the collection URI is empty.
  error CollectionURIZero(string reason);
  /// Thrown when the collection is sold out and no more tokens can be minted.
  error CollectionIsSoldOut(string reason);
  /// Thrown when attempting to perform a mint operation with an incorrect mint type.
  error WrongMintType(string reason, uint8 mintType);
  /// Thrown when the payment is invalid or insufficient.
  error InvalidPayment(string reason);
  /// Thrown when no payment is required for the minting operation.
  error NoPaymentRequired(string reason);
  /// Thrown when the verification process fails.
  error VerificationFailed(string reason);
  /// Thrown when the entity is not whitelisted.
  error NotWhitelisted(string reason);
  /// Thrown when the caller is not the owner of the specified token.
  error NotOwner(string reason, uint256 tokenId);
  /// Thrown when attempting to access the entity slot of a token that is not subscribed to any entity.
  error Unsubscribed(string reason, uint256 tokenId, uint256 entityId);
  /// Thrown when the signature provided is not operative.
  error InoperativeSignature(string reason);
  /// Thrown when the caller is not authorized to perform the operation.
  error NotAuthorized(string reason);
  /// Thrown when the caller has insufficient balance to perform the operation.
  error InsufficientBalance(string reason);
  /// Thrown when the minting limit has been reached and no more tokens can be minted for an account.
  error MintLimitReached(string reason);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ImQuarkEntity.sol";

interface ImQuarkRegistry {
  /**
   * Emitted when the subscriber contract address is set.
   *
   * @param subscriber The address of the subscriber contract.
   */
  event SubscriberSet(address subscriber);
  /**
   * Emitted when the controller contract address is set.
   *
   * @param controller The address of the controller contract.
   */
  event ControllerSet(address controller);
  /**
   * Emitted when the implementation contract address is set for a specific ID.
   *
   * @param id             The ID of the implementation.
   * @param implementation The address of the implementation contract.
   */
  event ImplementationSet(uint256 id, address implementation);
  /**
   * Emitted when an entity is registered to the contract.
   *
   * @param entity                The address of the entity.
   * @param contractAddress       The address of the contract.
   * @param entityId              The ID of the entity.
   * @param entityName            The name of the entity.
   * @param description           The description of the entity.
   * @param thumbnail             The thumbnail image URL of the entity.
   * @param entityDefaultSlotURI  The default URI for the entity's slots.
   * @param subscriptionPrice     The price for the entity's subscription slot.
   */
  event EntityRegistered(
    address entity,
    address contractAddress,
    uint256 entityId,
    string entityName,
    string description,
    string thumbnail,
    string entityDefaultSlotURI,
    uint256 subscriptionPrice
  );
  
  /**
   * Represents an entity registered in the contract.
   */
  struct Entity {
    // The creator address of the entity
    address creator;
    // The createed contract address of the entity's creator
    address contractAddress;
    // The unique ID of the entity
    uint256 id;
    // The name of the entity
    string name;
    // The description of the entity
    string description;
    // The thumbnail image of the entity
    string thumbnail;
    // The default URI for the entity's tokens
    string entitySlotDefaultURI;
  }

  /**
   * Sets the address of the controller.
   *
   * @param controller The address of the controller contract.
   */
  function setControllerAddress(address controller) external;

  /**
   * Sets the address of the subscriber.
   *
   * @param subscriber The address of the subscriber contract.
   */
  function setSubscriberAddress(address subscriber) external;

  /**
   * Sets the address of the implementation for a specific ID.
   *
   * @param id            The ID of the implementation.
   * @param implementation The address of the implementation contract.
   */
  function setImplementationAddress(uint8 id, address implementation) external;

  /**
   * Registers an entity to the contract.
   *
   * @param entityName            The name of the entity.
   * @param description           The description of the entity.
   * @param thumbnail             The URL of the entity's thumbnail image.
   * @param entitySlotDefaultURI  The default URI for the entity's tokens.
   * @param subscriptionPrice     The price of the entity's subscription slot.
   */
  function registerEntity(
    string calldata entityName,
    string calldata description,
    string calldata thumbnail,
    string calldata entitySlotDefaultURI,
    uint256 subscriptionPrice
  ) external;

  /**
   * Returns the entity ID for a given contract address.
   *
   * @param contractAddress The address of the contract.
   * @return                The entity ID.
   */
  function getEntityId(address contractAddress) external view returns (uint256);

  /**
   * Returns the contract address for a given entity ID.
   *
   * @param entityId The ID of the entity.
   * @return         The contract address.
   */
  function getEntityAddress(uint256 entityId) external view returns (address);

  /**
   * Returns the details of a registered entity.
   *
   * @param entityId               The ID of the entity.
   * @return contractAddress       Contract address
   * @return creator               Creator address
   * @return id                    ID
   * @return name                  Name
   * @return description           Description
   * @return thumbnail             Thumbnail
   * @return entitySlotDefaultURI  Slot default URI
   * */
  function getRegisteredEntity(
    uint256 entityId
  )
    external
    view
    returns (
      address contractAddress,
      address creator,
      uint256 id,
      string memory name,
      string memory description,
      string memory thumbnail,
      string memory entitySlotDefaultURI
    );

  /**
   * Returns the subscriber contract address.
   *
   * @return The subscriber contract address.
   */
  function getSubscriber() external view returns (address);

  /**
   * Returns the controller contract address.
   *
   * @return The controller contract address.
   */
  function getController() external view returns (address);

  /**
   * Returns the price of the entity's subscription slot.
   *
   * @param entityId The ID of the entity.
   * @return          The price of the subscription slot.
   */
  function getEntitySubscriptionPrice(uint256 entityId) external view returns (uint256);

  /**
   * Returns the last entity ID.
   *
   * @return The last entity ID.
   */
  function getLastEntityId() external view returns (uint256);

  /**
   * Returns the implementation contract address for a specific ID.
   *
   * @param implementation The ID of the implementation.
   * @return                The implementation contract address.
   */
  function getImplementation(uint8 implementation) external view returns (address);

  /**
   * Returns the controller and subscriber contract addresses.
   *
   * @return The controller and subscriber contract addresses.
   */
  function getControllerAndSubscriber() external view returns (address, address);

  // todo
  // todo
  function getEntityIsRegistered(address _contractAddress) external view returns (bool);

  /// Throws if the given address is not registered.
  error EntityAddressNotRegistered(address entity);

  /// Throws if the given ID is not registered.
  error EntityIdNotRegistered(uint256 entity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {BuyOrder, SellOrder} from "../lib/mQuarkStructs.sol";

/**
 * @title ImQuarkSubscriber
 * @author Unbounded team
 * @notice Interface smart contract of the mQuark Subscriber.
 */
interface ImQuarkSubscriber {
  /**
   * @notice Emitted when protocol funds are withdrawn to a specified address.
   * @param to The address to which the funds are withdrawn.
   * @param amount The amount of funds withdrawn.
   */
  event WithdrawProtocol(address to, uint256 amount);

  /**
   * @notice Emitted when funds are withdrawn from an entity to a specified address.
   * @param entityId The ID of the entity from which funds are withdrawn.
   * @param to The address to which the funds are withdrawn.
   * @param amount The amount of funds withdrawn.
   */
  event Withdraw(uint256 entityId, address to, uint256 amount);

  /**
   * @notice Emitted when the royalty percentage is set.
   * @param royalty The new royalty percentage.
   */
  event RoyaltySet(uint256 royalty);

  /**
   * @notice Emitted when the registry contract address is set.
   * @param registry The address of the registry contract.
   */
  event RegistrySet(address registry);

  /**
   * @notice Emitted when the controller contract address is set.
   * @param controller The address of the controller contract.
   */
  event ControllerSet(address controller);

  /**
   * @notice Emitted when the imported contracts address is set.
   * @param importedContracts The address of the imported contracts contract.
   */
  event ImportedContractsSet(address importedContracts);

  /**
   * @notice Emitted when a token is unlocked.
   * @param tokenId The ID of the unlocked token.
   * @param tokenContract The address of the token contract.
   * @param to The address to which the unlocked token is transferred.
   * @param amount The amount of unlocked tokens transferred.
   */
  event Unlocked(uint256 tokenId, address tokenContract, address to, uint256 amount);

  /**
   * @notice Emitted when the URI slot of a token is updated.
   * @param entityId The ID of the entity associated with the token.
   * @param tokenContract The address of the token contract.
   * @param tokenId The ID of the token whose URI slot is updated.
   * @param updatedUri The updated URI value.
   */
  event URISlotUpdated(uint256 entityId, address tokenContract, uint256 tokenId, string updatedUri);

  /**
   * @notice Emitted when multiple subscriptions are made in batch.
   * @param tokenId The ID of the token for which the subscriptions are made.
   * @param tokenContract The address of the token contract.
   * @param subscriptionIds The IDs of the subscriptions made.
   * @param to The address to which the token is subscribed.
   * @param defaultUris The default URIs associated with the subscriptions.
   * @param amount The total amount paid for the subscriptions.
   */
  event SubscribedBatch(
    uint256 tokenId,
    address tokenContract,
    uint64[] subscriptionIds,
    address to,
    string[] defaultUris,
    uint256 amount
  );

  /**
   * @notice Emitted when a single subscription is made.
   * @param tokenId The ID of the token for which the subscription is made.
   * @param tokenContract The address of the token contract.
   * @param subscriptionId The ID of the subscription made.
   * @param to The address to which the token is subscribed.
   * @param defaultUri The default URI associated with the subscription.
   * @param amount The amount paid for the subscription.
   */
  event Subscribed(
    uint256 tokenId,
    address tokenContract,
    uint256 subscriptionId,
    address to,
    string defaultUri,
    uint256 amount
  );

  /**
   * @notice Emitted when the signer address is set for an entity.
   * @param entityId The ID of the entity for which the signer address is set.
   * @param signer The address of the signer.
   */
  event SignerSet(uint256 entityId, address signer);

  /**
   * @notice Emitted when the subscription price is set for an entity.
   * @param entityId The ID of the entity for which the subscription price is set.
   * @param price The subscription price.
   */
  event SubscriptionPriceSet(uint256 entityId, uint256 price);

  /**
   * @notice Emitted when the default URI is set for an entity.
   * @param entityId The ID of the entity for which the default URI is set.
   * @param defaultURI The default URI.
   */
  event DefaultURISet(uint256 entityId, string defaultURI);

  /**
   * @notice Emitted when an entity is initialized.
   * @param contractAddress The address of the entity contract.
   * @param entityId The ID of the entity.
   * @param signer The address of the entity signer.
   * @param defaultURI The default URI associated with the entity.
   * @param price The subscription price of the entity.
   */
  event EntityInitialized(address contractAddress, uint256 entityId, address signer, string defaultURI, uint256 price);

  /**
   * @notice Emitted when the entity URI of a token is transferred to another token.
   * @param fromTokenContract The address of the token contract from which the entity URI is transferred.
   * @param fromTokenId The ID of the token from which the entity URI is transferred.
   * @param toTokenContract The address of the token contract to which the entity URI is transferred.
   * @param toTokenId The ID of the token to which the entity URI is transferred.
   * @param entityId The ID of the entity associated with the entity URI.
   * @param price The price associated with the entity URI transfer.
   * @param uri The entity URI being transferred.
   * @param from The address from which the entity URI is transferred.
   * @param to The address to which the entity URI is transferred.
   */
  event TokenEntityUriTransferred(
    address fromTokenContract,
    uint256 fromTokenId,
    address toTokenContract,
    uint256 toTokenId,
    uint256 entityId,
    uint256 price,
    string uri,
    address from,
    address to
  );

  /**
   * @dev Represents the configuration of a collection.
   */
  struct Collection {
    uint256 entityId; // The ID of the entity associated with the collection.
    uint256 templateId; // The ID of the template.
    bool free; // Indicates if the collection is free.
    bool isExternal; // Indicates if the collection is external.
    address contractAddress; // The address of the collection's contract.
  }
  /**
   * @dev Represents the configuration of an entity.
   */
  struct EntityConfig {
    uint256 entityId; // The ID of the entity.
    uint256 subscriptionPrice; // The subscription price for the entity.
    address signer; // The address of the entity's signer.
    string defaultURI; // The default URI for the entity's tokens.
    bool set; // Indicates if the entity configuration is set.
  }

  /**
   * Initializes an entity with the specified configuration.
   *
   * @param contract_ The address of the entity's contract.
   * @param entityId The ID of the entity.
   * @param signer The address of the entity's signer.
   * @param defaultURI The default URI for the entity's tokens.
   * @param price The subscription price for the entity.
   */
  function initializeEntity(
    address contract_,
    uint256 entityId,
    address signer,
    string calldata defaultURI,
    uint256 price
  ) external;

  /**
   * @notice Sets the address of the registry contract.
   * @param registry The address of the registry contract.
   */
  function setRegistryAddress(address registry) external;

  /**
   * @notice Sets the royalty amount for the contract.
   * @param royalty The royalty amount to be set.
   */
  function setRoyalty(uint256 royalty) external;

  /**
   * @notice Sets the address of the controller contract.
   * @param controller The address of the controller contract.
   */
  function setControllerAddress(address controller) external;

  /**
   * @notice Sets the address of the external collection contract.
   * @param externalCollection The address of the external collection contract.
   */
  function setImportedContractsAddress(address externalCollection) external;

  /**
   * @notice Sets the default URI for a specific entity.
   * @param entityId The ID of the entity.
   * @param defaultURI The default URI to be set.
   */
  function setDefaultURI(uint256 entityId, string calldata defaultURI) external;

  /**
   * @notice Sets the subscription price for a specific entity.
   * @param entityId The ID of the entity.
   * @param price The subscription price to be set.
   */
  function setSubscriptionPrice(uint256 entityId, uint256 price) external;

  /**
   * @notice Sets the signer address for a specific entity.
   * @param entityId The ID of the entity.
   * @param signer The signer address to be set.
   */
  function setSigner(uint256 entityId, address signer) external;

  /**
   * @notice Sets the collection details.
   * @param free Whether the collection is free or not.
   * @param external_ Whether the collection is external or not.
   * @param entityId The ID of the entity associated with the collection.
   * @param templateId The template ID of the collection.
   * @param collectionAddress The address of the collection contract.
   */
  function setCollection(
    bool free,
    bool external_,
    uint256 entityId,
    uint256 templateId,
    address collectionAddress
  ) external;

  /**
   * @notice Subscribes to a specific subscription of a token.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @param subscriptionId The ID of the subscription.
   */
  function subscribe(uint256 tokenId, address tokenContract, uint64 subscriptionId) external payable;

  /**
   * @notice Subscribes to multiple subscriptions of a token.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @param subscriptionIds An array of subscription IDs.
   */
  function subscribeBatch(uint256 tokenId, address tokenContract, uint64[] calldata subscriptionIds) external payable;

  /**
   * @notice Unlocks a token by providing payment.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   */
  function unlockToken(uint256 tokenId, address tokenContract) external payable;

  /**
   * @notice Transfers the token's entity URI from the seller to the buyer.
   * @dev Requires valid signatures from both the seller and the buyer.
   * @param seller The sell order containing the seller's information.
   * @param buyer The buy order containing the buyer's information.
   * @param sellerSignature The signature of the seller.
   * @param buyerSignature The signature of the buyer.
   */
  function transferTokenEntityURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable;

  /**
   * @notice Updates the URI slot with the provided update information.
   * @dev Requires a valid signature.
   * @param signature The signature of the update.
   * @param updateInfo The update information.
   */
  function updateURISlot(bytes calldata signature, bytes calldata updateInfo) external;

  /**
   * @notice Checks if a token is subscribed to a specific subscription.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @param subscriptionId The ID of the subscription.
   * @return A boolean indicating whether the token is subscribed to the specified subscription or not.
   */
  function getIsSubscribed(uint256 tokenId, address tokenContract, uint64 subscriptionId) external view returns (bool);

  /**
   * @notice Retrieves the configuration of an entity.
   * @param entityId The ID of the entity.
   * @return entityId_ The ID of the entity.
   * @return subscriptionPrice The subscription price of the entity.
   * @return defaultURI The default URI of the entity.
   * @return uriSet The URI set status of the entity.
   * @return signer The address of the signer for the entity.
   */
  function getEntityConfig(
    uint256 entityId
  )
    external
    view
    returns (uint256 entityId_, uint256 subscriptionPrice, string memory defaultURI, bool uriSet, address signer);

  /**
   * @notice Retrieves the details of a collection.
   * @param contractAddress The address of the collection contract.
   * @return entityId The ID of the entity associated with the collection.
   * @return templateId The template ID of the collection.
   * @return free The free status of the collection.
   * @return isExternal The external status of the collection.
   * @return collectionAddress The address of the collection.
   */
  function getCollection(
    address contractAddress
  )
    external
    view
    returns (
      uint256 entityId, 
      uint256 templateId,
      bool free, 
      bool isExternal,
      address collectionAddress
    );

  /**
   * @notice Checks if a token is unlocked.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @return A boolean indicating whether the token is unlocked or not.
   */
  function getIsUnlocked(uint256 tokenId, address tokenContract) external view returns (bool);

  /**
   * @notice Retrieves the balance of an entity.
   * @param entityId The ID of the entity.
   * @return The balance of the entity.
   */
  function getEntityBalance(uint256 entityId) external view returns (uint256);

  /**
   * @notice Checks if an address is registered as an entity.
   * @param address_ The address to check.
   * @return A boolean indicating whether the address is registered as an entity or not.
   */
  function getIsAddressRegisteredAsEntity(address address_) external view returns (bool);

  /**
   * @notice Calculates the total price for a batch subscription.
   * @param subscriptionIds An array of subscription IDs.
   * @return The total price for the batch subscription.
   */
  function calculateBatchSubscriptionPrice(uint64[] calldata subscriptionIds) external view returns (uint256);

  /**
   * @notice Withdraws funds from the entity balance.
   * @param entityId The ID of the entity.
   * @param amount The amount to withdraw.
   */
  function withdraw(uint256 entityId, uint256 amount) external;

  /**
   * @notice Withdraws protocol funds.
   * @param amount The amount to withdraw.
   */
  function withdrawProtocol(uint256 amount) external;

  /// The caller is unauthorized to perform the operation
  error Unauthorized(address caller);

  /// The caller is not the registry address
  error NotRegistry(address caller);

  /// The caller is not the owner of the entity with the specified ID
  error NotEntityOwner(uint256 entityId);

  /// The caller is not the owner of the collection with the specified address
  error NotCollectionOwner(address collectionAddress);

  /// The subscription with the specified ID is already subscribed to by the given token and token contract
  error AlreadySubscribed(uint64 subscriptionId, address InvalidTokenContract, uint256 tokenId);

  /// The entity with the specified ID does not exist
  error Unexist(uint256 entityId);

  /// The token with the specified ID is locked by the given contract address
  error TokenLocked(address contractAddress, uint256 tokenId);

  /// The payment amount is invalid
  error InvalidPayment(uint256 amount);

  /// The token contract address is invalid
  error InvalidTokenContract(address contractAddress);

  /// The entity with the specified ID is not subscribed to
  error Unsubscribed(uint256 entityId);

  /// Verification of signature failed
  error VerificationFailed();

  /// The collection is unknown
  error UnknownCollection();

  /// The collection is not free
  error NotFreeCollection();

  /// The token with the specified ID is already unlocked
  error AlreadyUnlocked(uint256 tokenId);

  /// The provided signature is inoperative
  error SignatureInoperative();

  /// The balance is insufficient to perform the operation
  error InsufficientBalance();

  /// The caller is not the owner of the token with the specified ID
  error NotOwner(uint256 tokenId);

  /// The caller is unauthorized to transfer the token
  error UnauthorizedToTransfer();

  /// The price does not match the expected value
  error PriceMismatch();

  /// The sent amount is invalid
  error InvalidSentAmount();

  /// The token does not match the expected value
  error TokenMismatch();

  /// The given entity ID does not match the expected value
  error GivenEntityIdMismatch();

  /// The seller address does not match the expected value
  error SellerAddressMismatch();

  /// The URI does not match the expected value
  error UriMismatch();

  /// The seller is not the signer
  error SellerIsNotTheSigner();

  /// The buyer is not the signer
  error BuyerIsNotTheSigner();

  /// Failed to send Ether during an operation
  error FailedToSentEther();

  /// The collection at the specified token contract address is invalid
  error InvalidCollection(address tokenContract);

  /// The royalty value is too high
  error RoyaltyTooHigh();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ImQuarkTemplate {
  /**
   * @notice Emitted when a new category is created.
   * @param category The name of the category.
   * @param id The ID of the category.
   * @param selector The selector of the category.
   * @param uri The URI of the category.
   */
  event CategoryCreated(string category, uint256 id, bytes4 selector, string uri);
  /**
   * @notice Emitted when a new template is created.
   * @param templateId The ID of the created template.
   * @param uri The URI of the template.
   */
  event TemplateCreated(uint256 templateId, string uri);
  /**
   * @notice Emitted when categories are set for a group of templates.
   * @param category The name of the category.
   * @param templateIds The IDs of the templates associated with the category.
   */
  event CategoriesSet(string category, uint256[] templateIds);

  /**
   * @notice Emitted when a template is removed from a category.
   * @param category The name of the category.
   * @param templateId The ID of the removed template.
   */
  event CategoryRemoved(string category, uint256 templateId);

  struct Category {
    uint256 id; // The ID of the category
    bytes4 selector; // The selector of the category
    string name; // The name of the category
    string uri; // The URI of the category
  }

  /**
   * @notice Creates a new template with the given URI, which will be inherited by collections.
   * @param uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata uri) external;

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   * @param uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata uris) external;

  /**
   * @notice Creates a new category with the given name and URI.
   * @param name The name of the category.
   * @param uri The metadata URI that will represent the category.
   */
  function createCategory(string calldata name, string calldata uri) external;

  /**
   * @notice Creates multiple categories with the given names and URIs.
   * @param names The names of the categories.
   * @param uris The metadata URIs that will represent the categories.
   */
  function createBatchCategory(string[] calldata names, string[] calldata uris) external;

  /**
   * @notice Sets the category for multiple templates.
   * @param category The name of the category.
   * @param templateIds_ The IDs of the templates to assign to the category.
   */
  function setTemplateCategory(string calldata category, uint256[] calldata templateIds_) external;

  /**
   * @notice Removes a category assignment from a template.
   * @param category The name of the category.
   * @param templateId The ID of the template to remove from the category.
   */
  function removeCategoryFromTemplate(string memory category, uint256 templateId) external;

  /**
   * @notice Retrieves all template IDs assigned to a specific category.
   * @param category The name of the category.
   * @return An array of template IDs assigned to the category.
   */
  function getAllCategoryTemplates(string memory category) external view returns (uint256[] memory);

  /**
   * @notice Retrieves a batch of template IDs assigned to a specific category based on an index range.
   * @param category The name of the category.
   * @param startIndex The start index of the batch.
   * @param batchLength The length of the batch.
   * @return An array of template IDs assigned to the category within the specified index range.
   */
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) external view returns (uint256[] memory);

  /**
   * @notice Retrieves the categories associated with a template based on its ID.
   * @param templateId The ID of the template.
   * @return An array of category names associated with the template.
   */
  function getTemplatesCategory(uint256 templateId) external view returns (string[] memory);

  /**
   * @notice Retrieves the number of templates assigned to a specific category.
   * @param category The name of the category.
   * @return The number of templates assigned to the category.
   */
  function getCategoryTemplateLength(string calldata category) external view returns (uint256);

  /**
   * @notice Retrieves category information by its name.
   * @param name The name of the category.
   * @return id The ID of the category.
   * @return selector The selector of the category.
   * @return uri The URI of the category.
   */
  function getCategoryByName(
    string calldata name
  ) external view returns (uint256 id, bytes4 selector, string memory uri);

  /**
   * @notice Retrieves category information by its ID.
   * @param id The ID of the category.
   * @return selector The selector of the category.
   * @return name The name of the category.
   * @return uri The URI of the category.
   */
  function getCategoryById(uint256 id) external view returns (bytes4 selector, string memory name, string memory uri);

  /**
   * @notice Retrieves category information by its selector.
   * @param selector The selector of the category.
   * @return id The ID of the category.
   * @return name The name of the category.
   * @return uri The URI of the category.
   */
  function getCategoryBySelector(
    bytes4 selector
  ) external view returns (uint256 id, string memory name, string memory uri);

  /**
   * @notice Retrieves the metadata URI of a template based on its ID.
   * @param templateId The ID of the template.
   * @return The metadata URI of the template.
   */
  function templateUri(uint256 templateId) external view returns (string memory);

  /**
   * @notice Retrieves the ID of the last created template.
   * @return The ID of the last created template.
   */
  function getLastTemplateId() external view returns (uint256);

  /**
   * @notice Checks if a template with the given ID exists.
   * @param templateId The ID of the template.
   * @return exist A boolean indicating if the template exists.
   */
  function isTemplateIdExist(uint256 templateId) external view returns (bool exist);

  /// Throws if a limit has been exceeded.
  error ExceedsLimit();
  /// Throws if there is a mismatch in the length of arrays.
  error ArrayLengthMismatch();
  /// Throws if the specified category does not exist.
  error UnexistingCategory();
  /// Throws if the specified template does not exist.
  error UnexistingTemplate();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IOwnable {
  function owner() external view returns (address);
  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

struct CreateCollectionParams {
  uint256 templateId;
  uint256 collectionPrice;
  uint256 totalSupply;
}

struct Collection {
  uint256 entityId;
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
  // the token id whose entity URI will be sold
  uint256 fromTokenId;
  // the entity's id whose owner is selling the URI
  uint256 entityId;
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
  // the token id whose entity URI will be sold
  uint256 fromTokenId;
  // the "to" token contract address
  address toContractAddress;
  // the token id whose entity URI will be sold
  uint256 toTokenId;
  // the entity's id whose owner is selling the URI
  uint256 entityId;
  // the URI that will be bought
  string slotUri;
  // the price required for the URI
  uint256 buyPrice;
  bytes salt;
}

// SPDX-License-Identifier: BUSL-1.1
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ImQuarkNFT.sol";
import "./interfaces/ImQuarkRegistry.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkSubscriber.sol";
import "./interfaces/IImportedContracts.sol";
import "./utils/noDelegateCall.sol";

contract mQuarkSubscriber is AccessControl, ImQuarkSubscriber, ReentrancyGuard, NoDelegateCall {
  //* =============================== MAPPINGS ======================================================== *//

  // Mapping to track inoperative signatures.
  // The keys are the signature byte arrays and the values indicate whether a signature is considered inoperative.
  mapping(bytes => bool) private s_inoperativeSignatures;

  // Mapping to store collections associated with addresses.
  // The keys are addresses and the values are the corresponding Collection struct.
  mapping(address => Collection) private s_collections;

  // Mapping to track registered entities.
  // The keys are addresses and the values indicate whether an entity is registered or not.
  mapping(address => bool) private s_registeredEntities;

  // Mapping to track the balance of each entity.
  // The keys are entity IDs and the values represent the balance associated with each entity.
  mapping(uint256 => uint256) private s_entityBalance;

  // Mapping to store the configuration of each entity.
  // The keys are entity IDs, and the values represent the configuration associated with each entity.
  mapping(uint256 => EntityConfig) private s_entityConfig;

  // Mapping to track the unlocked status of collection tokens.Locked tokens cannot be subscribed to entities.
  // The keys of the outer mapping represent token contract address, and the keys of the inner mapping represent token IDs.
  mapping(address => mapping(uint256 => bool)) private s_unlocked;

  // Mapping to track the subscribers for each entity.
  // The keys of the outer mapping represent entity IDs.
  // The keys of the middle mapping represent token contract addresses.
  // The keys of the inner mapping represent token IDs.
  // The boolean values indicate the subscriber status for the corresponding entity.
  mapping(uint256 => mapping(address => mapping(uint256 => bool))) private s_entitySubscribers;

  //* =============================== VARIABLES ======================================================= *//
  // This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  // Registry contract address.
  ImQuarkRegistry public s_registry;

  // Controller contract address.
  ImQuarkController public s_controller;

  // ImportedContracts contract address.
  IImportedContracts public s_importedContracts;

  // The constant value for royalty divisor
  uint256 public constant ROYALTY_DIVISOR = 100000;

  // The royalty percentage for the subscription.
  uint256 public s_royalty;

  // The protocol balance.
  uint256 public s_protocolBalance;

  //* =============================== MODIFIERS ======================================================= *//

  modifier onlyEntityContract() {
    if (!s_registeredEntities[msg.sender]) revert Unauthorized(msg.sender);
    _;
  }

  modifier onlyRegistry() {
    if (msg.sender != address(s_registry)) revert NotRegistry(msg.sender);
    _;
  }

  modifier onlyEntityOwner(uint256 _entityId) {
    _onlyEntityOwner(_entityId);
    _;
  }

  //* =============================== CONSTRUCTOR ===================================================== *//
  constructor(ImQuarkRegistry _registry, ImQuarkController _controller, uint256 _royalty) {
    if (_royalty > 3000 || _royalty == 0) revert RoyaltyTooHigh();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
    s_registry = _registry;
    s_controller = _controller;
    s_royalty = _royalty;
  }

  //* =============================== FUNCTIONS ======================================================= *//
  // * ============== EXTERNAL =========== *//
  /**
   * @dev Sets the address of the registry contract.
   * This function can only be called by an address with the CONTROL_ROLE role.
   *
   * @param _registry The address of the registry contract to be set
   */
  function setRegistryAddress(address _registry) external onlyRole(CONTROL_ROLE) {
    s_registry = ImQuarkRegistry(_registry);
    emit RegistrySet(_registry);
  }

  /**
   * @dev Sets the royalty percentage for the subcription.
   * This function can only be called by an address with the CONTROL_ROLE role.
   *
   * @param _royalty The royalty percentage to be set
   * @dev The royalty percentage must be between 1 and 3000 (inclusive), and it cannot be set to 0.
   */
  function setRoyalty(uint256 _royalty) external onlyRole(CONTROL_ROLE) {
    if (_royalty > 3000 || _royalty == 0) revert RoyaltyTooHigh();
    s_royalty = _royalty;
    emit RoyaltySet(_royalty);
  }

  /**
   * @dev Sets the address of the controller contract for the collection.
   * This function can only be called by an address with the CONTROL_ROLE role.
   *
   * @param _controller The address of the controller contract to be set
   */
  function setControllerAddress(address _controller) external onlyRole(CONTROL_ROLE) {
    s_controller = ImQuarkController(_controller);
    emit ControllerSet(_controller);
  }

  /**
   * @dev Sets the address of the imported contracts interface contract.
   * This function can only be called by an address with the CONTROL_ROLE role.
   *
   * @param _importedContracts The address of the imported contracts interface contract to be set
   */
  function setImportedContractsAddress(address _importedContracts) external onlyRole(CONTROL_ROLE) {
    s_importedContracts = IImportedContracts(_importedContracts);
    emit ImportedContractsSet(_importedContracts);
  }

  /**
   * @dev Initializes the configuration of an entity in the registry contract.
   * This function can only be called by the registry contract.
   *
   * @param _contract The address of the entity contract to be initialized
   * @param _entityId The ID of the entity to be initialized
   * @param _signer The address of the entity's signer
   * @param _defaultURI The default URI of the entity
   * @param _price The subscription price of the entity
   */
  function initializeEntity(
    address _contract,
    uint256 _entityId,
    address _signer,
    string calldata _defaultURI,
    uint256 _price
  ) external onlyRegistry {
    s_registeredEntities[_contract] = true;
    EntityConfig memory m_temp = s_entityConfig[_entityId];
    m_temp.entityId = _entityId;
    m_temp.signer = _signer;
    m_temp.defaultURI = _defaultURI;
    m_temp.subscriptionPrice = _price;
    m_temp.set = true;
    s_entityConfig[_entityId] = m_temp;
  }

  /**
   * @dev Sets the default URI of an entity.
   * This function can only be called by the owner of the entity.
   *
   * @param _entityId The ID of the entity to set the default URI for
   * @param _defaultURI The new default URI to be set
   */
  function setDefaultURI(
    uint256 _entityId,
    string calldata _defaultURI
  ) external noDelegateCall onlyEntityOwner(_entityId) {
    s_entityConfig[_entityId].defaultURI = _defaultURI;
    emit DefaultURISet(_entityId, _defaultURI);
  }

  /**
   * @dev Sets the subscription price of an entity.
   * This function can only be called by the owner of the entity.
   *
   * @param _entityId The ID of the entity to set the subscription price for
   * @param _price The new subscription price to be set
   */
  function setSubscriptionPrice(uint256 _entityId, uint256 _price) external noDelegateCall onlyEntityOwner(_entityId) {
    s_entityConfig[_entityId].subscriptionPrice = _price;
    emit SubscriptionPriceSet(_entityId, _price);
  }

  /**
   * @dev Sets the signer address for an entity.
   * This function can only be called by the owner of the entity.
   *
   * @param _entityId The ID of the entity to set the signer address for
   * @param _signer The new signer address to be set
   */
  function setSigner(uint256 _entityId, address _signer) external noDelegateCall onlyEntityOwner(_entityId) {
    s_entityConfig[_entityId].signer = _signer;
    emit SignerSet(_entityId, _signer);
  }

  /**
   * @dev Sets the configuration for a collection.
   * This function can only be called by the entity contract.
   *
   * @param _free Boolean indicating if the collection is free
   * @param _external Boolean indicating if the collection is external
   * @param _entityId The ID of the entity the collection belongs to
   * @param _templateId The ID of the template associated with the collection
   * @param _collectionAddress The address of the collection contract
   */
  function setCollection(
    bool _free,
    bool _external,
    uint256 _entityId,
    uint256 _templateId,
    address _collectionAddress
  ) external onlyEntityContract {
    Collection memory m_collection;

    m_collection.entityId = _entityId;
    m_collection.templateId = _templateId;
    m_collection.free = _free;
    m_collection.contractAddress = _collectionAddress;
    m_collection.isExternal = _external;

    s_collections[_collectionAddress] = m_collection;
  }

  /**
   * @dev Allows a user to subscribe to a collection by paying the subscription price.
   * This function is non-reentrant and can't be called via delegate call.
   *
   * @param _tokenId The ID of the token being subscribed to
   * @param _tokenContract The address of the token contract
   * @param _subscriptionId The ID of the subscription being purchased
   */
  function subscribe(
    uint256 _tokenId,
    address _tokenContract,
    uint64 _subscriptionId
  ) external payable nonReentrant noDelegateCall {
    Collection memory m_collection = s_collections[_tokenContract];
    if (m_collection.contractAddress == address(0)) revert InvalidCollection(_tokenContract);
    EntityConfig memory m_entityConfig = s_entityConfig[_subscriptionId];
    if (s_entitySubscribers[_subscriptionId][_tokenContract][_tokenId])
      revert AlreadySubscribed(_subscriptionId, _tokenContract, _tokenId);
    if (m_entityConfig.set == false) revert Unexist(_subscriptionId);
    if (m_collection.free) {
      if (!s_unlocked[_tokenContract][_tokenId]) revert TokenLocked(_tokenContract, _tokenId);
    }
    if (msg.value != m_entityConfig.subscriptionPrice) revert InvalidPayment(msg.value);
    s_entitySubscribers[_subscriptionId][_tokenContract][_tokenId] = true;

    if (!m_collection.isExternal) {
      ImQuarkNFT(_tokenContract).subscribeToEntity(msg.sender, _tokenId, _subscriptionId, m_entityConfig.defaultURI);
    } else {
      s_importedContracts.subscribeToEntity(
        _tokenContract,
        msg.sender,
        _tokenId,
        _subscriptionId,
        m_entityConfig.defaultURI
      );
    }

    uint256 m_cut = (msg.value * s_royalty) / ROYALTY_DIVISOR;
    s_entityBalance[_subscriptionId] += (msg.value - m_cut);
    s_protocolBalance += m_cut;
    emit Subscribed(_tokenId, _tokenContract, _subscriptionId, msg.sender, m_entityConfig.defaultURI, msg.value);
  }

  /**
   * @dev Allows a user to subscribe to multiple subscriptions in a batch by paying the total subscription price.
   * This function is non-reentrant and can't be called via delegate call.
   *
   * @param _tokenId The ID of the token being subscribed to
   * @param _tokenContract The address of the token contract
   * @param _subscriptionIds An array of subscription IDs being purchased
   */
  function subscribeBatch(
    uint256 _tokenId,
    address _tokenContract,
    uint64[] calldata _subscriptionIds
  ) external payable nonReentrant noDelegateCall {
    Collection memory m_collection = s_collections[_tokenContract];
    if (m_collection.contractAddress == address(0)) revert InvalidCollection(_tokenContract);
    if (m_collection.free) {
      if (!s_unlocked[_tokenContract][_tokenId]) revert TokenLocked(_tokenContract, _tokenId);
    }
    if (calculateBatchSubscriptionPrice(_subscriptionIds) != msg.value) revert InvalidPayment(msg.value);
    string[] memory m_uris = new string[](_subscriptionIds.length);
    uint256 m_numberOfIds = _subscriptionIds.length;

    for (uint i = 0; i < m_numberOfIds; ) {
      if (s_entityConfig[_subscriptionIds[i]].set == false) revert Unexist(_subscriptionIds[i]);
      m_uris[i] = s_entityConfig[_subscriptionIds[i]].defaultURI;
      s_entityBalance[_subscriptionIds[i]] += s_entityConfig[_subscriptionIds[i]].subscriptionPrice;
      unchecked {
        ++i;
      }
    }
    uint256 m_cut = (msg.value * s_royalty) / ROYALTY_DIVISOR;
    s_protocolBalance += m_cut;
    if (!m_collection.isExternal) {
      ImQuarkNFT(_tokenContract).subscribeToEntities(msg.sender, _tokenId, _subscriptionIds, m_uris);
    } else {
      s_importedContracts.subscribeToEntities(_tokenContract, msg.sender, _tokenId, _subscriptionIds, m_uris);
    }
    emit SubscribedBatch(_tokenId, _tokenContract, _subscriptionIds, msg.sender, m_uris, msg.value);
  }

  /**
   * @dev Makes a call to the mQuark contract to update the URI slot of a single token.
   * The function expects the update information to be encoded as bytes since token owners will have only one parameter
   * instead of five separate parameters.
   *
   * @notice The entity should sign the updated URI with their wallet.
   *
   * @param _signature Signed data by the entity's wallet
   * @param _updateInfo Encoded data containing the following:
   *   - entity: Address of the entity that is responsible for the slot
   *   - entityId: ID of the entity
   *   - tokenContract: Contract address of the given token (external contract or mQuark)
   *   - tokenId: Token ID
   *   - updatedUri: The newly generated URI for the token
   */
  function updateURISlot(bytes calldata _signature, bytes calldata _updateInfo) external noDelegateCall {
    (address m_signer, uint64 m_entityId, address m_tokenContract, uint256 m_tokenId, string memory m_updatedUri) = abi
      .decode(_updateInfo, (address, uint64, address, uint, string));

    EntityConfig memory m_entity = s_entityConfig[m_entityId];
    if (m_entity.entityId == 0) revert UnknownCollection();
    if (s_collections[m_tokenContract].contractAddress != m_tokenContract)
      revert InvalidTokenContract(s_collections[m_tokenContract].contractAddress);
    if (s_entitySubscribers[m_entityId][m_tokenContract][m_tokenId] == false) revert Unsubscribed(m_entityId);

    if (!_verifyUpdateTokenURISignature(_signature, m_signer, m_entityId, m_tokenContract, m_tokenId, m_updatedUri))
      revert VerificationFailed();

    s_inoperativeSignatures[_signature] = true;
    if (!s_collections[m_tokenContract].isExternal) {
      ImQuarkNFT(m_tokenContract).updateURISlot(msg.sender, m_entityId, m_tokenId, m_updatedUri);
    } else {
      s_importedContracts.updateURISlot(m_tokenContract, msg.sender, m_entityId, m_tokenId, m_updatedUri);
    }
    emit URISlotUpdated(m_entityId, m_tokenContract, m_tokenId, m_updatedUri);
  }

  /**
   * @dev Allows a user to unlock a token by paying the required fee.
   * This function is applicable only for tokens from free collections.
   *
   * @param _tokenId The ID of the token to unlock
   * @param _tokenContract The contract address of the token
   */
  function unlockToken(uint256 _tokenId, address _tokenContract) external payable noDelegateCall {
    Collection memory m_collection = s_collections[_tokenContract];
    if (m_collection.entityId == 0) revert UnknownCollection();
    if (!m_collection.free) revert NotFreeCollection();
    if (s_unlocked[_tokenContract][_tokenId]) revert AlreadyUnlocked(_tokenId);
    if (IERC721(_tokenContract).ownerOf(_tokenId) != msg.sender) revert NotOwner(_tokenId);
    uint256 m_limitPrice = s_controller.getTemplateMintPrice(m_collection.templateId);
    if (msg.value != m_limitPrice) revert InvalidPayment(msg.value);
    s_protocolBalance += msg.value;
    s_unlocked[_tokenContract][_tokenId] = true;
    emit Unlocked(_tokenId, _tokenContract, msg.sender, msg.value);
  }

  /**
   * @dev Makes a call to mQuark to transfer an entity slot URI of a single token to another token's the same entity slot.
   * Both the seller and buyer must provide their respective signatures to validate the transfer.
   *
   * @notice If the orders don't match, the function reverts.
   *
   * @param seller The struct containing the sell order details
   * @param buyer The struct containing the buy order details
   * @param sellerSignature Signed data by the seller's wallet
   * @param buyerSignature Signed data by the buyer's wallet
   */
  function transferTokenEntityURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable nonReentrant noDelegateCall {
    if (msg.sender != buyer.buyer) revert UnauthorizedToTransfer();
    if (seller.sellPrice != buyer.buyPrice) revert PriceMismatch();
    if (msg.value != buyer.buyPrice) revert InvalidSentAmount();
    if (seller.fromTokenId != buyer.fromTokenId) revert TokenMismatch();
    if (seller.entityId != buyer.entityId) revert GivenEntityIdMismatch();
    if (seller.seller != buyer.seller) revert SellerAddressMismatch();
    if (keccak256(abi.encodePacked(seller.slotUri)) != keccak256(abi.encodePacked(buyer.slotUri))) revert UriMismatch();
    bytes32 _messageHash = keccak256(
      abi.encode(
        seller.seller,
        seller.fromContractAddress,
        seller.fromTokenId,
        seller.entityId,
        seller.slotUri,
        seller.sellPrice,
        seller.salt
      )
    );
    bytes32 _signed = ECDSA.toEthSignedMessageHash(_messageHash);
    address _signer = ECDSA.recover(_signed, sellerSignature);
    if (seller.seller != _signer) revert SellerIsNotTheSigner();
    _messageHash = keccak256(
      abi.encode(
        buyer.buyer,
        buyer.seller,
        buyer.fromContractAddress,
        buyer.fromTokenId,
        buyer.toContractAddress,
        buyer.toTokenId,
        buyer.entityId,
        buyer.slotUri,
        buyer.buyPrice,
        buyer.salt
      )
    );
    _signed = ECDSA.toEthSignedMessageHash(_messageHash);
    _signer = ECDSA.recover(_signed, buyerSignature);
    if (buyer.buyer != _signer) revert BuyerIsNotTheSigner();
    string memory defualtEntitySlotUri = s_entityConfig[seller.entityId].defaultURI;
    if (!s_collections[seller.fromContractAddress].isExternal) {
      ImQuarkNFT(seller.fromContractAddress).resetSlotToDefault(
        seller.seller,
        seller.fromTokenId,
        seller.entityId,
        defualtEntitySlotUri
      );
    } else {
      s_importedContracts.resetSlotToDefault(
        seller.fromContractAddress,
        seller.seller,
        seller.fromTokenId,
        seller.entityId,
        defualtEntitySlotUri
      );
    }
    if (!s_collections[buyer.toContractAddress].isExternal) {
      ImQuarkNFT(buyer.toContractAddress).transferTokenEntityURI(
        buyer.buyer,
        buyer.toTokenId,
        buyer.entityId,
        buyer.slotUri
      );
    } else {
      s_importedContracts.transferTokenEntityURI(
        buyer.toContractAddress,
        buyer.buyer,
        buyer.toTokenId,
        buyer.entityId,
        buyer.slotUri
      );
    }

    (bool sent, ) = seller.seller.call{value: msg.value}("");
    if (!sent) revert FailedToSentEther();
    emit TokenEntityUriTransferred(
      seller.fromContractAddress,
      seller.fromTokenId,
      buyer.toContractAddress,
      buyer.toTokenId,
      seller.entityId,
      seller.sellPrice,
      seller.slotUri,
      seller.seller,
      buyer.buyer
    );
  }

  // * ============== VIEW =============== *//
  /**
   * @dev Retrieves information about a collection based on its contract address.
   *
   * @param _contractAddress The contract address of the collection
   * @return entityId The ID of the entity associated with the collection
   * @return templateId The ID of the template associated with the collection
   * @return free Indicates if the collection is free
   * @return isExternal Indicates if the collection is an external contract
   * @return collectionAddress The contract address of the collection
   */
  function getCollection(
    address _contractAddress
  )
    external
    view
    noDelegateCall
    returns (uint256 entityId, uint256 templateId, bool free, bool isExternal, address collectionAddress)
  {
    Collection storage m_collection = s_collections[_contractAddress];
    return (
      m_collection.entityId,
      m_collection.templateId,
      m_collection.free,
      m_collection.isExternal,
      m_collection.contractAddress
    );
  }

  /**
   * @dev Checks if a token is subscribed to a specific subscription ID.
   *
   * @param _tokenId The ID of the token
   * @param _tokenContract The contract address of the token
   * @param _subscriptionId The ID of the subscription
   * @return isSubscribed Returns true if the token is subscribed to the specified subscription ID, otherwise false
   */
  function getIsSubscribed(
    uint256 _tokenId,
    address _tokenContract,
    uint64 _subscriptionId
  ) external view returns (bool) {
    return s_entitySubscribers[_subscriptionId][_tokenContract][_tokenId];
  }

  /**
   * @dev Checks if a token is unlocked.
   *
   * @param _tokenId The ID of the token
   * @param _tokenContract The contract address of the token
   * @return isUnlocked Returns true if the token is unlocked, otherwise false
   */
  function getIsUnlocked(uint256 _tokenId, address _tokenContract) external view returns (bool) {
    return s_unlocked[_tokenContract][_tokenId];
  }

  /**
   * @dev Retrieves the configuration of an entity.
   *
   * @param _entityId The ID of the entity
   * @return entityId The ID of the entity
   * @return subscriptionPrice The subscription price of the entity
   * @return defaultURI The default URI of the entity
   * @return uriSet Indicates if the URI is set for the entity
   * @return signer The address of the signer for the entity
   */
  function getEntityConfig(
    uint256 _entityId
  )
    external
    view
    returns (uint256 entityId, uint256 subscriptionPrice, string memory defaultURI, bool uriSet, address signer)
  {
    EntityConfig storage m_entityConfig = s_entityConfig[_entityId];
    return (
      m_entityConfig.entityId,
      m_entityConfig.subscriptionPrice,
      m_entityConfig.defaultURI,
      m_entityConfig.set,
      m_entityConfig.signer
    );
  }

  /**
   * @dev Retrieves the balance of an entity.
   *
   * @param _entityId The ID of the entity
   * @return The balance of the entity
   */
  function getEntityBalance(uint256 _entityId) external view returns (uint256) {
    return s_entityBalance[_entityId];
  }

  /**
   * @dev Returns a boolean indicating whether an address is registered as an entity.
   *
   * @param _address The address to check
   * @return A boolean indicating if the address is registered as an entity
   */
  function getIsAddressRegisteredAsEntity(address _address) external view returns (bool) {
    return s_registeredEntities[_address];
  }

  /**
   * @dev Calculates the total subscription price for a batch of subscription IDs.
   *
   * @param _subscriptionIds The array of subscription IDs
   * @return The total subscription price
   */
  function calculateBatchSubscriptionPrice(uint64[] calldata _subscriptionIds) public view returns (uint256) {
    uint256 m_price;
    uint256 m_numberOfIds = _subscriptionIds.length;
    for (uint256 i = 0; i < m_numberOfIds; ) {
      m_price += s_entityConfig[_subscriptionIds[i]].subscriptionPrice;
      unchecked {
        ++i;
      }
    }
    return m_price;
  }

  // * ============== INTERNAL =========== *//
  /**
   * @dev Checks the validity of a given signature by verifying that it is signed by the given entity address.
   *
   * @param _signature The signature to verify
   * @param _signer The address of the entity that signed the signature
   * @param _entityId The ID of the entity associated with the signature
   * @param _tokenContract The address of the token contract associated with the signature
   * @param _tokenId The ID of the token associated with the signature
   * @param _uri The URI associated with the signature
   * @return True if the signature is valid
   */
  function _verifyUpdateTokenURISignature(
    bytes memory _signature,
    address _signer,
    uint256 _entityId,
    address _tokenContract,
    uint256 _tokenId,
    string memory _uri
  ) internal view returns (bool) {
    if (s_inoperativeSignatures[_signature]) revert SignatureInoperative();
    bytes32 m_messageHash = keccak256(abi.encode(_signer, _entityId, _tokenContract, _tokenId, _uri));
    bytes32 m_signed = ECDSA.toEthSignedMessageHash(m_messageHash);
    address m_signer = ECDSA.recover(m_signed, _signature);
    return (s_entityConfig[_entityId].signer == m_signer);
  }

  /**
   * @dev Allows the owner of an entity to withdraw a certain amount of Ether from their entity's balance.
   *
   * @param _entityId  The ID of the entity
   * @param _amount    The amount of Ether to withdraw
   */
  function withdraw(
    uint256 _entityId,
    uint256 _amount
  ) external onlyEntityOwner(_entityId) nonReentrant noDelegateCall {
    if (_amount > s_entityBalance[_entityId]) revert InsufficientBalance();
    s_entityBalance[_entityId] -= _amount;
    (bool sent, ) = msg.sender.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    emit Withdraw(_entityId, msg.sender, _amount);
  }

  /**
   * @dev Allows the default admin role to withdraw a certain amount of Ether from the protocol balance.
   *
   * @param _amount  The amount of Ether to withdraw
   */
  function withdrawProtocol(uint256 _amount) external onlyRole(CONTROL_ROLE) nonReentrant noDelegateCall {
    if (_amount > s_protocolBalance) revert InsufficientBalance();
    s_protocolBalance -= _amount;
    (bool sent, ) = msg.sender.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    emit WithdrawProtocol(msg.sender, _amount);
  }

  function _onlyEntityOwner(uint256 _entityId) internal view {
    address entityContractAddress = s_registry.getEntityAddress(_entityId);
    if (IOwnable(entityContractAddress).owner() != msg.sender) revert NotEntityOwner(_entityId);
  }

  function _onlyNFTOwner(address _nftContractAddress) internal view {
    if (IOwnable(_nftContractAddress).owner() == msg.sender) revert NotCollectionOwner(_nftContractAddress);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "./lib/StringSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ImQuarkTemplate.sol";

contract mQuarkTemplate is AccessControl, ImQuarkTemplate {
  //* =============================== LIBRARIES ======================================================= *//
  using EnumerableSet for EnumerableSet.UintSet;

  using EnumerableSet for EnumerableSet.Bytes32Set;

  using EnumerableStringSet for EnumerableStringSet.StringSet;

  //* =============================== MAPPINGS ======================================================== *//

  // Mapping from 'category name' to 'category'
  mapping(string => Category) public categoriesByName;

  // Mapping from 'category id' to 'category'
  mapping(uint256 => Category) public categoriesById;

  // Mapping from 'selector' to 'category'
  mapping(bytes4 => Category) public categoriesBySelector;

  // Mapping from 'category' to  'template ids'
  mapping(string => EnumerableSet.UintSet) private categoryTemplates;

  // Mapping from 'template id' to 'categories'
  mapping(uint256 => EnumerableStringSet.StringSet) private templateCategories;

  // Mapping from a 'template id' to a 'template URI'
  mapping(uint256 => string) private s_templateURIs;

  //* =============================== VARIABLES ======================================================= *//

  // Stores the ids of created templates
  EnumerableSet.UintSet private s_templateIds;

  // Keeps track of the last created template id
  uint256 public s_templateIdCounter;

  // Keeps track of the last created category id
  uint256 public s_categoryCounter;

  // This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  //* =============================== CONSTRUCTOR ===================================================== *//
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
  }

  //* =============================== FUNCTIONS ======================================================= *//
  // * ============== EXTERNAL =========== *//
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

  /**
   * @notice This function allows the creation of a new category.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param name The name of the category.
   * @param uri The URI associated with the category.
   */
  function createCategory(string calldata name, string calldata uri) external onlyRole(CONTROL_ROLE) {
    uint256 m_categoryId = ++s_categoryCounter;
    bytes4 selector = bytes4(keccak256(bytes(name)));
    Category memory m_category = Category(m_categoryId, selector, name, uri);
    categoriesByName[name] = m_category;
    categoriesById[m_categoryId] = m_category;
    categoriesBySelector[selector] = m_category;
    emit CategoryCreated(name, m_categoryId, selector, uri);
  }

  /**
   * @notice This function allows the creation of multiple categories in a batch.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param names An array of category names.
   * @param uris An array of URIs associated with each category.
   */
  function createBatchCategory(string[] calldata names, string[] calldata uris) external onlyRole(CONTROL_ROLE) {
    if (names.length != uris.length) revert ArrayLengthMismatch();
    uint256 m_numberOfUris = names.length;
    for (uint8 i = 0; i < m_numberOfUris; ) {
      this.createCategory(names[i], uris[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Sets the given templates to a category.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param category The category name for the templates (e.g., "vehicle").
   * @param templateIds_ An array of template IDs that will be set to the given category (e.g., [1, 2, 3]).
   */
  function setTemplateCategory(
    string calldata category,
    uint256[] calldata templateIds_
  ) external onlyRole(CONTROL_ROLE) {
    if (categoriesByName[category].id == 0) revert UnexistingCategory();
    uint256 templateLength = templateIds_.length;
    for (uint256 i = 0; i < templateLength; ) {
      if (s_templateIds.contains(templateIds_[i]) != true) revert UnexistingTemplate();
      categoryTemplates[category].add(templateIds_[i]);
      templateCategories[templateIds_[i]].add(category);
      {
        ++i;
      }
    }
    emit CategoriesSet(category, templateIds_);
  }

  /**
   * @notice Removes a given template from a given category.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param category The category name for the template.
   * @param templateId The template ID that will be removed from the category.
   */
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

  // * ============== VIEW =============== *//
  /**
   * @notice This function returns the total number of templates that have been created.
   *
   * @return The total number of templates that have been created
   */
  function getLastTemplateId() external view returns (uint256) {
    return s_templateIds.length();
  }

  /**
   * @notice Checks if a template ID exists.
   * @param _templateId The template ID to check.
   * @return exist `true` if the template ID exists, `false` otherwise.
   */
  function isTemplateIdExist(uint256 _templateId) external view returns (bool exist) {
    exist = s_templateIds.contains(_templateId);
  }

  /**
   * @notice Retrieves all the template IDs in the given category.
   * @param category The name of the category.
   * @return An array of all the template IDs in the given category.
   */
  function getAllCategoryTemplates(string memory category) external view returns (uint256[] memory) {
    return categoryTemplates[category].values();
  }

  /**
   * @notice Retrieves a batch of template IDs in the given category, starting from the specified index.
   * @param category The name of the category.
   * @param startIndex The index of the array to start searching from.
   * @param batchLength The length of the returned array.
   * @return An array of template IDs in the given category.
   */
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) external view returns (uint256[] memory) {
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

  /**
   * @notice Retrieves the categories that a template belongs to.
   * @param templateId The ID of the template.
   * @return An array of category names that the template belongs to.
   * @dev If the template is not in any category, it will return an empty array.
   */
  function getTemplatesCategory(uint256 templateId) external view returns (string[] memory) {
    return templateCategories[templateId].values();
  }

  /**
   * @notice Retrieves the number of templates in a given category.
   * @param category The name of the category.
   * @return The length of the category's template list.
   */
  function getCategoryTemplateLength(string calldata category) external view returns (uint256) {
    return categoryTemplates[category].length();
  }

  /**
   * @notice Retrieves the details of a category by its name.
   * @param name The name of the category.
   * @return id The ID of the category.
   * @return selector selector of the category.
   * @return uri URI of the category.
   */
  function getCategoryByName(
    string calldata name
  ) external view returns (uint256 id, bytes4 selector, string memory uri) {
    Category storage category = categoriesByName[name];
    return (category.id, category.selector, category.uri);
  }

  /**
   * @notice Retrieves the details of a category by its ID.
   * @param id The ID of the category.
   * @return selector selector of the category.
   * @return name name of the category.
   * @return uri URI of the category.
   */
  function getCategoryById(uint256 id) external view returns (bytes4 selector, string memory name, string memory uri) {
    Category storage category = categoriesById[id];
    return (category.selector, category.name, category.uri);
  }

  /**
   * @notice Retrieves the details of a category by its selector.
   * @param selector The selector of the category.
   * @return id The ID of the category.
   * @return name name of the category.
   * @return uri URI of the category.
   */
  function getCategoryBySelector(
    bytes4 selector
  ) external view returns (uint256 id, string memory name, string memory uri) {
    Category storage category = categoriesBySelector[selector];
    return (category.id, category.name, category.uri);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

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