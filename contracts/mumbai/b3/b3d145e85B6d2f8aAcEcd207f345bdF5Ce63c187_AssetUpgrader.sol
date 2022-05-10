// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";
import "../common/interfaces/IAssetAttributesRegistry.sol";
import "../common/interfaces/IAssetUpgrader.sol";
import "../catalyst/GemsCatalystsRegistry.sol";
import "../common/interfaces/IERC20Extended.sol";
import "../common/interfaces/IPolygonAssetERC721.sol";
import "../common/interfaces/IPolygonAssetERC1155.sol";

/// @notice Allow to upgrade Asset with Catalyst, Gems and Sand, giving the assets attributes through AssetAttributeRegistry
contract AssetUpgrader is Ownable, ERC2771Handler, IAssetUpgrader {
    using SafeMath for uint256;

    address public immutable feeRecipient;
    uint256 public immutable upgradeFee;
    uint256 public immutable gemAdditionFee;
    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    address private constant BURN_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    IERC20Extended internal immutable _sand;
    IAssetAttributesRegistry internal immutable _registry;
    IPolygonAssetERC721 internal immutable _assetERC721;
    IPolygonAssetERC1155 internal immutable _assetERC1155;
    GemsCatalystsRegistry internal immutable _gemsCatalystsRegistry;

    event TrustedForwarderChanged(address indexed newTrustedForwarderAddress);

    /// @notice AssetUpgrader depends on
    /// @param registry: AssetAttributesRegistry for recording catalyst and gems used
    /// @param sand: ERC20 for fee payment
    /// @param assetERC1155: ERC1155 Asset Token Contract
    /// @param gemsCatalystsRegistry: that track the canonical catalyst and gems and provide batch burning facility
    /// @param _upgradeFee: the fee in Sand paid for an upgrade (setting or replacing a catalyst)
    /// @param _gemAdditionFee: the fee in Sand paid for adding gems
    /// @param _feeRecipient: address receiving the Sand fee
    /// @param trustedForwarder: address of the trusted forwarder (used for metaTX)
    constructor(
        IAssetAttributesRegistry registry,
        IERC20Extended sand,
        IPolygonAssetERC721 assetERC721,
        IPolygonAssetERC1155 assetERC1155,
        GemsCatalystsRegistry gemsCatalystsRegistry,
        uint256 _upgradeFee,
        uint256 _gemAdditionFee,
        address _feeRecipient,
        address trustedForwarder
    ) {
        _registry = registry;
        _sand = sand;
        _assetERC721 = assetERC721;
        _assetERC1155 = assetERC1155;
        _gemsCatalystsRegistry = gemsCatalystsRegistry;
        upgradeFee = _upgradeFee;
        gemAdditionFee = _gemAdditionFee;
        feeRecipient = _feeRecipient;
        __ERC2771Handler_initialize(trustedForwarder);
    }

    /// @notice associate a catalyst to a fungible Asset token by extracting it as ERC721 first.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being extracted.
    /// @param catalystId address of the catalyst token to use and burn.
    /// @param gemIds list of gems to socket into the catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    /// @return tokenId The Id of the extracted token.
    function extractAndSetCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external override returns (uint256 tokenId) {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        tokenId = _assetERC1155.extractERC721From(from, assetId, from);
        _changeCatalyst(from, tokenId, catalystId, gemIds, to);
    }

    // TODO tests
    // function extractAndAddGems(
    //     address from,
    //     uint256 assetId,
    //     uint16[] calldata gemIds,
    //     address to
    // ) external override returns (uint256 tokenId) {
    //     require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
    //     require(_msgSender() == from, "AUTH_ACCESS_DENIED");
    //     tokenId = _asset.extractERC721From(from, assetId, from);
    //     _addGems(from, assetId, gemIds, to);
    // }

    /// @notice associate a new catalyst to a non-fungible Asset token.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being updated.
    /// @param catalystId address of the catalyst token to use and burn.
    /// @param gemIds list of gems to socket into the catalyst (burned).
    /// @param to destination address receiving the Asset token.
    /// @return tokenId The id of the asset.
    function changeCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external override returns (uint256 tokenId) {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        _changeCatalyst(from, assetId, catalystId, gemIds, to);
        return assetId;
    }

    /// @notice add gems to a non-fungible Asset token.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset to which the gems will be added to.
    /// @param gemIds list of gems to socket into the existing catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    function addGems(
        address from,
        uint256 assetId,
        uint16[] calldata gemIds,
        address to
    ) external override {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        _addGems(from, assetId, gemIds, to);
    }

    /// @dev Collect a fee in SAND tokens
    /// @param from The address paying the fee.
    /// @param sandFee The fee amount.
    function _chargeSand(address from, uint256 sandFee) internal {
        if (feeRecipient != address(0) && sandFee != 0) {
            if (feeRecipient == address(BURN_ADDRESS)) {
                // special address for burn
                _sand.burnFor(from, sandFee);
            } else {
                require(
                    _sand.transferFrom(from, feeRecipient, sandFee),
                    "AssetUpgrader: ERC20 operation did not succeed"
                );
            }
        }
    }

    /// @dev Change the catalyst for an asset.
    /// @param from The current owner of the asset.
    /// @param assetId The id of the asset to change.
    /// @param catalystId The id of the new catalyst to set.
    /// @param gemIds An array of gemIds to embed.
    /// @param to The address to transfer the asset to after the catalyst is changed.
    function _changeCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] memory gemIds,
        address to
    ) internal {
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT"); // Asset (ERC1155ERC721.sol) ensure NFT will return true here and non-NFT will return false
        _burnCatalyst(from, catalystId);
        _burnGems(from, gemIds);
        _chargeSand(from, upgradeFee);
        _registry.setCatalyst(assetId, catalystId, gemIds);
        _transfer(from, to, assetId);
    }

    /// @dev Add gems to an existing asset.
    /// @param from The current owner of the asset.
    /// @param assetId The asset to add gems to.
    /// @param gemIds An array of gemIds to add to the asset.
    /// @param to The address to transfer the asset to after adding gems.
    function _addGems(
        address from,
        uint256 assetId,
        uint16[] memory gemIds,
        address to
    ) internal {
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT"); // Asset (ERC1155ERC721.sol) ensure NFT will return true here and non-NFT will return false
        _burnGems(from, gemIds);
        _chargeSand(from, gemAdditionFee);
        _registry.addGems(assetId, gemIds);
        _transfer(from, to, assetId);
    }

    /// @dev transfer an asset if from != to.
    /// @param from The address to transfer the asset from.
    /// @param to The address to transfer the asset to.
    /// @param assetId The asset to transfer.
    function _transfer(
        address from,
        address to,
        uint256 assetId
    ) internal {
        // TODO: ensure always assetERC1155?
        if (from != to) {
            _assetERC1155.safeTransferFrom(from, to, assetId, 1, "");
        } else {
            require(_assetERC1155.balanceOf(from, assetId) > 0, "NOT_AUTHORIZED_ASSET_OWNER");
        }
    }

    /// @dev Burn gems.
    /// @param from The owner of the gems.
    /// @param gemIds The gem types to burn.
    function _burnGems(address from, uint16[] memory gemIds) internal {
        uint256[] memory gemFactors;
        for (uint256 i = 0; i < gemIds.length; i++) {
            gemFactors[i] = _gemsCatalystsRegistry.getGemDecimals(gemIds[i]);
        }
        _gemsCatalystsRegistry.burnDifferentGems(from, gemIds, gemFactors);
    }

    /// @dev Burn a catalyst.
    /// @param from The owner of the catalyst.
    /// @param catalystId The catalyst type to burn.
    function _burnCatalyst(address from, uint16 catalystId) internal {
        uint256 catalystFactor = _gemsCatalystsRegistry.getCatalystDecimals(catalystId);
        _gemsCatalystsRegistry.burnCatalyst(from, catalystId, catalystFactor);
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;

        emit TrustedForwarderChanged(trustedForwarder);
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IGem.sol";
import "./interfaces/ICatalyst.sol";
import "../common/interfaces/IERC20Extended.sol";
import "./interfaces/IGemsCatalystsRegistry.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @notice Contract managing the Gems and Catalysts
/// Each Gems and Catalyst must be registered here.
/// Each new Gem get assigned a new id (starting at 1)
/// Each new Catalyst get assigned a new id (starting at 1)
contract GemsCatalystsRegistry is ERC2771Handler, IGemsCatalystsRegistry, OwnableUpgradeable, AccessControlUpgradeable {
    uint256 private constant MAX_GEMS_AND_CATALYSTS = 256;
    uint256 internal constant MAX_UINT256 = ~uint256(0);
    bytes32 public constant SUPER_OPERATOR_ROLE = keccak256("SUPER_OPERATOR_ROLE");

    IGem[] internal _gems;
    ICatalyst[] internal _catalysts;

    event TrustedForwarderChanged(address indexed newTrustedForwarderAddress);

    function initV1(address trustedForwarder, address admin) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        __ERC2771Handler_initialize(trustedForwarder);
        __Ownable_init();
    }

    /// @notice Returns the values for each gem included in a given asset.
    /// @param catalystId The catalyst identifier.
    /// @param assetId The asset tokenId.
    /// @param events An array of GemEvents. Be aware that only gemEvents from the last CatalystApplied event onwards should be used to populate a query. If gemEvents from multiple CatalystApplied events are included the output values will be incorrect.
    /// @return values An array of values for each gem present in the asset.
    function getAttributes(
        uint16 catalystId,
        uint256 assetId,
        IAssetAttributesRegistry.GemEvent[] calldata events
    ) external view override returns (uint32[] memory values) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getAttributes(assetId, events);
    }

    /// @notice Returns the maximum number of gems for a given catalyst
    /// @param catalystId catalyst identifier
    function getMaxGems(uint16 catalystId) external view override returns (uint8) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getMaxGems();
    }

    /// @notice Returns the decimals for a given catalyst
    /// @param catalystId catalyst identifier
    function getCatalystDecimals(uint16 catalystId) external view override returns (uint8) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getDecimals();
    }

    /// @notice Returns the decimals for a given gem
    /// @param gemId gem identifier
    function getGemDecimals(uint16 gemId) external view override returns (uint8) {
        IGem gem = getGem(gemId);
        require(gem != IGem(address(0)), "GEM_DOES_NOT_EXIST");
        return gem.getDecimals();
    }

    /// @notice Burns one gem unit from each gem id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param gemIds list of gems to burn one gem from each
    /// @param amounts amount units to burn
    function burnDifferentGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) external override {
        for (uint256 i = 0; i < gemIds.length; i++) {
            burnGem(from, gemIds[i], amounts[i]);
        }
    }

    /// @notice Burns one catalyst unit from each catalyst id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param catalystIds list of catalysts to burn
    /// @param amounts amount to burn
    function burnDifferentCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) external override {
        for (uint256 i = 0; i < catalystIds.length; i++) {
            burnCatalyst(from, catalystIds[i], amounts[i]);
        }
    }

    /// @notice Burns few gem units from each gem id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param gemIds list of gems to burn gem units from each
    /// @param amounts list of amounts of units to burn
    function batchBurnGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) public override {
        for (uint256 i = 0; i < gemIds.length; i++) {
            if (gemIds[i] != 0 && amounts[i] != 0) {
                burnGem(from, gemIds[i], amounts[i]);
            }
        }
    }

    /// @notice Burns few catalyst units from each catalyst id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param catalystIds list of catalysts to burn catalyst units from each
    /// @param amounts list of amounts of units to burn
    function batchBurnCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) public override {
        for (uint256 i = 0; i < catalystIds.length; i++) {
            if (catalystIds[i] != 0 && amounts[i] != 0) {
                burnCatalyst(from, catalystIds[i], amounts[i]);
            }
        }
    }

    /// @notice Adds both arrays of gems and catalysts to registry
    /// @param gems array of gems to be added
    /// @param catalysts array of catalysts to be added
    function addGemsAndCatalysts(IGem[] calldata gems, ICatalyst[] calldata catalysts)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            uint256(_gems.length + _catalysts.length + gems.length + catalysts.length) < MAX_GEMS_AND_CATALYSTS,
            "GemsCatalystsRegistry: Too many gem and catalyst contracts"
        );

        for (uint256 i = 0; i < gems.length; i++) {
            IGem gem = gems[i];
            uint16 gemId = gem.gemId();
            require(gemId == _gems.length + 1, "GEM_ID_NOT_IN_ORDER");
            _gems.push(gem);
        }

        for (uint256 i = 0; i < catalysts.length; i++) {
            ICatalyst catalyst = catalysts[i];
            uint16 catalystId = catalyst.catalystId();
            require(catalystId == _catalysts.length + 1, "CATALYST_ID_NOT_IN_ORDER");
            _catalysts.push(catalyst);
        }
    }

    /// @notice Query whether a given gem exists.
    /// @param gemId The gem being queried.
    /// @return Whether the gem exists.
    function doesGemExist(uint16 gemId) external view override returns (bool) {
        return getGem(gemId) != IGem(address(0));
    }

    /// @notice Query whether a giving catalyst exists.
    /// @param catalystId The catalyst being queried.
    /// @return Whether the catalyst exists.
    function doesCatalystExist(uint16 catalystId) external view returns (bool) {
        return getCatalyst(catalystId) != ICatalyst(address(0));
    }

    /// @notice Burn a catalyst.
    /// @param from The signing address for the tx.
    /// @param catalystId The id of the catalyst to burn.
    /// @param amount The number of catalyst tokens to burn.
    function burnCatalyst(
        address from,
        uint16 catalystId,
        uint256 amount
    ) public override checkAuthorization(from) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        catalyst.burnFor(from, amount);
    }

    /// @notice Burn a gem.
    /// @param from The signing address for the tx.
    /// @param gemId The id of the gem to burn.
    /// @param amount The number of gem tokens to burn.
    function burnGem(
        address from,
        uint16 gemId,
        uint256 amount
    ) public override checkAuthorization(from) {
        IGem gem = getGem(gemId);
        require(gem != IGem(address(0)), "GEM_DOES_NOT_EXIST");
        gem.burnFor(from, amount);
    }

    function getNumberOfCatalystContracts() external view returns (uint256 number) {
        number = _catalysts.length;
    }

    function getNumberOfGemContracts() external view returns (uint256 number) {
        number = _gems.length;
    }

    function revokeGemsandCatalystsMaxAllowance() external {
        _setGemsAndCatalystsAllowance(0);
    }

    function setGemsAndCatalystsMaxAllowance() external {
        _setGemsAndCatalystsAllowance(MAX_UINT256);
    }

    // //////////////////// INTERNALS ////////////////////

    function _setGemsAndCatalystsAllowance(uint256 allowanceValue) internal {
        for (uint256 i = 0; i < _gems.length; i++) {
            _gems[i].approveFor(_msgSender(), address(this), allowanceValue);
        }

        for (uint256 i = 0; i < _catalysts.length; i++) {
            _catalysts[i].approveFor(_msgSender(), address(this), allowanceValue);
        }
    }

    /// @dev Get the catalyst contract corresponding to the id.
    /// @param catalystId The catalyst id to use to retrieve the contract.
    /// @return The requested Catalyst contract.
    function getCatalyst(uint16 catalystId) public view returns (ICatalyst) {
        if (catalystId > 0 && catalystId <= _catalysts.length) {
            return _catalysts[catalystId - 1];
        } else {
            return ICatalyst(address(0));
        }
    }

    /// @dev Get the gem contract corresponding to the id.
    /// @param gemId The gem id to use to retrieve the contract.
    /// @return The requested Gem contract.
    function getGem(uint16 gemId) public view returns (IGem) {
        if (gemId > 0 && gemId <= _gems.length) {
            return _gems[gemId - 1];
        } else {
            return IGem(address(0));
        }
    }

    /// @dev verify that the caller is authorized for this function call.
    /// @param from The original signer of the transaction.
    modifier checkAuthorization(address from) {
        require(_msgSender() == from || hasRole(SUPER_OPERATOR_ROLE, _msgSender()), "AUTH_ACCESS_DENIED");
        _;
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;

        emit TrustedForwarderChanged(trustedForwarder);
    }

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";
import "../../common/interfaces/IAttributes.sol";
import "../../common/interfaces/IERC20Extended.sol";

