/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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

// File: @openzeppelin/contracts/access/IAccessControl.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: EVOKE/Escrow.sol


pragma solidity 0.8.19;






interface ERC1155 {
    struct Royalties {
        address payable account;
        uint256 percentage;
    }

    function mint(
        address receiver,
        uint256 collectibleId,
        uint256 ntokens,
        string memory IPFS_hash,
        Royalties calldata royalties
    ) external;
}

interface ERC721 {
    struct Royalties {
        address payable account;
        uint256 percentage;
    }

    function mint(
        address receiver,
        uint256 collectibleId,
        string memory IPFSHash,
        Royalties calldata royalties
    ) external;
}

contract EscrowFactory is AccessControl {
    using SafeERC20 for IERC20;

    struct Fee {
        address receiver;
        uint256 percentageValue;
    }

    struct NftInfo {
        string metaHash;
        address royaltyReceiver;
        uint256 royaltyPercentage;
    }

    struct CreatEscrowOptions {
        address receiver;
        address nftAddress;
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        address currency;
    }

    struct Escrow {
        address payable seller;
        address payable buyer;
        address tokenAddress;
        uint256 value;
        address nftContractAddress;
        uint256 tokenId;
        bool isResell;
        uint256 quantity;
        NftInfo nftData;
        Fee[] fees;
    }

    struct NFTBalance {
        address nftContractAddress;
        uint256[] tokensIds;
    }

    struct TokensBalance {
        address tokenAddress;
        uint256 value;
    }

    struct ValuedData {
        uint256 value;
        bool hasValue;
    }

    struct ValuedArrayData {
        uint256[] value;
        bool hasValue;
    }

    event EscrowCreated(
        address indexed seller,
        address indexed buyer,
        address token,
        uint256 value,
        address indexed nftContractAddress,
        uint256 tokenId
    );

    event EscrowRefunded(address indexed buyer, uint256 value);

    event EscrowSettled(
        address indexed seller,
        address indexed buyer,
        uint256 value,
        address indexed nftContractAddress,
        uint256 tokenId
    );

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    address private constant NATIVE_TOKEN_ADDRESS =
        address(0x0000000000000000000000000000000000001010);

    Fee private escrowFee;

    mapping(address => mapping(uint256 => Escrow)) private escrows;
    mapping(address => mapping(address => ValuedData)) private tokensBalance;
    mapping(address => mapping(address => ValuedArrayData)) private nftBalance;
    mapping(address => address[]) private tokensCount;
    mapping(address => address[]) private nftsCount;

    constructor(Fee memory _escrowFee) {
        _setEscrowFee(_escrowFee);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function createEscrow(
        CreatEscrowOptions calldata _escrowOptions,
        bool _isResell,
        NftInfo calldata _nftData,
        Fee calldata _marketPlaceFee
    ) external payable onlyRole(AGENT_ROLE) {
        require(!_isAdmin(), "CreateEscrow:: Admin can not create escrow");
        require(
            _isNFT(_escrowOptions.nftAddress),
            "CreateEscrow:: Not compatible with any NFT standards"
        );
        require(
            _escrowOptions.seller != address(0),
            "CreateEscrow:: Zero address is not allowed"
        );
        require(
            _escrowOptions.receiver != address(0),
            "CreateEscrow:: Zero address is not allowed"
        );

        if (_isResell) {
            require(
                _checkTokenApproval(
                    _escrowOptions.nftAddress,
                    _escrowOptions.tokenId,
                    _escrowOptions.seller
                ),
                "CreateEscrow:: NFT approval is missing"
            );
        }

        Escrow storage newEscrow = escrows[_escrowOptions.nftAddress][
            _escrowOptions.tokenId
        ];

        require(
            !(newEscrow.value > 0 && _escrowOptions.seller != address(0)),
            "CreateEscrow:: Already in escrow"
        );

        if (address(_escrowOptions.currency) == address(NATIVE_TOKEN_ADDRESS)) {
            require(
                msg.value == _escrowOptions.price,
                "CreateEscrow:: Amount received should be equal to value"
            );
        } else {
            IERC20(_escrowOptions.currency).safeTransferFrom(
                payable(msg.sender),
                address(this),
                _escrowOptions.price
            );
        }

        newEscrow.seller = payable(_escrowOptions.seller);
        newEscrow.buyer = payable(_escrowOptions.receiver);
        newEscrow.tokenAddress = _escrowOptions.currency;
        newEscrow.value = _escrowOptions.price;
        newEscrow.nftContractAddress = _escrowOptions.nftAddress;
        newEscrow.tokenId = _escrowOptions.tokenId;
        newEscrow.isResell = _isResell;
        newEscrow.quantity = _escrowOptions.quantity;
        newEscrow.fees.push(_marketPlaceFee);
        newEscrow.fees.push(escrowFee);
        newEscrow.nftData.metaHash = _nftData.metaHash;
        newEscrow.nftData.royaltyReceiver = _nftData.royaltyReceiver;
        newEscrow.nftData.royaltyPercentage = _nftData.royaltyPercentage;

        if (
            tokensBalance[_escrowOptions.seller][_escrowOptions.currency]
                .hasValue
        ) {
            tokensBalance[_escrowOptions.seller][_escrowOptions.currency]
                .value += _escrowOptions.price;
        } else {
            tokensBalance[_escrowOptions.seller][_escrowOptions.currency]
                .hasValue = true;
            tokensBalance[_escrowOptions.seller][_escrowOptions.currency]
                .value = _escrowOptions.price;
            tokensCount[_escrowOptions.seller].push(_escrowOptions.currency);
        }

        if (
            nftBalance[_escrowOptions.receiver][_escrowOptions.nftAddress]
                .hasValue
        ) {
            nftBalance[_escrowOptions.receiver][_escrowOptions.nftAddress]
                .value = [_escrowOptions.tokenId];
        } else {
            nftBalance[_escrowOptions.receiver][_escrowOptions.nftAddress]
                .value
                .push(_escrowOptions.tokenId);
            nftBalance[_escrowOptions.receiver][_escrowOptions.nftAddress]
                .hasValue = true;
            nftsCount[_escrowOptions.receiver].push(_escrowOptions.nftAddress);
        }

        emit EscrowCreated(
            _escrowOptions.seller,
            _escrowOptions.receiver,
            _escrowOptions.currency,
            _escrowOptions.price,
            _escrowOptions.nftAddress,
            _escrowOptions.tokenId
        );
    }

    function endEscrow(
        bool isRefund,
        address _nftContractAddress,
        uint256 _tokenId
    ) external onlyRole(AGENT_ROLE) {
        Escrow storage storedEscrow = escrows[_nftContractAddress][_tokenId];

        require(
            storedEscrow.seller != address(0),
            "ReleaseEscrow:: Escrow not found"
        );

        _settleEscrow(isRefund, storedEscrow);

        _resetState(storedEscrow);
    }

    function myNFTBalance() external view returns (NFTBalance[] memory) {
        NFTBalance[] memory myNFTBalanceArray = new NFTBalance[](
            nftsCount[msg.sender].length
        );
        for (uint256 i = 0; i < nftsCount[msg.sender].length; i++) {
            if (
                nftBalance[msg.sender][nftsCount[msg.sender][i]].hasValue ==
                true
            ) {
                NFTBalance memory currentNFTBalance;
                currentNFTBalance.nftContractAddress = nftsCount[msg.sender][i];
                currentNFTBalance.tokensIds = nftBalance[msg.sender][
                    nftsCount[msg.sender][i]
                ].value;
                myNFTBalanceArray[i] = currentNFTBalance;
            }
        }
        return myNFTBalanceArray;
    }

    function myTokensBalance() external view returns (TokensBalance[] memory) {
        TokensBalance[] memory myTokensBalanceArray = new TokensBalance[](
            tokensCount[msg.sender].length
        );
        for (uint256 i = 0; i < tokensCount[msg.sender].length; i++) {
            if (
                tokensBalance[msg.sender][tokensCount[msg.sender][i]]
                    .hasValue == true
            ) {
                TokensBalance memory currentTokenBalance;
                currentTokenBalance.tokenAddress = tokensCount[msg.sender][i];
                currentTokenBalance.value = tokensBalance[msg.sender][
                    tokensCount[msg.sender][i]
                ].value;
                myTokensBalanceArray[i] = currentTokenBalance;
            }
        }
        return myTokensBalanceArray;
    }

    function withdraw(address _targetToken, address _to)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (_targetToken == address(NATIVE_TOKEN_ADDRESS)) {
            (bool isWithdrawSuccess, ) = payable(_to).call{
                value: address(this).balance
            }("");
            require(isWithdrawSuccess, "Withdraw failed");
        } else {
            IERC20(_targetToken).safeTransfer(
                payable(_to),
                IERC20(_targetToken).balanceOf(address(this))
            );
        }
    }

    function _settleEscrow(bool _isRefund, Escrow memory _storedEscrow)
        internal
    {
        if (_isRefund) {
            _payOut(
                _storedEscrow.value,
                _storedEscrow.tokenAddress,
                _storedEscrow.buyer
            );
            emit EscrowRefunded(_storedEscrow.buyer, _storedEscrow.value);
        } else {
            bool isNFTApproved = _checkTokenApproval(
                _storedEscrow.nftContractAddress,
                _storedEscrow.tokenId,
                _storedEscrow.seller
            );

            if (isNFTApproved) {
                if (
                    IERC721(_storedEscrow.nftContractAddress).supportsInterface(
                        type(IERC721).interfaceId
                    )
                ) {
                    IERC721(_storedEscrow.nftContractAddress).safeTransferFrom(
                        _storedEscrow.seller,
                        _storedEscrow.buyer,
                        _storedEscrow.tokenId
                    );
                } else if (
                    IERC1155(_storedEscrow.nftContractAddress)
                        .supportsInterface(type(IERC1155).interfaceId)
                ) {
                    IERC1155(_storedEscrow.nftContractAddress).safeTransferFrom(
                        _storedEscrow.seller,
                        _storedEscrow.buyer,
                        _storedEscrow.tokenId,
                        _storedEscrow.quantity,
                        ""
                    );
                }

                uint256 restOfAmount;
                uint256 marketPlaceProfit;
                uint256 escrowProfit;
                uint256 royalityProfit;        

                if (_storedEscrow.fees[0].percentageValue > 0) {
                    marketPlaceProfit =
                        (_storedEscrow.value *
                            _storedEscrow.fees[0].percentageValue) /
                        10000;
                }
                if (_storedEscrow.fees[1].percentageValue > 0) {
                    escrowProfit =
                        (_storedEscrow.value *
                            _storedEscrow.fees[1].percentageValue) /
                        10000;
                }
                if (_storedEscrow.nftData.royaltyPercentage > 0) {
                    royalityProfit =
                        (_storedEscrow.value *
                            _storedEscrow.nftData.royaltyPercentage) /
                        10000;
                }

                restOfAmount =
                    _storedEscrow.value -
                    (marketPlaceProfit + escrowProfit + royalityProfit);

                _payOut(
                    marketPlaceProfit,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.fees[0].receiver
                );

                _payOut(
                    escrowProfit,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.fees[1].receiver
                );

                _payOut(
                    royalityProfit,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.nftData.royaltyReceiver
                );

                _payOut(
                    restOfAmount,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.seller
                );

                emit EscrowSettled(
                    _storedEscrow.seller,
                    _storedEscrow.buyer,
                    _storedEscrow.value,
                    _storedEscrow.nftContractAddress,
                    _storedEscrow.tokenId
                );
            }
            if (!isNFTApproved && !_storedEscrow.isResell) {
                _mintNFT(
                    _storedEscrow.buyer,
                    _storedEscrow.nftContractAddress,
                    _storedEscrow.tokenId,
                    _storedEscrow.quantity,
                    _storedEscrow.nftData
                );
                uint256 restOfAmount;
                uint256 marketPlaceProfit;
                uint256 escrowProfit;

                if (_storedEscrow.fees[0].percentageValue > 0) {
                    marketPlaceProfit =
                        (_storedEscrow.value *
                            _storedEscrow.fees[0].percentageValue) /
                        10000;
                }
                if (_storedEscrow.fees[1].percentageValue > 0) {
                    escrowProfit =
                        (_storedEscrow.value *
                            _storedEscrow.fees[1].percentageValue) /
                        10000;
                }

                restOfAmount =
                    _storedEscrow.value -
                    (marketPlaceProfit + escrowProfit);

                _payOut(
                    marketPlaceProfit,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.fees[0].receiver
                );

                _payOut(
                    escrowProfit,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.fees[1].receiver
                );

                _payOut(
                    restOfAmount,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.seller
                );

                emit EscrowSettled(
                    _storedEscrow.seller,
                    _storedEscrow.buyer,
                    _storedEscrow.value,
                    _storedEscrow.nftContractAddress,
                    _storedEscrow.tokenId
                );
            }
            if (!isNFTApproved && _storedEscrow.isResell) {
                _payOut(
                    _storedEscrow.value,
                    _storedEscrow.tokenAddress,
                    _storedEscrow.buyer
                );
                emit EscrowRefunded(_storedEscrow.buyer, _storedEscrow.value);
            }
        }
    }

    function _payOut(
        uint256 _amount,
        address _tokenAddress,
        address _to
    ) internal {
        if (_amount > 0 && _to != address(0)) {
            if (address(_tokenAddress) == address(NATIVE_TOKEN_ADDRESS)) {
                (bool isPayOutSuccess, ) = payable(_to).call{value: _amount}(
                    ""
                );
                require(isPayOutSuccess, "Payout:: failed");
            } else {
                IERC20(_tokenAddress).safeTransfer(payable(_to), _amount);
            }
        }
    }

    function _setEscrowFee(Fee memory _escrowFee) internal {
        require(
            _escrowFee.percentageValue <= 5000,
            "Fee: max allowed perecentage is 50%"
        );
        escrowFee = _escrowFee;
    }

    function _isNFT(address _nftAddress) internal view returns (bool) {
        return (IERC721(_nftAddress).supportsInterface(
            type(IERC721).interfaceId
        ) ||
            IERC1155(_nftAddress).supportsInterface(
                type(IERC1155).interfaceId
            ));
    }

    function _isAdmin() internal view returns (bool) {
        return (hasRole(ADMIN_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    }

    function _resetState(Escrow memory storedEscrow) internal {
        uint256 newTokenBalance = tokensBalance[storedEscrow.seller][
            storedEscrow.tokenAddress
        ].value - storedEscrow.value;
        tokensBalance[storedEscrow.seller][storedEscrow.tokenAddress]
            .value = newTokenBalance;
        if (newTokenBalance <= 0) {
            delete tokensBalance[storedEscrow.seller][
                storedEscrow.tokenAddress
            ];
            tokensCount[storedEscrow.seller] = _removeArrayValueAddress(
                storedEscrow.tokenAddress,
                tokensCount[storedEscrow.seller]
            );
        }
        uint256[] memory newNFTBalance = _removeArrayValueUnit(
            storedEscrow.tokenId,
            nftBalance[storedEscrow.buyer][storedEscrow.nftContractAddress]
                .value
        );
        nftBalance[storedEscrow.buyer][storedEscrow.nftContractAddress]
            .value = newNFTBalance;
        if (newNFTBalance.length == 0) {
            delete nftBalance[storedEscrow.buyer][
                storedEscrow.nftContractAddress
            ];
            nftsCount[storedEscrow.buyer] = _removeArrayValueAddress(
                storedEscrow.nftContractAddress,
                nftsCount[storedEscrow.buyer]
            );
        }
        delete escrows[storedEscrow.nftContractAddress][storedEscrow.tokenId];
    }

    function _checkTokenApproval(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller
    ) internal view returns (bool) {
        if (
            IERC721(_nftContractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        ) {
            if (
                IERC721(_nftContractAddress).getApproved(_tokenId) !=
                address(this)
            ) {
                return false;
            } else {
                return true;
            }
        } else if (
            IERC1155(_nftContractAddress).supportsInterface(
                type(IERC1155).interfaceId
            )
        ) {
            if (
                IERC1155(_nftContractAddress).isApprovedForAll(
                    _seller,
                    address(this)
                ) &&
                IERC1155(_nftContractAddress).balanceOf(_seller, _tokenId) >= 1
            ) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function _mintNFT(
        address _receiver,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        NftInfo memory _nftData
    ) internal {
        if (IERC721(_nftAddress).supportsInterface(type(IERC721).interfaceId)) {
            ERC721.Royalties memory royalties = ERC721.Royalties(
                payable(_nftData.royaltyReceiver),
                _nftData.royaltyPercentage
            );
            ERC721(_nftAddress).mint(
                _receiver,
                _tokenId,
                _nftData.metaHash,
                royalties
            );
        } else if (
            IERC1155(_nftAddress).supportsInterface(type(IERC1155).interfaceId)
        ) {
            ERC1155.Royalties memory royalties = ERC1155.Royalties(
                payable(_nftData.royaltyReceiver),
                _nftData.royaltyPercentage
            );
            ERC1155(_nftAddress).mint(
                _receiver,
                _tokenId,
                _quantity,
                _nftData.metaHash,
                royalties
            );
        }
    }

    function _removeArrayValueUnit(
        uint256 _input,
        uint256[] storage _targetArray
    ) internal returns (uint256[] memory _resultArray) {
        for (uint256 i = 0; i < _targetArray.length; i++) {
            if (_input == _targetArray[i]) {
                _targetArray[i] = _targetArray[_targetArray.length - 1];
                _targetArray.pop();
            }
        }
        return _targetArray;
    }

    function _removeArrayValueAddress(
        address _input,
        address[] storage _targetArray
    ) internal returns (address[] memory) {
        for (uint256 i = 0; i < _targetArray.length; i++) {
            if (_input == _targetArray[i]) {
                _targetArray[i] = _targetArray[_targetArray.length - 1];
                _targetArray.pop();
            }
        }
        return _targetArray;
    }
}