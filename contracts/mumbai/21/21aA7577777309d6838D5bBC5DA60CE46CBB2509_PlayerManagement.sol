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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAddressRegistry {
    function uriGenerator() external view returns (address);

    function treasury() external view returns (address);

    function pdp() external view returns (address);

    function pxp() external view returns (address);

    function pdt() external view returns (address);

    function pdtOracle() external view returns (address);

    function playerMgmt() external view returns (address);

    function poolMgmt() external view returns (address);

    function svgGenerator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPDP {
    function publicMint(bytes32 name) external;

    function whitelistMint(bytes32 name, bytes memory signature) external;

    function getPlayerAddress(uint256 id) external view returns (address playerAddress_);

    function getPlayerId(address player) external view returns (uint256 playerId_);

    function totalPlayers() external view returns (uint256 totalPlayers_);

    function playerExists(uint256 id) external view returns (bool playerExists_);

    function getAddressRegistry() external view returns (address addressRegistry_);

    function getSignerAddress() external view returns (address signerAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPDTOracle {
    function requestPdtPrice() external;

    function fulfillPdtPrice(bytes32 requestId, uint256 pdtPrice) external;

    function getLatestPdtPrice() external view returns (uint256 pdtPrice_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPXP {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPlayerManagement {
    /// @notice  Stored in a mapping per Player ID in PlayerManagement.
    /// @param   playerName  Bytes32 representation of the player's name.
    /// @param   playerRank
    struct PlayerData {
        bytes32 playerName;
        uint64 playerRank;
        uint64 mintDate;
    }

    function claimPlayerXp(bytes memory signature, uint256 pxpAmount, uint256 claimCount) external;

    function setPlayerName(bytes32 newName) external;

    function upgradePlayerRank() external;

    function getLevelMultiplier(uint256 rank) external view returns (uint256 levelMultiplier_);

    function getPdpMintCost(bool whitelist) external view returns (uint256 pdtCost_);

    function getNameChangeCost() external view returns (uint256 pdtCost_);

    function getRankUpCosts(uint256 rank) external view returns (uint256 pdtCost_, uint256 pxpCost_);

    function getAddressRegistry() external view returns (address addressRegistry_);

    function getSignerAddress() external view returns (address signerAddress_);

    function getMaxRank() external view returns (uint256 maxRank_);

    function getMinRankForTransfers() external view returns (uint256 minRankForTransfers_);

    function getUsdCostPdpMintPublic() external view returns (uint256 usdCostPdpMintPublic_);

    function getUsdCostPdpMintWhitelist() external view returns (uint256 usdCostPdpMintWhitelist_);

    function getUsdCostNameChange() external view returns (uint256 usdCostNameChange_);

    function getUsdCostRankUp() external view returns (uint256 usdCostRankUp_);

    function getPxpBaseCostRankUp() external view returns (uint256 pxpBaseCostRankUp_);

    function getRankMultiplierBasisPoints() external view returns (uint256 rankMultiplierBasisPoints_);

    function getPlayerData(uint256 id) external view returns (PlayerData memory playerData_);

    function getPlayersInRank(uint256 rank) external view returns (uint256 playersInRank_);

    function getClaimCount(uint256 id) external view returns (uint256 claimCount_);

    function getPxpClaimed(uint256 id) external view returns (uint256 pxpClaimed_);

    function getTotalPxpEarnedPerRank(uint256 rank) external view returns (uint256 totalPxpEarnedPerRank_);

    function initializePlayerData(uint256 id, bytes32 name) external;

    function setMaxRank(uint256 maxRank) external;

    function setMinRankForTransfers(uint256 minRankForTransfers) external;

    function setUsdCostPdpMintPublic(uint256 usdCostPdpMintPublic) external;

    function setUsdCostPdpMintWhitelist(uint256 usdCostPdpMintWhitelist) external;

    function setUsdCostNameChange(uint256 usdCostNameChange) external;

    function setUsdCostRankUp(uint256 usdCostRankUp) external;

    function setPxpBaseCostRankup(uint256 pxpBaseCostRankUp) external;

    function setRankMultiplierBasisPoints(uint256 rankMultiplierBasisPoints) external;

    function setTotalPxpEarnedPerRank(uint256[] memory totalPxpEarnedPerRank) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/IAddressRegistry.sol";
import "../interfaces/IPlayerManagement.sol";
import "../interfaces/IPDTOracle.sol";
import "../interfaces/IPXP.sol";
import "../interfaces/IPDP.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

/// @author  0xFirekeeper
/// @title   ParagonsDAO Player Management system.
/// @dev     Central hub for the player management ecosystem data handling.
/// @notice  Player Management system acting as a hub for claiming, player data, player experience, general costs and more.

contract PlayerManagement is AccessControl, IPlayerManagement {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error for if PDT balance is too low.
    /// @param  available  Amount of PDT available.
    /// @param  required  Amount of PDT required.
    error PDTBalanceTooLow(uint256 available, uint256 required);

    /// @notice Error for if PXP balance is too low.
    /// @param  available  Amount of PXP available.
    /// @param  required  Amount of PXP required.
    error PXPBalanceTooLow(uint256 available, uint256 required);

    /// @notice Error for if already claimed.
    /// @param  invalidClaimCount  Claim count that has been passed.
    /// @param  currentClaimCount  Expected claim count.
    error AlreadyClaimed(uint256 invalidClaimCount, uint256 currentClaimCount);

    /// @notice Error for if signature is invalid.
    error InvalidSignature();

    /// @notice Error for if does not exist.
    error DoesNotExist();

    /// @notice Error for if name is invalid.
    error InvalidName();

    /// @notice Error for if is not PDP contract.
    error NotPDPContract();

    /// @notice Error for if maximum rank has been reached.
    error MaximumRankReached();

    /// @notice Error for if array length is invalid.
    error InvalidArrayLength();

    /// @notice Error for if amount is invalid.
    error InvalidAmount();

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Manager role identifier for AccessControl.
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice AddressRegistry contract.
    IAddressRegistry private _addressRegistry;

    /// @notice Address used for sign-claiming PXP.
    address private _signerAddress;

    /// @notice Maximum rank that a player can reach.
    uint256 private _maxRank;

    /// @notice Minimum rank to unlock PDP transfers.
    uint256 private _minRankForTransfers;

    /// @notice USD cost to mint a PDP (public).
    uint256 private _usdCostPdpMintPublic;

    /// @notice USD cost to mint a PDP (whitelist).
    uint256 private _usdCostPdpMintWhitelist;

    /// @notice USD cost to change a player's name, to be paid in PDT.
    uint256 private _usdCostNameChange;

    /// @notice USD cost to rank up, to be paid in PDT.
    uint256 private _usdCostRankUp;

    /// @notice PXP base cost to rank up.
    uint256 private _pxpBaseCostRankUp;

    /// @notice Base PXP earnings multiplier per rank.
    uint256 private _rankMultiplierBasisPoints;

    /// @notice Player ID => PlayerData.
    mapping(uint256 => PlayerData) private _playerData;

    /// @notice Rank => Amount of players in that rank.
    mapping(uint256 => uint256) private _playersInRank;

    /// @notice Amount of times a Player ID has claimed PXP.
    mapping(uint256 => uint256) private _claimCount;

    /// @notice Amount of PXP that a Player ID has claimed.
    mapping(uint256 => uint256) private _pxpClaimed;

    /// @notice Amount of PXP earned per rank, the index being the rank.
    uint256[] private _totalPxpEarnedPerRank;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Emitted upon Player Rank being upgraded.
    /// @param   id  Token ID.
    /// @param   oldRank  Previous rank.
    /// @param   newRank  New rank.
    event PlayerRankUpdated(uint256 indexed id, uint256 indexed oldRank, uint256 indexed newRank);

    /// @notice  Emitted upon Player Name being updated.
    /// @param   id  Token ID.
    /// @param   oldName  Previous name.
    /// @param   newName  New name.
    event PlayerNameUpdated(uint256 indexed id, bytes32 indexed oldName, bytes32 indexed newName);

    /// @notice  Emitted upon Player Claiming XP
    /// @param   id  Token ID.
    /// @param   amountClaimed  Amount of Player XP claimed.
    /// @param   claimCount  Amount of times this player has claimed Player XP.
    /// @param   totalClaimed  Total PXP this player has claimed so far.
    event PlayerXPClaimed(
        uint256 indexed id,
        uint256 indexed amountClaimed,
        uint256 indexed claimCount,
        uint256 totalClaimed
    );

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice  Sets up AddressRegistry, AccessControl and initializes variables.
    /// @param   addressRegistry  AddressRegistry contract address.
    constructor(IAddressRegistry addressRegistry) {
        _addressRegistry = addressRegistry;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        _maxRank = 9;
        _minRankForTransfers = 5;
        _usdCostPdpMintPublic = 5 * 1e18;
        _usdCostPdpMintWhitelist = 1 * 1e18;
        _usdCostNameChange = 5 * 1e18;
        _usdCostRankUp = 10 * 1e18;
        _pxpBaseCostRankUp = 1000 * 1e18;
        _rankMultiplierBasisPoints = 2500;
        _totalPxpEarnedPerRank = new uint[](_maxRank + 1);
        _signerAddress = 0xCC954Ab6004e04daEde3efbFF2f34e6BC4054A13;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Mints Player XP to msg.sender after verifying signature.
    /// @param   signature  Signature containing relavant variables.
    /// @param   pxpAmount  Amount of PXP to claim.
    /// @param   claimCount  Amount of times PXP has been claimed by this user.
    function claimPlayerXp(bytes memory signature, uint256 pxpAmount, uint256 claimCount) external {
        uint256 tokenId = IPDP(_addressRegistry.pdp()).getPlayerId(msg.sender);
        uint256 currentClaimCount = _claimCount[tokenId];
        uint256 totalPxpClaimed = _pxpClaimed[tokenId];

        if (pxpAmount < 1e18) revert InvalidAmount();
        if (claimCount != currentClaimCount) revert AlreadyClaimed(claimCount, currentClaimCount);
        if (!_verifySignature(signature, pxpAmount, claimCount)) revert InvalidSignature();

        _claimCount[tokenId] = currentClaimCount + 1;
        _pxpClaimed[tokenId] = totalPxpClaimed + pxpAmount;

        emit PlayerXPClaimed(tokenId, pxpAmount, currentClaimCount + 1, totalPxpClaimed + pxpAmount);

        IPXP(_addressRegistry.pxp()).mint(msg.sender, pxpAmount);
    }

    /// @notice  Updates a Player's Name.
    /// @param   newName  Bytes32 name to be set as the new Player name.
    function setPlayerName(bytes32 newName) external {
        uint256 tokenId = IPDP(_addressRegistry.pdp()).getPlayerId(msg.sender);

        if (newName == "") revert InvalidName();

        _playerData[tokenId].playerName = newName;

        emit PlayerNameUpdated(tokenId, _playerData[tokenId].playerName, newName);

        uint256 pdtCost = getNameChangeCost();
        if (pdtCost > 0) {
            IERC20 pdt = IERC20(_addressRegistry.pdt());
            uint256 pdtBalance = pdt.balanceOf(msg.sender);
            if (pdtCost > pdtBalance) revert PDTBalanceTooLow(pdtBalance, pdtCost);
            pdt.transferFrom(msg.sender, _addressRegistry.treasury(), pdtCost);
        }
    }

    /// @notice  Updates a Player's Name for a PDT and PXP cost.
    function upgradePlayerRank() external {
        uint256 tokenId = IPDP(_addressRegistry.pdp()).getPlayerId(msg.sender);
        uint64 rank = _playerData[tokenId].playerRank;

        if (rank >= _maxRank) revert MaximumRankReached();

        _playerData[tokenId].playerRank = rank + 1;
        --_playersInRank[rank];
        ++_playersInRank[rank + 1];

        emit PlayerRankUpdated(tokenId, rank, rank + 1);

        (uint256 pdtCost, uint256 pxpCost) = getRankUpCosts(rank);
        if (pxpCost > 0) {
            address pxp = _addressRegistry.pxp();
            uint256 pxpBalance = IERC20(pxp).balanceOf(msg.sender);
            if (pxpCost > pxpBalance) revert PXPBalanceTooLow(pxpBalance, pxpCost);
            IPXP(pxp).burn(msg.sender, pxpCost);
        }
        if (pdtCost > 0) {
            IERC20 pdt = IERC20(_addressRegistry.pdt());
            uint256 pdtBalance = pdt.balanceOf(msg.sender);
            if (pdtCost > pdtBalance) revert PDTBalanceTooLow(pdtBalance, pdtCost);
            pdt.transferFrom(msg.sender, _addressRegistry.treasury(), pdtCost);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Returns the level multiplier for a specific rank (e.g. 15432 = 154.32% multiplier)
    /// @param   rank  Player's rank.
    /// @return  levelMultiplier_  Level multiplier
    function getLevelMultiplier(uint256 rank) public view returns (uint256 levelMultiplier_) {
        return 10000 + (_rankMultiplierBasisPoints * rank);
    }

    /// @notice  Returns the PDT cost of a Player ID public or whitelist mint.
    /// @param   whitelist  Whether to return whitelist or public cost.
    /// @return  pdtCost_  PDT cost of a Player ID mint.
    function getPdpMintCost(bool whitelist) public view returns (uint256 pdtCost_) {
        uint256 currentPdtPrice = IPDTOracle(_addressRegistry.pdtOracle()).getLatestPdtPrice();
        return
            whitelist
                ? (1e18 * _usdCostPdpMintWhitelist) / currentPdtPrice
                : (1e18 * _usdCostPdpMintPublic) / currentPdtPrice;
    }

    /// @notice  Returns the PDT cost of a changing a player's name.
    /// @return  pdtCost_  PDT cost of a changing a player's name.
    function getNameChangeCost() public view returns (uint256 pdtCost_) {
        return (1e18 * _usdCostNameChange) / IPDTOracle(_addressRegistry.pdtOracle()).getLatestPdtPrice();
    }

    /// @notice  Returns the PDT and PXP costs of ranking up.
    /// @param   rank  Current player rank.
    /// @return  pdtCost_  Final PDT cost including 1e18.
    /// @return  pxpCost_  Final PXP cost including 1e18.
    function getRankUpCosts(uint256 rank) public view returns (uint256 pdtCost_, uint256 pxpCost_) {
        uint256 pdtCost = (1e18 * _usdCostRankUp) / IPDTOracle(_addressRegistry.pdtOracle()).getLatestPdtPrice();
        uint256 pxpCost = 2 ** (rank + 1) * _pxpBaseCostRankUp;
        return (pdtCost, pxpCost);
    }

    /// @notice  Returns the AddressRegistry contract address.
    /// @return  addressRegistry_ AddressRegistry contract address.
    function getAddressRegistry() public view returns (address addressRegistry_) {
        return address(_addressRegistry);
    }

    /// @notice  Returns the signer address for claiming PXP.
    /// @return  signerAddress_  Signer address for claiming PXP.
    function getSignerAddress() public view returns (address signerAddress_) {
        return _signerAddress;
    }

    /// @notice  Returns the maximum rank a player can reach.
    /// @return  maxRank_  Maximum rank a player can reach.
    function getMaxRank() public view returns (uint256 maxRank_) {
        return _maxRank;
    }

    /// @notice  Returns the minimum rank required for PDP transfers.
    /// @return  minRankForTransfers_  Minimum rank required for PDP transfers.
    function getMinRankForTransfers() public view returns (uint256 minRankForTransfers_) {
        return _minRankForTransfers;
    }

    /// @notice  Returns the USD Cost for a PDP public mint, paid in PDT if > 0.
    /// @return  usdCostPdpMintPublic_  USD Cost for a PDP public mint.
    function getUsdCostPdpMintPublic() public view returns (uint256 usdCostPdpMintPublic_) {
        return _usdCostPdpMintPublic;
    }

    /// @notice  Returns the USD Cost for a PDP whitelist mint, paid in PDT if > 0.
    /// @return  usdCostPdpMintWhitelist_  USD Cost for a PDP whitelist mint.
    function getUsdCostPdpMintWhitelist() public view returns (uint256 usdCostPdpMintWhitelist_) {
        return _usdCostPdpMintWhitelist;
    }

    /// @notice  Returns the USD Cost for changing your Player Name, paid in PDT if > 0.
    /// @return  usdCostNameChange_  USD Cost for changing your Player Name.
    function getUsdCostNameChange() public view returns (uint256 usdCostNameChange_) {
        return _usdCostNameChange;
    }

    /// @notice  Returns the USD Cost for upgrading your Player Rank, paid in PDT if > 0.
    /// @return  usdCostRankUp_  USD Cost for upgrading your Player Rank.
    function getUsdCostRankUp() public view returns (uint256 usdCostRankUp_) {
        return _usdCostRankUp;
    }

    /// @notice  Returns the Base PXP cost for ranking up.
    /// @return  pxpBaseCostRankUp_  Base PXP cost for ranking up.
    function getPxpBaseCostRankUp() public view returns (uint256 pxpBaseCostRankUp_) {
        return _pxpBaseCostRankUp;
    }

    /// @notice  Returns teh Base PXP earnings multiplier per rank.
    /// @return  rankMultiplierBasisPoints_  Rank multiplier basis points (15432 = 154.32%).
    function getRankMultiplierBasisPoints() public view returns (uint256 rankMultiplierBasisPoints_) {
        return _rankMultiplierBasisPoints;
    }

    /// @notice  Returns the PlayerData for a specific Player ID.
    /// @param   id  Player ID.
    /// @return  playerData_  PlayerData struct for 'id'.
    function getPlayerData(uint256 id) public view returns (PlayerData memory playerData_) {
        return _playerData[id];
    }

    /// @notice  Returns the amount of players in a specific rank.
    /// @param   rank  Player rank to check for.
    /// @return  playersInRank_  Amount of players in 'rank'.
    function getPlayersInRank(uint256 rank) public view returns (uint256 playersInRank_) {
        return _playersInRank[rank];
    }

    /// @notice  Returns the amount of times PXP has been claimed by a specific Player ID.
    /// @param   id  Player ID.
    /// @return  claimCount_ Amount of times PXP has been claimed by 'id'.
    function getClaimCount(uint256 id) public view returns (uint256 claimCount_) {
        return _claimCount[id];
    }

    /// @notice  Returns the amount of PXP claimed by a specific Player ID.
    /// @param   id  Player ID to check for.
    /// @return  pxpClaimed_  Amount of PXP claimed by 'id'.
    function getPxpClaimed(uint256 id) public view returns (uint256 pxpClaimed_) {
        return _pxpClaimed[id];
    }

    /// @notice  Returns the total PXP earned by all players in a specific rank.
    /// @param   rank  Player rank to check for.
    /// @return  totalPxpEarnedPerRank_  Total PXP earned by all players in 'rank'.
    function getTotalPxpEarnedPerRank(uint256 rank) public view returns (uint256 totalPxpEarnedPerRank_) {
        return _totalPxpEarnedPerRank[rank];
    }

    /*///////////////////////////////////////////////////////////////
                                PDP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Checks if msg.sender is the Player ID contract.
    modifier onlyPDPContract() {
        if (msg.sender != _addressRegistry.pdp()) revert NotPDPContract();
        _;
    }

    /// @notice  Initializes the PlayerData upon new PDP mints.
    /// @dev     Called by PDP contract upon mints.
    /// @param   id  Token ID of Player.
    /// @param   name  Bytes32 name of the minter.
    function initializePlayerData(uint256 id, bytes32 name) public onlyPDPContract {
        _playerData[id] = PlayerData(name, 0, uint64(block.timestamp));
        ++_playersInRank[0];
    }

    /*///////////////////////////////////////////////////////////////
                                MANAGER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Updates the maximum rank a player can reach.
    /// @dev     Managers only.
    /// @param   maxRank  Maximum rank a player can reach.
    function setMaxRank(uint256 maxRank) public onlyRole(MANAGER_ROLE) {
        _maxRank = maxRank;
    }

    /// @notice  Updates the minimum rank for transfers.
    /// @dev     Managers only.
    /// @param   minRankForTransfers  Minimum rank for transfers.
    function setMinRankForTransfers(uint256 minRankForTransfers) public onlyRole(MANAGER_ROLE) {
        _minRankForTransfers = minRankForTransfers;
    }

    /// @notice  Updates the USD cost for a PDP Public Mint.
    /// @dev     Managers only. Multiply input by 1e18
    /// @param   usdCostPdpMintPublic  USD cost for a PDP Public Mint.
    function setUsdCostPdpMintPublic(uint256 usdCostPdpMintPublic) public onlyRole(MANAGER_ROLE) {
        _usdCostPdpMintPublic = usdCostPdpMintPublic;
    }

    /// @notice  Updates the USD cost for a PDP Whitelist Mint.
    /// @dev     Managers only. Multiply input by 1e18
    /// @param   usdCostPdpMintWhitelist  USD cost for a PDP Whitelist Mint.
    function setUsdCostPdpMintWhitelist(uint256 usdCostPdpMintWhitelist) public onlyRole(MANAGER_ROLE) {
        _usdCostPdpMintWhitelist = usdCostPdpMintWhitelist;
    }

    /// @notice  Updates the USD Cost for a Player name change.
    /// @dev     Managers only. Multiply input by 1e18
    /// @param   usdCostNameChange  USD Cost for a Player name change.
    function setUsdCostNameChange(uint256 usdCostNameChange) public onlyRole(MANAGER_ROLE) {
        _usdCostNameChange = usdCostNameChange;
    }

    /// @notice  Updates the USD Cost for a Player ranking up.
    /// @dev     Managers only. Multiply input by 1e18
    /// @param   usdCostRankUp  USD Cost for a Player ranking up.
    function setUsdCostRankUp(uint256 usdCostRankUp) public onlyRole(MANAGER_ROLE) {
        _usdCostRankUp = usdCostRankUp;
    }

    /// @notice  Updates the PXP Base Cost for ranking up.
    /// @dev     Managers only. Multiply input by 1e18
    /// @param   pxpBaseCostRankUp  PXP Base Cost for ranking up.
    function setPxpBaseCostRankup(uint256 pxpBaseCostRankUp) public onlyRole(MANAGER_ROLE) {
        _pxpBaseCostRankUp = pxpBaseCostRankUp;
    }

    /// @notice  Updates the Ranking Multiplier value.
    /// @dev     Managers only.
    /// @param   rankMultiplierBasisPoints  Ranking Multiplier value.
    function setRankMultiplierBasisPoints(uint256 rankMultiplierBasisPoints) public onlyRole(MANAGER_ROLE) {
        _rankMultiplierBasisPoints = rankMultiplierBasisPoints;
    }

    /// @notice  Updates the total PXP earned per rank array.
    /// @dev     Managers only.
    /// @param   totalPxpEarnedPerRank  Total PXP Earned Per Rank (Yesterday) array.
    function setTotalPxpEarnedPerRank(uint256[] calldata totalPxpEarnedPerRank) public onlyRole(MANAGER_ROLE) {
        if (totalPxpEarnedPerRank.length != _maxRank + 1) revert InvalidArrayLength();
        _totalPxpEarnedPerRank = totalPxpEarnedPerRank;
    }

    /*///////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Updates the AddressRegistry contract address.
    /// @dev     Admin only.
    /// @param   addressRegistry  AddressRegistry contract address.
    function setAddressRegistry(IAddressRegistry addressRegistry) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addressRegistry = addressRegistry;
    }

    /// @notice  Updates the dummy address used for claiming PXP.
    /// @param   signerAddress  The signer address.
    function setSignerAddress(address signerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _signerAddress = signerAddress;
    }

    /*///////////////////////////////////////////////////////////////
                                PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Returns whether an address is allowed to claim a certain amount of Pxp.
    /// @dev     Signature consists of this contract's address, msg.sender, pxp amount to claim, and the msg.sender's claim count.
    /// @param   signature  User's signature.
    /// @param   pxpAmount  Amount to claim.
    /// @param   claimCount Amount of times msg.sender claimed PXP.
    /// @return  allowed_  Whether the user is allowed to claim _pxpAmount (signature is valid).
    function _verifySignature(
        bytes memory signature,
        uint256 pxpAmount,
        uint256 claimCount
    ) private view returns (bool allowed_) {
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), msg.sender, pxpAmount, claimCount));
        return _signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }
}