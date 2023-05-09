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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
  event WithdrawProtocol(address to, uint256 amount);
  event Withdraw(uint64 projectId, address to, uint256 amount);
  event RoyaltySet(uint256 royalty);
  event RegistrySet(address registery);
  event ControllerSet(address controller);
  event Unlocked(uint256 tokenId, address tokenContract, address to, uint256 amount);
  event URISlotUpdated(uint64 projectId, address tokenContract, uint256 tokenId, string updatedUri);
  event SubscribedBatch(uint256 tokenId, address tokenContract, uint64[] subscriptionIds, address to, uint256 amount);
  event Subscribed(uint256 tokenId, address tokenContract, uint256 subscriptionId, address to, uint256 amount);
  event CollectionSet(bool free, uint64 projectId, uint256 templateId, uint64 collectionId, address collectionAddress);
  event SignerSet(uint64 projectId, address signer);
  event SubscriptionPriceSet(uint64 projectId, uint256 price);
  event DefaultURISet(uint64 projectId, string defaultURI);
  event ProjectInitialized(address contractAddress, uint64 projectId, address signer, string defaultURI, uint256 price);
  event TokenProjectUriTransferred(
    address fromTokenContract,
    uint256 fromTokenId,
    address toTokenContract,
    uint256 toTokenId,
    uint256 projectId,
    uint256 price,
    string uri,
    address from,
    address to
  );

  /// @dev    Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  mapping(bytes => bool) private s_inoperativeSignatures;

  mapping(address => Collection) private s_collections;

  mapping(address => bool) private s_registeredProjects;

  mapping(uint64 => uint256) private s_projectBalance;

  mapping(uint64 => ProjectConfig) private s_projectConfig;

  mapping(address => mapping(uint256 => bool)) private s_unlocked;

  mapping(uint64 => mapping(address => mapping(uint256 => bool))) private s_projectSubscribers;

  /// @dev This role will be used to check the validity of signatures
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  /// @dev This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @dev This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  //create a modifer that checks if the contract is authorized
  modifier onlyProjectContract() {
    if (!s_registeredProjects[msg.sender]) revert Unauthorized(msg.sender);
    _;
  }

  //create a modifer that checks if the caller is registry
  modifier onlyRegistry() {
    if (msg.sender != address(s_registry)) revert NotRegistry(msg.sender);
    _;
  }

  modifier onlyProjectOwner(uint64 _projectId) {
    _onlyProjectOwner(_projectId);
    _;
  }

  //create a modifier that checks if the caller is owner of the registry
  function _onlyProjectOwner(uint64 _projectId) internal view {
    /// @dev lets create view functions for calling the registry for getting project address & name then use that function call here
    address projectContractAddress = s_registry.getProjectAddress(_projectId);
    /// @dev let's replace all the errors with custom Error to make them more gas efficient.
    if (IOwnable(projectContractAddress).owner() != msg.sender) revert NotProjectOwner(_projectId);
  }

  //only mQuarNFT owner modifier
  function _onlyNFTOwner(address _nftContractAddress) internal view {
    if (IOwnable(_nftContractAddress).owner() == msg.sender) revert NotCollectionOwner(_nftContractAddress);
  }

  ImQuarkRegistry public s_registry;
  ImQuarkController public s_controller;
  IImportedContracts public s_importedContracts;
  uint256 public constant ROYALTY_DIVISOR = 1000000000;
  uint256 public s_royalty;
  uint256 public s_protocolBalance;

  constructor(ImQuarkRegistry _registry, ImQuarkController _controller, uint256 _royalty) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
    s_registry = _registry;
    s_controller = _controller;
    s_royalty = _royalty;
  }

  //set registry contract
  function setRegistery(address _registery) external onlyRole(CONTROL_ROLE) {
    s_registry = ImQuarkRegistry(_registery);
    emit RegistrySet(_registery);
  }

  function setRoyalty(uint256 _royalty) external onlyRole(CONTROL_ROLE) {
    s_royalty = _royalty;
    emit RoyaltySet(_royalty);
  }

  //set controller contract
  function setController(address _controller) external onlyRole(CONTROL_ROLE) {
    s_controller = ImQuarkController(_controller);
    emit ControllerSet(_controller);
  }

  //set external collection contract
  function setExternalCollection(address _externalCollection) external onlyRole(CONTROL_ROLE) {
    s_importedContracts = IImportedContracts(_externalCollection);
  }

  //sets authorized contract
  function initializeProject(
    address _contract,
    uint64 _projectId,
    address _signer,
    string calldata _defaultURI,
    uint256 _price
  ) external onlyRegistry {
    s_registeredProjects[_contract] = true;
    ProjectConfig memory m_temp = s_projectConfig[_projectId];
    m_temp.projectId = _projectId;
    m_temp.signer = _signer;
    m_temp.defaultURI = _defaultURI;
    m_temp.subscriptionPrice = _price;
    m_temp.set = true;
    s_projectConfig[_projectId] = m_temp;
    emit ProjectInitialized(_contract, _projectId, _signer, _defaultURI, _price);
  }

  //change default uri
  function setDefaultURI(
    uint64 _projectId,
    string calldata _defaultURI
  ) external noDelegateCall onlyProjectOwner(_projectId) {
    s_projectConfig[_projectId].defaultURI = _defaultURI;
    emit DefaultURISet(_projectId, _defaultURI);
  }

  function setSubscriptionPrice(
    uint64 _projectId,
    uint256 _price
  ) external noDelegateCall onlyProjectOwner(_projectId) {
    s_projectConfig[_projectId].subscriptionPrice = _price;
    emit SubscriptionPriceSet(_projectId, _price);
  }

  function setSigner(uint64 _projectId, address _signer) external noDelegateCall onlyProjectOwner(_projectId) {
    s_projectConfig[_projectId].signer = _signer;
    emit SignerSet(_projectId, _signer);
  }

  /// @notice Sets collection by the project contract
  function setCollection(
    bool _free,
    bool _external,
    uint64 _projectId,
    uint256 _templateId,
    uint64 _collectionId,
    address _collectionAddress
  ) external onlyProjectContract {
    Collection memory m_collection;

    m_collection.projectId = _projectId;
    m_collection.templateId = _templateId;
    m_collection.collectionId = _collectionId;
    m_collection.free = _free;
    m_collection.contractAddress = _collectionAddress;
    m_collection.isExternal = _external;

    s_collections[_collectionAddress] = m_collection;
    // emit CollectionSet(_free, _projectId, _templateId, _collectionId, _collectionAddress);
  }

  function subscribe(
    uint256 _tokenId,
    address _tokenContract,
    uint64 _subscriptionId
  ) external payable nonReentrant noDelegateCall {
    Collection memory m_collection = s_collections[_tokenContract];
    if (m_collection.contractAddress == address(0)) revert InvalidCollection(_tokenContract);
    ProjectConfig memory m_projectConfig = s_projectConfig[_subscriptionId];
    if (s_projectSubscribers[_subscriptionId][_tokenContract][_tokenId])
      revert AlreadySubscribed(_subscriptionId, _tokenContract, _tokenId);
    if (m_projectConfig.set == false) revert Unexist(_subscriptionId);
    if (m_collection.free) {
      if (!s_unlocked[_tokenContract][_tokenId]) revert TokenLocked(_tokenContract, _tokenId);
    }
    if (msg.value != m_projectConfig.subscriptionPrice) revert InvalidPayment(msg.value);
    s_projectSubscribers[_subscriptionId][_tokenContract][_tokenId] = true;

    if (!m_collection.isExternal) {
      ImQuarkNFT(_tokenContract).subscribeToProject(msg.sender, _tokenId, _subscriptionId, m_projectConfig.defaultURI);
    } else {
      s_importedContracts.subscribeToProject(
        _tokenContract,
        msg.sender,
        _tokenId,
        _subscriptionId,
        m_projectConfig.defaultURI
      );
    }

    uint256 m_cut = (msg.value * s_royalty) / ROYALTY_DIVISOR;
    s_projectBalance[_subscriptionId] += (msg.value - m_cut);
    s_protocolBalance += m_cut;
    emit Subscribed(_tokenId, _tokenContract, _subscriptionId, msg.sender, msg.value);
  }

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

    for (uint i = 0; i < m_numberOfIds;) {
      if (s_projectConfig[_subscriptionIds[i]].set == false) revert Unexist(_subscriptionIds[i]);
      m_uris[i] = s_projectConfig[_subscriptionIds[i]].defaultURI;
      s_projectBalance[_subscriptionIds[i]] += s_projectConfig[_subscriptionIds[i]].subscriptionPrice;
      unchecked {
        ++i;
      }
    }
    uint256 m_cut = (msg.value * s_royalty) / ROYALTY_DIVISOR;
    s_protocolBalance += m_cut;
    if (!m_collection.isExternal) {
      ImQuarkNFT(_tokenContract).subscribeToProjects(msg.sender, _tokenId, _subscriptionIds, m_uris);
    } else {
      s_importedContracts.subscribeToProjects(_tokenContract, msg.sender, _tokenId, _subscriptionIds, m_uris);
    }
    emit SubscribedBatch(_tokenId, _tokenContract, _subscriptionIds, msg.sender, msg.value);
  }

  /**
   * "updateInfo" is used as bytes because token owners will have only one parameter rather than five parameters.
   * Makes a call to mQuark contract to update a given uri slot
   * Updates the project's slot uri of a single token
   * @notice Project should sign the upated URI with their wallet
   * @param _signature  Signed data by project's wallet
   * @param _updateInfo Encoded data
   * * project       Address of the project that is responsible for the slot
   * * projectId     ID of the project
   * * tokenContract Contract address of the given token.(External contract or mQuark)
   * * tokenId       Token ID
   * * updatedUri    The newly generated URI for the token
   */
  function updateURISlot(bytes calldata _signature, bytes calldata _updateInfo) external noDelegateCall {
    (address m_signer, uint64 m_projectId, address m_tokenContract, uint256 m_tokenId, string memory m_updatedUri) = abi
      .decode(_updateInfo, (address, uint64, address, uint, string));

    ProjectConfig memory m_project = s_projectConfig[m_projectId];
    if (m_project.projectId == 0) revert UnknownCollection();
    if (s_collections[m_tokenContract].contractAddress != m_tokenContract)
      revert InvalidTokenContract(s_collections[m_tokenContract].contractAddress);
    if (s_projectSubscribers[m_projectId][m_tokenContract][m_tokenId] == false) revert Unsubscribed(m_projectId);

    if (!_verifyUpdateTokenURISignature(_signature, m_signer, m_projectId, m_tokenContract, m_tokenId, m_updatedUri))
      revert VerificationFailed();

    s_inoperativeSignatures[_signature] = true;
    // ImQuarkNFT(m_tokenContract).updateURISlot(msg.sender, m_projectId, m_tokenId, m_updatedUri);
    if (!s_collections[m_tokenContract].isExternal) {
      ImQuarkNFT(m_tokenContract).updateURISlot(msg.sender, m_projectId, m_tokenId, m_updatedUri);
    } else {
      s_importedContracts.updateURISlot(m_tokenContract, msg.sender, m_projectId, m_tokenId, m_updatedUri);
    }
    emit URISlotUpdated(m_projectId, m_tokenContract, m_tokenId, m_updatedUri);
  }

  // unlock free mint token
  function unlockToken(uint256 _tokenId, address _tokenContract) external payable noDelegateCall {
    Collection memory m_collection = s_collections[_tokenContract];
    if (m_collection.projectId == 0) revert UnknownCollection();
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
   * Makes a call to mQuark tı transfers a project slot uri of a single token to another token's the same project slot
   * @notice If orders doesn't match, it reverts
   *
   * @param seller           The struct that contains sell order details
   * @param buyer            The struct that contains buy order details
   * @param sellerSignature  Signed data by seller's wallet
   * @param buyerSignature   Signed data by buyer's wallet
   */
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable nonReentrant noDelegateCall {
    if (msg.sender != buyer.buyer) revert UnauthorizedToTransfer();
    if (seller.sellPrice != buyer.buyPrice) revert PriceMismatch();
    if (msg.value != buyer.buyPrice) revert InvalidSentAmount();
    if (seller.fromTokenId != buyer.fromTokenId) revert TokenMismatch();
    if (seller.projectId != buyer.projectId) revert GivenProjectIdMismatch();
    if (seller.seller != buyer.seller) revert SellerAddressMismatch();
    if (keccak256(abi.encodePacked(seller.slotUri)) != keccak256(abi.encodePacked(buyer.slotUri))) revert UriMismatch();
    bytes32 _messageHash = keccak256(
      abi.encode(
        seller.seller,
        seller.fromContractAddress,
        seller.fromTokenId,
        seller.projectId,
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
        buyer.projectId,
        buyer.slotUri,
        buyer.buyPrice,
        buyer.salt
      )
    );
    _signed = ECDSA.toEthSignedMessageHash(_messageHash);
    _signer = ECDSA.recover(_signed, buyerSignature);
    if (buyer.buyer != _signer) revert BuyerIsNotTheSigner();
    string memory defualtProjectSlotUri = s_projectConfig[seller.projectId].defaultURI;
    if (!s_collections[seller.fromContractAddress].isExternal) {
      ImQuarkNFT(seller.fromContractAddress).resetSlotToDefault(
        seller.seller,
        seller.fromTokenId,
        seller.projectId,
        defualtProjectSlotUri
      );
    } else {
      s_importedContracts.resetSlotToDefault(
        seller.fromContractAddress,
        seller.seller,
        seller.fromTokenId,
        seller.projectId,
        defualtProjectSlotUri
      );
    }
    if (!s_collections[buyer.toContractAddress].isExternal) {
      ImQuarkNFT(buyer.toContractAddress).transferTokenProjectURI(
        buyer.buyer,
        buyer.toTokenId,
        buyer.projectId,
        buyer.slotUri
      );
    } else {
      s_importedContracts.transferTokenProjectURI(
        buyer.toContractAddress,
        buyer.buyer,
        buyer.toTokenId,
        buyer.projectId,
        buyer.slotUri
      );
    }
    // ImQuarkNFT(buyer.toContractAddress).transferTokenProjectURI(
    //   buyer.buyer,
    //   buyer.toTokenId,
    //   buyer.projectId,
    //   buyer.slotUri
    // );

    (bool sent, ) = seller.seller.call{value: msg.value}("");
    if (!sent) revert FailedToSentEther();
    emit TokenProjectUriTransferred(
      seller.fromContractAddress,
      seller.fromTokenId,
      buyer.toContractAddress,
      buyer.toTokenId,
      seller.projectId,
      seller.sellPrice,
      seller.slotUri,
      seller.seller,
      buyer.buyer
    );
  }

  // function tokenProjectURI(uint256 _tokenId, uint256 _projectId) external view returns (string memory) {
  //   return s_tokenSubscriptions[_tokenId][_projectId].uri;
  // }

  //get collection
  function getCollection(
    address _contractAddress
  )
    external
    view
    noDelegateCall
    returns (uint64 projectId, uint256 templateId, uint64 collectionId, bool free, address collectionAddress)
  {
    Collection memory m_collection = s_collections[_contractAddress];
    return (
      m_collection.projectId,
      m_collection.templateId,
      m_collection.collectionId,
      m_collection.free,
      m_collection.contractAddress
    );
  }

  function getIsSubscribed(
    uint256 _tokenId,
    address _tokenContract,
    uint64 _subscriptionId
  ) external view returns (bool) {
    return s_projectSubscribers[_subscriptionId][_tokenContract][_tokenId];
  }

  function getIsUnlocked(uint256 _tokenId, address _tokenContract) external view returns (bool) {
    return s_unlocked[_tokenContract][_tokenId];
  }

  function getProjectConfig(
    uint64 _projectId
  )
    external
    view
    returns (uint64 projectId, uint256 subscriptionPrice, string memory defaultURI, bool uriSet, address signer)
  {
    ProjectConfig memory m_projectConfig = s_projectConfig[_projectId];
    return (
      m_projectConfig.projectId,
      m_projectConfig.subscriptionPrice,
      m_projectConfig.defaultURI,
      m_projectConfig.set,
      m_projectConfig.signer
    );
  }

  function getProjectBalance(uint64 _projectId) external view returns (uint256) {
    return s_projectBalance[_projectId];
  }

  function getIsAddressRegisteredAsProject(address _address) external view returns (bool) {
    return s_registeredProjects[_address];
  }

  //calculate batch subscription price
  function calculateBatchSubscriptionPrice(uint64[] calldata _subscriptionIds) public view returns (uint256) {
    uint256 m_price;
    uint256 m_numberOfIds = _subscriptionIds.length;
    for (uint256 i = 0; i < m_numberOfIds; ) {
      m_price += s_projectConfig[_subscriptionIds[i]].subscriptionPrice;
      unchecked {
        ++i;
      }
    }
    return m_price;
  }

  /**
   * @notice This function checks the validity of a given signature by verifying that it is signed by the given project address.
   *
   * @param _signature  The signature to verify
   * @param _signer    The address of the project that signed the signature
   * @param _projectId  The ID of the project associated with the signature
   * @param _tokenId    The ID of the token associated with the signature
   * @param _uri       The URI associated with the signature
   * @return           "true" if the signature is valid
   *    */
  function _verifyUpdateTokenURISignature(
    bytes memory _signature,
    address _signer,
    uint64 _projectId,
    address _tokenContract,
    uint256 _tokenId,
    string memory _uri
  ) internal view returns (bool) {
    if (s_inoperativeSignatures[_signature]) revert SignatureInoperative();
    bytes32 m_messageHash = keccak256(abi.encode(_signer, _projectId, _tokenContract, _tokenId, _uri));
    bytes32 m_signed = ECDSA.toEthSignedMessageHash(m_messageHash);
    address m_signer = ECDSA.recover(m_signed, _signature);
    return (s_projectConfig[_projectId].signer == m_signer);
  }

  function withdraw(
    uint64 _projectId,
    uint256 _amount
  ) external onlyProjectOwner(_projectId) nonReentrant noDelegateCall {
    if (_amount > s_projectBalance[_projectId]) revert InsufficientBalance();
    s_projectBalance[_projectId] -= _amount;
    (bool sent, ) = msg.sender.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    emit Withdraw(_projectId, msg.sender, _amount);
  }

  function withdrawProtocol(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant noDelegateCall {
    if (_amount > s_protocolBalance) revert InsufficientBalance();
    s_protocolBalance -= _amount;
    (bool sent, ) = msg.sender.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    emit WithdrawProtocol(msg.sender, _amount);
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