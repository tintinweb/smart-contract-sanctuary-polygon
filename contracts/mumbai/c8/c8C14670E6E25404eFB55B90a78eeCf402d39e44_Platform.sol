/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// 
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 
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


// File @openzeppelin/contracts/utils/[email protected]

// 
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


// File @openzeppelin/contracts/access/[email protected]

// 
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


// File contracts/IERC721.sol

// 

pragma solidity ^0.8.1;
/**
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 is IERC165 {
    /**
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


// File contracts/extensions/IERC721Enumerable.sol

// 

pragma solidity ^0.8.1;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x780e9d63.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Count NFTs tracked by this contract
     * @return A count of valid NFTs tracked by this contract, where each one of
     *  them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Enumerate valid NFTs
     * @dev Throws if `_index` >= `totalSupply()`.
     * @param _index A counter less than `totalSupply()`
     * @return The token identifier for the `_index`th NFT,
     *  (sort order not specified)
     */
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Enumerate NFTs assigned to an owner
     * @dev Throws if `_index` >= `balanceOf(_owner)` or if
     *  `_owner` is the zero address, representing invalid NFTs.
     * @param _owner An address where we are interested in NFTs owned by them
     * @param _index A counter less than `balanceOf(_owner)`
     * @return The token identifier for the `_index`th NFT assigned to `_owner`,
     *  (sort order not specified)
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


// File contracts/IERC3525.sol

// 

pragma solidity ^0.8.0;
/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xd5358140.
 */
interface IERC3525 is IERC165, IERC721 {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(uint256 _tokenId, address _operator, uint256 _value) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) external payable;

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving ERC3525 tokens.
     * @dev This function MUST create a new ERC3525 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(uint256 _fromTokenId, address _to, uint256 _value) external payable returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 
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


// File contracts/IPlatformSFT.sol

//

pragma solidity ^0.8.0;

interface IPlatformSFT {
    function mint(address mintTo_, uint256 slot_, uint256 value_) external returns (uint256);

    function mintValue(uint256 tokenId_, uint256 value_) external;

    // function burn(uint256 tokenId_) external; // to avoid exceed size

    function burnValue(uint256 tokenId_, uint256 burnValue_) external;
}


// File contracts/Roles.sol

// 
pragma solidity >0.8.0;
contract Roles is AccessControl {
    error NotAuthorizedError(address sender);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address _owner) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAuthorizedError(_msgSender());
        }
        _;
    }

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            revert NotAuthorizedError(_msgSender());
        }
        _;
    }
}


// File contracts/Platform.sol

// 
pragma solidity ^0.8.0;
interface IGame {
    function startGame(address player, uint256 dollar, uint256 tokenId, bytes memory gameArgs)
        external
        payable
        returns (uint256);
}

interface IDistributeFT {
    function distributeFT(address ft, uint64 mainType, uint64 subType, address player, uint256 amount) external;
}

interface ICalculateShare {
    function calculateShare(uint64 mainType, uint64 subType, address player, uint256 dollar)
        external
        returns (uint256);
}

interface IClean {
    function clean(address SFT) external returns (uint256);
}

