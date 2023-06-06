// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "../mQuarkTemplate.sol";
import "./ImQuarkRegistry.sol";

interface ImQuarkController {
  /**
   * @notice Emitted when the address of the subscriber contract is set.
   * @param subscriber The address of the subscriber contract.
   */
  event SubscriberContractAddressSet(address subscriber);

  /**
   * @notice Emitted when the address of the template contract is set.
   * @param template The address of the template contract.
   */
  event TemplateContractAddressSet(address template);

  /**
   * @notice Emitted when the address of the registry contract is set.
   * @param registry The address of the registry contract.
   */
  event RegistryContractAddressSet(address registry);

  /**
   * @notice Emitted when the royalty percentage is set.
   * @param royalty The royalty percentage.
   */
  event RoyaltySet(uint256 royalty);

  /**
   * @notice Emitted when the prices of templates are set.
   * @param templateIds The IDs of the templates.
   * @param prices The corresponding prices for the templates.
   */
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);

  /**
   * @notice Emitted when the authorized withdrawal address is set.
   * @param authorizedWithdrawal The authorized withdrawal address.
   */
  event AuthorizedWithdrawalSet(address authorizedWithdrawal);

  /**
   * @notice Sets the prices for multiple templates.
   * @param templateIds The IDs of the templates.
   * @param prices The corresponding prices for the templates.
   */
  function setTemplatePrices(uint256[] calldata templateIds, uint256[] calldata prices) external;

  /**
   * @notice Sets the address of the template contract.
   * @param template The address of the template contract.
   */
  function setTemplateContractAddress(address template) external;

  /**
   * @notice Sets the address of the registry contract.
   * @param registry The address of the registry contract.
   */
  function setRegistryContract(address registry) external;

  /**
   * @notice Sets the royalty percentage.
   * @param _royalty The royalty percentage to set.
   */
  function setRoyalty(uint256 _royalty) external;

  /**
   * @notice Validates the authorization of a caller.
   * @param caller The address of the caller.
   * @return True if the caller is authorized, otherwise false.
   */
  function validateAuthorization(address caller) external view returns (bool);

  /**
   * @notice Retrieves the mint price for a template.
   * @param templateId The ID of the template.
   * @return The mint price of the template.
   */
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256);

  /**
   * @notice Retrieves the address of the subscriber contract.
   * @return The address of the subscriber contract.
   */
  function getSubscriberContract() external view returns (address);

  /**
   * @notice Retrieves the balance of an entity.
   * @param _entityId The ID of the entity.
   * @return The balance of the entity.
   */
  function getEntityBalance(uint256 _entityId) external view returns (uint256);

  /**
   * @notice Retrieves the implementation address for a given implementation type.
   * @param implementation The implementation type.
   * @return The implementation address.
   */
  function getImplementation(uint8 implementation) external view returns (address);

  /**
   * @notice Retrieves the royalty percentage.
   * @return The royalty percentage.
   */
  function getRoyalty() external view returns (uint256);

  /**
   * @notice Retrieves the authorized withdrawal address.
   * @return The authorized withdrawal address.
   */
  function getWithdrawalAddress() external view returns (address);

  /**
   * @notice Retrieves the royalty percentage and mint price for a template.
   * @param templateId The ID of the template.
   * @return The royalty percentage and mint price of the template.
   */
  function getRoyaltyAndMintPrice(uint256 templateId) external view returns (uint256, uint256);

  /// Throws if the lengths of the input arrays do not match.
  error ArrayLengthMismatch();

  /// Throws if the provided template ID does not exist.
  error TemplateIdNotExist();

  /// Throws if the provided royalty percentage is too high.
  error RoyaltyIsTooHigh();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

interface ImQuarkEntity {
  /**
   * @notice Emitted when a collection is created.
   * @param instanceAddress The address of the created collection contract instance.
   * @param verifier The address of the verifier contract.
   * @param controller The address of the controller contract.
   * @param entityId The ID of the entity associated with the collection.
   * @param collectionId The ID of the collection.
   * @param templateId The ID of the template associated with the collection.
   * @param mintPrice The price of minting a token in the collection.
   * @param totalSupply The total supply of tokens in the collection.
   * @param mintLimitPerWallet The maximum number of tokens that can be minted per wallet.
   * @param royalty The royalty percentage for the collection.
   * @param collectionURIs The URIs associated with the collection.
   * @param mintType The minting type of the collection.
   * @param dynamic A flag indicating if the collection has dynamic URIs.
   * @param free A flag indicating if the collection is free.
   * @param whiteListed A flag indicating if the collection is whitelisted.
   */
  event CollectionCreated(
    address instanceAddress,
    address verifier,
    address controller,
    uint256 entityId,
    uint64 collectionId,
    uint256 templateId,
    uint256 mintPrice,
    uint256 totalSupply,
    uint256 mintLimitPerWallet,
    uint256 royalty,
    string[] collectionURIs,
    uint8 mintType,
    bool dynamic,
    bool free,
    bool whiteListed
  );

  /**
   * @notice Emitted when an external collection is created.
   * @param collectionAddress The address of the created external collection contract.
   * @param entityId The ID of the entity associated with the collection.
   * @param templateId The ID of the template associated with the collection.
   * @param collectionId The ID of the collection.
   */
  event ExternalCollectionCreated(address collectionAddress, uint256 entityId, uint256 templateId, uint64 collectionId);

  /**
   * @notice Represents the parameters required to create a collection.
   */
  struct CollectionParams {
    uint256 templateId; // The ID of the template associated with the collection
    string[] collectionURIs; // The URIs associated with the collection
    uint256 totalSupply; // The total supply of tokens in the collection
    uint256 mintPrice; // The price of minting a token in the collection
    uint8 mintPerAccountLimit; // The maximum number of tokens that can be minted per wallet
    string name; // The name of the collection
    string symbol; // The symbol of the collection
    address verifier; // The address of the verifier contract
    bool isWhitelisted; // A flag indicating if the collection is whitelisted
  }

  /**
   * @notice Creates a new collection with the provided parameters.
   * @param collectionParams The parameters to create the collection.
   * @param isDynamicUri A flag indicating if the collection has dynamic URIs.
   * @param ERCimplementation The implementation type of the ERC721 contract.
   * @param merkeRoot The Merkle root of the collection.
   * @return instance The address of the created collection contract instance.
   */
  function createCollection(
    CollectionParams calldata collectionParams,
    bool isDynamicUri,
    uint8 ERCimplementation,
    bytes32 merkeRoot
  ) external returns (address instance);

  function importExternalCollection(
    uint256 _templateId,
    address _collectionAddress
  ) external;

  function addNewCollection(address _collectionAddress) external returns (uint64);

  function transferCollection(address _entity, uint64 _collectionId) external returns (uint64);

  /**
   * @notice Retrieves the ID of the last created collection.
   * @return The ID of the last created collection.
   */
  function getLastCollectionId() external view returns (uint64);

  /**
   * @notice Retrieves the address of a collection with the given collection ID.
   * @param collectionId The ID of the collection.
   * @return The address of the collection contract.
   */
  function getCollectionAddress(uint64 collectionId) external view returns (address);

  /**
   * @notice Retrieves the ID of a collection with the given entity address.
   * @param entity The Address of the entity.
   * @return The ID of the collection contract.
   */
  // function getEntityId(address entity) external view returns (uint256); 

  /// Throws if the provided URI length is invalid.
  error InvalidURILength(uint256 uriLength);

  /// Throws if the provided template ID is invalid.
  error InvalidTemplate(uint256 templateId);

  /// Throws if the provided collection price is invalid.
  error InvalidCollectionPrice(uint256 mintPrice);

  /// Throws if the caller is not the owner of the collection.
  error NotCollectionOwner(address collectionAddress);

  /// Throws if the collection contract does not support the ERC165 interface.
  error NoERC165Support(address collectionAddress);

  /// Throws if the collection contract does not support the ERC721 interface.
  error NoERC721Support(address collectionAddress);

  /// Throws if the collection address is not an external collection.
  error NotExternal(address collectionAddress);

  /// Throws if the total supply of the collection is zero.
  error TotalSupplyIsZero();

  /// Throws if the given collection ID is invalid.
  error InvalidCollection(uint64 collectionId);

