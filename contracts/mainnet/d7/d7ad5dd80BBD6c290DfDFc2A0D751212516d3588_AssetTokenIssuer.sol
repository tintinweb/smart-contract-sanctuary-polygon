// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IAssetTokenData.sol";
import "../interfaces/IAssetToken.sol";
import "./events/AssetTokenIssuerEvents.sol";

/// @title A contract built for instantly minting AssetTokens.
/// @author Swarm Markets
/// @notice Deposits the given asset in and issues the underlying AssetToken to the user.
/// @dev Normally, for minting AssetToken: minter should first call requestMint on the AssetToken
/// and then then wait for an approveMint event from the AssetToken issuer which is a role.
/// This contract sits in the AssetToken's issuer role. Because, when issuer role requests mint
/// it is automatically approved. Therefore, setting an AssetToken's issuer role as this contract's
/// address makes the minting instant for the users.
contract AssetTokenIssuer is AccessControlUpgradeable, ERC1155HolderUpgradeable, AssetTokenIssuerEvents {
    uint256 public constant BPS = 10000;
    uint256 public constant MAX_FEE_BPS = 1000;
    uint256 public constant DECIMALS = 10 ** 18;

    uint256 public feeBPS;
    string public description;
    address public custodyAddress;
    address public assetTokenAddress;
    address public assetTokenPriceFeedAddress;
    bool public isMintPaused;

    mapping(address => address) public authorizedAssetsPriceFeedAddresses;

    modifier requireAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "AssetTokenIssuer: only DEFAULT_ADMIN");
        _;
    }

    modifier requireNonEmptyAddress(address _address) {
        require(_address != address(0), "AssetTokenIssuer: passed address is address 0");
        _;
    }

    function initialize(
        string memory _description,
        uint256 _feeBPS,
        address _custodyAddress,
        address _assetTokenAddress,
        address _assetTokenPriceFeedAddress
    ) external initializer {
        require(_custodyAddress != address(0), "AssetTokenIssuer: custodyAddress is address 0");
        require(_feeBPS <= MAX_FEE_BPS, "AssetTokenIssuer: feeBPS can not be greater than 1000 BPS (10%)");
        require(_assetTokenAddress != address(0), "AssetTokenIssuer: assetTokenAddress is address 0");
        require(_assetTokenPriceFeedAddress != address(0), "AssetTokenIssuer: assetTokenPriceFeedAddress is address 0");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        description = _description;
        feeBPS = _feeBPS;
        custodyAddress = _custodyAddress;
        assetTokenAddress = _assetTokenAddress;
        assetTokenPriceFeedAddress = _assetTokenPriceFeedAddress;
        isMintPaused = false;
    }

    /// @notice Pauses mint functionality
    function pauseMint() external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AssetTokenIssuer: Only DEFAULT_ADMIN or MARKET_HOURS_MAINTAINER"
        );

        isMintPaused = true;
        emit PauseMint(block.timestamp, block.number);
    }

    /// @notice Unpauses mint functionality
    function unpauseMint() external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AssetTokenIssuer: Only DEFAULT_ADMIN or MARKET_HOURS_MAINTAINER"
        );

        isMintPaused = false;
        emit UnPauseMint(block.timestamp, block.number);
    }

    /// @notice Authorizes an asset with its USD price feed.
    /// @dev The authorized asset will be able to deposited in the mint function to get AssetToken in exchange.
    /// @param _assetAddress is the ERC-20 Token address that will be allowed to deposit in mint function.
    /// @param _usdPriceFeedAddress is the USD denominated price feed address of the given asset.
    function authorizeAsset(
        address _assetAddress,
        address _usdPriceFeedAddress
    ) external requireAdmin requireNonEmptyAddress(_assetAddress) requireNonEmptyAddress(_usdPriceFeedAddress) {
        authorizedAssetsPriceFeedAddresses[_assetAddress] = _usdPriceFeedAddress;
        emit AssetAuthorized(_assetAddress, _usdPriceFeedAddress);
    }

    /// @notice Unauthorizes an asset.
    /// @dev Unauthorized assets can't be used in mint function anymore.
    /// @param _assetAddress is the ERC-20 Token address that will be excluded from allowed assets.
    function unauthorizeAsset(address _assetAddress) external requireAdmin requireNonEmptyAddress(_assetAddress) {
        require(
            authorizedAssetsPriceFeedAddresses[_assetAddress] != address(0),
            "AssetTokenIssuer: Asset is already unauthorized"
        );
        authorizedAssetsPriceFeedAddresses[_assetAddress] = address(0);
        emit AssetUnauthorized(_assetAddress);
    }

    /// @notice Sets the AssetToken address and its USD price feed.
    /// @dev The asset token will be the underlying asset for the issuer contract and it will be minted to the user.
    /// @param _assetTokenAddress is the underlying AssetToken address that will be minted within the issuer contract.
    /// @param _usdPriceFeedAddress is the USD denominated price feed address of the given AssetToken.
    function setAssetToken(
        address _assetTokenAddress,
        address _usdPriceFeedAddress
    ) external requireAdmin requireNonEmptyAddress(_assetTokenAddress) requireNonEmptyAddress(_usdPriceFeedAddress) {
        assetTokenAddress = _assetTokenAddress;
        assetTokenPriceFeedAddress = _usdPriceFeedAddress;
        emit AssetTokenSet(_assetTokenAddress, _usdPriceFeedAddress);
    }

    /// @notice Sets the custody wallet address.
    /// @dev Custody wallet address is where issuer protocol keeps the depossitted funds.
    /// @param _custodyAddress is a wallet address that will be used as a vault for deposited assets.
    function setCustodyAddress(address _custodyAddress) external requireAdmin requireNonEmptyAddress(_custodyAddress) {
        custodyAddress = _custodyAddress;
        emit CustodyAddressSet(_custodyAddress);
    }

    /// @notice Sets the fee basis points.
    /// @dev A fee basis point is equal to 1/100th of 1 percent, which is 1 permyriad
    /// @param _feeBPS is a basis points which the issuer will use as fee. MAX VALUE is 1000 BPS = 10%
    function setFeeBPS(uint256 _feeBPS) external requireAdmin {
        require(_feeBPS <= MAX_FEE_BPS, "AssetTokenIssuer: Fee can not be greater than 1000 BPS (10%)");
        feeBPS = _feeBPS;
        emit FeeBPSSet(_feeBPS);
    }

    /// @notice Sets the underlying AssetToken's kya string.
    /// @dev Only issuer is able to set kya url of the AssetToken.
    /// @param kya is an IPFS url for the metadata JSON.
    function setKya(string memory kya) external requireAdmin {
        _getAssetToken().setKya(kya);
        emit AssetTokenKyaSet(assetTokenAddress, kya);
    }

    /// @notice Sets the description property of this contract.
    /// @dev Description is used for describing the purpose of the deployed contract.
    /// @param _description is a string used for describing the purpose of the contract.
    function setDescription(string memory _description) external requireAdmin {
        description = _description;
        emit DescriptionSet(_description);
    }

    /// @notice Calls the approveMint method of the AssetToken.
    /// @dev Approves the mint request of the AssetToken.
    /// @param mintRequestID is the previously created mint request's ID.
    /// @param referenceTo is the string for specifying the reference for this mint request.
    function approveMint(uint256 mintRequestID, string memory referenceTo) external requireAdmin {
        _getAssetToken().approveMint(mintRequestID, referenceTo);
        emit AssetTokenMintApproved(assetTokenAddress, mintRequestID, referenceTo);
    }

    /// @notice Calls the approveRedemption method of the AssetToken.
    /// @dev Approves the redemption request of the AssetToken.
    /// @param redemptionRequestID is the previously created redemption request's ID.
    /// @param approveTxID is the transaction ID
    function approveRedemption(uint256 redemptionRequestID, string memory approveTxID) external requireAdmin {
        _getAssetToken().approveRedemption(redemptionRequestID, approveTxID);
        emit AssetTokenRedemptionApproved(assetTokenAddress, redemptionRequestID, approveTxID);
    }

    /// @notice Returns the AssetToken's getCurrentRate method's result.
    /// @dev Directly calls and returns the underlying AssetToken's current interest rate.
    function getCurrentRate() public view returns (uint256) {
        return _getAssetTokenData().getCurrentRate(assetTokenAddress);
    }

    /// @notice Sets the AssetToken's interest rate.
    /// @dev Directly calls the underlying AssetToken's set interest rate method.
    /// @param interestRate is the interest rate per-second value.
    /// @param positiveInterest is indicates that if interest rate is positive or negative.
    function setInterestRate(uint256 interestRate, bool positiveInterest) external requireAdmin {
        _getAssetTokenData().setInterestRate(assetTokenAddress, interestRate, positiveInterest);
        emit AssetTokenInterestRateSet(assetTokenAddress, interestRate, positiveInterest);
    }

    /// @notice Returns the AssetToken's getInterestRate method result.
    /// @dev Directly calls the underlying AssetToken's set interest rate method.
    /// @return interestRate interest rate per seconds
    /// @return positiveInterest indicates if interest is positive or negative
    function getInterestRate() external view returns (uint256, bool) {
        return _getAssetTokenData().getInterestRate(assetTokenAddress);
    }

    /// @notice Transfers the issuer role to a new account.
    /// @dev Directly calls the underlying AssetToken's transferIssuer method.
    /// @param newIssuer is the new issuer address.
    function transferIssuer(address newIssuer) external requireAdmin {
        _getAssetTokenData().transferIssuer(assetTokenAddress, newIssuer);
        emit AssetTokenIssuerTransferred(assetTokenAddress, newIssuer);
    }

    /// @notice Sets the AssetTokenData contract of the AssetToken.
    /// @dev Directly calls the underlying AssetToken's setAssetTokenData method.
    /// @param newAssetTokenData is the new asset token data contract address.
    function setAssetTokenData(address newAssetTokenData) external requireAdmin {
        _getAssetToken().setAssetTokenData(newAssetTokenData);
        emit AssetTokenDataContractSet(assetTokenAddress, newAssetTokenData);
    }

    /// @notice Sets the minimum redemption amount of the AssetToken.
    /// @dev Directly calls the underlying AssetToken's setMinimumRedemptionAmount method.
    /// @param _minimumRedemptionAmount is the AssetToken amount that will be allowed to redeem minimum.
    function setMinimumRedemptionAmount(uint256 _minimumRedemptionAmount) external requireAdmin {
        _getAssetToken().setMinimumRedemptionAmount(_minimumRedemptionAmount);
        emit AssetTokenMinimumRedemptionAmountSet(assetTokenAddress, _minimumRedemptionAmount);
    }

    /// @notice Freezes the AssetToken contract.
    /// @dev Directly calls the underlying AssetToken's freezeContract method.
    function freezeAssetTokenContract() external requireAdmin {
        _getAssetToken().freezeContract();
        emit AssetTokenContractFrozen(assetTokenAddress);
    }

    /// @notice Unfreezes the AssetToken contract.
    /// @dev Directly calls the underlying AssetToken's unfreezeContract method.
    function unfreezeAssetTokenContract() external requireAdmin {
        _getAssetToken().unfreezeContract();
        emit AssetTokenContractUnfrozen(assetTokenAddress);
    }

    /// @notice Adds an agent to AssetTokenData contract for the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's addAgent method.
    /// @param _newAgent is the new agent address
    function addAgent(address _newAgent) external requireAdmin {
        _getAssetTokenData().addAgent(assetTokenAddress, _newAgent);
        emit AssetTokenAgentAdded(assetTokenAddress, _newAgent);
    }

    /// @notice Removes an agent from AssetTokenData contract for the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's removeAgent method.
    /// @param _agent is the agent address that will be removed.
    function removeAgent(address _agent) external requireAdmin {
        _getAssetTokenData().removeAgent(assetTokenAddress, _agent);
        emit AssetTokenAgentRemoved(assetTokenAddress, _agent);
    }

    /// @notice Blacklists an account for the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's addMemberToBlacklist method.
    /// @param _account is the address that will be blacklisted.
    function addMemberToBlacklist(address _account) external requireAdmin {
        _getAssetTokenData().addMemberToBlacklist(assetTokenAddress, _account);
        emit AssetTokenMemberBlacklistExtended(assetTokenAddress, _account);
    }

    /// @notice Removes an account from the blacklist of the AssetToken.
    /// @dev Directly calls the underlying AssetTokenData contract's removeMemberFromBlacklist method.
    /// @param _account is the address that will be removed from the blacklist.
    function removeMemberFromBlacklist(address _account) external requireAdmin {
        _getAssetTokenData().removeMemberFromBlacklist(assetTokenAddress, _account);
        emit AssetTokenMemberBlacklistReduced(assetTokenAddress, _account);
    }

    /// @notice Allows the account to make transfers on the safeguard mode.
    /// @dev Directly calls the underlying AssetTokenData contract's allowTransferOnSafeguard method.
    /// @param _account is the address that will allowed for trading on the safeguard mode.
    function allowTransferOnSafeguard(address _account) external requireAdmin {
        _getAssetTokenData().allowTransferOnSafeguard(assetTokenAddress, _account);
        emit AssetTokenTransferOnSafeguardAllowed(assetTokenAddress, _account);
    }

    /// @notice Requests minting of the AssetToken.
    /// @dev Mints the requested amount and transfers it to the destination address.
    /// @param _amount is the AssetToken amount requested.
    /// @param _destination is the address that tokens will be minted to.
    function requestMint(uint256 _amount, address _destination) external requireAdmin returns (uint256) {
        uint256 mintRequestID = _getAssetToken().requestMint(_amount, _destination);
        emit AssetTokenMintRequested(assetTokenAddress, _amount, _destination);
        return mintRequestID;
    }

    /// @notice Requests the redemption of the AssetToken.
    /// @dev It will transfer the given asset token amount to the issuer contract and then will execute the
    /// requestRedemption method which redeems the previously deposited asset.
    /// @param _assetTokenAmount is the AssetToken amount wants to be redeemed.
    /// @param _destination is the address that deposited asset will be transferred to.
    /// @return redemptionRequestID is the created redemption request's ID.
    function requestRedemption(
        uint256 _assetTokenAmount,
        string memory _destination
    ) external requireAdmin returns (uint256) {
        bool success = IERC20(assetTokenAddress).transferFrom(_msgSender(), address(this), _assetTokenAmount);
        require(success, "Transfer failed");
        uint256 redemptionRequestID = _getAssetToken().requestRedemption(_assetTokenAmount, _destination);

        emit AssetTokenRedemptionRequested(assetTokenAddress, _assetTokenAmount, _destination);
        return redemptionRequestID;
    }

    /// @notice Cancels a redemption request.
    /// @dev Calls the AssetToken's cancelRedemptionRequest method.
    /// @param _redemptionRequestID is the redemption request ID that will cancelled.
    /// @param _motive of the cancelation
    function cancelRedemptionRequest(uint256 _redemptionRequestID, string memory _motive) external {
        _getAssetToken().cancelRedemptionRequest(_redemptionRequestID, _motive);
        emit AssetTokenRedemptionRequestCancelled(assetTokenAddress, _redemptionRequestID, _motive);
    }

    /// @notice Prevents the AssetToken's transfers to a specific account on the safe guard mode.
    /// @dev Calls the AssetToken's preventTransferOnSafeguard method.
    /// @param _account is the address that will be prevented making transfers on the safe guard mode.
    function preventTransferOnSafeguard(address _account) external requireAdmin {
        _getAssetTokenData().preventTransferOnSafeguard(assetTokenAddress, _account);
        emit AssetTokenTransferOnSafeguardPrevented(assetTokenAddress, _account);
    }

    /// @notice Returns AssetTokenData contract of the AssetToken for internal usage.
    /// @dev Calls the internal utility method to easily access to the AssetTokenData contract.
    function _getAssetTokenData() private view returns (IAssetTokenData) {
        return IAssetTokenData(_getAssetToken().assetTokenDataAddress());
    }

    /// @notice Returns the AssetToken contract set in this issuer contract for internal usage.
    /// @dev Calls the internal utility method to easily access to the AssetToken contract.
    function _getAssetToken() private view returns (IAssetToken) {
        return IAssetToken(assetTokenAddress);
    }

    /// @notice Returns how much AssetToken will be minted with the given asset and amount.
    /// @dev External method to get how much AssetToken will minted with the given asset and amount-
    /// with the current interest rate included.
    /// @param asset is the authorized ERC-20 asset address.
    /// @param amount is the depositting asset's amount.
    /// @return amountToMint is the estimated amount of AssetToken.
    function getAmountToMint(address asset, uint256 amount) external view returns (uint256) {
        uint256 amountToRequest = calculateAmountToRequestMint(asset, amount);
        uint256 currentRate = getCurrentRate();

        return (amountToRequest * (DECIMALS)) / (currentRate);
    }

    /// @notice Returns how much AssetToken needs to be requested from the AssetToken contract.
    /// @dev Utility method to calculate the value that will be requested for the minting without the interest rate.
    /// @param asset is the authorized ERC-20 asset address.
    /// @param amount is the depositting asset's amount.
    /// @return amountToRequest is the calculated AssetToken amount.
    function calculateAmountToRequestMint(address asset, uint256 amount) public view returns (uint256) {
        uint256 fee = (amount * (feeBPS)) / (BPS);
        uint256 feeDeductedAmount = amount - (fee);

        (, int256 assetTokenPrice, , , ) = AggregatorV3Interface(assetTokenPriceFeedAddress).latestRoundData();
        (, int256 assetPrice, , , ) = AggregatorV3Interface(authorizedAssetsPriceFeedAddresses[asset])
            .latestRoundData();

        uint256 assetDecimals = IERC20Metadata(asset).decimals();
        uint256 assetValue = (uint256(assetPrice) * (feeDeductedAmount)) / (10 ** assetDecimals);
        uint256 amountToRequest = (assetValue * (DECIMALS)) / (uint256(assetTokenPrice));

        return amountToRequest;
    }

    /// @notice Instantly mints AssetTokens for the account that calls this method.
    /// @dev This method will transfer the given asset in to the custody address.
    /// Then it calls the requestMint function of the AssetToken with the calculated amount to mint.
    /// Since, this contract is holding the issuer role of the AssetToken; it will instantly accept the request mint.
    /// @param asset is the authorized ERC-20 asset address.
    /// @param amount is the depositting asset's amount.
    function mint(address asset, uint256 amount, uint256 minExpectedAmount) external requireNonEmptyAddress(asset) {
        require(isMintPaused == false, "AssetTokenIssuer: mint is paused");
        require(authorizedAssetsPriceFeedAddresses[asset] != address(0), "AssetTokenIssuer: asset is not authorized");
        require(amount > 0, "AssetTokenIssuer: amount must be > 0");
        require(minExpectedAmount > 0, "AssetTokenIssuer: minExpectedAmount must be > 0");

        uint256 amountToRequest = calculateAmountToRequestMint(asset, amount);
        uint256 amountToMint = (amountToRequest * (DECIMALS)) / (getCurrentRate());

        require(amountToMint >= minExpectedAmount, "AssetTokenIssuer: amountToMint must be >= minExpectedAmount");

        require(
            IERC20(asset).transferFrom(_msgSender(), custodyAddress, amount),
            "AssetTokenIssuer: transfer to custody failed"
        );

        IAssetToken(assetTokenAddress).requestMint(amountToRequest, _msgSender());

        emit AssetTokenMinted(_msgSender(), amountToMint, asset, amount);
    }

    /// @notice Gets the name of the contract.
    /// @dev Contract name can be used to differentiate if issuer is an AssetTokenIssuer contract.
    /// @return name of the contract.
    function name() external pure returns (string memory) {
        return "AssetTokenIssuer";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Events for Asset Token issuer contracts.
/// @author Swarm Markets
contract AssetTokenIssuerEvents {
    event AssetTokenMinted(
        address indexed to,
        uint256 amount,
        address indexed depositingAsset,
        uint256 depositingAssetAmount
    );
    event AssetAuthorized(address indexed asset, address priceFeed);
    event AssetUnauthorized(address indexed asset);
    event AssetTokenSet(address assetToken, address priceFeed);
    event CustodyAddressSet(address custody);
    event FeeBPSSet(uint256 feeBPS);
    event AssetTokenKyaSet(address assetToken, string kya);
    event DescriptionSet(string description);
    event AssetTokenMintApproved(address assetToken, uint256 mintRequestID, string referenceTo);
    event AssetTokenRedemptionApproved(address assetToken, uint256 redemptionRequestID, string approveTxID);
    event AssetTokenInterestRateSet(address assetToken, uint256 interestRate, bool isPositiveInterest);
    event AssetTokenIssuerTransferred(address assetToken, address newIssuer);
    event AssetTokenDataContractSet(address assetToken, address newAssetTokenData);
    event AssetTokenMinimumRedemptionAmountSet(address assetToken, uint256 minimumRedemptionAmount);
    event AssetTokenContractFrozen(address assetToken);
    event AssetTokenContractUnfrozen(address assetToken);
    event AssetTokenAgentAdded(address assetToken, address newAgent);
    event AssetTokenAgentRemoved(address assetToken, address agent);
    event AssetTokenMemberBlacklistExtended(address assetToken, address account);
    event AssetTokenMemberBlacklistReduced(address assetToken, address account);
    event AssetTokenTransferOnSafeguardAllowed(address assetToken, address account);
    event AssetTokenMintRequested(address assetToken, uint256 amount, address destination);
    event AssetTokenRedemptionRequested(address assetToken, uint256 assetTokenAmount, string destination);
    event AssetTokenRedemptionRequestCancelled(address assetToken, uint256 redemptionRequestID, string motive);
    event AssetTokenTransferOnSafeguardPrevented(address assetToken, address account);
    event PauseMint(uint256 timestamp, uint256 blocknumber);
    event UnPauseMint(uint256 timestamp, uint256 blocknumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAssetToken {
    function assetTokenDataAddress() external view returns (address);

    function requestMint(uint256 _amount, address _destination) external returns (uint256);

    function approveMint(uint256 _mintRequestID, string memory _referenceTo) external;

    function approveRedemption(uint256 _redemptionRequestID, string memory _approveTxID) external;

    function setKya(string memory _kya) external;

    function setAssetTokenData(address _newAddress) external;

    function setMinimumRedemptionAmount(uint256 _minimumRedemptionAmount) external;

    function freezeContract() external;

    function unfreezeContract() external;

    function requestRedemption(uint256 _assetTokenAmount, string memory _destination) external returns (uint256);

    function cancelRedemptionRequest(uint256 _redemptionRequestID, string memory _motive) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @author Swarm Markets
/// @title
/// @notice
/// @notice

interface IAssetTokenData {
    function getIssuer(address _tokenAddress) external view returns (address);

    function getGuardian(address _tokenAddress) external view returns (address);

    function setContractToSafeguard(address _tokenAddress) external returns (bool);

    function freezeContract(address _tokenAddress) external returns (bool);

    function unfreezeContract(address _tokenAddress) external returns (bool);

    function isOnSafeguard(address _tokenAddress) external view returns (bool);

    function isContractFrozen(address _tokenAddress) external view returns (bool);

    function beforeTokenTransfer(address, address) external;

    function onlyStoredToken(address _tokenAddress) external view;

    function onlyActiveContract(address _tokenAddress) external view;

    function onlyUnfrozenContract(address _tokenAddress) external view;

    function onlyIssuer(address _tokenAddress, address _functionCaller) external view;

    function onlyIssuerOrGuardian(address _tokenAddress, address _functionCaller) external view;

    function onlyIssuerOrAgent(address _tokenAddress, address _functionCaller) external view;

    function checkIfTransactionIsAllowed(
        address _caller,
        address _from,
        address _to,
        address _tokenAddress,
        bytes4 _operation,
        bytes calldata _data
    ) external view returns (bool);

    function mustBeAuthorizedHolders(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function update(address _tokenAddress) external;

    function getCurrentRate(address _tokenAddress) external view returns (uint256);

    function getInterestRate(address _tokenAddress) external view returns (uint256, bool);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function isAllowedTransferOnSafeguard(address _tokenAddress, address _account) external view returns (bool);

    function registerAssetToken(address _tokenAddress, address _issuer, address _guardian) external returns (bool);

    function transferIssuer(address _tokenAddress, address _newIssuer) external;

    function setInterestRate(address _tokenAddress, uint256 _interestRate, bool _positiveInterest) external;

    function addAgent(address _tokenAddress, address _newAgent) external;

    function removeAgent(address _tokenAddress, address _agent) external;

    function addMemberToBlacklist(address _tokenAddress, address _account) external;

    function removeMemberFromBlacklist(address _tokenAddress, address _account) external;

    function allowTransferOnSafeguard(address _tokenAddress, address _account) external;

    function preventTransferOnSafeguard(address _tokenAddress, address _account) external;
}