/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// File: @openzeppelin/contracts/access/IAccessControl.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/libraries/EIP712Base.sol

pragma solidity ^0.8.3;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns (bytes32) {
        return domainSeparator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
            );
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/libraries/EIP712MetaTransaction.sol

pragma solidity ^0.8.3;


contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version)
        EIP712Base(name, version)
    {}

    function convertBytesToBytes4(bytes memory inBytes)
        internal
        pure
        returns (bytes4 outBytes4)
    {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(
            destinationFunctionSig != msg.sig,
            "functionSignature can not be of executeMetaTransaction method"
        );
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer = ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/libraries/ERC20.sol


pragma solidity ^0.8.9;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/VendingMachine.sol

pragma solidity ^0.8.9;





contract VendingMachine is
    AccessControl,
    IERC721Receiver,
    EIP712MetaTransaction("VendingMachine", "1")
{
    event EtherPurchase(
        address indexed from,
        uint256 indexed itemId,
        uint256 indexed value,
        uint32 itemType,
        bytes varData
    );
    event BonePurchase(
        address indexed from,
        uint256 indexed itemId,
        uint256 indexed value,
        uint32 itemType,
        bytes varData
    );
    event FossilPurchase(
        address indexed from,
        uint256 indexed itemId,
        uint256 indexed value,
        uint32 itemType,
        bytes varData
    );

    event Breed(
        address indexed breeder,
        address indexed breedee,
        uint256 indexed priceBone,
        uint256 priceFossil,
        uint256 dinoOne,
        uint256 dinoTwo
    );
    event BreedWithNFT(
        address indexed breeder,
        uint256 indexed tokenId,
        uint256 dinoOne,
        uint256 dinoTwo
    );

    struct InventoryEntry {
        uint256 index;
        uint256 fossilPrice;
        uint256 bonePrice;
        uint256 ethPrice;
        uint32 quantity;
        uint32 itemType;
    }

    // Constants
    uint32 public constant UINT32_MAX = ~uint32(0);

    // Privileges
    bytes32 public constant PRIV_MANAGE = keccak256("PRIV_MANAGE");
    bytes32 public constant PRIV_WITHDRAW = keccak256("PRIV_WITHDRAW");

    // Core settnigs and inventory
    mapping(uint256 => InventoryEntry) public inventoryEntries;
    uint256[] public itemIds;
    uint256 public burnedFossil = 10000000000000000000;
    uint256 public daoFossil = 10000000000000000000;
    uint256 public devFossil = 130000000000000000000;
    uint256 public burnedBone = 10000000000000000000;
    uint256 public daoBone = 10000000000000000000;
    uint256 public devBone = 7300000000000000000000;
    address public daoAddress = 0x438B08fe98A9fC86f087a1F4b462E923F4752de6;

    // Breed charges + minimums
    // This maps the dino ID (and chain/contract) to a breed charge count.
    // (0-1] billion = original dinos on ethereum
    // (1-2] billion = dapper dinos on ethereum
    // (2-3] billion = baby dinos on polygon
    // Charges start at 0 (or negative if desired) and count up to 5 or 6
    // (depending on which contract is being used)
    mapping(uint => int16) public breedCharges;
    uint256 public fossilFee = 150000000000000000000;
    uint256[6] public boneFeeMinimums = [
        uint256(7500000000000000000000),
        11250000000000000000000,
        18800000000000000000000,
        30600000000000000000000,
        55080000000000000000000,
        104652000000000000000000
    ];

    // Contracts
    ERC20 internal fossilContract =
        ERC20(0x1E22860BD666A71774ae33BE2A5318598E46B900);
    ERC20 internal boneContract =
        ERC20(0x6c6888D42d2FF58e153Fc6F41B3c459F2F67D557);
    IERC721 internal breedNFTContract =
        IERC721(0xAA3DCcd7972578bF3FAEf4EA59638e037789Fc17);

    constructor(address _fossilContract,
                address _boneContract,
                address _breedNFTContract) {

        // Grant other privileges to the contract creator
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
        _setupRole(PRIV_MANAGE, msgSender());
        _setupRole(PRIV_WITHDRAW, msgSender());

        fossilContract = ERC20(_fossilContract);
        boneContract = ERC20(_boneContract);
        breedNFTContract = IERC721(_breedNFTContract);
    }

    function etherPurchase(uint256 _itemId, bytes calldata _varData)
        external
        payable
    {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.ethPrice != 0);
        require(msg.value == inventoryEntry.ethPrice);
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit EtherPurchase(
            msgSender(),
            _itemId,
            msg.value,
            _itemType,
            _varData
        );
    }

    function fossilPurchase(
        uint256 _itemId,
        uint256 _value,
        bytes calldata _varData
    ) external {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.fossilPrice != 0);
        require(_value == inventoryEntry.fossilPrice);
        require(fossilContract.transferFrom(msgSender(), address(this), _value));
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit FossilPurchase(msgSender(), _itemId, _value, _itemType, _varData);
    }

    function bonePurchase(
        uint256 _itemId,
        uint256 _value,
        bytes calldata _varData
    ) external {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.bonePrice != 0);
        require(_value == inventoryEntry.bonePrice);
        require(boneContract.transferFrom(msgSender(), address(this), _value));
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit BonePurchase(msgSender(), _itemId, _value, _itemType, _varData);
    }

    function upsertInventoryItem(
        uint256 _itemId,
        uint256 fossilPrice,
        uint256 bonePrice,
        uint256 ethPrice,
        uint32 quantity,
        uint32 itemType
    ) external onlyRole(PRIV_MANAGE) {
        require(quantity > 0);
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        if (!_inventoryEntryExists(inventoryEntry)) {
            // New item
            inventoryEntry.index = itemIds.length;
            itemIds.push(_itemId);
        }
        inventoryEntry.fossilPrice = fossilPrice;
        inventoryEntry.bonePrice = bonePrice;
        inventoryEntry.ethPrice = ethPrice;
        inventoryEntry.quantity = quantity;
        inventoryEntry.itemType = itemType;
    }

    function deleteInventoryItem(uint256 _itemId)
        external
        onlyRole(PRIV_MANAGE)
    {
        _deleteInventoryItem(_itemId);
    }

    function withdrawFossil(uint256 _amount) external onlyRole(PRIV_WITHDRAW) {
        fossilContract.transfer(msgSender(), _amount);
    }

    function withdrawBone(uint256 _amount) external onlyRole(PRIV_WITHDRAW) {
        boneContract.transfer(msgSender(), _amount);
    }

    function withdrawEther(uint256 _amount) external onlyRole(PRIV_WITHDRAW) {
        payable(msgSender()).transfer(_amount);
    }

    function totalItems() public view returns (uint256) {
        return itemIds.length;
    }

    function _deductInventoryItem(
        InventoryEntry storage inventoryEntry,
        uint256 _itemId
    ) internal {
        if (inventoryEntry.quantity == UINT32_MAX) {
            return;
        } else if (inventoryEntry.quantity > 1) {
            inventoryEntry.quantity--;
        } else {
            _deleteInventoryItem(_itemId);
        }
    }

    function _deleteInventoryItem(uint256 _itemId) internal {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        if (!_inventoryEntryExists(inventoryEntry)) {
            return;
        }
        uint256 lastItemIndex = itemIds.length - 1; // Safe because at least one item must exist (asserted above)
        uint256 lastItemId = itemIds[lastItemIndex];
        itemIds[inventoryEntry.index] = itemIds[lastItemIndex];
        inventoryEntries[lastItemId].index = inventoryEntry.index;
        delete inventoryEntries[_itemId];
    }

    function _inventoryEntryExists(InventoryEntry storage inventoryEntry)
        internal
        view
        returns (bool)
    {
        return inventoryEntry.quantity != 0;
    }

    // Returns the max number of breeds a dino can do. Basically:
    // - 6 for karma dinos
    // - 5 for all other dinos
    // Never fails to return a result, even if that dino ID doesn't exist (yet)
    function maxBreedChargesForDinoID(uint256 _dinoID) public pure returns(uint16) {
        uint16 maxCharges = 5;
        // karma dinos have 6 charges (all others have 5)
        if (_dinoID >= 1000000000 && _dinoID < 2000000000) {
            maxCharges = 6;
        }
        return maxCharges;
    }

    // Increments breed charge for dino, returns whether it was successful
    function _spendBreedCharge(uint256 _dinoID) internal returns(bool) {
        uint16 maxCharges = maxBreedChargesForDinoID(_dinoID);
        int16 curUsedCharges = breedCharges[_dinoID];
        // fail: all charges used
        uint256 uintCurUsedCharges = 0;
        if (curUsedCharges > 0) {
            uintCurUsedCharges = uint256(uint16(curUsedCharges));
        }
        if (uintCurUsedCharges >= maxCharges) {
            return false;
        }
        breedCharges[_dinoID] = curUsedCharges + 1;
        return true;
    }

    // Returns the current bone price minimum for a given dino.
    // REMEMBER TO INCREMENT THE BREED CHARGE COUNTER (breedCharges) IF NEEDED
    // CALL _spendBreedCharge(_dinoID) TO DO THIS
    function boneBreedFeeMinimum(uint256 _dinoID) public view returns(uint256) {
        uint16 maxCharges = maxBreedChargesForDinoID(_dinoID);
        int16 curUsedCharges = breedCharges[_dinoID];
        // special case: admin set number of charges to negative —
        // so we use the cheapest bone fee category
        if (curUsedCharges < 0) {
            curUsedCharges = 0;
        }
        // fail: all charges used, so we return price of 0
        if (uint256(uint16(curUsedCharges)) >= maxCharges) {
            return 0;
        }
        return boneFeeMinimums[uint256(uint16(curUsedCharges))];
    }

    function breed(address _breedee,
                   uint256 _priceBone, uint256 _priceFossil,
                   uint256 _dinoOne, uint256 _dinoTwo) external {

        uint256 boneBreedFeeMinOne = boneBreedFeeMinimum(_dinoOne);
        uint256 boneBreedFeeMinTwo = boneBreedFeeMinimum(_dinoTwo);
        uint256 boneBreedFeeMin = boneBreedFeeMinOne;
        if (boneBreedFeeMinTwo > boneBreedFeeMinOne) {
            boneBreedFeeMin = boneBreedFeeMinTwo;
        }

        // Checking available breed charges
        require(boneBreedFeeMinOne > 0,
               "Dino one has no breed charges remaining");
        require(boneBreedFeeMinTwo > 0,
               "Dino two has no breed charges remaining");

        // Checking fossil payment, minimum, split cover
        require(fossilContract.balanceOf(msgSender()) >= fossilFee,
               "Not enough FOSSIL balance to cover base FOSSIL fee");
        require(_priceFossil >= fossilFee,
               "Not enough FOSSIL paid to cover base FOSSIL fee");
        require(_priceFossil >= burnedFossil + daoFossil + devFossil,
               "FOSSIL price not enough to cover burn and fees");
        require(fossilContract.balanceOf(msgSender()) >= _priceFossil,
               "Not enough FOSSIL");
        require(fossilContract.allowance(msgSender(), address(this)) >= _priceFossil,
               "Not enough FOSSIL allowance");

        // Checking bone payment, minimum, split cover
        require(boneContract.balanceOf(msgSender()) >= boneBreedFeeMin,
               "Not enough BONE balance to cover breed pair minimum");
        require(_priceBone >= boneBreedFeeMin,
               "Not enough BONE paid to cover breed pair minimum");
        require(_priceBone >= burnedBone + daoBone + devBone,
               "BONE price not enough to cover burn and fees");
        require(boneContract.balanceOf(msgSender()) >= _priceBone,
               "Not enough BONE");
        require(boneContract.allowance(msgSender(), address(this)) >= _priceBone,
               "Not enough BONE allowance");

        // Burn FOSSIL
        if (burnedFossil > 0) {
            require(fossilContract.transferFrom(msgSender(), address(this), burnedFossil),
                "Could not transfer burned FOSSIL to this contract");
            fossilContract.burn(burnedFossil);
        }
        // Transfer FOSSIL to us (this contract)
        if (devFossil > 0) {
            require(fossilContract.transferFrom(msgSender(), address(this), devFossil),
                "Could not transfer FOSSIL payment to this contract");
        }
        // Transfer FOSSIL to DAO
        if (daoFossil > 0) {
            require(fossilContract.transferFrom(msgSender(), daoAddress, daoFossil),
               "Could not transfer FOSSIL payment to dao contract");
        }
        // Transfer remaining FOSSIL to breedee
        require(fossilContract.transferFrom(msgSender(), _breedee,
                _priceFossil - daoFossil - devFossil - burnedFossil),
           "Could not transfer FOSSIL payment to breedee");

        // Burn BONE
        if (burnedBone > 0) {
            require(boneContract.transferFrom(msgSender(), address(this), burnedBone),
                "Could not transfer burned BONE to this contract");
            boneContract.burn(burnedBone);
        }
        // Transfer BONE to us (this contract)
        if (devBone > 0) {
            require(boneContract.transferFrom(msgSender(), address(this), devBone),
                "Could not transfer BONE payment to this contract");
        }
        // Transfer BONE to DAO
        if (daoBone > 0) {
            require(boneContract.transferFrom(msgSender(), daoAddress, daoBone),
               "Could not transfer BONE payment to dao contract");
        }
        // Transfer BONE to breedee
        require(fossilContract.transferFrom(msgSender(), _breedee,
                _priceBone - daoBone - devBone - burnedBone),
           "Could not transfer BONE payment to breedee");

        // Spend the breed charges
        require(_spendBreedCharge(_dinoOne),
               "Dino one did not have enough breed charges!");
        require(_spendBreedCharge(_dinoTwo),
               "Dino two did not have enough breed charges!");

        emit Breed(
            msgSender(),
            _breedee,
            _priceBone,
            _priceFossil,
            _dinoOne,
            _dinoTwo
        );
    }

    function onERC721Received(
        address /* operator */,
        address _from,
        uint256 _tokenId,
        bytes calldata _vardata
    ) external override(IERC721Receiver) returns (bytes4)
    {
        address tokenContract = msgSender();
        require(address(breedNFTContract) == tokenContract,
                "Only receives BREED NFTs");
        require(_vardata.length > 0,
                "Must receive breeding data on transfer");

        (uint _dinoOne, uint _dinoTwo) = abi.decode(_vardata, (uint, uint));

        // Spend the breed charges
        require(_spendBreedCharge(_dinoOne),
               "Dino one did not have enough breed charges!");
        require(_spendBreedCharge(_dinoTwo),
               "Dino two did not have enough breed charges!");

        emit BreedWithNFT(
            _from,
            _tokenId,
            _dinoOne,
            _dinoTwo
        );

        return IERC721Receiver.onERC721Received.selector;
    }

    function setBurnedBone(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        burnedBone = _fee;
    }

    function setDaoBone(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        daoBone = _fee;
    }

    function setDevBone(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        devBone = _fee;
    }

    function setBurnedFossil(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        burnedFossil = _fee;
    }

    function setDaoFossil(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        daoFossil = _fee;
    }

    function setDevFossil(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        devFossil = _fee;
    }

    function setDaoAddress(address _dao) external onlyRole(PRIV_MANAGE) {
        daoAddress = _dao;
    }

    function setFossilToken(address _fossilContract) external onlyRole(PRIV_MANAGE) {
        fossilContract = ERC20(_fossilContract);
    }

    function setBoneToken(address _boneContract) external onlyRole(PRIV_MANAGE) {
        boneContract = ERC20(_boneContract);
    }

    function setBreedNFTToken(address _breedNFTContract) external onlyRole(PRIV_MANAGE) {
        breedNFTContract = IERC721(_breedNFTContract);
    }

    // Admin function to set the available number of breed charges for a dino.
    // Remember that _dinoIDs have some amount of billions added to them to
    // determine which contract the dinoID refers to. See `breedCharges`
    // Charges are considered spent when _amount >= 5 (or 6).
    // Negative amounts are allowed, to add extra charges to a dino. I.e. if you
    // set _amount to -10, then 15 (or 16) charges become available.
    function setBreedChargesForDino(uint256 _dinoID, int16 _amount) external onlyRole(PRIV_MANAGE) {
        breedCharges[_dinoID] = _amount;
    }
}