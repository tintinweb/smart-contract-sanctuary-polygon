// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
                        StringsUpgradeable.toHexString(account),
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

library AppConsts {
    string public constant PROXYWALLETFACTORY_MODULE_NAME =
        "PROXYWALLETFACTORY_MODULE";
    bytes32 public constant PROXYWALLETFACTORY_MODULE_ID =
        keccak256(abi.encodePacked(PROXYWALLETFACTORY_MODULE_NAME));

    string public constant TREASURY_MODULE_NAME = "TREASURY_MODULE";
    bytes32 public constant TREASURY_MODULE_ID =
        keccak256(abi.encodePacked(TREASURY_MODULE_NAME));

    string public constant ZAP_MODULE_NAME = "ZAP_MODULE";
    bytes32 public constant ZAP_MODULE_ID =
        keccak256(abi.encodePacked(ZAP_MODULE_NAME));

    string public constant SHAPESHIFTER_MODULE_NAME = "SHAPESHIFTER_MODULE";
    bytes32 public constant SHAPESHIFTER_MODULE_ID =
        keccak256(abi.encodePacked(SHAPESHIFTER_MODULE_NAME));

    string public constant SHAPESHIFTER_META_MODULE_NAME =
        "SHAPESHIFTER_META_MODULE";
    bytes32 public constant SHAPESHIFTER_META_MODULE_ID =
        keccak256(abi.encodePacked(SHAPESHIFTER_META_MODULE_NAME));

    string public constant SHAPESHIFTER_MINTER_MODULE_NAME =
        "SHAPESHIFTER_MINTER_MODULE";
    bytes32 public constant SHAPESHIFTER_MINTER_MODULE_ID =
        keccak256(abi.encodePacked(SHAPESHIFTER_MINTER_MODULE_NAME));

    string public constant SHAPESHIFTER_RENTING_MODULE_NAME =
        "SHAPESHIFTER_RENTING_MODULE";
    bytes32 public constant SHAPESHIFTER_RENTING_MODULE_ID =
        keccak256(abi.encodePacked(SHAPESHIFTER_RENTING_MODULE_NAME));

    string public constant TEAMTOKENMANAGER_MODULE_NAME =
        "TEAMTOKENMANAGER_MODULE";
    bytes32 public constant TEAMTOKENMANAGER_MODULE_ID =
        keccak256(abi.encodePacked(TEAMTOKENMANAGER_MODULE_NAME));

    string public constant VAULT_MODULE_NAME = "VAULT_MODULE";
    bytes32 public constant VAULT_MODULE_ID =
        keccak256(abi.encodePacked(VAULT_MODULE_NAME));

    string public constant VRFCOORD_MODULE_NAME = "VRFCOORDINATOR_ADDRESS";
    bytes32 public constant VRFCOORD_MODULE_ID =
        keccak256(abi.encodePacked(VRFCOORD_MODULE_NAME));

    string public constant BEACON_MODULE_NAME = "BEACON_MODULE";
    bytes32 public constant BEACON_MODULE_ID =
        keccak256(abi.encodePacked(BEACON_MODULE_NAME));

    string public constant BENEFICIARY_NAME = "BENEFICIARY_ADDRESS";
    bytes32 public constant BENEFICIARY_ID =
        keccak256(abi.encodePacked(BENEFICIARY_NAME));

    string public constant LIQUID_POOL_NAME = "LIQUID_POOL_ADDRESS";
    bytes32 public constant LIQUID_POOL_ID =
        keccak256(abi.encodePacked(LIQUID_POOL_NAME));

    string public constant STAKING_NAME = "STAKING_ADDRESS";
    bytes32 public constant STAKING_ID =
        keccak256(abi.encodePacked(STAKING_NAME));

    string public constant TX_AUTHORIZER_NAME = "TX_AUTHORIZER_MODULE";
    bytes32 public constant TX_AUTHORIZER_ID =
        keccak256(abi.encodePacked(TX_AUTHORIZER_NAME));

    string public constant TEAM_NAME = "TEAM_ADDRESS";
    bytes32 public constant TEAM_ID = keccak256(abi.encodePacked(TEAM_NAME));

    bytes32 public constant MINTER_ROLE =
        keccak256(abi.encodePacked("MINTER_ROLE"));
    bytes32 public constant UPGRADER_ROLE =
        keccak256(abi.encodePacked("UPGRADER_ROLE"));
    bytes32 public constant BEACON_ROLE =
        keccak256(abi.encodePacked("BEACON_ROLE"));
    bytes32 public constant RENTING_ROLE =
        keccak256(abi.encodePacked("RENTING_ROLE"));
    bytes32 public constant PROXY_WALLET_ROLE =
        keccak256(abi.encodePacked("PROXY_WALLET_ROLE"));
    bytes32 public constant PROXY_WALLET_ADMIN_ROLE =
        keccak256(abi.encodePacked("PROXY_WALLET_ADMIN_ROLE"));
    bytes32 public constant RENT_MANAGER_ROLE =
        keccak256(abi.encodePacked("RENT_MANAGER_ROLE"));
    bytes32 public constant RENT_VAULT_ROLE =
        keccak256(abi.encodePacked("RENT_VAULT_ROLE"));
    bytes32 public constant VAULT_ADMIN_ROLE =
        keccak256(abi.encodePacked("VAULT_ADMIN_ROLE"));
    bytes32 public constant TX_DECODER_ROLE =
        keccak256(abi.encodePacked("TX_DECODER_ROLE"));

    uint32 public constant MAX_SHS = 10;
    //    uint32[] public constant MAX_SHS_LEVEL = [11, 16, 26];
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS_MINT = 4;
    uint32 public constant NUM_WORDS_UPGRADE = 3;

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct Token {
        TokenType tokenType;
        address tokenAddr;
        uint256 tokenId;
        uint256 tokenValue;
    }

    function getTokenStruct(
        address _tokenAddr,
        uint256 _tokenId
    ) internal pure returns (Token memory) {
        return Token(TokenType.ERC721, _tokenAddr, _tokenId, 1);
    }

    function getTokenStruct(
        address _tokenAddr,
        uint256 _tokenId,
        uint256 _tokenValue
    ) internal pure returns (Token memory) {
        return Token(TokenType.ERC1155, _tokenAddr, _tokenId, _tokenValue);
    }

    function token2Id(Token memory _token) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "TOKEN_",
                    _token.tokenType,
                    _token.tokenAddr,
                    _token.tokenId,
                    _token.tokenValue
                )
            );
    }

    struct RentTransaction {
        address proxyWallet;
        address tokenAddr;
        uint256 tokenId;
        uint256 expiryTime;
    }

    function getRentTransactionStruct(
        address _proxyWallet,
        address _tokenAddr,
        uint256 _tokenId,
        uint256 _expiryTime
    ) internal pure returns (RentTransaction memory) {
        return RentTransaction(_proxyWallet, _tokenAddr, _tokenId, _expiryTime);
    }

    function rentTransaction2Id(
        RentTransaction memory _rentTransaction
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "RENTTRANSACTION_",
                    _rentTransaction.proxyWallet,
                    _rentTransaction.tokenAddr,
                    _rentTransaction.tokenId,
                    _rentTransaction.expiryTime
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "./base/ModuleUpgradeable.sol";

import {AppConsts} from "./AppConsts.sol";

import "./IApp.sol";

error AppModuleUpgradeable_SenderHasNoRole(bytes32 _role, address _sender);
error Shapeshifter__InvalidRentalRequestOrigin();
error Shapeshifter__NotRenter();
error Vault__IllegalAction();
error AppModuleUpgradeable__NotProxyWallet(address);

abstract contract AppModuleUpgradeable is ModuleUpgradeable, IApp {
    uint32[] public MAX_SHS_LEVEL;

    uint256[256] private __gap;

    modifier minterOnly() {
        if (!hasRole(AppConsts.MINTER_ROLE, msg.sender))
            revert AppModuleUpgradeable_SenderHasNoRole(
                AppConsts.MINTER_ROLE,
                msg.sender
            );
        _;
    }

    function getMinterRole() public pure returns (bytes32) {
        return AppConsts.MINTER_ROLE;
    }

    modifier upgraderOnly() {
        if (!hasRole(AppConsts.UPGRADER_ROLE, msg.sender))
            revert AppModuleUpgradeable_SenderHasNoRole(
                AppConsts.UPGRADER_ROLE,
                msg.sender
            );
        _;
    }

    function getUpgraderRole() public pure returns (bytes32) {
        return AppConsts.UPGRADER_ROLE;
    }

    modifier beaconOnly() {
        if (!hasRole(AppConsts.BEACON_ROLE, msg.sender))
            revert Vault__IllegalAction();
        _;
    }

    modifier beaconOnlyFrom(address from) {
        if (!hasRole(AppConsts.BEACON_ROLE, from))
            revert Vault__IllegalAction();

        _;
    }

    function getBeaconRole() public pure returns (bytes32) {
        return AppConsts.BEACON_ROLE;
    }

    modifier onlyRenting() {
        if (!hasRole(AppConsts.RENTING_ROLE, msg.sender))
            revert Shapeshifter__NotRenter();
        _;
    }

    function getRentingRole() public pure returns (bytes32) {
        return AppConsts.RENTING_ROLE;
    }

    function getProxyWalletRole() public pure returns (bytes32) {
        return AppConsts.PROXY_WALLET_ROLE;
    }

    modifier onlyProxyWallet() {
        if (!hasRole(AppConsts.PROXY_WALLET_ROLE, msg.sender)) {
            revert AppModuleUpgradeable__NotProxyWallet(
                msg.sender
            );
        }
        _;
    }

    modifier onlyToProxyWallet(address to) {
        if (!hasRole(AppConsts.PROXY_WALLET_ROLE, to)) {
            revert AppModuleUpgradeable__NotProxyWallet(
                to
            );
        }
        _;
    }

    function __AppModule_init() internal onlyInitializing {
        ModuleUpgradeable.__Module_init();

        MAX_SHS_LEVEL = [11, 16, 26];
    }

    function getMaxSHS() public pure returns (uint256) {
        return AppConsts.MAX_SHS;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

library CoreConsts {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string public constant ROLE_MANAGER_MODULE_NAME = "ROLE_MANAGER";
    bytes32 public constant ROLE_MANAGER_MODULE_ID =
        keccak256(abi.encodePacked(ROLE_MANAGER_MODULE_NAME));

    string public constant MANAGER_MODULE_NAME = "MODULE_MANAGER";
    bytes32 public constant MANAGER_MODULE_ID =
        keccak256(abi.encodePacked(MANAGER_MODULE_NAME));

    string public constant TAG_STORAGE_MODULE_NAME = "TAG_STORAGE";
    bytes32 public constant TAG_STORAGE_MODULE_ID =
        keccak256(abi.encodePacked(TAG_STORAGE_MODULE_NAME));
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IModuleListener {
    event ModuleUpdated(address oldInstance, address _manager);

    event ModuleAdded(address _manager);

    event ModuleReplaced(address contractInstance);

    event ModuleRemoved();

    event ModuleOwnershipUpdate(address newOwner);

    event ModuleManagerSwitch(address newManager);

    function getName() external view returns (string memory);

    function getId() external view returns (bytes32);

    function getVersion() external view returns (bytes32);

    function onUpdate(address oldInstance, address _manager) external;

    function onAdd(address _manager) external;

    function onReplaced(address newInstance) external;

    function onRemoved() external;

    function updateOwnership(address newOwner) external;

    function switchManager(address newManager) external;

    function onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) external;

    function onListenRemoved(bytes32 hname) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../common/IModuleManager.sol";

import "./IModuleListener.sol";
import {CoreConsts} from "./CoreConsts.sol";

abstract contract ModuleUpgradeable is
    AccessControlUpgradeable,
    OwnableUpgradeable,
    IModuleListener
{
    IModuleManager public manager;
    IAccessControl public authManager;

    uint256[256] private __gap;

    event LinkRoleManager(address addr);

    modifier onlyManager() {
        require(
            hasRole(CoreConsts.MANAGER_ROLE, msg.sender),
            "CrossContractManListener: the caller must have MANAGER_ROLE"
        );
        _;
    }

    function getManagerRole() public pure returns (bytes32) {
        return CoreConsts.MANAGER_ROLE;
    }

    function __Module_init() internal onlyInitializing {
        AccessControlUpgradeable.__AccessControl_init();
        OwnableUpgradeable.__Ownable_init();

        __Module_init_unchained();
    }

    function __Module_init_unchained() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) public virtual override onlyManager {
        _onListenAdded(hname, contractInstance, isNew);
    }

    function _onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) internal virtual {
        if (address(this) == contractInstance) return;
        if (hname == CoreConsts.ROLE_MANAGER_MODULE_ID) {
            _linkRoleManager(contractInstance);
        }
    }

    function onListenRemoved(
        bytes32 hname
    ) public virtual override onlyManager {
        _onListenRemoved(hname);
    }

    function _onListenRemoved(bytes32 hname) internal virtual {
        if (hname == CoreConsts.ROLE_MANAGER_MODULE_ID) {
            authManager = IAccessControl(address(0));
        }
    }

    function onUpdate(
        address oldInstance,
        address _manager
    ) external virtual override {
        _onUpdate(oldInstance, _manager);
    }

    function _onUpdate(
        address oldInstance,
        address _manager
    ) internal virtual onlyManager {
        manager = IModuleManager(_manager);

        require(
            IModuleListener(oldInstance).getVersion() != this.getVersion(),
            "The version of the updated contract must differ from the previous one"
        );

        emit ModuleUpdated(oldInstance, _manager);
    }

    function onAdd(address _manager) external virtual override {
        _onAdd(_manager);
    }

    function _onAdd(address _manager) internal virtual onlyManager {
        manager = IModuleManager(_manager);

        emit ModuleAdded(_manager);
    }

    function onReplaced(address newInstance) external virtual override {
        _onReplaced(newInstance);
    }

    function _onReplaced(address newInstance) internal virtual onlyManager {
        emit ModuleReplaced(newInstance);
    }

    function onRemoved() external virtual override {
        _onRemoved();
    }

    function _onRemoved() internal virtual onlyManager {
        manager = IModuleManager(address(0));

        emit ModuleRemoved();
    }

    function updateOwnership(address newOwner) external virtual override {
        _updateOwnership(newOwner);
    }

    function _updateOwnership(address newOwner) internal virtual onlyManager {
        transferOwnership(newOwner);

        emit ModuleOwnershipUpdate(newOwner);
    }

    function switchManager(address newManager) external virtual override {
        _switchManager(newManager);
    }

    function _switchManager(address newManager) internal virtual onlyManager {
        manager = IModuleManager(newManager);
        grantRole(CoreConsts.MANAGER_ROLE, newManager);
        revokeRole(CoreConsts.MANAGER_ROLE, msg.sender);

        emit ModuleManagerSwitch(newManager);
    }

    function linkRoleManager(address addr) public virtual onlyOwner {
        _linkRoleManager(addr);
    }

    function _linkRoleManager(address addr) internal virtual {
        authManager = IAccessControl(addr);

        emit LinkRoleManager(addr);
    }

    function hasRole(
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
        if (!super.hasRole(role, account)) {
            if (address(authManager) != address(0)) {
                return authManager.hasRole(role, account);
            } else return false;
        } else return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IModuleListener).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IModuleManager {
    event Man_ModuleReplaced(bytes32 h_name, address module_addr);

    event Man_ModuleAdded(bytes32 h_name, address module_addr);

    event ManagerUpdatedFrom(address oldManager);

    event ManagerUpdatedTo(address newManager);

    function onSwitchManager(address oldManager) external;

    function addModule(address module_addr) external;

    function addModule(string calldata name, address module_addr) external;

    function removeModule(string calldata name) external;

    function isListener(address instance) external view returns (bool);

    function upgradeManager(address newManager) external;

    function getModule(string calldata name) external view returns (address);

    function getModule(bytes32 id) external view returns (address);

    function getModuleId(address addr) external view returns (bytes32);

    function getModuleIdAt(uint256 idx) external view returns (bytes32);

    function getModulesCount() external view returns (uint256);

    function getManagerRoleCode() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IApp {
    enum Rarity {
        COMMON,
        RARE,
        LEGENDARY
    }
    enum RequestType {
        MINT,
        UPGRADE
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library CryptoLib {
    error InvalidSignatureLength(bytes);
    error InvalidSignatureVersion(bytes);

    function verifySig(bytes32 rawHash, bytes memory signature) internal pure returns (address) {
        bytes32 messageHash = _prefixed(rawHash);
        return _recoverSigner(messageHash, signature);
    }

    function _prefixed(bytes32 rawHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", rawHash));
    }

    function _recoverSigner(bytes32 messageHash, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        return ecrecover(messageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // Check the signature length
        if (sig.length != 65) {
            revert InvalidSignatureLength(sig);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            revert InvalidSignatureVersion(sig);
        }

        return (v, r, s);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

library AuthPluginsLib {
    function getUserRole(address _walletAddr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("WALLET_USER_ROLE_", _walletAddr));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {PluginsConsts} from "./PluginsConsts.sol";

import "./RentableTokensStorage.sol";

abstract contract ConnectorRentableTokensStorage is Initializable {
    RentableTokensStorage public rentable_storage;

    uint256[256] private __gap;

    event StorageLink(address _addr);

    function __Storage_init() internal onlyInitializing {}

    function __Storage_onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) internal returns (bool) {
        if (hname == PluginsConsts.RENT_STORAGE_ID) {
            _linkStorage(contractInstance);
            return true;
        } else return false;
    }

    function __Storage_onListenRemoved(bytes32 hname) internal returns (bool) {
        if (hname == PluginsConsts.RENT_STORAGE_ID) {
            rentable_storage = RentableTokensStorage(address(0));
            return true;
        } else return false;
    }

    function _linkStorage(address addr) internal {
        rentable_storage = RentableTokensStorage(addr);
        emit StorageLink(addr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "../AppConsts.sol";

interface IRentableTokensStorage {
    function setRentable(
        address _tokenAddr,
        uint256 _tokenId
    ) external returns (bytes32);

    //    function setRentable(address _tokenAddr, uint256 _tokenId, uint256 _tokenValue) external returns(bytes32);

    function getTokenId(
        address tokenAddr,
        uint256 tokenId
    ) external returns (bytes32);

    function unsetRentable(bytes32 _tokenId) external;

    function isRentable(bytes32 _tokenId) external view returns (bool);

    function lockToken(
        address _proxyWallet,
        bytes32 _tokenId,
        uint256 _lockTime
    ) external;

    function extendLock(bytes32 _tokenId, uint256 _lockTime) external;

    function getLockedTill(bytes32 _tokenId) external returns (uint256);

    function unlockToken(bytes32 _tokenId) external;

    function trustTokenHolder(address _holder) external returns (bool);

    function untrustTokenHolder(address _holder) external returns (bool);

    function trustProjectTokenHolder(
        address _projectNftContract,
        address _holder
    ) external returns (bool);

    function untrustProjectTokenHolder(
        address _projectNftContract,
        address _holder
    ) external returns (bool);

    function trustIndividualTokenHolder(
        bytes32 _tokenId,
        address _holder
    ) external returns (bool);

    function untrustIndividualTokenHolder(
        bytes32 _tokenId,
        address _holder
    ) external returns (bool);

    function trustHolder4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) external returns (bool);

    function untrustHolder4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) external returns (bool);

    function trustTokenDelegate(address _holder) external returns (bool);

    function untrustTokenDelegate(address _holder) external returns (bool);

    function trustProjectTokenDelegate(
        address _projectNftContract,
        address _holder
    ) external returns (bool);

    function untrustProjectTokenDelegate(
        address _projectNftContract,
        address _holder
    ) external returns (bool);

    function trustIndividualTokenDelegate(
        bytes32 _tokenId,
        address _holder
    ) external returns (bool);

    function untrustIndividualTokenDelegate(
        bytes32 _tokenId,
        address _holder
    ) external returns (bool);

    function trustDelegate4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) external returns (bool);

    function untrustDelegate4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) external returns (bool);

    function getLockedTo(bytes32 _tokenId) external view returns (address);

    function getTokenFromId(
        bytes32 _tokenId
    ) external view returns (AppConsts.Token memory);

    function getLockedTokensFor(
        address _proxywallet
    ) external view returns (bytes32[] memory);

    function isTrustedTokenHolder(address _holder) external view returns (bool);

    function isTrustedProjectTokenHolder(
        address _projectNftContract,
        address _holder
    ) external view returns (bool);

    function isTrustedIndividualTokenHolder(
        bytes32 _tokenId,
        address _holder
    ) external view returns (bool);

    function isTrustedHolder4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) external view returns (bool);

    function isTrustedTokenDelegate(
        address _holder
    ) external view returns (bool);

    function isTrustedProjectTokenDelegate(
        address _projectNftContract,
        address _holder
    ) external view returns (bool);

    function isTrustedIndividualTokenDelegate(
        bytes32 _tokenId,
        address _holder
    ) external view returns (bool);

    function isTrustedDelegate4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

library PluginsConsts {
    string public constant DEFAULT_PLUGIN_NAME = "DEFAULT_PLUGIN";
    bytes32 public constant DEFAULT_PLUGIN_ID =
        keccak256(abi.encodePacked(DEFAULT_PLUGIN_NAME));

    string public constant TX_NFT_DECODER_NAME = "TX_NFT_DECODER";
    bytes32 public constant TX_NFT_DECODER_ID =
        keccak256(abi.encodePacked(TX_NFT_DECODER_NAME));

    string public constant RENT_STORAGE_NAME = "RENT_STORAGE_MODULE";
    bytes32 public constant RENT_STORAGE_ID =
        keccak256(abi.encodePacked(RENT_STORAGE_NAME));

    //    bytes32 public constant RENTABLE_TOKEN_ROLE = keccak256(abi.encodePacked('RENTABLE_TOKEN_ROLE'));
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../AppConsts.sol";

import "./RentableTokensStorageBase.sol";
import "./IRentableTokensStorage.sol";

//import "hardhat/console.sol";

error RentableTokensStorage_AlreadyLocked(
    bytes32 _tokenId,
    address _proxyWallet
);
error RentableTokensStorage_AlreadyRentable(bytes32 _tokenId);
error RentableTokensStorage_NotLocked(bytes32 _tokenId);
error RentableTokensStorage_NotRentable(bytes32 _tokenId);
error RentableTokensStorage_StillLocked(bytes32 _tokenId);
error RentableTokensStorage_NotRentManager(address _caller);
error RentableTokensStorage_NotRentVault(address _holder);
error RentableTokensStorage_EarlyUnlockAttempt(
    bytes32 _tokenId,
    uint256 _lockedTill,
    uint256 _call_time
);

contract RentableTokensStorage is
    RentableTokensStorageBase,
    IRentableTokensStorage
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping(bytes32 => bool) internal rentableTokens;
    mapping(bytes32 => AppConsts.Token) internal id2Token;
    mapping(bytes32 => address) internal lockedTo;
    mapping(bytes32 => uint256) internal lockedTill;
    mapping(address => EnumerableSet.Bytes32Set) internal lockedTokens;
    EnumerableSet.AddressSet internal trustedTokenHolders; // Trust holder for anything
    mapping(address => EnumerableSet.AddressSet)
        internal trustedProjectTokenHolders; // Trust holder for specific NFT smart contracts
    mapping(bytes32 => EnumerableSet.AddressSet)
        internal trustedIndividualTokenHolders; // Trust holder for specific UUID
    mapping(address => EnumerableSet.AddressSet)
        internal trustedHolders4ProxyWallet; // Trust holder for specific proxy wallet
    EnumerableSet.AddressSet internal trustedTokenDelegates;
    mapping(address => EnumerableSet.AddressSet)
        internal trustedProjectTokenDelegates;
    mapping(bytes32 => EnumerableSet.AddressSet)
        internal trustedIndividualTokenDelegates;
    mapping(address => EnumerableSet.AddressSet)
        internal trustedDelegates4ProxyWallet;

    event Rentable(
        bytes32 _tokenUUID,
        AppConsts.TokenType _tokenType,
        address _tokenAddr,
        uint256 _tokenId,
        uint256 _tokenValue
    );
    event NonRentable(bytes32 _tokenUUID);
    event Locked(address _proxyWallet, bytes32 _tokenUUID, uint256 _lockedTill);
    event Unlocked(bytes32 _tokenUUID);
    event ExtendedLock(bytes32 _tokenUUID, uint256 _lockedTill);

    modifier rentManagerOnly() {
        if (!hasRole(AppConsts.RENT_MANAGER_ROLE, msg.sender))
            revert RentableTokensStorage_NotRentManager(msg.sender);
        _;
    }

    modifier isInVault(AppConsts.Token memory _token) {
        address _holder;
        if (_token.tokenType == AppConsts.TokenType.ERC721)
            _holder = IERC721(_token.tokenAddr).ownerOf(_token.tokenId);
        if (!hasRole(AppConsts.RENT_VAULT_ROLE, _holder))
            revert RentableTokensStorage_NotRentVault(_holder);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public virtual initializer {
        RentableTokensStorageBase.__Base_init();
    }

    function setRentable(
        address _tokenAddr,
        uint256 _tokenId
    ) public override rentManagerOnly returns (bytes32) {
        //	console.log("setRentable");
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            _tokenAddr,
            _tokenId
        );
        return _setRentable(_token);
    }

    /*    function setRentable(address _tokenAddr, uint256 _tokenId, uint256 _tokenValue) public override rentManagerOnly returns(bytes32){
	AppConsts.Token memory _token = AppConsts.getTokenStruct(_tokenAddr, _tokenId, _tokenValue);
	return _setRentable(_token);
    }*/

    function _setRentable(
        AppConsts.Token memory _token
    ) internal isInVault(_token) returns (bytes32) {
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        if (rentableTokens[tokenUUID])
            revert RentableTokensStorage_AlreadyRentable(tokenUUID);
        id2Token[tokenUUID] = _token;
        rentableTokens[tokenUUID] = true;
        emit Rentable(
            tokenUUID,
            _token.tokenType,
            _token.tokenAddr,
            _token.tokenId,
            _token.tokenValue
        );
        //	console.log("EMITTED!");
        return tokenUUID;
    }

    function unsetRentable(bytes32 _tokenUUID) public override rentManagerOnly {
        _unsetRentable(_tokenUUID);
    }

    function _unsetRentable(bytes32 _tokenUUID) internal {
        if (lockedTo[_tokenUUID] != address(0))
            revert RentableTokensStorage_StillLocked(_tokenUUID);
        delete rentableTokens[_tokenUUID];
        delete id2Token[_tokenUUID];
        emit NonRentable(_tokenUUID);
    }

    function isRentable(
        bytes32 _tokenUUID
    ) public view override returns (bool) {
        return rentableTokens[_tokenUUID];
    }

    function lockToken(
        address _proxyWallet,
        bytes32 _tokenUUID,
        uint256 _lockTime
    ) public override rentManagerOnly {
        _lockToken(_proxyWallet, _tokenUUID, _lockTime);
    }

    function _lockToken(
        address _proxyWallet,
        bytes32 _tokenUUID,
        uint256 _lockTime
    ) internal {
        if (!rentableTokens[_tokenUUID])
            revert RentableTokensStorage_NotRentable(_tokenUUID);
        if (lockedTo[_tokenUUID] != address(0))
            revert RentableTokensStorage_AlreadyLocked(
                _tokenUUID,
                lockedTo[_tokenUUID]
            );
        lockedTo[_tokenUUID] = _proxyWallet;
        lockedTill[_tokenUUID] = block.timestamp + _lockTime;
        lockedTokens[_proxyWallet].add(_tokenUUID);
        emit Locked(_proxyWallet, _tokenUUID, lockedTill[_tokenUUID]);
    }

    function extendLock(
        bytes32 _tokenUUID,
        uint256 _lockTime
    ) public override rentManagerOnly {
        if (lockedTo[_tokenUUID] == address(0))
            revert RentableTokensStorage_NotLocked(_tokenUUID);
        lockedTill[_tokenUUID] = lockedTill[_tokenUUID] + _lockTime;
        emit ExtendedLock(_tokenUUID, lockedTill[_tokenUUID]);
    }

    function unlockToken(bytes32 _tokenUUID) public override rentManagerOnly {
        _unlockToken(_tokenUUID);
    }

    function _unlockToken(bytes32 _tokenUUID) internal {
        if (lockedTo[_tokenUUID] == address(0))
            revert RentableTokensStorage_NotLocked(_tokenUUID);
        if (block.timestamp < lockedTill[_tokenUUID])
            revert RentableTokensStorage_EarlyUnlockAttempt(
                _tokenUUID,
                lockedTill[_tokenUUID],
                block.timestamp
            );
        lockedTokens[lockedTo[_tokenUUID]].remove(_tokenUUID);
        delete lockedTo[_tokenUUID];
        delete lockedTill[_tokenUUID];
        emit Unlocked(_tokenUUID);
    }

    function getTokenId(
        address tokenAddress,
        uint256 tokenId
    ) public pure override returns (bytes32) {
        return
            AppConsts.token2Id(AppConsts.getTokenStruct(tokenAddress, tokenId));
    }

    function getLockedTo(
        bytes32 _tokenUUID
    ) public view override returns (address) {
        return lockedTo[_tokenUUID];
    }

    function getLockedTill(
        bytes32 _tokenUUID
    ) public view override returns (uint256) {
        return lockedTill[_tokenUUID];
    }

    function getTokenFromId(
        bytes32 _tokenUUID
    ) public view override returns (AppConsts.Token memory) {
        return id2Token[_tokenUUID];
    }

    function getLockedTokensFor(
        address _proxywallet
    ) public view override returns (bytes32[] memory) {
        return lockedTokens[_proxywallet].values();
    }

    function trustTokenHolder(
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedTokenHolders.add(_holder);
    }

    function untrustTokenHolder(
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedTokenHolders.remove(_holder);
    }

    function isTrustedTokenHolder(
        address _holder
    ) public view override returns (bool) {
        return trustedTokenHolders.contains(_holder);
    }

    function trustProjectTokenHolder(
        address _projectNftContract,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedProjectTokenHolders[_projectNftContract].add(_holder);
    }

    function untrustProjectTokenHolder(
        address _projectNftContract,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedProjectTokenHolders[_projectNftContract].remove(_holder);
    }

    function isTrustedProjectTokenHolder(
        address _projectNftContract,
        address _holder
    ) public view override returns (bool) {
        return
            trustedProjectTokenHolders[_projectNftContract].contains(_holder);
    }

    function trustIndividualTokenHolder(
        bytes32 _tokenUUID,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedIndividualTokenHolders[_tokenUUID].add(_holder);
    }

    function untrustIndividualTokenHolder(
        bytes32 _tokenUUID,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedIndividualTokenHolders[_tokenUUID].remove(_holder);
    }

    function isTrustedIndividualTokenHolder(
        bytes32 _tokenUUID,
        address _holder
    ) public view override returns (bool) {
        return trustedIndividualTokenHolders[_tokenUUID].contains(_holder);
    }

    function trustHolder4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedHolders4ProxyWallet[_proxyWallet].add(_holder);
    }

    function untrustHolder4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedHolders4ProxyWallet[_proxyWallet].remove(_holder);
    }

    function isTrustedHolder4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) public view override returns (bool) {
        return trustedHolders4ProxyWallet[_proxyWallet].contains(_holder);
    }

    function trustTokenDelegate(
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedTokenDelegates.add(_holder);
    }

    function untrustTokenDelegate(
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedTokenDelegates.remove(_holder);
    }

    function isTrustedTokenDelegate(
        address _holder
    ) public view override returns (bool) {
        return trustedTokenDelegates.contains(_holder);
    }

    function trustProjectTokenDelegate(
        address _projectNftContract,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedProjectTokenDelegates[_projectNftContract].add(_holder);
    }

    function untrustProjectTokenDelegate(
        address _projectNftContract,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return
            trustedProjectTokenDelegates[_projectNftContract].remove(_holder);
    }

    function isTrustedProjectTokenDelegate(
        address _projectNftContract,
        address _holder
    ) public view override returns (bool) {
        return
            trustedProjectTokenDelegates[_projectNftContract].contains(_holder);
    }

    function trustIndividualTokenDelegate(
        bytes32 _tokenUUID,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedIndividualTokenDelegates[_tokenUUID].add(_holder);
    }

    function untrustIndividualTokenDelegate(
        bytes32 _tokenUUID,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedIndividualTokenDelegates[_tokenUUID].remove(_holder);
    }

    function isTrustedIndividualTokenDelegate(
        bytes32 _tokenUUID,
        address _holder
    ) public view override returns (bool) {
        return trustedIndividualTokenDelegates[_tokenUUID].contains(_holder);
    }

    function trustDelegate4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedDelegates4ProxyWallet[_proxyWallet].add(_holder);
    }

    function untrustDelegate4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) public override rentManagerOnly returns (bool) {
        return trustedDelegates4ProxyWallet[_proxyWallet].remove(_holder);
    }

    function isTrustedDelegate4ProxyWallet(
        address _proxyWallet,
        address _holder
    ) public view override returns (bool) {
        return trustedDelegates4ProxyWallet[_proxyWallet].contains(_holder);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "../AppModuleUpgradeable.sol";

import "./PluginsConsts.sol";

abstract contract RentableTokensStorageBase is AppModuleUpgradeable {
    uint256[256] private __gap;

    function __Base_init() internal onlyInitializing {
        AppModuleUpgradeable.__AppModule_init();
    }

    function getId() public pure override returns (bytes32) {
        return PluginsConsts.RENT_STORAGE_ID;
    }

    function getName() public pure override returns (string memory) {
        return PluginsConsts.RENT_STORAGE_NAME;
    }

    function getVersion() external pure virtual override returns (bytes32) {
        return keccak256(abi.encodePacked("mv1.0")); // Module: first release
    }

    function onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) public override onlyManager {
        _onListenAdded(hname, contractInstance, isNew);
    }

    function _onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) internal override {
        ModuleUpgradeable._onListenAdded(hname, contractInstance, isNew);
    }

    function onListenRemoved(bytes32 hname) public override onlyManager {
        _onListenRemoved(hname);
    }

    function _onListenRemoved(bytes32 hname) internal override {
        ModuleUpgradeable._onListenRemoved(hname);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/* Errors */
// error Vault__UnsetPrice(address, uint256);
error Vault__NotVaultAdmin(address);
error Vault__TooShortDuration(uint256);
error Vault__TooLongDuration(uint256);
error Vault__ExceedMaxRentalAmount(address, uint256);
error Vault__NotEnoughValue(uint256, uint256);
error Vault__RentCreditExceeded(uint256);

/**
 * @notice Vault for all ZipZap owned NFTs
 */
interface IVault is IERC721Receiver {
    event Vault__received(address tokenAddress, uint256 tokenId);
    event Vault__adminWithdraw(
        address tokenAddress,
        uint256 tokenId,
        address adminAddress
    );
    event Vault__userWithdraw(
        address tokenAddress,
        uint256 tokenId,
        address proxyWallet,
        uint256 lockedUntil
    );
    event Vault__reclaim(
        address proxyWallet,
        address tokenAddress,
        uint256 tokenId
    );

    event Vault__Refer(address referer_proxy, address referee_proxy, uint256 ref_uuid);
    event Vault__SetReferenceTime(uint256 _time);
    event Vault__SetRefererRewardPercentage(uint256 _percent);
    event Vault__SetRefereeRewardPercentage(uint256 _percent);
    event Vault__SetPrice(address nftAddress, uint256 tokenId, uint256 price);
    event Vault__SetValue(address nftAddress, uint256 tokenId, uint256 value);
    event Vault__SetMaxRentalAmount(uint256 amount);
    event Vault__SetMinRentDuration(uint256 _minDuration);
    event Vault__SetMaxRentDuration(uint256 _maxDuration);
    event Vault__SetCreditSpendCap(uint256 _cap);
    event Vault__AddRentCredit(address proxyWallet, uint256 value);
    event Vault__RemoveRentCredit(address proxyWallet, uint256 value);

    function withdrawETH(uint256 value) external;

    /**
     * @dev see OpenZeppelin onERC721Received
     */
    function onERC721Received(
        address /* operator */,
        address from /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4 selector);

    /**
     * @notice sets the price of a specified NFT
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the ID of the NFT we are setting the price for
     * @param price - the price to be set for this NFT
     */
    function setPrice(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external;

    /**
     * @notice returns the price of a specified NFT
     * @param nftAddress - the address of the nft to query
     * @param tokenId - the tokenId of the nft to query
     * @return uint256 - the price of the nft to query
     */
    function getPrice(
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    function getValue(
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    function setValue(
        address nftAddress,
        uint256 tokenId,
        uint256 value
    ) external;

    /**
     * @notice Adds rental credit to a specified proxywallet
     * @param proxyWallet - the address of the proxywallet to credit
     * @param value - amount to credit
     * @return - the proxywallet's credit after the operation
     */
    function addRentCredit(
	address proxyWallet,
	uint256 value
    ) external returns (uint256);

    /**
     * @notice Removes rental credit from a specified proxywallet
     * @param proxyWallet - the address of the proxywallet to remove credit from
     * @param value - the amount to credit to remove. If the value exceed the total proxywallet's credit, then all the credit is removed
     * @return - the proxywallet's credit after the operation
     */
    function removeRentCredit(
	address proxyWallet,
	uint256 value
    ) external returns (uint256);

    /**
     * @notice returns current rental credit amount for a specified proxywallet
     * @param proxyWallet - the address of the proxywallet
     * @return - the proxywallet's current rental credit balance
     */
    function getRentCredit(
	address proxyWallet
    ) external view returns (uint256);

    function getMaxRentalAmount() external view returns (uint256);

    function setMaxRentalAmount(uint256) external;

    function getRentalAmount(address) external view returns (uint256);

    function getMinRentDuration() external view returns (uint256);

    function setMinRentDuration(uint256) external;

    function getMaxRentDuration() external view returns (uint256);

    function setMaxRentDuration(uint256) external;

    /**
     * @notice Get total rental duration for the specified token with the specified payment
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the token ID
     * @param value - the anticipated value to be payed for the rent
     * @return - the anticipated rental period in seconds
     */
    function getDuration(
        address nftAddress,
        uint256 tokenId,
        uint256 value
    ) external view returns (uint256);


    /**
     * @notice rent out the specified NFT token to the payer proxywallet
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the token ID
     */
    function withdraw(address nftAddress, uint256 tokenId) external payable;

    /**
     * @notice rent out the specified NFT token to the specified proxiwallet
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the token ID
     * @param to - the recipient proxywallet
     */
    function withdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to
    ) external payable;

    /**
     * @notice rent out multiple specified NFT tokens to the specified proxiwallet
     * @param nftAddresses - the addresses of the contracts housing the NFT tokens
     * @param tokenIds - the token IDs
     * @param nftFees - the fees distribution for the respective token rentals
     * @param to - the recipient proxywallet
     */
    function withdrawMultiple(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata nftFees,
        address to
    ) external payable;


    /**
     * @notice Get total rental duration for the specified token with the specified payment and credit
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the token ID
     * @param value - the anticipated value to be payed for the rent
     * @param credit - the rental credit anticipated to be used
     * @return - the anticipated rental period in seconds
     */
    function getDuration(
        address nftAddress,
        uint256 tokenId,
        uint256 value,
	uint256 credit
    ) external view returns (uint256);

    /**
     * @notice rent out the specified NFT token to the payer proxywallet
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the token ID
     * @param credit - the rental credit anticipated to be used
     */
    function withdraw(address nftAddress, uint256 tokenId, uint256 credit) external payable;

    /**
     * @notice rent out the specified NFT token to the specified proxiwallet
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the token ID
     * @param to - the recipient proxywallet
     * @param credit - the rental credit anticipated to be used
     */
    function withdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to,
	uint256 credit
    ) external payable;

    /**
     * @notice rent out multiple specified NFT tokens to the specified proxiwallet
     * @param nftAddresses - the addresses of the contracts housing the NFT tokens
     * @param tokenIds - the token IDs
     * @param nftFees - the fees distribution for the respective token rentals
     * @param to - the recipient proxywallet
     * @param credits - the rental credit distribution per token
     */
    function withdrawMultiple(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata nftFees,
        address to,
	uint256[] calldata credits
    ) external payable;

    function adminWithdraw(address nftAddress, uint256 tokenId) external;

    /**
     * @notice admin withdraws multiple specified NFT tokens to the specified proxiwallet
     * @param nftAddresses - the addresses of the contracts housing the NFT tokens
     * @param tokenIds - the token IDs
     */
    function adminWithdrawMultiple(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds
    ) external;

    function adminWithdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to
    ) external;

    function reclaim(
        address proxyWallet,
        address nftAddress,
        uint256 tokenId
    ) external;

    function reclaimEOA(
        address proxyWallet,
        address nftAddress,
        uint256 tokenId
    ) external;

    /**
     * @notice Sets for a referee proxy wallet the referent. proxy wallet Only one referent can be set for any proxywallet account
     * @param referer_proxy - The referent proxy wallet address. This can be either EOA or contract address
     * @param ref_uuid - The reference UUID
     * @param signature - The signature by the referent (referer's proxywallet) of this reference UUID
     * @param referee_proxy - The referee proxy wallet address. This can be either EOA or contract address
    */
    function setReference(
        address referer_proxy,
        uint256 ref_uuid,
        bytes memory signature,
        address referee_proxy
    ) external;

    /**
     * @notice Get the referer proxywallet address for given proxywallet address
     * @param referee_proxy - the referee proxywallet for which we want to get the proxy wallet
     * @return The referer proxywallet address if the referee_proxywallet is references, otherwise return address(0)
     */
    function getReferer(address referee_proxy) external view returns (address);

    /**
     * @notice Sets the reference active time, during which the credit award reference program is functional
     * @param time - The reference active time since a proxy wallet is being referenced
     */
    function setReferenceActiveTime(uint256 time) external;

    /**
     * @notice Gets the reference active time, during which the credit award reference program is functional
     * @return The reference active time since a proxy wallet is being referenced
     */
    function getReferenceActiveTime() external view returns (uint256);

    /**
     * @notice Sets absolute reward cap per reference in rental credits for a referer. The referer can earn as much as the _cap per referencing someone.
     * @param cap - The maximal reward _cap per reference
     */
    function setRefererRewardCap(uint256 cap) external;

    /**
     * @notice Sets absolute reward cap per reference in rental credits for a referee. The referee can earn as much as the cap when being referenced by someone. 
     * @param cap - The maximal reward _cap per reference
     */
    function setRefereeRewardCap(uint256 cap) external;

    /**
     * @notice Gets absolute reward cap per reference in rental credits. The referee can earn as much as the cap when being referenced by someone. 
     * @return The maximal reward cap per reference
     */
    function getRefereeRewardCap() external view returns(uint256);

    /**
     * @notice Gets absolute reward cap per reference in rental credits.
     * The referer can earn as much as cap per reference.
     * @return The maximal reward cap per reference
     */
    function getRefererRewardCap() external view returns(uint256);

    /**
     * @notice Sets the referer reward percentage. When the referee spends X amount (native cryptocurrency) on rent, the referent gets X*_percent/100 
     * of rewards in rental credit (limited by the reward cap)
     * @param percent - The percent (0..100)
     */
    function setRefererRewardPercentage(uint8 percent) external;

    /**
     * @notice Gets the referer reward percentage. When the referee spends X amount (native cryptocurrency) on rent, the referent gets X*_percent/100 
     * of rewards in rental credit (limited by the reward cap)
     * @return The percent (0..100)
     */
    function getRefererRewardPercentage() external view returns(uint8);

    /**
     * @notice Sets the referer reward percentage. When the referee spends X amount (native cryptocurrency) on rent, the referent gets X*_percent/100 
     * of rewards in rental credit (limited by the reward cap)
     * @param percent - The percent (0..100)
     */
    function setRefereeRewardPercentage(uint8 percent) external;

    /**
     * @notice Gets the referer reward percentage. When the referee spends X amount (native cryptocurrency) on rent, the referent gets X*_percent/100 
     * of rewards in rental credit (limited by the reward cap)
     * @return The percent (0..100)
     */
    function getRefereeRewardPercentage() external view returns(uint8);

    /**
     * @notice Sets credit spend cap per rent in percent
     * @param _cap - the spending cap in percent
     */
    function setCreditSpendCap(uint8 _cap) external;

    /**
     * @notice Gets credit spend cap per rent in percent
     * @return Returns the spending cap
     */
    function getCreditSpendCap() external view returns (uint256);

    /**
     * @notice Gets the toal number of references for the given referer
     * @param referer_proxy - the referer
     * @return t6he number of references
     */
    function getReferenceCount(address referer_proxy) external view returns (uint256);

    /**
     * @notice Checks whether the given proxy wallet can be controlled by the given user
     * @param proxy_wallet - The proxy wallet address (can be either smart contract or EOA)
     * @param user - The user's address
     * @return True - if the given user has right to controll the proxy wallet
     **/
    function isProxyWalletUser(address proxy_wallet, address user) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../proxywallet/IProxyWallet.sol";
import "./IVault.sol";
import "./VaultModuleBase.sol";
import "../txauthorizer/AuthPluginsLib.sol";
import { CryptoLib } from "../libs/CryptoLib.sol";

import "hardhat/console.sol";

error Vault__ReferenceAlreadyUsed(uint256);
error Vault__AlreadyReferenced(address, address);
error Vault__NotWalletUser(address, address);
error Vault__InvalidSignatureLength(bytes);
error Vault__InvalidSignatureVersion(bytes);
error Vault__WrongSignature(bytes32, bytes);
error Vault__TwoWayReference(address, address);
error Vault__CreditCapExceeded(uint256 credit, uint256 cap);

/**
 * @notice Vault for all ZipZap owned NFTs
 */
contract VaultModule is IVault, ReentrancyGuardUpgradeable, VaultModuleBase {
    // using EnumerableSet for EnumerableSet.AddressSet;
    // using EnumerableSet for EnumerableSet.UintSet;
    uint256 private minRentDuration;
    uint256 private maxRentDuration;
    uint256 private maxRentalAmount;
    mapping(address => mapping(uint256 => uint256)) private prices; // Price/day of each NFT
    mapping(address => mapping(uint256 => uint256)) private values; // Value of each NFT
    mapping(address => uint256) private walletToRentalAmount;
    mapping(address => uint256) private rentCredit; // Non-transferable, rental credit power is equivalent to the currency used for rental payments
    mapping(address => uint256) refereesUUID; // Reference UUID assigned to a referee
    mapping(uint256 => address) private uuidToReferent; // Mapping from the reference UUID to its referent
    mapping(uint256 => uint256) usedReferences; // The list of used reference UUIDs. Each UUID can be used at most once. Stores the time of reference assignment
    mapping(uint256 => uint256) private _refereeUsedRewards; // Total rewards for referee on the given reference
    mapping(uint256 => uint256) private _refererUsedRewards; // Total rewards for referer on the given reference
    uint256 private ref_time;
    uint256 private reward_cap;
    uint8 private referer_reward;
    uint8 private referee_reward;
    uint256 private referer_reward_cap;
    uint256 private referee_reward_cap;
    uint8 private credits_per_rent_cap;
    mapping(address => uint256) private _refCount; // Total number of references per referer

    modifier onlyVaultAdmin() {
        if (
            !hasRole(AppConsts.VAULT_ADMIN_ROLE, msg.sender) &&
            msg.sender != address(this)
        ) revert Vault__NotVaultAdmin(msg.sender);
        _;
    }

    modifier onlyToVaultAdmin(address to) {
        if (
            !hasRole(AppConsts.VAULT_ADMIN_ROLE, to) &&
            msg.sender != address(this)
        ) revert Vault__NotVaultAdmin(to);
        _;
    }


    modifier isWalletUser(address user, address proxywallet){
	if(
	    !hasRole(
		AuthPluginsLib.getUserRole(proxywallet),
		user
	    )
	) revert Vault__NotWalletUser(user, proxywallet);
	_;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external virtual initializer {
        ContextUpgradeable.__Context_init();
	ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        VaultModuleBase.__Base_init();
    }

    function _notReferedYet(address proxywallet) internal view{
	uint256 ref_uuid = refereesUUID[proxywallet];
	if(ref_uuid != 0)
	    revert Vault__AlreadyReferenced(uuidToReferent[ref_uuid], proxywallet);
    }

    function _referenceNotUsed(uint256 ref_uuid) internal view{
	if(usedReferences[ref_uuid] != 0)
	    revert Vault__ReferenceAlreadyUsed(ref_uuid);
    }

    function _noReverseReference(address referer_proxy, address referee_proxy) internal view{
	uint256 rev_ref_uuid = refereesUUID[referer_proxy];
	if(rev_ref_uuid != 0)
	    if(uuidToReferent[rev_ref_uuid] == referee_proxy)
		revert Vault__TwoWayReference(referer_proxy, referee_proxy);
    }

    function _getReferenceSigner(bytes memory signature, address referer_proxy, uint256 ref_uuid) internal view returns(address){
	bytes32 hash = getReferenceHash(referer_proxy, ref_uuid);
	return CryptoLib.verifySig(hash, signature);
    }

    function _checkCreditCap(uint256 value, uint256 credit) internal view {
	uint256 cap = (value+credit)*credits_per_rent_cap/100;
	if(credit>cap)
	    revert Vault__CreditCapExceeded(credit, cap);
    }

    function withdrawETH(uint256 value) external override onlyVaultAdmin {
        // TODO make sure collateral doesn't fall below totalCollateralHeld
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev see OpenZeppelin onERC721Received
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4 selector) {
        // Rentable Storage Tracking
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            msg.sender,
            tokenId
        );
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        if (!rentable_storage.isRentable(tokenUUID)) {
            rentable_storage.setRentable(msg.sender, tokenId);
        }
        // TODO track collateral stuff
        // Comply with onERC721Received requirements
        selector = IERC721Receiver.onERC721Received.selector;
        emit Vault__received(msg.sender, tokenId);
    }

    /**
     * @notice sets the price of a specified NFT
     * @param nftAddress - the address of the contract housing the NFT
     * @param tokenId - the ID of the NFT we are setting the price for
     * @param price - the price to be set for this NFT
     */
    function setPrice(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external override onlyVaultAdmin {
        prices[nftAddress][tokenId] = price;

	emit Vault__SetPrice(nftAddress, tokenId, price);
    }

    /**
     * @notice returns the price of a specified NFT
     * @param nftAddress - the address of the nft to query
     * @param tokenId - the tokenId of the nft to query
     * @return uint256 - the price of the nft to query
     */
    function getPrice(
        address nftAddress,
        uint256 tokenId
    ) public view override returns (uint256) {
        uint256 price = prices[nftAddress][tokenId];
        return price;
    }

    function getValue(
        address nftAddress,
        uint256 tokenId
    ) public view override returns (uint256) {
        return values[nftAddress][tokenId];
    }

    function setValue(
        address nftAddress,
        uint256 tokenId,
        uint256 value
    ) external override onlyVaultAdmin {
        // adjust rentAmount of proxywallet that currently holds this NFT, if any
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            nftAddress,
            tokenId
        );
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        address renter = rentable_storage.getLockedTo(tokenUUID);
        if (renter != address(0)) {
            walletToRentalAmount[renter] += value;
            walletToRentalAmount[renter] -= getValue(nftAddress, tokenId);
        }
        // set value
        values[nftAddress][tokenId] = value;

	emit Vault__SetValue(nftAddress, tokenId, value);
    }

    function getMaxRentalAmount() external view override returns (uint256) {
        return maxRentalAmount;
    }

    function setMaxRentalAmount(uint256 amount) external override onlyVaultAdmin {
        maxRentalAmount = amount;

	emit Vault__SetMaxRentalAmount(amount);
    }

    function getRentalAmount(
        address proxyWallet
    ) external view override returns (uint256) {
        return walletToRentalAmount[proxyWallet];
    }

    function getMinRentDuration() external view override returns (uint256) {
        return minRentDuration;
    }

    function setMinRentDuration(
        uint256 _minDuration
    ) external override onlyVaultAdmin {
        minRentDuration = _minDuration;

	emit Vault__SetMinRentDuration(_minDuration);
    }

    function getMaxRentDuration() external view override returns (uint256) {
        return maxRentDuration;
    }

    function setMaxRentDuration(
        uint256 _maxDuration
    ) external override onlyVaultAdmin {
        maxRentDuration = _maxDuration;

	emit Vault__SetMaxRentDuration(_maxDuration);
    }

    function setCreditSpendCap(uint8 _cap) external override onlyVaultAdmin{
	credits_per_rent_cap = _cap;

	emit Vault__SetCreditSpendCap(_cap);
    }

    function getCreditSpendCap() external view override returns (uint256) {
	return credits_per_rent_cap;
    }

    function addRentCredit(
        address proxyWallet,
        uint256 value
    ) external override onlyVaultAdmin returns (uint256){
	rentCredit[proxyWallet] += value;

	emit Vault__AddRentCredit(proxyWallet, value);
	return rentCredit[proxyWallet];
    }

    function removeRentCredit(
        address proxyWallet,
        uint256 value
    ) external override onlyVaultAdmin returns (uint256){
	if(rentCredit[proxyWallet] > value)
	    rentCredit[proxyWallet] -= value;
	else
	    rentCredit[proxyWallet] = 0;

	emit Vault__RemoveRentCredit(proxyWallet, value);
	return rentCredit[proxyWallet];
    }

     function getRentCredit(
        address proxyWallet
    ) external override view returns (uint256){
	return rentCredit[proxyWallet];
    }

    function getDuration(
        address nftAddress,
        uint256 tokenId,
        uint256 value
    ) public view override returns (uint256) {
        uint256 price = getPrice(nftAddress, tokenId);
        if (price == 0) {
            return 0;
        }
        uint256 duration = (value * 86400) / price;
        if (duration < minRentDuration) {
            revert Vault__TooShortDuration(duration);
        } else if (duration > maxRentDuration) {
            revert Vault__TooLongDuration(duration);
        }
        return duration;
    }

    function getDuration(
        address nftAddress,
        uint256 tokenId,
        uint256 value,
        uint256 credit
    ) public override view returns (uint256){
	_checkCreditCap(value, credit);
	return getDuration(nftAddress, tokenId, value + credit);
    }

    function _authorizeProxywalletUser(address proxywallet) internal{
	if(proxywallet != msg.sender)
	    if(!hasRole(
		AuthPluginsLib.getUserRole(proxywallet),
		msg.sender
	    ))revert Vault__NotWalletUser(msg.sender, proxywallet);
    }

    function withdraw(
        address nftAddress,
        uint256 tokenId
    ) external payable override nonReentrant onlyToProxyWallet(msg.sender) {
	_withdrawTo(nftAddress, tokenId, msg.sender, msg.value);
	_rewardReference(msg.sender, msg.value);
    }

    function withdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to
    ) external payable override nonReentrant onlyToProxyWallet(to) {
	_withdrawTo(nftAddress, tokenId, to, msg.value);
	_rewardReference(to, msg.value);
    }

    function withdrawMultiple(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata nftFees,
        address to
    ) external payable override nonReentrant onlyToProxyWallet(to) {
        uint256 totalFee = 0;
        for (uint i = 0; i < nftAddresses.length; i++) {
            totalFee += nftFees[i];
        }
        if (totalFee > msg.value) {
            revert Vault__NotEnoughValue(totalFee, msg.value);
        }
        for (uint i = 0; i < nftAddresses.length; i++) {
            _withdrawTo(
                nftAddresses[i],
                tokenIds[i],
                to,
		nftFees[i]
            );
        }
	_rewardReference(to, totalFee);
    }

    function withdraw(
        address nftAddress,
        uint256 tokenId,
	uint256 credit
    ) external payable override nonReentrant onlyProxyWallet {
	_checkCreditCap(msg.value, credit);
	_withdrawTo(nftAddress, tokenId, msg.sender, msg.value + credit);
	_rewardReference(msg.sender, msg.value);
	_consumeCredit(msg.sender, credit);
    }

    function withdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to,
	uint256 credit
    ) external payable nonReentrant onlyToProxyWallet(to) override {
	_checkCreditCap(msg.value, credit);
	_withdrawTo(nftAddress, tokenId, to, msg.value + credit);
	_rewardReference(to, msg.value);
	_consumeCredit(to, credit);
    }

    function withdrawMultiple(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata nftFees,
        address to,
	uint256[] calldata credits
    ) external payable nonReentrant onlyToProxyWallet(to) override {
        uint256 totalFee = 0;
	uint256 totalCredits = 0;
        for (uint i = 0; i < nftAddresses.length; i++) {
            totalFee += nftFees[i];
        }
        if (totalFee > msg.value) {
            revert Vault__NotEnoughValue(totalFee, msg.value);
        }
        for (uint i = 0; i < credits.length; i++) {
            totalCredits += credits[i];
        }
	_checkCreditCap(msg.value, totalCredits);
        for (uint i = 0; i < nftAddresses.length; i++) {
            _withdrawTo(
                nftAddresses[i],
                tokenIds[i],
                to,
		nftFees[i]+credits[i]
            );
        }
	_rewardReference(to, totalFee);
        _consumeCredit(to, totalCredits);
    }

    function adminWithdrawMultiple(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds
    ) external override onlyVaultAdmin {
        for (uint i = 0; i < nftAddresses.length; i++) {
            this.adminWithdrawTo(nftAddresses[i], tokenIds[i], msg.sender);
        }
    }

    function adminWithdraw(
        address nftAddress,
        uint256 tokenId
    ) external override onlyVaultAdmin {
        this.adminWithdrawTo(nftAddress, tokenId, msg.sender);
    }

    function adminWithdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to
    ) external override onlyToVaultAdmin(to) {
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            nftAddress,
            tokenId
        );
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        rentable_storage.unsetRentable(tokenUUID);
        _withdraw(nftAddress, tokenId, to);
        emit Vault__adminWithdraw(nftAddress, tokenId, to);
    }

    function _consumeCredit(address proxyWallet, uint256 credit) internal {
	if(credit > rentCredit[proxyWallet])
	    revert Vault__RentCreditExceeded(credit);
	rentCredit[proxyWallet] -= credit;
    }

    function _withdrawTo(
        address nftAddress,
        uint256 tokenId,
        address to,
	uint256 value
    ) internal {
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            nftAddress,
            tokenId
        );
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        uint256 duration = getDuration(nftAddress, tokenId, value);
        rentable_storage.lockToken(to, tokenUUID, duration);
        uint256 expiryTime = block.timestamp + duration;
        uint256 newRentalAmount = walletToRentalAmount[to] +
            getValue(nftAddress, tokenId);
        if (newRentalAmount > maxRentalAmount) {
            revert Vault__ExceedMaxRentalAmount(to, newRentalAmount);
        }
        walletToRentalAmount[to] = newRentalAmount;
        emit Vault__userWithdraw(nftAddress, tokenId, to, expiryTime);
        _withdraw(nftAddress, tokenId, to);
    }

    function _withdraw(
        address nftAddress,
        uint256 tokenId,
        address to
    ) internal {
        IERC721(nftAddress).safeTransferFrom(address(this), to, tokenId);
    }

    function reclaim(
        address proxyWallet,
        address nftAddress,
        uint256 tokenId
    ) external override {
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            nftAddress,
            tokenId
        );
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        rentable_storage.unlockToken(tokenUUID);
        walletToRentalAmount[proxyWallet] -= getValue(nftAddress, tokenId);
        bytes memory _data = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            proxyWallet,
            address(this),
            tokenId
        );
        IProxyWallet(proxyWallet).wrapTx(
            payable(nftAddress),
            gasleft(),
            0,
            _data
        );
        emit Vault__reclaim(proxyWallet, nftAddress, tokenId);
    }

    function reclaimEOA(
        address proxyWallet,
        address nftAddress,
        uint256 tokenId
    ) external override {
        AppConsts.Token memory _token = AppConsts.getTokenStruct(
            nftAddress,
            tokenId
        );
        bytes32 tokenUUID = AppConsts.token2Id(_token);
        rentable_storage.unlockToken(tokenUUID);
        walletToRentalAmount[proxyWallet] -= getValue(nftAddress, tokenId);
        IERC721(nftAddress).safeTransferFrom(
            proxyWallet,
            address(this),
            tokenId
        );
	emit Vault__reclaim(proxyWallet, nftAddress, tokenId);
    }

    function setReference(
        address referer_proxy,
        uint256 ref_uuid,
        bytes memory signature,
	address referee_proxy
    ) public override 
	    onlyToProxyWallet(referer_proxy)
	    onlyToProxyWallet(referee_proxy)
    {
	address signer = _getReferenceSigner(signature, referer_proxy, ref_uuid);
	if(signer != referer_proxy)
	    if(
		!hasRole(
		    AuthPluginsLib.getUserRole(referer_proxy),
		    signer
		)
	    )revert Vault__NotWalletUser(signer, referer_proxy);
	_notReferedYet(referee_proxy);
	_referenceNotUsed(ref_uuid);
	_noReverseReference(referer_proxy, referee_proxy);
	refereesUUID[referee_proxy] = ref_uuid;
	usedReferences[ref_uuid] = block.timestamp;
	uuidToReferent[ref_uuid] = referer_proxy;
	_refCount[referer_proxy]++;

	emit	Vault__Refer(referer_proxy, referee_proxy,ref_uuid);
    }

    function getReferer(address referee_proxy) public override view returns (address){
	return uuidToReferent[refereesUUID[referee_proxy]];
    }

    function getReferenceCount(address referer_proxy) public override view returns (uint256){
	return _refCount[referer_proxy];
    }

    function getReferenceHash(address referer, uint256 ref_uuid) public pure returns(bytes32){
	return keccak256(abi.encodePacked('REFERENCE_',ref_uuid));
    }

    function setReferenceActiveTime(uint256 _time) public override onlyVaultAdmin {
	ref_time = _time;

	emit Vault__SetReferenceTime(_time);
    }

    function getReferenceActiveTime() public override view returns (uint256){
	return ref_time;
    }

    function setRefererRewardCap(uint256 _cap) public override onlyVaultAdmin {
	referer_reward_cap = _cap;

	emit Vault__SetRefererRewardPercentage(_cap);
    }

    function setRefereeRewardCap(uint256 _cap) public override onlyVaultAdmin {
	referee_reward_cap = _cap;

	emit Vault__SetRefereeRewardPercentage(_cap);
    }

    function getRefererRewardCap() public override view returns(uint256){
	return referer_reward_cap;
    }

    function getRefereeRewardCap() public override view returns(uint256){
	return referee_reward_cap;
    }

    function setRefererRewardPercentage(uint8 _percent) public override onlyVaultAdmin {
	referer_reward = _percent;

	emit Vault__SetRefererRewardPercentage(_percent);
    }

    function getRefererRewardPercentage() public override view returns(uint8){
	return referer_reward;
    }

    function setRefereeRewardPercentage(uint8 _percent) public override onlyVaultAdmin {
	referee_reward = _percent;

	emit Vault__SetRefereeRewardPercentage(_percent);
    }

    function getRefereeRewardPercentage() public override view returns(uint8){
	return referee_reward;
    }

    function _rewardReference(address referee, uint256 payed_value) internal {
	if(payed_value == 0)return;
	uint256 ref_uuid = refereesUUID[referee];
	if(ref_uuid == 0)return;
	if(block.timestamp - usedReferences[ref_uuid] > ref_time)
	    return;
	address referer = uuidToReferent[ref_uuid];
	uint256 refererRentReward = payed_value*referer_reward/100;
	uint256 refererReward = (_refererUsedRewards[ref_uuid] + refererRentReward > referer_reward_cap)?(referer_reward_cap - _refererUsedRewards[ref_uuid]):refererRentReward;
	_refererUsedRewards[ref_uuid] += refererReward;
	uint256 refereeRentReward = payed_value*referee_reward/100;
	uint256 refereeReward = (_refereeUsedRewards[ref_uuid] + refereeRentReward > referee_reward_cap)?(referee_reward_cap - _refereeUsedRewards[ref_uuid]):refereeRentReward;
	_refereeUsedRewards[ref_uuid] += refereeReward;
	rentCredit[referer]+=refererReward;
	rentCredit[referee]+=refereeReward;
    }

    function isProxyWalletUser(address proxywallet, address user) external view override returns (bool){
	return (hasRole(AppConsts.PROXY_WALLET_ROLE, proxywallet)&&
	    hasRole(
		AuthPluginsLib.getUserRole(proxywallet),
		user
	    ));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ModuleUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            ModuleUpgradeable.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "../AppModuleUpgradeable.sol";
import "../txauthorizer/ConnectorRentableTokensStorage.sol";

abstract contract VaultModuleBase is
    AppModuleUpgradeable,
    ConnectorRentableTokensStorage
{
    uint256[256] private __gap;

    function __Base_init() internal onlyInitializing {
        ConnectorRentableTokensStorage.__Storage_init();
        AppModuleUpgradeable.__AppModule_init();
    }

    function getId() public pure override returns (bytes32) {
        return AppConsts.VAULT_MODULE_ID;
    }

    function getName() public pure override returns (string memory) {
        return AppConsts.VAULT_MODULE_NAME;
    }

    function getVersion() external pure virtual override returns (bytes32) {
        return keccak256(abi.encodePacked("mv1.1.0")); // Module: add referral
    }

    function onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) public override onlyManager {
        _onListenAdded(hname, contractInstance, isNew);
    }

    function _onListenAdded(
        bytes32 hname,
        address contractInstance,
        bool isNew
    ) internal override {
        if (
            !ConnectorRentableTokensStorage.__Storage_onListenAdded(
                hname,
                contractInstance,
                isNew
            )
        ) ModuleUpgradeable._onListenAdded(hname, contractInstance, isNew);
    }

    function onListenRemoved(bytes32 hname) public override onlyManager {
        _onListenRemoved(hname);
    }

    function _onListenRemoved(bytes32 hname) internal override {
        if (!ConnectorRentableTokensStorage.__Storage_onListenRemoved(hname))
            ModuleUpgradeable._onListenRemoved(hname);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

/**
 * @title IProxyWallet
 * @notice Interface for proxy wallets
 */
interface IProxyWallet {
    /**
     * @notice Authorizes, performs, and post-validates a transaction call
     * @param _to The address to send the transaction to
     * @param _gas The amount of gas for the transaction
     * @param _value The amount of ETH to send
     * @param _data The data for this transaction
     * @return The data returned from the recipient
     */
    function wrapTx(
        address payable _to,
        uint256 _gas,
        uint256 _value,
        bytes memory _data
    ) external returns (bytes memory);

    /**
     * @notice Wraps a view call
     * @param _to The address to send the view call to
     * @param _data The data for this call
     * @return The data returned from the recipient
     */
    function wrapViewCall(
        address payable _to,
        bytes memory _data
    ) external view returns (bytes memory);

    /**
     * @notice Withdraws ETH to the user
     * @param value the amount of ETH to withdraw
     */
    function withdraw(uint256 value) external;

    /**
     * @notice Withdraws ERC20 to the user
     * @param erc20Contract the address of the ERC20 to withdraw
     * @param value the amount of ERC20 to withdraw
     */
    function withdrawERC20(address erc20Contract, uint256 value) external;

    function withdrawFromVault(
        address nftAddress,
        uint256 tokenId,
        uint256 value,
        address vault
    ) external;

    function withdrawFromVault(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        address vault
    ) external;

    function withdrawFromVault(
        address nftAddress,
        uint256 tokenId,
        uint256 value,
        address vault,
	uint256 credit
    ) external;

    function withdrawFromVault(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        address vault,
	uint256[] calldata credits
    ) external;

    // function trackWithdrawNFT(address nftContract, uint256 tokenId) external;

    // /**
    //  * @notice returns all addresses of nfts this vault owns
    //  * @return address[] - an array of all addresses of nfts owned
    //  */
    // function getOwnedNftsAddresses() external view returns (address[] memory);

    // /**
    //  * @notice returns the addresses of nfts this vault owns within the range [start, end)
    //  * @param start - the start index of the returned array slice
    //  * @param end - the end index of the returned array slice
    //  * @return address[] - an array of all addresses owned within the specified range
    //  */
    // function getOwnedNftsAddresses(
    //     uint256 start,
    //     uint256 end
    // ) external view returns (address[] memory);

    // /**
    //  * @notice returns all tokenIds of nfts from a specified address this vault owns
    //  * @param nftAddress - the address of the nfts to return tokenIds for
    //  * @return uint256[] - an array of all tokenIds owned for this nft type
    //  */
    // function getOwnedNftsIds(
    //     address nftAddress
    // ) external view returns (uint256[] memory);

    // /**
    //  * @notice returns tokenIds of nfts from a specified address this vault owns
    //  *         within the range [start, end)
    //  * @param nftAddress - the address of the nfts to return tokenIds for
    //  * @param start - the start index of the returned array slice
    //  * @param end - the end index of the returned array slice
    //  * @return uint256[] - an array of all tokenIds owned for this nft type within the specified range
    //  */
    // function getOwnedNftsIds(
    //     address nftAddress,
    //     uint256 start,
    //     uint256 end
    // ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}