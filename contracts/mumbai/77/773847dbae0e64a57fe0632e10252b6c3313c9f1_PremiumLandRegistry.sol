/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

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


// File src/solc_0.8/common/Libraries/TileLib.sol

// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @title An optimized bitset of 24x24 bits (used to represent maps)
/// @notice see: http://
/// @dev We store 8 lines of 24 bits in each uint256 and leave some free space.
library TileLib {
    uint256 public constant PIXEL_MASK = 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant PIXEL_MASK_INV = 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000;

    struct Tile {
        uint256[3] data;
    }

    /// @notice init the tile with the internal data directly
    /// @return A Tile that has the bit data set
    function init(
        Tile memory self,
        uint256 pixelData1,
        uint256 pixelData2,
        uint256 pixelData3
    ) internal pure returns (Tile memory) {
        self.data[0] = pixelData1 & PIXEL_MASK;
        self.data[1] = pixelData2 & PIXEL_MASK;
        self.data[2] = pixelData3 & PIXEL_MASK;
        return self;
    }

    /// @notice Set the bits inside a square that has size x size in the x,y coordinates
    /// @dev can be optimized for the specific case of a 24x24 square
    /// @param self the Tile in which the bits are set
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding bits set
    function set(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (Tile memory) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            self.data[idx] |= mask << (x + 24 * ((y + i) % 8));
        }
        return self;
    }

    /// @notice Clear the bits inside a square that has size x size in the x,y coordinates
    /// @dev can be optimized for the specific case of a 24x24 square
    /// @param self the Tile in which the bits will be cleared
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding cleared bits
    function clear(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (Tile memory) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            self.data[idx] &= ~(mask << (x + 24 * ((y + i) % 8)));
        }
        return self;
    }

    /// @notice Check if the bit in certain coordinate inside the Tile is set or not, if not set it.
    /// @dev this routine is a combination of contains and set, used to save some gas
    /// @param self the Tile where the check is done
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function addIfNotContain(
        Tile memory self,
        uint256 x,
        uint256 y
    ) internal pure returns (bool, Tile memory) {
        require(x < 24 && y < 24, "Invalid coordinates");
        uint256 idx = y / 8;
        uint256 bitMask = 1 << (x + 24 * (y % 8));
        if (self.data[idx] & bitMask == bitMask) {
            return (false, self);
        }
        self.data[idx] |= bitMask;
        return (true, self);
    }

    /// @notice Check if the bit in certain coordinate inside the Tile is set or not
    /// @param self the Tile where the check is done
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function contain(
        Tile memory self,
        uint256 x,
        uint256 y
    ) internal pure returns (bool) {
        require(x < 24 && y < 24, "Invalid coordinates");
        uint256 idx = y / 8;
        uint256 bitMask = 1 << (x + 24 * (y % 8));
        return (self.data[idx] & bitMask == bitMask);
    }

    /// @notice Check if the all the bits of a square inside the Tile are set or not
    /// @param self the Tile where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function contain(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (bool) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            uint256 bitMask = mask << (x + 24 * ((y + i) % 8));
            if (self.data[idx] & bitMask != bitMask) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if a Tile includes all the bits that are set in another Tile
    /// @param self the bigger Tile that is checked for inclusion
    /// @param contained the Tile that must be included
    /// @return true if self contain contained Tile
    function contain(Tile memory self, Tile memory contained) internal pure returns (bool) {
        uint256 d0 = contained.data[0] & PIXEL_MASK;
        uint256 d1 = contained.data[1] & PIXEL_MASK;
        uint256 d2 = contained.data[2] & PIXEL_MASK;
        return (self.data[0] & d0 == d0) && (self.data[1] & d1 == d1) && (self.data[2] & d2 == d2);
    }

    /// @notice Check if the Tile has any bit in common with a square
    /// @param self the Tile where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in both Tiles
    function intersect(
        Tile memory self,
        uint256 x,
        uint256 y,
        uint256 size
    ) internal pure returns (bool) {
        require(x < 24 && y < 24, "Invalid tile coordinates");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        uint256 mask = _quadMask(size);
        require(mask != 0, "invalid size");
        uint256 i;
        for (; i < size; i++) {
            uint256 idx = (y + i) / 8;
            uint256 bitMask = mask << (x + 24 * ((y + i) % 8));
            if (self.data[idx] & bitMask != 0) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if two Tiles has any bit in common
    /// @param self first Tile to compare
    /// @param other second tile to compare
    /// @return true if there is at least one bit set in both Tiles
    function intersect(Tile memory self, Tile memory other) internal pure returns (bool) {
        return
            ((self.data[0] & other.data[0]) | (self.data[1] & other.data[1]) | (self.data[2] & other.data[2])) &
                PIXEL_MASK !=
            0;
    }

    /// @notice Check if two Tiles has exactly the same bits set
    /// @param self first Tile to compare
    /// @param other second Tile to compare
    /// @return true if the two Tiles has the same bits set
    function isEqual(Tile memory self, Tile memory other) internal pure returns (bool) {
        return
            ((self.data[0] ^ other.data[0]) | (self.data[1] ^ other.data[1]) | (self.data[2] ^ other.data[2])) &
                PIXEL_MASK ==
            0;
    }

    /// @notice return a Tile that is the union of two Tiles
    /// @dev this function destroys data outside the pixel data (we want to save some gas)
    /// @param self first Tile to compare
    /// @param other second Tile to compare
    /// @return a Tile that is the union of self and other
    function or(Tile memory self, Tile memory other) internal pure returns (Tile memory) {
        self.data[0] |= other.data[0] & PIXEL_MASK;
        self.data[1] |= other.data[1] & PIXEL_MASK;
        self.data[2] |= other.data[2] & PIXEL_MASK;
        return self;
    }

    /// @notice return a Tile that is the intersection of two Tiles
    /// @dev this function destroys data outside the pixel data (we want to save some gas)
    /// @param self first Tile to compare
    /// @param other second Tile to compare
    /// @return a Tile that is the intersection of self and other
    function and(Tile memory self, Tile memory other) internal pure returns (Tile memory) {
        self.data[0] &= other.data[0] | PIXEL_MASK_INV;
        self.data[1] &= other.data[1] | PIXEL_MASK_INV;
        self.data[2] &= other.data[2] | PIXEL_MASK_INV;
        return self;
    }

    /// @notice Calculates the subtraction of two Tile
    /// @param self the Tile to subtract from
    /// @param value the Tile subtracted
    /// @return the self with all the bits set in value cleared
    function subtract(Tile memory self, Tile memory value) internal pure returns (Tile memory) {
        self.data[0] &= ~(value.data[0] & PIXEL_MASK);
        self.data[1] &= ~(value.data[1] & PIXEL_MASK);
        self.data[2] &= ~(value.data[2] & PIXEL_MASK);
        return self;
    }

    /// @notice check if a Tile is empty, doesn't have any bit set
    /// @param self first Tile to compare
    /// @return true if the Tile is empty
    function isEmpty(Tile memory self) internal pure returns (bool) {
        return (self.data[0] | self.data[1] | self.data[2]) & PIXEL_MASK == 0;
    }

    /// @notice return a Tile that has only one of the pixels from the original Tile set
    /// @param self Tile in which one pixel is searched
    /// @return ret a Tile that has only one pixel set
    function findAPixel(Tile memory self) internal pure returns (Tile memory ret) {
        uint256 target;
        uint256 shift;

        target = self.data[2] & PIXEL_MASK;
        if (target != 0) {
            shift = _findAPixel(target);
            ret.data[2] = (1 << shift);
            return ret;
        }

        target = self.data[1] & PIXEL_MASK;
        if (target != 0) {
            shift = _findAPixel(target);
            ret.data[1] = (1 << shift);
            return ret;
        }

        target = self.data[0] & PIXEL_MASK;
        if (target != 0) {
            shift = _findAPixel(target);
            ret.data[0] = (1 << shift);
        }
        return ret;
    }

    /// @notice given a tile, translate all the bits in the x and y direction
    /// @param self the initial Tile to translate
    /// @param x the x distance to translate
    /// @param y the y distance to translate
    /// @return col1 first column that represents the four tiles that are the result of the translation
    /// @return col2 second column that represents the four tiles that are the result of the translation
    function translate(
        Tile memory self,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256[6] memory col1, uint256[6] memory col2) {
        // Move right
        uint256 mask = _getTranslateXMask(x);
        col1[0] = (self.data[0] & mask) << x;
        col1[1] = (self.data[1] & mask) << x;
        col1[2] = (self.data[2] & mask) << x;
        if (x > 0) {
            mask = PIXEL_MASK - mask;
            col2[0] = (self.data[0] & mask) >> (24 - x);
            col2[1] = (self.data[1] & mask) >> (24 - x);
            col2[2] = (self.data[2] & mask) >> (24 - x);
        }
        // Move down
        uint256 rem = 24 * (y % 8);
        uint256 div = y / 8;
        mask = PIXEL_MASK - (2**(24 * 8 - rem) - 1);
        // TODO: optimization, remove the loop, check gas consumption
        for (uint256 i = 5; i > div; i--) {
            col1[i] = (col1[i - div] << rem) | ((col1[i - div - 1] & mask) >> (24 * 8 - rem));
            col2[i] = (col2[i - div] << rem) | ((col2[i - div - 1] & mask) >> (24 * 8 - rem));
        }
        col1[div] = col1[0] << rem;
        col2[div] = col2[0] << rem;
        if (div > 0) {
            col1[0] = 0;
            col2[0] = 0;
            if (div > 1) {
                col1[1] = 0;
                col2[1] = 0;
            }
        }
        return (col1, col2);
    }

    uint256 private constant QUAD_MASK_1 = 1;
    uint256 private constant QUAD_MASK_3 = 2**3 - 1;
    uint256 private constant QUAD_MASK_6 = 2**6 - 1;
    uint256 private constant QUAD_MASK_12 = 2**12 - 1;
    uint256 private constant QUAD_MASK_24 = 2**24 - 1;

    /// @notice return a bit mask used to set or clear a square of certain size in the Tile
    /// @param size the size of the square
    /// @return the bit mask or zero if the size is not supported
    function _quadMask(uint256 size) private pure returns (uint256) {
        if (size == 1) return 1;
        if (size == 3) return QUAD_MASK_3;
        if (size == 6) return QUAD_MASK_6;
        if (size == 12) return QUAD_MASK_12;
        if (size == 24) return QUAD_MASK_24;
        return 0;
    }

    /// @notice count the amount of bits set inside the Tile
    /// @param self the Tile in which the bits are counted
    /// @return the count of bits that are set
    function countBits(Tile memory self) internal pure returns (uint256) {
        return _countBits(self.data[0]) + _countBits(self.data[1]) + _countBits(self.data[2]);
    }

    /// @notice count the amount of bits set inside a word
    /// @dev see: https://stackoverflow.com/questions/109023/how-to-count-the-number-of-set-bits-in-a-32-bit-integer
    /// @param x the word in which the bits are counted
    /// @return the count of bits that are set
    function _countBits(uint256 x) private pure returns (uint256) {
        x = x - ((x >> 1) & 0x0000000000000000555555555555555555555555555555555555555555555555);
        x =
            (x & 0x0000000000000000333333333333333333333333333333333333333333333333) +
            ((x >> 2) & 0x0000000000000000333333333333333333333333333333333333333333333333);
        x = (x + (x >> 4)) & 0x00000000000000000F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
        return
            ((((x >> 96) * 0x010101010101010101010101) +
                ((x & 0x0F0F0F0F0F0F0F0F0F0F0F0F) * 0x010101010101010101010101)) >> (11 * 8)) & 0xFF;
    }

    /// @notice giving 8 lines of a Tile, find any bit that is set
    /// @dev we must search in 8 * 24 bits that correspond to 8 lines, so 2^6 * 3, we split in three and then do a binary search
    /// @param target the uint256 that has the 8 lines
    /// @return shift the amount of bits shift left so the choose bit is set in the resulting Tile
    function _findAPixel(uint256 target) private pure returns (uint256 shift) {
        uint256 mask = (2**64 - 1);
        // divide in 3 parts, then do a binary search
        if ((target & mask) == 0) {
            target = target >> 64;
            shift = 64;
            if ((target & mask) == 0) {
                target = target >> 64;
                shift = 128;
            }
        }
        for (uint256 i = 32; i > 0; i = i / 2) {
            mask = mask >> i;
            if ((target & mask) == 0) {
                target = target >> i;
                shift += i;
            }
        }
        return shift;
    }

    /// @notice return a bit mask used translate a Tile data in the x direction
    /// @param x the x value to translate
    /// @return the bit mask
    function _getTranslateXMask(uint256 x) private pure returns (uint256) {
        uint256 mask = (2**24 - 1) >> x;
        mask |= mask << 24;
        mask |= mask << (24 * 2);
        mask |= mask << (24 * 4);
        return mask;
    }
}


// File src/solc_0.8/common/Libraries/TileWithCoordLib.sol

// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @title A Tile (24x24 map piece) that also stores x,y coordinates and a combination of the two called key
/// @dev Using a sparse array of TileWithCoords we build a bigger map covered with Tiles
library TileWithCoordLib {
    using TileLib for TileLib.Tile;

    struct TileWithCoord {
        TileLib.Tile tile;
    }

    /// @notice initialize the TileWithCoord structure
    /// @return An empty Tile that has the x,y and corresponding key value set
    function init(uint256 x, uint256 y) internal pure returns (TileWithCoord memory) {
        TileWithCoord memory ret;
        ret.tile.data[1] = (x / 24) << 224;
        ret.tile.data[2] = (y / 24) << 224;
        return ret;
    }

    /// @notice initialize the TileWithCoord structure
    /// @return An TileWithCoord that has the x,y, key and the Tile bit data set
    function init(
        uint256 x,
        uint256 y,
        uint256 pixelData1,
        uint256 pixelData2,
        uint256 pixelData3
    ) internal pure returns (TileWithCoord memory) {
        TileWithCoord memory ret;
        ret.tile = ret.tile.init(pixelData1, pixelData2, pixelData3);
        ret.tile.data[1] |= (x / 24) << 224;
        ret.tile.data[2] |= (y / 24) << 224;
        return ret;
    }

    /// @notice Set the bits inside a square that has size x size in the x,y coordinates
    /// @param self the TileWithCoord in which the bits are set
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding bits set
    function set(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (TileWithCoord memory) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        self.tile = self.tile.set(xi % 24, yi % 24, size);
        return self;
    }

    /// @notice Calculates the union/addition of two TileWithCoord
    /// @dev to be able to merge the two TileWithCoord must have the same coordinates
    /// @param self one of the TileWithCoord to merge
    /// @param value the second TileWithCoord to merge
    /// @return the merge of the two TileWithCoord
    function merge(TileWithCoord memory self, TileWithCoord memory value) internal pure returns (TileWithCoord memory) {
        require(getX(self) == getX(value) && getY(self) == getY(value), "Invalid tile coordinates");
        self.tile = self.tile.or(value.tile);
        return self;
    }

    /// @notice Clear the bits inside a square that has size x size in the x,y coordinates
    /// @param self the TileWithCoord, in which the bits will be cleared
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return self with the corresponding cleared bits
    function clear(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (TileWithCoord memory) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        self.tile = self.tile.clear(xi % 24, yi % 24, size);
        return self;
    }

    /// @notice Calculates the subtraction of two TileWithCoord
    /// @dev to be able to subtract them the two TileWithCoord must have the same coordinates
    /// @param self the TileWithCoord to subtract from
    /// @param value the TileWithCoord subtracted
    /// @return the self with all the bits set in value cleared
    function clear(TileWithCoord memory self, TileWithCoord memory value) internal pure returns (TileWithCoord memory) {
        require(getX(self) == getX(value) && getY(self) == getY(value), "Invalid tile coordinates");
        self.tile = self.tile.subtract(value.tile);
        return self;
    }

    /// @notice Check if the bit in certain coordinate are set or not in the TileWithCoord
    /// @param self the TileWithCoord where the check is done
    /// @param xi the x coordinate
    /// @param yi the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function contain(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi
    ) internal pure returns (bool) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid coordinates");
        return self.tile.contain(xi % 24, yi % 24);
    }

    /// @notice Check if the all the bits of a square inside the TileWithCoord are set or not
    /// @param self the TileWithCoord where the check is done
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function contain(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (bool) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        return self.tile.contain(xi % 24, yi % 24, size);
    }

    /// @notice Check if the TileWithCoord has any bit in common with a square
    /// @param self the TileWithCoord where the check is done
    /// @param xi the x coordinate of the square
    /// @param yi the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in the TileWithCoords and the square
    function intersect(
        TileWithCoord memory self,
        uint256 xi,
        uint256 yi,
        uint256 size
    ) internal pure returns (bool) {
        require(getX(self) == xi / 24 && getY(self) == yi / 24, "Invalid tile coordinates");
        return self.tile.intersect(xi % 24, yi % 24, size);
    }

    /// @notice return the x coordinate value stored in the TileWithCoord
    /// @param self the TileWithCoord to get the x coordinate from
    /// @return the x value
    function getX(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.data[1] >> 224;
    }

    /// @notice return the y coordinate value stored in the TileWithCoord
    /// @param self the TileWithCoord to get the y coordinate from
    /// @return the y value
    function getY(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.data[2] >> 224;
    }

    /// @notice return the key value stored in the TileWithCoord
    /// @param self the TileWithCoord to get the key from
    /// @return the key value
    function getKey(TileWithCoord memory self) internal pure returns (uint256) {
        return getX(self) | (getY(self) << 16);
    }

    /// @notice helper to calculate the key value given the x,y coordinates
    /// @param x the x coordinate
    /// @param y the y coordinate
    /// @return the key value
    function getKey(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x / 24) | ((y / 24) << 16);
    }

    /// @notice count the amount of bits set inside the TileWithCoord
    /// @param self the TileWithCoord in which the bits are counted
    /// @return the count of bits that are set
    function countBits(TileWithCoord memory self) internal pure returns (uint256) {
        return self.tile.countBits();
    }

    /// @notice check if a TileWithCoord is empty, none of the bits are set
    /// @param self the TileWithCoord to check
    /// @return true if none of the bits are set
    function isEmpty(TileWithCoord memory self) internal pure returns (bool) {
        return self.tile.isEmpty();
    }

    /// @notice Check if two TileWithCoord has exactly the same coordinates and bits set
    /// @param self first TileWithCoord to compare
    /// @param other second TileWithCoord to compare
    /// @return true if the two TileWithCoord has the same coordinates and bits set
    function isEqual(TileWithCoord memory self, TileWithCoord memory other) internal pure returns (bool) {
        return
            self.tile.data[0] == other.tile.data[0] &&
            self.tile.data[1] == other.tile.data[1] &&
            self.tile.data[2] == other.tile.data[2];
    }
}


