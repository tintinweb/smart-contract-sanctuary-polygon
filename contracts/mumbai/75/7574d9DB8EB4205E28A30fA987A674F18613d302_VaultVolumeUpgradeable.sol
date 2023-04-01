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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IManagerUpgradeable} from './interfaces/IManagerUpgradeable.sol';
import {IOfficerUpgradeable} from './interfaces/IOfficerUpgradeable.sol';
import {ProfileTokens, VaultType} from './utils/Structures.sol';
import {IVaultMainUpgradeable} from './interfaces/IVaultMainUpgradeable.sol';
import {IUniswapV2Router02} from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IJoeRouter02} from '@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol';
import {IUniswapV2Factory} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Roles} from './utils/Roles.sol';
import {OraclePermission} from './utils/OraclePermission.sol';

/**
 * @title VaultMainUpgradeable
 * @author gotbit
 * @notice The contract responsible for managing funds of the profile,
 * transferring funds to other vaults, and managing liquidity.
 * @dev Can be paused, preventing all actions except for withdrawing funds.
 */

contract VaultMainUpgradeable is Initializable, Roles, IVaultMainUpgradeable {
    using SafeERC20 for IERC20;

    VaultType public VAULT_TYPE;
    address public manager;

    bool public paused;

    function __Vault_init(
        address manager_,
        VaultType vaultType
    ) internal onlyInitializing {
        manager = manager_;
        VAULT_TYPE = vaultType;
    }

    function init(address manager_) external virtual initializer {
        __Vault_init(manager_, VaultType.MAIN);
    }

    function transfer(
        ProfileTokens token,
        VaultType toVault,
        uint256 amount,
        OraclePermission.Data calldata oraclePermission
    ) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        // console.log('data length', msg.data.length);
        // console.log('signature length', signature.length);
        require(
            IManagerUpgradeable(manager).hasRole(WITHDRAWER_ROLE, msg.sender) ||
                IOfficerUpgradeable(officer).hasRoles(roles, msg.sender) ||
                OraclePermission.has(manager, oraclePermission),
            'no access'
        );

        address to = IManagerUpgradeable(manager).getVaultAddress(toVault);
        require(to != address(0), 'bad destination');

        require(token != ProfileTokens.LIQUIDITY, 'LIQUIDITY token is not transferable');
        require(address(this) != to, 'Same address');
        IERC20(
            token == ProfileTokens.BASE
                ? IManagerUpgradeable(manager).BASE()
                : IManagerUpgradeable(manager).QUOTE()
        ).safeTransfer(to, amount);
    }

    function setPaused(bool state) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        require(IOfficerUpgradeable(officer).hasRoles(roles, msg.sender), 'no access');

        paused = state;
    }

    function withdraw(address token, address to, uint256 amount) external {
        address officer = IManagerUpgradeable(manager).OFFICER();
        bool isAdmin = IOfficerUpgradeable(officer).hasRole(ADMIN_ROLE, msg.sender);
        require(
            isAdmin ||
                msg.sender == manager ||
                msg.sender == officer ||
                IManagerUpgradeable(manager).hasRole(WITHDRAWER_ROLE, msg.sender) ||
                IOfficerUpgradeable(officer).hasRole(SUPERADMIN_ROLE, msg.sender),
            'no access'
        );

        // if (isAdmin) IOfficerUpgradeable(officer).checkWithdrawCooldown(msg.sender);

        IERC20(token).safeTransfer(to, amount);
    }

    function WETH() external view returns (address) {
        address dex = IManagerUpgradeable(manager).getDexAddress();
        uint256 dexType = IManagerUpgradeable(manager).DEX_TYPE();

        if (dexType == 1) {
            // Uniswap V2-like DEXes

            return IUniswapV2Router02(dex).WETH();
        } else if (dexType == 2) {
            return IJoeRouter02(dex).WAVAX();
        } else {
            revert('unsupported dex');
        }
    }

    struct LiquidityParams {
        address dex;
        address base;
        address quote;
    }

    function addLiquidity(
        ManagerAddLiquidityParams calldata params,
        OraclePermission.Data calldata oraclePermission
    ) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        require(
            IManagerUpgradeable(manager).hasRole(WITHDRAWER_ROLE, msg.sender) ||
                IOfficerUpgradeable(officer).hasRoles(roles, msg.sender) ||
                OraclePermission.has(manager, oraclePermission),
            'no access'
        );
        require(!paused, 'vault paused');
        require(!IManagerUpgradeable(manager).profilePaused(), 'profile paused');
        LiquidityParams memory params2; // weird workaround for "stack too deep"
        {
            params2.dex = IManagerUpgradeable(manager).getDexAddress();
            params2.base = IManagerUpgradeable(manager).BASE();
            params2.quote = IManagerUpgradeable(manager).QUOTE();

            IERC20(params2.base).safeIncreaseAllowance(
                params2.dex,
                params.amountBaseDesired
            );
            IERC20(params2.quote).safeIncreaseAllowance(
                params2.dex,
                params.amountQuoteDesired
            );

            uint256 dexType = IManagerUpgradeable(manager).DEX_TYPE();
            if (dexType != 1 && dexType != 2) revert('unsupported dex');
        }

        IUniswapV2Router02(params2.dex).addLiquidity(
            params2.base,
            params2.quote,
            params.amountBaseDesired,
            params.amountQuoteDesired,
            params.amountBaseMin,
            params.amountQuoteMin,
            address(this),
            params.deadline
        );
    }

    function removeLiquidity(
        ManagerRemoveLiquidityParams calldata params,
        OraclePermission.Data calldata oraclePermission
    ) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        require(
            IManagerUpgradeable(manager).hasRole(WITHDRAWER_ROLE, msg.sender) ||
                IOfficerUpgradeable(officer).hasRoles(roles, msg.sender) ||
                OraclePermission.has(manager, oraclePermission),
            'no access'
        );
        require(!paused, 'vault paused');
        require(!IManagerUpgradeable(manager).profilePaused(), 'profile paused');
        LiquidityParams memory params2; // weird workaround for "stack too deep"
        {
            params2.dex = IManagerUpgradeable(manager).getDexAddress();
            params2.base = IManagerUpgradeable(manager).BASE();
            params2.quote = IManagerUpgradeable(manager).QUOTE();

            address pair = IUniswapV2Factory(IUniswapV2Router02(params2.dex).factory())
                .getPair(params2.base, params2.quote);

            IERC20(pair).safeIncreaseAllowance(params2.dex, params.liquidity);

            uint256 dexType = IManagerUpgradeable(manager).DEX_TYPE();
            if (dexType != 1 && dexType != 2) revert('unsupported dex');
        }

        IUniswapV2Router02(params2.dex).removeLiquidity(
            params2.base,
            params2.quote,
            params.liquidity,
            params.amountBaseMin,
            params.amountQuoteMin,
            address(this),
            params.deadline
        );
    }

    function remoteCall(address to, bytes calldata data) external {
        address officer = IManagerUpgradeable(manager).OFFICER();
        require(
            IOfficerUpgradeable(officer).hasRole(SUPERADMIN_ROLE, msg.sender),
            'no access'
        );

        (bool success, ) = to.call(data);
        require(success, 'remote call failed');
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

/**
 * @title VaultVolumeUpgradeable
 * @author gotbit
 */

// libraries
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {OraclePermission} from './utils/OraclePermission.sol';

// interfaces
import {IManagerUpgradeable} from './interfaces/IManagerUpgradeable.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {IVaultVolumeUpgradeable} from './interfaces/IVaultVolumeUpgradeable.sol';
import {IOfficerUpgradeable} from './interfaces/IOfficerUpgradeable.sol';
import {IUniswapV2Router02} from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IJoeRouter02} from '@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol';
import {IUniswapV2Factory} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import {Direction, VaultSwapParams, VaultType} from './utils/Structures.sol';

