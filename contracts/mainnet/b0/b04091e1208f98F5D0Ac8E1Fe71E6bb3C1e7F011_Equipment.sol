/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

// File: contracts/IAOM.sol

pragma solidity 0.8.11;

interface IAOM {
    function mintFT(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function mintNFT(address account) external returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external returns (uint256[] memory);
}

// File: contracts/IEquipment.sol

pragma solidity 0.8.11;

interface IEquipment {
    struct EquipItem {
        uint256 token1155Id; //Token Id
        uint256 belong; // belong to specific character
        bool isEquiped; // Indicate you have been equipped this item.
        bool isUndefined; // Random magic property ready to find. but need a few 0.001bnb;     x2
        bool isAncient; // drop from monster
        bool untradable;
        uint8 enhanceLevel; // Updagrade item level.
        uint8 bodyPart; //  Equipment type refers to bodyPart.
        uint8 rarity; // from 1~5 and 6 is event type for specical purposes.
        uint8 weaponType; // Only available in weapon include sowrd axe. etc..   x4
        uint8 t00; // Basic Solt type 00
        uint8 t01; // Basic Solt type 01
        uint8 t1; // Basic Solt type 1  normal
        uint8 t2; // Basic Solt type 2  rare
        uint8 t3; // Basic Solt type 3  legendary
        uint8 t4; // Basic Solt type 4  epic
        uint8 t5; // Basic Solt type 5  maigc    x7
        uint8 skin; // for style pattern
        uint8 set; // for reserved1  use fro  set
        uint8 gem; // for reserved1  use fro  set
        uint24 legacyId; // for unique item;
        uint8 world; // which world
        uint24 fromScene; // which scene
        uint8 transferable;
        uint24 equipmentLv; //  Equipment level
        uint24 v00; // Basic Solt Value 00
        uint24 v01; // Basic Solt Value 01
        uint24 v1; // Basic Solt value 1  normal
        uint24 v2; // Basic Solt value 2  normal
        uint8 v3; // Basic Solt value 3  normal
        uint8 v4; // Basic Solt value 4  normal
        uint8 v5; // Basic Solt value 5  normal
    }

    function isArmed(uint256 _charId, uint8 bodyPart) external view returns (bool);

    function OwnItem(uint256 tokenId, address caller) external view returns (bool);

    function melt(uint256 tokenId, address addr) external;

    function upgrade(uint256 tokenId) external returns (bool);

    function getEquippedIdsByCharId(uint256 _charId) external view returns (uint256[] memory);

    function getEquipment(uint256 tokenId) external view returns (IEquipment.EquipItem memory);

    function getEquipmentList(address addr) external view returns (IEquipment.EquipItem[] memory);

    function getEquipmentByIds(uint256[] memory tokenIds) external view returns (IEquipment.EquipItem[] memory);

    function getEquipmentCount(address account) external view returns (uint256);

    // function generateEquipment(
    //     uint16 equipmentLv,
    //     uint8[] calldata bodyParts,
    //     uint256 amount,
    //     uint8 from
    // ) external;

    function createItem(IEquipment.EquipItem memory item, address minter) external;

    function equipItem(uint256 _charId, uint256 _itemId) external;

    function unequipItem(uint256 _charId, uint256[] memory tokenIds) external;

    function identify(uint256 tokenId) external payable;

    function TransferItemOwnership(uint256 _itemId, uint256 _toCharId) external payable;

    function DangerUpdate(uint256 tokenId1155, IEquipment.EquipItem memory equipitem) external;
}

// File: contracts/ICharacter.sol

pragma solidity 0.8.11;

interface ICharacter {
    struct CharacterInfo {
        // ----- id ------
        uint256 tokenId; //character token id
        uint24 roleId; //same as passive skill
        uint8 rarity;
        // ------ 4 demension
        uint16 STR; //65535
        uint16 DEX; // 65535
        uint16 INT; //65535
        uint16 VIT; //65535
        uint16 point; // stat point
        // growth
        uint128 exp; // experience value; 1.1Q 1,125,899,906,842,623
        uint8 growth; // 5~10  255
        uint24 level; // 65535
        // passive skill
        uint8 ps1;
        uint8 ps2;
        uint8 ps3;
        uint8 ps4;
        uint8 ps5;
        uint8 ps6;
        // rule
        bool isVio;
        uint8 channel;
        uint8 world;
        // for adventure purpose
        uint16 badge; // to record badge level
        uint16 lastAdventureDay; //  65536 days is equil to = 180yrs
        uint8 maxAdventureTimesPerDay;
        uint8 AdventuredTimes;
    }