// File src/solc_0.8/common/Libraries/MapLib.sol

/* solhint-disable code-complexity */
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;


/// @title An iterable mapping of Tiles (24x24 bit set).
/// @notice Used to represent a the presence or absence of certain x,y coordinate in a map of lands
/// @dev The key of the mapping is a combination of x and y.
/// @dev This library try to reduce the gas consumption and to do that it accesses the internal structure of the Tiles
library MapLib {
    using TileWithCoordLib for TileWithCoordLib.TileWithCoord;
    using TileLib for TileLib.Tile;

    uint256 private constant LEFT_MASK = 0x000001000001000001000001000001000001000001000001;
    uint256 private constant LEFT_MASK_NEG = ~LEFT_MASK;
    uint256 private constant RIGHT_MASK = 0x800000800000800000800000800000800000800000800000;
    uint256 private constant RIGHT_MASK_NEG = ~RIGHT_MASK;
    uint256 private constant UP_MASK = 0x000000000000000000000000000000000000000000FFFFFF;
    uint256 private constant DOWN_MASK = 0xFFFFFF000000000000000000000000000000000000000000;

    struct TranslateResult {
        TileWithCoordLib.TileWithCoord topLeft;
        TileWithCoordLib.TileWithCoord topRight;
        TileWithCoordLib.TileWithCoord bottomLeft;
        TileWithCoordLib.TileWithCoord bottomRight;
    }

    // An iterable mapping of tiles (24x24 bit set).
    struct Map {
        TileWithCoordLib.TileWithCoord[] values;
        // Position of the value in the `values` array, plus 1 because index 0 means that the key is not found.
        mapping(uint256 => uint256) indexes;
    }

    /// @notice Set the bits inside a square that has size x size in the x,y coordinates in the map
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map in which the bits are set
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    function set(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            // Add a new tile
            TileWithCoordLib.TileWithCoord memory t = TileWithCoordLib.init(x, y);
            self.values.push(t.set(x, y, size));
            self.indexes[key] = self.values.length;
        } else {
            // contains
            self.values[idx - 1] = self.values[idx - 1].set(x, y, size);
        }
    }

    /// @notice Given a translation of a tile the corresponding bits are set in the current map
    /// @param self the Map in which the bits are set
    /// @param s translation result, the result of a translation of a tile are four tiles.
    function set(Map storage self, TranslateResult memory s) public {
        set(self, s.topLeft);
        set(self, s.topRight);
        set(self, s.bottomLeft);
        set(self, s.bottomRight);
    }

    /// @notice Given a TileWithCoord (a tile that includes coordinates inside it) set the corresponding bits in the map
    /// @param self the Map in which the bits are set
    /// @param tile the tile that is used to set the bits inside the map
    function set(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public {
        if (tile.isEmpty()) {
            return;
        }
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            // Add a new tile
            self.values.push(tile);
            self.indexes[key] = self.values.length;
        } else {
            self.values[idx - 1] = self.values[idx - 1].merge(tile);
        }
    }

    /// @notice Merge the bits of a list of TileWithCoord in the current one
    /// @param self the Map in which the bits are set
    /// @param tiles the list of TileWithCoord
    function set(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            set(self, tiles[i]);
        }
    }

    /// @notice Merge the bits of another map in the current one
    /// @param self the Map in which the bits are set
    /// @param other the map that is used as source to set the bits in the current one
    function set(Map storage self, Map storage other) public {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            set(self, other.values[i]);
        }
    }

    /// @notice Clear the bits inside a square that has size x size in the x,y coordinates in the map
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map, in which the bits will be cleared
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return false if the the coordinates are not found so the bits are already cleared
    function clear(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains, nothing to clear
            return false;
        }
        TileWithCoordLib.TileWithCoord memory t = self.values[idx - 1].clear(x, y, size);
        if (t.isEmpty()) {
            _remove(self, idx, key);
        } else {
            self.values[idx - 1] = t;
        }
        return true;
    }

    /// @notice Given a translation of a tile the corresponding bits are cleared in the current map
    /// @param self the Map in which the bits are cleared
    /// @param s translation result, the result of a translation of a tile are four tiles.
    function clear(Map storage self, TranslateResult memory s) public {
        clear(self, s.topLeft);
        clear(self, s.topRight);
        clear(self, s.bottomLeft);
        clear(self, s.bottomRight);
    }

    /// @notice Given a TileWithCoord (a tile that includes coordinates inside it) clear the corresponding bits in the map
    /// @param self the Map, in which the bits will be cleared
    /// @param tile the tile that is used to clear the bits inside the map
    /// @return false if the the coordinates are not found so the bits are already cleared
    function clear(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public returns (bool) {
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        TileWithCoordLib.TileWithCoord memory t = self.values[idx - 1].clear(tile);
        if (t.isEmpty()) {
            _remove(self, idx, key);
        } else {
            self.values[idx - 1] = t;
        }
        return true;
    }

    /// @notice Clear the bits of a list of TileWithCoord
    /// @param self the Map in which the bits are cleared
    /// @param tiles the list of TileWithCoord
    function clear(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            clear(self, tiles[i]);
        }
    }

    /// @notice Clear the bits of another map in the current one
    /// @param self the Map in which the bits are cleared
    /// @param other the map that is used as source to clear the bits in the current one
    function clear(Map storage self, Map storage other) public {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            clear(self, other.values[i]);
        }
    }

    /// @notice Clear the all the bits in the map
    /// @param self the Map in which the bits are cleared
    function clear(Map storage self) public {
        for (uint256 i; i < self.values.length; i++) {
            delete self.indexes[self.values[i].getKey()];
        }
        delete self.values;
    }

    /// @notice Given a TileWithCoord set the values of this tile in the map to the given one
    /// @param self the Map in which the bits are set
    /// @param tile the tile that is used to assign the bits inside the map
    function assign(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public {
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (tile.isEmpty()) {
            if (idx == 0) {
                // !contains
                return;
            }
            _remove(self, idx, key);
            return;
        }
        if (idx == 0) {
            // !contains
            // Add a new tile
            self.values.push(tile);
            self.indexes[key] = self.values.length;
        } else {
            self.values[idx - 1] = tile;
        }
    }

    /// @notice Set the values of a list of TileWithCoord in the current one
    /// @param self the Map in which the bits are set
    /// @param tiles the list of TileWithCoord
    function assign(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            assign(self, tiles[i]);
        }
    }

    /// @notice given a tile, translate all the bits in the x and y direction
    /// @dev the result of the translation are four tiles
    /// @param deltaX the x distance to translate
    /// @param deltaY the y distance to translate
    /// @return four tiles with coords that are the result of the translation
    function translate(
        TileLib.Tile memory tile,
        uint256 deltaX,
        uint256 deltaY
    ) internal pure returns (TranslateResult memory) {
        (uint256[6] memory col1, uint256[6] memory col2) = tile.translate(deltaX % 24, deltaY % 24);
        return
            TranslateResult({
                topLeft: TileWithCoordLib.init(deltaX, deltaY, col1[0], col1[1], col1[2]),
                bottomLeft: TileWithCoordLib.init(deltaX, deltaY + 24, col1[3], col1[4], col1[5]),
                topRight: TileWithCoordLib.init(deltaX + 24, deltaY, col2[0], col2[1], col2[2]),
                bottomRight: TileWithCoordLib.init(deltaX + 24, deltaY + 24, col2[3], col2[4], col2[5])
            });
    }

    /// @notice Check if the bit in certain coordinate are set or not inside the map
    /// @param self the Map where the check is done
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function contain(
        Map storage self,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].contain(x, y);
    }

    /// @notice Check if the all the bits of a square inside the Map are set or not
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function contain(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].contain(x, y, size);
    }

    /// @notice Check if a Map includes all the bits that are set in a TileWithCoord
    /// @param self the Map that is checked for inclusion
    /// @param tile the TileWithCoord that must be included
    /// @return true if self contain tile TileWithCoord
    function contain(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public view returns (bool) {
        if (tile.isEmpty()) {
            return true;
        }
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].tile.contain(tile.tile);
    }

    /// @notice Check if a Map includes all the bits that are set in a TileWithCoord[]
    /// @param self the Map that is checked for inclusion
    /// @param tiles the TileWithCoord that must be included
    /// @return true if self contain tiles TileWithCoord[]
    function contain(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public view returns (bool) {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            if (!contain(self, tiles[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if a Map includes all the bits that are set in translation result
    /// @dev this routine is used to match an experience template after translation
    /// @param self the bigger Tile that is checked for inclusion
    /// @param s the translation result that must be included
    /// @return true if self contain all the bits in the translation result
    function contain(Map storage self, TranslateResult memory s) public view returns (bool) {
        return
            contain(self, s.topLeft) &&
            contain(self, s.topRight) &&
            contain(self, s.bottomLeft) &&
            contain(self, s.bottomRight);
    }

    /// @notice Check if a Map includes all the bits that are set in another Map
    /// @dev self can be huge, but other must be small, we iterate over other values.
    /// @param self the Map that is checked for inclusion
    /// @param other the Map that must be included
    /// @return true if self contain other Map
    function contain(Map storage self, Map storage other) public view returns (bool) {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            if (!contain(self, other.values[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if a map has at least one bit in common with a square (x,y,size)
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the Map where the check is done
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in both the Map and the square
    function intersect(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (bool) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !intersect
            return false;
        }
        return self.values[idx - 1].intersect(x, y, size);
    }

    /// @notice Check if a map has at least one bit in common with some TileWithCoord
    /// @param self the Map to compare
    /// @param tile the TileWithCoord to compare
    /// @return true if there is at least one bit set in both the Map and the TileWithCoord
    function intersect(Map storage self, TileWithCoordLib.TileWithCoord memory tile) public view returns (bool) {
        if (tile.isEmpty()) {
            return false;
        }
        uint256 key = tile.getKey();
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            // !contains
            return false;
        }
        return self.values[idx - 1].tile.intersect(tile.tile);
    }

    /// @notice Check if a Map has at least one of the bits that are set in a TileWithCoord[]
    /// @param self the Map that is checked for inclusion
    /// @param tiles the TileWithCoord that must be included
    /// @return true if there is at least one bit set in both the Map and the TileWithCoord[]
    function intersect(Map storage self, TileWithCoordLib.TileWithCoord[] memory tiles) public view returns (bool) {
        uint256 len = tiles.length;
        for (uint256 i; i < len; i++) {
            if (intersect(self, tiles[i])) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if a map has at least one bit in common with some translation result
    /// @param self the Map to compare
    /// @param s the four tiles that are the result of a translation
    /// @return true if there is at least one bit set in both the Map and the TranslationResult
    function intersect(Map storage self, TranslateResult memory s) public view returns (bool) {
        return
            intersect(self, s.topLeft) ||
            intersect(self, s.topRight) ||
            intersect(self, s.bottomLeft) ||
            intersect(self, s.bottomRight);
    }

    /// @notice Check if a Map includes any of the bits that are set in another Map
    /// @dev self can be huge, but other must be small, we iterate over other values.
    /// @param self the Map that is checked for inclusion
    /// @param other the Map that must be included
    /// @return true if there is at least one bit set in both Maps
    function intersect(Map storage self, Map storage other) public view returns (bool) {
        uint256 len = other.values.length;
        for (uint256 i; i < len; i++) {
            if (intersect(self, other.values[i])) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if a map is empty (no bits are set)
    /// @param self the Map to check
    /// @return true if the map is empty
    function isEmpty(Map storage self) public view returns (bool) {
        // We remove the tiles when they are empty
        return self.values.length == 0;
    }

    /// @notice Check if two maps are equal
    /// @param self the first Map to check
    /// @param other the second Map to check
    /// @return true if the two maps are equal
    function isEqual(Map storage self, Map storage other) public view returns (bool) {
        return isEqual(self, other.values);
    }

    /// @notice Check if a map is equal to an array of TileWithCoord
    /// @param self the Map to check
    /// @param other the list of TileWithCoord to check
    /// @return true if the two are equal
    function isEqual(Map storage self, TileWithCoordLib.TileWithCoord[] memory other) public view returns (bool) {
        if (other.length != self.values.length) {
            return false;
        }
        uint256 cant = other.length;
        // Check that self contains the same set of tiles than other and they are equal
        for (uint256 i; i < cant; i++) {
            uint256 key = other[i].getKey();
            uint256 idx = self.indexes[key];
            if (idx == 0 || !self.values[idx - 1].isEqual(other[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice return the length of the internal list of tiles
    /// @dev used to iterate off-chain over the tiles.
    /// @param self the Map
    /// @return the length of the list
    function length(Map storage self) public view returns (uint256) {
        return self.values.length;
    }

    /// @notice get the tile that is in certain position in the internal list of tiles
    /// @dev used to iterate off-chain over the tiles.
    /// @param self the Map
    /// @param index the index of the tile
    /// @return the tile that is in the position index in the list
    function at(Map storage self, uint256 index) public view returns (TileWithCoordLib.TileWithCoord memory) {
        return self.values[index];
    }

    /// @notice get the internal list of tiles with pagination
    /// @dev used to iterate off-chain over the tiles.
    /// @param self the Map
    /// @param offset initial offset used to paginate
    /// @param limit amount of tiles to get
    /// @return the partial list of tiles
    function at(
        Map storage self,
        uint256 offset,
        uint256 limit
    ) public view returns (TileWithCoordLib.TileWithCoord[] memory) {
        TileWithCoordLib.TileWithCoord[] memory ret = new TileWithCoordLib.TileWithCoord[](limit);
        for (uint256 i; i < limit; i++) {
            ret[i] = self.values[offset + i];
        }
        return ret;
    }

    /// @notice return the internal list of tiles
    /// @dev Use only for testing. This can be problematic if it grows too much !!!
    /// @param self the map
    /// @return the list of internal tiles
    function getMap(Map storage self) public view returns (TileWithCoordLib.TileWithCoord[] memory) {
        return self.values;
    }

    /// @notice count the amount of bits (lands) set inside a Map
    /// @param self the map
    /// @return the quantity of lands
    function getLandCount(Map storage self) public view returns (uint256) {
        uint256 ret;
        uint256 len = self.values.length;
        for (uint256 i; i < len; i++) {
            ret += self.values[i].countBits();
        }
        return ret;
    }

    /// @notice count the amount of bits (lands) set inside a Map filtered by quad
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param self the map
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return the quantity of lands
    function getLandCount(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (uint256) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx == 0) {
            return 0;
        }
        TileLib.Tile memory t;
        return t.set(x, y, size).and(self.values[idx - 1].tile).countBits();
    }

    /// @notice return a tile from the Map by his coordinates
    /// @param self the map
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @return found true if the tile inside the map wad found
    /// @return tile the tile with coords inside the map
    function get(
        Map storage self,
        uint256 x,
        uint256 y
    ) public view returns (bool found, TileWithCoordLib.TileWithCoord memory tile) {
        uint256 key = TileWithCoordLib.getKey(x, y);
        uint256 idx = self.indexes[key];
        if (idx != 0) {
            tile = self.values[idx - 1];
            found = true;
        }
    }

    /// @notice check if a square is adjacent (4-connected component) to the current map.
    /// @dev used to add a quad to a map, it is cheaper than isAdjacent(map)
    /// @param self the map
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if the square is 4-connected to the map
    function isAdjacent(
        Map storage self,
        uint256 x,
        uint256 y,
        uint256 size
    ) public view returns (bool) {
        if (isEmpty(self)) {
            return true;
        }

        uint256 idx;
        TileLib.Tile memory spot;
        spot = spot.set(x % 24, y % 24, size);
        // left
        if (x >= 24) {
            idx = _getIdx(self, x - 24, y);
            if (idx != 0 && !self.values[idx - 1].tile.and(_growLeft(spot)).isEmpty()) {
                return true;
            }
        }
        // up
        if (y >= 24) {
            idx = _getIdx(self, x, y - 24);
            if (idx != 0 && (self.values[idx - 1].tile.data[0] & ((spot.data[0] & UP_MASK) << (24 * 7))) != 0) {
                return true;
            }
        }
        // middle
        idx = _getIdx(self, x, y);
        if (idx != 0 && !self.values[idx - 1].tile.and(_growMiddle(spot)).isEmpty()) {
            return true;
        }
        // down
        idx = _getIdx(self, x, y + 24);
        if (idx != 0 && (self.values[idx - 1].tile.data[2] & ((spot.data[2] & DOWN_MASK) >> (24 * 7))) != 0) {
            return true;
        }
        // right
        idx = _getIdx(self, x + 24, y);
        if (idx != 0 && !self.values[idx - 1].tile.and(_growRight(spot)).isEmpty()) {
            return true;
        }
        return false;
    }

    /// @notice check that the map has only one 4-connected component, aka everything is adjacent
    /// @dev Checks the full map to see if all the pixels are adjacent
    /// @param self the map
    /// @return ret true if all the bits (lands) are adjacent
    function isAdjacent(Map storage self) public view returns (bool ret) {
        if (isEmpty(self)) {
            // everything is adjacent to an empty map
            return true;
        }

        TileLib.Tile[] memory spot = new TileLib.Tile[](self.values.length);
        // We assume that all self.values[] are non empty (we remove them if they are empty).
        spot[0] = self.values[0].tile.findAPixel();
        bool done;
        while (!done) {
            (spot, done) = floodStep(self, spot);
        }
        uint256 len = self.values.length;
        uint256 i;
        for (; i < len; i++) {
            // Check the tile ignoring coordinates
            if (!self.values[i].tile.isEqual(spot[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice used to check adjacency. See: https://en.wikipedia.org/wiki/Flood_fill and isAdjacent.
    /// @param self the map
    /// @param current the current image
    /// @return next return the image with the extra pixels that correspond to the flooding process
    /// @return done true if the current image is the same as the next one so the algorithm is ready to stop flooding.
    function floodStep(Map storage self, TileLib.Tile[] memory current)
        public
        view
        returns (TileLib.Tile[] memory next, bool done)
    {
        uint256 len = self.values.length;
        uint256 i;
        uint256 x;
        uint256 y;
        uint256 idx;
        TileLib.Tile memory ci;
        next = new TileLib.Tile[](len);
        // grow
        for (i; i < len; i++) {
            ci = current[i];
            // isEmpty
            if ((ci.data[0] | ci.data[1] | ci.data[2]) == 0) {
                continue;
            }
            x = self.values[i].getX() * 24;
            y = self.values[i].getY() * 24;

            // middle, always included
            next[i].data[0] |= _grow(ci.data[0]) | ((ci.data[1] & UP_MASK) << (24 * 7));
            next[i].data[1] |=
                _grow(ci.data[1]) |
                ((ci.data[2] & UP_MASK) << (24 * 7)) |
                ((ci.data[0] & DOWN_MASK) >> (24 * 7));
            next[i].data[2] |= _grow(ci.data[2]) | ((ci.data[1] & DOWN_MASK) >> (24 * 7));
            // left
            if (x >= 24) {
                idx = _getIdx(self, x - 24, y);
                if (idx != 0) {
                    next[idx - 1].data[0] |= (ci.data[0] & LEFT_MASK) << 23;
                    next[idx - 1].data[1] |= (ci.data[1] & LEFT_MASK) << 23;
                    next[idx - 1].data[2] |= (ci.data[2] & LEFT_MASK) << 23;
                }
            }
            // up
            if (y >= 24) {
                idx = _getIdx(self, x, y - 24);
                if (idx != 0) {
                    next[idx - 1].data[2] |= (ci.data[0] & UP_MASK) << (24 * 7);
                }
            }
            // down
            idx = _getIdx(self, x, y + 24);
            if (idx != 0) {
                next[idx - 1].data[0] |= (ci.data[2] & DOWN_MASK) >> (24 * 7);
            }
            // right
            idx = _getIdx(self, x + 24, y);
            if (idx != 0) {
                next[idx - 1].data[0] |= (ci.data[0] & RIGHT_MASK) >> 23;
                next[idx - 1].data[1] |= (ci.data[1] & RIGHT_MASK) >> 23;
                next[idx - 1].data[2] |= (ci.data[2] & RIGHT_MASK) >> 23;
            }
        }
        // Mask it.
        done = true;
        for (i = 0; i < len; i++) {
            // next[i] = next[i].and(self.values[i].tile);
            // done = done && next[i].isEqual(current[i]);
            next[i].data[0] &= self.values[i].tile.data[0];
            next[i].data[1] &= self.values[i].tile.data[1];
            next[i].data[2] &= self.values[i].tile.data[2];
            done =
                done &&
                next[i].data[0] == current[i].data[0] &&
                next[i].data[1] == current[i].data[1] &&
                next[i].data[2] == current[i].data[2];
        }
        return (next, done);
    }

    /// @notice delete certain tile from the map
    /// @param self the Map where the tile is removed
    /// @param idx the index of the tile in the internal list
    /// @param key the key of the tile (combination of x,y)
    function _remove(
        Map storage self,
        uint256 idx,
        uint256 key
    ) private {
        uint256 toDeleteIndex = idx - 1;
        uint256 lastIndex = self.values.length - 1;
        if (lastIndex != toDeleteIndex) {
            TileWithCoordLib.TileWithCoord memory lastValue = self.values[lastIndex];
            self.values[toDeleteIndex] = lastValue;
            self.indexes[lastValue.getKey()] = idx;
        }
        self.values.pop();
        delete self.indexes[key];
    }

    /// @notice given x and y return the index of the tile inside the internal list of tiles
    /// @param self the Map where the tile is removed
    /// @param x the x coordinate
    /// @param y the y coordinate
    /// @return the index in the list + 1 or zero if not found
    function _getIdx(
        Map storage self,
        uint256 x,
        uint256 y
    ) private view returns (uint256) {
        return self.indexes[TileWithCoordLib.getKey(x, y)];
    }

    /// @notice grow (4-connected) the internal word that represent 8 lines of the tile adding pixels
    /// @param x the value of the internal work
    /// @return the internal work with the extra pixels from growing it
    function _grow(uint256 x) private pure returns (uint256) {
        return (x | ((x & RIGHT_MASK_NEG) << 1) | ((x & LEFT_MASK_NEG) >> 1) | (x << 24) | (x >> 24));
    }

    /// @notice grow (4-connected) a tile adding pixels around those that exists
    /// @param self the tile to grow
    /// @return e the tile that results from adding all the 4-connected pixels
    function _growMiddle(TileLib.Tile memory self) internal pure returns (TileLib.Tile memory e) {
        e.data[0] = _grow(self.data[0]) | ((self.data[1] & UP_MASK) << (24 * 7));
        e.data[1] =
            _grow(self.data[1]) |
            ((self.data[2] & UP_MASK) << (24 * 7)) |
            ((self.data[0] & DOWN_MASK) >> (24 * 7));
        e.data[2] = _grow(self.data[2]) | ((self.data[1] & DOWN_MASK) >> (24 * 7));
        return e;
    }

    /// @notice grow (4-connected) a tile adding pixels around those that exists
    /// @param self the tile to grow
    /// @return e the extra tile to the right that results from adding all the 4-connected pixels
    function _growRight(TileLib.Tile memory self) internal pure returns (TileLib.Tile memory e) {
        // for loop removed to save some gas.
        e.data[0] = (self.data[0] & RIGHT_MASK) >> 23;
        e.data[1] = (self.data[1] & RIGHT_MASK) >> 23;
        e.data[2] = (self.data[2] & RIGHT_MASK) >> 23;
        return e;
    }

    /// @notice grow (4-connected) a tile adding pixels around those that exists
    /// @param self the tile to grow
    /// @return e the extra tile to the left that results from adding all the 4-connected pixels
    function _growLeft(TileLib.Tile memory self) internal pure returns (TileLib.Tile memory e) {
        e.data[0] = (self.data[0] & LEFT_MASK) << 23;
        e.data[1] = (self.data[1] & LEFT_MASK) << 23;
        e.data[2] = (self.data[2] & LEFT_MASK) << 23;
        return e;
    }
}


// File src/solc_0.8/common/interfaces/IPremiumLandRegistry.sol

pragma solidity 0.8.2;

interface IPremiumLandRegistry {
    /// @notice Check if the bit in certain coordinate are set or not inside the map
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function isPremium(uint256 x, uint256 y) external view returns (bool);
}


// File src/solc_0.8/registry/PremiumLandRegistry.sol

pragma solidity 0.8.2;






/// @notice A 408x408 matrix of bits, true means that the land is premium
contract PremiumLandRegistry is Initializable, ContextUpgradeable, AccessControlUpgradeable, IPremiumLandRegistry {
    using MapLib for MapLib.Map;
    using TileWithCoordLib for TileWithCoordLib.TileWithCoord;

    // The following role is provided for business-related admin functions
    bytes32 public constant MAP_DESIGNER_ROLE = keccak256("MAP_DESIGNER_ROLE");

    struct PremiumLandRegistryStorage {
        MapLib.Map premiumLand;
    }

    /// @dev Emitted when a tile is updated
    event TileChanged(TileWithCoordLib.TileWithCoord[]);

    /// @dev Emitted when a tile is updated
    event PixelSet(uint256 x, uint256 y);

    /// @dev Emitted when a tile is updated
    event PixelClear(uint256 x, uint256 y);

    function PremiumLandRegistry_init(address admin) external initializer {
        require(admin != address(0), "invalid admin address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice assign the bits of a premium map
    /// @param tiles the list of TileWithCoord to be assigned
    function assign(TileWithCoordLib.TileWithCoord[] memory tiles) external onlyRole(MAP_DESIGNER_ROLE) {
        _s().premiumLand.assign(tiles);
        emit TileChanged(tiles);
    }

    /// @notice set a pixel in the premium map
    /// @dev helper method that can be called by hand
    /// @param x coordinate
    /// @param y coordinate
    function set(uint256 x, uint256 y) external onlyRole(MAP_DESIGNER_ROLE) {
        _s().premiumLand.set(x, y, 1);
        emit PixelSet(x, y);
    }

    /// @notice clear a pixel in the premium map
    /// @dev helper method that can be called by hand
    /// @param x coordinate
    /// @param y coordinate
    function clear(uint256 x, uint256 y) external onlyRole(MAP_DESIGNER_ROLE) {
        _s().premiumLand.clear(x, y, 1);
        emit PixelClear(x, y);
    }

    /// @notice Check if the bit in certain coordinate are set or not inside the map
    /// @param x the x coordinate
    /// @param y the  coordinate
    /// @return true if the x,y coordinate bit is set or false if it is cleared
    function isPremium(uint256 x, uint256 y) external view override returns (bool) {
        return _s().premiumLand.contain(x, y);
    }

    /// @notice Count the amount of premium lands.
    /// @param xs the x coordinate
    /// @param ys the  coordinate
    /// @return the amount of premium lands
    function countPremium(uint256[] calldata xs, uint256[] calldata ys) external view returns (uint256) {
        uint256 len = xs.length;
        require(len == ys.length, "invalid arguments");
        MapLib.Map storage premiumLand = _s().premiumLand;
        uint256 count;
        for (uint256 i; i < len; i++) {
            if (premiumLand.contain(xs[i], ys[i])) count++;
        }
        return count;
    }

    /// @notice Count the amount of premium lands inside the Map filtered by a quad
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return the amount of premium lands
    function countPremium(
        uint256 x,
        uint256 y,
        uint256 size
    ) external view returns (uint256) {
        return _s().premiumLand.getLandCount(x, y, size);
    }

    /// @notice Count the amount of premium lands inside the Map filtered by a quad
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param xs the x coordinate of the square
    /// @param ys the y coordinate of the square
    /// @param sizes the size of the square
    /// @return the amount of premium lands
    function countPremium(
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint256[] calldata sizes
    ) external view returns (uint256) {
        uint256 len = xs.length;
        require(len == ys.length && len == sizes.length, "invalid arguments");
        MapLib.Map storage premiumLand = _s().premiumLand;
        uint256 count;
        for (uint256 i; i < len; i++) {
            count += premiumLand.getLandCount(xs[i], ys[i], sizes[i]);
        }
        return count;
    }

    /// @notice Check if the all the bits of a square inside the Map are set or not
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if al the bits are set or false if at least one bit is cleared
    function isAllPremium(
        uint256 x,
        uint256 y,
        uint256 size
    ) external view returns (bool) {
        return _s().premiumLand.contain(x, y, size);
    }

    /// @notice Check if a Map includes all the bits that are set in a TileWithCoord
    /// @param tile the TileWithCoord that must be included
    /// @return true if self contain tile TileWithCoord
    function isAllPremium(TileWithCoordLib.TileWithCoord memory tile) external view returns (bool) {
        return _s().premiumLand.contain(tile);
    }

    /// @notice Check if a Map includes all the bits that are set in a TileWithCoord[]
    /// @param tiles the TileWithCoord that must be included
    /// @return true if self contain tiles TileWithCoord[]
    function isAllPremium(TileWithCoordLib.TileWithCoord[] memory tiles) external view returns (bool) {
        return _s().premiumLand.contain(tiles);
    }

    /// @notice Check if a map has at least one bit in common with a square (x,y,size)
    /// @dev the coordinates must be % size and size can be 1, 3, 6, 12 and 24 to match the Quads in the land contract
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if there is at least one bit set in both the Map and the square
    function isSomePremium(
        uint256 x,
        uint256 y,
        uint256 size
    ) external view returns (bool) {
        return _s().premiumLand.intersect(x, y, size);
    }

    /// @notice Check if a map has at least one bit in common with some TileWithCoord
    /// @param tile the TileWithCoord to compare
    /// @return true if there is at least one bit set in both the Map and the TileWithCoord
    function isSomePremium(TileWithCoordLib.TileWithCoord memory tile) external view returns (bool) {
        return _s().premiumLand.intersect(tile);
    }

    /// @notice Check if a Map has at least one of the bits that are set in a TileWithCoord[]
    // @param tiles the TileWithCoord that must be included
    /// @return true if there is at least one bit set in both the Map and the TileWithCoord[]
    function isSomePremium(TileWithCoordLib.TileWithCoord[] memory tiles) external view returns (bool) {
        return _s().premiumLand.intersect(tiles);
    }

    /// @notice return the length of the internal list of tiles
    /// @dev used to iterate off-chain over the tiles.
    /// @return the length of the list
    function length() external view returns (uint256) {
        return _s().premiumLand.length();
    }

    /// @notice get the tile that is in certain position in the internal list of tiles
    /// @dev used to iterate off-chain over the tiles.
    /// @param index the index of the tile
    /// @return the tile that is in the position index in the list
    function at(uint256 index) external view returns (TileWithCoordLib.TileWithCoord memory) {
        return _s().premiumLand.at(index);
    }

    /// @notice get the internal list of tiles with pagination
    /// @dev used to iterate off-chain over the tiles.
    /// @param offset initial offset used to paginate
    /// @param limit amount of tiles to get
    /// @return the partial list of tiles
    function at(uint256 offset, uint256 limit) external view returns (TileWithCoordLib.TileWithCoord[] memory) {
        return _s().premiumLand.at(offset, limit);
    }

    /// @notice return the internal list of tiles
    /// @dev Use only for testing. This can be problematic if it grows too much !!!
    /// @return the list of internal tiles
    function getMap() external view returns (TileWithCoordLib.TileWithCoord[] memory) {
        return _s().premiumLand.getMap();
    }

    /// @notice count the amount of bits (lands) set inside a Map
    /// @return the quantity of lands
    function getLandCount() external view returns (uint256) {
        return _s().premiumLand.getLandCount();
    }

    /// @notice check if a square is adjacent (4-connected component) to the current map.
    /// @dev used to add a quad to a map, it is cheaper than isAdjacent(map)
    /// @param x the x coordinate of the square
    /// @param y the y coordinate of the square
    /// @param size the size of the square
    /// @return true if the square is 4-connected to the map
    function isAdjacent(
        uint256 x,
        uint256 y,
        uint256 size
    ) external view returns (bool) {
        return _s().premiumLand.isAdjacent(x, y, size);
    }

    function _s() internal pure returns (PremiumLandRegistryStorage storage ds) {
        bytes32 storagePosition = keccak256("PremiumLandRegistry.PremiumLandRegistryStorage");
        assembly {
            ds.slot := storagePosition
        }
    }

    uint256[50] private __gap;
}