// contracts
import {VaultMainUpgradeable} from './VaultMainUpgradeable.sol';

/**
 * @title VaultVolumeUpgradeable
 * @author gotbit
 * @notice The contract responsible for trading with funds transferred to it.
 * @dev Inherits from the VaultMainUpgradeable contract.
 */

contract VaultVolumeUpgradeable is VaultMainUpgradeable, IVaultVolumeUpgradeable {
    using SafeERC20 for IERC20;

    /// @inheritdoc IVaultVolumeUpgradeable
    function init(
        address manager_
    )
        external
        virtual
        override(VaultMainUpgradeable, IVaultVolumeUpgradeable)
        initializer
    {
        __Vault_init(manager_, VaultType.VOLUME);
    }

    function _swapExactTokensForTokens(
        SwapExactTokensForTokensParams memory params
    ) internal returns (uint256[] memory amounts) {
        address dex = IManagerUpgradeable(manager).getDexAddress();
        IERC20(params.path[0]).safeIncreaseAllowance(dex, params.amountIn);

        uint256 dexType = IManagerUpgradeable(manager).DEX_TYPE();
        if (dexType != 1 && dexType != 2) revert('unsupported dex');

        address to = params.useReceiver
            ? IManagerUpgradeable(manager).requestReceiver(VAULT_TYPE)
            : address(this);

        return
            IUniswapV2Router02(dex).swapExactTokensForTokens(
                params.amountIn,
                params.amountOutMin,
                params.path,
                to,
                params.deadline
            );
    }

    function swapExactTokensForTokens(
        SwapExactTokensForTokensParams memory params,
        OraclePermission.Data calldata oraclePermission
    ) public returns (uint256[] memory amounts) {
        bytes32[] memory localRoles = new bytes32[](2);
        localRoles[0] = VAULT_TYPE == VaultType.LIMIT
            ? EXECUTOR_LIMIT_ROLE
            : EXECUTOR_VOLUME_ROLE;
        localRoles[1] = WITHDRAWER_ROLE;

        bytes32[] memory globalRoles = new bytes32[](2);
        globalRoles[0] = ADMIN_ROLE;
        globalRoles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        require(
            IManagerUpgradeable(manager).hasRoles(localRoles, msg.sender) ||
                IOfficerUpgradeable(officer).hasRoles(globalRoles, msg.sender) ||
                OraclePermission.has(manager, oraclePermission),
            'no access'
        );

        require(!paused, 'vault paused');
        require(!IManagerUpgradeable(manager).profilePaused(), 'profile paused');
        return _swapExactTokensForTokens(params);
    }

    function _swapTokensForExactTokens(
        SwapTokensForExactTokensParams memory params
    ) internal returns (uint256[] memory amounts) {
        address dex = IManagerUpgradeable(manager).getDexAddress();
        IERC20(params.path[0]).safeIncreaseAllowance(dex, params.amountInMax);

        uint256 dexType = IManagerUpgradeable(manager).DEX_TYPE();
        if (dexType != 1 && dexType != 2) revert('unsupported dex');

        address to = params.useReceiver
            ? IManagerUpgradeable(manager).requestReceiver(VAULT_TYPE)
            : address(this);

        return
            IUniswapV2Router02(dex).swapTokensForExactTokens(
                params.amountOut,
                params.amountInMax,
                params.path,
                to,
                params.deadline
            );
    }

    function swapTokensForExactTokens(
        SwapTokensForExactTokensParams memory params,
        OraclePermission.Data calldata oraclePermission
    ) public returns (uint256[] memory amounts) {
        bytes32[] memory localRoles = new bytes32[](2);
        localRoles[0] = VAULT_TYPE == VaultType.LIMIT
            ? EXECUTOR_LIMIT_ROLE
            : EXECUTOR_VOLUME_ROLE;
        localRoles[1] = WITHDRAWER_ROLE;

        bytes32[] memory globalRoles = new bytes32[](2);
        globalRoles[0] = ADMIN_ROLE;
        globalRoles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        require(
            IManagerUpgradeable(manager).hasRoles(localRoles, msg.sender) ||
                IOfficerUpgradeable(officer).hasRoles(globalRoles, msg.sender) ||
                OraclePermission.has(manager, oraclePermission),
            'no access'
        );

        require(!paused, 'vault paused');
        require(!IManagerUpgradeable(manager).profilePaused(), 'profile paused');
        return _swapTokensForExactTokens(params);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        SwapExactTokensForTokensParams memory params,
        OraclePermission.Data calldata oraclePermission
    ) external {
        bytes32[] memory localRoles = new bytes32[](2);
        localRoles[0] = VAULT_TYPE == VaultType.LIMIT
            ? EXECUTOR_LIMIT_ROLE
            : EXECUTOR_VOLUME_ROLE;
        localRoles[1] = WITHDRAWER_ROLE;

        bytes32[] memory globalRoles = new bytes32[](2);
        globalRoles[0] = ADMIN_ROLE;
        globalRoles[1] = SUPERADMIN_ROLE;

        address officer = IManagerUpgradeable(manager).OFFICER();
        require(
            IManagerUpgradeable(manager).hasRoles(localRoles, msg.sender) ||
                IOfficerUpgradeable(officer).hasRoles(globalRoles, msg.sender) ||
                OraclePermission.has(manager, oraclePermission),
            'no access'
        );

        require(!paused, 'vault paused');
        require(!IManagerUpgradeable(manager).profilePaused(), 'profile paused');

        address dex = IManagerUpgradeable(manager).getDexAddress();
        IERC20(params.path[0]).safeIncreaseAllowance(dex, params.amountIn);

        uint256 dexType = IManagerUpgradeable(manager).DEX_TYPE();
        if (dexType != 1 && dexType != 2) revert('unsupported dex');

        address to = params.useReceiver
            ? IManagerUpgradeable(manager).requestReceiver(VAULT_TYPE)
            : address(this);

        return
            IUniswapV2Router02(dex).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                params.amountIn,
                params.amountOutMin,
                params.path,
                to,
                params.deadline
            );
    }

    function _swap(VaultSwapParams memory swapParams) internal {
        address _base = IManagerUpgradeable(manager).BASE();
        address _quote = IManagerUpgradeable(manager).QUOTE();

        address[] memory path = new address[](2);

        if (swapParams.direction == Direction.BUY) {
            path[0] = _quote;
            path[1] = _base;

            SwapTokensForExactTokensParams memory params = SwapTokensForExactTokensParams(
                swapParams.useReceiver,
                swapParams.amountOut,
                swapParams.amountIn,
                path,
                swapParams.deadline
            );

            _swapTokensForExactTokens(params);
        } else {
            // sell
            path[0] = _base;
            path[1] = _quote;

            SwapExactTokensForTokensParams memory params = SwapExactTokensForTokensParams(
                swapParams.useReceiver,
                swapParams.amountIn,
                swapParams.amountOut,
                path,
                swapParams.deadline
            );

            _swapExactTokensForTokens(params);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol';
import {VaultType} from '../utils/Structures.sol';
import {OraclePermission} from '../utils/OraclePermission.sol';

/**
 * @title IManagerUpgradeable
 * @author gotbit
 * @notice Interface for the ManagerUpgradeable contract.
 * @dev The ManagerUpgradeable contract is the main contract of the profile.
 * It's responsible for providing addresses of the other contracts of the profile,
 * pausing the entire profile at once, profile level roles, managing receivers,
 * and providing access to the Officer contract managing the entire DEX Bot system.
 */

interface IManagerUpgradeable is IAccessControlUpgradeable {
    /// @notice Returns the ID of the EXECUTOR_VOLUME role.
    function EXECUTOR_VOLUME_ROLE() external pure returns (bytes32);

    /// @notice Returns the ID of the EXECUTOR_LIMIT role.
    function EXECUTOR_LIMIT_ROLE() external pure returns (bytes32);

    /// @notice Returns the ID of the WITHDRAWER role.
    function WITHDRAWER_ROLE() external pure returns (bytes32);

    /// @notice Returns the ID of the DEPLOYER role.
    function DEPLOYER_ROLE() external pure returns (bytes32);

    /// @notice Returns the address that deployed the profile.
    function DEPLOYER() external view returns (address);

    /// @notice Returns the address of the OfficerUpgradeable contract managing the profile.
    function OFFICER() external view returns (address);

    /// @notice Returns the address of the 'base' token.
    function BASE() external view returns (address);

    /// @notice Returns the address of the 'quote' token.
    function QUOTE() external view returns (address);

    /// @notice Returns the address of the DEX used corresponding to the DEX_ID.
    /// @dev Returns the DEX router address.
    function getDexAddress() external view returns (address);

    /// @notice Returns the DEX type. (1: Uniswap V2-like, 2: TraderJoe-like etc.)
    function DEX_TYPE() external view returns (uint256);

    /// @notice Returns the ID of the DEX used.
    function DEX_ID() external view returns (uint256);

    /// @notice Returns the address of the Beacon contract used to deploy receivers.
    /// @dev The beacon contract contains a pointer to the implementation contract.
    function RECEIVER_BEACON() external view returns (address);

    /// @notice Returns the address of the VaultMainUpgradeable contract of the profile.
    function MAIN_VAULT() external view returns (address);

    /// @notice Returns the address of the VaultVolumeUpgradeable contract of the profile.
    function VOLUME_VAULT() external view returns (address);

    /// @notice Returns the address of the VaultLimitUpgradeable contract of the profile.
    function LIMIT_VAULT() external view returns (address);

    /// @notice Returns whether the profile is paused. Pausing a profile is equivalent to pausing all vaults.
    function profilePaused() external view returns (bool);

    /// @notice Returns whether the momot wallet is paused. This restricts transfers from other vaults to the momot wallet.
    function momotPaused() external view returns (bool);

    /// @notice Returns the address of the Momot wallet.
    /// @dev Privileged users can send funds from the profile to this wallet.
    function momot() external view returns (address);

    /// @notice Returns the address of the receiver contract corresponding to the ID.
    function receivers(uint256 id) external view returns (address);

    /// @notice Returns the address of the last used receiver contract.
    function prevReceiver() external view returns (address);

    /// @notice Returns the type of the last used vault.
    function prevVault() external view returns (VaultType);

    /// @notice Returns the address of the receiver contract to be used for the swap.
    /// @dev This is called by the vaults on each swap that uses receivers.
    function requestReceiver(VaultType vault) external returns (address);

    /// @notice Returns the address of the vault.
    function getVaultAddress(VaultType vault) external view returns (address);

    /// @notice Returns all the receiver contracts.
    function getReceivers() external view returns (address[] memory);

    /// @notice Returns the amount of oracle permissions used by `address`.
    function nonces(address) external view returns (uint256);

    /// @notice Returns whether a permission is valid and matches the parameters provided.
    /// @dev This calls OfficerUpgradeable.hasPermission().
    /// @param user The address of the user.
    /// @param contract_ The address of the contract interacted with.
    /// @param expiresAt The timestamp at which the permission expires.
    /// @param nonce The nonce of the permission.
    /// @param data Function call data.
    /// @param signature The permission itself (the signature).
    /// @return has Whether the permission is valid.
    function hasPermission(
        address user,
        address contract_,
        uint256 expiresAt,
        uint256 nonce,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool has);

    /// @notice Returns whether the account has any of the profile level roles provided.
    /// @param roles The profile level roles to check.
    /// @param account The address of the account.
    function hasRoles(
        bytes32[] memory roles,
        address account
    ) external view returns (bool);

    /// @notice Marks the entire profile as paused. Pausing a profile is equivalent to pausing all vaults.
    function setProfilePaused(bool paused) external;

    /// @notice Marks the momot wallet as paused. This prevents transferring funds from other vaults to the momot wallet.
    function setMomotPaused(bool paused) external;

    /// @notice Sets the address of the Momot wallet.
    function setMomot(address momot_) external;

    struct InitParams {
        address deployer;
        address officer;
        address base;
        address quote;
        uint256 dexType;
        uint256 dexId;
        address receiverBeacon;
        address mainVault;
        address mmVault;
        address limitVault;
        address momot;
        address[] receivers;
        address[] executorsVolume;
        address[] executorsLimit;
        address[] withdrawers;
    }

    /// @notice Initializes the contract.
    function init(InitParams calldata params) external;

    /// @notice Grants roles to accounts.
    /// @dev The caller is subject to access control checks of the `grantRole` function.
    function batchGrantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Revokes roles from accounts.
    /// @dev The caller is subject to access control checks of the `revokeRole` function.
    function batchRevokeRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Revokes WITHDRAWER_ROLE from `accounts`. Can only be called by the superadmin.
    function revokeWithdrawer(address[] calldata accounts) external;

    /// @notice Returns the address of the Manager contract managing the profile.
    function manager() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProfileTokens, Order} from '../utils/Structures.sol';
import {IAccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol';

/**
 * @title IOfficerUpgradeable
 * @author gotbit
 * @notice Interface for the OfficerUpgradeable contract.
 * @dev The OfficerUpgradeable contract is the main contract of the system.
 * It's responsible for global roles, checking oracle permissions and managing DEXes.
 * Note that it is not responsible for managing and deploying profiles.
 * Profile contracts read from the Officer contract but don't write,
 * eliminating the need for access control for profiles.
 */

interface IOfficerUpgradeable is IAccessControlUpgradeable {
    // read

    /// @notice Returns the unique identifier for the superadmin role.
    function SUPERADMIN_ROLE() external view returns (bytes32);

    /// @notice Returns the unique identifier for the admin role.
    function ADMIN_ROLE() external view returns (bytes32);

    /// @notice Returns the address of the superadmin.
    function superAdmin() external view returns (address);

    /// @notice Returns the timestamp at which the user can withdraw funds.
    /// @dev Used only in adminWithdraw() available to ADMIN_ROLE.
    function withdrawCooldown(address user) external view returns (uint256);

    /// @notice Returns whether `account` has any of the global roles provided.
    /// @param roles The global level roles to check.
    /// @param account The address to check.
    function hasRoles(
        bytes32[] memory roles,
        address account
    ) external view returns (bool);

    /// @dev Returns whether a permission is valid and matches the parameters provided.
    /// @param permissionOracle The signer of the permission.
    /// @param user The address of the user.
    /// @param contract_ The address of the contract interacted with.
    /// @param expiresAt The timestamp at which the permission expires.
    /// @param nonce The nonce of the permission.
    /// @param data Function call data.
    /// @param signature The permission itself (the signature).
    /// @return Whether the permission is valid.
    function hasPermission(
        address permissionOracle,
        address user,
        address contract_,
        uint256 expiresAt,
        uint256 nonce,
        bytes calldata data,
        bytes calldata signature
    ) external view returns (bool);

    /// @notice Returns the DEX address associated with a DEX ID.
    /// @param dexId The ID of the DEX.
    /// @return The address of the DEX.
    function getDexAddress(uint256 dexId) external view returns (address);

    // write

    /// @notice Sets the superadmin address.
    /// @dev The old superadmin loses his role.
    /// @param superAdmin_ The new superadmin.
    function setSuperAdmin(address superAdmin_) external;

    /// @notice Grants roles to accounts.
    /// @dev The caller is subject to access control checks of the `grantRole` function.
    function batchGrantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Revokes roles from accounts.
    /// @dev The caller is subject to access control checks of the `revokeRole` function.
    function batchRevokeRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Allows the admin to withdraw funds with a 6 hour cooldown.
    /// @param vault The vault to withdraw from.
    /// @param token The token to withdraw.
    /// @param to The address to send the funds to.
    /// @param amount The amount of tokens to withdraw.
    function adminWithdraw(
        address vault,
        address token,
        address to,
        uint256 amount
    ) external;

    /// @notice Initializes the contract.
    /// @param superAdmin_ The address of the superadmin.
    /// @param dexAddresses The addresses of the DEXes. Index is the DEX ID.
    function init(address superAdmin_, address[] calldata dexAddresses) external;

    /// @notice Sets the DEX addresses associated with the specified DEX IDs.
    /// @param dexIds The IDs of the DEXes.
    /// @param dexAddresses The addresses of the DEXes.
    function batchSetDexAddress(
        uint256[] calldata dexIds,
        address[] calldata dexAddresses
    ) external;

    // function checkWithdrawCooldown(address user) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProfileTokens, VaultType} from '../utils/Structures.sol';
import {OraclePermission} from '../utils/OraclePermission.sol';

/**
 * @title IVaultMainUpgradeable
 * @author gotbit
 * @notice Interface for the VaultMainUpgradeable contract.
 * @dev The VaultMainUpgradeable contract is responsible for managing the funds
 * of the profile, transferring funds to other vaults, and managing liquidity.
 * It can be paused, preventing all actions except for withdrawing funds.
 */

interface IVaultMainUpgradeable {
    /// @notice Returns the type of the vault (main / volume / limit).
    function VAULT_TYPE() external view returns (VaultType);

    /// @dev Returns the manager address.
    /// @return The manager address.
    function manager() external view returns (address);

    /// @notice Returns whether the vault is paused.
    function paused() external view returns (bool);

    /// @notice Calls a function on another contract. Emergency measure.
    /// @param to The address of the contract to call.
    /// @param data The tx.data of the call.
    function remoteCall(address to, bytes calldata data) external;

    /// @notice Transfers funds to another vault.
    /// @param token The token to transfer.
    /// @param toVault The vault to transfer the funds to.
    /// @param amount The amount of funds to transfer.
    /// @param oraclePermission Permission from the oracle.
    function transfer(
        ProfileTokens token,
        VaultType toVault,
        uint256 amount,
        OraclePermission.Data calldata oraclePermission
    ) external;

    /// @notice Pauses / unpauses the vault.
    function setPaused(bool state) external;

    /// @notice Withdraws funds from the vault.
    /// @param token The token to withdraw.
    /// @param to The address to send the funds to.
    /// @param amount The amount of funds to withdraw.
    function withdraw(address token, address to, uint256 amount) external;

    /// @notice Initializes the vault.
    function init(address manager_) external;

    /// @notice Returns the address of the WETH token.
    /// @dev This calls the WETH() function of the DEX router.
    function WETH() external view returns (address);

    struct ManagerAddLiquidityParams {
        uint256 amountBaseDesired;
        uint256 amountQuoteDesired;
        uint256 amountBaseMin;
        uint256 amountQuoteMin;
        uint256 deadline;
    }

    /// @notice Adds liquidity to the DEX pair.
    /// @param params Parameters to be passed to the DEX router function.
    /// @param oraclePermission Permission from the oracle.
    function addLiquidity(
        ManagerAddLiquidityParams calldata params,
        OraclePermission.Data calldata oraclePermission
        // returns (
        //     uint256 amountA,
        //     uint256 amountB,
        //     uint256 liquidity
        // )
    ) external;

    struct ManagerRemoveLiquidityParams {
        uint256 liquidity;
        uint256 amountBaseMin;
        uint256 amountQuoteMin;
        uint256 deadline;
    }

    /// @notice Removes liquidity from the DEX pair.
    /// @param params Parameters to be passed to the DEX router function.
    /// @param oraclePermission Permission from the oracle.
    function removeLiquidity(
        ManagerRemoveLiquidityParams memory params,
        OraclePermission.Data calldata oraclePermission
        // returns (uint256 amountA, uint256 amountB)
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Direction} from '../utils/Structures.sol';
import {IVaultMainUpgradeable} from '../interfaces/IVaultMainUpgradeable.sol';
import {OraclePermission} from '../utils/OraclePermission.sol';

/**
 * @title IVaultVolumeUpgradeable
 * @author gotbit
 * @notice Interface for the VaultVolumeUpgradeable contract.
 * @dev The VaultVolumeUpgradeable contract is responsible for trading with
 * funds transferred to it. It inherits from the VaultMainUpgradeable
 * contract.
 */

interface IVaultVolumeUpgradeable is IVaultMainUpgradeable {
    struct SwapExactTokensForTokensParams {
        bool useReceiver;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        uint256 deadline;
    }

    struct SwapTokensForExactTokensParams {
        bool useReceiver;
        uint256 amountOut;
        uint256 amountInMax;
        address[] path;
        uint256 deadline;
    }

    /// @notice Initializes the vault.
    /// @param manager_ The address of the profile manager.
    function init(address manager_) external;

    /// @notice Mimics the swapExactTokensForTokens function of the DEX router.
    /// @param params Parameters to be passed to the DEX router function.
    /// @param oraclePermission Permission from the oracle.
    function swapExactTokensForTokens(
        SwapExactTokensForTokensParams memory params,
        OraclePermission.Data calldata oraclePermission
    ) external returns (uint256[] memory amounts);

    /// @notice Mimics the swapTokensForExactTokens function of the DEX router.
    /// @param params Parameters to be passed to the DEX router function.
    /// @param oraclePermission Permission from the oracle.
    function swapTokensForExactTokens(
        SwapTokensForExactTokensParams memory params,
        OraclePermission.Data calldata oraclePermission
    ) external returns (uint256[] memory amounts);

    /// @notice Mimics the swapExactTokensForTokensSupportingFeeOnTransferTokens function of the DEX router.
    /// @param params Parameters to be passed to the DEX router function.
    /// @param oraclePermission Permission from the oracle.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        SwapExactTokensForTokensParams memory params,
        OraclePermission.Data calldata oraclePermission
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IManagerUpgradeable} from '../interfaces/IManagerUpgradeable.sol';

library OraclePermission {
    struct Data {
        uint256 permExpiresAt;
        uint256 nonce;
        bytes signature;
    }

    function has(address manager, Data calldata data) internal returns (bool) {
        return
            IManagerUpgradeable(manager).hasPermission(
                msg.sender,
                address(this),
                data.permExpiresAt,
                data.nonce,
                msg.data[0:(msg.data.length - 256)],
                data.signature
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Roles {
    bytes32 internal constant DEPLOYER_ROLE = keccak256('DEPLOYER');
    bytes32 internal constant WITHDRAWER_ROLE = keccak256('WITHDRAWER');
    bytes32 internal constant EXECUTOR_VOLUME_ROLE = keccak256('EXECUTOR_VOLUME');
    bytes32 internal constant EXECUTOR_LIMIT_ROLE = keccak256('EXECUTOR_LIMIT');
    bytes32 internal constant ADMIN_ROLE = keccak256('ADMIN');
    bytes32 internal constant SUPERADMIN_ROLE = 0x00;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum ProfileTokens {
    BASE,
    QUOTE,
    LIQUIDITY
}

enum Direction {
    BUY,
    SELL
}

enum VaultType {
    MAIN,
    VOLUME,
    LIMIT,
    MOMOT
}

struct Order {
    uint256 price_min;
    uint256 price_max;
    uint256 volume;
    Direction dir;
}

struct VaultSwapParams {
    Direction direction;
    bool useReceiver;
    uint256 amountIn; // quote
    uint256 amountOut; // base
    uint256 deadline;
}