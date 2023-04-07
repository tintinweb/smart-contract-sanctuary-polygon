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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interface/IERC20MintableBurnableUpgradeable.sol";
import "../interface/IFactory.sol";
import "../interface/IStaking.sol";

contract Staking is
  Initializable,
  OwnableUpgradeable,
  IStaking
{
  using SafeERC20Upgradeable for IERC20MintableBurnableUpgradeable;
  
  uint256 internal constant yearInSeconds = 365 * 86400;
  
  uint128 public minStaking;
  uint128 public lockNumber;

  address[] public staker;

  address public factory;
  address public token; // token to stake

  bool public isStakePaused;
  bool public isUnstakePaused;

  // PreWithdraw Status
  // 0 => Burn => stake amount will be burnt partially
  // 1 => Reward => stake amount will become token rewards partially
  // 2 => Idle => can't be premature withdrawn
  PreWithdrawStatus public preWithdrawStatus;

  struct Lock {
    uint128 lockPeriodInSeconds;
    uint64 apy_d2;
    uint64 feeInPercent_d2;
    uint256 tokenStaked;
    uint256 pendingReward;
    uint256 limit;
    uint256 filled;
  }

  struct Stake {
    uint128 lockIndex;
    uint128 userStakedIndex;
    uint256 amount;
    uint256 reward;
    uint128 stakedAt;
    uint128 endedAt;
  }

  struct StakeData {
    uint256 stakedAmount;
    uint256 stakerPendingReward;
  }
    
  mapping(uint128 => Lock) internal lock;
  mapping(address => uint128) internal stakerIndex;
  mapping(address => Stake[]) internal staked;

  mapping(address => StakeData) public stakerDetail;

  /* ========== EVENTS ========== */

  event Staked(
    address indexed stakerAddress,
    uint128 lockPeriodInDays,
    uint256 amount,
    uint256 reward,
    uint128 stakedAt,
    uint128 endedAt
  );
  event Unstaked(
    address indexed stakerAddress,
    uint128 lockPeriodInDays,
    uint256 amount,
    uint256 reward,
    uint256 prematurePenalty,
    uint128 stakedAt,
    uint128 endedAt,
    uint128 unstakedAt,
    bool isPremature
  );

  modifier onlyFactoryOwner {
    require(_msgSender() == IFactory(factory).owner(), "!factoryOwner");
    _;
  }

  modifier isPermitted {
    require(
      _msgSender() == IFactory(factory).owner() ||
      _msgSender() == owner()
    , "!permitted");
    _;
  }

  modifier whenStakePaused {
    require(isStakePaused, "stake");
    _;
  }

  function init(
    address _token,
    uint64 _minStaking,
    uint128[] calldata _lockPeriodInDays,
    uint64[] calldata _apy_d2,
    uint64[] calldata _feeInPercent_d2,
    uint256[] calldata _limit,
    PreWithdrawStatus _preWithdrawStatus,
    address _owner
  ) external initializer {
    require(
      _lockPeriodInDays.length == _apy_d2.length &&
      _lockPeriodInDays.length == _feeInPercent_d2.length &&
      _lockPeriodInDays.length == _limit.length,
      "misslength"
    );

    factory = msg.sender;
    token = _token;
    lockNumber = uint128(_lockPeriodInDays.length);
    minStaking = _minStaking;
    preWithdrawStatus = _preWithdrawStatus;

    uint128 i = 0;
    do {
      lock[i] = Lock({
        lockPeriodInSeconds: _lockPeriodInDays[i] * 86400,
        apy_d2: _apy_d2[i],
        feeInPercent_d2: _feeInPercent_d2[i],
        tokenStaked: 0,
        pendingReward: 0,
        limit: _limit[i],
        filled: 0
      });

      ++i;
    } while(i < _lockPeriodInDays.length);

    _transferOwnership(_owner);
  }

  function totalPendingReward() external view virtual returns(uint256 total){
    for(uint128 i=0; i<lockNumber; ++i){
      total += lock[i].pendingReward;
    }
  }

  function totalTokenStaked() external view virtual returns(uint256 total){
    for(uint128 i=0; i<lockNumber; ++i){
      total += lock[i].tokenStaked;
    }
  }

  function stakerLength() external view virtual returns(uint256 length){
    length = staker.length;
  }

  function getStakerIndex(address _user) external view virtual returns(uint128){
    return stakerIndex[_user];
  }

  function locked(uint128 _lockIndex) external view virtual returns(
    uint128 lockPeriodInDays,
    uint64 apy_d2,
    uint64 feeInPercent_d2,
    uint256 tokenStaked,
    uint256 pendingReward,
    uint256 limit,
    uint256 filled
  ){
    lockPeriodInDays = lock[_lockIndex].lockPeriodInSeconds / 86400;
    apy_d2 = lock[_lockIndex].apy_d2;
    feeInPercent_d2 = lock[_lockIndex].feeInPercent_d2;
    tokenStaked = lock[_lockIndex].tokenStaked;
    pendingReward = lock[_lockIndex].pendingReward;
    limit = lock[_lockIndex].limit;
    filled = lock[_lockIndex].filled;
  }

  function userStakedLength(address _staker) external view virtual returns(uint256 length){
    length = staked[_staker].length;
  }

  function getStakedDetail(
    address _staker,
    uint128 _userStakedIndex
  ) external view virtual returns(
    uint128 lockPeriodInDays,
    uint256 amount,
    uint256 reward,
    uint256 prematurePenalty,
    uint128 stakedAt,
    uint128 endedAt
  ){
    // get stake data
    Stake memory stakeDetail = staked[_staker][_userStakedIndex];

    lockPeriodInDays = lock[stakeDetail.lockIndex].lockPeriodInSeconds / 86400;
    amount = stakeDetail.amount;
    reward = stakeDetail.reward;
    prematurePenalty = (stakeDetail.amount * lock[stakeDetail.lockIndex].feeInPercent_d2) / 10000;
    stakedAt = stakeDetail.stakedAt;
    endedAt = stakeDetail.endedAt;
  }

  function getTotalWithdrawableTokens(address _staker) external view virtual returns (uint256 withdrawableTokens) {
    for(uint128 i = 0; i < staked[_staker].length; ++i){
      if (staked[_staker][i].endedAt < block.timestamp) {
        withdrawableTokens += staked[_staker][i].amount + staked[_staker][i].reward;
      }
    }
  }

  function getTotalLockedTokens(address _staker) external view virtual returns (uint256 lockedTokens) {
    for (uint128 i = 0; i < staked[_staker].length; ++i) {
      if (staked[_staker][i].endedAt >= block.timestamp) {
        lockedTokens += staked[_staker][i].amount + staked[_staker][i].reward;
      }
    }
  }

  function getUserNextUnlock(address _staker) external view virtual returns (
    uint128 nextUnlockTime,
    uint256 nextUnlockRewards
  ) {
    for (uint128 i = 0; i < staked[_staker].length; ++i) {
      Stake memory stakeDetail = staked[_staker][i];
      if (stakeDetail.endedAt >= block.timestamp) {
        if(nextUnlockTime == 0 || nextUnlockTime > stakeDetail.endedAt) {
          nextUnlockTime = stakeDetail.endedAt;
          nextUnlockRewards = stakeDetail.reward;
        }
      }
    }
  }

  function getUserStakedTokensBeforeDate(
    address _staker,
    uint128 _beforeAt
  ) external view virtual returns (uint256 lockedTokens) {
    for (uint128 i = 0; i < staked[_staker].length; ++i) {
      Stake memory stakeDetail = staked[_staker][i];
      if (stakeDetail.stakedAt <= _beforeAt) {
        lockedTokens += stakeDetail.amount;
      }
    }
  }

  function calculateReward(
    uint256 _amount,
    uint128 _lockIndex
  ) public view virtual returns (uint256 reward) {
    Lock memory lockDetail = lock[_lockIndex];

    uint256 effectiveAPY = lockDetail.apy_d2 * lockDetail.lockPeriodInSeconds; 
    reward = (_amount * effectiveAPY) / (yearInSeconds * 10000);
  }

  function stake(
    uint256 _amount,
    uint128 _lockIndex
  ) external virtual {
    require(
      !isStakePaused &&
      _amount >= minStaking, // validate min amount to stake
      "bad"
    );

    // fetch sender
    address sender = _msgSender();

    // push staker if eligible
    if(staked[sender].length == 0){
      staker.push(sender);
      stakerIndex[sender] = uint128(staker.length - 1);
    }

    // adjust token amount to its limit
    Lock memory lockDetail = lock[_lockIndex];
    if(lockDetail.filled + _amount > lockDetail.limit) {
      _amount = lockDetail.limit - lockDetail.filled;

      // validate amount not zero
      require(_amount > 0, "zero");
    }

    // stake
    _stake(
      sender,
      _amount,
      _lockIndex
    );

    // take out token
    IERC20MintableBurnableUpgradeable(token).safeTransferFrom(
      sender,
      address(this),
      _amount
    );
  }

  function unstake(
    uint128 _userStakedIndex,
    uint256 _amount,
    address _staker
  ) external virtual {
    require(!isUnstakePaused, "!unstake");

    // worker check
    if(IFactory(factory).isWorker(_msgSender())){
      require(block.timestamp > staked[_staker][_userStakedIndex].endedAt, "premature");
    } else {
      _staker = _msgSender();
    }

    // validate existance of staker stake index
    require(staked[_staker].length > _userStakedIndex,  "bad");

    // get stake data
    Stake memory stakeDetail = staked[_staker][_userStakedIndex];
    if(block.timestamp > stakeDetail.endedAt){
      _amount = stakeDetail.amount;
    } else {
      // preWithdrawStatus validation
      require(preWithdrawStatus != PreWithdrawStatus.Idle, "premature restricted");

      if(stakeDetail.amount > _amount){
        uint256 remainderAmount = stakeDetail.amount - _amount;

        // stake remainder
        _stake(
          _staker,
          remainderAmount,
          stakeDetail.lockIndex
        );

        // adjust new staking amount to be partially withdrawn
        uint256 newPartialReward = calculateReward(_amount, stakeDetail.lockIndex);
        staked[_staker][_userStakedIndex].amount = _amount;
        staked[_staker][_userStakedIndex].reward = newPartialReward;

        // subtract staked amount & pending reward to staker
        stakerDetail[_staker].stakedAmount -= remainderAmount;
        stakerDetail[_staker].stakerPendingReward -= (stakeDetail.reward - newPartialReward);

        // subtract tokenStaked & pending reward to lock index
        lock[stakeDetail.lockIndex].tokenStaked -= remainderAmount;
        lock[stakeDetail.lockIndex].pendingReward -= (stakeDetail.reward - newPartialReward);
      }
    }

    _unstake(_staker, _userStakedIndex, stakeDetail.endedAt >= block.timestamp);
  }

  function _stake(
    address _sender,
    uint256 _amount,
    uint128 _lockIndex
  ) internal virtual {
    require(
      _lockIndex < lockNumber, // validate existance of lock index
      "!lockIndex"
    );

    // calculate reward
    uint256 reward = calculateReward(_amount, _lockIndex);

    // add staked amount & pending reward to sender
    stakerDetail[_sender].stakedAmount += _amount;
    stakerDetail[_sender].stakerPendingReward += reward;

    // add tokenStaked, pending reward & tokenFilled to lock index
    lock[_lockIndex].tokenStaked += _amount;
    lock[_lockIndex].pendingReward += reward;
    lock[_lockIndex].filled += _amount;
    
    // push stake struct to staked mapping
    staked[_sender].push(Stake({
      lockIndex: _lockIndex,
      userStakedIndex: uint128(staked[_sender].length),
      amount: _amount,
      reward: reward,
      stakedAt: uint128(block.timestamp),
      endedAt: uint128(block.timestamp) + lock[_lockIndex].lockPeriodInSeconds
    }));
    
    // emit staked event
    emit Staked(
      _sender,
      lock[_lockIndex].lockPeriodInSeconds / 86400,
      _amount,
      reward,
      uint128(block.timestamp),
      uint128(block.timestamp) + lock[_lockIndex].lockPeriodInSeconds
    );
  }

  function _unstake(
    address _sender,
    uint128 _userStakedIndex,
    bool _isPremature
  ) internal virtual {
    // get stake data
    Stake memory stakeDetail = staked[_sender][_userStakedIndex];

    // subtract staked amount & pending reward to sender
    stakerDetail[_sender].stakedAmount -= stakeDetail.amount;
    stakerDetail[_sender].stakerPendingReward -= stakeDetail.reward;

    // subtract tokenStaked & pending reward to lock index
    lock[stakeDetail.lockIndex].tokenStaked -= stakeDetail.amount;
    lock[stakeDetail.lockIndex].pendingReward -= stakeDetail.reward;
    
    // shifts struct from lastIndex to currentIndex & pop lastIndex from staked mapping
    staked[_sender][_userStakedIndex] = staked[_sender][staked[_sender].length - 1];
    staked[_sender][_userStakedIndex].userStakedIndex = _userStakedIndex;
    staked[_sender].pop();

    // remove staker if eligible
    if(
      staked[_sender].length == 0 &&
      staker[stakerIndex[_sender]] == _sender
    ){
      uint128 indexToDelete = stakerIndex[_sender];
      address stakerToMove = staker[staker.length - 1];

      staker[indexToDelete] = stakerToMove;
      stakerIndex[stakerToMove] = indexToDelete;
      
      delete stakerIndex[_sender];
      staker.pop();
    }

    // set withdrawable amount to transfer
    uint256 withdrawableAmount = stakeDetail.amount + stakeDetail.reward;

    if(_isPremature){
      // decrease tokenFilled
      lock[stakeDetail.lockIndex].filled -= stakeDetail.amount;

      // calculate penalty & staked amount to withdraw
      uint256 penaltyAmount = (stakeDetail.amount * lock[stakeDetail.lockIndex].feeInPercent_d2) / 10000;
      withdrawableAmount = stakeDetail.amount - penaltyAmount;

      // preWd handling
      // if burn => burn penaltyAmount
      // else => do nothing (penaltyAmount will stay & become reward in pool)
      if(preWithdrawStatus == PreWithdrawStatus.Burn) {
        // burn penalty
        IERC20MintableBurnableUpgradeable(token).burn(penaltyAmount);
      }
    }
    
    // send staked + reward to sender
    IERC20MintableBurnableUpgradeable(token).safeTransfer(
      _sender,
      withdrawableAmount
    );

    // emit unstaked event
    emit Unstaked(
      _sender,
      lock[stakeDetail.lockIndex].lockPeriodInSeconds / 86400,
      stakeDetail.amount,
      stakeDetail.reward,
      _isPremature ? (stakeDetail.amount * lock[stakeDetail.lockIndex].feeInPercent_d2) / 10000 : 0,
      stakeDetail.stakedAt,
      stakeDetail.endedAt,
      uint128(block.timestamp),
      _isPremature
    );
  }

  function _msgSender() internal view virtual override returns (address sender) {
    sender = super._msgSender();
    if(IFactory(factory).isTrustedForwarder(sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata data) {
    data = super._msgData();
    if(IFactory(factory).isTrustedForwarder(msg.sender)) {
      data = msg.data[:msg.data.length - 20];
    }
  }

  function setLimit(
    uint256 _amount,
    uint128 _lockIndex
  ) external virtual whenStakePaused onlyFactoryOwner {
    require(
      _amount > 0 &&
      _lockIndex < lockNumber, // validate existance of lock index
      "bad"
    );

    lock[_lockIndex].limit = _amount;

    // unpause
    toggleStakePause();
  }

  function setMin(uint64 _minStaking) external virtual whenStakePaused isPermitted {
    require(
      _minStaking > 0,
      "bad"
    );
    minStaking = _minStaking;

    // unpause
    toggleStakePause();
  }

  function setPeriodInDays(
    uint128 _lockIndex,
    uint128 _newLockPeriodInDays
  ) external virtual whenStakePaused isPermitted {
    require(lockNumber > _lockIndex, "bad");
    lock[_lockIndex].lockPeriodInSeconds = _newLockPeriodInDays * 86400;

    // unpause
    toggleStakePause();
  }

  function setPenaltyFee(
    uint128 _lockIndex,
    uint64 _feeInPercent_d2
  ) external virtual whenStakePaused isPermitted {
    require(lockNumber > _lockIndex, "bad");
    lock[_lockIndex].feeInPercent_d2 = _feeInPercent_d2;
    
    // unpause
    toggleStakePause();
  }

  function setAPY(
    uint128 _lockIndex,
    uint64 _apy_d2
  ) external virtual whenStakePaused isPermitted {
    require(lockNumber > _lockIndex, "bad");
    lock[_lockIndex].apy_d2 = _apy_d2;
    
    // unpause
    toggleStakePause();
  }

  function changePreWithdrawStatus(PreWithdrawStatus _newPreWithdrawStatus) external virtual whenStakePaused onlyFactoryOwner {
    // preWithdrawStatus check
    require(preWithdrawStatus != _newPreWithdrawStatus, "bad");

    // assign new preWd Status
    preWithdrawStatus = _newPreWithdrawStatus;

    // unpause
    toggleStakePause();
  }

  function emergencyWithdraw(
    address _token,
    uint256 _amount,
    address _receiver
  ) external virtual whenStakePaused onlyFactoryOwner {
    // adjust amount to wd
    uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
    if(_amount > balance) _amount = balance;

    IERC20MintableBurnableUpgradeable(_token).safeTransfer(
      _receiver,
      _amount
    );

    // unpause
    toggleStakePause();
  }

  function toggleStakePause() public virtual isPermitted {
    isStakePaused = !isStakePaused;
  }

  function toggleUnstakePause() external virtual isPermitted {
    isUnstakePaused = !isUnstakePaused;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IERC20MintableBurnableUpgradeable is IERC20MetadataUpgradeable {
  function mint(address to, uint256 amount) external;
  function burn(address to, uint256 amount) external;
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
  // PreWithdraw Status
  enum PreWithdrawStatus {
    Burn, // 0 => stake amount will be burnt partially
    Reward, // 1 => stake amount will become token rewards partially
    Idle // 2 => can't be premature withdrawn
  }

  function owner() external view returns (address);
  function isWorker(address) external view returns(bool);
  function isTrustedForwarder(address) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
  // PreWithdraw Status
  enum PreWithdrawStatus {
    Burn, // 0 => stake amount will be burnt partially
    Reward, // 1 => stake amount will become token rewards partially
    Idle // 2 => can't be premature withdrawn
  }

  function init(
    address _token,
    uint64 _minStaking,
    uint128[] calldata _lockPeriodInDays,
    uint64[] calldata _apy_d2,
    uint64[] calldata _feeInPercent_d2,
    uint256[] calldata _limit,
    PreWithdrawStatus _preWithdrawStatus,
    address _owner
  ) external;
}