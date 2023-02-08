// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "AccessControl.sol";
import "Initializable.sol";
import "IERC20.sol";
import "EnumerableSet.sol";

import "Product.sol";
import "IERC1155MetadataURI.sol";
import "IERC20Metadata.sol";

import "CoorestProduct.sol";

contract CoorestProductCo2 is 
    CoorestProduct
{
    event LogCoorestCo2PolicyCreated(
                bytes32 processId,
                address policyHolder,
                uint256 nftreeId,
                uint256 duration,
                uint256 sumInsured,
                uint256 premium
            );

    constructor(
        bytes32 name,
        address token,
        uint256 oracleId,
        uint256 riskpoolId,
        address registry
    )
        CoorestProduct(name, token, oracleId, riskpoolId, registry)
    { }

    // sum insured derived from nftreeId via CoorestMeta.TokenInfo
    function newCo2Policy(
        address nftreeHolder,
        uint256 nftreeId,
        uint256 duration
    )
        external
        returns(
            bytes32 processId,
            uint256 premium
        )
    {
        address policyHolder = msg.sender;
        CoorestMeta.TokenInfo memory info  = _coorestMeta.getToken(nftreeId);
        uint256 sumInsured = info.co2absorbed * 10 ** _tokenContract.decimals();
        (
            processId,
            premium
        ) = applyForPolicy(
            policyHolder,
            nftreeHolder,
            nftreeId,
            duration,
            sumInsured);

        emit LogCoorestCo2PolicyCreated(processId, policyHolder, nftreeId, duration, sumInsured, premium);
    }

    function calculatePremium(uint256 nftreeId, uint256 sumInsured, uint256 duration) public override view returns(uint256 premium) {
        return sumInsured * _premiumFraction / PERCENTAGE_MULTIPLIER + _premiumFixed;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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

import "IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IProduct.sol";
import "Component.sol";
import "IPolicy.sol";
import "IInstanceService.sol";
import "IProductService.sol";

abstract contract Product is
    IProduct, 
    Component 
{
    string public constant DEFAULT_DATA_STRUCTURE = "";

    address private _policyFlow; // policy flow contract to use for this procut
    address private _token; // erc20 token to use for this product
    uint256 private _riskpoolId; // id of riskpool responsible for this product

    IProductService internal _productService;
    IInstanceService internal _instanceService;

    modifier onlyPolicyHolder(bytes32 policyId) {
        address policyHolder = _instanceService.getMetadata(policyId).owner;
        require(
            _msgSender() == policyHolder, 
            "ERROR:PRD-001:POLICY_OR_HOLDER_INVALID"
        );
        _;
    }

    modifier onlyLicence {
        require(
             _msgSender() == _getContractAddress("Licence"),
            "ERROR:PRD-002:ACCESS_DENIED"
        );
        _;
    }

    modifier onlyOracle {
        require(
             _msgSender() == _getContractAddress("Query"),
            "ERROR:PRD-003:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        bytes32 name,
        address token,
        bytes32 policyFlow,
        uint256 riskpoolId,
        address registry
    )
        Component(name, ComponentType.Product, registry)
    {
        _token = token;
        _riskpoolId = riskpoolId;

        // TODO add validation for policy flow
        _policyFlow = _getContractAddress(policyFlow);
        _productService = IProductService(_getContractAddress("ProductService"));
        _instanceService = IInstanceService(_getContractAddress("InstanceService"));

        emit LogProductCreated(address(this));
    }

    function getToken() public override view returns(address) {
        return _token;
    }

    function getPolicyFlow() public view override returns(address) {
        return _policyFlow;
    }

    function getRiskpoolId() public override view returns(uint256) {
        return _riskpoolId;
    }

    // default callback function implementations
    function _afterApprove() internal override { emit LogProductApproved(getId()); }

    function _afterPropose() internal override { emit LogProductProposed(getId()); }
    function _afterDecline() internal override { emit LogProductDeclined(getId()); }

    function _newApplication(
        address applicationOwner,
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes memory metaData, 
        bytes memory applicationData 
    )
        internal
        returns(bytes32 processId)
    {
        processId = _productService.newApplication(
            applicationOwner, 
            premiumAmount, 
            sumInsuredAmount, 
            metaData, 
            applicationData);
    }

    function _collectPremium(bytes32 processId) 
        internal
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        IPolicy.Policy memory policy = _getPolicy(processId);

        if (policy.premiumPaidAmount < policy.premiumExpectedAmount) {
            (success, feeAmount, netAmount) 
                = _collectPremium(
                    processId, 
                    policy.premiumExpectedAmount - policy.premiumPaidAmount
                );
        }
    }

    function _collectPremium(
        bytes32 processId,
        uint256 amount
    )
        internal
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        (success, feeAmount, netAmount) = _productService.collectPremium(processId, amount);
    }

    function _adjustPremiumSumInsured(
        bytes32 processId,
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) internal {
        _productService.adjustPremiumSumInsured(processId, expectedPremiumAmount, sumInsuredAmount);
    }

    function _revoke(bytes32 processId) internal {
        _productService.revoke(processId);
    }

    function _underwrite(bytes32 processId) internal returns(bool success) {
        success = _productService.underwrite(processId);
    }

    function _decline(bytes32 processId) internal {
        _productService.decline(processId);
    }

    function _expire(bytes32 processId) internal {
        _productService.expire(processId);
    }

    function _close(bytes32 processId) internal {
        _productService.close(processId);
    }

    function _newClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes memory data
    ) 
        internal
        returns (uint256 claimId)
    {
        claimId = _productService.newClaim(
            processId, 
            claimAmount, 
            data);
    }

    function _confirmClaim(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount
    )
        internal
    {
        _productService.confirmClaim(
            processId, 
            claimId, 
            payoutAmount);
    }

    function _declineClaim(bytes32 processId, uint256 claimId) internal {
        _productService.declineClaim(processId, claimId);
    }

    function _closeClaim(bytes32 processId, uint256 claimId) internal {
        _productService.closeClaim(processId, claimId);
    }

    function _newPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 amount,
        bytes memory data
    )
        internal
        returns(uint256 payoutId)
    {
        payoutId = _productService.newPayout(processId, claimId, amount, data);
    }

    function _processPayout(
        bytes32 processId,
        uint256 payoutId
    )
        internal
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        )
    {
        (
            feeAmount,
            netPayoutAmount
        ) = _productService.processPayout(processId, payoutId);
    }

    function _request(
        bytes32 processId,
        bytes memory input,
        string memory callbackMethodName,
        uint256 responsibleOracleId
    )
        internal
        returns (uint256 requestId)
    {
        requestId = _productService.request(
            processId,
            input,
            callbackMethodName,
            address(this),
            responsibleOracleId
        );
    }

    function _cancelRequest(uint256 requestId)
        internal
    {
        _productService.cancelRequest(requestId);
    }

    function _getMetadata(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Metadata memory metadata) 
    {
        return _instanceService.getMetadata(processId);
    }

    function _getApplication(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Application memory application) 
    {
        return _instanceService.getApplication(processId);
    }

    function _getPolicy(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Policy memory policy) 
    {
        return _instanceService.getPolicy(processId);
    }

    function _getClaim(bytes32 processId, uint256 claimId) 
        internal 
        view 
        returns (IPolicy.Claim memory claim) 
    {
        return _instanceService.getClaim(processId, claimId);
    }

    function _getPayout(bytes32 processId, uint256 payoutId) 
        internal 
        view 
        returns (IPolicy.Payout memory payout) 
    {
        return _instanceService.getPayout(processId, payoutId);
    }

    function getApplicationDataStructure() external override virtual pure returns(string memory dataStructure) {
        return DEFAULT_DATA_STRUCTURE;
    }

    function getClaimDataStructure() external override virtual pure returns(string memory dataStructure) {
        return DEFAULT_DATA_STRUCTURE;
    }

    function getPayoutDataStructure() external override virtual pure returns(string memory dataStructure) {
        return DEFAULT_DATA_STRUCTURE;
    }

    function riskPoolCapacityCallback(uint256 capacity) external override virtual { }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IProduct is IComponent {

    event LogProductCreated (address productAddress);
    event LogProductProposed (uint256 componentId);
    event LogProductApproved (uint256 componentId);
    event LogProductDeclined (uint256 componentId);

    function getToken() external view returns(address token);
    function getPolicyFlow() external view returns(address policyFlow);
    function getRiskpoolId() external view returns(uint256 riskpoolId);

    function getApplicationDataStructure() external view returns(string memory dataStructure);
    function getClaimDataStructure() external view returns(string memory dataStructure);
    function getPayoutDataStructure() external view returns(string memory dataStructure);

    function riskPoolCapacityCallback(uint256 capacity) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IRegistry.sol";

interface IComponent {

    enum ComponentType {
        Oracle,
        Product,
        Riskpool
    }

    enum ComponentState {
        Created,
        Proposed,
        Declined,
        Active,
        Paused,
        Suspended,
        Archived
    }

    event LogComponentCreated (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        address registryAddress);

    function setId(uint256 id) external;

    function getName() external view returns(bytes32);
    function getId() external view returns(uint256);
    function getType() external view returns(ComponentType);
    function getState() external view returns(ComponentState);
    function getOwner() external view returns(address);

    function isProduct() external view returns(bool);
    function isOracle() external view returns(bool);
    function isRiskpool() external view returns(bool);

    function getRegistry() external view returns(IRegistry);

    function proposalCallback() external;
    function approvalCallback() external; 
    function declineCallback() external;
    function suspendCallback() external;
    function resumeCallback() external;
    function pauseCallback() external;
    function unpauseCallback() external;
    function archiveCallback() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRegistry {

    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);

    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);

    function ensureSender(address sender, bytes32 _contractName) external view returns(bool _senderMatches);

    function contracts() external view returns (uint256 _numberOfContracts);

    function contractName(uint256 idx) external view returns (bytes32 _contractName);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";
import "IAccess.sol";
import "IComponentEvents.sol";
import "IRegistry.sol";
import "IComponentOwnerService.sol";
import "IInstanceService.sol";
import "Ownable.sol";


// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/GUIDELINES.md#style-guidelines
abstract contract Component is 
    IComponent,
    IComponentEvents,
    Ownable 
{
    bytes32 private _componentName;
    uint256 private _componentId;
    IComponent.ComponentType private _componentType;

    IRegistry private _registry;
    IAccess private _access;
    IComponentOwnerService private _componentOwnerService;
    IInstanceService private _instanceService;

    modifier onlyInstanceOperatorService() {
        require(
             _msgSender() == _getContractAddress("InstanceOperatorService"),
            "ERROR:CMP-001:NOT_INSTANCE_OPERATOR_SERVICE");
        _;
    }

    modifier onlyComponent() {
        require(
             _msgSender() == _getContractAddress("Component"),
            "ERROR:CMP-002:NOT_COMPONENT");
        _;
    }

    modifier onlyComponentOwnerService() {
        require(
             _msgSender() == address(_componentOwnerService),
            "ERROR:CMP-003:NOT_COMPONENT_OWNER_SERVICE");
        _;
    }

    constructor(
        bytes32 name,
        IComponent.ComponentType componentType,
        address registry
    )
        Ownable()
    {
        require(registry != address(0), "ERROR:CMP-004:REGISTRY_ADDRESS_ZERO");

        _registry = IRegistry(registry);
        _access = _getAccess();
        _componentOwnerService = _getComponentOwnerService();
        _instanceService = _getInstanceService();

        _componentName = name;
        _componentType = componentType;

        emit LogComponentCreated(
            _componentName, 
            _componentType, 
            address(this), 
            address(_registry));
    }

    function setId(uint256 id) external override onlyComponent { _componentId = id; }

    function getName() public override view returns(bytes32) { return _componentName; }
    function getId() public override view returns(uint256) { return _componentId; }
    function getType() public override view returns(IComponent.ComponentType) { return _componentType; }
    function getState() public override view returns(IComponent.ComponentState) { return _instanceService.getComponentState(_componentId); }
    function getOwner() public override view returns(address) { return owner(); }

    function isProduct() public override view returns(bool) { return _componentType == IComponent.ComponentType.Product; }
    function isOracle() public override view returns(bool) { return _componentType == IComponent.ComponentType.Oracle; }
    function isRiskpool() public override view returns(bool) { return _componentType == IComponent.ComponentType.Riskpool; }

    function getRegistry() external override view returns(IRegistry) { return _registry; }

    function proposalCallback() public override onlyComponent { _afterPropose(); }
    function approvalCallback() public override onlyComponent { _afterApprove(); }
    function declineCallback() public override onlyComponent { _afterDecline(); }
    function suspendCallback() public override onlyComponent { _afterSuspend(); }
    function resumeCallback() public override onlyComponent { _afterResume(); }
    function pauseCallback() public override onlyComponent { _afterPause(); }
    function unpauseCallback() public override onlyComponent { _afterUnpause(); }
    function archiveCallback() public override onlyComponent { _afterArchive(); }
    
    // these functions are intended to be overwritten to implement
    // component specific notification handling
    function _afterPropose() internal virtual {}
    function _afterApprove() internal virtual {}
    function _afterDecline() internal virtual {}
    function _afterSuspend() internal virtual {}
    function _afterResume() internal virtual {}
    function _afterPause() internal virtual {}
    function _afterUnpause() internal virtual {}
    function _afterArchive() internal virtual {}

    function _getAccess() internal view returns (IAccess) {
        return IAccess(_getContractAddress("Access"));        
    }

    function _getInstanceService() internal view returns (IInstanceService) {
        return IInstanceService(_getContractAddress("InstanceService"));        
    }

    function _getComponentOwnerService() internal view returns (IComponentOwnerService) {
        return IComponentOwnerService(_getContractAddress("ComponentOwnerService"));        
    }

    function _getContractAddress(bytes32 contractName) internal view returns (address) { 
        return _registry.getContract(contractName);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IAccess {
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns(bool);

    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;
    function renounceRole(bytes32 role, address principal) external;
    
    function addRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IComponentEvents {

    event LogComponentProposed (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        uint256 id);
    
    event LogComponentApproved (uint256 id);
    event LogComponentDeclined (uint256 id);

    event LogComponentSuspended (uint256 id);
    event LogComponentResumed (uint256 id);

    event LogComponentPaused (uint256 id);
    event LogComponentUnpaused (uint256 id);

    event LogComponentArchived (uint256 id);

    event LogComponentStateChanged (
        uint256 id, 
        IComponent.ComponentState stateOld, 
        IComponent.ComponentState stateNew);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IComponentOwnerService {

    function propose(IComponent component) external;

    function stake(uint256 id) external;
    function withdraw(uint256 id) external;

    function pause(uint256 id) external; 
    function unpause(uint256 id) external;

    function archive(uint256 id) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";
import "IBundle.sol";
import "IPolicy.sol";
import "IPool.sol";
import "IBundleToken.sol";
import "IComponentOwnerService.sol";
import "IInstanceOperatorService.sol";
import "IOracleService.sol";
import "IProductService.sol";
import "IRiskpoolService.sol";

import "IERC20.sol";
import "IERC721.sol";

interface IInstanceService {

    // instance
    function getChainId() external view returns(uint256 chainId);
    function getChainName() external view returns(string memory chainName);
    function getInstanceId() external view returns(bytes32 instanceId);
    function getInstanceOperator() external view returns(address instanceOperator);

    // registry
    function getComponentOwnerService() external view returns(IComponentOwnerService service);
    function getInstanceOperatorService() external view returns(IInstanceOperatorService service);
    function getOracleService() external view returns(IOracleService service);
    function getProductService() external view returns(IProductService service);
    function getRiskpoolService() external view returns(IRiskpoolService service);
    function contracts() external view returns (uint256 numberOfContracts);
    function contractName(uint256 idx) external view returns (bytes32 name);

    // access
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns (bool roleIsAssigned);    

    // component
    function products() external view returns(uint256 numberOfProducts);
    function oracles() external view returns(uint256 numberOfOracles);
    function riskpools() external view returns(uint256 numberOfRiskpools);

    function getComponentId(address componentAddress) external view returns(uint256 componentId);
    function getComponent(uint256 componentId) external view returns(IComponent component);
    function getComponentType(uint256 componentId) external view returns(IComponent.ComponentType componentType);
    function getComponentState(uint256 componentId) external view returns(IComponent.ComponentState componentState);

    // service staking
    function getStakingRequirements(uint256 componentId) external view returns(bytes memory data);
    function getStakedAssets(uint256 componentId) external view returns(bytes memory data);

    // riskpool
    function getRiskpool(uint256 riskpoolId) external view returns(IPool.Pool memory riskPool);
    function getFullCollateralizationLevel() external view returns (uint256);
    function getCapital(uint256 riskpoolId) external view returns(uint256 capitalAmount);
    function getTotalValueLocked(uint256 riskpoolId) external view returns(uint256 totalValueLockedAmount);
    function getCapacity(uint256 riskpoolId) external view returns(uint256 capacityAmount);
    function getBalance(uint256 riskpoolId) external view returns(uint256 balanceAmount);

    function activeBundles(uint256 riskpoolId) external view returns(uint256 numberOfActiveBundles);
    function getActiveBundleId(uint256 riskpoolId, uint256 bundleIdx) external view returns(uint256 bundleId);
    function getMaximumNumberOfActiveBundles(uint256 riskpoolId) external view returns(uint256 maximumNumberOfActiveBundles);

    // bundles
    function getBundleToken() external view returns(IBundleToken token);
    function bundles() external view returns(uint256 numberOfBundles);
    function getBundle(uint256 bundleId) external view returns(IBundle.Bundle memory bundle);
    function unburntBundles(uint256 riskpoolId) external view returns(uint256 numberOfUnburntBundles);

    // policy
    function processIds() external view returns(uint256 numberOfProcessIds);
    function getMetadata(bytes32 processId) external view returns(IPolicy.Metadata memory metadata);
    function getApplication(bytes32 processId) external view returns(IPolicy.Application memory application);
    function getPolicy(bytes32 processId) external view returns(IPolicy.Policy memory policy);
    function claims(bytes32 processId) external view returns(uint256 numberOfClaims);
    function payouts(bytes32 processId) external view returns(uint256 numberOfPayouts);

    function getClaim(bytes32 processId, uint256 claimId) external view returns (IPolicy.Claim memory claim);
    function getPayout(bytes32 processId, uint256 payoutId) external view returns (IPolicy.Payout memory payout);

    // treasury
    function getTreasuryAddress() external view returns(address treasuryAddress);
 
    function getInstanceWallet() external view returns(address walletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address walletAddress);
 
    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeFractionFullUnit() external view returns(uint256 fullUnit);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IBundle {

    event LogBundleCreated(
        uint256 bundleId, 
        uint256 riskpoolId, 
        address owner,
        BundleState state,
        uint256 amount
    );

    event LogBundleStateChanged(uint256 bundleId, BundleState oldState, BundleState newState);

    event LogBundleCapitalProvided(uint256 bundleId, address sender, uint256 amount, uint256 capacity);
    event LogBundleCapitalWithdrawn(uint256 bundleId, address recipient, uint256 amount, uint256 capacity);

    event LogBundlePolicyCollateralized(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);
    event LogBundlePayoutProcessed(uint256 bundleId, bytes32 processId, uint256 amount);
    event LogBundlePolicyReleased(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);

    enum BundleState {
        Active,
        Locked,
        Closed,
        Burned
    }

    struct Bundle {
        uint256 id;
        uint256 riskpoolId;
        uint256 tokenId;
        BundleState state;
        bytes filter; // required conditions for applications to be considered for collateralization by this bundle
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function create(address owner_, uint256 riskpoolId_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fund(uint256 bundleId, uint256 amount) external;
    function defund(uint256 bundleId, uint256 amount) external;

    function lock(uint256 bundleId) external;
    function unlock(uint256 bundleId) external;
    function close(uint256 bundleId) external;
    function burn(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPolicy {

    // Events
    event LogMetadataCreated(
        address owner,
        bytes32 processId,
        uint256 productId, 
        PolicyFlowState state
    );

    event LogMetadataStateChanged(
        bytes32 processId, 
        PolicyFlowState state
    );

    event LogApplicationCreated(
        bytes32 processId, 
        uint256 premiumAmount, 
        uint256 sumInsuredAmount
    );

    event LogApplicationRevoked(bytes32 processId);
    event LogApplicationUnderwritten(bytes32 processId);
    event LogApplicationDeclined(bytes32 processId);

    event LogPolicyCreated(bytes32 processId);
    event LogPolicyExpired(bytes32 processId);
    event LogPolicyClosed(bytes32 processId);

    event LogPremiumCollected(bytes32 processId, uint256 amount);
    
    event LogApplicationSumInsuredAdjusted(bytes32 processId, uint256 sumInsuredAmountOld, uint256 sumInsuredAmount);
    event LogApplicationPremiumAdjusted(bytes32 processId, uint256 premiumAmountOld, uint256 premiumAmount);
    event LogPolicyPremiumAdjusted(bytes32 processId, uint256 premiumExpectedAmountOld, uint256 premiumExpectedAmount);

    event LogClaimCreated(bytes32 processId, uint256 claimId, uint256 claimAmount);
    event LogClaimConfirmed(bytes32 processId, uint256 claimId, uint256 confirmedAmount);
    event LogClaimDeclined(bytes32 processId, uint256 claimId);
    event LogClaimClosed(bytes32 processId, uint256 claimId);

    event LogPayoutCreated(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutId,
        uint256 amount
    );

    event LogPayoutProcessed(
        bytes32 processId, 
        uint256 payoutId
    );

    // States
    enum PolicyFlowState {Started, Active, Finished}
    enum ApplicationState {Applied, Revoked, Underwritten, Declined}
    enum PolicyState {Active, Expired, Closed}
    enum ClaimState {Applied, Confirmed, Declined, Closed}
    enum PayoutState {Expected, PaidOut}

    // Objects
    struct Metadata {
        address owner;
        uint256 productId;
        PolicyFlowState state;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        ApplicationState state;
        uint256 premiumAmount;
        uint256 sumInsuredAmount;
        bytes data; 
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Policy {
        PolicyState state;
        uint256 premiumExpectedAmount;
        uint256 premiumPaidAmount;
        uint256 claimsCount;
        uint256 openClaimsCount;
        uint256 payoutMaxAmount;
        uint256 payoutAmount;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Claim {
        ClaimState state;
        uint256 claimAmount;
        uint256 paidAmount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Payout {
        uint256 claimId;
        PayoutState state;
        uint256 amount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function createPolicyFlow(
        address owner,
        uint256 productId, 
        bytes calldata data
    ) external returns(bytes32 processId);

    function createApplication(
        bytes32 processId, 
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata data
    ) external;

    function revokeApplication(bytes32 processId) external;
    function underwriteApplication(bytes32 processId) external;
    function declineApplication(bytes32 processId) external;

    function collectPremium(bytes32 processId, uint256 amount) external;

    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function createPolicy(bytes32 processId) external;
    function expirePolicy(bytes32 processId) external;
    function closePolicy(bytes32 processId) external;

    function createClaim(
        bytes32 processId, 
        uint256 claimAmount, 
        bytes calldata data
    ) external returns (uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function createPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount,
        bytes calldata data
    ) external returns (uint256 payoutId);

    function processPayout(
        bytes32 processId,
        uint256 payoutId
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPool {

    event LogRiskpoolRegistered(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token, 
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    );
    
    event LogRiskpoolRequiredCollateral(bytes32 processId, uint256 sumInsured, uint256 collateral);
    event LogRiskpoolCollateralizationFailed(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralizationSucceeded(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralReleased(uint256 riskpoolId, bytes32 processId, uint256 amount);

    struct Pool {
        uint256 id; // matches component id of riskpool
        address wallet; // riskpool wallet
        address erc20Token; // the value token of the riskpool
        uint256 collateralizationLevel; // required collateralization level to cover new policies 
        uint256 sumOfSumInsuredCap; // max sum of sum insured the pool is allowed to secure
        uint256 sumOfSumInsuredAtRisk; // current sum of sum insured at risk in this pool
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function registerRiskpool(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token,
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    ) external;

    function setRiskpoolForProduct(uint256 productId, uint256 riskpoolId) external;

    function underwrite(bytes32 processId) external returns(bool success);
    function processPremium(bytes32 processId, uint256 amount) external;
    function processPayout(bytes32 processId, uint256 amount) external;
    function release(bytes32 processId) external; 
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IERC721.sol";

interface IBundleToken is
    IERC721
{
    event LogBundleTokenMinted(uint256 bundleId, uint256 tokenId, address tokenOwner);
    event LogBundleTokenBurned(uint256 bundleId, uint256 tokenId);   

    function burned(uint tokenId) external view returns(bool isBurned);
    function exists(uint256 tokenId) external view returns(bool doesExist);
    function getBundleId(uint256 tokenId) external view returns(uint256 bundleId);
    function totalSupply() external view returns(uint256 tokenCount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "ITreasury.sol";

interface IInstanceOperatorService {

    // registry
    function prepareRelease(bytes32 newRelease) external;
    function register(bytes32 contractName, address contractAddress) external;
    function deregister(bytes32 contractName) external;
    function registerInRelease(bytes32 release, bytes32 contractName, address contractAddress) external;
    function deregisterInRelease(bytes32 release, bytes32 contractName) external;

    // access
    function createRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;

    // component
    function approve(uint256 id) external;
    function decline(uint256 id) external;
    function suspend(uint256 id) external;
    function resume(uint256 id) external;
    function archive(uint256 id) external;
    
    // service staking
    function setDefaultStaking(uint16 componentType, bytes calldata data) external;
    function adjustStakingRequirements(uint256 id, bytes calldata data) external;

    // treasury
    function suspendTreasury() external;
    function resumeTreasury() external;
    
    function setInstanceWallet(address walletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address walletAddress) external;  
    function setProductToken(uint256 productId, address erc20Address) external; 

    function setPremiumFees(ITreasury.FeeSpecification calldata feeSpec) external;
    function setCapitalFees(ITreasury.FeeSpecification calldata feeSpec) external;
    
    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    ) external view returns(ITreasury.FeeSpecification memory);


}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;
import "IERC20.sol";

interface ITreasury {

    event LogTreasurySuspended();
    event LogTreasuryResumed();

    event LogTreasuryProductTokenSet(uint256 productId, uint256 riskpoolId, address erc20Address);
    event LogTreasuryInstanceWalletSet(address walletAddress);
    event LogTreasuryRiskpoolWalletSet(uint256 riskpoolId, address walletAddress);

    event LogTreasuryPremiumFeesSet(uint256 productId, uint256 fixedFee, uint256 fractionalFee);
    event LogTreasuryCapitalFeesSet(uint256 riskpoolId, uint256 fixedFee, uint256 fractionalFee);

    event LogTreasuryPremiumTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryPayoutTransferred(address riskpoolWalletAddress, address to, uint256 amount);
    event LogTreasuryCapitalTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryFeesTransferred(address from, address instanceWalletAddress, uint256 amount);
    event LogTreasuryWithdrawalTransferred(address riskpoolWalletAddress, address to, uint256 amount);

    event LogTreasuryPremiumProcessed(bytes32 processId, uint256 amount);
    event LogTreasuryPayoutProcessed(uint256 riskpoolId, address to, uint256 amount);
    event LogTreasuryCapitalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);
    event LogTreasuryWithdrawalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);

    struct FeeSpecification {
        uint256 componentId;
        uint256 fixedFee;
        uint256 fractionalFee;
        bytes feeCalculationData;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function setProductToken(uint256 productId, address erc20Address) external;

    function setInstanceWallet(address instanceWalletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address riskpoolWalletAddress) external;

    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    )
        external view returns(FeeSpecification memory feeSpec);
    
    function setPremiumFees(FeeSpecification calldata feeSpec) external;
    function setCapitalFees(FeeSpecification calldata feeSpec) external;
    
    function processPremium(bytes32 processId) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPremium(bytes32 processId, uint256 amount) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPayout(bytes32 processId, uint256 payoutId) external 
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );
    
    function processCapital(uint256 bundleId, uint256 capitalAmount) external 
        returns(
            uint256 feeAmount,
            uint256 netCapitalAmount
        );

    function processWithdrawal(uint256 bundleId, uint256 amount) external
        returns(
            uint256 feeAmount,
            uint256 netAmount
        );

    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeSpecification(uint256 componentId) external view returns(FeeSpecification memory feeSpecification);

    function getFractionFullUnit() external view returns(uint256);
    function getInstanceWallet() external view returns(address instanceWalletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address riskpoolWalletAddress);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IOracleService {

    function respond(uint256 requestId, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IProductService {

    function newApplication(
        address owner,
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata metaData, 
        bytes calldata applicationData 
    ) external returns(bytes32 processId);

    function collectPremium(bytes32 processId, uint256 amount) external
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function revoke(bytes32 processId) external;
    function underwrite(bytes32 processId) external returns(bool success);
    function decline(bytes32 processId) external;
    function expire(bytes32 processId) external;
    function close(bytes32 processId) external;

    function newClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes calldata data
    ) external returns(uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function newPayout(
        bytes32 processId, 
        uint256 claimId, 
        uint256 amount,
        bytes calldata data
    ) external returns(uint256 payoutId);

    function processPayout(bytes32 processId, uint256 payoutId) external
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );

    function request(
        bytes32 processId,
        bytes calldata data,
        string calldata callbackMethodName,
        address callbackContractAddress,
        uint256 responsibleOracleId
    ) external returns(uint256 requestId);

    function cancelRequest(uint256 requestId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRiskpoolService {

    function registerRiskpool(
        address wallet,
        address erc20Token,
        uint256 collateralization, 
        uint256 sumOfSumInsuredCap
    ) external;

    function createBundle(address owner_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);
    function defundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);

    function lockBundle(uint256 bundleId) external;
    function unlockBundle(uint256 bundleId) external;
    function closeBundle(uint256 bundleId) external;
    function burnBundle(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);

    function setMaximumNumberOfActiveBundles(uint256 riskpoolId, uint256 maxNumberOfActiveBundles) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
pragma solidity ^0.8.2;

import "AccessControl.sol";
import "Initializable.sol";
import "IERC20.sol";
import "EnumerableSet.sol";
import "IERC1155MetadataURI.sol";
import "IERC20Metadata.sol";

import "IInstanceService.sol";
import "IPolicy.sol";
import "Product.sol";

import "CoorestMeta.sol";

abstract contract CoorestProduct is 
    Product, 
    AccessControl, 
    Initializable
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant POLICY_FLOW = "PolicyDefaultFlow";
    bytes32 public constant INSURER_ROLE = keccak256("INSURER");

    uint256 public constant POLICY_DURATION = 365 * 24 * 3600;

    uint256 public constant PERCENTAGE_MULTIPLIER = 10 ** 18;
    uint256 public constant PREMIUM_FRACTION_DEFAULT = PERCENTAGE_MULTIPLIER/10;
    uint256 public constant PREMIUM_FRACTION_FIXED = 0;

    // group policy data structure
    struct Risk {
        uint256 id; // token info id (see CoorestMeta.sol)
        uint256 requestId;
        bool requestTriggered;
        uint256 responseAt;
        uint256 createdAt;
        uint256 updatedAt;
    }


    struct PolicyInfo {
        bytes32 processId;
        address policyHolder;
        address nftHolder;
        uint256 nftId;
        uint256 duration;
        address token;
        string tokenSymbol;
        uint256 sumInsured;
        uint256 premium;
        IPolicy.ApplicationState applicationState;
        IPolicy.PolicyState policyState;
        uint256 createdAt;
        uint256 expiryAt;
    }


    // IInstanceService internal _instanceService;
    CoorestMeta internal _coorestMeta;

    uint256 internal _premiumFraction;
    uint256 internal _premiumFixed;

    IERC20Metadata internal _tokenContract;
    uint256 private _oracleId;

    mapping(uint256 /* tokenId */ => Risk) private _risks;
    uint256[] private _riskIds;

    bytes32[] private _applications;
    mapping(uint256 /* riskId */ => EnumerableSet.Bytes32Set /* processIds */) private _policies;


    event LogCoorestRiskDataCreated(uint256 riskId);
    event LogCoorestRiskDataRequested(
        uint256 requestId,
        uint256 riskId
        // bytes32 regionId,
        // bytes32 plantId
    );

    event LogCoorestRiskDataReceived(
        uint256 requestId,
        uint256 riskId //,
        // TODO: maybe more risk data
    );

    event LogCoorestRiskDataRequestCancelled(
        bytes32 processId,
        uint256 requestId
    );

    event LogCoorestRiskProcessed(uint256 riskId, uint256 policies);

    event LogCoorestPolicyApplicationCreated(
        bytes32 policyId,
        address policyHolder,
        uint256 premiumAmount,
        uint256 sumInsuredAmount
    );

    event LogCoorestPolicyCreated(
        bytes32 policyId,
        address policyHolder,
        uint256 premiumAmount,
        uint256 sumInsuredAmount
    );

    event LogCoorestPolicyProcessed(bytes32 policyId);
    event LogCoorestClaimCreated(
        bytes32 policyId,
        uint256 claimId,
        uint256 payoutAmount
    );

    event LogCoorestPayoutCreated(bytes32 policyId, uint256 payoutAmount);
    constructor(
        bytes32 productName,
        address token,
        uint256 oracleId,
        uint256 riskpoolId,
        address registry
    )
        Product(productName, token, POLICY_FLOW, riskpoolId, registry)
    {
        _instanceService = _getInstanceService();
        _tokenContract = IERC20Metadata(getToken());

        _oracleId = oracleId;

        setPremiumParameters(
            PREMIUM_FRACTION_DEFAULT, 
            PREMIUM_FRACTION_FIXED);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setCoorestMeta(address coorestMeta)
        external
        onlyOwner
    {
        require(coorestMeta != address(0), "ERROR:COB-001:COOREST_META_CONTRACT_ZERO");
        _coorestMeta = CoorestMeta(coorestMeta);
    }

    function hasInsurerRole(address account) external view returns(bool) {
        return hasRole(INSURER_ROLE, account);
    }

    function grantInsurerRole(address insurer) external onlyOwner {
        _setupRole(INSURER_ROLE, insurer);
    }

    // TODO add revokeInsurerRole

    function createRisk(uint256 nftreeTokenId)
        external
        onlyRole(INSURER_ROLE)
    {
        // TODO: _validateRiskParameters(...);

        _riskIds.push(nftreeTokenId);

        Risk storage risk = _risks[nftreeTokenId];
        require(risk.createdAt == 0, "ERROR:COB-001:RISK_ALREADY_EXISTS");

        risk.id = nftreeTokenId;
        risk.createdAt = block.timestamp; // solhint-disable-line
        risk.updatedAt = block.timestamp; // solhint-disable-line

        emit LogCoorestRiskDataCreated(risk.id);
    }

    function getCoorestMeta() public view returns(CoorestMeta) {
        return _coorestMeta;
    }

    // only yearly policies for now
    function getPolicyDuration() public pure returns(uint256 oneYear) {
        return POLICY_DURATION;
    }

    function setPremiumParameters(
        uint256 premiumFraction,
        uint256 premiumFixed
    )
        public
    {
        _premiumFraction = premiumFraction;
        _premiumFixed = premiumFixed;
    }

    // assuming a fixed, yearly duration
    function calculatePremium(uint256 nftreeId, uint256 sumInsured, uint256 duration) public virtual view returns(uint256 premium);
    //  {
    //     return sumInsured * _premiumFraction / PERCENTAGE_MULTIPLIER + _premiumFixed;
    // }

    // sum insured for stablecoin: farmer chooses any amount
    // initial duration for policy 1 year
    function applyForPolicy(
        address policyHolder,
        address nftreeHolder,
        uint256 nftreeId,
        uint256 duration,
        uint256 sumInsured // needs to be checked against a cap (set by product owner)
    ) 
        public
        returns(
            bytes32 processId,
            uint256 premium
        ) 
    {
        // check holder actually has token as claimed by input param
        require(nftreeHolder != address(0), "ERROR:COB-010:HOLDER_ZERO");
        require(_coorestMeta.isNftreeTokenHolder(nftreeHolder, nftreeId), "ERROR:COB-011:NOT_HOLDER");

        // check that onchain token info available
        CoorestMeta.TokenInfo memory info = _coorestMeta.getToken(nftreeId);
        require(info.createdAt > 0, "ERROR:CC2-002:UNKNOWN_TOKEN");

        // check policy duration
        require(duration == POLICY_DURATION,"ERROR:CC2-001:DURATION_NOT_SUPPORTED");

        // check that a risk corresponding to token exists
        Risk storage risk = _risks[nftreeId];
        require(risk.createdAt > 0, "ERROR:COB-012:RISK_UNDEFINED");

        premium = calculatePremium(nftreeId, sumInsured, duration);
        bytes memory metaData = "";
        bytes memory applicationData = encodeAsApplicationData(nftreeHolder, nftreeId, duration);

        processId = _newApplication(
            policyHolder,
            premium,
            sumInsured,
            metaData,
            applicationData
        );

        // remember process id
        _applications.push(processId);

        emit LogCoorestPolicyApplicationCreated(
            processId,
            policyHolder,
            premium,
            sumInsured
        );

        bool success = _underwrite(processId);

        if (success) {
            EnumerableSet.add(_policies[nftreeId], processId);

            emit LogCoorestPolicyCreated(
                processId,
                policyHolder,
                premium,
                sumInsured
            );
        }
    }

    function encodeAsApplicationData(
        address nftreeHolder,
        uint256 nftreeId,
        uint256 duration
    )
        public
        pure
        returns(bytes memory data)
    {
        data = abi.encode(nftreeHolder, nftreeId, duration);
    }

    function decodeFromApplicationData(bytes memory data)
        public
        pure
        returns(
            address nftreeHolder,
            uint256 nftreeId,
            uint256 duration
        )
    {
        (nftreeHolder, nftreeId, duration) = abi.decode(data, (address, uint256, uint256));
    }

    function getNftInfo(bytes32 processId) external view returns(CoorestMeta.TokenInfo memory info) {
        IPolicy.Application memory application = _instanceService.getApplication(processId);
        (,uint256 nftreeId,) = decodeFromApplicationData(application.data);
        return _coorestMeta.getToken(nftreeId);
    }

    function getPolicyInfo(bytes32 processId)
        external
        view
        returns(PolicyInfo memory info)
    {
        IPolicy.Metadata memory metadata = _instanceService.getMetadata(processId);
        IPolicy.Application memory application = _instanceService.getApplication(processId);
        IPolicy.Policy memory policy = _instanceService.getPolicy(processId);

        (
            address nftreeHolder,
            uint256 nftreeId,
            uint256 duration
        ) = decodeFromApplicationData(application.data);

        return PolicyInfo(
            processId,
            metadata.owner,
            nftreeHolder,
            nftreeId,
            duration,
            address(_tokenContract),
            string(_tokenContract.symbol()),
            application.sumInsuredAmount,
            application.premiumAmount,
            application.state,
            policy.state,
            policy.createdAt,
            policy.createdAt + duration
        );
    }


    function underwrite(bytes32 processId)
        external
        onlyRole(INSURER_ROLE)
        returns (bool success)
    {
        // ensure the application for processId exists
        _getApplication(processId);
        success = _underwrite(processId);

        if (success) {
            IPolicy.Application memory application = _getApplication(processId);
            IPolicy.Metadata memory metadata = _getMetadata(processId);
            emit LogCoorestPolicyCreated(
                processId,
                metadata.owner,
                application.premiumAmount,
                application.sumInsuredAmount
            );
        }
    }

    function collectPremium(bytes32 policyId)
        external
        onlyRole(INSURER_ROLE)
        returns (
            bool success,
            uint256 fee,
            uint256 netPremium
        )
    {
        (success, fee, netPremium) = _collectPremium(policyId);
    }

    function triggerOracle(bytes32 processId)
        external
        onlyRole(INSURER_ROLE)
        returns (uint256 requestId)
    {
        Risk storage risk = _risks[_getRiskId(processId)];
        require(risk.createdAt > 0, "ERROR:CO2-010:RISK_UNDEFINED");
        require(risk.responseAt == 0, "ERROR:CO2-011:ORACLE_ALREADY_RESPONDED");

        bytes memory queryData = abi.encode(
            risk.id //,the nftree nft id
        );

        requestId = _request(processId, queryData, "oracleCallback", _oracleId);

        risk.requestId = requestId;
        risk.requestTriggered = true;
        risk.updatedAt = block.timestamp; // solhint-disable-line

        emit LogCoorestRiskDataRequested(
            requestId,
            risk.id
            // risk.regionId,
            // risk.plantId
        );
    }

    function cancelOracleRequest(bytes32 processId)
        external
        onlyRole(INSURER_ROLE)
    {
        Risk storage risk = _risks[_getRiskId(processId)];
        require(risk.createdAt > 0, "ERROR:CO2-012:RISK_UNDEFINED");
        require(
            risk.requestTriggered,
            "ERROR:CO2-013:ORACLE_REQUEST_NOT_FOUND"
        );
        require(risk.responseAt == 0, "ERROR:CO2-014:EXISTING_CALLBACK");

        _cancelRequest(risk.requestId);

        // reset request id to allow to trigger again
        risk.requestTriggered = false;
        risk.updatedAt = block.timestamp; // solhint-disable-line

        emit LogCoorestRiskDataRequestCancelled(processId, risk.requestId);
    }

    function oracleCallback(
        uint256 requestId,
        bytes32 processId,
        bytes calldata responseData
    ) external onlyOracle {
        uint256 nftreeTokenId = abi.decode( // bytes32 plantId //, // bytes32 regionId, //, // TODO: add parameters
            responseData,
            (uint256) //, bytes32, bytes32)
        ); // TODO: add more args

        uint256 riskId = _getRiskId(processId);
        require(
            riskId == nftreeTokenId, 
            "ERROR:CO2-020:RISK_ID_MISMATCH"
        );

        Risk storage risk = _risks[riskId];
        require(risk.createdAt > 0, "ERROR:CO2-021:RISK_UNDEFINED");
        require(
            risk.requestId == requestId,
            "ERROR:CO2-022:REQUEST_ID_MISMATCH"
        );
        require(risk.responseAt == 0, "ERROR:CO2-023:EXISTING_CALLBACK");

        // require(
        // TODO: check validity of response
        // );

        // update risk
        risk.responseAt = block.timestamp; // solhint-disable-line
        risk.updatedAt = block.timestamp; // solhint-disable-line

        emit LogCoorestRiskDataReceived(
            requestId,
            riskId /* TODO: add parameters here */
        );
    }

    function getOracleId() external view returns(uint256 oracleId) {
        return _oracleId;
    }


    function processPoliciesForRisk(uint256 riskId, uint256 batchSize)
        external
        onlyRole(INSURER_ROLE)
        returns (bytes32[] memory processedPolicies)
    {
        Risk memory risk = _risks[riskId];
        require(risk.responseAt > 0, "ERROR:CO2-030:ORACLE_RESPONSE_MISSING");

        uint256 elements = EnumerableSet.length(_policies[riskId]);
        if (elements == 0) {
            emit LogCoorestRiskProcessed(riskId, 0);
            return new bytes32[](0);
        }

        if (batchSize == 0) {
            batchSize = elements;
        } else {
            batchSize = min(batchSize, elements);
        }

        processedPolicies = new bytes32[](batchSize);
        uint256 elementIdx = elements - 1;

        for (uint256 i = 0; i < batchSize; i++) {
            // grab and process the last policy
            bytes32 policyId = EnumerableSet.at(
                _policies[riskId],
                elementIdx - i
            );
            processPolicy(policyId);
            processedPolicies[i] = policyId;
        }

        emit LogCoorestRiskProcessed(riskId, batchSize);
    }

    function processPolicy(bytes32 policyId) public onlyRole(INSURER_ROLE) {
        IPolicy.Application memory application = _getApplication(policyId);
        uint256 riskId = abi.decode(application.data, (uint256));
        Risk memory risk = _risks[riskId];

        require(risk.id == riskId, "ERROR:CO2-031:RISK_ID_INVALID");
        require(risk.responseAt > 0, "ERROR:CO2-032:ORACLE_RESPONSE_MISSING");
        require(
            EnumerableSet.contains(_policies[riskId], policyId),
            "ERROR:CO2-033:POLICY_FOR_RISK_UNKNOWN"
        );

        EnumerableSet.remove(_policies[riskId], policyId);

        uint256 claimAmount = calculatePayout();
        // TODO: add risk parameters here
        // application.sumInsuredAmount

        uint256 claimId = _newClaim(policyId, claimAmount, "");
        emit LogCoorestClaimCreated(policyId, claimId, claimAmount);

        if (claimAmount > 0) {
            uint256 payoutAmount = claimAmount;
            _confirmClaim(policyId, claimId, payoutAmount);

            uint256 payoutId = _newPayout(policyId, claimId, payoutAmount, "");
            _processPayout(policyId, payoutId);

            emit LogCoorestPayoutCreated(policyId, payoutAmount);
        } else {
            _declineClaim(policyId, claimId);
            _closeClaim(policyId, claimId);
        }

        _expire(policyId);
        _close(policyId);

        emit LogCoorestPolicyProcessed(policyId);
    }

    function calculatePayout()
        public
        pure
        returns (
            // TODO: add parameters
            uint256 payoutAmount
        )
    {
        // TODO: add calculation logic
        payoutAmount = 0;
    }

    function calculatePayoutPercentage()
        public
        pure
        returns (
            // TODO: add parameters
            uint256 payoutPercentage
        )
    {
        // TODO: add calculation logic
        return 0;
    }

    function getPercentageMultiplier()
        external
        pure
        returns (uint256 multiplier)
    {
        return PERCENTAGE_MULTIPLIER;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a <= b ? a : b;
    }

    function risks() external view returns (uint256) {
        return _riskIds.length;
    }

    function getRiskId(uint256 idx) external view returns (uint256 riskId) {
        return _riskIds[idx];
    }

    function getRisk(uint256 riskId) external view returns (Risk memory risk) {
        return _risks[riskId];
    }

    function applications()
        external
        view
        returns (uint256 count)
    {
        return _applications.length;
    }

    function getApplicationId(uint256 idx)
        external
        view
        returns (bytes32 processId)
    {
        require(idx < _applications.length, "ERROR:CO2-040:INDEX_TOO_LARGE");
        return _applications[idx];
    }

    function policies(uint256 riskId)
        external
        view
        returns (uint256 policyCount)
    {
        return EnumerableSet.length(_policies[riskId]);
    }

    function getPolicyId(uint256 riskId, uint256 policyIdx)
        external
        view
        returns (bytes32 processId)
    {
        return EnumerableSet.at(_policies[riskId], policyIdx);
    }

    function getApplicationDataStructure()
        external
        pure
        override
        returns (string memory dataStructure)
    {
        return "(bytes32 riskId)";
    }

    function _validateRiskParameters() internal // add risk parameters here

    {
        // require(
        // condition,
        // message
        // );
    }

    function _processPolicy(bytes32 policyId, Risk memory risk) internal {
        IPolicy.Application memory application = _getApplication(policyId);

        uint256 claimAmount = calculatePayout();
        // TODO: add risk parameters

        uint256 claimId = _newClaim(policyId, claimAmount, "");
        emit LogCoorestClaimCreated(policyId, claimId, claimAmount);

        if (claimAmount > 0) {
            uint256 payoutAmount = claimAmount;
            _confirmClaim(policyId, claimId, payoutAmount);

            uint256 payoutId = _newPayout(policyId, claimId, payoutAmount, "");
            _processPayout(policyId, payoutId);

            emit LogCoorestPayoutCreated(policyId, payoutAmount);
        } else {
            _declineClaim(policyId, claimId);
            _closeClaim(policyId, claimId);
        }

        emit LogCoorestPolicyProcessed(policyId);
    }

    function _getRiskId(bytes32 processId)
        private
        view
        returns (uint256 riskId)
    {
        IPolicy.Application memory application = _getApplication(processId);
        (riskId) = abi.decode(application.data, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "Ownable.sol";
import "IERC1155MetadataURI.sol";
import "IERC20Metadata.sol";

contract CoorestMeta is 
    Ownable 
{
    uint256 public constant CHAIN_ID_MUMBAI = 80001;
    address public constant NFTREE_CONTRACT_MUMBAI = 0xA5cE390be1D19CC41ecB26C3174E99EAD3A3E45A;
    address public constant CO2_CONTRACT_MUMBAI = 0xEed642576C3B6497c6bC7793A61c3c620a931e68;

    // on chain data necessary to determine link to nftree project
    // and co2 sum insured
    struct TokenInfo {
        bytes32 projectId;
        uint256 tokenId; // ERC1155 token id
        uint256 co2absorbed; // kg of co2 absorbed per year
        uint256 createdAt;
    }

    IERC1155MetadataURI private _nftree;
    IERC20Metadata private _cco2;

    mapping(uint256 /* nftree id */ => TokenInfo) private _nftInfo;
    uint256 [] private _nftList;

    event LogCoorestTokenContractsSet(
        address owner,
        address nftree,
        address cco2
    );

    event LogCoorestTokenInfoCreated(
        uint256 tokenId,
        bytes32 projecId,
        uint256 co2absorbed
    );

    constructor() Ownable() { }

    function setTokens(
        address nftree, 
        address cco2
    )
        external
        onlyOwner
    {
        _setTokens(nftree, cco2);
        emit LogCoorestTokenContractsSet(msg.sender, nftree, cco2);
    }

    function storeTokenInfo(
        uint256 tokenId,
        bytes32 projectId,
        uint256 co2absorbed
    )
        external
        onlyOwner
    {
        // TODO: _validateTokenInfoParameters(...);

        _nftList.push(tokenId);

        TokenInfo storage info = _nftInfo[tokenId];
        require(info.createdAt == 0, "ERROR:COP-001:INFO_ALREADY_EXISTS");

        info.tokenId = tokenId;
        info.projectId = projectId;
        info.co2absorbed = co2absorbed;
        info.createdAt = block.timestamp; // solhint-disable-line

        emit LogCoorestTokenInfoCreated(
            info.tokenId,
            info.projectId,
            info.co2absorbed
        );
    }

    function calculateTokenInfoId(
        bytes32 projectId,
        uint256 tokenId // link to nftree token
    )
        public
        pure
        returns (bytes32 riskId)
    {
        riskId = keccak256(abi.encode(projectId, tokenId)); // , regionId, plantId));
    }

    function tokens() external view returns(uint256 numberOfTokens) {
        return _nftList.length;
    }

    function getTokenAt(uint256 idx) external view returns(TokenInfo memory info) {
        require(idx < _nftList.length, "ERROR:COP-010:INDEX_TOO_LARGE");
        uint256 tokenId = _nftList[idx];
        return _nftInfo[tokenId];
    }

    function exists(uint tokenId) public view returns(bool) {
        return _nftInfo[tokenId].createdAt > 0;
    }

    function getToken(uint256 tokenId) external view returns(TokenInfo memory info) {
        require(exists(tokenId), "ERROR:COP-011:TOKEN_ID_UNKNOWN");
        return _nftInfo[tokenId];
    }

    function isNftreeTokenHolder(address holder, uint256 tokenId) external view returns(bool) {
        return _nftree.balanceOf(holder, tokenId) > 0;
    }

    function getNftreeContract() external view returns(IERC1155MetadataURI) {
        return _nftree;
    }

    function getCo2Contract() external view returns(IERC20Metadata) {
        return _cco2;
    }

    function tokensAreSet()
        external
        view
        returns(bool)
    {
        return address(_nftree) != address(0) && address(_cco2) != address(0);
    }


    function _setTokens(
        address nftree,
        address co2
    )
        internal 
    {
        if(nftree != address(0)) {
            _nftree = IERC1155MetadataURI(nftree);
        } else if(block.chainid == CHAIN_ID_MUMBAI) {
            _nftree = IERC1155MetadataURI(NFTREE_CONTRACT_MUMBAI);
        }

        if(co2 != address(0)) {
            _cco2 = IERC20Metadata(co2);
        } else if(block.chainid == CHAIN_ID_MUMBAI) {
            _cco2 = IERC20Metadata(CO2_CONTRACT_MUMBAI);
        }

        require(address(_nftree) != address(0), "ERROR:COP-050:NFTREE_CONTRACT_ZERO");
        require(address(_cco2) != address(0), "ERROR:COP-051:CO2_CONTRACT_ZERO");
    }
}