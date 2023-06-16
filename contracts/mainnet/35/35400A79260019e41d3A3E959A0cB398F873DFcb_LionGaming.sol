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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithMetaTx is IERC20 {
    function executeMetaTransaction(address userAddress, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) external payable returns(bytes memory);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.17;

interface IHousePool {
    struct BetInfo {
        bool parlay;
        address user;
        uint256 Id;
        uint256 amount;
        uint256 result;
        uint256 payout;
        uint256 commission;
    }

    struct ValuesOfInterest {
        int256 expectedValue;
        int256 maxExposure;
        uint256 deadline;
        address signer;
    }

    function storeBets(BetInfo[] memory betinformation) external;
    function updateBets(uint256[] memory _Id, uint256[] memory _payout) external;
    function settleBets(uint256[] memory _Id, uint256[] memory _result) external;
    function setVOI(bytes memory sig_, ValuesOfInterest memory voi_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}

//-----------------------------------------------------------------------------
// LunaFi <-> Lion Gaming balance management contract.
//
// Developed by Lion Gaming Group.
//
// https://liongaming.io/
//
// SPDX-License-Identifier: MIT
//-----------------------------------------------------------------------------

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IERC20WithMetaTx.sol";
import "./interfaces/IHousePool.sol";

import "./lib/DateTime.sol";

/**
 * @title Lion Gaming balance manager
 * @author Lion Gaming Group
 */
contract LionGaming is AccessControlUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable {
    // Contract owner/admin
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    // Lion Gaming agent - majority of interaction with contract
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    // Commission manager - allowed to withdraw commission
    bytes32 public constant COMMISSION_MGR_ROLE = keccak256("COMMISSION_MGR_ROLE");

    // Rates setter - allowed to set rates
    bytes32 public constant RATES_SETTER_ROLE = keccak256("RATES_SETTER_ROLE");

    // Deposit manager - allowed to give users funds from the free balance
    bytes32 public constant DEPOSIT_MGR_ROLE = keccak256("DEPOSIT_MGR_ROLE");

    // Treasurer - allowed to fund and withdraw free balance
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    // Client contracts - contracts which may call privileged methods
    bytes32 public constant CLIENT_CONTRACT_ROLE = keccak256("CLIENT_CONTRACT_ROLE");

    struct WithdrawalRequest {
        string destination;
        address payable transferTo;
        uint256 amount;
        uint32 coinIndex;
        uint256 withdrawalId;
        uint256 nonce;
    }

    struct SweepRequest {
        address sweepFrom;
        address user;
        uint32 coinIndex;
        bytes data;
        bytes signature;
    }

    struct AffiliatePair {
        address user;
        address affiliate;
    }

    struct AffiliateRate {
        address affiliate;
        uint256 cutBPS;
    }

    struct Reward {
        address recipient;
        uint256 amount;
        RewardType rewardType;
    }

    enum RewardType {
        CREDIT,
        AIRDROP,
        CONTEST
    }

    // ERC20 tokens we allow
    mapping(uint32 => IERC20WithMetaTx) private supportedTokens;

    // Values required to truncate values to our desired precision
    mapping(uint32 => uint256) private precisionScales;

    // Balances owned by users (key is encoded address + coinIndex)
    mapping(uint256 => uint256) private userBalance;

    // Balance not owned by users (key is coinIndex)
    mapping(uint32 => uint256) public freeBalance;

    // LFI tokens owed to users
    mapping(address => uint256) public owedLFI;

    // House pools for each coin we support
    mapping(uint32 => IHousePool) public housePools;

    // Nonces for withdraw to hosted wallet permission
    mapping(address => uint256) public withdrawalRequestNonces;

    // User => person who referred them
    mapping(address => address) public affiliates;

    // Affiliate => cut earned from profits (% * 100)
    mapping(address => uint256) public affiliatesCutBPS;

    // Commission balances, per coin
    mapping(uint32 => uint256) public lionGamingCommission;
    mapping(uint32 => uint256) public lionGamingPendingCommission;
    mapping(uint32 => uint256) public affiliatesPendingCommission;

    /// @custom:oz-renamed-from affiliateMonthlyBalance
    mapping(uint256 => uint256) private unused0;

    // Lion Gaming cut (% * 100)
    uint256 public lionGamingCutBPS;

    // The coin which represents LFI
    uint32 public lfiCoinIndex;

    // Flag to disable deposits
    bool public depositsEnabled;

    // Off-chain event tracking variables
    uint256 public lastEventNumber;
    uint256 public lastEventBlock;
    uint256 public creationBlock;

    // Platform fee
    uint256 public platformFeeBPS;

    /**
     * Sets up the contract.
     *
     * @param lfiCoinIndex_      Which coin index will be LFI.
     * @param nativeCoinDecimals Decimals for the native coin.
     */
    function initialize(
        uint32 lfiCoinIndex_,
        uint256 nativeCoinDecimals
    ) external initializer {
        _grantRole(ADMIN_ROLE, msg.sender);

        __EIP712_init("LunaFi", "1.0");

        creationBlock = block.number;

        depositsEnabled = true;
        lfiCoinIndex = lfiCoinIndex_;
        precisionScales[0] = uint256(10)**(18 - nativeCoinDecimals);
    }

    event BalanceIncreased(
        address indexed user,
        uint256 change,
        uint256 balance,
        uint32 coinIndex,
        string reason,
        uint256 indexed eventNumber,
        uint256 lastEventBlock
    );

    event BalanceDecreased(
        address indexed user,
        uint256 change,
        uint256 balance,
        uint32 coinIndex,
        string reason,
        uint256 withdrawn,
        uint256 indexed eventNumber,
        uint256 lastEventBlock
    );

    event BalanceSynced(
        address indexed user,
        uint256 spent,
        uint256 gained,
        uint256 balance,
        uint32 coinIndex,
        uint256 indexed eventNumber,
        uint256 lastEventBlock
    );

    event LFIOwed(
        address indexed user,
        uint256 change,
        uint256 balance,
        uint256 indexed eventNumber,
        uint256 lastEventBlock
    );

    event WithdrawalReceipt(
        address indexed user,
        uint256 indexed withdrawalId, // Not included in signed structure
        uint256 indexed eventNumber,
        uint256 lastEventBlock
    );

    event DepositReceipt(
        address indexed user,
        uint256 indexed depositId,
        uint256 indexed eventNumber,
        uint256 lastEventBlock
    );

    //-----------------------------------------------------------------------------
    // Modifiers
    //-----------------------------------------------------------------------------

    /**
     * Requires a valid coin. Throws an exception if the coin is not valid.
     *
     * @param coinIndex The coin to check.
     */
    modifier validateCoin(uint32 coinIndex) {
        require(
            coinIndex == 0 || address(supportedTokens[coinIndex]) != address(0),
            "Unsupported coin"
        );
        _;
    }

    /**
     * Requires a valid token (i.e. not the native coin). Throws an exception
     * if the token is invalid or the native coin.
     *
     * @param coinIndex The coin to check.
     */
    modifier validateToken(uint32 coinIndex) {
        require(
            coinIndex != 0 && address(supportedTokens[coinIndex]) != address(0),
            "Unsupported coin"
        );
        _;
    }

    /**
     * Requires deposits not to be disabled. Throws an exception if deposits are
     * disabled.
     */
    modifier whenDepositsEnabled() {
        require(depositsEnabled, "Deposits currently disabled");
        _;
    }

    //-----------------------------------------------------------------------------
    // Owner methods
    //-----------------------------------------------------------------------------

    /**
     * Enables or disables user deposits.
     *
     * @param enable New enabled state.
     */
    function enableDeposits(
        bool enable
    )
        external
        onlyRole(ADMIN_ROLE)
    {
        depositsEnabled = enable;
    }

    /**
     * Adds a coin to the list of coins we support.
     *
     * @param coinIndex Index of this coin; indices need not be sequential.
     * @param token     Address of an ERC20 token contract.
     * @param housePool Address of a house pool which will manage funds for this coin.
     * @param tokenDecimals Decimals defined on this token's contract.
     * @param decimals  Decimals to which we truncate values for this coin; must be <=
     *                  the token's decimals property.
     */
    function addCoin(
        uint32 coinIndex,
        IERC20WithMetaTx token,
        IHousePool housePool,
        uint256 tokenDecimals,
        uint256 decimals
    )
        external
        onlyRole(ADMIN_ROLE)
    {
        require(coinIndex != 0, "Can't assign coinIndex zero");
        require(coinIndex < 100, "Can't assign reserved coinIndex"); // >= 100 is for internal use
        require(address(supportedTokens[coinIndex]) == address(0), "coinIndex already assigned");
        supportedTokens[coinIndex] = token;
        precisionScales[coinIndex] = uint256(10)**(tokenDecimals - decimals);
        housePools[coinIndex] = housePool;
    }

    /**
     * Updates the house pool address for a token.
     *
     * @param coinIndex House pool currency.
     * @param housePool Address of a house pool which will manage funds for this coin.
     */
    function updateHousePool(
        uint32 coinIndex,
        IHousePool housePool
    )
        external
        onlyRole(ADMIN_ROLE)
    {
        require(address(supportedTokens[coinIndex]) != address(0), "coinIndex not defined");
        housePools[coinIndex] = housePool;
    }

    /**
     * Updates the decimals value for a token.
     *
     * @param coinIndex House pool currency.
     * @param tokenDecimals Decimals defined on this token's contract.
     * @param decimals  Decimals to which we truncate values for this coin; must be <=
     *                  the token's decimals property.
     */
    function updateTokenDecimals(
        uint32 coinIndex,
        uint256 tokenDecimals,
        uint256 decimals
    )
        external
        onlyRole(ADMIN_ROLE)
    {
        require(address(supportedTokens[coinIndex]) != address(0), "coinIndex not defined");
        precisionScales[coinIndex] = uint256(10)**(tokenDecimals - decimals);
    }

    /**
     * Sets the LionGaming commission
     *
     * @param lionCut New commission rate.
     */
    function setLionCommission(
        uint256 lionCut
    )
        external
        onlyRole(RATES_SETTER_ROLE)
    {
        lionGamingCutBPS = lionCut;
    }

    /**
     * Sets the platform fee.
     *
     * @param platformFee New platform fee.
     */
    function setPlatformFee(
        uint256 platformFee
    )
        external
        onlyRole(RATES_SETTER_ROLE)
    {
        platformFeeBPS = platformFee;
    }

    //-----------------------------------------------------------------------------
    // Treasurer methods
    //-----------------------------------------------------------------------------

    /**
     * Withdraws available commission. The current available commission will be
     * sent to the caller.
     *
     * @param coinIndex Currency.
     */
    function withdrawCommission(
        uint32 coinIndex
    )
        external
        onlyRole(COMMISSION_MGR_ROLE)
    {
        uint256 commission = lionGamingCommission[coinIndex];
        lionGamingCommission[coinIndex] = 0;
        makePayment(payable(msg.sender), commission, coinIndex);
    }

    /**
     * Withdraws available commission to the specified address.
     *
     * @param recipient Where to send funds.
     * @param coinIndex Currency.
     */
    function withdrawCommissionTo(
        address payable recipient,
        uint32 coinIndex
    )
        external
        onlyRole(COMMISSION_MGR_ROLE)
    {
        uint256 commission = lionGamingCommission[coinIndex];
        lionGamingCommission[coinIndex] = 0;
        makePayment(payable(recipient), commission, coinIndex);
    }

    //-----------------------------------------------------------------------------
    // Agent methods
    //-----------------------------------------------------------------------------

    /**
     * Makes a deposit on behalf of a user (assumes they've set the allowance
     * for us beforehand).
     *
     * @param coinIndex Currency.
     * @param amount    Amount.
     * @param user      The destination user.
     */
    function depositTokenForUser(
        uint32 coinIndex,
        uint256 amount,
        address user
    )
        external
        onlyRole(AGENT_ROLE)
    {
        _depositToken(coinIndex, amount, user, user);
    }

    /**
     * Sends a user's entire balance to their wallet.
     *
     * @param user      Recipient.
     * @param coinIndex Coin to evict.
     */
    function evictBalance(
        address payable user,
        uint32 coinIndex
    )
        external
        onlyRole(AGENT_ROLE)
        validateCoin(coinIndex)
    {
        uint256 bal = getBalanceId(user, coinIndex);

        uint256 amount = userBalance[bal];

        userBalance[bal] = 0;

        emit BalanceDecreased(
            user,
            amount,
            0,
            coinIndex,
            "EvictBalance",
            amount,
            ++lastEventNumber,
            updateLastEventBlock()
        );

        if (amount == 0)
            return;

        makePayment(user, amount, coinIndex);
    }

    /**
     * Sends funds from the user's contract balance to their wallet.
     *
     * @notice User must have sufficient funds to cover the withdrawal.
     *
     * @param user      Recipient.
     * @param amount    Amount to send.
     * @param coinIndex Coin.
     */
    function withdraw(
        address payable user,
        uint256 amount,
        uint32 coinIndex
    )
        external
        onlyRole(AGENT_ROLE)
        validateCoin(coinIndex)
    {
        uint256 bal = getBalanceId(user, coinIndex);

        require(amount <= userBalance[bal], "Insufficient balance");

        userBalance[bal] -= amount;

        emit BalanceDecreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "Withdrawal",
            amount,
            ++lastEventNumber,
            updateLastEventBlock()
        );

        makePayment(user, amount, coinIndex);
    }

    /**
     * Sends funds from the user's contract balance to a hosted wallet.
     *
     * @notice User must have sufficient funds to cover the withdrawal.
     * @notice To perform a null withdrawal (funds stay on contract), set transferTo to 0.
     * @notice For non-null withdrawals, destination must not be 0.
     *
     * @param user      Owner of the funds.
     * @param request   Request to withdraw.
     * @param signature Signature authorising this request.
     */
    function withdrawToHosted(
        address payable user,
        WithdrawalRequest calldata request,
        bytes calldata signature
    )
        external
        onlyRole(AGENT_ROLE) validateCoin(request.coinIndex)
    {
        uint256 bal = getBalanceId(user, request.coinIndex);

        requireIndirectWithdrawalPermission(user, request, signature);

        require(request.amount <= userBalance[bal], "Insufficient balance");

        userBalance[bal] -= request.amount;

        if (request.transferTo == address(0)) {
            // User will receive funds off-chain or on another chain
            // We will move their funds to the free balance
            // The destination address is optional in this case
            freeBalance[request.coinIndex] += request.amount;

            emit BalanceDecreased(
                user,
                request.amount,
                userBalance[bal],
                request.coinIndex,
                "NullSweep",
                request.amount,
                ++lastEventNumber,
                updateLastEventBlock()
            );

            emit WithdrawalReceipt(
                user,
                request.withdrawalId,
                ++lastEventNumber,
                updateLastEventBlock()
            );
        } else {
            // Funds will be sent out to the hosted wallet, for
            // forwarding to the destination address.
            require(bytes(request.destination).length != 0, "Invalid destination wallet");

            emit BalanceDecreased(
                user,
                request.amount,
                userBalance[bal],
                request.coinIndex,
                "SweepOut",
                request.amount,
                ++lastEventNumber,
                updateLastEventBlock()
            );

            emit WithdrawalReceipt(
                user,
                request.withdrawalId,
                ++lastEventNumber,
                updateLastEventBlock()
            );

            makePayment(request.transferTo, request.amount, request.coinIndex);
        }
    }

    /**
     * Assigns affiliate relationships and commission percentages.
     *
     * @notice once set, an affiliate may not be changed (but the rate may be)
     *
     * @param affiliatePairs affiliate <-> user pairings.
     * @param affiliateRates affiliate <-> rate pairings.
     */
    function assignAffiliates(
        AffiliatePair[] calldata affiliatePairs,
        AffiliateRate[] calldata affiliateRates
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
    {
        uint256 numRates = affiliateRates.length;
        uint256 numPairs = affiliatePairs.length;

        for (uint256 i = 0; i < numRates; i++) {
            affiliatesCutBPS[affiliateRates[i].affiliate] = affiliateRates[i].cutBPS;
        }

        for (uint256 i = 0; i < numPairs; i++) {
            address current = affiliates[affiliatePairs[i].user];

            if (current == affiliatePairs[i].affiliate)
                continue;

            require(current == address(0), "Can't change a user's affiliate");

            affiliates[affiliatePairs[i].user] = affiliatePairs[i].affiliate;
        }
    }

    /**
     * Sweeps tokens from hosted wallets into the present contract.
     *
     * @param requests Details of sweep operation with signature from
     *                 the wallet key (which we control).
     */
    function sweepHostedWallets(
        SweepRequest[] calldata requests
    )
        external
        onlyRole(AGENT_ROLE)
        nonReentrant
    {
        uint256 numRequests = requests.length;

        for (uint256 i = 0; i < numRequests; i++) {
            require(requests[i].coinIndex != 0); // "Can't sweep native token"
            require(supportedTokens[requests[i].coinIndex] != IERC20WithMetaTx(address(0))); // "Unknown coinIndex"

            IERC20WithMetaTx token = supportedTokens[requests[i].coinIndex];

            uint8 v;
            bytes32 r;
            bytes32 s;

            (v, r, s) = splitSignature(requests[i].signature);

            uint256 bal = getBalanceId(requests[i].user, requests[i].coinIndex);

            uint256 oldBalance = getContractBalance(requests[i].coinIndex);

            require(abi.decode(token.executeMetaTransaction(requests[i].sweepFrom, requests[i].data, r, s, v), (bool)));

            uint32 coinIndex = requests[i].coinIndex;
            {
                // Calculate what we were sent by the ERC20 contract
                uint256 newBalance = getContractBalance(requests[i].coinIndex);
                uint256 delta = newBalance - oldBalance;     // Expected to fail if -ve delta

                if (delta == 0)
                    continue;

                userBalance[bal] = userBalance[bal] + delta;

                emit BalanceIncreased(
                    requests[i].user,
                    delta,
                    userBalance[bal],
                    coinIndex,
                    "SweepIn",
                    ++lastEventNumber,
                    updateLastEventBlock()
                );
            }
        }
    }

    /**
     * Performs a meta deposit on behalf of a user.
     *
     * @notice will revert if the expected amount doesn't match.
     *
     * @param user      User making the deposit.
     * @param data      Meta deposit data.
     * @param signature Meta deposit signature.
     * @param amount    Exact amount user is expected to deposit.
     * @param coinIndex Coin the user is depositing.
     */
    function metaDeposit(
        address user,
        bytes calldata data,
        bytes calldata signature,
        uint256 amount,
        uint32 coinIndex
    )
        external
        onlyRole(AGENT_ROLE)
        validateToken(coinIndex)
        nonReentrant
    {
        IERC20WithMetaTx token = supportedTokens[coinIndex];

        uint256 oldBalance = getContractBalance(coinIndex);

        {
            uint8 v;
            bytes32 r;
            bytes32 s;

            (v, r, s) = splitSignature(signature);

            require(abi.decode(token.executeMetaTransaction(user, data, r, s, v), (bool)));
        }

        uint256 bal = getBalanceId(user, coinIndex);

        // Calculate what we were sent by the ERC20 contract
        uint256 newBalance = getContractBalance(coinIndex);
        uint256 delta = newBalance - oldBalance;     // Expected to fail if -ve delta

        require(delta == amount, "Incorrect number of tokens sent");

        userBalance[bal] += delta;

        emit BalanceIncreased(
            user,
            delta,
            userBalance[bal],
            coinIndex,
            "MetaDeposit",
            ++lastEventNumber,
            updateLastEventBlock()
        );
    }

    /**
     * Distributes LFI tokens owed to users (to be called after replenishing
     * the supply on the contract.)
     *
     * @notice the LFI index must have been set.
     *
     * @param users Array of users to which we need to give funds.
     */
    function distributeLFI(
        address[] calldata users
    )
        external
        onlyRole(AGENT_ROLE)
    {
        require(lfiCoinIndex != 0, "LFI coinIndex not defined");

        uint256 numUsers = users.length;

        for (uint256 i = 0; i < numUsers; i++) {
            uint256 bal = getBalanceId(users[i], lfiCoinIndex);
            freeBalance[lfiCoinIndex] -= owedLFI[users[i]];
            userBalance[bal] += owedLFI[users[i]];

            emit BalanceIncreased(
                users[i],
                owedLFI[users[i]],
                userBalance[bal],
                lfiCoinIndex,
                "OwedLFIReward",
                ++lastEventNumber,
                updateLastEventBlock()
            );

            owedLFI[users[i]] = 0;
        }
    }

    /**
     * Allocates funds to a user from the contract's free balance; this will
     * match a deposit made elsewhere (e.g. another blockchain).
     *
     * @param user      User.
     * @param coinIndex Currency.
     * @param amount    Amount.
     * @param depositId Reference for this deposit (for bookkeeping purposes).
     */
    function internalDeposit(
        address user,
        uint32 coinIndex,
        uint256 amount,
        uint256 depositId
    )
        external
        onlyRole(DEPOSIT_MGR_ROLE)
        validateCoin(coinIndex)
    {
        uint256 bal = getBalanceId(user, coinIndex);

        freeBalance[coinIndex] -= amount;
        userBalance[bal] += amount;

        emit BalanceIncreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "NullDeposit",
            ++lastEventNumber,
            updateLastEventBlock()
        );

        emit DepositReceipt(
            user,
            depositId,
            ++lastEventNumber,
            updateLastEventBlock()
        );
    }

    /**
     * Adds to the contract's free balance.
     */
    function fundContract() external payable onlyRole(TREASURER_ROLE) {
        freeBalance[0] += msg.value;
    }

    /**
     * Funds the contract's free balance.
     *
     * @param coinIndex Currency.
     * @param amount    Amount.
     */
    function fundContractTokens(
        uint32 coinIndex,
        uint256 amount
    )
        external
        onlyRole(TREASURER_ROLE)
        validateToken(coinIndex)
    {
        IERC20WithMetaTx token = supportedTokens[coinIndex];
        require(token.allowance(msg.sender, address(this)) >= amount, "Transfer not approved");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        freeBalance[coinIndex] += amount;
    }

    /**
     * Withdraws funds from the contract's free balance.
     *
     * @param coinIndex Currency.
     * @param amount    Amount.
     */
    function withdrawContractFunds(
        uint32 coinIndex,
        uint256 amount
    )
        external
        onlyRole(TREASURER_ROLE)
        validateCoin(coinIndex)
    {
        freeBalance[coinIndex] -= amount;
        makePayment(payable(msg.sender), amount, coinIndex);
    }

    /**
     * Withdraws funds from the contract's free balance to a specified address.
     *
     * @param recipient Where to send funds.
     * @param coinIndex Currency.
     * @param amount    Amount.
     */
    function withdrawContractFundsTo(
        address payable recipient,
        uint32 coinIndex,
        uint256 amount
    )
        external
        onlyRole(TREASURER_ROLE)
        validateCoin(coinIndex)
    {
        require(recipient != address(0), "Invalid recipient");
        freeBalance[coinIndex] -= amount;
        makePayment(recipient, amount, coinIndex);
    }

    /**
     * Gives LFI to a list of users.
     *
     * @notice There must be sufficient free balance for the operation.
     *         Owed LFI will not be issued.
     *
     * @param rewards Give users LFI rewards.
     */
    function rewardUsers(
        Reward[] calldata rewards
    )
        external
        onlyRole(AGENT_ROLE)
    {
        require(lfiCoinIndex != 0);

        uint256 available = truncate(freeBalance[lfiCoinIndex], lfiCoinIndex);
        uint256 numRecipients = rewards.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            uint256 bal = getBalanceId(rewards[i].recipient, lfiCoinIndex);
            uint256 amount = truncate(rewards[i].amount, lfiCoinIndex);

            require(amount <= available, "Insufficient balance");

            userBalance[bal] += amount;
            freeBalance[lfiCoinIndex] -= amount;
            available -= amount;

            string memory typeString;

            if (rewards[i].rewardType == RewardType.AIRDROP)
                typeString = "LFIAirdrop";
            else if (rewards[i].rewardType == RewardType.CONTEST)
                 typeString = "LFIContest";
            else
                typeString = "LFICredit";

            emit BalanceIncreased(
                rewards[i].recipient,
                amount,
                userBalance[bal],
                lfiCoinIndex,
                typeString,
                ++lastEventNumber,
                updateLastEventBlock()
            );
        }
    }

    //-----------------------------------------------------------------------------
    // Client contract methods
    //-----------------------------------------------------------------------------

    function transferFundsToPool(
        uint256 amount,
        uint32 coinIndex
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
    {
        require(housePools[coinIndex] != IHousePool(address(0)), "House pool not defined");
        freeBalance[coinIndex] -= amount;
        makePayment(payable(address(housePools[coinIndex])), amount, coinIndex);
    }

    /**
     * Applies a delta to a user's balance; this consists of an amount spent by
     * the user and an amount gained. The amount added to the balance is
     * gained - spent.
     *
     * @param user User whose balance we will manipulate.
     * @param spent Amount the user has spent.
     * @param gained Gross amount the user has gained.
     * @param margin Margin (BPS).
     * @param coinIndex Which coin to manipulate.
     *
     * @return netSpent spent minus commission and affiliate earnings.
     * @return affiliateCut Amount allocated to user's affiliate.
     */
    function applyBalanceDelta(
        address user,
        uint256 spent,
        uint256 gained,
        uint256 margin,
        uint256 miningRate,
        uint32 coinIndex
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        validateCoin(coinIndex)
        returns (uint256, uint256)
    {
        uint256 affiliateCut;
        uint256 netSpent = spent;

        affiliateCut = calculateAffiliateCut(user, spent, margin, miningRate, coinIndex);

        uint256 bal = getBalanceId(user, coinIndex);

        require(spent <= userBalance[bal] + gained, "Insufficient balance");

        userBalance[bal] += gained;
        userBalance[bal] -= spent;

        emit BalanceSynced(
            user,
            spent,
            gained,
            userBalance[bal],
            coinIndex,
            ++lastEventNumber,
            updateLastEventBlock()
        );

        if (affiliateCut > 0) {
            address affiliate = affiliates[user];

            uint256 affBal = getBalanceId(affiliate, coinIndex);

            userBalance[affBal] += affiliateCut;

            emit BalanceIncreased(
                affiliate,
                affiliateCut,
                userBalance[affBal],
                coinIndex,
                "AffiliatePayout",
                ++lastEventNumber,
                updateLastEventBlock()
            );

            netSpent -= affiliateCut;
        }

        require(gained <= freeBalance[coinIndex] + netSpent, "Insufficient balance");

        freeBalance[coinIndex] += netSpent;
        freeBalance[coinIndex] -= gained;

        return (netSpent, affiliateCut);
    }

    /**
     * Reduces a user's balance and takes part of the funds as (pending)
     * commission for Lion Gaming and the user's affiliate (if any)
     *
     * @notice The user must have sufficient balance.
     *
     * @param user       User.
     * @param amount     Amount to deduct.
     * @param margin     Margin (BPS) to determine commission.
     * @param miningRate User's mining rate.
     * @param coinIndex  Currency.
     *
     * @return netAmount     Net amount without commission.
     * @return affiliateCut  Amount of bet reserved for affiliate.
     * @return lionGamingCut Amount of bet reserved for Lion Gaming.
     */
    function reduceBalanceAndTakeCommission(
        address user,
        uint256 amount,
        uint256 margin,
        uint256 miningRate,
        uint32 coinIndex
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        validateCoin(coinIndex)
        returns (uint256, uint256, uint256)
    {
        uint256 netAmount = amount;
        uint256 affiliateCut;

        // Set aside funds for the affiliate, if any
        if (affiliates[user] != address(0)) {
            affiliateCut = calculateAffiliateCut(user, amount, margin, miningRate, coinIndex);
            if (affiliateCut > 0) {
                netAmount -= affiliateCut;
                affiliatesPendingCommission[coinIndex] += affiliateCut;
            }
        }

        // Lion Gaming revenue share
        uint256 lionGamingCut = amount * lionGamingCutBPS * margin / (100**4);
        lionGamingCut = truncate(lionGamingCut, coinIndex);
        lionGamingPendingCommission[coinIndex] += lionGamingCut;
        netAmount -= lionGamingCut;

        uint256 bal = getBalanceId(user, coinIndex);

        require(amount <= userBalance[bal], "Insufficient balance");

        userBalance[bal] -= amount;
        freeBalance[coinIndex] += netAmount;

        emit BalanceDecreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "SpendFunds",
            0,
            ++lastEventNumber,
            updateLastEventBlock()
        );

        return (netAmount, affiliateCut, lionGamingCut);
    }

    /**
     * Allocates funds (bet winnings) to a user, and reverts reserved commissions.
     *
     * @param user          User.
     * @param amount        Amount to fund (gross amount, including commissions).
     * @param affiliateCut  Original affiliate cut
     * @param lionGamingCut Lion gaming cut
     */
    function increaseBalanceAndReturnCommission(
        address user,
        uint256 amount,
        uint256 affiliateCut,
        uint256 lionGamingCut,
        uint32 coinIndex
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        validateCoin(coinIndex)
    {
        uint256 bal = getBalanceId(user, coinIndex);

        // Takes back affiliate cut
        affiliatesPendingCommission[coinIndex] -= affiliateCut;

        // ...and Lion Gaming commission
        lionGamingPendingCommission[coinIndex] -= lionGamingCut;

        // Gives the user the whole payout
        userBalance[bal] += amount;

        // Takes the net amount (after cuts) from the free balance
        freeBalance[coinIndex] -= (amount - (affiliateCut + lionGamingCut));

        emit BalanceIncreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "Payout",
            ++lastEventNumber,
            updateLastEventBlock()
        );
    }

    /**
     * Allocates funds (bet winnings) to a user, and commits (frees) reserved commissions.
     *
     * @notice Funds come from the free balance, so there must be sufficient funds.
     *
     * @param user   User.
     * @param amount Amount to fund.
     */
    function increaseBalance(
        address user,
        uint256 amount,
        uint32 coinIndex
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        validateCoin(coinIndex)
    {
        uint256 bal = getBalanceId(user, coinIndex);

        // Gives user their winnings
        userBalance[bal] += amount;

        // Takes the net amount from the free balance
        freeBalance[coinIndex] -= amount;

        emit BalanceIncreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "Payout",
            ++lastEventNumber,
            updateLastEventBlock()
        );
    }

    /**
     * Commits pending commissions to the monthly silos (in response to
     * a losing bet.
     *
     * @param user          User who placed the bet.
     * @param affiliateCut  Affiliate cut from the bet.
     * @param lionGamingCut LionGaming cut from the bet.
     * @param coinIndex     Currency.
     */
    function commitCommission(
        address user,
        uint256 affiliateCut,
        uint256 lionGamingCut,
        uint32 coinIndex
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        validateCoin(coinIndex)
    {
        lionGamingPendingCommission[coinIndex] -= lionGamingCut;
        lionGamingCommission[coinIndex] += lionGamingCut;

        if (affiliateCut > 0) {
            address affiliate = affiliates[user];
            affiliatesPendingCommission[coinIndex] -= affiliateCut;

            uint256 bal = getBalanceId(affiliate, coinIndex);

            userBalance[bal] += affiliateCut;

            emit BalanceIncreased(
                affiliate,
                affiliateCut,
                userBalance[bal],
                coinIndex,
                "AffiliatePayout",
                ++lastEventNumber,
                updateLastEventBlock()
            );
        }
    }

    /**
     * Allocates LFI to the user to compensate for the house edge (margin).
     *
     * @param user   User.
     * @param amount Amount wagered, in LFI.
     * @param rate   Discount rate (BPS) to apply.
     * @param margin Margin (BPS) for bet.
     * @return amount Amount of LFI given.
     */
    function giveLFIRewards(
        address user,
        uint256 amount,
        uint256 rate,
        uint256 margin
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        returns (uint256)
    {
        return giveLFI(user, (amount * rate * margin) / (100**4));
    }

    /**
     * Informs the contract of change of a possible balance change -- i.e.
     * a contract sent us tokens and we need to reconcile our records.
     *
     * @param coinIndex  Currency of expected balance change.
     * @param oldBalance Balance before the event that caused a change.
     *
     * @return delta     Change in balance observed compared to records.
     */
    function syncBalance(
        uint32 coinIndex,
        uint256 oldBalance
    )
        external
        onlyRole(CLIENT_CONTRACT_ROLE)
        returns (uint256)
    {
        uint256 newBalance = getContractBalance(coinIndex);
        uint256 delta = newBalance - oldBalance;     // Expected to fail if -ve delta
        freeBalance[coinIndex] += delta;
        return delta;
    }

    //-----------------------------------------------------------------------------
    // World-accessible methods
    //-----------------------------------------------------------------------------

    /**
     * Retrieves a user's current balance.
     *
     * @param user      User.
     * @param coinIndex Currency.
     *
     * @return balance  User's available balance.
     */
    function getBalance(
        address user,
        uint32 coinIndex
    )
        external
        view
        validateCoin(coinIndex)
        returns(uint256)
    {
        uint256 bal = getBalanceId(user, coinIndex);
        return userBalance[bal];
    }

    /**
     * Determines the balance (native token or other coins)
     * currently held by the contract, whether assigned to
     * users, the free balance, or otherwise.
     *
     * @param coinIndex Currency we wish to query.
     *
     * @return balance  Contract balance.
     */
    function getContractBalance(
        uint32 coinIndex
    )
        public
        view
        returns (uint256)
    {
        if (coinIndex == 0)
            return address(this).balance;
        else
            return supportedTokens[coinIndex].balanceOf(address(this));
    }

    /**
     * Allows a user to deposit coins into their contract balance.
     */
    function deposit() external payable {
        _deposit(msg.sender, msg.value);
    }

    /**
     * Allows us to forward funds from a hosted wallet to a user.
     * Will be called from an external wallet under our control.
     *
     * @param user The destination user.
     */
    function forwardDepositToUser(address user) external payable {
        _deposit(user, msg.value);
    }

    /**
     * Allows a user to deposit tokens into their contract balance.
     *
     * @param coinIndex Currency.
     * @param amount    Amount.
     */
    function depositToken(uint32 coinIndex, uint256 amount) external {
        _depositToken(coinIndex, amount, msg.sender, msg.sender);
    }

    /**
     * Allows us to forward tokens from a hosted wallet to a user.
     * Will be called from an external wallet under our control.
     *
     * @param coinIndex Currency.
     * @param amount    Amount.
     * @param user      The destination user.
     */
    function forwardTokenToUser(
        uint32 coinIndex,
        uint256 amount,
        address user
    )
        external
    {
        _depositToken(coinIndex, amount, user, msg.sender);
    }

    /**
     * Returns the user's balance for a given coin.
     *
     * @param user      The destination user.
     * @param coinIndex Currency.
     * @return balance  User's balance.
     */
    function getUserBalance(
        address user,
        uint32 coinIndex
    )
        external
        view
        returns(uint256)
    {
        uint256 bal = getBalanceId(user, coinIndex);
        return userBalance[bal];
    }

    /**
     * Truncates (rounds towards zero) the given value based on the coin.
     *
     * @param amount    Number to manipulate.
     * @param coinIndex Currency.
     *
     * @return truncated Amount after truncation.
     */
    function truncate(
        uint256 amount,
        uint32 coinIndex
    )
        public
        view
        validateToken(coinIndex)
        returns (uint256)
    {
        uint256 scale = precisionScales[coinIndex];

        if (scale == 1)
            return amount;

        return (amount / scale) * scale;
    }

    //-----------------------------------------------------------------------------
    // Internal/private methods
    //-----------------------------------------------------------------------------

    /**
     * Allows a user to deposit coins into their contract balance. Must
     * be accompanied by a transfer of native tokens into the contract.
     *
     * @param user   Recipient of funds.
     * @param amount Amount being sent.
     */
    function _deposit(
        address user,
        uint256 amount
    )
        internal
        whenDepositsEnabled
    {
        uint32 coinIndex = 0; // Depositing the native token

        uint256 bal = getBalanceId(user, coinIndex);

        userBalance[bal] += amount;

        emit BalanceIncreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "UserDeposit",
            ++lastEventNumber,
            updateLastEventBlock()
        );
    }

    /**
     * Allows a user to deposit supported ERC20 tokens into their contract balance.
     *
     * @param coinIndex Currency.
     * @param amount    Amount.
     * @param user      Receipient.
     * @param payer     Who will supply the funds.
     */
    function _depositToken(uint32 coinIndex,
        uint256 amount,
        address user,
        address payer
    )
        internal
        whenDepositsEnabled
        validateToken(coinIndex)
    {
        uint256 bal = getBalanceId(user, coinIndex);

        userBalance[bal] += amount;

        IERC20WithMetaTx token = IERC20WithMetaTx(supportedTokens[coinIndex]);
        require(token.allowance(payer, address(this)) >= amount, "Transfer not approved");
        require(token.transferFrom(payer, address(this), amount), "Transfer failed");

        emit BalanceIncreased(
            user,
            amount,
            userBalance[bal],
            coinIndex,
            "UserDeposit",
            ++lastEventNumber,
            updateLastEventBlock()
        );
    }

    /**
     * Validates user's permission to withdraw to an external wallet. Aborts if
     * the signature is not valid.
     */
    function requireIndirectWithdrawalPermission(
        address user,
        WithdrawalRequest calldata request,
        bytes calldata signature
    )
        private
    {
        require(request.nonce >= withdrawalRequestNonces[user], "Invalid nonce");

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("WithdrawalRequest(string destination,address transferTo,uint256 amount,uint32 coinIndex,uint256 nonce)"),
            keccak256(bytes(request.destination)),
            request.transferTo,
            request.amount,
            request.coinIndex,
            request.nonce
        )));

        address signer = ECDSAUpgradeable.recover(digest, signature);

        require(user == signer, "Invalid signature");

        withdrawalRequestNonces[user] = request.nonce + 1;
    }

    /**
     * Makes a payment (native coin or tokens) to the given wallet. Aborts on
     * error.
     *
     * @param recipient Recipient.
     * @param amount    Amount to send.
     * @param coinIndex Coin.
     */
    function makePayment(
        address payable recipient,
        uint256 amount,
        uint32 coinIndex
    )
        private
    {
        if (coinIndex == 0) {
            require(recipient.send(amount));
        } else {
            IERC20WithMetaTx token = supportedTokens[coinIndex];
            require(token.transfer(recipient, amount), "Transfer failed");
        }
    }

    /**
     * Gives the user some LFI: if there are insufficient free funds on the
     * contract, an IOU is issued.
     *
     * @param user   User to receive the LFI allocation.
     * @param amount How much to give the user.
     * @return amount Amount of LFI given to user.
     */
    function giveLFI(
        address user,
        uint256 amount
    )
        private
        returns (uint256)
    {
        require(lfiCoinIndex != 0, "LFI coinIndex not defined");

        uint256 bal = getBalanceId(user, lfiCoinIndex);
        uint256 available = truncate(freeBalance[lfiCoinIndex], lfiCoinIndex);

        amount = truncate(amount, lfiCoinIndex);

        uint256 owed;
        uint256 given;

        if (available >= amount) {
            owed = 0;
            given = amount;
        } else {
            owed = amount - available;
            given = available;
        }

        if (given > 0) {
            userBalance[bal] += given;
            freeBalance[lfiCoinIndex] -= given;

            emit BalanceIncreased(
                user,
                given,
                userBalance[bal],
                lfiCoinIndex,
                "LFIReward",
                ++lastEventNumber,
                updateLastEventBlock()
            );
        }

        if (owed > 0) {
            owedLFI[user] += owed;

            emit LFIOwed(
                user,
                owed,
                owedLFI[user],
                ++lastEventNumber,
                updateLastEventBlock()
            );
        }

        return amount;
    }

    /**
     * Calculates the amount due to an affiliate for a given wager.
     *
     * @param user       User whose affiliate we will credit.
     * @param spent      Amount of the bet.
     * @param margin     Margin.
     * @param miningRate Mining rate.
     * @param coinIndex  Currency.
     *
     * @return affiliateCut - Affiliate cut from wager.
     */
    function calculateAffiliateCut(
        address user,
        uint256 spent,
        uint256 margin,
        uint256 miningRate,
        uint32 coinIndex
    )
        internal
        view
        returns (uint256)
    {
        address affiliate = affiliates[user];

        if (affiliate == address(0))
            return 0;

        uint256 affiliateCut = spent * margin * affiliatesCutBPS[affiliate];
        affiliateCut *= (100**2 - miningRate);
        affiliateCut /= (100**2 + platformFeeBPS) * (100**4);
        affiliateCut = truncate(affiliateCut, coinIndex);

        return affiliateCut;
    }

    /**
     * Encodes a user and coin into a balance record id, which is a key in
     * the balances table.
     *
     * @param user      User.
     * @param coinIndex Coin.
     *
     * @return balanceId Balance id
     */
    function getBalanceId(
        address user,
        uint32 coinIndex
    )
        private
        pure
        returns (uint256)
    {
        // Addresses are 160 bits
        return (uint256(uint160(user)) << (256-160)) | uint128(coinIndex);
    }

    /**
     * Gets the block number of the last emitted event and
     * updates it (expecting a new event to be emitted)
     *
     * This is for tracking purposes so we can find lost events.
     *
     * @return blockNo The previous last block, before the update.
     */
    function updateLastEventBlock() internal returns (uint256) {
        uint256 blockNo = lastEventBlock;
        lastEventBlock = block.number;
        return blockNo;
    }

    /**
     * Splits signature into components.
     *
     * @param signature Signature to split.
     *
     * @return v First (v) component.
     * @return r Second (r) component.
     * @return s Third (s) component.
     */
    function splitSignature(
        bytes memory signature
    )
        private
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }
}