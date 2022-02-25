/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/Whitelist.sol


pragma solidity >=0.8.0;





contract Whitelist is AccessControl, ERC1155Holder {
    // Setup the roles
    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant CLEVEL = keccak256("CLEVEL");

    // setup whitelist mapping and predefined whitelist addresses
    mapping(address => bool) whitelistedAddresses;
    address[] public addressArray = [0x06Bf91198317705c564EA5825E7a63B1709d6CE9,0xBFA8Fa89a1Fd2f970E2841b604697957C067aA11,0x80a1031E3AAcA01b4B46B279770b5Bb77374498B,0xfaC83DCC15935Ba8EE5B9eD4AB18EC3334B3faF6,0xA18Adb486Df078644D7bE3012243FF6CcfA8c5ED,0x26dD06a88FECf83c2ABaE76b9B8a603ceD24EFF0,0xDbEB114e22349A67fBd691BA712b8792968bACCA,0xf7d5CC0ad142F229e55e6B55Fb5D21C861BfD8E4,0x85b11756659087F8ACd973deba904015E6Fc8373,0xe31Fc5032D21E3C36f917963b29f392F3A9B38be,0x6aFA49499b53482EbEC2118EAB5A80465dfABE54,0x34345af51f865bf630B95caccd5FfD4B2003921E,0x57D1B862929e786D8aB23e28fea970d8EAE95684,0xB84aAE3a0Db721a7121b5991A1133c74C072Ef5d,0x67212326B32f75A0E2C074da0bb7161c66A09180,0xB627Fa85A00794f721e9f6EC066456A3964Df3ca,0x367465E1aD1c5386C52211Da1f5084787c7366Fa,0xf11bC7f74CbED97bB723F033f3C7b848Db7133ed,0x427F36C3698641fF54571916319B59B686560209,0x580D99Fac7Ff2D47f82b3aD3D5ED487AC2D12863,0x01D7656023e058D32B2320dcF1A7d9f74d8E25E2,0xecf58bde0ad133B943c7C1E4a4CbB961fd8Da2f1,0xd58A829047f8A3D3CB059b0177810403E8E75CE3,0xb55aFcD58b8ee5676260cAeaCE1ed60572Aa35c0,0x8fA796e84878F798cfc86d9c42Ca64437ED2e083,0x2998e53a5560f3CeD2431AB920109232E9f5C1E1,0xbC7F951a7C4C24540570BA80Bba8b08F8C013ED3,0x5Ec294a7181cbd6491C0cD6E7a85a0dBE98BE904,0x2f6EfddA1a850781F3ACc58e234C43597C500D9A,0xCa3f95Abd4A6bB1f176b6De2615A2fA29eF36eFa,0xC8F93520554B710a17e1980CEb779dF0B155e854,0xFE7dAfE370f518A64245fB9ACC3db695d8514537,0xB79B353d98134bc9A8E8Ff492c6848f537aB3502,0xb2B2FEEe41E9A56B22fFC7742256740C30492544,0x9224142Cb941dE922bda23d890DeE10704fA62Bd,0x0D4883711BC4Ef7DAEFa2A50821b8604ebe3a76f,0xC0ab9328ae7FD47b3C176bcd2c5626037eA149A7,0x1cd924b0453ef7c515F8A61a1B12000eC3fb9f82,0x3De0D2cEe3383d01D86935ACF4857580EE743C68,0x38cAc3C869B500C8f5189C9B528E9142a7f5FA36,0xf2FE7602334fE287c8289cF891914F565A996cc1,0x0A04103BC697B6842799f4f6346b2C34Dfb7039f,0xB06D3224055Cc84A5402F2A77182Cc4E6A89bc44,0xaC9040500c5B8b6344e4AF444DAbAd16cdDe7267,0x354Dd66Aa18A22DE76fc1cd89580825570317854,0x95Afb9384D050B886fDcac66D7d6B9DEd389f3a1,0x401bFc62Ee3790dEb36589BBdB01762e423fEAAC,0xb07e202440Ef634eA5df3C046B660d434cBD635F,0x17D22C6aCF271608bFB7C702CeA081A1cb8563e8,0x6e54541C3641Dac0325148b02820Dd084747Ea27,0x7fE8517308E4e198Ab5dFf09730862E9f17720c4,0x170A434778eF2519bB83b1888a50DAAC8740Eeb8,0x74EAbF7a99fC52e7D782aCDB8487d262d220916d,0x4D8AF093Baaa9Ea9Bc3E709E7FfEbC9C2E683E6D,0xD57eEb4014ace4aEEFdF2f9c691B545730581F0A,0xBB6e867427681C35b00dA711A243578D6E123a73,0x98341Eb115a9e5Ca6B50c79F978EB4c7e20505a7,0x603dFe696DcDB3a37063b042a40B1A5E27a18e6F,0x739dB7e0B2434aa24E5FCa02Aad94e2353daBFde,0xdcC1D63CaA4382b554Cbf22ee9e08aB91840d674,0x098f6379Cd3B262C977d8Bc72960dDBCeC274c74,0xd971865Ae0F56BA3D8De271187A90d7fb7382386,0x3bFb730e7940a93189dca48b3051dd06ED9aD417,0xA3c3dADda2147385c2Ea1F21088e542CF68fCfcf,0x24167268058A1dF8c6828fD775e5f4d80b5598Ac,0x17dC94aABCB50EB469EA1740B90Bf4374c6795cF,0x9b206dDE8fb2b2F29F7DB9E659275993468E896f,0x688aE3eCD8B4E72DeEf3DD86b9b6463E273820bB,0xaA6Db36178113E24d444C61303Cb7df5b1C7b33A,0xd69b1e2099fA8BBD883D4143556a582694964198,0x28416bBeCAEF4b0e65CB86e599C0A4af8d5Cc2ed,0xbf93c3AF5E1d2F9E177F5Ce5069dbEb010f411B9,0x1Ac92730d342352E9321EA993C4C7398a298f356,0x04b656FbEE32B4fDcdB5b30008600EA1C5D01A0d,0x0d1Be7118d8Dd35aDe33D45aa4c82DD95f98FcbF,0xb8757035a32D750aB89DBBf93D64812159eFbEcC,0x6Ea022Dd24a912F4F9008A5Ad8E2A34767c7A5d7,0x63e7F0f33E3AFcC0F827657c0A4e16f5c1c3e6b7,0x3531f92800049C7f817574dB3d425a8aC90D07F2,0x513e60f8912d024A5A3C70689cfAe3d84C017421,0xBdc0207c0E361AB17cD4578A0e39f06Ca3B7bCe4,0xe351340C00CA52298B4bd7D5DaF485373468BD60,0xC053cc26b4e833dC0D81FB056ADD2d72Bf76501d,0x951Bf9Dd49dF95de097067518b66A5136beBBf47,0x74674359AB77BAAbB4Ae2eb89D409Dae164f0Ee3,0x0F4d976132c5aD5839E25ab6F5504393ac93678a,0x4ea5f74d3Be7a061EB8437fF90157918815532b6,0x7D07e6f7dEb9d74Bc44Ea40d4E1B0DEA80B9fb5a,0x7E3Bfc343370F39EBF6a004f288075C1c648cae9,0xCf558500516FAb299928dF7513f814D9a2c76E01,0x492A48418ED02b82FE2bA65c4e83d6E47F4ADdaf,0x2128688eB741345Ee654F756c464FabA58a98Acc,0xecB9c79DFE7434a4A5D7Ec97BF259E5Cd69Daab7,0x87451B038b50A5a35c1230dE1ad066F4aFe139c7,0x1a5ED6213df5442516D1bE2C946630C7b6ED2aE8,0x2b1dE4AE11485039F3b9dCbE5ad223bDB231B166,0x9F7CAd5b86fc13EE63E1205050e8D5317e87e28a,0x39b455E8BD4F94A9D246E07493D87C3b5d6b82eC,0x7Ba82EC6AEf9c6B46f00327589441132BCE54226,0x9Bb1FE9399DB4F5ba46920F1722853a868548746];
    
    // setup presale data
    bool public presaleEnabled = false;
    uint256 public salePrice = 0.2 ether;
    address public wethToken;
    address public presaleToken;
    //address public presaleToken = 0xE803193865e73Db35354a96060D21eB3dD3422fB;
    //address public wethToken = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;

    constructor(address _weth, address _presale) {
      // setup the roles
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupRole(CEO, msg.sender);
      _setupRole(CLEVEL, msg.sender);

      // whitelist deployer
      whitelistedAddresses[msg.sender] = true;

      // loop predefined list
      for (uint i=0; i < addressArray.length; i++) {
        whitelistedAddresses[addressArray[i]] = true;
      }

      wethToken = _weth;
      presaleToken = _presale;
    }

    // whitelist check modifier
    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address], "Whitelist: You need to be whitelisted");
      _;
    }

    // add array of addresses to whitelist
    function addUsers(address[] calldata _addressesToWhitelist) external onlyRole(CLEVEL) {
      for(uint i = 0; i < _addressesToWhitelist.length; i++) {
        whitelistedAddresses[_addressesToWhitelist[i]] = true;    
      }
    }

    // check if address is whitelisted
    function verifyUser(address _whitelistedAddress) external view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    // CEO can buy an NFT for free except basic gas
    // Users will pay the sale price and the NFT will be sent from the contract balance.
    function buyNft(uint _amount) external isWhitelisted(msg.sender) {  
        require(IERC1155(presaleToken).balanceOf(address(this), 0) >= _amount, 'Contract balance insufficient');
        if(!hasRole(CEO, msg.sender)) {
            require(presaleEnabled, 'Presale not enabled');
            uint _total = salePrice * _amount;
            require(IERC20(wethToken).transferFrom(msg.sender, address(this), _total), "Transfer failed");
        }
        
        IERC1155(presaleToken).safeTransferFrom(address(this), msg.sender, 0, _amount, "");     
    }

    // @dev owner can withdraw ERC20 tokens sent to the contract
    function withdrawTokens(IERC20 _token) external onlyRole(CEO) {
        uint256 balance = _token.balanceOf(address(this));
        require(balance != 0);
        require(_token.transfer(msg.sender, balance), "Transfer failed");
    }

    // @param _amount the price for the nft, need to set this in wei
    // @dev update sale price of nft
    function updateSalePrice(uint256 _amount) external onlyRole(CLEVEL) {
        salePrice = _amount;
    }

    // @param _status of the presale
    // @dev update the presale status, should be set to false once finished
    function updatePresaleEnabled(bool _status) external onlyRole(CLEVEL) {
        presaleEnabled = _status;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(AccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }
}