// Roles to allow multi-admin to avoid upgrade error
contract Platform is Roles {
    uint256 public constant PRECISION = 1e6;
    address public SFT;
    address public defaultSuperNode;

    uint256 public constant minWeightedDollar = 300 * (10 ** 36);

    mapping(address => bool) public isAnyNode;

    address[] public superNodeList; // not include defaultSuperNode
    address[] public nodeList; // not include selfNode

    // player => agent
    mapping(address => address) public agentOf;

    // agent => child-player's total dollars
    mapping(address => uint256) public weightedDollar;
    // mapping(uint64 => mapping(uint256 => uint256));

    // agent => child-player's account
    mapping(address => uint64) public level2nd;

    // agent => grandchild-player's account
    mapping(address => uint64) public level3th;

    // Node => SuperNode // L2 >= 2 && L3 >= 4 Mount/Bind
    mapping(address => address) public superOf;
    // Player/Node => Node // Node => NodeSelf // Player => Node;
    mapping(address => address) public channelOf;

    // superNode => selfNode // superNode and selfNode belong to the same person
    mapping(address => address) public selfNodeOf;

    // dailyRecord[node or superNode][date] += wd;
    mapping(address => mapping(uint256 => uint256)) public dailyRecord;

    // playerDailyRecord[player][date] += wd;
    mapping(address => mapping(uint256 => uint256)) public playerDailyRecord;

    mapping(uint64 => mapping(uint64 => bool)) public pause;

    event SwitchPause(uint64 mainType, uint64 subType, bool state);
    event AddGame(uint64 mainType, uint64 subType, address game);
    event SetSFT(address sft);
    event SetDefaultSuperNode(address superNode);
    event SetSuperNode(address superNode, address selfNode);
    event UpgradeAndBind(address node, address superNode);
    event ChannelUpdated(address addr, address channel);
    event ConfigMainType(uint64 mainType, address FT, address shareCalc, address[] pools, uint256[] ratios);

    constructor(address superNode, address owner) Roles(owner) {
        require(superNode != address(0), "Zero address");
        defaultSuperNode = superNode;
        selfNodeOf[superNode] = superNode;
        isAnyNode[superNode] = true;
    }

    function superNodeListLength() external view returns (uint256) {
        return superNodeList.length;
    }

    function nodeListLength() external view returns (uint256) {
        return nodeList.length;
    }

    function isNode(address addr) public view returns (bool) {
        return addr != address(0) && channelOf[addr] == addr;
    }

    function isSuperNode(address addr) public view returns (bool) {
        return addr != address(0) && selfNodeOf[addr] != address(0);
    }

    function areBothNodes(address addr) external view returns (bool, bool, address) {
        address agent = agentOf[addr];
        return (isNode(addr), isNode(agent), agent);
    }

    // considering special player (1. selfNode of a superNode; 2.common Node)
    function relationOf(address player) external view returns (address superNode, address node, address agent) {
        agent = agentOf[player];
        node = channelOf[player];
        superNode = superOf[node];
        if (superNode == address(0)) {
            superNode = defaultSuperNode;
        }
    }

    function switchPause(uint64 mainType, uint64 subType, bool state) external onlyOwner {
        pause[mainType][subType] = state;
        emit SwitchPause(mainType, subType, state);
    }

    function addGames(uint64 mainType, uint64 subType, address game) external onlyOwner {
        require(!closed[mainType], "Already closed");
        require(address(games[mainType][subType]) == address(0), "Already initialized");
        games[mainType][subType] = IGame(game);
        emit AddGame(mainType, subType, game);
    }

    function initSFT(address sft) external onlyOwner {
        require(SFT == address(0), "Already initialized");
        SFT = sft;
        emit SetSFT(sft);
    }

    // no need to delete selfNodeOf[defaultSuperNode];
    function setDefaultSuperNode(address superNode) external onlyOwner {
        require(superNode != address(0), "Args error");
        require(!isAnyNode[superNode], "Already set as Node or SuperNode"); // to avoid a node as superNode

        defaultSuperNode = superNode;
        selfNodeOf[superNode] = superNode; // to record history defaultSuperNode

        emit SetDefaultSuperNode(superNode);
        isAnyNode[superNode] = true;
    }

    // considering msg.sender is a selfNode
    function upgradeAndBind(address superNode) external {
        require(
            level2nd[msg.sender] >= 2 && level3th[msg.sender] >= 4 && weightedDollar[msg.sender] >= minWeightedDollar,
            "Can not upgrade"
        );
        require(superOf[msg.sender] == address(0), "Already Upgraded");
        // history defaultSuperNode is forbidden
        require(isSuperNode(superNode) && selfNodeOf[superNode] != superNode, "Super node error");
        superOf[msg.sender] = superNode;
        channelOf[msg.sender] = msg.sender; // cut the old channel if have, force to set the new channel
        nodeList.push(msg.sender);
        emit ChannelUpdated(msg.sender, msg.sender);
        emit UpgradeAndBind(msg.sender, superNode);

        isAnyNode[msg.sender] = true;
    }

    // superNode and defaultNode belong to the same person
    function setSuperNode(address superNode, address selfNode) external onlyManager {
        require(
            superNode != selfNode && superNode != address(0) && selfNode != address(0) && selfNode != address(this),
            "Args error"
        );
        require(agentOf[superNode] == address(0) && level2nd[superNode] == 0, "Super node has relation");
        require((!isAnyNode[superNode]) && (!isAnyNode[selfNode]), "Already set");

        // superNode not have any relation, totally new address
        // selfNode is not a node, has no channel, may be a agent or player
        superOf[selfNode] = superNode;
        selfNodeOf[superNode] = selfNode;
        channelOf[selfNode] = selfNode;
        superNodeList.push(superNode);

        emit ChannelUpdated(selfNode, selfNode);
        emit SetSuperNode(superNode, selfNode);

        isAnyNode[superNode] = true;
        isAnyNode[selfNode] = true;
    }

    event PlayGame(
        address player,
        address agent,
        uint256 dollar,
        uint64 mainType,
        uint64 subType,
        uint256 tokenId,
        uint256 requestId,
        bytes gameArgs
    );

    event PassiveAgent(address agent, address sAgent);

    function play(
        address agent, // input by frontend
        uint256 dollar,
        uint64 mainType,
        uint64 subType,
        uint256 tokenId, // for receive share, address(0) means to mint
        bytes memory gameArgs // abi.encode() by frontend, abi.decode by game contract if needed
    ) public payable {
        require(!pause[mainType][subType], "Paused");
        require(!closed[mainType], "Closed");

        // Step1 build relation (player, agent) tree
        address player = msg.sender;
        require(player.code.length == 0, "Contract player not allowed");
        require(agent != player, "Agent and player are same");
        require(selfNodeOf[player] == address(0), "Player is a super node");
        require(selfNodeOf[agent] == address(0), "Agent is a super node");

        address _agent = agentOf[player];
        if (agent == address(0)) {
            agent = _agent;
        }
        if (_agent != address(0)) {
            require(agent == _agent, "Agent mismatch");
        }

        uint256 wd = dollar * weight[mainType];
        if (agent != address(0)) {
            weightedDollar[agent] += wd;
            buildRelation(player, agent, _agent);
        }

        record(player, wd);

        // Step2 calculate share
        uint256 shareAmount = ICalculateShare(shareCalc[mainType]).calculateShare(mainType, subType, player, dollar);

        // Step3 mint nft of slot(mainType), if tokenId == 0; or revert for invalid tokenId;
        tokenId = mintSFT(player, tokenId, mainType, shareAmount);

        // Step4 distribute to several pools
        distributeFT(mainType, subType, player, dollar);

        // Step5 trigger the game -> random-oracle
        IGame game = games[mainType][subType];
        require(address(game) != address(0), "Game is not existed");
        uint256 requestId = game.startGame{value: msg.value}(player, dollar, tokenId, gameArgs);

        emit PlayGame(player, agent, dollar, mainType, subType, tokenId, requestId, gameArgs);
    }

    function record(address player, uint256 wd) private {
        uint256 _date = block.timestamp/(1 days);
        playerDailyRecord[player][_date] += wd;
        address _node = channelOf[player];
        if (_node != address(0)) {
            dailyRecord[superOf[_node]][_date] += wd; // SuperNode
            dailyRecord[_node][_date] += wd;
        }
    }

    function buildRelation(address player, address agent, address _agent) internal {
        // Make sure that Player is not a [Common-Node or Self-Node]
        // build agent
        if (_agent == address(0)) {
            agentOf[player] = agent;
            level2nd[agent] += 1;
            address sAgent = agentOf[agent];
            if (sAgent != address(0)) {
                level3th[sAgent] += 1;
            } else {
                agentOf[agent] = address(this);
                emit PassiveAgent(agent, address(this));
            }
        }
        // build channel
        if (channelOf[player] == address(0)) {
            address channel = channelOf[agent];
            if (channel != address(0)) {
                channelOf[player] = channel;
                emit ChannelUpdated(player, channel);
            }
        }
    }

    // divide to different pools, Pools(Game-Returns), (2%) to Jack-Pool if opened
    function distributeFT(uint64 mainType, uint64 subType, address player, uint256 amount) internal {
        // (address FT, address[] memory _pools, uint256[] memory _ratios) = poolList(mainType);
        address FT = payment[mainType];
        address[] memory _pools = pools[mainType];
        uint256[] memory _ratios = ratios[mainType];
        // IERC20(FT).transferFrom(player, address(this), amount);
        // BE CAREFUL, part1 + part2 ... != amount due to directly distribute to pools
        uint256 length = _pools.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 part = amount * _ratios[i] / PRECISION;
            IERC20(FT).transferFrom(player, _pools[i], part);
            IDistributeFT(_pools[i]).distributeFT(FT, mainType, subType, player, part);
        }
    }

    function mintSFT(address player, uint256 tokenId, uint256 slot, uint256 share) internal returns (uint256) {
        if (tokenId == 0) {
            uint256 balance = IERC3525(SFT).balanceOf(player);
            if (balance > 0) {
                // to find the first matched tokenId
                for (uint256 i = 0; i < balance; i++) {
                    tokenId = IERC721Enumerable(SFT).tokenOfOwnerByIndex(player, i);
                    if (IERC3525(SFT).slotOf(tokenId) == slot) {
                        IPlatformSFT(SFT).mintValue(tokenId, share);
                        return tokenId;
                    }
                }
            }
            tokenId = IPlatformSFT(SFT).mint(player, slot, share);
        } else if (IERC3525(SFT).ownerOf(tokenId) == player && IERC3525(SFT).slotOf(tokenId) == slot) {
            IPlatformSFT(SFT).mintValue(tokenId, share);
        } else {
            revert("Token is not owned by the player");
        }
        return tokenId;
    }

    mapping(uint64 => bool) public closed;
    mapping(uint64 => address) public payment;
    mapping(uint64 => uint256) public weight;
    mapping(uint64 => address[]) public pools;
    mapping(uint64 => uint256[]) public ratios;
    mapping(uint64 => address) public shareCalc;
    mapping(uint64 => mapping(uint64 => IGame)) public games;

    // might set Oracle as Manager, frequently update this
    function setWeight(uint64 mainType, uint256 _weight) external onlyManager {
        // No need to require(_weight != 0) for some mainTypes not count into score
        weight[mainType] = _weight;
    }

    function poolList(uint64 mainType)
        external
        view
        returns (address FT, address[] memory _pools, uint256[] memory _ratios)
    {
        FT = payment[mainType];
        uint256 length = ratios[mainType].length;
        _pools = new address[](length);
        _ratios = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            _pools[i] = pools[mainType][i];
            _ratios[i] = ratios[mainType][i];
        }
    }

    function configMainType(
        uint64 mainType,
        uint256 _weight,
        address FT,
        address _shareCalc,
        address[] memory _pools,
        uint256[] memory _ratios
    ) external onlyOwner {
        require(_ratios.length == _pools.length, "Length error");
        require(payment[mainType] == address(0), "Already Configured");
        require(FT != address(0) && _shareCalc != address(0), "Wrong address");

        payment[mainType] = FT;
        weight[mainType] = _weight;
        shareCalc[mainType] = _shareCalc;
        delete pools[mainType];
        delete ratios[mainType];
        uint256 length = _ratios.length;
        uint256 acc;

        for (uint256 i = 0; i < length; i++) {
            require(_pools[i] != address(0), "Wrong address");
            pools[mainType].push(_pools[i]);
            ratios[mainType].push(_ratios[i]);
            acc += _ratios[i];
        }
        require(acc == PRECISION, "Ratios error");
        emit ConfigMainType(mainType, FT, _shareCalc, _pools, _ratios);
    }

    // function clean(address receiver) external onlyPlatform returns (uint256);
    function shutDown(uint64 mainType, address gamePool) external onlyOwner {
        // require(gamePool != address(0), "Zero address");
        bool checked = false;
        for (uint256 i = 0; i < pools[mainType].length; i++) {
            if (pools[mainType][i] == gamePool) {
                checked = true;
                break;
            }
        }
        require(checked, "Wrong address");

        address FT = payment[mainType];
        uint256 balance = IClean(gamePool).clean(SFT);
        IDistributeFT(SFT).distributeFT(FT, mainType, 0, address(0), balance);
        // payment[mainType] = address(this);
        // do not modify payment[mainType], SFT need it to burn value and withdraw shares
        delete pools[mainType];
        delete ratios[mainType];
        delete shareCalc[mainType];
        closed[mainType] = true;
    }
}