  /// Throws if the given entity address is invalid.
  error InvalidEntity(address entity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

/**
 * @title ImQuarkNFT
 * @author Unbounded team
 * @notice Interface smart contract of the mQuark NFT protocol.
 */
interface ImQuarkNFT {
  /**
   * @notice Signals the minting of a new token.
   * @dev This event is emitted when a new token is created and assigned to the specified address.
   * @param tokenId ID of the newly minted token
   * @param to Address to which the token is assigned
   * @param entityId ID of the associated entity
   * @param templateId ID of the token's template
   * @param collectionId ID of the token's collection
   * @param amount Amount of tokens minted
   * @param uri URI associated with the token's metadata
   */
  event TokenMint(
    uint256 tokenId,
    address to,
    uint256 entityId,
    uint256 templateId,
    uint64 collectionId,
    uint256 amount,
    string uri
  );

  event CollectionTransferred(uint64 newCollectionId, uint64 previousCollectionId, address newEntityAddress);

  /**
   * @notice Signals the withdrawal of protocol funds.
   * @dev This event is emitted when funds are withdrawn from the protocol by the specified address.
   * @param to Address that receives the withdrawn funds
   * @param amount Amount of funds withdrawn
   * @param savedAmountOwner Amount of funds saved by the owner
   * @param totalWithdrawn Total amount of funds withdrawn so far
   */
  event WithdrawProtocol(address to, uint256 amount, uint256 savedAmountOwner, uint256 totalWithdrawn);

  /**
   * @notice Signals the withdrawal of funds.
   * @dev This event is emitted when funds are withdrawn by the specified address.
   * @param to Address that receives the withdrawn funds
   * @param amount Amount of funds withdrawn
   * @param royalty Royalty amount associated with the withdrawal
   * @param totalWithdrawn Total amount of funds withdrawn so far
   */
  event Withdraw(address to, uint256 amount, uint256 royalty, uint256 totalWithdrawn);

  /**
   * @notice Signals the update of royalty information.
   * @dev This event is emitted when the royalty percentage and receiver address are updated.
   * @param percentage Royalty percentage
   * @param receiver Address of the royalty receiver
   */
  event RoyaltyInfoUpdated(uint16 percentage, address receiver);

  /**
   * @notice Represents the subscription information for a token.
   */
  struct TokenSubscriptionInfo {
    bool isSubscribed; // Flag indicating if the token is subscribed
    string uri; // URI associated with the token
  }

  /**
   * @notice Represents royalty information for minted tokens.
   */
  struct MintRoyalty {
    uint256 royalty; // Royalty amount for the token
    uint256 withdrawnAmountByOwner; // Amount withdrawn by the owner
    uint256 withdrawnAmountByProtocol; // Amount withdrawn by the protocol
    uint256 savedAmountOwner; // Amount saved by the owner
    uint256 totalWithdrawn; // Total amount withdrawn for the token
  }

  /**
   * @notice Mints a token with the given variation ID.
   * @dev Emits an {TokenMint} event.
   * @param variationId The ID of the token variation to mint.
   */
  function mint(uint256 variationId) external payable;

  /**
   * @notice Mints a token with a specified URI and signature.
   * @dev Emits an {TokenMint} event.
   * @param signer The address of the signer for the signature verification.
   * @param signature The signature used to verify the authenticity of the minting request.
   * @param uri The URI associated with the minted token.
   * @param salt The salt value used for the minting process.
   */
  function mintWithURI(
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Mints a token with a whitelist verification using Merkle proofs.
   * @dev Emits an {TokenMint} event.
   * @param merkleProof The array of Merkle proofs used for whitelist verification.
   * @param variationId The ID of the token variation to mint.
   */
  function mintWhitelist(bytes32[] memory merkleProof, uint256 variationId) external payable;

  /**
   * @notice Mints a token with a whitelist verification, specified URI, and signature.
   * @dev Emits an {TokenMint} event.
   * @param merkleProof The array of Merkle proofs used for whitelist verification.
   * @param signer The address of the signer for the signature verification.
   * @param signature The signature used to verify the authenticity of the minting request.
   * @param uri The URI associated with the minted token.
   * @param salt The salt value used for the minting process.
   */
  function mintWithURIWhitelist(
    bytes32[] memory merkleProof,
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Subscribes an owner to a single entity for a specific token.
   * @param owner The address of the owner to subscribe.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity to subscribe to.
   * @param entitySlotDefaultUri The default URI associated with the entity slot.
   */
  function subscribeToEntity(
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata entitySlotDefaultUri
  ) external;

  /**
   * @notice Subscribes an owner to multiple entities for a specific token.
   * @param owner The address of the owner to subscribe.
   * @param tokenId The ID of the token.
   * @param entityIds The array of entity IDs to subscribe to.
   * @param entitySlotDefaultUris The array of default URIs associated with the entity slots.
   */
  function subscribeToEntities(
    address owner,
    uint256 tokenId,
    uint64[] calldata entityIds,
    string[] calldata entitySlotDefaultUris
  ) external;

  /**
   * @notice Updates the URI slot of a single token.
   * @dev The entity must sign the new URI with its wallet address.
   * @param owner The address of the token owner.
   * @param entityId The ID of the entity.
   * @param tokenId The ID of the token.
   * @param updatedUri The updated, signed URI value.
   */
  function updateURISlot(address owner, uint256 entityId, uint256 tokenId, string calldata updatedUri) external;

  /**
   * @notice Returns the entity URI for the given token ID.
   * @dev Each entity can assign slots to tokens, storing a URI that refers to something on the entity.
   * @dev Slots are viewable by other entities but modifiable only by the token owner with a valid signature from the entity.
   * @param tokenId  The ID of the token for which the entity URI is to be returned.
   * @param entityId The ID of the entity associated with the given token.
   * @return The URI of the entity slot for the given token.
   */
  function tokenEntityURI(uint256 tokenId, uint256 entityId) external view returns (string memory);
  
  // todo: add documentation
  function transferCollectionOwnership(address newOwner) external;

  /**
   * @notice Initializes the contract with the specified parameters.
   * @dev This function is used to initialize the contract's state variables.
   * @param collection The Collection object representing the collection.
   * @param collectionOwner The address of the collection owner.
   * @param controller The address of the controller.
   * @param merkleRoot The root hash of the Merkle tree used for whitelist verification.
   * @param mintRoyalty The royalty percentage to be applied during token minting.
   */
  function initilasiable(
    Collection calldata collection,
    address collectionOwner,
    address controller,
    bytes32 merkleRoot,
    uint256 mintRoyalty
  ) external;

  /**
   * @notice Transfers the entity URI of a token to a new owner with the specified URI.
   * @dev This function is used to transfer the ownership of the entity URI associated with a token.
   * @param owner The address of the new owner of the token.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @param soldUri The URI to be transferred to the new owner.
   */
  function transferTokenEntityURI(address owner, uint256 tokenId, uint256 entityId, string calldata soldUri) external;

  /**
   * @notice Resets the entity slot of a token to its default URI.
   * @dev This function is used to reset the entity slot of a token to its default URI.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @param defaultUri The default URI to be set for the entity slot.
   */
  function resetSlotToDefault(address owner, uint256 tokenId, uint256 entityId, string calldata defaultUri) external;

  /**
   * @notice Retrieves information about the collection.
   * @dev This function returns various information about the collection.
   * @return entityId The ID of the entity associated with the collection.
   * @return collectionId The ID of the collection.
   * @return mintType The type of minting allowed for the collection.
   * @return mintPerAccountLimit The maximum number of tokens that can be minted per account.
   * @return isWhitelisted A flag indicating whether the collection is whitelisted.
   * @return isFree A flag indicating whether the minting is free for the collection.
   * @return templateId The ID of the collection template.
   * @return mintCount The current count of minted tokens in the collection.
   * @return totalSupply The total supply of tokens in the collection.
   * @return mintPrice The price of minting a token in the collection.
   * @return collectionURIs An array of URIs associated with the collection.
   * @return verifier The address of the verifier for the collection.
   */
  function getCollectionInfo()
    external
    view
    returns (
      uint256 entityId,
      uint64 collectionId,
      uint8 mintType,
      uint8 mintPerAccountLimit,
      bool isWhitelisted,
      bool isFree,
      uint256 templateId,
      uint256 mintCount,
      uint256 totalSupply,
      uint256 mintPrice,
      string[] memory collectionURIs,
      address verifier
    );

  /**
   * @notice Withdraws the available balance for the caller.
   */
  function withdraw() external;

  /**
   * @notice Allows the protocol to withdraw its available balance.
   */
  function protocolWithdraw() external;

  /// Thrown when attempting to access an invalid variation.
  error InvalidVariation(string reason, uint256 variationId);
  /// Thrown when the collection URI is empty.
  error CollectionURIZero(string reason);
  /// Thrown when the collection is sold out and no more tokens can be minted.
  error CollectionIsSoldOut(string reason);
  /// Thrown when attempting to perform a mint operation with an incorrect mint type.
  error WrongMintType(string reason, uint8 mintType);
  /// Thrown when the payment is invalid or insufficient.
  error InvalidPayment(string reason);
  /// Thrown when no payment is required for the minting operation.
  error NoPaymentRequired(string reason);
  /// Thrown when the verification process fails.
  error VerificationFailed(string reason);
  /// Thrown when the entity is not whitelisted.
  error NotWhitelisted(string reason);
  /// Thrown when the caller is not the owner of the specified token.
  error NotOwner(string reason, uint256 tokenId);
  /// Thrown when attempting to access the entity slot of a token that is not subscribed to any entity.
  error Unsubscribed(string reason, uint256 tokenId, uint256 entityId);
  /// Thrown when the signature provided is not operative.
  error InoperativeSignature(string reason);
  /// Thrown when the caller is not authorized to perform the operation.
  error NotAuthorized(string reason);
  /// Thrown when the caller has insufficient balance to perform the operation.
  error InsufficientBalance(string reason);
  /// Thrown when the minting limit has been reached and no more tokens can be minted for an account.
  error MintLimitReached(string reason);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ImQuarkEntity.sol";

interface ImQuarkRegistry {
  /**
   * Emitted when the subscriber contract address is set.
   *
   * @param subscriber The address of the subscriber contract.
   */
  event SubscriberSet(address subscriber);
  /**
   * Emitted when the controller contract address is set.
   *
   * @param controller The address of the controller contract.
   */
  event ControllerSet(address controller);
  /**
   * Emitted when the implementation contract address is set for a specific ID.
   *
   * @param id             The ID of the implementation.
   * @param implementation The address of the implementation contract.
   */
  event ImplementationSet(uint256 id, address implementation);
  /**
   * Emitted when an entity is registered to the contract.
   *
   * @param entity                The address of the entity.
   * @param contractAddress       The address of the contract.
   * @param entityId              The ID of the entity.
   * @param entityName            The name of the entity.
   * @param description           The description of the entity.
   * @param thumbnail             The thumbnail image URL of the entity.
   * @param entityDefaultSlotURI  The default URI for the entity's slots.
   * @param subscriptionPrice     The price for the entity's subscription slot.
   */
  event EntityRegistered(
    address entity,
    address contractAddress,
    uint256 entityId,
    string entityName,
    string description,
    string thumbnail,
    string entityDefaultSlotURI,
    uint256 subscriptionPrice
  );
  
  /**
   * Represents an entity registered in the contract.
   */
  struct Entity {
    // The creator address of the entity
    address creator;
    // The createed contract address of the entity's creator
    address contractAddress;
    // The unique ID of the entity
    uint256 id;
    // The name of the entity
    string name;
    // The description of the entity
    string description;
    // The thumbnail image of the entity
    string thumbnail;
    // The default URI for the entity's tokens
    string entitySlotDefaultURI;
  }

  /**
   * Sets the address of the controller.
   *
   * @param controller The address of the controller contract.
   */
  function setControllerAddress(address controller) external;

  /**
   * Sets the address of the subscriber.
   *
   * @param subscriber The address of the subscriber contract.
   */
  function setSubscriberAddress(address subscriber) external;

  /**
   * Sets the address of the implementation for a specific ID.
   *
   * @param id            The ID of the implementation.
   * @param implementation The address of the implementation contract.
   */
  function setImplementationAddress(uint8 id, address implementation) external;

  /**
   * Registers an entity to the contract.
   *
   * @param entityName            The name of the entity.
   * @param description           The description of the entity.
   * @param thumbnail             The URL of the entity's thumbnail image.
   * @param entitySlotDefaultURI  The default URI for the entity's tokens.
   * @param subscriptionPrice     The price of the entity's subscription slot.
   */
  function registerEntity(
    string calldata entityName,
    string calldata description,
    string calldata thumbnail,
    string calldata entitySlotDefaultURI,
    uint256 subscriptionPrice
  ) external;

  /**
   * Returns the entity ID for a given contract address.
   *
   * @param contractAddress The address of the contract.
   * @return                The entity ID.
   */
  function getEntityId(address contractAddress) external view returns (uint256);

  /**
   * Returns the contract address for a given entity ID.
   *
   * @param entityId The ID of the entity.
   * @return         The contract address.
   */
  function getEntityAddress(uint256 entityId) external view returns (address);

  /**
   * Returns the details of a registered entity.
   *
   * @param entityId               The ID of the entity.
   * @return contractAddress       Contract address
   * @return creator               Creator address
   * @return id                    ID
   * @return name                  Name
   * @return description           Description
   * @return thumbnail             Thumbnail
   * @return entitySlotDefaultURI  Slot default URI
   * */
  function getRegisteredEntity(
    uint256 entityId
  )
    external
    view
    returns (
      address contractAddress,
      address creator,
      uint256 id,
      string memory name,
      string memory description,
      string memory thumbnail,
      string memory entitySlotDefaultURI
    );

  /**
   * Returns the subscriber contract address.
   *
   * @return The subscriber contract address.
   */
  function getSubscriber() external view returns (address);

  /**
   * Returns the controller contract address.
   *
   * @return The controller contract address.
   */
  function getController() external view returns (address);

  /**
   * Returns the price of the entity's subscription slot.
   *
   * @param entityId The ID of the entity.
   * @return          The price of the subscription slot.
   */
  function getEntitySubscriptionPrice(uint256 entityId) external view returns (uint256);

  /**
   * Returns the last entity ID.
   *
   * @return The last entity ID.
   */
  function getLastEntityId() external view returns (uint256);

  /**
   * Returns the implementation contract address for a specific ID.
   *
   * @param implementation The ID of the implementation.
   * @return                The implementation contract address.
   */
  function getImplementation(uint8 implementation) external view returns (address);

  /**
   * Returns the controller and subscriber contract addresses.
   *
   * @return The controller and subscriber contract addresses.
   */
  function getControllerAndSubscriber() external view returns (address, address);

  // todo
  // todo
  function getEntityIsRegistered(address _contractAddress) external view returns (bool);

  /// Throws if the given address is not registered.
  error EntityAddressNotRegistered(address entity);

  /// Throws if the given ID is not registered.
  error EntityIdNotRegistered(uint256 entity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ImQuarkTemplate {
  /**
   * @notice Emitted when a new category is created.
   * @param category The name of the category.
   * @param id The ID of the category.
   * @param selector The selector of the category.
   * @param uri The URI of the category.
   */
  event CategoryCreated(string category, uint256 id, bytes4 selector, string uri);
  /**
   * @notice Emitted when a new template is created.
   * @param templateId The ID of the created template.
   * @param uri The URI of the template.
   */
  event TemplateCreated(uint256 templateId, string uri);
  /**
   * @notice Emitted when categories are set for a group of templates.
   * @param category The name of the category.
   * @param templateIds The IDs of the templates associated with the category.
   */
  event CategoriesSet(string category, uint256[] templateIds);

  /**
   * @notice Emitted when a template is removed from a category.
   * @param category The name of the category.
   * @param templateId The ID of the removed template.
   */
  event CategoryRemoved(string category, uint256 templateId);

  struct Category {
    uint256 id; // The ID of the category
    bytes4 selector; // The selector of the category
    string name; // The name of the category
    string uri; // The URI of the category
  }

  /**
   * @notice Creates a new template with the given URI, which will be inherited by collections.
   * @param uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata uri) external;

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   * @param uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata uris) external;

  /**
   * @notice Creates a new category with the given name and URI.
   * @param name The name of the category.
   * @param uri The metadata URI that will represent the category.
   */
  function createCategory(string calldata name, string calldata uri) external;

  /**
   * @notice Creates multiple categories with the given names and URIs.
   * @param names The names of the categories.
   * @param uris The metadata URIs that will represent the categories.
   */
  function createBatchCategory(string[] calldata names, string[] calldata uris) external;

  /**
   * @notice Sets the category for multiple templates.
   * @param category The name of the category.
   * @param templateIds_ The IDs of the templates to assign to the category.
   */
  function setTemplateCategory(string calldata category, uint256[] calldata templateIds_) external;

  /**
   * @notice Removes a category assignment from a template.
   * @param category The name of the category.
   * @param templateId The ID of the template to remove from the category.
   */
  function removeCategoryFromTemplate(string memory category, uint256 templateId) external;

  /**
   * @notice Retrieves all template IDs assigned to a specific category.
   * @param category The name of the category.
   * @return An array of template IDs assigned to the category.
   */
  function getAllCategoryTemplates(string memory category) external view returns (uint256[] memory);

  /**
   * @notice Retrieves a batch of template IDs assigned to a specific category based on an index range.
   * @param category The name of the category.
   * @param startIndex The start index of the batch.
   * @param batchLength The length of the batch.
   * @return An array of template IDs assigned to the category within the specified index range.
   */
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) external view returns (uint256[] memory);

  /**
   * @notice Retrieves the categories associated with a template based on its ID.
   * @param templateId The ID of the template.
   * @return An array of category names associated with the template.
   */
  function getTemplatesCategory(uint256 templateId) external view returns (string[] memory);

  /**
   * @notice Retrieves the number of templates assigned to a specific category.
   * @param category The name of the category.
   * @return The number of templates assigned to the category.
   */
  function getCategoryTemplateLength(string calldata category) external view returns (uint256);

  /**
   * @notice Retrieves category information by its name.
   * @param name The name of the category.
   * @return id The ID of the category.
   * @return selector The selector of the category.
   * @return uri The URI of the category.
   */
  function getCategoryByName(
    string calldata name
  ) external view returns (uint256 id, bytes4 selector, string memory uri);

  /**
   * @notice Retrieves category information by its ID.
   * @param id The ID of the category.
   * @return selector The selector of the category.
   * @return name The name of the category.
   * @return uri The URI of the category.
   */
  function getCategoryById(uint256 id) external view returns (bytes4 selector, string memory name, string memory uri);

  /**
   * @notice Retrieves category information by its selector.
   * @param selector The selector of the category.
   * @return id The ID of the category.
   * @return name The name of the category.
   * @return uri The URI of the category.
   */
  function getCategoryBySelector(
    bytes4 selector
  ) external view returns (uint256 id, string memory name, string memory uri);

  /**
   * @notice Retrieves the metadata URI of a template based on its ID.
   * @param templateId The ID of the template.
   * @return The metadata URI of the template.
   */
  function templateUri(uint256 templateId) external view returns (string memory);

  /**
   * @notice Retrieves the ID of the last created template.
   * @return The ID of the last created template.
   */
  function getLastTemplateId() external view returns (uint256);

  /**
   * @notice Checks if a template with the given ID exists.
   * @param templateId The ID of the template.
   * @return exist A boolean indicating if the template exists.
   */
  function isTemplateIdExist(uint256 templateId) external view returns (bool exist);

  /// Throws if a limit has been exceeded.
  error ExceedsLimit();
  /// Throws if there is a mismatch in the length of arrays.
  error ArrayLengthMismatch();
  /// Throws if the specified category does not exist.
  error UnexistingCategory();
  /// Throws if the specified template does not exist.
  error UnexistingTemplate();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

struct CreateCollectionParams {
  uint256 templateId;
  uint256 collectionPrice;
  uint256 totalSupply;
}

struct Collection {
  uint256 entityId;
  uint64 collectionId;
  uint8 mintType;
  uint8 mintPerAccountLimit;
  bool isWhitelisted;
  bool isFree;
  uint256 templateId;
  uint256 mintCount;
  uint256 totalSupply;
  uint256 mintPrice;
  string[] collectionURIs;
  string name;
  string symbol;
  address verifier;
}

struct SellOrder {
  // the order maker (the person selling the URI)
  address payable seller;
  // the "from" token contract address
  address fromContractAddress;
  // the token id whose entity URI will be sold
  uint256 fromTokenId;
  // the entity's id whose owner is selling the URI
  uint256 entityId;
  // the URI that will be sold
  string slotUri;
  // the price required for the URI
  uint256 sellPrice;
  bytes salt;
}
struct BuyOrder {
  // the order executer (the person buying the URI)
  address buyer;
  // the order maker (the person selling the URI)
  address seller;
  // the "from" token contract address
  address fromContractAddress;
  // the token id whose entity URI will be sold
  uint256 fromTokenId;
  // the "to" token contract address
  address toContractAddress;
  // the token id whose entity URI will be sold
  uint256 toTokenId;
  // the entity's id whose owner is selling the URI
  uint256 entityId;
  // the URI that will be bought
  string slotUri;
  // the price required for the URI
  uint256 buyPrice;
  bytes salt;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

library EnumerableStringSet {
    
  struct StringSet {
    // Storage of set values
    string[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(string => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(StringSet storage set, string memory value) internal returns (bool) {
    if (!contains(set, value)) {
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
  function remove(StringSet storage set, string memory value) internal returns (bool) {
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
        string memory lastvalue = set._values[lastIndex];

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
  function contains(StringSet storage set, string memory value) internal view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(StringSet storage set) internal view returns (uint256) {
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
  function at(StringSet storage set, uint256 index) internal view returns (string memory) {
    return set._values[index];
  }

  function values(StringSet storage set) internal view returns (string[] memory) {
    return set._values;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "./utils/SolmateNFT.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ImQuarkNFT.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkEntity.sol";

///@dev mQuarkNFT721
contract mQuarkNFT721 is ImQuarkNFT, ERC721, Ownable, Initializable, ReentrancyGuard {
  //* =============================== MAPPINGS ======================================================== *//
  // Mapping from a 'token id' to TokenInfo struct.
  mapping(uint256 => string) private s_tokenUris;

  // Mapping from a 'token id' and 'entity id' to a 'entity slot URI'
  mapping(uint256 => mapping(uint256 => TokenSubscriptionInfo)) private s_tokenSubscriptions;

  // Stores already minted accounts / EOA => contract => mint count
  mapping(address => uint256) private s_mintCountsPerAccount;

  // Mapping from a 'signature' to a 'boolean
  // Prevents the same signature from being used twice
  mapping(bytes => bool) private s_inoperativeSignatures;

  //* =============================== VARIABLES ======================================================= *//

  // ID of this contract
  uint64 public s_ID;

  // Royalty percentage for mQuark protocol
  uint16 public s_royaltyPercentage;

  // Indicates if the collection is free to mint
  bool public s_freeMintCollection;

  // Stores the current token ID
  uint256 public s_currentTokenId;

  // Royalty receiver address from token transfers
  address public s_royaltyReceiver;

  // Stores the owner entity address
  ImQuarkEntity public s_ownerEntity;

  // Stores the controller contract address
  ImQuarkController public s_controller;

  // Stores the collection information
  Collection private s_collectionInfo;

  // Stores the mint royalty information
  MintRoyalty private s_mintRoyaltyInfo;

  // Stores the merkle root if the collection is based on merkle proof mint
  bytes32 public s_merkleRoot;

  // The constant value for royalty divisor
  uint32 public constant ROYALTY_DIVISOR = 100000;

  //* =============================== MODIFIERS ======================================================= *//

  modifier onlyAuthorized() {
    if (!s_controller.validateAuthorization(msg.sender)) revert NotAuthorized("L721");
    _;
  }

  modifier onlySubscriber() {
    if (s_controller.getSubscriberContract() != msg.sender) revert NotAuthorized("L721");
    _;
  }

  modifier onlyOwners() {
    if (owner() != _msgSender() && address(s_ownerEntity) != _msgSender()) revert NotAuthorized("L721");
    _;
  }

  //* =============================== CONSTRUCTOR ===================================================== *//

  constructor() ERC721("mQuark", "MQK") {}

  //* =============================== FUNCTIONS ======================================================= *//
  // * ============== EXTERNAL =========== *//
  /**
   * @dev Initializes the collection contract with the specified parameters.
   * @param _collection The Collection struct containing the collection information.
   * @param _collectionOwner The address of the collection owner.
   * @param _controller The address of the controller contract.
   * @param _merkleRoot The Merkle root hash for verifying token subscriptions.
   * @param _mintRoyalty The royalty percentage for minting tokens.
   */
  function initilasiable(
    Collection calldata _collection,
    address _collectionOwner,
    address _controller,
    bytes32 _merkleRoot,
    uint256 _mintRoyalty
  ) external initializer {
    name = _collection.name;
    symbol = _collection.symbol;
    s_collectionInfo = _collection;
    s_merkleRoot = _merkleRoot;
    s_ID = _collection.collectionId;
    s_freeMintCollection = _collection.isFree;
    s_mintRoyaltyInfo.royalty = _mintRoyalty;
    s_ownerEntity = ImQuarkEntity(msg.sender);
    s_controller = ImQuarkController(_controller);
    _transferOwnership(_collectionOwner);
  }

  /**
   * @dev Mints a new token with the specified variation ID.
   * @param _variationId The ID of the token variation to mint.
   */
  function mint(uint256 _variationId) external payable {
    // Perform validity checks on the collection
    Collection memory m_tempData = _validityChecks();

    // Check the mint type of the collection
    if (m_tempData.mintType != 1 && m_tempData.mintType != 5 && m_tempData.mintType != 7 && m_tempData.mintType != 11) {
      revert WrongMintType("D721", m_tempData.mintType);
    }

    // Check the validity of the variation ID
    if (m_tempData.collectionURIs.length <= _variationId) {
      revert InvalidVariation("A721", _variationId);
    }

    // Perform payment checks based on the mint type
    if (m_tempData.mintType < 6) {
      // Paid collection
      if (msg.value == 0 || msg.value != m_tempData.mintPrice) {
        revert InvalidPayment("E721");
      }
    } else {
      // Free collection
      if (msg.value != 0) {
        revert NoPaymentRequired("F721");
      }
    }

    // Mint the token and get its ID
    uint256 m_tokenId = _mintToken();

    // Set the URI for the minted token
    s_tokenUris[m_tokenId] = m_tempData.collectionURIs[_variationId];

    // Emit the TokenMint event
    emit TokenMint(
      m_tokenId,
      msg.sender,
      m_tempData.entityId,
      m_tempData.templateId,
      m_tempData.collectionId,
      msg.value,
      m_tempData.collectionURIs[_variationId]
    );
  }

  /**
   * @dev Mints a new token with the specified URI and signature.
   * @param _signer The address of the signer of the signature.
   * @param _signature The signature of the minting data.
   * @param _uri The URI for the minted token.
   * @param _salt The salt value for signature verification.
   */
  function mintWithURI(
    address _signer,
    bytes calldata _signature,
    string calldata _uri,
    bytes calldata _salt
  ) external payable {
    // Perform validity checks on the collection
    Collection memory m_tempData = _validityChecks();

    // Check the mint type of the collection
    if (m_tempData.mintType != 3 && m_tempData.mintType != 9) {
      revert WrongMintType("D721", m_tempData.mintType);
    }

    // Verify the signature
    if (
      !_verifySignature(
        _signature,
        _signer,
        m_tempData.entityId,
        m_tempData.templateId,
        m_tempData.collectionId,
        _uri,
        _salt
      )
    ) {
      revert VerificationFailed("G721");
    }

    // Perform payment checks based on the mint type
    if (m_tempData.mintType < 6) {
      // Paid collection
      if (msg.value == 0 || msg.value != m_tempData.mintPrice) {
        revert InvalidPayment("E721");
      }
    } else {
      // Free collection
      if (msg.value != 0) {
        revert NoPaymentRequired("F721");
      }
    }

    // Mark the signature as inoperative
    s_inoperativeSignatures[_signature] = true;

    // Mint the token and get its ID
    uint256 m_tokenId = _mintToken();

    // Set the URI for the minted token
    s_tokenUris[m_tokenId] = _uri;

    // Emit the TokenMint event
    emit TokenMint(
      m_tokenId,
      msg.sender,
      m_tempData.entityId,
      m_tempData.templateId,
      m_tempData.collectionId,
      msg.value,
      _uri
    );
  }

  /**
   * @dev Mints a new token for a whitelisted address using a Merkle proof.
   * @param _merkleProof The Merkle proof for address whitelisting.
   * @param _variationId The ID of the token variation.
   */
  function mintWhitelist(bytes32[] memory _merkleProof, uint256 _variationId) external payable {
    // Perform validity checks on the collection
    Collection memory m_tempData = _validityChecks();

    // Check the mint type of the collection
    if (m_tempData.mintType != 0 && m_tempData.mintType != 4 && m_tempData.mintType != 6 && m_tempData.mintType != 10) {
      revert WrongMintType("D721", m_tempData.mintType);
    }

    // Calculate the leaf value for the sender's address
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

    // Verify the Merkle proof for address whitelisting
    if (!MerkleProof.verify(_merkleProof, s_merkleRoot, leaf)) {
      revert NotWhitelisted("H721");
    }

    // Check the validity of the variation ID
    if (m_tempData.collectionURIs.length <= _variationId) {
      revert InvalidVariation("A721", _variationId);
    }

    // Perform payment checks based on the mint type
    if (m_tempData.mintType < 6) {
      // Paid collection
      if (msg.value == 0 || msg.value != m_tempData.mintPrice) {
        revert InvalidPayment("E721");
      }
    } else {
      // Free collection
      if (msg.value != 0) {
        revert NoPaymentRequired("F721");
      }
    }

    // Mint the token and get its ID
    uint256 m_tokenId = _mintToken();

    // Set the URI for the minted token
    s_tokenUris[m_tokenId] = m_tempData.collectionURIs[_variationId];

    // Emit the TokenMint event
    emit TokenMint(
      m_tokenId,
      msg.sender,
      m_tempData.entityId,
      m_tempData.templateId,
      m_tempData.collectionId,
      msg.value,
      m_tempData.collectionURIs[_variationId]
    );
  }

  /**
   * @dev Mints a new token for a whitelisted address using a Merkle proof and a signature.
   * @param _merkleProof The Merkle proof for address whitelisting.
   * @param _signer The signer address used for the signature.
   * @param _signature The signature to be verified.
   * @param _uri The URI of the token.
   * @param _salt The salt used in the signature.
   */
  function mintWithURIWhitelist(
    bytes32[] memory _merkleProof,
    address _signer,
    bytes calldata _signature,
    string calldata _uri,
    bytes calldata _salt
  ) external payable {
    // Perform validity checks on the collection
    Collection memory m_tempData = _validityChecks();

    // Check the mint type of the collection
    if (m_tempData.mintType != 2 && m_tempData.mintType != 8) {
      revert WrongMintType("D721", m_tempData.mintType);
    }

    // Calculate the leaf value for the sender's address
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

    // Verify the Merkle proof for address whitelisting
    if (!MerkleProof.verify(_merkleProof, s_merkleRoot, leaf)) {
      revert NotWhitelisted("H721");
    }

    // Verify the signature
    if (
      !_verifySignature(
        _signature,
        _signer,
        m_tempData.entityId,
        m_tempData.templateId,
        m_tempData.collectionId,
        _uri,
        _salt
      )
    ) {
      revert VerificationFailed("G721");
    }

    // Perform payment checks based on the mint type
    if (m_tempData.mintType < 6) {
      // Paid collection
      if (msg.value == 0 || msg.value != m_tempData.mintPrice) {
        revert InvalidPayment("E721");
      }
    } else {
      // Free collection
      if (msg.value != 0) {
        revert NoPaymentRequired("F721");
      }
    }

    // Mark the signature as used
    s_inoperativeSignatures[_signature] = true;

    // Mint the token and get its ID
    uint256 m_tokenId = _mintToken();

    // Set the URI for the minted token
    s_tokenUris[m_tokenId] = _uri;

    // Emit the TokenMint event
    emit TokenMint(
      m_tokenId,
      msg.sender,
      m_tempData.entityId,
      m_tempData.templateId,
      m_tempData.collectionId,
      msg.value,
      _uri
    );
  }

  /**
   * @dev Adds a single URI slot to a single non-fungible token (NFT) and initializes the added slot with the given entity's default URI.
   * So that, token owner subscribes to the entity.Entity owner can change the URI of the slot.
   * The added slot's initial state will be pre-filled with the entity's default URI.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token to which the slot will be added.
   * @param _entityId The ID of the slot's entity.
   * @param _entityDefaultUri The entity's default URI that will be set to the added slot.
   */
  function subscribeToEntity(
    address _owner,
    uint256 _tokenId,
    uint256 _entityId,
    string calldata _entityDefaultUri
  ) external onlySubscriber {
    // Check if the caller is the owner of the token
    if (ownerOf(_tokenId) != _owner) revert NotOwner("I721", _tokenId);

    // Set the subscription for the token and entity
    s_tokenSubscriptions[_tokenId][_entityId] = TokenSubscriptionInfo(true, _entityDefaultUri);
  }

  /**
   * @dev Adds multiple URI slots to a single token in a batch operation.
   * So that, token owner subscribes to the entity.Entity owner can change the URI of the slot.
   * Slots' initial state will be pre-filled with the given default URI values.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token to which the slots will be added.
   * @param _entityIds An array of IDs for the slots that will be added.
   * @param _entityDefaultUris An array of default URI values for the added slots.
   */
  function subscribeToEntities(
    address _owner,
    uint256 _tokenId,
    uint64[] calldata _entityIds,
    string[] calldata _entityDefaultUris
  ) external onlySubscriber {
    // Check if the caller is the owner of the token
    if (ownerOf(_tokenId) != _owner) revert NotOwner("I721", _tokenId);

    uint256 m_numberOfEntities = _entityIds.length;
    for (uint256 i = 0; i < m_numberOfEntities; ) {
      // Set the subscription for each entity ID with the corresponding default URI
      s_tokenSubscriptions[_tokenId][_entityIds[i]] = TokenSubscriptionInfo(true, _entityDefaultUris[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Updates the URI of a token's entity slot.
   * @param _owner The address of the token owner.
   * @param _entityId The ID of the entity slot.
   * @param _tokenId The ID of the token.
   * @param _updatedUri The updated URI for the entity slot.
   */
  function updateURISlot(
    address _owner,
    uint256 _entityId,
    uint256 _tokenId,
    string calldata _updatedUri
  ) external onlySubscriber {
    if (ownerOf(_tokenId) != _owner) revert NotOwner("I721", _tokenId);
    if (!s_tokenSubscriptions[_tokenId][_entityId].isSubscribed) revert Unsubscribed("J721", _tokenId, _entityId);
    s_tokenSubscriptions[_tokenId][_entityId].uri = _updatedUri;
  }

  /**
   * @dev Transfers the URI of a token's entity slot to a new value.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token.
   * @param _entityId The ID of the entity slot.
   * @param _transferredUri The new URI for the entity slot.
   */
  function transferTokenEntityURI(
    address _owner,
    uint256 _tokenId,
    uint256 _entityId,
    string calldata _transferredUri
  ) external onlySubscriber {
    if (ownerOf(_tokenId) != _owner) revert NotOwner("I721", _tokenId);
    if (!s_tokenSubscriptions[_tokenId][_entityId].isSubscribed) revert Unsubscribed("J721", _tokenId, _entityId);
    s_tokenSubscriptions[_tokenId][_entityId].uri = _transferredUri;
  }

  /**
   * @dev Resets the URI of a token's entity slot to its default value.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token.
   * @param _entityId The ID of the entity slot.
   * @param _entityDefaultUri The default URI for the entity slot.
   */
  function resetSlotToDefault(
    address _owner,
    uint256 _tokenId,
    uint256 _entityId,
    string calldata _entityDefaultUri
  ) external onlySubscriber {
    if (ownerOf(_tokenId) != _owner) revert NotOwner("I721", _tokenId);
    if (!s_tokenSubscriptions[_tokenId][_entityId].isSubscribed) revert Unsubscribed("J721", _tokenId, _entityId);
    s_tokenSubscriptions[_tokenId][_entityId].uri = _entityDefaultUri;
  }

  /**
   * @dev Transfers the ownership of the collection to a new owner.
   * @param newOwner The address of the new owner.
   */
  function transferOwnership(address newOwner) public override {
    uint64 m_newCollectionId = s_ownerEntity.transferCollection(newOwner, s_ID);
    s_collectionInfo.collectionId = m_newCollectionId;
    s_ID = m_newCollectionId;
    s_ownerEntity = ImQuarkEntity(newOwner);
    super.transferOwnership(newOwner);
    emit CollectionTransferred(m_newCollectionId, s_ID, newOwner);
  }

  /**
   * @dev Transfers the ownership of the collection to a new account.
   * Can only be called by the entity.
   * @param newOwner The address of the new owner.
   */
  function transferCollectionOwnership(address newOwner) external {
    if (msg.sender != address(s_ownerEntity)) revert NotAuthorized("L721");
    super.transferOwnership(newOwner);
  }

  /**
   * @dev Allows owners to withdraw their funds from the contract.
   * Can only be called by owners.
   */
  function withdraw() external onlyOwners nonReentrant {
    _withdraw(false);
  }

  /**
   * @dev Allows authorized parties to withdraw funds from the contract.
   * Can only be called by authorized parties.
   */
  function protocolWithdraw() external onlyAuthorized nonReentrant {
    _withdraw(true);
  }

  // * ============== VIEW =============== *//

  /**
   * @dev Returns the URI for a given token ID.
   *
   * @param _id The ID of the token.
   * @return The URI of the token.
   */
  function tokenURI(uint256 _id) public view virtual override returns (string memory) {
    return s_tokenUris[_id];
  }

  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return ((_interfaceId == type(ImQuarkNFT).interfaceId) || super.supportsInterface(_interfaceId));
  }

  /**
   * @dev Returns the entity URI for the given token ID and entity ID.
   *
   * @param _tokenId   The ID of the token whose entity URI is to be returned.
   * @param _entityId  The ID of the entity associated with the given token.
   *
   * @return           The URI of the given token's entity slot.
   */
  function tokenEntityURI(uint256 _tokenId, uint256 _entityId) external view returns (string memory) {
    return s_tokenSubscriptions[_tokenId][_entityId].uri;
  }

  /**
   * @return receiver        The royalty receiver address
   * @return royaltyAmount   The percentage of royalty
   */
  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    royaltyAmount = (s_royaltyPercentage * _salePrice) / 1000;
    receiver = s_royaltyReceiver;
  }

  /**
   * @dev Sets the royalty information for the contract.
   *
   * @param royaltyPercentage  The percentage of royalty to be set.
   * @param receiver           The address of the royalty receiver.
   */
  function setRoyaltyInfo(uint16 royaltyPercentage, address receiver) external onlyOwner {
    s_royaltyPercentage = royaltyPercentage;
    s_royaltyReceiver = receiver;
    emit RoyaltyInfoUpdated(royaltyPercentage, receiver);
  }

  /**
   * @dev Returns the information about the collection.
   *
   * @return entityId                The ID of the entity.
   * @return collectionId            The ID of the collection.
   * @return mintType                The type of minting.
   * @return mintPerAccountLimit     The maximum number of mints per account.
   * @return isWhitelisted           A flag indicating if the collection is whitelisted.
   * @return isFree                  A flag indicating if the collection is free.
   * @return templateId              The ID of the template.
   * @return mintCount               The number of mints.
   * @return totalSupply             The total supply of tokens.
   * @return mintPrice               The price of minting.
   * @return collectionURIs          An array of collection URIs.
   * @return verifier                The address of the verifier.
   */
  function getCollectionInfo()
    external
    view
    returns (
      uint256 entityId,
      uint64 collectionId,
      uint8 mintType,
      uint8 mintPerAccountLimit,
      bool isWhitelisted,
      bool isFree,
      uint256 templateId,
      uint256 mintCount,
      uint256 totalSupply,
      uint256 mintPrice,
      string[] memory collectionURIs,
      address verifier
    )
  {
    Collection storage m_collection = s_collectionInfo;

    return (
      m_collection.entityId,
      m_collection.collectionId,
      m_collection.mintType,
      m_collection.mintPerAccountLimit,
      m_collection.isWhitelisted,
      m_collection.isFree,
      m_collection.templateId,
      m_collection.mintCount,
      m_collection.totalSupply,
      m_collection.mintPrice,
      m_collection.collectionURIs,
      m_collection.verifier
    );
  }

  /**
   * @dev Returns the balance of the protocol.
   *
   * @return balance The balance of the protocol after deducting the owner's saved amount and calculating the royalty.
   */
  function getProtocolBalance() external view returns (uint256 balance) {
    MintRoyalty memory info = s_mintRoyaltyInfo;
    uint256 m_cleanBalance = (address(this).balance - info.savedAmountOwner);
    balance = (m_cleanBalance * s_mintRoyaltyInfo.royalty) / ROYALTY_DIVISOR;
  }

  /**
   * @dev Returns the balance of the owner.
   *
   * @return balance The balance of the owner after deducting the owner's saved amount and calculating the royalty.
   */
  function getOwnerBalance() external view returns (uint256 balance) {
    MintRoyalty memory info = s_mintRoyaltyInfo;
    uint256 m_cleanBalance = (address(this).balance - info.savedAmountOwner);
    uint256 m_royalty = (m_cleanBalance * s_mintRoyaltyInfo.royalty) / ROYALTY_DIVISOR;
    balance = m_cleanBalance - m_royalty + info.savedAmountOwner;
  }

  /**
   * @dev Returns the royalty percentage set for the protocol.
   *
   * @return royalty The royalty percentage for the protocol.
   */
  function getProtocolRoyalty() external view returns (uint256) {
    return s_mintRoyaltyInfo.royalty;
  }

  /**
   * @dev Returns information about the royalty configuration and amounts.
   *
   * @return royalty The royalty percentage set for the protocol.
   * @return withdrawnAmountByOwner The total amount withdrawn by the owner.
   * @return withdrawnAmountByProtocol The total amount withdrawn by the protocol.
   * @return savedAmountOwner The amount saved by the owner.
   * @return totalWithdrawn The total amount withdrawn overall.
   */
  function getRoyaltyInfo()
    external
    view
    returns (
      uint256 royalty,
      uint256 withdrawnAmountByOwner,
      uint256 withdrawnAmountByProtocol,
      uint256 savedAmountOwner,
      uint256 totalWithdrawn
    )
  {
    MintRoyalty storage m_mintRoyaltyInfo = s_mintRoyaltyInfo;
    return (
      m_mintRoyaltyInfo.royalty,
      m_mintRoyaltyInfo.withdrawnAmountByOwner,
      m_mintRoyaltyInfo.withdrawnAmountByProtocol,
      m_mintRoyaltyInfo.savedAmountOwner,
      m_mintRoyaltyInfo.totalWithdrawn
    );
  }

  // * ============== INTERNAL =========== *//
  /**
   * @notice This function checks the validity of a given signature by verifying that it is signed by the given signer.
   *
   * @param _signature    The signature to verify
   * @param _entityId     The ID of the entity associated with the signature
   * @param _templateId   The ID of the template associated with the signature
   * @param _collectionId The ID of the collection associated with the signature
   * @param _uri          The URI associated with the signature
   * @param _salt         The salt value
   * @return              "true" if the signature is valid
   */
  function _verifySignature(
    bytes memory _signature,
    address _verifier,
    uint256 _entityId,
    uint256 _templateId,
    uint64 _collectionId,
    string memory _uri,
    bytes memory _salt
  ) internal view returns (bool) {
    if (s_inoperativeSignatures[_signature]) revert InoperativeSignature("K721");
    bytes32 m_messageHash = keccak256(abi.encode(_verifier, _entityId, _templateId, _collectionId, _uri, _salt));
    bytes32 m_signed = ECDSA.toEthSignedMessageHash(m_messageHash);
    address m_signer = ECDSA.recover(m_signed, _signature);
    return (m_signer == s_collectionInfo.verifier);
  }

  /**
   * @dev Internal function for withdrawing funds either by the owner or by the protocol.
   *
   * @param isProtocolWithdraw A boolean indicating whether it is a protocol withdrawal or owner withdrawal.
   */
  function _withdraw(bool isProtocolWithdraw) internal {
    MintRoyalty memory info = s_mintRoyaltyInfo;
    uint256 cleanBalance = address(this).balance - info.savedAmountOwner;

    if ((cleanBalance == 0 && isProtocolWithdraw) || address(this).balance == 0) {
      revert InsufficientBalance("M721");
    }

    uint256 royalty = (cleanBalance * info.royalty) / ROYALTY_DIVISOR;
    uint256 withdrawable;
    address payable targetAddress;

    if (isProtocolWithdraw) {
      withdrawable = royalty;
      info.withdrawnAmountByProtocol += withdrawable;
      info.savedAmountOwner = cleanBalance - royalty;
    } else {
      withdrawable = cleanBalance - royalty + info.savedAmountOwner;
      info.withdrawnAmountByOwner += withdrawable;
      info.withdrawnAmountByProtocol += royalty;
      info.totalWithdrawn += royalty;
      info.savedAmountOwner = 0;
      targetAddress = payable(s_controller.getWithdrawalAddress());
    }

    info.totalWithdrawn += withdrawable;
    s_mintRoyaltyInfo = info;
    _send(payable(msg.sender), withdrawable);

    if (isProtocolWithdraw) {
      emit WithdrawProtocol(msg.sender, withdrawable, info.savedAmountOwner, info.totalWithdrawn);
    } else {
      _send(targetAddress, royalty);
      emit Withdraw(msg.sender, withdrawable, royalty, info.totalWithdrawn);
    }
  }

  /**
   * @dev Performs validity checks on the collection.
   * @return m_tempData The Collection struct containing the collection information.
   * Throws CollectionURIZero if the collection URI length is zero.
   * Throws CollectionIsSoldOut if the total supply of the collection has been reached.
   * Throws MintLimitReached if the mint per account limit has been reached for the sender.
   */
  function _validityChecks() internal view returns (Collection memory m_tempData) {
    m_tempData = s_collectionInfo;

    // Check if the collection URI length is zero
    if (m_tempData.collectionURIs.length == 0) revert CollectionURIZero("B721");

    // Check if the total supply has been reached
    if (m_tempData.totalSupply <= m_tempData.mintCount) revert CollectionIsSoldOut("C721");

    // Check if the mint per account limit has been reached for the sender
    if (m_tempData.mintPerAccountLimit != 0 && s_mintCountsPerAccount[msg.sender] == m_tempData.mintPerAccountLimit)
      revert MintLimitReached("N721");
  }

  /**
   * @dev Mints a new token.
   * @return m_tokenId The ID of the newly minted token.
   */
  function _mintToken() internal returns (uint256 m_tokenId) {
    // Increment the mint count of the collection
    s_collectionInfo.mintCount++;

    // Increment the mint count for the sender's account
    ++s_mintCountsPerAccount[msg.sender];

    // Assign the next available token ID
    m_tokenId = s_currentTokenId++;

    // Mint the token and assign ownership to the sender
    _safeMint(msg.sender, m_tokenId);
  }

  /**
   * @dev Internal function for sending Ether to a target address.
   *
   * @param target The address to which Ether will be sent.
   * @param amount The amount of Ether to send.
   */
  function _send(address payable target, uint256 amount) internal {
    (bool sent, ) = target.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "./lib/StringSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ImQuarkTemplate.sol";

contract mQuarkTemplate is AccessControl, ImQuarkTemplate {
  //* =============================== LIBRARIES ======================================================= *//
  using EnumerableSet for EnumerableSet.UintSet;

  using EnumerableSet for EnumerableSet.Bytes32Set;

  using EnumerableStringSet for EnumerableStringSet.StringSet;

  //* =============================== MAPPINGS ======================================================== *//

  // Mapping from 'category name' to 'category'
  mapping(string => Category) public categoriesByName;

  // Mapping from 'category id' to 'category'
  mapping(uint256 => Category) public categoriesById;

  // Mapping from 'selector' to 'category'
  mapping(bytes4 => Category) public categoriesBySelector;

  // Mapping from 'category' to  'template ids'
  mapping(string => EnumerableSet.UintSet) private categoryTemplates;

  // Mapping from 'template id' to 'categories'
  mapping(uint256 => EnumerableStringSet.StringSet) private templateCategories;

  // Mapping from a 'template id' to a 'template URI'
  mapping(uint256 => string) private s_templateURIs;

  //* =============================== VARIABLES ======================================================= *//

  // Stores the ids of created templates
  EnumerableSet.UintSet private s_templateIds;

  // Keeps track of the last created template id
  uint256 public s_templateIdCounter;

  // Keeps track of the last created category id
  uint256 public s_categoryCounter;

  // This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  //* =============================== CONSTRUCTOR ===================================================== *//
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
  }

  //* =============================== FUNCTIONS ======================================================= *//
  // * ============== EXTERNAL =========== *//
  /**
   *  @notice Creates a new template with the given URI, which will be inherited by collections.
   *
   * @param _uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata _uri) external onlyRole(CONTROL_ROLE) {
    uint256 m_templateId = ++s_templateIdCounter;

    s_templateURIs[m_templateId] = _uri;

    s_templateIds.add(m_templateId);

    emit TemplateCreated(m_templateId, _uri);
  }

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   *
   * @param _uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata _uris) external onlyRole(CONTROL_ROLE) {
    uint256 m_numberOfUris = _uris.length;
    if (m_numberOfUris > 255) revert ExceedsLimit();
    uint256 _templateId = s_templateIdCounter;
    for (uint8 i = 0; i < m_numberOfUris; ) {
      ++_templateId;
      s_templateURIs[_templateId] = _uris[i];
      s_templateIds.add(_templateId);
      emit TemplateCreated(_templateId, _uris[i]);

      unchecked {
        ++i;
      }
    }
    s_templateIdCounter = _templateId;
  }

  /**
   * @notice This function allows the creation of a new category.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param name The name of the category.
   * @param uri The URI associated with the category.
   */
  function createCategory(string calldata name, string calldata uri) external onlyRole(CONTROL_ROLE) {
    uint256 m_categoryId = ++s_categoryCounter;
    bytes4 selector = bytes4(keccak256(bytes(name)));
    Category memory m_category = Category(m_categoryId, selector, name, uri);
    categoriesByName[name] = m_category;
    categoriesById[m_categoryId] = m_category;
    categoriesBySelector[selector] = m_category;
    emit CategoryCreated(name, m_categoryId, selector, uri);
  }

  /**
   * @notice This function allows the creation of multiple categories in a batch.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param names An array of category names.
   * @param uris An array of URIs associated with each category.
   */
  function createBatchCategory(string[] calldata names, string[] calldata uris) external onlyRole(CONTROL_ROLE) {
    if (names.length != uris.length) revert ArrayLengthMismatch();
    uint256 m_numberOfUris = names.length;
    for (uint8 i = 0; i < m_numberOfUris; ) {
      this.createCategory(names[i], uris[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Sets the given templates to a category.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param category The category name for the templates (e.g., "vehicle").
   * @param templateIds_ An array of template IDs that will be set to the given category (e.g., [1, 2, 3]).
   */
  function setTemplateCategory(
    string calldata category,
    uint256[] calldata templateIds_
  ) external onlyRole(CONTROL_ROLE) {
    if (categoriesByName[category].id == 0) revert UnexistingCategory();
    uint256 templateLength = templateIds_.length;
    for (uint256 i = 0; i < templateLength; ) {
      if (s_templateIds.contains(templateIds_[i]) != true) revert UnexistingTemplate();
      categoryTemplates[category].add(templateIds_[i]);
      templateCategories[templateIds_[i]].add(category);
      {
        ++i;
      }
    }
    emit CategoriesSet(category, templateIds_);
  }

  /**
   * @notice Removes a given template from a given category.
   * @dev Only addresses with the `CONTROL_ROLE` are allowed to call this function.
   * @param category The category name for the template.
   * @param templateId The template ID that will be removed from the category.
   */
  function removeCategoryFromTemplate(string memory category, uint256 templateId) external onlyRole(CONTROL_ROLE) {
    categoryTemplates[category].remove(templateId);
    templateCategories[templateId].remove(category);
    emit CategoryRemoved(category, templateId);
  }

  /**
   * Templates defines what a token is. Every template id has its own properties and attributes.
   * Collections are created by templates. Inherits the properties and attributes of the template.
   *
   * @param _templateId  Template ID
   * @return             Template's URI
   * */
  function templateUri(uint256 _templateId) external view returns (string memory) {
    return s_templateURIs[_templateId];
  }

  // * ============== VIEW =============== *//
  /**
   * @notice This function returns the total number of templates that have been created.
   *
   * @return The total number of templates that have been created
   */
  function getLastTemplateId() external view returns (uint256) {
    return s_templateIds.length();
  }

  /**
   * @notice Checks if a template ID exists.
   * @param _templateId The template ID to check.
   * @return exist `true` if the template ID exists, `false` otherwise.
   */
  function isTemplateIdExist(uint256 _templateId) external view returns (bool exist) {
    exist = s_templateIds.contains(_templateId);
  }

  /**
   * @notice Retrieves all the template IDs in the given category.
   * @param category The name of the category.
   * @return An array of all the template IDs in the given category.
   */
  function getAllCategoryTemplates(string memory category) external view returns (uint256[] memory) {
    return categoryTemplates[category].values();
  }

  /**
   * @notice Retrieves a batch of template IDs in the given category, starting from the specified index.
   * @param category The name of the category.
   * @param startIndex The index of the array to start searching from.
   * @param batchLength The length of the returned array.
   * @return An array of template IDs in the given category.
   */
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) external view returns (uint256[] memory) {
    uint16 endIndex = startIndex + batchLength;
    if (batchLength + startIndex > categoryTemplates[category].length())
      endIndex = uint16(categoryTemplates[category].length());
    uint256[] memory _templateIds = new uint256[](endIndex - startIndex);
    unchecked {
      for (uint16 i = startIndex; i < endIndex; ) {
        _templateIds[i - startIndex] = categoryTemplates[category].at(i);
        ++i;
      }
    }
    return _templateIds;
  }

  /**
   * @notice Retrieves the categories that a template belongs to.
   * @param templateId The ID of the template.
   * @return An array of category names that the template belongs to.
   * @dev If the template is not in any category, it will return an empty array.
   */
  function getTemplatesCategory(uint256 templateId) external view returns (string[] memory) {
    return templateCategories[templateId].values();
  }

  /**
   * @notice Retrieves the number of templates in a given category.
   * @param category The name of the category.
   * @return The length of the category's template list.
   */
  function getCategoryTemplateLength(string calldata category) external view returns (uint256) {
    return categoryTemplates[category].length();
  }

  /**
   * @notice Retrieves the details of a category by its name.
   * @param name The name of the category.
   * @return id The ID of the category.
   * @return selector selector of the category.
   * @return uri URI of the category.
   */
  function getCategoryByName(
    string calldata name
  ) external view returns (uint256 id, bytes4 selector, string memory uri) {
    Category storage category = categoriesByName[name];
    return (category.id, category.selector, category.uri);
  }

  /**
   * @notice Retrieves the details of a category by its ID.
   * @param id The ID of the category.
   * @return selector selector of the category.
   * @return name name of the category.
   * @return uri URI of the category.
   */
  function getCategoryById(uint256 id) external view returns (bytes4 selector, string memory name, string memory uri) {
    Category storage category = categoriesById[id];
    return (category.selector, category.name, category.uri);
  }

  /**
   * @notice Retrieves the details of a category by its selector.
   * @param selector The selector of the category.
   * @return id The ID of the category.
   * @return name name of the category.
   * @return uri URI of the category.
   */
  function getCategoryBySelector(
    bytes4 selector
  ) external view returns (uint256 id, string memory name, string memory uri) {
    Category storage category = categoriesBySelector[selector];
    return (category.id, category.name, category.uri);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // unchecked {
        //     _balanceOf[from]--;

        //     _balanceOf[to]++;
        // }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        // unchecked {
        //     _balanceOf[to]++;
        // }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        // unchecked {
        //     _balanceOf[owner]--;
        // }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}