    function createRole(address minter, uint8 role) external;

    function DangerUpdate(uint256 tokenId, ICharacter.CharacterInfo memory charInfo) external;

    function levelup(uint256 tokenId) external payable returns (bool);

    function usePoint(
        uint256 tokenId,
        uint16 STR,
        uint16 DEX,
        uint16 INT,
        uint16 VIT
    ) external payable;

    function gainExp(uint256 tokenId, uint128 exp) external;

    function work(
        uint256 tokenId,
        uint8 cost,
        address player
    ) external;

    function badge(
        uint256 tokenId,
        address player,
        uint16 value
    ) external;

    function getCharactersList(address addr) external view returns (ICharacter.CharacterInfo[] memory);

    function getCharacter(uint256 token1155Id) external view returns (ICharacter.CharacterInfo memory);

    function getCharacterByIds(uint256[] calldata token1155Ids)
        external
        view
        returns (ICharacter.CharacterInfo[] memory);

    function hasCharacter(address addr, uint256 tokenId) external view returns (bool);

    function getNextExp(uint256 cur) external pure returns (uint48);

    function getDays() external view returns (uint256);

    function born() external view returns (uint256);

    function melt(uint256 tokenId, address addr) external;

    function onMarketTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /** shopping online */

    function extendMaxAdventureTimes(
        uint256 tokenId,
        uint8 times,
        address player
    ) external;
}

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

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
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
            return '0x00';
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
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
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
                        'AccessControl: account ',
                        Strings.toHexString(uint160(account), 20),
                        ' is missing role ',
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
        require(account == _msgSender(), 'AccessControl: can only renounce roles for self');

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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/Equipment.sol

pragma solidity 0.8.11;

contract Equipment is IEquipment, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;

    error bodyPartIsNotSupportedYet(uint8);
    error rarityTypeIsNotSupportedYet(uint8);

    event FindEquipment(address indexed owner, uint256 indexed itemId, IEquipment.EquipItem equipItem);
    event NewItemMaster(address indexed owner, uint256 indexed master, uint256 indexed itemId);
    uint256 private identifyFee = 1 ether;
    uint256 private maintainFee = 0.00875 ether;
    uint256 private seed;
    address private token1155Contract;
    address private charAddress;
    address private erc20Contract;

    bytes32 public constant MARKET_ROLE = keccak256('MARKET');
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant UPDATER_ROLE = keccak256('UPDATER');

    mapping(uint256 => IEquipment.EquipItem) private idToEquipment;

    mapping(address => EnumerableSet.UintSet) private addressToUintSet;

    mapping(uint256 => EnumerableSet.UintSet) private charIdToEquippedItems;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setIdentifyFee(uint256 val) external onlyRole(DEFAULT_ADMIN_ROLE) {
        identifyFee = val;
    }