interface ICatalyst is IERC20Extended, IAttributes {
    function catalystId() external returns (uint16);

    function changeAttributes(IAttributes attributes) external;

    function getMaxGems() external view returns (uint8);

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external override returns (bool success);

    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        view
        override
        returns (uint32[] memory values);

    function getDecimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IERC20Extended.sol";

interface IGem is IERC20Extended {
    function gemId() external returns (uint16);

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external override returns (bool success);

    function getDecimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";
import "./IGem.sol";
import "./ICatalyst.sol";

interface IGemsCatalystsRegistry {
    function getAttributes(
        uint16 catalystId,
        uint256 assetId,
        IAssetAttributesRegistry.GemEvent[] calldata events
    ) external view returns (uint32[] memory values);

    function getMaxGems(uint16 catalystId) external view returns (uint8);

    function burnDifferentGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) external;

    function burnDifferentCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) external;

    function batchBurnGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) external;

    function batchBurnCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) external;

    function addGemsAndCatalysts(IGem[] calldata gems, ICatalyst[] calldata catalysts) external;

    function doesGemExist(uint16 gemId) external view returns (bool);

    function burnCatalyst(
        address from,
        uint16 catalystId,
        uint256 amount
    ) external;

    function burnGem(
        address from,
        uint16 gemId,
        uint256 amount
    ) external;

    function getCatalystDecimals(uint16 catalystId) external view returns (uint8);

    function getGemDecimals(uint16 gemId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/// @dev minimal ERC2771 handler to keep bytecode-size down.
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol

contract ERC2771Handler {
    address internal _trustedForwarder;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetAttributesRegistry {
    struct GemEvent {
        uint16[] gemIds;
        bytes32 blockHash;
    }

    struct AssetGemsCatalystData {
        uint256 assetId;
        uint16 catalystContractId;
        uint16[] gemContractIds;
    }

    function getRecord(uint256 assetId)
        external
        view
        returns (
            bool exists,
            uint16 catalystId,
            uint16[] memory gemIds
        );

    function getAttributes(uint256 assetId, GemEvent[] calldata events) external view returns (uint32[] memory values);

    function setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWhenDepositOnOtherLayer(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWithBlockNumber(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external;

    function addGems(uint256 assetId, uint16[] calldata gemIds) external;

    function setMigrationContract(address _migrationContract) external;

    function getCatalystRegistry() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Base} from "./IERC721Base.sol";

interface IAssetERC721 is IERC721Base {
    function mint(address to, uint256 id) external override;

    function mint(
        address to,
        uint256 id,
        bytes calldata data
    ) external override;

    function setTokenURI(uint256 id, string memory uri) external;

    function tokenURI(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetUpgrader {
    function extractAndSetCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId);

    function changeCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId);

    function addGems(
        address from,
        uint256 assetId,
        uint16[] calldata gemIds,
        address to
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../interfaces/IAssetAttributesRegistry.sol";

interface IAttributes {
    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        view
        returns (uint32[] memory values);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC20.sol";

interface IERC20Extended is IERC20 {
    function burnFor(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool success);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ExtendedToken} from "./IERC721ExtendedToken.sol";

interface IERC721Base is IERC721Upgradeable {
    function mint(address to, uint256 id) external;

    function mint(
        address to,
        uint256 id,
        bytes calldata metaData
    ) external;

    function approveFor(
        address from,
        address operator,
        uint256 id
    ) external;

    function setApprovalForAllFor(
        address from,
        address operator,
        bool approved
    ) external;

    function burnFrom(address from, uint256 id) external;

    function burn(uint256 id) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function exists(uint256 tokenId) external view returns (bool);

    function supportsInterface(bytes4 id) external view override returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address trustedForwarder);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC721ExtendedToken {
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function burn(uint256 id) external;

    function burnFrom(address from, uint256 id) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IAssetERC721} from "./IAssetERC721.sol";

interface IPolygonAssetERC1155 {
    function changeBouncerAdmin(address newBouncerAdmin) external;

    function setBouncer(address bouncer, bool enabled) external;

    function setPredicate(address predicate) external;

    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        address owner,
        bytes calldata data
    ) external returns (uint256 id);

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids);

    // fails on non-NFT or nft who do not have collection (was a mistake)
    function collectionOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    // return true for Non-NFT ERC1155 tokens which exists
    function isCollection(uint256 id) external view returns (bool);

    function collectionIndexOf(uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function getBouncerAdmin() external view returns (address);

    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId);

    function isBouncer(address who) external view returns (bool);

    function creatorOf(uint256 id) external view returns (address);

    function wasEverMinted(uint256 id) external view returns (bool);

    function isSuperOperator(address who) external view returns (bool);

    function isApprovedForAll(address owner, address operator) external view returns (bool isOperator);

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external returns (uint256[] memory);

    function name() external returns (string memory _name);

    function symbol() external returns (string memory _symbol);

    function supportsInterface(bytes4 id) external returns (bool);

    function tokenURI(uint256 id) external returns (string memory);

    function setAssetERC721(IAssetERC721 assetERC721) external;

    function exists(uint256 tokenId) external view returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Base} from "./IERC721Base.sol";

interface IPolygonAssetERC721 is IERC721Base {
    function mint(address to, uint256 id) external override;

    function mint(
        address to,
        uint256 id,
        bytes calldata data
    ) external override;

    function setTokenURI(uint256 id, string memory uri) external;

    function tokenURI(uint256 id) external view returns (string memory);
}