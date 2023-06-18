// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum Workflow {
    Preparatory,
    Presale,
    SaleHold,
    SaleOpen
}

uint256 constant PRICE_PACK_LEVEL1_IN_USD = 50e18;
uint256 constant PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB = 200e18;
uint256 constant OVERRLAP_TIME_ACTIVITY = 3 days;
uint256 constant PACK_ACTIVITY_PERIOD = 30 days;
uint256 constant PURCHASE_TIME_LIMIT_PERIOD = 30 days;
uint256 constant SHARE_OF_MARKETING = 80e16;
uint256 constant SHARE_OF_REWARDS = 5e16;
uint256 constant SHARE_OF_OTHER = 1e16;
uint256 constant SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE = 4e16;
uint256 constant SHARE_OF_TEAM = 2e16;
uint256 constant SHARE_OF_LIQUIDITY_LISTING = 8e16;
uint256 constant LEVELS_COUNT = 9;
uint256 constant HMFS_COUNT = 8;
uint256 constant TRANSITION_PHASE_PERIOD = 30 days;
uint256 constant ACTIVATION_COST_RATIO_TO_RENEWAL = 5e18;
uint256 constant COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL = 2e18;
uint256 constant COEFF_DECREASE_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_MB = 6e16; //0.06
uint256 constant MB_COUNT = 10;
uint256 constant COEFF_FIRST_MB = 127e16; //1.27
uint256 constant START_COEFF_DECREASE_MICROBLOCK = 124e16;
uint256 constant MARKETING_REFERRALS_TREE_ARITY = 2;
uint256 constant ROOT_ID = 1;
uint256 constant SHARE_ROYLTY_GIFT_POOL_FROM_BUY_MFS = 15e16;
uint256 constant RATE_SFCR2_TO_ENERGY = 2e18;
uint256 constant RATE_SFCR_TO_ENERGY = 1e18;
uint256 constant MINIMUM_REQUEST_USD = 50e18;
uint256 constant REFERRAL_TREE_STEP = 15;
uint256 constant MARKETING_TREE_STEP = 10;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Constants.sol";
import "./interfaces/ICoreContract.sol";
import "./interfaces/ICoins.sol";
import "./interfaces/IMetaCore.sol";
import "./interfaces/IMetaPayment.sol";
import "./libraries/FixedPointMath.sol";
import "./Governed.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

bytes32 constant META_FORCE_CONTRACT_ROLE = 0x50cf39c8fa39275243850e894fcd4b72000d4f0b08c3de0e36d7f1d1718942da;