    function setMaintainFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maintainFee = fee;
    }

    function connectContracts(
        address erc1155,
        address charAddr,
        address market,
        address enhance,
        address giftV1Role,
        address contiV1,
        address erc20
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token1155Contract = erc1155;
        charAddress = charAddr;
        _grantRole(MARKET_ROLE, market);
        _grantRole(UPDATER_ROLE, market);
        _grantRole(UPDATER_ROLE, enhance);
        _grantRole(MINTER_ROLE, enhance);
        _grantRole(MINTER_ROLE, giftV1Role);
        _grantRole(MINTER_ROLE, contiV1);
        erc20Contract = erc20;
    }

    modifier OwnThisItem(uint256 tokenId) {
        require(addressToUintSet[msg.sender].contains(tokenId), '1');
        _;
    }

    modifier OwnTheseItems(uint256[] memory tokenIds) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(addressToUintSet[msg.sender].contains(tokenIds[i]), '1');
        }
        _;
    }
    modifier Pay(uint256 fee) {
        require(msg.value >= fee, '18');
        _;
    }
    modifier OwnThatCharacter(uint256 _charId) {
        bool hasChar = ICharacter(charAddress).hasCharacter(msg.sender, _charId);
        require(hasChar, '2');
        _;
    }
    modifier InPackage(uint256 _itemId) {
        require(!idToEquipment[_itemId].isEquiped, '3');
        _;
    }

    function OwnItem(uint256 tokenId, address caller) external view returns (bool) {
        return addressToUintSet[caller].contains(tokenId);
    }

    function isArmed(uint256 _charId, uint8 required) external view returns (bool) {
        uint256[] memory equipIds = charIdToEquippedItems[_charId].values();
        for (uint256 i = 0; i < equipIds.length; i++) {
            IEquipment.EquipItem memory item = idToEquipment[equipIds[i]];
            if (item.bodyPart == required) {
                return true;
            }
        }
        return false;
    }

    function _random() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number + 1), msg.sender, seed)));
        seed = randomNumber;
        return randomNumber;
    }

    function getBaseValue(
        uint8 r,
        uint256 base,
        uint256 eqLv
    ) private returns (uint16) {
        uint16 baseValue = (uint16)((((baseRate(r) * base * eqLv) / 100) * ((_random() % 20) + 91)) / 100);
        return baseValue == 0 ? 1 : baseValue;
    }

    function baseRate(uint8 rarity) private pure returns (uint256 u) {
        if (rarity == 1) return 80;
        if (rarity == 2) return 100;
        if (rarity == 3) return 115;
        if (rarity == 4) return 120;
        if (rarity == 5) return 130;
        if (rarity == 6) return 125;
        if (rarity == 7) return 150;
    }

    function upgrade(uint256 tokenId) public onlyRole(UPDATER_ROLE) returns (bool) {
        idToEquipment[tokenId].enhanceLevel++;
        return true;
    }

    function getEquipment(uint256 tokenId) public view returns (IEquipment.EquipItem memory) {
        return idToEquipment[tokenId];
    }

    function getEquipmentByIds(uint256[] memory tokenIds) external view returns (IEquipment.EquipItem[] memory) {
        IEquipment.EquipItem[] memory _items = new IEquipment.EquipItem[](tokenIds.length);
        for (uint256 i = 0; i < _items.length; i++) {
            _items[i] = idToEquipment[tokenIds[i]];
        }
        return _items;
    }

    function getEquipmentList(address addr) external view returns (IEquipment.EquipItem[] memory) {
        uint256 length = addressToUintSet[addr].length();
        require(length > 0, '4');
        IEquipment.EquipItem[] memory _items = new IEquipment.EquipItem[](length);
        uint256[] memory _set = addressToUintSet[addr].values();
        for (uint256 i = 0; i < length; i++) {
            _items[i] = idToEquipment[_set[i]];
        }
        return _items;
    }

    function getEquipmentCount(address account) external view returns (uint256) {
        return addressToUintSet[account].length();
    }

    function getEquippedIdsByCharId(uint256 _charId) external view returns (uint256[] memory) {
        return charIdToEquippedItems[_charId].values();
    }

    function createItem(IEquipment.EquipItem memory item, address minter) external onlyRole(MINTER_ROLE) {
        uint256 token1155Id = IAOM(token1155Contract).mintNFT(minter);
        item.token1155Id = token1155Id;
        item.transferable = 3;
        idToEquipment[token1155Id] = item;
        addressToUintSet[minter].add(token1155Id);
        emit FindEquipment(minter, token1155Id, item);
    }

    modifier ableTransfer(uint256 _itemId) {
        require(idToEquipment[_itemId].transferable > 0, '31');
        _;
    }

    function TransferItemOwnership(uint256 _itemId, uint256 _toCharId)
        external
        payable
        OwnThisItem(_itemId)
        ableTransfer(_itemId)
        InPackage(_itemId)
        Pay(maintainFee)
    {
        idToEquipment[_itemId].belong = _toCharId;
        idToEquipment[_itemId].transferable -= 1;
        emit NewItemMaster(msg.sender, _toCharId, _itemId);
    }

    function equipItem(uint256 _charId, uint256 _itemId)
        external
        InPackage(_itemId)
        OwnThisItem(_itemId)
        OwnThatCharacter(_charId)
    {
        require(ICharacter(charAddress).getCharacter(_charId).level >= idToEquipment[_itemId].equipmentLv, '30');

        require(idToEquipment[_itemId].belong == _charId, '32');

        uint256 equipedItemCount = charIdToEquippedItems[_charId].length(); // get equipped item count of char from Array.
        if (equipedItemCount == 0) {
            if (idToEquipment[_itemId].isEquiped == false) {
                charIdToEquippedItems[_charId].add(_itemId);
                idToEquipment[_itemId].isEquiped = true;
            }
        } else {
            bool allowEquipItem = true;

            for (uint256 i = 0; i < equipedItemCount; i++) {
                if (idToEquipment[_itemId].bodyPart == idToEquipment[charIdToEquippedItems[_charId].at(i)].bodyPart) {
                    allowEquipItem = false;
                    break;
                }
            }
            require(allowEquipItem, '6');
            charIdToEquippedItems[_charId].add(_itemId);
            idToEquipment[_itemId].isEquiped = true;
        }
    }

    function DangerUpdate(uint256 tokenId1155, IEquipment.EquipItem memory equipitem) external onlyRole(UPDATER_ROLE) {
        idToEquipment[tokenId1155] = equipitem;
    }

    function updateSkin(uint256 tokenId1155, uint8 skin) external onlyRole(UPDATER_ROLE) {
        idToEquipment[tokenId1155].skin = skin;
    }

    function updateSet(uint256 tokenId1155, uint8 set) external onlyRole(UPDATER_ROLE) {
        idToEquipment[tokenId1155].set = set;
    }

    function updateGems(uint256 tokenId1155, uint8 gem) external onlyRole(UPDATER_ROLE) {
        idToEquipment[tokenId1155].gem = gem;
    }

    function unequipItem(uint256 _charId, uint256[] memory tokenIds)
        external
        OwnThatCharacter(_charId)
        OwnTheseItems(tokenIds)
    {
        require(tokenIds.length > 0, '7');
        require(tokenIds.length <= charIdToEquippedItems[_charId].length(), '8');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(idToEquipment[tokenIds[i]].isEquiped, '9');
            require(charIdToEquippedItems[_charId].contains(tokenIds[i]), '8');

            idToEquipment[tokenIds[i]].isEquiped = false;
            charIdToEquippedItems[_charId].remove(tokenIds[i]);
        }
    }

    function melt(uint256 tokenId, address addr) public InPackage(tokenId) onlyRole(MINTER_ROLE) {
        IAOM(token1155Contract).burn(addr, tokenId, 1);
        bool isTrue = addressToUintSet[addr].remove(tokenId);
        require(isTrue, '10');
        delete idToEquipment[tokenId];
    }

    function meltBatch(uint256[] memory ids, address addr) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            melt(ids[i], addr);
        }
    }

    function identify(uint256 tokenId) external payable OwnThisItem(tokenId) Pay(maintainFee) {
        require(idToEquipment[tokenId].isUndefined == true, '11');
        receiveOre(identifyFee);
        uint8 rarity = idToEquipment[tokenId].rarity;
        if (rarity >= 2) {
            idToEquipment[tokenId].t2 = (uint8)(_random() % 6) + 6 + 1;
            idToEquipment[tokenId].v2 = getBaseValue(rarity, 1, idToEquipment[tokenId].equipmentLv);
        }
        if (rarity >= 3) {
            idToEquipment[tokenId].t3 = (uint8)(_random() % 7) + 12 + 1;
            idToEquipment[tokenId].v3 = (uint8)(_random() % 10) + 1;
        }
        if (rarity >= 4) {
            idToEquipment[tokenId].t4 = (uint8)(_random() % 7) + 19 + 1;
            idToEquipment[tokenId].v4 = (uint8)(_random() % 10) + 1;
        }
        if (rarity >= 5) {
            idToEquipment[tokenId].t5 = (uint8)(_random() % 7) + 26 + 1;
            idToEquipment[tokenId].v5 = (uint8)(_random() % 10) + 1;
        }

        idToEquipment[tokenId].isUndefined = false;
    }

    function onMarketTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external onlyRole(MARKET_ROLE) {
        require(addressToUintSet[from].contains(tokenId), '1');
        addressToUintSet[from].remove(tokenId);
        addressToUintSet[to].add(tokenId);
    }

    // ---------------------------------------------start----❤️❤️❤️❤️❤️❤️❤️❤️------------------------------------
    function withdraw(address _to, uint256 amount) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent, ) = _to.call{value: amount}('');
        require(sent, '16');
    }

    function receiveOre(uint256 amount) internal {
        require(IERC20(erc20Contract).transferFrom(msg.sender, address(this), amount), 'T');
    }

    function withdrawOre(address _to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(erc20Contract).transfer(_to, amount);
    }
}