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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A contract for giving role for address
/// @dev this is an upgradable function
contract GameAccessControls is AccessControl {
    bytes32 public constant MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08; // keccak256(abi.encodePacked("MANAGER_ROLE"));

    event GameRoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event GameRoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice Constructor for setting up default roles
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    /// @notice function to give an address Admin role
    /// @param _address address that will be getting role
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit GameRoleGranted(DEFAULT_ADMIN_ROLE, _address, _msgSender());
    }

    /// @notice function to give an address Admin role
    /// @param _address address that will be getting role
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit GameRoleRevoked(DEFAULT_ADMIN_ROLE, _address, _msgSender());
    }

    /// @notice function to give role to an address
    /// @param _address address that will be getting role
    function addRole(bytes32 _role, address _address) external {
        grantRole(_role, _address);
        emit GameRoleGranted(_role, _address, _msgSender());
    }

    /// @notice function to remove role of an address
    /// @param _address address that will be revoked
    function removeRole(bytes32 _role, address _address) external {
        revokeRole(_role, _address);
        emit GameRoleRevoked(_role, _address, _msgSender());
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Unauthorized.");
        _;
    }

    /// @notice function to check an address has Admin role
    /// @param _address address that has admin role
    /// @return bool true if address is admmin
    function hasAdminRole(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function isAuthorized(address _address) external view returns (bool) {
        return hasAdminRole(_address) || hasRole(MANAGER_ROLE, _address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GameSession is OwnableUpgradeable {
    using ECDSA for bytes32;

    event Synced(address indexed sender, bytes32 oldSessionId, bytes32 newSessionId);

    address private signer;

    mapping(address => bytes32) public sessions;
    mapping(address => uint256) public syncedTime;

    function setSigner(address _signer) public {
        signer = _signer;
    }

    function generateSessionId(address msgSender) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), sessions[msgSender], block.number)).toEthSignedMessageHash();
    }

    function getSessionId(address msgSender) public view returns (bytes32) {
        bytes32 id = sessions[msgSender];
        if (id == 0) {
            id = keccak256(abi.encodePacked(_msgSender(), block.number)).toEthSignedMessageHash();
        }
        return id;
    }

    function updateSession() public returns (bool) {
        address msgSender = _msgSender();

        sessions[msgSender] = generateSessionId(msgSender);
        return true;
    }

    function isRegisteredUser() public view returns (bool) {
        return sessions[_msgSender()] != 0;
    }

    modifier isRegistered() {
        require(sessions[_msgSender()] != 0, "WorldBattle: Not Registered");
        _;
    }

    //  modifier isReady(uint tokenId) {
    //     require(syncedAt'[tokenId] < block.timestamp - 60, "NftStaking: Too many requests");
    //     _;
    // }

    function verify(bytes32 hash, bytes memory signature) public view returns (bool) {
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        return ethSignedHash.recover(signature) == signer;
    }

    function verificationSignature(bytes32 sessionId, address user, uint256[] memory stakedTokens) private pure returns (bytes32 signature) {
        return keccak256(abi.encode(sessionId, user, stakedTokens));
    }

    // state of the game
    function sync(bytes memory signature, bytes32 sessionId, uint256[] memory stakedTokens) public returns (bool success) {
        address msgSender = _msgSender();
        bytes32 latestGameSessionId = sessions[msgSender];

        require(latestGameSessionId == sessionId, "WorldBattle: Session has changed");

        bytes32 hashToVerify = verificationSignature(sessionId, msgSender, stakedTokens);
        require(verify(hashToVerify, signature), "WorldBattle: Couldn't Verify.");

        bytes32 newSessionId = generateSessionId(msgSender);
        sessions[msgSender] = newSessionId;
        syncedTime[msgSender] = block.timestamp;

        emit Synced(msgSender, sessionId, newSessionId);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./WBBData.sol";
import "./GameAccessControls.sol";

contract WBBActions is Initializable, ContextUpgradeable, WBBData {
    GameAccessControls public accessControls;

    function initialize(GameAccessControls _accessControls) public initializer {
        accessControls = GameAccessControls(_accessControls);
    }

    /*
        ---------------------------------------
        ╔╗ ┌─┐┌┬┐┌┬┐┬  ┌─┐  ╔═╗┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
        ╠╩╗├─┤ │  │ │  ├┤   ╠═╣│   │ ││ ││││└─┐
        ╚═╝┴ ┴ ┴  ┴ ┴─┘└─┘  ╩ ╩└─┘ ┴ ┴└─┘┘└┘└─┘
        ---------------------------------------
    */
    function checkBattleExists(string memory _battleId) public view returns (bool) {
        if (battleList.length > 0) {
            string[] memory allBattleList = battleList;
            for (uint256 i = 0; i < allBattleList.length;) {
                if (keccak256(abi.encodePacked(allBattleList[i])) == keccak256(abi.encodePacked(_battleId))) return true;
            unchecked {
                i++;
            }
            }
        }
        return false;
    }

    function setBattleStatus(string memory _battleId, bool _status) external {
        require(accessControls.isAuthorized(msg.sender), "WBB: Unauthorized to set battle status");
        require(checkBattleExists(_battleId), "WBB: Battle doesn't exist");
        Battle storage battleInstance = battles[_battleId];
        battleInstance.status = _status;
    }

    /**
     * @notice function to create battle requires battleId and bossId, starting time and ending time
     * @param _battleId which is a string and identify battles,
     * @param _bossIds which is an array of string,
     * @param _startTime and
     * @param _endTime are unix timestamp
     */
    function createBattle(string memory _battleId, string[] memory _bossIds, uint256 _startTime, uint256 _endTime) external {
        address operatorAddress = msg.sender;
        require(accessControls.isAuthorized(operatorAddress), "WBB: Unauthorized to create battle");
        require(checkBattleExists(_battleId) == false, "WBB: Battle already Exists");
        require(_endTime > _startTime, "WBB: invalid battle period");

        checkActiveBosses(_bossIds);

        Battle storage battleInstance = battles[_battleId];
        battleInstance.battleId = _battleId;
        battleInstance.startTime = _startTime;
        battleInstance.endTime = _endTime;
        battleInstance.status = true;
        battleInstance.bossCount = _bossIds.length;
        battleList.push(_battleId);

        battleInstance.index = battleList.length - 1;
        for (uint i = 0; i < _bossIds.length; i++) {
            battleInstance.bossIds.push(_bossIds[i]);
        }
        emit CreateBattle(operatorAddress, _battleId, _bossIds, _startTime, _endTime);
    }

    /**
     * @notice function to update battle requires battleId, bossId, starting time and ending time along with battle status.
     *         Note: 1. Battle should be inactive to be able to update.
     *               2. If battle should be updated with new bosses or updated boss, new battle SHOULD be created
     * @param _battleId which is a string and identify battles,
     * @param _startTime and
     * @param _endTime are unix timestamp
     */
    function updateBattle(string memory _battleId, uint256 _startTime, uint256 _endTime) external {
        address operatorAddress = msg.sender;
        require(accessControls.isAuthorized(operatorAddress), "WBB: Unauthorized to update battle");
        require(checkBattleExists(_battleId), "WBB: Battle doesn't exists");
        require(battles[_battleId].status == false, "WBB: Battle is active");

        Battle storage battleInstance = battles[_battleId];
        battleInstance.battleId = _battleId;
        battleInstance.startTime = _startTime;
        battleInstance.endTime = _endTime;

        emit UpdateBattle(operatorAddress, _battleId, _startTime, _endTime);
    }

    /// @notice function to check the battleStatus i.e true or false
    /// @param _battleId its a string
    function checkBattleStatus(string memory _battleId) public view returns (bool) {
        require(checkBattleExists(_battleId), "WBB: Battle doesn't exists");
        return battles[_battleId].status;
    }

    /// @notice to check the battle Ended or not i.e true or false
    /// @param _battleId its a string
    function checkBattleEnded(string memory _battleId) public view returns (bool) {
        return block.timestamp > battles[_battleId].endTime;
    }

    /// @notice gives the end time of an battle in unix
    /// @param _battleId which is in string format
    function getBattlePeriod(string memory _battleId) public view returns (uint256 startTime, uint256 endTime) {
        return (battles[_battleId].startTime, battles[_battleId].endTime);
    }

    function getLatestBattle() public view returns (string memory battleId) {
        return battleList[battleList.length - 1];
    }

    function getAllBattle() public view returns (string[] memory) {
        return battleList;
    }

    /*
        ---------------------------------
        ╔╗ ┌─┐┌─┐┌─┐  ╔═╗┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
        ╠╩╗│ │└─┐└─┐  ╠═╣│   │ ││ ││││└─┐
        ╚═╝└─┘└─┘└─┘  ╩ ╩└─┘ ┴ ┴└─┘┘└┘└─┘
        ---------------------------------
    */

    function checkBossExists(string memory _bossId) public view returns (bool) {
        if (bossList.length > 0) {
            string[] memory allBossList = bossList;
            for (uint256 i = 0; i < allBossList.length;) {
                if (keccak256(abi.encodePacked(allBossList[i])) == keccak256(abi.encodePacked(_bossId))) return true;
                unchecked {
                    i++;
                }
            }
        }
        return false;
    }

    function setBossStatus(string memory _bossId, bool _status) external {
        require(accessControls.isAuthorized(msg.sender), "WBB: Unauthorized to update boss status");
        require(checkBossExists(_bossId), "WBB: Boss doesn't exist");
        Boss storage bossInstance = bosses[_bossId];
        bossInstance.status = _status;
    }

    /// @notice checks the boss is available or not
    /// @param _bossId is should be given as parameter
    function checkActiveBosses(string[] memory _bossId) public view {
        for (uint i = 0; i < _bossId.length; i++) {
            require(checkBossStatus(_bossId[i]), "WBB: boss not created");
        }
    }

    /// @notice checks the boss is available or not
    /// @param _bossId is should be given as parameter
    function checkBossStatus(string memory _bossId) public view returns (bool) {
        return bosses[_bossId].status;
    }

    /**
     * @notice Method to create a new boss.
     * @param bossId which is a string and identify boss,
     * @param name which is name of string,
     * @param maxHp is uint that have boss health and
     * @param uri is a string
     */
    function createBoss(string memory bossId, string memory name, uint256 maxHp, string memory uri) public {
        address operatorAddress = msg.sender;
        require(accessControls.isAuthorized(operatorAddress), "WBB: Unauthorized to create boss");
        require(checkBossExists(bossId) == false, "WBB: Boss already Exists");

        Boss storage bossInstance = bosses[bossId];

        bossInstance.bossId = bossId;
        bossInstance.name = name;
        bossInstance.maxHp = maxHp;
        bossInstance.uri = uri;
        bossInstance.status = true;
        bossList.push(bossId);
        bossInstance.index = bossList.length - 1;
        emit CreateBoss(operatorAddress, bossId, name, maxHp, uri);
    }


    /**
     * @notice function to update the boss character
     * @param bossId which is a string and identify boss,
     * @param name which is name of string,
     * @param maxHp is uint that have boss health and
     * @param uri is a string
     */
    function updateBoss(string memory bossId, string memory name, uint256 maxHp, string memory uri) public {
        address operatorAddress = msg.sender;
        require(accessControls.isAuthorized(operatorAddress), "WBB: Unauthorized to update boss");
        require(checkBossExists(bossId), "WBB: Boss doesn't exist");

        Boss storage bossInstance = bosses[bossId];
        require(bossInstance.status == false, "WBB: Boss is active");

        bossInstance.bossId = bossId;
        bossInstance.name = name;
        bossInstance.maxHp = maxHp;
        bossInstance.uri = uri;

        bossList.push(bossId);
        emit UpdateBoss(operatorAddress, bossId, name, maxHp, uri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @title Battle related actions and datastructures
/// @notice you can use this contract for only creating and updating boss and battle
contract WBBData {

    event CreateBattle(address indexed _operatorAddress, string _battleId, string[] _bossIds, uint256 _startTime, uint256 _endTime);
    event UpdateBattle(address indexed _operatorAddress, string _battleId, uint256 _startTime, uint256 _endTime);
    event DisableBattle(string _battleId, bool _status);
    event EnableBattle(string _battleId, bool _status);
    event CreateBoss(address indexed _operatorAddress, string _bossId, string _name, uint256 _maxHp, string _uri);
    event UpdateBoss(address indexed _operatorAddress, string _bossId, string _name, uint256 _maxHp, string _uri);

    /** @notice Data structure to store the information of a battle.
     *  @field battleId The unique identifier for the battle.
     *  @field bossIds The unique identifier for the bosses in the battle.
     *  @field bossCount The number of bosses in the battle.
     *  @field startTime The time at which the battle starts (in Unix timestamp format).
     *  @field endTime The time at which the battle ends (in Unix timestamp format).
     *  @field status The current status of the battle (true for enabled, false for disabled).
     *  @field index An internal index used to keep track of the battle.
     */
    struct Battle {
        string battleId;
        string[] bossIds;
        uint256 bossCount;
        uint256 startTime;
        uint256 endTime;
        bool status;
        uint index;
    }

    /**
     * @notice Data structure to store the information of a boss.
     * @field bossId The unique identifier for the boss.
     * @field name The name of the boss.
     * @field maxHp The maximum hit points of the boss.
     * @field uri The URI where more information about the boss can be found.
     * @field status The current status of the boss (true for enabled, false for disabled).
     * @field index An internal index used to keep track of the boss.
     */
    struct Boss {
        string bossId;
        string name;
        uint256 maxHp;
        string uri;
        bool status;
        uint256 index;
    }

    /// @notice Mapping of battle data, where the key is the battle's identifier and the value is the battle's data structure.
    mapping(string => Battle) public battles;

    /// @notice An array of all the battle identifiers that have been created.
    string[] public battleList;

    /// @notice Mapping of boss data, where the key is the boss's identifier and the value is the boss's data structure.
    mapping(string => Boss) public bosses;

    /// @notice An array of all the boss identifiers that have been created.
    string[] public bossList;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Session.sol";
import "./WBBActions.sol";

import "./interfaces/IToken.sol";
import "./interfaces/ICDHNFTInventory.sol";
import "./interfaces/IWBBActions.sol";
import "./interfaces/GameStakeOps.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title WorldBossBattle, the game will support NFTs for in-game items and stakes the NFTs to join the P2E event.
 * @notice you can use this contract for only staking, un-staking and re-staking the NFTs
 * @dev GameSession and BattleOps are being inherited in this contract
 */

contract WorldBossBattle is Initializable, ContextUpgradeable, GameSession, GameStakeOps, PausableUpgradeable {
    using ECDSA for bytes32;

    /// @notice Event for when setting towerToken contract which emits old token address and new token address along with sender address
    event SetTokenContract(address indexed _oldTokenContract, address indexed _newTokenContract, address _sender);
    /// @notice Event for when setting NFT contract which emits old NFT address and new NFT address along with sender address
    event SetNFTContract(address indexed _oldNFTContract, address indexed _nftContract, address _sender);
    /// @notice Event for when setting NFT Holder which emits old nftHolder address and new nftHolder address along with sender address
    event SetNFTHolder(address indexed _oldHolder, address indexed _newholder, address _sender);
    /// @notice Event for when setting WBBActions contract Address which emits old WBBActions address and new WBBActions address along with sender address
    event SetWBBActionsAddress(address indexed _oldWBBActionsAddress, address indexed _newWBBActionsAddress, address _sender);
    /// @notice Event for when setting maximum number of token a user can stake which emits old count and new count address along with sender address
    event SetMaxStakeCount(uint256 _maxOldCount, uint256 _maxNewCount, address _sender);
    /// @notice Event is emitted when NFT is staked with owner address, token id and in which battle the token is staked
    event NFTStaked(address indexed _nftOwner, uint256 _tokenId, string _battleId, uint256 _stakedTokenTime);
    /// @notice Event is emitted when NFT is un-staked with owner address, token id and in which battle the token is un-staked
    event NFTUnstaked(address indexed _nftReceiver, uint256 _tokenId, string _battleId);
    /// @notice Event is emitted when NFT is re-staked with owner address, token id and in which battle the token is re-staked
    event NFTRestaked(address indexed _player, uint256 _tokenId, string _battleId, uint256 _stakedTokenTime);

    /// @notice to store cdhNFT contract address
    ICDHNFTInventory public cdhNFT;
    /// @notice to store tower token contract
    IToken public tokenAddress;

    IWBBActions public wbbActions;
    GameAccessControls public accessControls;
    address public nftHolder;
    uint256 public lastInteractionTime;

    /// @notice to store data of staker
    struct TokenStaker {
        mapping(string => uint256[]) battleTokenIds;
        mapping(uint256 => uint256) tokenIndex;
        mapping(uint256 => uint256) stakedTokenTime;
        uint256 blockNumber;
    }

    /// @notice List of active staker address
    address[] public stakersAddress;

    /// @notice Mapping for TokenStakers
    mapping(address => TokenStaker) public stakers;

    /// @notice Mapping of tokenId to owner's address
    mapping(uint256 => address) public tokenOwner;

    /// @notice maps tokenId to battleId
    mapping(uint256 => string) public tokenToBattleId;

    /// @notice to store the cooldownPeriod
    uint256 cooldownPeriod;

    /// @notice to store the value in which a user can stake
    uint256 public maxStakeCount;

    /// @notice Flag to enable or disable the battle unstake period.
    /// @dev true - unstake after cool down period end, false - unstake after battle ends
    bool public enableBattlePeriodUnstake;

    /// @notice minimum Tokens for staking
    uint256 public minTokensRequired;

    /**
     * @notice Since it is upgradable function it is initialized instead of using constructor
     * @param _cdhNFTAddress Contract address for NFT Inventory,
     * @param _tokenAddress Contract address for ERC20 token
     * @param _nftHolder Address who holds on staking
     * @param _signer Verified signer to store session
     * @param _maxStakeCount Number of tokens
     * @param _wbbActionsAddress Contract address for WorldBossBattle Actions
     * @param _accessControls Contract address for access controls
     */
    function initialize(
        ICDHNFTInventory _cdhNFTAddress,
        IToken _tokenAddress,
        address _nftHolder,
        address _signer,
        uint256 _maxStakeCount,
        IWBBActions _wbbActionsAddress,
        GameAccessControls _accessControls
    ) public initializer {
        cdhNFT = _cdhNFTAddress;
        tokenAddress = _tokenAddress;
        nftHolder = _nftHolder;
        maxStakeCount = _maxStakeCount;
        wbbActions = IWBBActions(_wbbActionsAddress);
        accessControls = GameAccessControls(_accessControls);

        lastInteractionTime = block.timestamp;
        maxStakeCount = 1000;
        minTokensRequired = 100;

        setSigner(_signer);

        __Context_init();
        __Pausable_init();
    }

    /**
     * @notice function to change the contract address of tower token
     * @param _tokenAddress is the new token address
     * @dev only authorized addresses could change token contract address
     */
    function setToken(address _tokenAddress) external {
        address msgSender = _msgSender();
        require(accessControls.isAuthorized(msgSender), "WBB: Unauthorized");
        require(_tokenAddress != address(0), "WBB: Invalid token address");

        emit SetTokenContract(address(tokenAddress), _tokenAddress, msgSender);
        tokenAddress = IToken(_tokenAddress);
    }

    /**
     * @notice function to change the contract address of CDH NFT
     * @param _nftContract new NFT address
     * @dev only authorized addresses could change NFT contract address
     */
    function setCDHNFTContractAddress(address _nftContract) external {
        address msgSender = _msgSender();
        require(accessControls.isAuthorized(msgSender), "WBB: Unauthorized");
        require(_nftContract != address(0), "WBB: Invalid NFT contract");

        emit SetNFTContract(address(cdhNFT), _nftContract, msgSender);
        cdhNFT = ICDHNFTInventory(_nftContract);
    }

    /**
     * @notice Change the holder address that will set CDH NFT
     * @param _holder new NFT holder address
     * @dev only authorized addresses could change holder address
     */
    function setNFTHolderAddress(address _holder) external {
        address msgSender = _msgSender();
        require(accessControls.isAuthorized(msgSender), "WBB: Unauthorized");

        emit SetNFTHolder(nftHolder, _holder, msgSender);
        nftHolder = _holder;
    }

    /**
     * @notice Change the WBBActionsContract address that will set WBBActionsContract
     * @param _wbbActionsAddress new wbbActionsContract address
     * @dev only authorized addresses could change WBB Actions contract address
     */
    function setWBBActionsContract(address _wbbActionsAddress) external {
        address msgSender = _msgSender();
        require(accessControls.isAuthorized(msgSender), "WBB: Unauthorized");
        require(_wbbActionsAddress != address(0), "WBB: Invalid Actions contract");

        emit SetWBBActionsAddress(address(wbbActions), _wbbActionsAddress, msgSender);
        wbbActions = IWBBActions(_wbbActionsAddress);
    }

    /**
     * @notice Check the limit of token that can be staked
     * @param _tokenIds tokenIDs that about to staked
     */
    function validStakeCount(uint256[] memory _tokenIds) public view returns (bool) {
        return _tokenIds.length + 1 < maxStakeCount;
    }

    /**
     * @notice function to set the limit of token that can be staked
     */
    function setMaxStakeCount(uint256 _maxCount) external {
        address msgSender = _msgSender();
        require(accessControls.isAuthorized(msgSender), "WBB: Unauthorized");

        emit SetMaxStakeCount(maxStakeCount, _maxCount, msgSender);
        maxStakeCount = _maxCount;
    }

    /**
     * @notice to set the cooldown period
     * @param _time in unix
     * @return _time
     */
    function setCoolDownPeriod(uint256 _time) external returns (uint256) {
        require(accessControls.isAuthorized(_msgSender()), "WBB: Unauthorized");
        cooldownPeriod = _time;
        return cooldownPeriod;
    }

    /**
     * @notice Set the boolean status to enable Battle period stake
     * @param _status boolean
     */
    function setBattlePeriodUnstakeStatus(bool _status) public {
        require(accessControls.isAuthorized(_msgSender()), "WBB: Unauthorized");
        enableBattlePeriodUnstake = _status;
    }

    /**************************
     *     Game Operations    *
     **************************/

    /**
     * @notice function to get the latest battle that is created
     */
    function latestBattle() public view returns (string memory) {
        return wbbActions.getLatestBattle();
    }

    /**
     * @param _pastBattleId Previous battleID
     * @param _player Address of player checking eligibility of
     * @return boolean if statement is true
     */
    function isEligibleToStake(string memory _pastBattleId, address _player) public view returns (bool) {
        return stakers[_player].battleTokenIds[_pastBattleId].length > 0;
    }

    /**
     * @notice Internal methods for staking operations
     * @param _nftCount how many nft user have
     * @param _balance user tower token balance
     * @return true if he has higher tower token balance than required
     */
    function checkRequiredTokenBalance(uint256 _nftCount, uint256 _balance) public view returns (bool) {
        uint256 requiredBalance = (_nftCount * minTokensRequired) * 10 ** 18;
        return _balance >= requiredBalance;
    }

    /**
     * @notice function to see user stakedTokenTime for specific tokenId
     * @param _player Address of player getting staked time for token
     * @param _tokenId Staked TokenID
     */
    function getStakedTokenTime(address _player, uint256 _tokenId) public view returns (uint256) {
        TokenStaker storage staker = stakers[_player];
        return staker.stakedTokenTime[_tokenId];
    }

    /// STAKE Operations

    /**
     * @notice function to get all the token that a address has in the Inventory contract
     * @param _player Address of the player to get all tokens
     */
    function getAllToken(address _player) public view returns (uint256[] memory) {
        uint256[] memory allTokens = cdhNFT.getAllTokens(_player);
        return allTokens;
    }

    /**
     * @notice Function to stake a single CDHNFT that sender owns
     * @param _tokenId TokenID of CDH NFT
     * @param _battleId is unique battle in which the NFT will be staked
     * @dev it calls internalStake function for further processing
     */
    function stake(uint256 _tokenId, string memory _battleId) external override {
        internalStake(_msgSender(), _tokenId, _battleId);
    }

    /**
     * @notice Function to stake a array of CDH NFT that sender owns
     * @param tokenIds is an array of tokenId of CDH NFT
     * @param _battleId is unique battle in which the NFT will be staked
     * @dev it calls internalStake function for further processing
     */
    function stakeTokens(uint256[] memory tokenIds, string memory _battleId) external override {
        address player = _msgSender();
        require(validStakeCount(tokenIds), "WBB: Max tokens staked.");
        for (uint i = 0; i < tokenIds.length; i++) {
            internalStake(player, tokenIds[i], _battleId);
        }
    }

    /**
     * @notice internal function where actual staking works
     * @param _player is address of a user
     * @param _tokenId is tokenId that user have
     * @param _battleId in which the token id will be staked
     */
    function internalStake(address _player, uint256 _tokenId, string memory _battleId) internal whenNotPaused {
        require(wbbActions.checkBattleStatus(_battleId), "WBB: battle not created");
        require(wbbActions.checkBattleEnded(_battleId) == false, "WBB: battle ended");

        TokenStaker storage staker = stakers[_player];

        uint256[] memory existingStakedTokens = staker.battleTokenIds[_battleId];
        uint256 existingStakedTokensCount = existingStakedTokens.length;

        uint256 tokenBalance = tokenAddress.balanceOf(_player);

        if (checkRequiredTokenBalance(existingStakedTokensCount + 1, tokenBalance)) {
            staker.blockNumber = block.number;
            staker.battleTokenIds[_battleId].push(_tokenId);
            staker.tokenIndex[_tokenId] = staker.battleTokenIds[_battleId].length - 1;
            staker.stakedTokenTime[_tokenId] = block.timestamp;
            tokenOwner[_tokenId] = _player;
            tokenToBattleId[_tokenId] = _battleId;

            if (existingStakedTokensCount == 0) {
                stakersAddress.push(_player);
            }

            ICDHNFTInventory(cdhNFT).safeTransferFrom(_player, nftHolder, _tokenId, 1, "0x");
            emit NFTStaked(_player, _tokenId, _battleId, block.timestamp);
        } else {
            revert("WBB: Not enough Tower Tokens.");
        }
    }

    /**
     * @notice Function to stake tokenIds in batch for the player on a battleId
     * @param _player is address of a user
     * @param _tokenIds is an array tokenIds that user have
     * @param _battleId in which the token id will be staked
     */
    function internalStakeBatch(address _player, uint256[] memory _tokenIds, string memory _battleId) internal {
        for (uint i = 0; i < _tokenIds.length; i++) {
            internalStake(_player, _tokenIds[i], _battleId);
        }
    }

    /**
     * @notice  function where user can stake without battleId
     * @param _tokenId is tokenId that user are about to stake
     */
    function stakeWithoutBattleId(uint256 _tokenId) external {
        internalStake(_msgSender(), _tokenId, latestBattle());
    }

    /**
     * @notice  function where user can stake all NFT without battleId
     * @dev Stake all the tokens owned by the address
     */
    function stakeAllWithoutBattleId() external {
        address player = _msgSender();
        uint256[] memory allTokens = cdhNFT.getAllTokens(player);
        uint256 nftBalance = allTokens.length;
        string memory latestBattleId = latestBattle();
        if (nftBalance > 0) {
            for (uint i = 0; i < nftBalance; i++) {
                internalStake(player, allTokens[i], latestBattleId);
            }
        }
    }

    /**
     * @notice function to stake an array of token without battleID
     * @param _tokenIds an array of NFT
     */
    function stakeTokensWithoutBattleId(uint256[] memory _tokenIds) external {
        string memory latestBattleId = latestBattle();
        for (uint i = 0; i < _tokenIds.length; i++) {
            internalStake(msg.sender, _tokenIds[i], latestBattleId);
        }
    }

    /**
     * @notice Get all the tokens staked by user in the battleId
     * @param _player is the user address
     */
    function getStakedTokensForBattle(address _player, string memory _battleId) public view returns (uint256[] memory tokenIds) {
        return stakers[_player].battleTokenIds[_battleId];
    }

    /// RE-STAKE Operations

    /**
     * @notice Restake tokenId on battleId for the user
     * @param _tokenId is tokenid that user have
     * @param _battleId in which the token id will be restaked
     */
    function restake(uint256 _tokenId, string memory _battleId) external {
        internalRestake(_msgSender(), _tokenId, _battleId);
    }

    /**
     * @notice Function to restakeAll all tokens owned by the player on a battle
     * @param _battleId in which the token id will be restaked
     */
    function restakeAll(string memory _battleId) external {
        uint256[] memory stakedToken = stakers[_msgSender()].battleTokenIds[_battleId];
        uint256 nftCounts = stakedToken.length;
        if (nftCounts > 0) {
            for (uint i = 0; i < nftCounts; i++) {
                this.restake(stakedToken[i], _battleId);
            }
        }
    }

    /**
     * @notice  function where  restakeTokens works
     * @param _tokenIds is tokenid that user have staked
     * @param _battleId in which the token id will be restaked
     */
    function restakeTokens(uint256[] memory _tokenIds, string memory _battleId) external {
        for (uint i = 0; i < _tokenIds.length; i++) {
            internalRestake(_msgSender(), _tokenIds[i], _battleId);
        }
    }

    /**
     * @notice Internal function to re-stake the tokens of a player on specific battle
     * @param _player is address of a user
     * @param _tokenId is tokenid that user have
     * @param _battleId in which the token id will be restaked
     */
    function internalRestake(address _player, uint256 _tokenId, string memory _battleId) internal {
        require(wbbActions.checkBattleStatus(_battleId) == true, "WBB: battle not created");
        require(tokenOwner[_tokenId] == _player, "WBB: Unauthorized.");
        require(tokenOwner[_tokenId] != address(0), "WBB: Token Id not staked");
        require(!wbbActions.checkBattleEnded(_battleId), "WBB: battle ended");

        TokenStaker storage staker = stakers[_player];
        staker.stakedTokenTime[_tokenId] = block.timestamp;
        emit NFTRestaked(_player, _tokenId, _battleId, staker.stakedTokenTime[_tokenId]);
    }

    /**
     * @notice function where user can restake without battleId
     * @param _tokenId is tokenId that user are about to stake
     */
    function restakeWithoutBattleId(uint256 _tokenId) external override {
        internalRestake(_msgSender(), _tokenId, latestBattle());
    }

    /**
     * @notice function where user can restake an array without battleId
     * @param _tokenIds is tokenid that user are about to stake
     */
    function restakeTokensWithoutBattleId(uint256[] memory _tokenIds) external override {
        for (uint i = 0; i < _tokenIds.length; i++) {
            internalRestake(_msgSender(), _tokenIds[i], latestBattle());
        }
    }

    /**
     * @notice  function where user can restakeAll without battleId
     */
    function restakeAllWithoutBattleId() external override {
        string memory lastBattle = latestBattle();
        uint256[] memory stakedToken = stakers[_msgSender()].battleTokenIds[lastBattle];
        uint256 nftCounts = stakedToken.length;
        if (nftCounts > 0) {
            for (uint i = 0; i < nftCounts; i++) {
                internalRestake(_msgSender(), stakedToken[i], lastBattle);
            }
        }
    }

    /// UN-STAKE Operations

    /**
     * @notice public function to unstake a single CDHNFT that sender owns
     * @param _tokenId TokenId of CDH NFT
     * @param _battleId is unique battle from which the NFT will be unstaked
     * @dev Calls internalUnStake function for unstaking tokens
     */
    function unstake(uint256 _tokenId, string memory _battleId) external override {
        address player = _msgSender();
        require(tokenOwner[_tokenId] == player, "WBB: Unauthorized.");

        internalUnstake(player, _tokenId, _battleId);
    }

    /**
     * @notice public function to unstake all CDHNFT that sender owns
     * @param _battleId is unique battle in which the NFT will be unstaked
     * @dev it calls internalUnStakeAll function for further processing
     */
    function unstakeAll(string memory _battleId) external override {
        internalUnstakeAll(_msgSender(), _battleId);
    }

    /**
     * @notice public function to unstake an array of  CDHNFT that sender owns
     * @param tokenIds is tokenId of CDHNFT
     * @param _battleId is unique battle in which the NFT will be unstaked
     * @dev it calls internalUnStake function for further processing
     */
    function unstakeTokens(uint256[] memory tokenIds, string memory _battleId) external override {
        address player = _msgSender();
        for (uint i = 0; i < tokenIds.length; i++) {
            internalUnstake(player, tokenIds[i], _battleId);
        }
    }

    /**
     * @notice public function to unstake all CDHNFT that sender owns by admin side
     * @param _battleId is unique battle in which the NFT will be unstaked
     * @param _player is the address of a user which nft will be unstaked
     * @dev it calls internalUnStakeAll function for further processing
     */
    function unstakeAllInternal(address _player, string memory _battleId) external {
        require(accessControls.isAuthorized(msg.sender), "WBB: Unauthorized");
        internalUnstakeAll(_player, _battleId);
    }

    /**
     * @notice internal function where actual unstaking works
     * @param _player is address of a user
     * @param _tokenId is tokenid that user staked
     * @param _battleId in which the token id will be unstaked
     */
    function internalUnstake(address _player, uint256 _tokenId, string memory _battleId) internal {
        require(wbbActions.checkBattleStatus(_battleId) == true, "WBB: battle not created");
        require(keccak256(bytes(tokenToBattleId[_tokenId])) == keccak256(bytes(_battleId)), "WBB: Card not staked in given battle");

        TokenStaker storage staker = stakers[_player];

        if (enableBattlePeriodUnstake) {
            require(
                block.timestamp > (staker.stakedTokenTime[_tokenId] + cooldownPeriod) && !wbbActions.checkBattleEnded(_battleId),
                "WBB: cooldown not over"
            );
        } else {
            require(wbbActions.checkBattleEnded(_battleId), "WBB: Battle not ended.");
        }

        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];
        uint256 battleTokenIdsLength = staker.battleTokenIds[_battleId].length;
        uint256 lastBattleTokenId = staker.battleTokenIds[_battleId][battleTokenIdsLength - 1];
        staker.battleTokenIds[_battleId].pop();
        if (staker.battleTokenIds[_battleId].length > 0) {
            if (lastBattleTokenId != _tokenId) {
                staker.battleTokenIds[_battleId][tokenIdIndex] = lastBattleTokenId;
                staker.tokenIndex[lastBattleTokenId] = tokenIdIndex;
                delete staker.tokenIndex[_tokenId];
            }
        }
        staker.stakedTokenTime[_tokenId] = 0;

        if (staker.battleTokenIds[_battleId].length == 0) {
            address lastStakerAddress = stakersAddress[stakersAddress.length - 1];
            stakersAddress.pop();
            if (stakersAddress.length > 0) {
                uint256 stakerIndex;
                for (uint256 i = 0; i < stakersAddress.length; i++) {
                    if (stakersAddress[i] == _player) {
                        stakerIndex = i;
                        break;
                    }
                }
                stakersAddress[stakerIndex] = lastStakerAddress;
            }
        }
        delete tokenOwner[_tokenId];
        delete tokenToBattleId[_tokenId];

        ICDHNFTInventory(cdhNFT).safeTransferFrom(nftHolder, _player, _tokenId, 1, "0x");
        emit NFTUnstaked(_player, _tokenId, _battleId);
    }

    /**
     * @notice internal function for unstaking all the tokens
     * @param _player is address of a user
     * @param _battleId in which the token id will be unstaked
     */
    function internalUnstakeAll(address _player, string memory _battleId) internal {
        uint256[] memory stakedToken = stakers[_player].battleTokenIds[_battleId];
        uint256 nftCounts = stakedToken.length;
        if (nftCounts > 0) {
            for (uint i = 0; i < nftCounts; i++) {
                internalUnstake(_player, stakedToken[i], _battleId);
            }
        }
    }

    /**
     * @notice internal function where unstaking works for batch
     * @param _player is address of a user
     * @param _tokenIds is tokenid that user have
     * @param _battleId in which the token id will be unstaked
     */
    function internalUnstakeBatch(address _player, uint256[] memory _tokenIds, string memory _battleId) internal {
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (tokenOwner[_tokenIds[i]] == msg.sender) {
                internalUnstake(_player, _tokenIds[i], _battleId);
            }
        }
    }

    /**
     * @notice Pause contract so users wont be able to stake new tokens
     */
    function pause() external {
        require(accessControls.isAuthorized(_msgSender()), "WBB: Unauthorized");
        _pause();
    }

    /**
     * @notice UnPause contract so users be able to stake new tokens again
     */
    function unpause() external {
        require(accessControls.isAuthorized(_msgSender()), "WBB: Unauthorized");
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title A interface of worldBattleBoss contract
/// @notice this interface is used in main contract
/// @dev all the funtion present here might be overridden
interface GameStakeOps {
    function stake(uint256 _tokenId, string memory _battleId) external;
    //    function stakeAll(string memory _battleId) external;
    function stakeTokens(uint256[] memory _tokenIds, string memory _battleId) external;

    function unstake(uint256 _tokenId, string memory _battleId) external;
    function unstakeAll(string memory _battleId) external;
    function unstakeTokens(uint256[] memory _tokenIds, string memory _battleId) external;
    function restake(uint256 _tokenId, string memory _battleId) external;
    function restakeAll(string memory _battleId) external;
    function restakeTokens(uint256[] memory _tokenIds, string memory _battleId) external;

    function stakeWithoutBattleId(uint256 _tokenId) external;
    function stakeAllWithoutBattleId() external;
    function stakeTokensWithoutBattleId(uint256[] memory _tokenIds) external;
    function restakeWithoutBattleId(uint256 _tokenId) external;
    function restakeAllWithoutBattleId() external;
    function restakeTokensWithoutBattleId(uint256[] memory _tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/// @title A interface of CDH Inventory NFT 
/// @notice this is used to help interact with real CDH Inventory 
interface ICDHNFTInventory {

    function balanceOf(address owner) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function getAllTokens(address user) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title A interface of CDH Tower token
/// @notice this is used to help interact with real tower token
interface IToken {
    function balanceOf(address owner) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title A interface of WorldBattleBoss Actions contract
/// @notice this interface is used for interface of Actions to use in WBB main contract
interface IWBBActions {
    function checkBattleExists(string memory _battleId) external view returns (bool);

    function setBattleStatus(string memory _battleId, bool _status) external;

    function createBattle(string memory _battleId, string[] memory _bossIds, uint256 _startTime, uint256 _endTime) external;

    function updateBattle(string memory _battleId, uint256 _startTime, uint256 _endTime) external;

    function checkBattleStatus(string memory _battleId) external view returns (bool);

    function checkBattleEnded(string memory _battleId) external view returns (bool);

    function getBattlePeriod(string memory _battleId) external view returns (uint256 startTime, uint256 endTime);

    function getLatestBattle() external view returns (string memory battleId);

    function checkBossExists(string memory _bossId) external view returns (bool);

    function setBossStatus(string memory _bossId, bool _status) external;

    function checkActiveBosses(string[] memory _bossId) external;

    function checkBossStatus(string memory _bossId) external view returns (bool);

    function newBoss(string memory bossId, string memory name, uint256 maxHp, string memory uri) external;

    function updateBoss(string memory bossId, string memory name, uint256 maxHp, string memory uri) external;
}