contract Core is Initializable, Proxied, Governed, AccessControl, ReentrancyGuard, ICoreContract {
    using EnumerableSet for EnumerableSet.UintSet;
    using FixedPointMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMFS;

    uint256 public totalEmissionMFS;
    uint256[] public rewardsDirectReferrers;
    uint256[] public rewardsMarketingReferrers;
    uint256 public override getDateStartSaleOpen;
    uint256 public override getEnergyConversionFactor;

    Workflow public override getWorkflowStage;
    uint256 public override bigBlockSize;
    uint256 public override meanSmallBlock;
    uint256 public override nowNumberSmallBlock;
    uint256 public override nowNumberBigBlock;
    uint256 public override endBigBlock;
    uint256 public override endSmallBlock;
    uint256 public override nowCoeffDecreaseMicroBlock;
    uint256 public override meanDecreaseMicroBlock;
    uint256 public override nowPriceFirstPackInMFS;
    uint256 public override priceMFSInUSD;

    IRegistryContract internal registry;
    mapping(uint256 => User) internal users;

    modifier onlyMetaForceContractRole() {
        if (!hasRole(META_FORCE_CONTRACT_ROLE, msg.sender)) {
            revert MetaForceSpaceCoreSenderIsNotMetaContract();
        }
        _;
    }

    constructor() {}

    function nextWorkflowStage() external override onlyGovernor {
        Workflow currentWorkflow = getWorkflowStage;
        if (currentWorkflow == Workflow.SaleOpen) {
            revert MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
        }
        currentWorkflow = Workflow(uint8(currentWorkflow) + 1);
        getWorkflowStage = currentWorkflow;
        if (currentWorkflow == Workflow.SaleOpen) {
            getDateStartSaleOpen = block.timestamp;
            IMetaPayment(IMetaCore(registry.getMetaCore()).getPaymentChannelAddress()).setFreezeStatus(
                registry.getMFS(),
                false
            );
        }
        emit WorkflowStageMove(currentWorkflow);
    }

    function setMarketingReferrer(uint256 user, uint256 marketingReferrer) external override onlyMetaForceContractRole {
        _setMarketingReferrer(user, marketingReferrer);
    }

    function setTypeReward(TypeReward typeReward) external override {
        uint256 userId = getUserId(msg.sender);
        users[userId].rewardType = typeReward;
    }

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external override onlyGovernor {
        getEnergyConversionFactor = _energyConversionFactor;
    }

    function increaseTimestampEndPack(
        uint256 userId,
        uint256 level,
        uint256 amount
    ) external override onlyMetaForceContractRole {
        users[userId].packs[level] = users[userId].packs[level] + amount;
        emit TimestampEndPackSet(userId, level, users[userId].packs[level]);
    }

    function setTimestampEndPack(
        uint256 userId,
        uint256 level,
        uint256 timestamp
    ) external override onlyMetaForceContractRole {
        users[userId].packs[level] = timestamp;
        emit TimestampEndPackSet(userId, level, timestamp);
    }

    function setNowPriceFirstPackInMFS(uint256 _price) external {
        /*if (getWorkflowStage != Workflow.SaleOpen) {
            revert MetaForceSpaceCoreWorkflowNotSaleOpen();
        }*/
        nowPriceFirstPackInMFS = _price;
    }

    function increaseTotalEmission(uint256 amount) external override onlyMetaForceContractRole {
        totalEmissionMFS = totalEmissionMFS + amount;
        if (totalEmissionMFS > endSmallBlock) {
            nextSmallBlock();
        }
    }

    function burnMFSPool() external override onlyGovernor {
        IRegistryContract tempRegistry = registry;
        address metaPool = tempRegistry.getMetaPool();
        IMFS mfs = IMFS(tempRegistry.getMFS());
        mfs.burn(metaPool, mfs.balanceOf(metaPool));
        emit PoolMFSBurned();
    }

    function giveMFSFromPool(uint256 userId, uint256 amount) external override onlyMetaForceContractRole {
        IRegistryContract tempRegistry = registry;
        address metaPool = tempRegistry.getMetaPool();
        IMFS mfs = IMFS(tempRegistry.getMFS());
        IMetaPayment payment = IMetaPayment(IMetaCore(tempRegistry.getMetaCore()).getPaymentChannelAddress());
        mfs.safeTransferFrom(metaPool, address(payment), amount);
        payment.increaseBalance(address(mfs), userId, amount);
    }

    function directGiveMFSFromPool(address to, uint256 amount) external override onlyMetaForceContractRole {
        IRegistryContract tempRegistry = registry;
        address metaPool = tempRegistry.getMetaPool();
        IMFS mfs = IMFS(tempRegistry.getMFS());
        mfs.safeTransferFrom(metaPool, to, amount);
    }

    function giveStableFromPool(uint256 userId, uint256 amount) external override onlyMetaForceContractRole {
        IRegistryContract tempRegistry = registry;
        address metaPool = tempRegistry.getMetaPool();
        IERC20 stableCoin = IERC20(tempRegistry.getStableCoin());
        IMetaPayment payment = IMetaPayment(IMetaCore(tempRegistry.getMetaCore()).getPaymentChannelAddress());
        stableCoin.safeTransferFrom(metaPool, address(payment), amount);
        payment.increaseBalance(address(stableCoin), userId, amount);
    }

    function replaceUserInMarketingTree(uint256 from, uint256 to) external override onlyMetaForceContractRole {
        if (isUserActive(from)) {
            revert MetaForceSpaceCoreActiveUser();
        }
        uint256 marketingReferrer = users[from].marketingReferrer;
        if (!users[marketingReferrer].marketingReferrals.remove(from)) {
            revert MetaForceSpaceCoreMarketingReferralRemovalFailed();
        }
        _setMarketingReferrer(to, marketingReferrer);
        uint256 length = users[from].marketingReferrals.length();
        for (uint256 i = 0; i < length; ) {
            _setMarketingReferrer(users[from].marketingReferrals.at(0), to);
            unchecked {
                ++i;
            }
        }
        users[from].marketingReferrer = 0;
        emit MarketingReferrerChanged(from, 0);
    }

    function setRewardsDirectReferrers(uint256[] calldata _rewardsReferrers) external override onlyGovernor {
        setRewardsReferrers(_rewardsReferrers, rewardsMarketingReferrers);
    }

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingReferrers)
        external
        override
        onlyGovernor
    {
        setRewardsReferrers(rewardsDirectReferrers, _rewardsMarketingReferrers);
    }

    function setupTokensInMetapayment() external override nonReentrant {
        IMFS mfsToken = IMFS(registry.getMFS());
        IEnergy energyToken = IEnergy(registry.getEnergyCoin());
        if (mfsToken.emissionCommitted()) {
            revert MetaForceSpaceCoreEmissionCommitted();
        }
        IMetaPayment metaPayment = IMetaPayment(IMetaCore(registry.getMetaCore()).getPaymentChannelAddress());
        metaPayment.setFreezeStatus(address(mfsToken), true);
        metaPayment.setNontransferableStatus(address(energyToken), true);
        uint256 cachedCap = mfsToken.cap();
        uint256 tempCap = cachedCap;

        uint256 sMarketing = cachedCap.mul(SHARE_OF_MARKETING);
        mfsToken.mint(registry.getMetaPool(), sMarketing);
        tempCap -= sMarketing;

        uint256 sRewards = cachedCap.mul(SHARE_OF_REWARDS);
        mfsToken.mint(registry.getRewardsFund(), sRewards);
        tempCap -= sRewards;

        uint256 sOther = cachedCap.mul(SHARE_OF_OTHER);
        mfsToken.mint(registry.getOtherPool(), sOther);
        tempCap -= sOther;

        uint256 sMeta = cachedCap.mul(SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE);
        mfsToken.mint(registry.getMetaDevelopmentAndIncentiveFund(), sMeta);
        tempCap -= sMeta;

        uint256 sTeam = cachedCap.mul(SHARE_OF_TEAM);
        mfsToken.mint(registry.getTeamFund(), sTeam);
        tempCap -= sTeam;

        mfsToken.mint(registry.getLiquidityListingFund(), tempCap);
        mfsToken.setEmissionCommitted(true);
    }

    function getRewardsDirectReferrers() external view override returns (uint256[] memory) {
        return rewardsDirectReferrers;
    }

    function getRewardsMarketingReferrers() external view override returns (uint256[] memory) {
        return rewardsMarketingReferrers;
    }

    function getTypeReward(uint256 userId) external view override returns (TypeReward) {
        return users[userId].rewardType;
    }

    function getMarketingReferrals(uint256 userId) external view override returns (uint256[] memory) {
        return users[userId].marketingReferrals.values();
    }

    function getRegistrationDate(uint256 userId) external view override returns (uint256) {
        return IMetaCore(registry.getMetaCore()).getRegistrationDate(userId);
    }

    function getLevelForNFT(uint256 _userId) external view override returns (uint256) {
        return getUserLevel(_userId);
    }

    function calcMFSAmountForUSD(uint256 amountUSD) external view returns (uint256 amount) {
        amount = amountUSD.div(priceMFSInUSD);
        if (totalEmissionMFS + amount > endSmallBlock) {
            uint256 amountInOldPrice = endSmallBlock - totalEmissionMFS;
            uint256 balance = amountUSD - amountInOldPrice.mul(priceMFSInUSD);
            uint256 amountInNewPrice = balance.div(calculateNextMFSPrice());
            amount = amountInOldPrice + amountInNewPrice;
        }
    }

    function calcUSDAmountForMFS(uint256 amountMFS) external view returns (uint256 amountUSD) {
        if (totalEmissionMFS + amountMFS > endSmallBlock) {
            uint256 amountBefore = endSmallBlock - totalEmissionMFS;
            uint256 amountAfter = totalEmissionMFS + amountMFS - endSmallBlock;

            uint256 amountInOldPrice = priceMFSInUSD.mul(amountBefore);
            uint256 amountInNewPrice = amountAfter.mul(calculateNextMFSPrice());

            amountUSD = amountInOldPrice + amountInNewPrice;
        } else {
            amountUSD = priceMFSInUSD.mul(amountMFS);
        }
    }

    function setRewardsReferrers(uint256[] memory _rewardsDirectReferrers, uint256[] memory _rewardsMarketingReferrers)
        public
        override
        onlyGovernor
    {
        uint256 count;
        for (uint256 i = 0; i < _rewardsDirectReferrers.length; ) {
            count += _rewardsDirectReferrers[i];
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < _rewardsMarketingReferrers.length; ) {
            count += _rewardsMarketingReferrers[i];
            unchecked {
                ++i;
            }
        }
        if (count != 100e16) {
            revert MetaForceSpaceCoreSumRewardsMustBeHundred();
        }
        if (
            keccak256(abi.encodePacked(_rewardsDirectReferrers)) ==
            keccak256(abi.encodePacked(rewardsDirectReferrers)) &&
            keccak256(abi.encodePacked(_rewardsMarketingReferrers)) ==
            keccak256(abi.encodePacked(rewardsMarketingReferrers))
        ) {
            revert MetaForceSpaceCoreRewardsIsNotChange();
        }
        if (
            keccak256(abi.encodePacked(_rewardsDirectReferrers)) == keccak256(abi.encodePacked(rewardsDirectReferrers))
        ) {
            rewardsMarketingReferrers = _rewardsMarketingReferrers;
        } else if (
            keccak256(abi.encodePacked(_rewardsMarketingReferrers)) ==
            keccak256(abi.encodePacked(rewardsMarketingReferrers))
        ) {
            rewardsDirectReferrers = _rewardsDirectReferrers;
        } else {
            rewardsDirectReferrers = _rewardsDirectReferrers;
            rewardsMarketingReferrers = _rewardsMarketingReferrers;
        }
        emit RewardsReferrerSetted();
    }

    function clearInfo(uint256 userId) public override onlyMetaForceContractRole {
        delete users[userId];
    }

    function initialize(IRegistryContract _registry) public proxied initializer {
        setGovernor(msg.sender);

        registry = _registry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(META_FORCE_CONTRACT_ROLE, _registry.getMetaForceContract());
        _setupRole(META_FORCE_CONTRACT_ROLE, _registry.getHoldingContract());
        _setupRole(META_FORCE_CONTRACT_ROLE, _registry.getRequestMFSContract());

        getEnergyConversionFactor = 1e18;
        User storage r = users[ROOT_ID];
        r.marketingReferrer = ROOT_ID;
        for (uint256 i = 1; i <= LEVELS_COUNT; ) {
            r.packs[i] = type(uint32).max;
            emit TimestampEndPackSet(ROOT_ID, i, type(uint32).max);
            unchecked {
                ++i;
            }
        }

        rewardsDirectReferrers = [10e16, 7e16, 4e16, 4e16];
        rewardsMarketingReferrers = [15e16, 15e16, 15e16, 15e16, 15e16];

        IMFS mfsToken = IMFS(registry.getMFS());
        uint256 cap = mfsToken.cap();
        bigBlockSize = cap.mul(SHARE_OF_MARKETING).div(COEFF_DECREASE_NEXT_BB);
        meanSmallBlock = bigBlockSize / MB_COUNT;
        nowNumberSmallBlock = 0;
        endSmallBlock =
            endBigBlock +
            meanSmallBlock.mul(COEFF_FIRST_MB - COEFF_DECREASE_COST_PACK_NEXT_MB * nowNumberSmallBlock);
        endBigBlock = bigBlockSize;
        nowCoeffDecreaseMicroBlock = START_COEFF_DECREASE_MICROBLOCK;
        nowPriceFirstPackInMFS = PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB;
        priceMFSInUSD = PRICE_PACK_LEVEL1_IN_USD.div(PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB);

        meanDecreaseMicroBlock =
            (PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB - (PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB.div(COEFF_DECREASE_NEXT_BB))) /
            MB_COUNT;

        emit MarketingReferrerChanged(ROOT_ID, ROOT_ID);
    }

    function getReferrer(uint256 userId) public view override returns (uint256) {
        return IMetaCore(registry.getMetaCore()).getReferrer(userId);
    }

    function getMarketingReferrer(uint256 userId) public view returns (uint256) {
        return users[userId].marketingReferrer;
    }

    function checkRegistrationInMarketing(uint256 userId) public view override returns (bool) {
        return getMarketingReferrer(userId) != 0;
    }

    function getTimestampEndPack(uint256 userId, uint256 level) public view override returns (uint256) {
        return users[userId].packs[level];
    }

    function isPackActive(uint256 userId, uint256 level) public view returns (bool) {
        return getTimestampEndPack(userId, level) >= block.timestamp - OVERRLAP_TIME_ACTIVITY;
    }

    function getUserLevel(uint256 userId) public view override returns (uint256) {
        for (uint256 i = LEVELS_COUNT; i != 0; i--) {
            if (isPackActive(userId, i)) {
                return i;
            }
        }
        return 0;
    }

    function isUserActive(uint256 userId) public view returns (bool) {
        for (uint256 i = 1; i <= LEVELS_COUNT; ) {
            if (getTimestampEndPack(userId, i) >= block.timestamp - PACK_ACTIVITY_PERIOD) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function getFreePlace(uint256[] memory ids) public view returns (uint256) {
        uint256[] memory referrals = new uint256[](ids.length * 2);
        for (uint256 i = 0; i < ids.length; i++) {
            User storage r = users[ids[i]];
            if (r.marketingReferrals.length() < 2) {
                return ids[i];
            }
            referrals[i * 2] = r.marketingReferrals.at(0);
            referrals[i * 2 + 1] = r.marketingReferrals.at(1);
        }
        return getFreePlace(referrals);
    }

    function _setMarketingReferrer(uint256 userId, uint256 marketingReferrerId) internal {
        if (!checkRegistrationInMarketing(marketingReferrerId)) {
            revert MetaForceSpaceCoreReferrerIsNotRegistredInMarketing();
        }

        User storage r = users[marketingReferrerId];
        if (r.marketingReferrals.length() >= MARKETING_REFERRALS_TREE_ARITY) {
            revert MetaForceSpaceCoreNoMoreSpaceInTree();
        }

        uint256 oldReferrer = users[userId].marketingReferrer;

        if (oldReferrer != 0) {
            if (!users[oldReferrer].marketingReferrals.remove(userId)) {
                revert MetaForceSpaceCoreMarketingReferralRemovalFailed();
            }
        }

        users[userId].marketingReferrer = marketingReferrerId;
        if (!r.marketingReferrals.add(userId)) {
            revert MetaForceSpaceCoreMarketingReferralAdditionFailed();
        }

        emit MarketingReferrerChanged(userId, marketingReferrerId);
    }

    function nextSmallBlock() internal {
        if (nowNumberSmallBlock < MB_COUNT - 1) {
            nowNumberSmallBlock = nowNumberSmallBlock + 1;
            endSmallBlock =
                endSmallBlock +
                meanSmallBlock.mul(COEFF_FIRST_MB - COEFF_DECREASE_COST_PACK_NEXT_MB * nowNumberSmallBlock);
            nowPriceFirstPackInMFS = nowPriceFirstPackInMFS - meanDecreaseMicroBlock.mul(nowCoeffDecreaseMicroBlock);
            priceMFSInUSD = PRICE_PACK_LEVEL1_IN_USD.div(nowPriceFirstPackInMFS);
            nowCoeffDecreaseMicroBlock = nowCoeffDecreaseMicroBlock - COEFF_DECREASE_COST_PACK_NEXT_MB;
        } else {
            nextBigBlock();
        }
        emit SmallBlockMove(nowNumberSmallBlock);
    }

    function nextBigBlock() internal {
        bigBlockSize = bigBlockSize.div(COEFF_DECREASE_NEXT_BB);
        meanSmallBlock = bigBlockSize / MB_COUNT;
        nowNumberSmallBlock = 0;
        unchecked {
            ++nowNumberBigBlock;
        }
        endSmallBlock =
            endBigBlock +
            meanSmallBlock.mul(COEFF_FIRST_MB - COEFF_DECREASE_COST_PACK_NEXT_MB * nowNumberSmallBlock);
        endBigBlock = endBigBlock + bigBlockSize;
        nowCoeffDecreaseMicroBlock = START_COEFF_DECREASE_MICROBLOCK;
        nowPriceFirstPackInMFS = PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB.div(
            COEFF_DECREASE_COST_PACK_NEXT_BB.pow(nowNumberBigBlock.convertIntToFixPoint())
        );
        priceMFSInUSD = PRICE_PACK_LEVEL1_IN_USD.div(nowPriceFirstPackInMFS);
        meanDecreaseMicroBlock = meanDecreaseMicroBlock.div(COEFF_DECREASE_NEXT_BB);
        emit BigBlockMove(nowNumberBigBlock);
    }

    function getUserId(address user) internal view returns (uint256 userId) {
        IMetaCore metaCore = IMetaCore(registry.getMetaCore());
        userId = metaCore.checkRegistration(user);
    }

    function calculateNextMFSPrice() internal view returns (uint256 nextPriceMFS) {
        if (nowNumberSmallBlock < 9) {
            uint256 nextPriceFirstPackInMFS = nowPriceFirstPackInMFS -
                meanDecreaseMicroBlock.mul(nowCoeffDecreaseMicroBlock);
            nextPriceMFS = PRICE_PACK_LEVEL1_IN_USD.div(nextPriceFirstPackInMFS);
        } else {
            nextPriceMFS = PRICE_PACK_LEVEL1_IN_USD.div(PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB.div(COEFF_DECREASE_NEXT_BB));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMFS is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function setEmissionCommitted(bool _emissionCommitted) external;

    function cap() external view returns (uint256);

    function emissionCommitted() external view returns (bool);
}

interface IHMFS is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

interface IEnergy is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Constants.sol";
import "./IRegistryContract.sol";

error MetaForceSpaceCoreSenderIsNotMetaContract();
error MetaForceSpaceCoreNoMoreSpaceInTree();
error MetaForceSpaceCoreActiveUser();
error MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
error MetaForceSpaceCoreSumRewardsMustBeHundred();
error MetaForceSpaceCoreRewardsIsNotChange();
error MetaForceSpaceCoreMarketingReferralRemovalFailed();
error MetaForceSpaceCoreMarketingReferralAdditionFailed();
error MetaForceSpaceCoreEmissionCommitted();
error MetaForceSpaceCoreReferrerIsNotRegistredInMarketing();
error MetaForceSpaceCoreWorkflowNotSaleOpen();

struct User {
    TypeReward rewardType;
    uint256 marketingReferrer;
    uint256 mfsFrozenAmount;
    mapping(uint256 => uint256) packs;
    EnumerableSet.UintSet marketingReferrals;
}

enum TypeReward {
    ONLY_MFS,
    MFS_AND_USD,
    ONLY_USD
}

interface ICoreContract {
    event MarketingReferrerChanged(uint256 indexed accountId, uint256 indexed marketingReferrer);
    event TimestampEndPackSet(uint256 indexed accountId, uint256 level, uint256 timestamp);
    event WorkflowStageMove(Workflow workflowstage);
    event RewardsReferrerSetted();
    event PoolMFSBurned();
    event SmallBlockMove(uint256 nowNumberSmallBlock);
    event BigBlockMove(uint256 nowNumberBigBlock);

    //Set referrer in Marketing tree
    function setMarketingReferrer(uint256 userId, uint256 marketingReferrerId) external;

    //Set users type reward
    function setTypeReward(TypeReward typeReward) external;

    //Increase timestamp end pack of the corresponding level
    function increaseTimestampEndPack(
        uint256 userId,
        uint256 level,
        uint256 time
    ) external;

    //Set timestamp end pack of the corresponding level
    function setTimestampEndPack(
        uint256 userId,
        uint256 level,
        uint256 timestamp
    ) external;

    //delete user in marketing tree
    function clearInfo(uint256 userId) external;

    //replace user in marketing tree(refer and all referrals)
    function replaceUserInMarketingTree(uint256 from, uint256 to) external;

    function nextWorkflowStage() external;

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external;

    function setRewardsDirectReferrers(uint256[] calldata _rewardsRefers) external;

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingRefers) external;

    function setRewardsReferrers(uint256[] calldata _rewardsRefers, uint256[] calldata _rewardsMarketingRefers)
        external;

    function setNowPriceFirstPackInMFS(uint256 _price) external;

    function setupTokensInMetapayment() external;

    function burnMFSPool() external;

    function giveMFSFromPool(uint256 userId, uint256 amount) external;

    function directGiveMFSFromPool(address to, uint256 amount) external;

    function giveStableFromPool(uint256 userId, uint256 amount) external;

    function increaseTotalEmission(uint256 amount) external;

    // Check have referrer in referral tree
    function checkRegistrationInMarketing(uint256 userId) external view returns (bool);

    // Request user type reward
    function getTypeReward(uint256 userId) external view returns (TypeReward);

    // Request timestamp end pack of the corresponding level
    function getTimestampEndPack(uint256 userId, uint256 level) external view returns (uint256);

    // Request user referrer in referral tree
    function getReferrer(uint256 userId) external view returns (uint256);

    // Request user referrer in marketing tree
    function getMarketingReferrer(uint256 userId) external view returns (uint256);

    //Request user referrals starting from indexStart in marketing tree
    function getMarketingReferrals(uint256 userId) external view returns (uint256[] memory);

    //get user level (maximum active level)
    function getUserLevel(uint256 userId) external view returns (uint256);

    function isPackActive(uint256 userId, uint256 level) external view returns (bool);

    function getWorkflowStage() external view returns (Workflow);

    function getRewardsDirectReferrers() external view returns (uint256[] memory);

    function getRewardsMarketingReferrers() external view returns (uint256[] memory);

    function getDateStartSaleOpen() external view returns (uint256);

    function getEnergyConversionFactor() external view returns (uint256);

    function getRegistrationDate(uint256 userId) external view returns (uint256);

    function getLevelForNFT(uint256 userId) external view returns (uint256);

    function bigBlockSize() external view returns (uint256);

    function meanSmallBlock() external view returns (uint256);

    function nowNumberSmallBlock() external view returns (uint256);

    function nowNumberBigBlock() external view returns (uint256);

    function endBigBlock() external view returns (uint256);

    function endSmallBlock() external view returns (uint256);

    function nowCoeffDecreaseMicroBlock() external view returns (uint256);

    function meanDecreaseMicroBlock() external view returns (uint256);

    function nowPriceFirstPackInMFS() external view returns (uint256);

    function priceMFSInUSD() external view returns (uint256);

    function totalEmissionMFS() external view returns (uint256);

    function calcMFSAmountForUSD(uint256 amountUSD) external view returns (uint256 amount);

    function calcUSDAmountForMFS(uint256 amountMFS) external view returns (uint256 amountUSD);

    function getFreePlace(uint256[] memory ids) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IMetaCore is IAccessControl {
    function adminSetUserAddress(uint256 id, address addr) external;

    function adminSetUserReferrer(uint256 id, uint256 referrerId) external;

    function adminSetUserRegistrationDate(uint256 id, uint256 registrationDate) external;

    function adminSetNextId(uint256 id) external;

    function setPaymentChannelAddress(address newAddress) external;

    function registration(uint256 referrerId) external returns (uint256);

    function setAllowAdminControl(bool allowance) external;

    function setAlias(uint256 id, string memory al) external;

    function adminSetAlias(uint256 id, string memory al) external;

    function setHashKey(bytes32 newHashKey) external;

    function changeHashKey(
        string[] memory seed,
        uint256 id,
        bytes32 newHashKey
    ) external;

    function adminChangeHashKey(uint256 id, bytes32 newHashKey) external;

    function changeIdAddress(address newAddress) external;

    function adminChangeIdAddress(uint256 id, address newAddress) external;

    function retrieveMyIdAddress(string[] memory seed, uint256 id) external;

    function getPaymentChannelAddress() external view returns (address);

    function root() external view returns (address);

    function getUserAddress(uint256 id) external view returns (address);

    function getUserId(address userAddress) external view returns (uint256);

    function getUserIdByAlias(string memory al) external view returns (uint256);

    function nextId() external view returns (uint256);

    function getReferralPage(
        uint256 id,
        uint256 amountElementsOnPage,
        uint256 pageNumber
    ) external view returns (uint256[] memory);

    function getReferralAmount(uint256 id) external view returns (uint256);

    function getReferrer(uint256 id) external view returns (uint256);

    function getReferrers(uint256 id, uint256 amount) external view returns (uint256[] memory);

    function getRegistrationDate(uint256 id) external view returns (uint256);

    function getAlias(uint256 id) external view returns (string memory);

    function getHashKey(uint256 id) external view returns (bytes32);

    function getAllowAdminControl(uint256 id) external view returns (bool);

    function checkRegistration(address userAddress) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IMetaPayment is IAccessControl {
    function claim(address erc20) external;

    function claim(address erc20, uint256 amount) external;

    function add(address erc20, uint256 amount) external;

    function setFreezeStatus(address erc20, bool freeze) external; //onlyContractsRole

    function setNontransferableStatus(address erc20, bool freeze) external; //onlyContractsRole

    function getFreezeStatusToken(address erc20) external returns (bool);

    function getNontransferableStatus(address erc20) external returns (bool);

    function setDirectPayment(bool directPayment) external;

    function getDirectPaymentStatus(uint256 userId) external returns (bool);

    function getBalance(address erc20, uint256 userId) external returns (uint256);

    function setBalance(
        address erc20,
        uint256 idUser,
        uint256 amount
    ) external; //onlyContractsRole

    function increaseBalance(
        address erc20,
        uint256 idUser,
        uint256 amount
    ) external returns (uint256); //onlyContractsRole

    function decreaseBalance(
        address erc20,
        uint256 idUser,
        address principal,
        uint256 amount
    ) external; //onlyContractsRole

    function transferFrom(
        address erc20,
        uint256 idFrom,
        uint256 idTo,
        uint256 amount
    ) external; //onlyContractsRole

    function transfer(
        address erc20,
        uint256 idTo,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

interface IRegistryContract {
    function setMetaCore(address _metaCore) external;

    function setHoldingContract(address _holdingContract) external;

    function setMetaForceContract(address _metaForceContract) external;

    function setCoreContract(address _coreContract) external;

    function setMFS(address _mfs) external;

    function setHMFS(uint256 level, address _hMFS) external;

    function setStableCoin(address _stableCoin) external;

    function setSFCR(address _sFCR) external;

    function setSFCR2(address _sFCR2) external;

    function setRequestMFSContract(address _requestMFSContract) external;

    function setEnergyCoin(address _energyCoin) external;

    function setRewardsFund(address addressFund) external;

    function setLiquidityPool(address addressPool) external;

    function setOtherPool(address addressPool) external;

    function setMetaDevelopmentAndIncentiveFund(address addressFund) external;

    function setTeamFund(address addressFund) external;

    function setLiquidityListingFund(address addressFund) external;

    function setMetaPool(address addressPool) external;

    function setRoyaltyNFTGiftsPool(address addressPool) external;

    function setAirdropPool(address addressPool) external;

    function getMetaCore() external view returns (address);

    function getHoldingContract() external view returns (address);

    function getMetaForceContract() external view returns (address);

    function getCoreContract() external view returns (address);

    function getMFS() external view returns (address);

    function getHMFS(uint256 level) external view returns (address);

    function getStableCoin() external view returns (address);

    function getEnergyCoin() external view returns (address);

    function getSFCR() external view returns (address);

    function getSFCR2() external view returns (address);

    function getRequestMFSContract() external view returns (address);

    function getRewardsFund() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function getOtherPool() external view returns (address);

    function getMetaDevelopmentAndIncentiveFund() external view returns (address);

    function getTeamFund() external view returns (address);

    function getLiquidityListingFund() external view returns (address);

    function getMetaPool() external view returns (address);

    function getRoyaltyNFTGiftsPool() external view returns (address);

    function getAirdropPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Math.sol";

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);
error FixedPointMathLog2ArgumentTooBig(uint256 a);

uint256 constant SCALE = 1e18;

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant HALF_SCALE = 5e17;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 != 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 != 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 != 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 != 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 != 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 != 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 != 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 != 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 != 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 != 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 != 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 != 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 != 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 != 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 != 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 != 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 != 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 != 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 != 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 != 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 != 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 != 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 != 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 != 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 != 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 != 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 != 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 != 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 != 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 != 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 != 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 != 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 != 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 != 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 != 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 != 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 != 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 != 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 != 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 != 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 != 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 != 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 != 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 != 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 != 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 != 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 != 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 != 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 != 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 != 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 != 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 != 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 != 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 != 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 != 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 != 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 != 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 != 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 != 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 != 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 != 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 != 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 != 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 != 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert FixedPointMathLog2ArgumentTooBig(x);
        }
        unchecked {
            uint256 n = Math.mostSignificantBit(x / SCALE);

            result = n * SCALE;

            uint256 y = x >> n;

            if (y == SCALE) {
                return result;
            }

            for (uint256 delta = HALF_SCALE; delta != 0; delta >>= 1) {
                y = (y * y) / SCALE;

                if (y >= 2 * SCALE) {
                    result += delta;

                    y >>= 1;
                }
            }
        }
    }

    function convertIntToFixPoint(uint256 integer) internal pure returns (uint256 result) {
        result = integer * SCALE;
    }

    function convertFixPointToInt(uint256 integer) internal pure returns (uint256 result) {
        result = integer / SCALE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Math {
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}