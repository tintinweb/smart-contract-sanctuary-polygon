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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITutellusEnergy {
    /// @notice Emitted when event tokens are minted
    /// @param eventId Identificator of event
    /// @param account Address receiving tokens
    /// @param amount Minted amount
    event EventMint(bytes32 eventId, address account, uint256 amount);

    /// @notice Emitted when event tokens are burnt
    /// @param eventId Identificator of event
    /// @param account Address whose tokens are burnt
    /// @param amount Burnt amount
    event EventBurn(bytes32 eventId, address account, uint256 amount);

    /// @notice Returns unscaled balanceOf for some event
    /// @dev Unscaled balanceOf + staticBalanceOf
    /// @param account Address to return balance
    /// @return balance Balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Destroys amount tokens of account reducing total supply
    /// @dev Burns first static balance and then variable if needed
    /// @param account Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address account, uint256 amount) external;

    /// @notice Destroys balanceOf tokens of account reducing total supply
    /// @dev Burns all static and variable
    /// @param account Address to burn all its tokens from
    function burnAll(address account) external;

    /// @notice Destroys amount tokens related to an event of account reducing total supply
    /// @param eventId Identificator of an event
    /// @param account Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burnEvent(
        bytes32 eventId,
        address account,
        uint256 amount
    ) external;

    /// @notice Destroys amount static tokens of account reducing total supply
    /// @param account Address to burn tokens from
    /// @param amount Amount of static tokens to burn
    function burnStatic(address account, uint256 amount) external;

    /// @notice Destroys amount variable tokens of account reducing total supply
    /// @param account Address to burn tokens from
    /// @param amount Amount of variable tokens to burn
    function burnVariable(address account, uint256 amount) external;

    /// @notice Returns unscaled balanceOf for some event
    /// @dev Unscaled balanceOf + event static balance
    /// @param eventId Identificator for event
    /// @param account Address to return balance
    /// @return balance Balance
    function eventBalanceOf(bytes32 eventId, address account)
        external
        view
        returns (uint256);

    /// @notice Returns unscaled balanceOf for some event in a snapshot
    /// @dev Unscaled balanceOfAt + event static balance
    /// @param eventId Identificator for event
    /// @param account Address to return balance
    /// @param snapshotId Identificator for snapshot
    /// @return balance Balance
    function eventBalanceOfAt(
        bytes32 eventId,
        address account,
        uint256 snapshotId
    ) external view returns (uint256);

    /// @notice Returns total supply of tokens for some event
    /// @param eventId Identificator for event
    /// @return eventSupply Balance
    function eventTotalSupply(bytes32 eventId) external view returns (uint256);

    /// @notice Returns total supply of tokens for some event in a snapshot
    /// @param eventId Identificator for event
    /// @param snapshotId Identificator for snapshot
    /// @return eventSupply Balance
    function eventTotalSupplyAt(bytes32 eventId, uint256 snapshotId)
        external
        view
        returns (uint256);

    /// @notice Returns identificator of current snapshot
    /// @return id Current snapshot identificator
    function getCurrentSnapshotId() external view returns (uint256);

    /// @notice Initialize proxy
    function initialize() external;

    /// @notice Creates amount tokens and assigns them to account increasing total supply
    /// @dev Mints static tokens, using mint to keep standard
    /// @param account Address of the receiver of tokens
    /// @param amount Amount of static tokens to mint
    function mint(address account, uint256 amount) external;

    /// @notice Creates amount event tokens and assigns them to account increasing total supply
    /// @param eventId Identificator for event
    /// @param account Address of the receiver of tokens
    /// @param amount Amount of tokens to mint
    function mintEvent(
        bytes32 eventId,
        address account,
        uint256 amount
    ) external;

    /// @notice Creates amount tokens and assigns them to account increasing total supply
    /// @dev Mints static tokens
    /// @param account Address of the receiver of tokens
    /// @param amount Amount of static tokens to mint
    function mintStatic(address account, uint256 amount) external;

    /// @notice Creates amount tokens and assigns them to account increasing total supply
    /// @dev Mints variable tokens
    /// @param account Address of the receiver of tokens
    /// @param amount Amount of variable tokens to mint
    function mintVariable(address account, uint256 amount) external;

    /// @notice Returns the scaled equivalent of amount
    /// @param amount Unscaled amount to transform
    /// @return scaledAmount Scaled amount
    function scale(uint256 amount) external view returns (uint256);

    /// @notice Updates params to unscale
    /// @dev Sets rate and lastUpdateTimestamp
    /// @param newRate The new interest rate, in ray
    function setRate(uint256 newRate) external;

    /// @notice Creates a new snapshot
    function snapshot() external returns (uint256);

    /// @notice Returns the unscaled equivalent of amount
    /// @param amount scaled amount to transform
    /// @return scaledAmount Unscaled amount
    function unscale(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITutellusEnergyMultiplierManager {
    /// @notice Emitted when multiplier type of a contract is updated
    /// @param energyContract Address of the contract to update
    /// @param multiplierType New multiplier type for contract
    event SetMultiplierType(address energyContract, uint8 multiplierType);

    /// @notice Emitted when factor of a multiplier type is updated
    /// @param factor New factor for multiplierType
    /// @param multiplierType Multiplier type to update factor
    event SetFactor(uint256 factor, uint8 multiplierType);

    /// @notice Returns identificator for contract admin role
    function ENERGY_MULTIPLIER_MANAGER_ADMIN_ROLE()
        external
        view
        returns (bytes32);

    /// @notice Returns energy multiplier for a contract
    /// @dev Checks if staking, farming or none
    /// @param _contract Address of the contract
    /// @return energyMultiplier
    function getEnergyMultiplier(address _contract)
        external
        view
        returns (uint256);

    /// @notice Initialize proxy
    function initialize() external;

    /// @notice Update factor of a type of contracts
    /// @param factor New factor for _type
    /// @param _type Type of contract to update factor
    function setFactoryByType(uint256 factor, uint8 _type) external;

    /// @notice Assign a type for a contract
    /// @param _contract Address of the contract to update type
    /// @param _type New type for contract
    function setMultiplierType(address _contract, uint8 _type) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITutellusERC20 {

    /**
     * @dev Returns the amount of tokens burned.
     */
    function burned() external view returns (uint256);
    
    /**
     * @dev Mints `amount` tokens to `account`.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens.
     */
    function burn(uint256 amount) external;

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITutellusFactionManager {
    /// @notice Emitted when a new account enters a faction
    /// @param id Identificator of faction
    /// @param account Address of the new user in faction
    event FactionIn(bytes32 id, address account);

    /// @notice Emitted when a new account goes leaves a faction
    /// @param id Identificator of faction
    /// @param account Address of the user leaving faction
    event FactionOut(bytes32 id, address account);

    /// @notice Emitted when an account deposits in staking contract of faction
    /// @param id Identificator of faction
    /// @param account Address of the user
    /// @param amount Amount to deposit
    /// @param energy Amount of energy minted for depositing
    event Stake(bytes32 id, address account, uint256 amount, uint256 energy);

    /// @notice Emitted when an account withdraws from staking contract of faction
    /// @param id Identificator of faction
    /// @param account Address of the user
    /// @param amount Amount to withdraw
    /// @param energy Amount of energy burnt for withdrawing
    event Unstake(bytes32 id, address account, uint256 amount, uint256 energy);

    /// @notice Emitted when an account deposits in farming contract of faction
    /// @param id Identificator of faction
    /// @param account Address of the user
    /// @param amount Amount to deposit
    /// @param energy Amount of energy minted for depositing
    event StakeLP(bytes32 id, address account, uint256 amount, uint256 energy);

    /// @notice Emitted when an account withdraws from farming contract of faction
    /// @param id Identificator of faction
    /// @param account Address of the user
    /// @param amount Amount to withdraw
    /// @param energy Amount of energy burnt for withdrawing
    event UnstakeLP(
        bytes32 id,
        address account,
        uint256 amount,
        uint256 energy
    );

    /// @notice Emitted when a user migrates from one faction to another
    /// @param id Old faction identificator
    /// @param to New faction identificator
    /// @param account Address of the user
    event Migrate(bytes32 id, bytes32 to, address account);

    /// @notice Authorize an account to interact with Launchpad
    /// @param account Address of the user
    function authorize(address account) external;

    /// @notice Returns if an account is authorized to interact with Launchpad or not
    /// @param account Address of the user
    /// @return isAuthorized Whether or not is authorized
    function authorized(address account) external view returns (address);

    /// @notice Executes transferFrom of account, amount and token
    /// @dev Only callable by faction staking contracts
    /// @param account Account to transfer from
    /// @param amount Amount to transfer
    /// @param token Token to transfer from
    function depositFrom(
        address account,
        uint256 amount,
        address token
    ) external;

    /// @notice Returns addresses for staking and farming contracts of faction
    /// @param id Identificator of faction
    /// @return stakingContract Address of staking contract
    /// @return farmingContract Address of farming contract
    function faction(bytes32 id)
        external
        view
        returns (address stakingContract, address farmingContract);

    /// @notice Returns identificator of faction of an user
    /// @param account Address of the user
    /// @return id Identificator of faction
    function factionOf(address account) external view returns (bytes32);

    /// @notice Returns loss of energy for migrating faction
    /// @dev Losses variable energy gains
    /// @param account Address of the user
    /// @return loss Amount of energy loss for migrating
    function getMigrateLoss(address account) external view returns (uint256);

    /// @notice Initialize proxy
    function initialize() external;

    /// @notice Migrate to a different faction
    /// @dev Moves deposited amounts
    /// @param account Address of the user
    /// @param to Identificator of faction to move to
    function migrateFaction(address account, bytes32 to) external;

    /// @notice Deposit in staking contract of a faction
    /// @param id Identificator of faction
    /// @param account Address of the user
    /// @param amount Amount to deposit
    function stake(
        bytes32 id,
        address account,
        uint256 amount
    ) external;

    /// @notice Deposit in farming contract of a faction
    /// @param id Identificator of faction
    /// @param account Address of the user
    /// @param amount Amount to deposit
    function stakeLP(
        bytes32 id,
        address account,
        uint256 amount
    ) external;

    /// @notice Withdraw from staking contract of a faction
    /// @param account Address of the user
    /// @param amount Amount to withdraw
    function unstake(address account, uint256 amount) external;

    /// @notice Withdraw from farming contract of a faction
    /// @param account Address of the user
    /// @param amount Amount to withdraw
    function unstakeLP(address account, uint256 amount) external;

    /// @notice Update staking and farming contracts of a faction
    /// @param id Identificator of faction
    /// @param stakingContract Address of staking contract
    /// @param farmingContract Address of farming contract
    function updateFaction(
        bytes32 id,
        address stakingContract,
        address farmingContract
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITutellusLaunchpadStaking {
    /// @notice Emitted when proxy contract is initialized
    /// @param lastUpdate Deploy block number
    /// @param token Address of the ERC20 token to handle
    event Init(uint256 lastUpdate, address token);

    /// @notice Emitted when claiming rewards for an account
    /// @dev Claimable for third parties
    /// @param account Address rewarded
    event Claim(address account);

    /// @notice Emitted when an account desposits an amount of token
    /// @param account Address of the staker
    /// @param amount Amount of token to deposit
    /// @param energyMinted Amount of energy token minted (dervied from amount)
    event Deposit(address account, uint256 amount, uint256 energyMinted);

    /// @notice Emitted when an account withdraws deposited amount of token
    /// @param account Address of the staker
    /// @param amount Amount of token to withdraw
    /// @param burned Amount of token burnt as fee
    /// @param energyBurned Amount of energy token burnt (derived from amount)
    event Withdraw(
        address account,
        uint256 amount,
        uint256 burned,
        uint256 energyBurned
    );

    /// @notice Emitted when rewards of account are claimed
    /// @param account Address of the staker
    /// @param amount Amount of token distributed as reward
    event Rewards(address account, uint256 amount);

    /// @notice Emitted when autoreward is updated
    /// @dev Updated to !autoreward
    /// @param autoreward Indicates if autoreward when deposit/withdraw is active
    event ToggleAutoreward(bool autoreward);

    /// @notice Emitted when stored general data is updated
    /// @dev Updated when deposit, withdraw and claim
    /// @param balance Total deposited amount
    /// @param accRewardsPerShare Released per unit of token deposited
    /// @param lastUpdate Block number of last update
    /// @param stakers Number of current stakers
    event Update(
        uint256 balance,
        uint256 accRewardsPerShare,
        uint256 lastUpdate,
        uint256 stakers
    );

    /// @notice Emitted when stored data of staker is updated
    /// @param account Address of staker
    /// @param amount Staker deposited amount
    /// @param rewardDebt accRewardsPerShare of staker
    /// @param notClaimed Amount available to claim
    /// @param endInterval End interval for fee
    event UpdateData(
        address account,
        uint256 amount,
        uint256 rewardDebt,
        uint256 notClaimed,
        uint256 endInterval
    );

    /// @notice Emitted when fee configuration is updated
    /// @param minFee Fee after endInterval
    /// @param maxFee Fee in deposit block number
    /// @param feeInterval Amount of blocks to get minFee when withdraw
    event SetFees(uint256 minFee, uint256 maxFee, uint256 feeInterval);

    /// @notice Released per unit of token deposited
    function accRewardsPerShare() external view returns (uint256);

    /// @notice Indicates if autoreward when deposit/withdraw is active
    function autoreward() external view returns (bool);

    /// @notice Total deposited amount
    function balance() external view returns (uint256);

    /// @notice Get released tokens as reward of staking
    /// @dev Claimable for third parties
    /// @param account Address of staker
    function claim(address account) external;

    /// @notice Returns stored info about staker
    /// @param account Address of the staker
    /// @return amount Staker deposited amount
    /// @return rewardDebt accRewardsPerShare of staker
    /// @return notClaimed Amount available to claim
    /// @return endInterval End interval for fee
    /// @return minFee Fee after endInterval
    /// @return maxFee Fee in deposit block number
    /// @return feeInterval Amount of blocks to get minFee when withdraw
    /// @return energyDebt Scaled amount of energy
    function data(address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 notClaimed,
            uint256 endInterval,
            uint256 minFee,
            uint256 maxFee,
            uint256 feeInterval,
            uint256 energyDebt
        );

    /// @notice Stake amount of token for staker with address account
    /// @param account Address of the staker
    /// @param amount Amount of token to stake
    function deposit(address account, uint256 amount)
        external
        returns (uint256);

    /// @notice Returns energy multiplier of this contract
    function getEnergyMultiplier() external view returns (uint256);

    /// @notice Returns number of blocks to reach minFee
    function feeInterval() external view returns (uint256);

    /// @notice Returns nomber of blocks until account's endInterval
    /// @param account Address of the staker
    function getBlocksLeft(address account) external view returns (uint256);

    /// @notice Returns fee to withdraw of account
    /// @param account Address of the staker
    function getFee(address account) external view returns (uint256);

    /// @notice Returns deposited amount of account
    /// @param account Address of the staker
    function getUserBalance(address account) external view returns (uint256);

    /// @notice Initializes proxy
    /// @param tkn Address of token to handle
    /// @param minFee Fee after endInterval
    /// @param maxFee Fee in deposit block number
    /// @param feeInterval Amount of blocks to get minFee when withdraw
    function initialize(
        address tkn,
        uint256 minFee,
        uint256 maxFee,
        uint256 feeInterval
    ) external;

    /// @notice Block number of last update
    function lastUpdate() external view returns (uint256);

    /// @notice Returns fee to withdraw in the same block as deposit
    function maxFee() external view returns (uint256);

    /// @notice Returns fee to withdraw after endInterval
    function minFee() external view returns (uint256);

    /// @notice Returns rewards available to claim for account
    /// @param account Address of the staker
    function pendingRewards(address account) external view returns (uint256);

    /// @notice Update configuration of fees to withdraw
    /// @param minFee Fee after endInterval
    /// @param maxFee Fee in deposit block number
    /// @param feeInterval Amount of blocks to get minFee when withdraw
    function setFees(
        uint256 minFee,
        uint256 maxFee,
        uint256 feeInterval
    ) external;

    /// @notice Returns current number of stakers
    function stakers() external view returns (uint256);

    /// @notice Emitted when autoreward is updated
    /// @dev Updated to !autoreward
    function toggleAutoreward() external;

    /// @notice Address of the token handled by the contract
    function token() external view returns (address);

    /// @notice Withdraw deposited amount of token
    /// @param account Address of the staker
    /// @param amount Amount of token to withdraw
    function withdraw(address account, uint256 amount)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/// @title The interface of TutellusManager
/// @notice Manages smart contracts deployments, ids and protocol roles
interface ITutellusManager is IAccessControlUpgradeable {

    /** EVENTS */

    /// @notice Emitted when a new link is set between id and addr
    /// @param id Hashed identifier linked to proxy
    /// @param proxy Proxy contract address
    /// @param implementation Implementation contract address
    /// @param upgrade Flag: true when the proxy implementation is upgraded
    event Deployment(
        bytes32 indexed id,
        address indexed proxy,
        address indexed implementation,
        bool upgrade
    );

    /// @notice Emitted when an identifier is locked forever to an address
    /// @param id Hashed identifier linked to addr
    /// @param addr Address linked to id
    event Locked(
        bytes32 indexed id,
        address indexed addr
    );

    /// @notice Emitted when a new link is set between id and addr
    /// @param id Hashed identifier linked to addr
    /// @param addr Address linked to id
    event NewId(
        bytes32 indexed id,
        address indexed addr
    );

    /// @notice Emitted when verification state is updated
    /// @param addr Address of the verification updated
    /// @param verified New verification state
    /// @param sender Address of the transaction sender
    event SetVerification(
        address indexed addr,
        bool indexed verified,
        address indexed sender
    );

    /** METHODS */

    /// @notice Deploys / upgrades a proxy contract by deploying a new implementation
    /// @param id Hashed identifier linked to the proxy contract
    /// @param bytecode Bytecode for the new implementation
    /// @param initializeCalldata Calldata for the initialization of the new contract (if necessary)
    /// @return implementation Address of the new implementation
    function deploy(
        bytes32 id,
        bytes memory bytecode,
        bytes memory initializeCalldata
    ) external returns ( address implementation );

    /// @notice Deploys / overwrites a proxy contract with an existing implementation 
    /// @param id Hashed identifier linked to the proxy contract
    /// @param implementation Address of the existing implementation contract
    /// @param initializeCalldata Calldata for the initialization of the new contract (if necessary)
    function deployProxyWithImplementation(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) external;

    /// @notice Initializes the manager and sets necessary roles
    function initialize() external;

    /// @notice Locks immutably a link between an address and an id
    /// @param id Hashed identifier linked to the proxy contract
    function lock(
        bytes32 id
    ) external;

    /// @notice Returns whether a hashed identifier is locked or not
    /// @param id Hashed identifier linked to the proxy contract
    /// @return isLocked A boolean: true if locked, false if not
    function locked(
        bytes32 id
    ) external returns ( bool isLocked );

    /// @notice Returns the address linked to a hashed identifier
    /// @param id Hashed identifier
    /// @return addr Address linked to id
    function get(
        bytes32 id
    ) external view returns ( address addr );

    /// @notice Returns the hashed identifier linked to an address
    /// @param addr Address
    /// @return id Hashed identifier linked to addr
    function idOf(
        address addr
    ) external view returns ( bytes32 id );

    /// @notice Returns the implementation of the proxy
    /// @param proxy Proxy address
    /// @return implementation Implementation of the proxy
    function implementationByProxy(
        address proxy
    ) external view returns ( address implementation );

    /// @notice Returns whether an address is verified
    /// @param addr Address
    /// @return verified State of verification
    function isVerified(
        address addr
    ) external view returns ( bool verified );

    /// @notice Sets a link between a hashed identifier and an address
    /// @param id Hashed identifier
    /// @param addr Address
    function setId(
        bytes32 id,
        address addr
    ) external;

    /// @notice Sets a new verification state to an address
    /// @param addr Address
    /// @param verified New verification state
    function setVerification(
        address addr,
        bool verified
    ) external;

    /// @notice Upgrades a proxy contract with an existing implementation 
    /// @param id Hashed identifier linked to the proxy contract
    /// @param implementation Address of the existing implementation contract
    /// @param initializeCalldata Calldata for the initialization of the new contract (if necessary)
    function upgrade(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) external;

    /// @notice Returns upgrader role hashed identifier
    /// @return role Hashed string of UPGRADER_ROLE
    function UPGRADER_ROLE() external returns ( bytes32 role );

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITutellusRewardsVaultV2 {
    /// @notice Emitted when proxy is initialized
    /// @param lastUpdate Block number of the tx
    /// @param lastReleasedOffset Offset for previous releases
    event Init(uint256 lastUpdate, uint256 lastReleasedOffset);

    /// @notice Emitted when a new address to release tokens to is added
    /// @param account New address to release tokens to
    /// @param allocation Allocation assigned for new address
    event NewAddress(address account, uint256 allocation);

    /// @notice Emitted when allocation for an address is setted/updated
    /// @param account Address to set/update allocation
    /// @param allocation New allocation for account
    event NewAllocation(address account, uint256 allocation);

    /// @notice Emitted when the rewardPerBlock is updated
    /// @param rewardPerBlock New rate of released tokens per block
    event NewRewardPerBlock(uint256 rewardPerBlock);

    /// @notice Emitted when released tokens are distributed
    /// @param sender Address of the tx sender
    /// @param account Address of the allocated account to distribute funds
    /// @param amount Amount of tokens distributed
    event NewDistribution(address sender, address account, uint256 amount);

    /// @notice Initialize proxy
    function initialize() external;

    /// @notice Returns allocated addresses by its index
    /// @param index Identificator for accounts in mapping
    /// @return account
    function accounts(uint256 index) external view returns (address);

    /// @notice Include a new account to release tokens to
    /// @param account Address to set/update allocation
    /// @param allocation Array with percentages by allocated account. Sum must be 100 ether
    function add(address account, uint256[] memory allocation) external;

    /// @notice Set/update allocation percentages
    /// @param allocations Array with percentages by allocated account. Sum must be 100 ether
    function setAllocations(uint256[] memory allocations) external;

    /// @notice Amount of tokens available to distribute to an allocated account
    /// @dev Released - distributed
    /// @param account Address of allocated account
    /// @return availableAmount
    function available(address account) external view returns (uint256);

    /// @notice Total amount of tokens released up to some block number
    /// @return totalReleasedAmount
    function totalReleased() external view returns (uint256);

    /// @notice Amount of tokens released to an allocated account
    /// @param account Address of allocated account
    /// @return releasedAmount
    function released(address account) external view returns (uint256);

    /// @notice Claim available tokens to an allocated account
    /// @param account Address of allocated account
    /// @param amount Amount of tokens to distribute
    function distribute(address account, uint256 amount) external;

    /// @notice Amount of tokens distributed to an allocated account
    /// @param account Address of allocated account
    /// @return distributedAmount
    function distributed(address account) external view returns (uint256);

    /// @notice Returns percentage of distribution assigned to an account
    /// @param account Address of allocated account
    /// @return distributionPercentage
    function allocation(address account) external view returns (uint256);

    /// @notice Update amount of tokens released per block
    /// @param value New amount of tokens released per block
    function setRewardPerBlock(uint256 value) external;

    /// @notice Returns amount of tokens released per block
    /// @return rewardPerBlock Amount of tokens released per block
    function rewardPerBlock() external view returns (uint256);

    /// @notice Returns amount of allocated accounts
    /// @return totalAccounts Amount of allocated accounts
    function totalAccounts() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

abstract contract AccessControlProxyPausable is PausableUpgradeable {

    address public config;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        require(hasRole(role, account), string(
                    abi.encodePacked(
                        "AccessControlProxyPausable: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                ));
        _;
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        IAccessControlUpgradeable manager = IAccessControlUpgradeable(config);
        return manager.hasRole(role, account);
    }

    function __AccessControlProxyPausable_init(address manager) internal initializer {
        __Pausable_init();
        __AccessControlProxyPausable_init_unchained(manager);
    }

    function __AccessControlProxyPausable_init_unchained(address manager) internal initializer {
        config = manager;
    }

    function pause() public onlyRole(PAUSER_ROLE){
        _pause();
    }
    
    function unpause() public onlyRole(PAUSER_ROLE){
        _unpause();
    }

    function updateManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        config = manager;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../utils/AccessControlProxyPausable.sol";

contract UUPSUpgradeableByRole is AccessControlProxyPausable, UUPSUpgradeable {

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function implementation () public view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "contracts/interfaces/ITutellusERC20.sol";
import "contracts/interfaces/ITutellusEnergy.sol";
import "contracts/interfaces/ITutellusRewardsVaultV2.sol";
import "contracts/interfaces/ITutellusManager.sol";
import "contracts/interfaces/ITutellusFactionManager.sol";
import "contracts/interfaces/ITutellusEnergyMultiplierManager.sol";
import "contracts/interfaces/ITutellusLaunchpadStaking.sol";
import "contracts/utils/UUPSUpgradeableByRole.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract TutellusLaunchpadStaking is
    ITutellusLaunchpadStaking,
    UUPSUpgradeableByRole
{
    bytes32 public constant LAUNCHPAD_ADMIN_ROLE =
        keccak256("LAUNCHPAD_ADMIN_ROLE");
    bytes32 public constant LAUNCHPAD_REWARDS = keccak256("LAUNCHPAD_REWARDS");

    /// @inheritdoc ITutellusLaunchpadStaking
    bool public autoreward;

    /// @inheritdoc ITutellusLaunchpadStaking
    address public token;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public balance;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public minFee;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public maxFee;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public accRewardsPerShare;

    uint256 internal _released;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public lastUpdate;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public feeInterval;

    /// @inheritdoc ITutellusLaunchpadStaking
    uint256 public stakers;

    struct Data {
        uint256 amount;
        uint256 rewardDebt;
        uint256 notClaimed;
        uint256 endInterval;
        uint256 minFee;
        uint256 maxFee;
        uint256 feeInterval;
        uint256 energyDebt;
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    mapping(address => Data) public data;

    modifier onlyFactionManager() {
        require(
            msg.sender ==
                ITutellusManager(config).get(keccak256("FACTION_MANAGER")),
            "TutellusLaunchpadStaking: only faction manager"
        );
        _;
    }

    modifier update() {
        ITutellusRewardsVaultV2 rewardsInterface = ITutellusRewardsVaultV2(
            ITutellusManager(config).get(LAUNCHPAD_REWARDS)
        );
        uint256 released = rewardsInterface.released(address(this)) - _released;
        _released += released;
        if (balance > 0) {
            accRewardsPerShare += ((released * 1 ether) / balance);
        }
        lastUpdate = block.number;
        _;
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function initialize(
        address tkn,
        uint256 minFee_,
        uint256 maxFee_,
        uint256 feeInterval_
    ) public initializer {
        __AccessControlProxyPausable_init(msg.sender);
        autoreward = true;
        lastUpdate = block.number;
        token = tkn;
        minFee = minFee_;
        maxFee = maxFee_;
        feeInterval = feeInterval_;

        emit Init(lastUpdate, token);
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function getFee(address account) public view returns (uint256) {
        Data memory user = data[account];
        uint256 fee = block.number < user.endInterval
            ? user.feeInterval > 0
                ? (user.maxFee * (user.endInterval - block.number)) /
                    user.feeInterval
                : user.minFee
            : user.minFee;
        return fee > user.minFee ? fee : user.minFee;
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function getBlocksLeft(address account) public view returns (uint256) {
        if (block.number > data[account].endInterval) {
            return 0;
        } else {
            return data[account].endInterval - block.number;
        }
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function pendingRewards(address account) public view returns (uint256) {
        Data memory user = data[account];
        uint256 rewards = user.notClaimed;
        if (balance > 0) {
            ITutellusRewardsVaultV2 rewardsInterface = ITutellusRewardsVaultV2(
                ITutellusManager(config).get(LAUNCHPAD_REWARDS)
            );
            uint256 released = rewardsInterface.released(address(this)) -
                _released;
            uint256 total = ((released * 1 ether) / balance);
            rewards +=
                ((accRewardsPerShare - user.rewardDebt + total) * user.amount) /
                1 ether;
        }
        return rewards;
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function getUserBalance(address account) public view returns (uint256) {
        Data memory user = data[account];
        return user.amount;
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function getEnergyMultiplier() public view returns (uint256) {
        return _getEnergyMultiplier();
    }

    function syncBalance(address recipient) external onlyRole(LAUNCHPAD_ADMIN_ROLE) {
        ITutellusERC20 tokenInterface = ITutellusERC20(token);
        uint256 tokenBalance = tokenInterface.balanceOf(address(this));
        uint256 dif = tokenBalance - balance;
        if (dif != 0) tokenInterface.transfer(recipient, dif);
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function setFees(
        uint256 minFee_,
        uint256 maxFee_,
        uint256 feeInterval_
    ) public onlyRole(LAUNCHPAD_ADMIN_ROLE) {
        require(
            minFee_ <= maxFee_,
            "TutellusLaunchpadStaking: mininum fee must be greater or equal than maximum fee"
        );
        require(
            maxFee_ <= 100 ether,
            "TutellusLaunchpadStaking: maxFee cannot exceed 100 ether"
        );
        minFee = minFee_;
        maxFee = maxFee_;
        feeInterval = feeInterval_;
        emit SetFees(minFee, maxFee, feeInterval);
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function toggleAutoreward() public onlyRole(LAUNCHPAD_ADMIN_ROLE) {
        autoreward = !autoreward;
        emit ToggleAutoreward(autoreward);
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function deposit(address account, uint256 amount)
        public
        update
        onlyFactionManager
        returns (uint256)
    {
        require(
            amount > 0,
            "TutellusLaunchpadStaking: amount must be over zero"
        );

        ITutellusEnergy energyInterface = ITutellusEnergy(
            ITutellusManager(config).get(keccak256("ENERGY"))
        );

        Data storage user = data[account];

        _updateRewards(account);

        if (user.amount == 0) {
            stakers += 1;
        }

        user.endInterval = block.number + feeInterval;
        user.minFee = minFee;
        user.maxFee = maxFee;
        user.feeInterval = feeInterval;
        user.amount += amount;
        balance += amount;

        if (autoreward) {
            _reward(account);
        }

        uint256 energyMinted = (amount * _getEnergyMultiplier()) / 1 ether;
        uint256 energyScaled = energyInterface.scale(energyMinted);
        user.energyDebt += energyScaled;

        ITutellusFactionManager(msg.sender).depositFrom(account, amount, token);
        energyInterface.mintVariable(account, energyMinted);

        emit Update(balance, accRewardsPerShare, lastUpdate, stakers);
        emit UpdateData(
            account,
            user.amount,
            user.rewardDebt,
            user.notClaimed,
            user.endInterval
        );
        emit Deposit(account, amount, energyMinted);
        return energyScaled;
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function withdraw(address account, uint256 amount)
        public
        update
        onlyFactionManager
        returns (uint256, uint256)
    {
        require(
            amount > 0,
            "TutellusLaunchpadStaking: amount must be over zero"
        );
        Data storage user = data[account];

        require(
            amount <= user.amount,
            "TutellusLaunchpadStaking: user has not enough staking balance"
        );

        ITutellusERC20 tokenInterface = ITutellusERC20(token);
        ITutellusEnergy energyInterface = ITutellusEnergy(
            ITutellusManager(config).get(keccak256("ENERGY"))
        );

        uint256 energyShare = (amount * user.energyDebt) / user.amount;
        uint256 energyBurned = energyInterface.unscale(energyShare);
        uint256 energyBalance = energyInterface.balanceOf(account);

        require(
            energyBurned <= energyBalance,
            "TutellusLaunchpadStaking: need more energy to unstake"
        );

        user.energyDebt -= energyShare;
        energyInterface.burnVariable(account, energyBurned);

        _updateRewards(account);

        user.rewardDebt = accRewardsPerShare;
        user.amount -= amount;
        balance -= amount;

        if (user.amount == 0) {
            stakers -= 1;
        }

        uint256 burned = (amount * getFee(account)) / 1e20;

        if (autoreward) {
            _reward(account);
        }

        if (burned > 0) {
            amount -= burned;
            tokenInterface.burn(burned);
        }

        tokenInterface.transfer(account, amount);

        emit Update(balance, accRewardsPerShare, lastUpdate, stakers);
        emit UpdateData(
            account,
            user.amount,
            user.rewardDebt,
            user.notClaimed,
            user.endInterval
        );
        emit Withdraw(account, amount, burned, energyBurned);
        return (amount, energyShare);
    }

    /// @inheritdoc ITutellusLaunchpadStaking
    function claim(address account) public update {
        Data storage user = data[account];

        _updateRewards(account);

        require(
            user.notClaimed > 0,
            "TutellusLaunchpadStaking: nothing to claim"
        );

        _reward(account);

        emit Update(balance, accRewardsPerShare, lastUpdate, stakers);
        emit UpdateData(
            account,
            user.amount,
            user.rewardDebt,
            user.notClaimed,
            user.endInterval
        );
        emit Claim(account);
    }

    function _getEnergyMultiplier() internal view returns (uint256) {
        address _energyManager = ITutellusManager(config).get(
            keccak256("ENERGY_MULTIPLIER_MANAGER")
        );
        return
            ITutellusEnergyMultiplierManager(_energyManager)
                .getEnergyMultiplier(address(this));
    }

    function _updateRewards(address account) internal {
        Data storage user = data[account];
        uint256 diff = accRewardsPerShare - user.rewardDebt;
        user.notClaimed += (diff * user.amount) / 1 ether;
        user.rewardDebt = accRewardsPerShare;
    }

    function _reward(address account) internal {
        ITutellusRewardsVaultV2 rewardsInterface = ITutellusRewardsVaultV2(
            ITutellusManager(config).get(LAUNCHPAD_REWARDS)
        );
        uint256 amount = data[account].notClaimed;
        if (amount > 0) {
            data[account].notClaimed = 0;
            rewardsInterface.distribute(account, amount);
            emit Rewards(account, amount);
        }
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[45] private __gap;
}