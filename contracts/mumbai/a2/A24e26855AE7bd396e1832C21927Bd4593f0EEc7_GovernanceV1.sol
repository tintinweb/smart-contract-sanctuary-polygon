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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCast.toUint32(block.number), SafeCast.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _blockNumber,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._blockNumber <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace224 storage self,
        uint32 key,
        uint224 value
    ) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _key,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint224[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint224[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint224 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace160 storage self,
        uint96 key,
        uint160 value
    ) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self)
        internal
        view
        returns (
            bool exists,
            uint96 _key,
            uint160 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint160[] storage self,
        uint96 key,
        uint160 value
    ) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint160[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint160 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

pragma solidity 0.8.9;

import "../../interfaces/ISystemPause.sol";

abstract contract AbstractSystemPause {
    /// bool to store system status
    bool public systemPaused;
    /// System pause interface
    ISystemPause system;

    /* ========== ERROR STATEMENTS ========== */

    error UnauthorisedAccess();
    error SystemPaused();

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */
    modifier onlySystemPauseContract() {
        if (address(system) != msg.sender) revert UnauthorisedAccess();
        _;
    }

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */

    modifier whenSystemNotPaused() {
        if (systemPaused) revert SystemPaused();
        _;
    }

    function pauseSystem() external virtual onlySystemPauseContract {
        systemPaused = true;
    }

    function unpauseSystem() external virtual onlySystemPauseContract {
        systemPaused = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../core/security/AbstractSystemPause.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IAccess.sol";

import "../interfaces/IWeightCalculator.sol";
import "../rewards/staking/StakingManager.sol";
import "./Proposal.sol";
import "./Vote.sol";

contract GovernanceV1 is
    Proposal,
    Vote,
    AbstractSystemPause,
    Initializable,
    PausableUpgradeable
{
    /* ========== CONSTANTS ========== */

    /// Rebalancing factor to assist with division
    uint256 constant REBALANCING_FACTOR = 1000;

    /* ========== STATE VARIABLES ========== */

    /// Main access contract
    IAccess access;
    /// interface
    IToken token;
    /// Weight calculator interface
    IWeightCalculator weightCalculator;
    /// Staking Manager
    StakingManager staking;
    Proposers public proposers;
    /// Mapping of ID => proposals
    mapping(uint256 => ProposalData) private _proposals;
    /// Mapping of ID hash => bool to indicate whether the proposal exists
    mapping(uint256 => bool) private _proposalExists;
    /// Flat minimum number of accounts that must have voted in order for a proposal to be accepted
    uint256 public flatMinimum;
    uint256 public highThreshold;
    /// Counter for generating a human readable reference to the proposal
    uint32 id;
    /// Percentage threshold of total accounts that must have voted in order for a proposal to be accepted
    uint8 public quorumThreshold;

    /* ========== MODIFIERS ========== */

    /**
     @dev this modifier checks if the caller is a proposer 
     */

    modifier onlyProposers() {
        _onlyProposers();
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyExecutive() {
        _onlyExecutive();
        _;
    }

    /**
     @dev this modifier checks if the propossal is paused and reverts if true
     */

    modifier whenProposalNotPaused(uint32 _id) {
        if (_proposals[_id].paused) revert ProposalPaused(_id);
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    function initialize(
        address _accessAddress,
        address _systemPauseAddress,
        address _vextAddress,
        address _stakingManagerAddress,
        address _weightCalculatorAddress,
        uint256 _flatMinimum,
        uint256 _highThreshold,
        uint8 _quorumThreshold,
        Proposers _proposers
    ) public initializer {
        __Pausable_init();
        if (
            _vextAddress == address(0) ||
            _accessAddress == address(0) ||
            _stakingManagerAddress == address(0) ||
            _systemPauseAddress == address(0) ||
            _weightCalculatorAddress == address(0)
        ) revert AddressError();

        if (_highThreshold == 0) revert HighThresholdIsZero();

        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        token = IToken(_vextAddress);
        weightCalculator = IWeightCalculator(_weightCalculatorAddress);
        staking = StakingManager(_stakingManagerAddress);
        flatMinimum = _flatMinimum;
        highThreshold = _highThreshold;
        quorumThreshold = _quorumThreshold;
        proposers = _proposers;
    }

    /* ========== EXTERNAL ========== */

    /**
    @dev this function creates a non executable proposal.
    @param _description. The description for proposal. It's purpose is to check if the proposal already exists
    @param _url. The proposal's url.
    @param _start. Unix timestamp for voting start
    @param _end. Unix timestamp for voting end
    @param _voteModel. The model for voting
    @param _category. The proposal's category. It's purpose is to create a human readable reference
    @param _threshold. The proposal's quorum threshold. The threshold is a % of total accounts that own VEXT
    */
    function proposeNonExecutable(
        string memory _description,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual override onlyProposers whenNotPaused {
        if (_threshold == 0 || _threshold > 100) revert InvalidThreshold();
        if (_votingPeriodError(_start, _end))
            revert VotingPeriodError(_start, _end);

        uint256 proposalHash = uint256(keccak256(bytes(_description)));
        if (_proposalHashExists(proposalHash))
            revert ProposalExists(proposalHash);

        id++;

        string memory proposalRef = string(
            abi.encodePacked(Strings.toString(id), "_", _category)
        );

        ProposalData memory proposal = _proposal(
            proposalRef,
            _url,
            _start,
            _end,
            _voteModel,
            _category,
            false,
            _threshold
        );

        _proposals[id] = proposal;
        _proposalExists[proposalHash] = true;

        emit NewProposal(id, proposal);
    }

    /**
    @dev this function enables executive to cancel proposals
    @param _id. The id of the proposal
    Only callable by the executive account
    Callable when system and governance is unpaused
    */
    function cancelProposal(
        uint32 _id
    ) external virtual override onlyGovernance {
        ProposalData storage proposal = _proposals[_id];

        if (proposal.state != ProposalState.Pending)
            revert InvalidProposalState(_id, proposal.state);

        _changeProposalState(_id, ProposalState.Canceled);
    }

    /** 
    @dev this function is called when the user cast their vote during voting window.
    @param _id. The id hash for the proposal 
    @param _vote. The user's vote

    Callable when system and governance is unpaused
     */

    function castVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external whenNotPaused whenSystemNotPaused whenProposalNotPaused(_id) {
        if (_id > id) revert InvalidId(_id);
        if (token.delegates(msg.sender) == address(0)) revert InvalidVoter();
        if (hasVoted[_id][msg.sender]) revert VoteCasted(_id, msg.sender);

        uint256 current = block.timestamp;
        ProposalData storage proposal = _proposals[_id];

        if (proposal.state == ProposalState.Canceled)
            revert InvalidProposalState(_id, proposal.state);

        if (proposal.start > current || current > proposal.end)
            revert OutsideVotePeriod();

        if (proposal.state == ProposalState.Pending) {
            _changeProposalState(_id, ProposalState.Active);
        }

        uint256 weight = _getWeight(_id, msg.sender);

        if (weight < Math.sqrt(1e18)) revert InvalidVoter();

        _storeVote(_id, _vote, weight);
        _storeHasVoted(_id, msg.sender);
        weightCalculator.storePreNormalisedWeight(
            _id,
            _vote,
            weight,
            msg.sender
        );

        emit NewVote(_id, msg.sender, _vote, weight);
    }

    /**
    @dev function to store the normalised weight. Called after voting has ended. 
    Due to a potentially high number of voters for each vote, a pagination method is required.
    @param _id. The proposal id
    @param _pageLength. The page length
    @param _page. The selected page to calculate normalised weights for
    @param _vote. The vote selection to calculate the normalised weights for
    */

    function storeNormalisedWeight(
        uint32 _id,
        uint16 _pageLength,
        uint16 _page,
        VoteLib.Vote _vote
    )
        public
        whenNotPaused
        whenSystemNotPaused
        whenProposalNotPaused(_id)
        onlyGovernance
    {
        if (_id == 0) revert InvalidId(_id);

        ProposalData memory proposal = _proposals[_id];

        if (proposal.state != ProposalState.Active)
            revert InvalidProposalState(_id, proposal.state);

        if (block.timestamp <= proposal.end) revert VoteNotEnded();

        uint256 startIndex;

        if (_page > 0) {
            startIndex = _page * _pageLength + 1;
        } else {
            startIndex = 1;
        }
        uint256 endIndex = startIndex + _pageLength;

        weightCalculator.calculateNormalisedWeight(
            _id,
            _vote,
            startIndex,
            endIndex
        );
    }

    /**
    @dev this function returns the proposal outcome after the voting window has closed. 
    @param _id. The id of the proposal

    Only admin can get the proposal outcome

    Callable when system and governance is unpaused

    This function checks whether the voting window has closed
    It checks that flat minimum has been exceeded
    It checks whether the total voters is above the proposal threshold

    It returns the proposal outcome and the proposal state. 
    */
    function getProposalOutcome(
        uint32 _id
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        whenProposalNotPaused(_id)
        onlyGovernance
    {
        _checkProposalState(_id);

        ProposalData memory proposal = _proposals[_id];
        uint256 totalVoters = _getTotalVoters(_id);
        uint256 totalAccounts = token.getTotalAccounts();
        string memory outcome;

        if (totalVoters < flatMinimum) {
            outcome = "Flat minimum not reached";
            _changeProposalState(_id, ProposalState.Defeated);
        } else if (totalVoters * 100 < quorumThreshold * totalAccounts) {
            outcome = "Quorum threshold not reached";
            _changeProposalState(_id, ProposalState.Defeated);
        } else if (totalVoters * 100 < proposal.threshold * totalAccounts) {
            outcome = "Total voters below threshold";
            _changeProposalState(_id, ProposalState.Defeated);
        } else {
            outcome = _getOutcome(_id, _proposals[_id].voteModel);
        }

        _storeOutcome(_id, outcome);

        keccak256(abi.encodePacked(outcome)) ==
            keccak256(abi.encodePacked("Succeeded"))
            ? _changeProposalState(_id, ProposalState.Succeeded)
            : _changeProposalState(_id, ProposalState.Defeated);

        emit ProposalOutcome(_id, proposal.outcome, proposal.state);
    }

    /** 
    @dev this functions is called by admin when the proposal has been completed
    @param _id. The proposal's id

    Callable when system and governance is unpaused
     */

    function completeProposal(
        uint32 _id
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        whenProposalNotPaused(_id)
        onlyGovernance
    {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.state != ProposalState.Succeeded)
            revert InvalidProposalState(_id, proposal.state);

        _changeProposalState(_id, ProposalState.Executed);
    }

    /**
    @dev this function sets the quorum minimum number of accounts
    @param _newThreshold. The new minimum number of accounts

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setFlatMinimum(
        uint256 _newThreshold
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyExecutive
    {
        flatMinimum = _newThreshold;

        emit NewQuorumMinimumAccounts(flatMinimum);
    }

    /**
    @dev this function sets the minimum tokens a VEXT holder should hold to make a proposal
    @param _newThreshold. The amount in VEXT that a user should own in order to make a proposal

    _newThreshold is converted to wei internally. 

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setHighThreshold(
        uint256 _newThreshold
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyExecutive
    {
        if (_newThreshold < 1e18) revert ThresholdTooLow();
        highThreshold = _newThreshold;
        emit NewProposerThreshold(highThreshold);
    }

    /**
    @dev this function enables executive to change proposers
    @param _proposers. The new category of proposers allowed to make proposals

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setProposers(
        Proposers _proposers
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyGovernance
    {
        if (_proposers == Proposers.High && highThreshold == 0)
            revert HighThresholdIsZero();

        proposers = _proposers;
        emit NewProposers(_proposers);
    }

    /** 
    @dev this function sets the quorum % threshold for all proposals.
    @param _newThreshold. The new global threshold that all proposal must meet in order for a proposal to pass.

    Only callable by executive. 
    Callable when system and governance is unpaused

    It checks that _newThreshold is a valid input and that it is not below the flat minimum.
     */

    function setQuorumThreshold(
        uint8 _newThreshold
    )
        external
        virtual
        override
        whenNotPaused
        whenSystemNotPaused
        onlyExecutive
    {
        quorumThreshold = _newThreshold;
        emit NewQuorumThreshold(quorumThreshold);
    }

    /**
     * @dev function to pause contract only callable by admin
     */
    function pauseContract() external virtual override onlyGovernance {
        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     */
    function unpauseContract() external virtual override onlyGovernance {
        _unpause();
    }

    /**
     * @dev function to pause proposal by id
     */

    function pauseProposal(
        uint32 _id
    ) external virtual override onlyGovernance {
        if (_proposals[_id].paused) revert ProposalPaused(_id);

        _proposals[_id].paused = true;

        emit PausedProposal(_id);
    }

    /**
     * @dev function to pause proposal by id
     */

    function unpauseProposal(
        uint32 _id
    ) external virtual override onlyGovernance {
        if (!_proposals[_id].paused) revert ProposalUnpaused(_id);

        _proposals[_id].paused = false;

        emit UnpausedProposal(_id);
    }

    /**
    @dev this function returns the proposal core data for the given proposal id
    @param _id. The proposal id
    */
    function getProposal(
        uint32 _id
    ) external view virtual override returns (ProposalData memory) {
        ProposalData memory proposal = _proposals[_id];
        return proposal;
    }

    /**
    @dev this function returns an array of proposal data
    Id starts at 1.
    If there are no proposals, it returns an empty array
    */
    function getPaginatedProposals(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual override returns (ProposalData[] memory) {
        require(
            _direction == 0 || _direction == 1,
            "RewardDrop: invalid direction input"
        );
        if (_page == 0) {
            require(
                _direction == 1,
                "RewardDrop: page 0 must have direction 1"
            );
        }
        ProposalData[] memory dataArray = new ProposalData[](id);
        ProposalData memory datum;
        uint256 counter = 0;
        uint256 index;

        if (_page > 0) {
            index = _page * _pageLength + 1;
        } else {
            index = 1;
        }

        require(index <= id, "RewardDrop: index too high, reduce page length");

        uint256 length;

        if (id > 0) {
            if (_direction == 1) {
                length = index + _pageLength;

                for (uint256 i = index; i < length; i++) {
                    datum = _proposals[i];
                    dataArray[counter] = datum;
                    counter++;
                }
            } else {
                length = index - _pageLength;

                for (uint256 i = index - 1; i >= length; i--) {
                    datum = _proposals[i];
                    dataArray[counter] = datum;
                    counter++;
                }
            }
        }

        return dataArray;
    }

    /**
    @dev this fnuction returns the proposal count by returning id. 
    */

    function getProposalCount()
        external
        view
        virtual
        override
        returns (uint32)
    {
        return id;
    }

    /**
    @dev this function returns the total number of voters by id.
    @param _id. the proposal id.
    */
    function getTotalVoters(
        uint32 _id
    ) external view virtual override returns (uint256) {
        return _getTotalVoters(_id);
    }

    /* ========== PUBLIC ========== */

    /** 
    @dev this function returns the vote data by id
    @param _id. the proposal id.
    */

    function getVoteData(
        uint32 _id
    ) public view returns (VoteLib.VoteData memory) {
        return _getVoteData(_id);
    }

    /** 
    @dev this function returns the total voters for a given vote 
    @param _id. the proposal id.
    @param _vote. The vote to get the total voters for.
    */

    function getTotalVotersByVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) public view returns (uint256) {
        return weightCalculator.getTotalVotersByVote(_id, _vote);
    }

    /**
    @dev this function returns true if the account has voted for the given proposal id.
    @param _id. the proposal id.
    @param _account. The account address.
     */
    function hasAccountVoted(
        uint256 _id,
        address _account
    ) public view returns (bool) {
        return hasVoted[_id][_account];
    }

    /** 
    @dev this function returns the flat minimum 
    */

    function viewFlatMinimum() public view returns (uint256) {
        return flatMinimum;
    }

    /** 
    @dev this function returns the quorum threshold 
    */

    function viewQuorumThreshold() public view returns (uint8) {
        return quorumThreshold;
    }

    /** 
    @dev this function returns all vote data 
    */

    function getAllVoteData() public view returns (VoteLib.VoteData[] memory) {
        return _getAllVoteData(id);
    }

    function getWeightPublic(
        uint32 _proposalId,
        address _voterAddress
    ) external view returns (uint256) {
        return (_getWeight(_proposalId, _voterAddress));
    }

    /* ========== INTERNAL ========== */

    /**
     @dev this is an internal function which store's the proposal's outcome
    @param _id. The id of the proposal
    @param _outcome. The outcome of the proposal
     */

    function _storeOutcome(uint32 _id, string memory _outcome) internal {
        ProposalData storage proposal = _proposals[_id];
        proposal.outcome = _outcome;
    }

    /** 
    @dev internal function which calls the required count method depending on the Vote Model.
    @param _id. The id of the proposal
    @param _vote. The vote choice to store 
    @param _weight. The weight for the vote
    */

    function _storeVote(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.voteModel == VoteModel.ForAgainst) {
            _storeVoteForAgainst(_id, _vote, _weight);
        } else if (proposal.voteModel == VoteModel.ForAgainstAbstain) {
            _storeVoteForAgainstAbstain(_id, _vote, _weight);
        } else {
            _storeVoteMultiChoice(_id, _vote, _weight);
        }
    }

    /**
    @dev internal function to change the proposal's state
    @param _id. The proposal's id 
    @param _newState. The proposal's new state
     */
    function _changeProposalState(
        uint32 _id,
        ProposalState _newState
    ) internal {
        ProposalData storage proposal = _proposals[_id];
        proposal.state = _newState;

        emit NewProposalState(_id, proposal.state);
    }

    /**
    @dev internal function to check that the proposal is ready for preparing the outcome
    @param _id. The proposal's id 
     */

    function _checkProposalState(uint32 _id) internal view {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.state != ProposalState.Active)
            revert InvalidProposalState(_id, proposal.state);

        if (block.timestamp <= proposal.end) revert VoteNotEnded();
    }

    /**
    @dev this is an internal function that checks for any inconsistencies in the voting start and end date.
    @param _start. The proposed voting start time 
    @param _end. The proposed voting end time

    It checks that the start time and end time are in the future. 
    It checks that the start time is greater than the end time
     */
    function _votingPeriodError(
        uint256 _start,
        uint256 _end
    ) internal virtual returns (bool) {
        uint256 current = block.timestamp;
        return (_start <= current || _end <= current || _end <= _start);
    }

    /**
    @dev this is an internal function which returns true if the proposal hash already exists 
    @param _proposalHash. The proposal hash for the proposed proposal
     */
    function _proposalHashExists(
        uint256 _proposalHash
    ) internal virtual returns (bool) {
        return _proposalExists[_proposalHash];
    }

    /**
     @dev this is an internal function which returns the proposal's outcome as a 
     string for a more detailed explanation of the outcome
    @param _id. The id of the proposal
     */
    function _getOutcome(
        uint32 _id,
        VoteModel _voteModel
    ) internal view returns (string memory outcome) {
        if (
            _voteModel == VoteModel.ForAgainst ||
            _voteModel == VoteModel.ForAgainstAbstain
        ) {
            outcome = _getOutcomeForAgainst(_id);
            (_id);
        } else {
            outcome = _getOutcomeMultiChoice(_id);
        }

        return outcome;
    }

    /**
    @dev internal function which returns the weight. The weight is the square root of the voter's balance at the point of proposal's creation (blocknumber creation).
    @param _id. The id for the proposal
    @param _voter. The voter's account
    @return uint256. The weight
    */
    function _getWeight(
        uint32 _id,
        address _voter
    ) internal view returns (uint256) {
        ProposalData memory proposal = _proposals[_id];
        uint256 checkpoint = proposal.created;

        uint256 weight = Math.sqrt(
            ((token.getProposalVotes(_voter, checkpoint)) +
                staking.getUserBalanceAtBlockNumber(_voter, checkpoint))
        );
        return weight;
    }

    /**
    @dev this is an internal function which reverts if the caller is not a valid proposer
    
    SuperAdmin are not authorised to make proposals. 

    It accounts for staked and unstaked balances. 

    Executive and Admin are able to make proposals regardless of eligible Proposers. 

     */
    function _onlyProposers() internal view {
        if (proposers == Proposers.Exec) {
            require(_onlyAdmin(), "Unauthorised");
        } else if (proposers == Proposers.High) {
            require(
                (token.balanceOf(msg.sender) +
                    staking.getUserBalanceAtBlockNumber(
                        msg.sender,
                        block.number
                    )) >=
                    highThreshold ||
                    _onlyAdmin(),
                "Unauthorised"
            );
        } else if (proposers == Proposers.Community) {
            require(
                (token.balanceOf(msg.sender) +
                    staking.getUserBalanceAtBlockNumber(
                        msg.sender,
                        block.number
                    )) >
                    1e18 ||
                    _onlyAdmin(),
                "Unauthorised"
            );
        }
    }

    /**
    @dev internal function to check whether the caller is admin
     */

    function _onlyAdmin() internal view returns (bool) {
        return (access.userHasRole(access.executive(), msg.sender) ||
            access.userHasRole(access.admin(), msg.sender) ||
            access.userHasRole(access.governanceRole(), msg.sender));
    }

    function _onlyGovernance() internal view {
        access.onlyGovernanceRole(msg.sender);
    }

    function _onlyExecutive() internal view {
        require(
            access.userHasRole(access.executive(), msg.sender),
            "Governance: access forbidden"
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IGovernanceV1.sol";

/**
@title Proposal contract
*/

abstract contract Proposal is IGovernanceV1 {
    /**
    @dev internal function which stores and returns a new proposal
    @return ProposalData struct 
     */
    function _proposal(
        string memory _proposalRef,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        bool _isExecutable,
        uint8 _threshold
    ) internal view returns (ProposalData memory) {
        ProposalData memory proposal = ProposalData(
            _proposalRef,
            _url,
            _start,
            _end,
            block.number,
            ProposalState.Pending,
            _voteModel,
            _category,
            _isExecutable,
            false,
            _threshold,
            ""
        );

        return proposal;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/VoteLib.sol";

/**
@title Vote contract
*/

abstract contract Vote {
    using VoteLib for *;

    /* ========== STATE VARIABLES ========== */

    /// stores voteData for proposal Id
    mapping(uint256 => VoteLib.VoteData) voteData;
    /// stored when user has voted for proposal Id
    mapping(uint256 => mapping(address => bool)) hasVoted;

    /* ========== EVENTS ========== */

    event TotalVotesForAgainst(
        uint256 indexed id,
        uint256 forVotes,
        uint256 againstVotes
    );
    event TotalVotesForAgainstAbstain(
        uint256 indexed id,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes
    );
    event TotalVotesMultiChoice(
        uint256 indexed id,
        uint256 aVotes,
        uint256 bVotes,
        uint256 cVotes,
        uint256 abstainVotes
    );
    event NewVote(
        uint256 indexed id,
        address indexed voter,
        VoteLib.Vote vote,
        uint256 weight
    );

    /* ========== ERROR STATEMENTS ========== */

    error InvalidVote(Vote _vote);

    /* ========== INTERNAL ========== */

    /** 
    @dev internal function which stores votes for ForAgainst proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
     */
    function _storeVoteForAgainst(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteForAgainst(_vote, _weight);

        emit TotalVotesForAgainst(_id, data.forVotes, data.againstVotes);
    }

    /**
    @dev internal function which stores votes for ForAgainstAbstain proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
     */
    function _storeVoteForAgainstAbstain(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteForAgainstAbstain(_vote, _weight);

        emit TotalVotesForAgainstAbstain(
            _id,
            data.forVotes,
            data.againstVotes,
            data.abstainVotes
        );
    }

    /**
    @dev internal function which stores votes for MultiChoice proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
     */
    function _storeVoteMultiChoice(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteMultiChoice(_vote, _weight);

        emit TotalVotesMultiChoice(
            _id,
            data.aVotes,
            data.bVotes,
            data.cVotes,
            data.abstainVotes
        );
    }

    /**
    @dev internal function which stores bool to show user has voted
    @param _id. The vote data id
    @param _voter. The voter's address
     */

    function _storeHasVoted(uint256 _id, address _voter) internal {
        hasVoted[_id][_voter] = true;
    }

    /** @dev this function returns the outcome for for against proposals */

    function _getOutcomeForAgainst(
        uint256 _id
    ) internal view returns (string memory outcome) {
        VoteLib.VoteData memory data = voteData[_id];

        return data.getOutcomeForAgainst();
    }

    /** @dev this function returns the outcome for multichoice proposals */

    function _getOutcomeMultiChoice(
        uint256 _id
    ) internal view returns (string memory outcome) {
        VoteLib.VoteData memory data = voteData[_id];
        return data.getOutcomeMultiChoice();
    }

    /** 
    @dev internal function which returns the total votes for the given proposal
    @param _id. The vote data id.
     */
    function _getTotalVoters(uint256 _id) internal view returns (uint256) {
        return voteData[_id].totalVoters;
    }

    /**
    @dev internal function that returns vote data 
    @param _id. Vote data id
    */

    function _getVoteData(
        uint256 _id
    ) internal view returns (VoteLib.VoteData memory) {
        return voteData[_id];
    }

    /**
    @dev internal function that returns all vote data 
    @param _id. The latest proposal id.
    */
    function _getAllVoteData(
        uint256 _id
    ) internal view returns (VoteLib.VoteData[] memory) {
        VoteLib.VoteData[] memory voteDataArray = new VoteLib.VoteData[](_id);
        VoteLib.VoteData memory voteDatum;
        uint256 numberItems = _id;
        uint256 counter = 0;

        if (numberItems > 0) {
            for (uint256 i = 1; i <= numberItems; ) {
                voteDatum = voteData[i];
                voteDataArray[counter] = voteDatum;
                unchecked {
                    ++i;
                    ++counter;
                }
            }
        }
        return voteDataArray;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Access interface
/// @notice Access is the main contract which stores the roles
abstract contract IAccess is ERC165 {
    /* ========== FUNCTIONS ========== */

    function userHasRole(bytes32 _role, address _address)
        external
        view
        virtual
        returns (bool);

    function onlyGovernanceRole(address _caller) external view virtual;

    function onlyEmergencyRole(address _caller) external view virtual;

    function onlyTokenRole(address _caller) external view virtual;

    function onlyBoostRole(address _caller) external view virtual;

    function onlyRewardDropRole(address _caller) external view virtual;

    function onlyStakingRole(address _caller) external view virtual;

    function onlyStakingPauserRole(address _caller) external view virtual;

    function onlyStakingFactoryRole(address _caller) external view virtual;

    function onlyStakingManagerRole(address _caller) external view virtual;

    function executive() public pure virtual returns (bytes32);

    function admin() public pure virtual returns (bytes32);

    function deployer() public pure virtual returns (bytes32);

    function emergencyRole() public pure virtual returns (bytes32);

    function tokenRole() public pure virtual returns (bytes32);

    function pauseRole() public pure virtual returns (bytes32);

    function governanceRole() public pure virtual returns (bytes32);

    function boostRole() public pure virtual returns (bytes32);

    function stakingRole() public pure virtual returns (bytes32);

    function rewardDropRole() public pure virtual returns (bytes32);

    function stakingFactoryRole() public pure virtual returns (bytes32);

    function stakingManagerRole() public pure virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IGovernanceV1 is ERC165 {
    /* ========== TYPE DECLARATIONS ========== */

    struct ProposalData {
        string proposalRef;
        string url;
        uint256 start;
        uint256 end;
        uint256 created;
        ProposalState state;
        VoteModel voteModel;
        string category;
        bool isExecutable;
        bool paused;
        uint8 threshold;
        string outcome;
    }

    struct ExecutableData {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum Proposers {
        Exec,
        High,
        Community
    }

    enum VoteModel {
        ForAgainst,
        ForAgainstAbstain,
        MultiChoice
    }

    /* ========== EVENTS ========== */

    event NewProposal(uint32 indexed id, ProposalData proposal);
    event NewQuorumThreshold(uint96 newThreshold);
    event NewQuorumMinimumAccounts(uint256 newThreshold);
    event NewProposerThreshold(uint256 newThreshold);
    event NewProposers(Proposers proposers);
    event ProposalCancelled(uint32 indexed id);
    event NewProposalState(uint32 indexed id, ProposalState proposalState);
    event ProposalOutcome(
        uint32 indexed id,
        string outcome,
        ProposalState proposalState
    );
    event PausedProposal(uint32 indexed id);
    event UnpausedProposal(uint32 indexed id);

    /* ========== REVERT STATEMENTS ========== */

    error ProposalExists(uint256 proposalHash);
    error AddressError();
    error VotingPeriodError(uint256 start, uint256 end);
    error InvalidProposalState(uint32 id, ProposalState state);
    error VoteCasted(uint32 id, address voter);
    error OutsideVotePeriod();
    error VoteNotEnded();
    error InvalidVoter();
    error ProposalPaused(uint32 id);
    error ProposalUnpaused(uint32 id);
    error HighThresholdIsZero();
    error InvalidThreshold();
    error InvalidId(uint32 id);
    error ReducePageLength(uint32 id, uint16 pageLength, uint256 index);
    error ThresholdTooLow();

    /* ========== FUNCTIONS ========== */

    function proposeNonExecutable(
        string memory _description,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual;

    function setFlatMinimum(uint256 _newThreshold) external virtual;

    function setHighThreshold(uint256 _newThreshold) external virtual;

    function setQuorumThreshold(uint8 _newThreshold) external virtual;

    function setProposers(Proposers _proposers) external virtual;

    function cancelProposal(uint32 _id) external virtual;

    function completeProposal(uint32 _id) external virtual;

    function getProposal(
        uint32 _id
    ) external view virtual returns (ProposalData memory);

    function getPaginatedProposals(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual returns (ProposalData[] memory);

    function getProposalCount() external view virtual returns (uint32);

    function getProposalOutcome(uint32 _id) external virtual;

    function getTotalVoters(uint32 _id) external view virtual returns (uint256);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function pauseProposal(uint32 _id) external virtual;

    function unpauseProposal(uint32 _id) external virtual;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

abstract contract IRace {
    struct PoolState {
        uint256 poolId;
        string url;
        bytes poolDescription;
        address poolAddress;
        address rewardPoolAddress;
        uint256 totalTokensStaked;
        uint256 numberOfUsersStaked;
        uint256 maximumNumberOfStakers;
        uint256 waitingRoomOpenTime;
        uint256 raceStartTime;
        uint256 raceEndTime;
        uint256 claimTimeDate;
        uint256 poolInterestRateInBasisPoints;
        uint256 minimumStakePerUser;
        uint256 maximumStakePerUser;
        bool isPoolInitialized;
        bool isPoolDisabled;
    }

    struct PoolInitiator {
        string _name;
        string _type;
        string _poolDescription;
        string _url;
        uint256 interestRateInBasisPoints;
        uint256 waitingRoomOpenDate;
        uint256 raceStartDate;
        uint256 raceEndDate;
        uint256 minimumStakePeruser;
        uint256 maximumStakePerUser;
        uint256 claimTimeAfterEndtime;
        uint256 maximumNumberOfStakers;
        uint256 maximumInterestRateInBasisPoints;
        uint256[] pitStopDates;
    }

    function _freeFromEmptyValues(PoolInitiator memory init) internal pure returns (bool) {
        if (
            bytes(init._name).length == 0 ||
            bytes(init._type).length == 0 ||
            bytes(init._url).length == 0 ||
            init.interestRateInBasisPoints == 0 ||
            init.waitingRoomOpenDate == 0 ||
            init.raceStartDate == 0 ||
            init.raceEndDate == 0 ||
            init.minimumStakePeruser == 0 ||
            init.maximumStakePerUser == 0 ||
            init.maximumNumberOfStakers == 0 ||
            init.maximumInterestRateInBasisPoints == 0
        ) {
            return false;
        } else {
            return true;
        }
    }

    function _validateInputs(PoolInitiator memory init) internal view returns (bool) {
        require(init.interestRateInBasisPoints > 0 && init.interestRateInBasisPoints <= init.maximumInterestRateInBasisPoints, "interest rate must be > 0 & < maximumInterestRateInBasisPoints");
        require(init.waitingRoomOpenDate > 0 && init.waitingRoomOpenDate > block.timestamp, "waitingRoomOpenDate must be > 0 && > block.timestamp");
        require(init.raceStartDate > 0 && init.raceStartDate > init.waitingRoomOpenDate, "raceStartDate must be > 0 &&  waitingRoomOpenDate");
        require(init.raceEndDate > 0 && init.raceEndDate > init.raceStartDate, "raceEndDate must be > 0 && raceStartDate");
        require(init.minimumStakePeruser > 0, "minimum stake must be > 0");
        require(init.maximumStakePerUser > 0 && init.maximumStakePerUser > init.minimumStakePeruser, "maximumStakePerUser must be > 0 && minimumStakePerUser");
        require(_validatePitStopDates(init.pitStopDates), "invalid pit stop dates, pls fix!");

        return true;
    }

    function _validatePitStopDates(uint256[] memory arr) internal pure returns(bool) {
        uint length = arr.length;

        if (length == 0 || length == 1) {
            return true;
        }

        for (uint256 i = 0; i < length - 1; i++) {
            if (arr[i] >= arr[i + 1]) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title RewardPool interface
/// @notice RewardPool facilitates the transfer of stakin rewards
abstract contract IRewardPool is ERC165 {
    function fundStaker(address to, uint256 amount) external virtual;

    function withdraw(uint256 amount, address recepient) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IStaking is ERC165 {
    /* ========== EVENTS ========== */

    event InitializedPool(
        uint256 waitingRoomOpenTime,
        uint256 raceStartTime,
        uint256 interestRateInBps,
        uint256 minimumStakingPerUser,
        uint256 maximumStakingPerUser,
        uint256 maximumReward,
        uint256 raceEndTime,
        uint256 claimTimeAfterEndTime,
        uint256 maximumNumberOfStakers,
        uint256[] pitStopDates,
        bool isInitialized
    );

    event Staked(
        address indexed staker,
        uint256 indexed amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event StakedFor(
        address indexed benefactor,
        address beneficiary,
        uint256 indexed amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event Unstaked(
        address indexed staker,
        uint256 indexed amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event ClaimedRewards(
        address indexed staker,
        uint256 indexed amount,
        uint256 totalBalance
    );

    event PoolDisabled(address caller, address pool, bool isDisabled);

    event StakersCountChanged(
        uint256 previousCount,
        uint256 newCount,
        address indexed caller
    );

    event MaximumInterestRateChanged(
        uint256 previousRate,
        uint256 currentRate,
        address indexed caller
    );

    /* ========== REVERT STATEMENTS ========== */

    error Staking__InsufficientTokens();
    error Staking__ZeroAmountNotAllowed();
    error Staking__PoolLimitReached();
    error Staking__BelowMinimumStake();
    error Staking__AboveMaximumStakePerUser();
    error Staking__AboveMaximumStake();
    error Staking__DepositPeriodHasPassed();
    error Staking__NoClaimableRewardsLeftInThePreviousPeriod();
    error Staking__NoClaimableRewards();
    error Staking__CannotRolloverWithdrawInstead();
    error Staking__StillInWaitingPeriod();
    error Staking__WaitTillRaceIsOver();
    error Staking__WaitForDepositToBegin();
    error Staking__AccessForbidden();
    error Staking__MaximumStakersExceeded();

    /* ========== FUNCTIONS ========== */

    function deposit(uint256 amount) external virtual;

    function viewUserBalance(
        address account
    ) external view virtual returns (uint256);

    function viewTotalRewards() external view virtual returns (uint256);

    function viewTotalRewardsAdmin(
        address account
    ) external view virtual returns (uint256);

    function payClaimableReward() external virtual;

    function unstake() external virtual;

    function totalStakers() external view virtual returns (uint256);

    function totalStaked() external view virtual returns (uint256);

    function printPitStopDates()
        external
        view
        virtual
        returns (uint256[] memory);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function disablePool() external virtual;

    function getPastCheckpoint(
        address account,
        uint256 blockNumber
    ) external view virtual returns (uint256);

    function hasPoolExpired() external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Pause interface
abstract contract ISystemPause is ERC165 {
    /* ========== REVERT STATEMENTS ========== */

    error SystemPaused();
    error UnauthorisedAccess();
    error InvalidAddress();
    error InvalidModuleName();
    error UpdateStakingManagerAddress();
    error CallUnsuccessful(address contractAddress);

    /* ========== EVENTS ========== */

    event PauseStatus(uint indexed moduleId, bool isPaused);
    event NewModule(
        uint indexed moduleId,
        address indexed contractAddress,
        string indexed name
    );
    event UpdatedModule(
        uint indexed moduleId,
        address indexed contractAddress,
        string indexed name
    );

    /* ========== FUNCTIONS ========== */

    function setStakingManager(address _stakingManagerAddress) external virtual;

    function pauseModule(uint id) external virtual;

    function unPauseModule(uint id) external virtual;

    function createModule(
        string memory name,
        address _contractAddress
    ) external virtual;

    function updateModule(uint id, address _contractAddress) external virtual;

    function getModuleStatusWithId(
        uint id
    ) external view virtual returns (bool isActive);

    function getModuleStatusWithAddress(
        address _contractAddress
    ) external view virtual returns (bool isActive);

    function getModuleAddressWithId(
        uint id
    ) external view virtual returns (address module);

    function getModuleIdWithAddress(
        address _contractAddress
    ) external view virtual returns (uint id);

    function getModuleIdWithName(
        string memory name
    ) external view virtual returns (uint id);

    function getModuleNameWithId(
        uint id
    ) external view virtual returns (string memory name);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IToken is ERC165 {
    /* ========== EVENTS ========== */

    event TotalAccounts(uint256 totalAccounts);

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */

    /* ========== FUNCTIONS ========== */

    function mint(address to, uint256 amount) external virtual;

    function burn(address from, uint256 amount) external virtual;

    function getTotalAccounts() external view virtual returns (uint256);

    function getPastVotes(
        address account,
        uint256 blockNumber
    ) external view virtual returns (uint256);

    function getProposalVotes(
        address account,
        uint256 blockNumber
    ) external view virtual returns (uint256);

    function getVotes(address account) external view virtual returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view virtual returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view virtual returns (uint256);

    function delegates(address account) public view virtual returns (address);

    function decimals() public view virtual returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address to,
        uint256 amount
    ) external virtual returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view virtual returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    ) external virtual returns (bool);

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
    ) external virtual returns (bool);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/WeightCalculatorLib.sol";

abstract contract IWeightCalculator is ERC165 {
    function setGovernanceAddress(address _governance) external virtual;

    function calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _startIndex,
        uint256 _endIndex
    ) external virtual;

    function storePreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) external virtual;

    function getTotalVotersByVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual returns (uint256);

    function getVoteWeightDataForVoter(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    ) external view virtual returns (WeightCalculatorLib.VoteWeight memory);

    function getNormalisedWeightForVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual returns (uint256);

    function getTotalVoteWeight(
        uint32 _id
    ) external view virtual returns (uint256);

    function calculationsComplete(uint32 _id) external virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
@title SortingLib library
@notice this is a library for sorting dates into ascending order
@author https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
 */

library StakingLib {
    /* ========== FUNCTIONS ========== */

    /**
     * The function converts interest rates in basis points to interest rates in basis points per second.
     * @param _interestRateInBps The interest rate in basis points
     * @return The interest rate in basis points per second.
     */
    function getInterestRatePerSecondUnbalanced(
        uint _interestRateInBps
    ) internal pure returns (uint256) {
        uint totalSecsPerYear = 60 * 60 * 24 * 365;
        return ((10e18 * _interestRateInBps) / (totalSecsPerYear * 10000));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
@title VoteLib library
@notice this is a library for counting votes and return the proposal outcome
 
 */

library VoteLib {
    /* ========== TYPE DECLARATIONS ========== */
    struct VoteData {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 aVotes;
        uint256 bVotes;
        uint256 cVotes;
        uint256 abstainVotes;
        uint256 totalVoters;
    }

    enum Vote {
        For,
        Against,
        A,
        B,
        C,
        Abstain
    }

    /* ========== ERROR STATEMENTS ========== */

    error InvalidVote(Vote _vote);

    /* ========== FUNCTIONS ========== */

    /** @dev this functions counts votes for ForAgainst Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteForAgainst(
        VoteData storage data,
        VoteLib.Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.For) {
            data.forVotes += weight;
        } else if (vote == Vote.Against) {
            data.againstVotes += weight;
        } else revert InvalidVote(vote);
        ++data.totalVoters;
        return data;
    }

    /** @dev this functions counts votes for ForAgainstAbstain Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteForAgainstAbstain(
        VoteData storage data,
        Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.For) {
            data.forVotes += weight;
        } else if (vote == Vote.Against) {
            data.againstVotes += weight;
        } else if (vote == Vote.Abstain) {
            data.abstainVotes += weight;
        } else {
            revert InvalidVote(vote);
        }
        ++data.totalVoters;
        return data;
    }

    /** @dev this functions counts votes for MultiChoice Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteMultiChoice(
        VoteData storage data,
        Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.A) {
            data.aVotes += weight;
        } else if (vote == Vote.B) {
            data.bVotes += weight;
        } else if (vote == Vote.C) {
            data.cVotes += weight;
        } else if (vote == Vote.Abstain) {
            data.abstainVotes += weight;
        } else revert InvalidVote(vote);
        ++data.totalVoters;
        return data;
    }

    /** @dev this function returns the outcome for for against proposals */

    function getOutcomeForAgainst(
        VoteData memory data
    ) internal pure returns (string memory outcome) {
        (data.forVotes > data.againstVotes)
            ? outcome = "Succeeded"
            : outcome = "Defeated";
        if (data.forVotes == data.againstVotes) outcome = "Draw";

        return outcome;
    }

    /** @dev this function returns the outcome for multichoice proposals */

    function getOutcomeMultiChoice(
        VoteData memory data
    ) internal pure returns (string memory outcome) {
        uint256 winningVote;
        uint256 drawingVote;

        uint256[3] memory votes;

        votes[0] = data.aVotes;
        votes[1] = data.bVotes;
        votes[2] = data.cVotes;

        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] > winningVote) {
                winningVote = votes[i];
            } else if (votes[i] == winningVote) {
                drawingVote = votes[i];
            }
        }

        if (winningVote != 0 && winningVote != drawingVote) {
            outcome = "Succeeded";
        } else if (winningVote == drawingVote) {
            outcome = "Draw";
        } else outcome = "Defeated";

        return outcome;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VoteLib.sol";

/**
@title WeightCalculatorLib library
@notice this is a library for updating the pre normalised weight, calculating calculating the normalised weight and returning the proposal's outcome
 
 */

library WeightCalculatorLib {
    /* ========== TYPE DECLARATIONS ========== */

    struct VoteWeightData {
        mapping(VoteLib.Vote => mapping(uint256 => VoteWeight)) voteWeight;
        mapping(VoteLib.Vote => uint256) totalVotersPerVote;
        mapping(VoteLib.Vote => uint256) normalisedWeight;
        uint256 totalPreNormalisedWeight;
        bool calculationsComplete;
    }

    struct VoteWeight {
        address voter;
        uint256 preNormalisedWeight;
        uint256 normalisedWeight;
    }
    /* ========== CONSTANTS ========== */

    /// Rebalancing factor to assist with division
    uint256 constant BPS = 1e18;

    /* ========== FUNCTIONS ========== */

    /**
    @dev this function stores the pre normalised weight for the given voter and updates the total weight
    */

    function storeVotersPreNormalisedWeight(
        VoteWeightData storage data,
        VoteLib.Vote vote,
        uint256 weight,
        address voter
    ) internal returns (VoteWeightData storage) {
        data.totalVotersPerVote[vote]++;

        data.voteWeight[vote][data.totalVotersPerVote[vote]].voter = voter;

        data
        .voteWeight[vote][data.totalVotersPerVote[vote]]
            .preNormalisedWeight = weight;

        data.totalPreNormalisedWeight += weight;
        return data;
    }

    /**
    @dev this function calculates and stores the normalised weight, and updates the total normalised weight for the vote
    */

    function storeNormalisedWeight(
        VoteWeightData storage data,
        VoteLib.Vote _vote,
        uint256 _index
    ) internal {
        uint256 normalisedWeight = (data
        .voteWeight[_vote][_index].preNormalisedWeight * BPS) /
            data.totalPreNormalisedWeight;

        data.voteWeight[_vote][_index].normalisedWeight = normalisedWeight;

        data.normalisedWeight[_vote] += normalisedWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./StakingStorage.sol";
import "../../core/security/AbstractSystemPause.sol";
import "../../libraries/StakingLib.sol";

import "../../interfaces/IStaking.sol";
import "../../interfaces/IRace.sol";
import "../../interfaces/IAccess.sol";
import "../../interfaces/IRewardPool.sol";
import "./StakingCheckpoint.sol";
import "hardhat/console.sol";

/**
@title Staking contract
@notice This contract is the staking contract.
 
 */

contract Staking is
    Initializable,
    IStaking,
    IRace,
    StakingCheckpoint,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    StakingStorage,
    AbstractSystemPause
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StakingLib for *;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable token;
    IRewardPool pool;
    IAccess access;

    string url;

    /// MAPPINGS
    /// Address to user balance in storage
    mapping(address => uint256) public s_userBalance;

    /// Address to user reward earned, stored in storage
    mapping(address => uint256) public s_unstakedRewardsDue;

    /// Address to user reward paid, storesd in storage
    mapping(address => uint256) public s_rewardPaid;

    /// Holds the address of the factory contract that created the pool.
    address public managerAddress;

    /* ========== MODIFIERS ========== */

    /**
     * @dev The modifier does a check for whether the pool is Disabled or not.
     * An active pool has a FALSE state, a Disabled pool has a TRUE state
     */
    modifier whenEnabled() {
        require(!isDisabled, "Pool is Disabled!");
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == managerAddress,
            "Staking: Only Staking Manager can call this"
        );
        _;
    }

    modifier whenInitialized() {
        require(isInitialized, "Staking: Must be initialized!");
        _;
    }

    modifier whenClaimable() {
        require(
            block.timestamp > CLAIM_TIME_AFTER_ENDTIME,
            "Staking: Must be called after Claim Time"
        );
        _;
    }

    /**
     * @dev The modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyStakingRole() {
        access.onlyStakingRole(msg.sender);
        _;
    }

    modifier onlyStakingPauserRole() {
        access.onlyStakingPauserRole(msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _accessAddress, // the contract address for global access control
        address _systemPauseAddress, // the contract address for gloabl pause control
        address _managerAddress, // the contract address for the  pool manager
        address _factoryAddress,
        address _tokenAddress, //token address
        address _pool, //reward pool address
        uint256 _poolId,
        bytes memory _poolDesc,
        uint256 _maximumInterestRateInBasisPoints
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        token = IERC20Upgradeable(_tokenAddress);
        pool = IRewardPool(_pool);
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        factoryAddress = _factoryAddress;
        managerAddress = _managerAddress;
        poolId = _poolId;
        poolDesc = _poolDesc;
        maximumInterestRateInBasisPoints = _maximumInterestRateInBasisPoints;
    }

    /**
     * @dev Function to initialize pool values
     * @param _url. The url of the pool
     * @param _interestInBasisPoints. Interest Rate in basis points
     * @param _waitingRoomOpenDate. The desired time at which the contract ought to begin to receive deposits
     * @param _minStakingPerUser. Minimum staking per user
     * @param _maxStakingPerUser. Maximum staking per user
     * @param _claimTimeAfterEndtime. The time which users can claim after staking.
     * @return isInitialized: The function returns a boolean
     */
    function initializePoolValues(
        string memory _url,
        uint256 _interestInBasisPoints,
        uint256 _waitingRoomOpenDate,
        uint256 _raceStartDate,
        uint256 _raceEndDate,
        uint256 _minStakingPerUser,
        uint256 _maxStakingPerUser,
        uint256 _claimTimeAfterEndtime,
        uint256[] memory _pitStopDates,
        uint256 _numberOfStakers
    ) external onlyManager returns (bool) {
        require(bytes(_url).length > 0, "Staking: _url is empty");
        require(!isDisabled, "Staking: Pool disabled!");
        require(
            _interestInBasisPoints <= maximumInterestRateInBasisPoints,
            "Exceeds maximum interest rate limit!"
        );
        require(
            _pitStopDates.length > 0,
            "Staking: Pit Stop must be at least 1"
        );
        require(
            _interestInBasisPoints > 99,
            "Minimum interest rate is 100 bps"
        );
        require(
            block.timestamp < _waitingRoomOpenDate,
            "Staking: _waitingRoomOpenDate must be greater than current time"
        );

        require(
            _waitingRoomOpenDate < _raceStartDate,
            "Staking: _waitingRoomOpenDate must be less than first vesting time"
        );

        require(
            _raceStartDate < _raceEndDate,
            "Staking: _raceStartDate must be less than _raceEndDate"
        );

        url = _url;
        waitingRoomOpenDate = _waitingRoomOpenDate;
        raceStartDate = _raceStartDate;
        raceEndDate = _raceEndDate;
        interestRateInBps = _interestInBasisPoints;
        MINIMUM_STAKING_PER_USER = _minStakingPerUser;
        MAXIMUM_STAKING_PER_USER = _maxStakingPerUser;
        maximumNumberOfStakers = _numberOfStakers;
        pitStopDates = _pitStopDates;

        unbalancedInterestRatePerSecond = StakingLib
            .getInterestRatePerSecondUnbalanced(_interestInBasisPoints);
        if (_claimTimeAfterEndtime == 0) {
            CLAIM_TIME_AFTER_ENDTIME = raceEndDate;
        } else {
            require(
                _claimTimeAfterEndtime > raceEndDate,
                "Staking: _claimTimeAfterEndtime must be > Race End Time"
            );
            CLAIM_TIME_AFTER_ENDTIME = _claimTimeAfterEndtime;
        }

        isInitialized = true;

        emit InitializedPool(
            waitingRoomOpenDate,
            raceStartDate,
            interestRateInBps,
            MINIMUM_STAKING_PER_USER,
            MAXIMUM_STAKING_PER_USER,
            maximumReward,
            raceEndDate,
            CLAIM_TIME_AFTER_ENDTIME,
            maximumNumberOfStakers,
            pitStopDates,
            isInitialized
        );

        return isInitialized;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice This function allows a user to deposit tokens into the the staking pool
     * This function only works when the contract is not paused, and the pool is still active i.e isDisabled is FALSE.
     * This function is open before the races start(before the vesting period), and will  not work (revert) once the race has begun.
     * @param amount: This specifies the amount the user seeks to deposit
     */
    function deposit(
        uint256 amount
    )
        external
        override
        nonReentrant
        whenNotPaused
        whenSystemNotPaused
        whenEnabled
        whenInitialized
    {
        if (block.timestamp < waitingRoomOpenDate) {
            revert Staking__WaitForDepositToBegin();
        }

        if (block.timestamp > raceStartDate) {
            revert Staking__DepositPeriodHasPassed();
        }

        if (amount == 0) {
            revert Staking__ZeroAmountNotAllowed();
        }
        if (token.balanceOf(msg.sender) < amount) {
            revert Staking__InsufficientTokens();
        }

        if (numberOfStakers + 1 > maximumNumberOfStakers) {
            revert Staking__MaximumStakersExceeded();
        }

        uint256 balance = s_userBalance[msg.sender];

        if (amount + balance < MINIMUM_STAKING_PER_USER) {
            revert Staking__BelowMinimumStake();
        }

        if (balance + amount > MAXIMUM_STAKING_PER_USER) {
            revert Staking__AboveMaximumStakePerUser();
        }

        incrementCountStakers(msg.sender);
        s_userBalance[msg.sender] += amount;
        uint256 bal = s_userBalance[msg.sender];
        totalAmountStaked += amount;
        _addCheckpoint(msg.sender, bal, block.number);

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, bal, totalAmountStaked);
    }

    /**
     * @notice This function allows a caller to claim rewards.
     * This function only works when the contract is not paused, and the pool is still active i.e isDisabled is FALSE.
     * If the caller has no balance and no rewards to claim, the function reverts.
     * This function is only callable after the race is over.
     *
     * FIRST BLOCK: will run when user has no balance and no rewards
     * SECOND BLOCK: will run when user has a reward but no balance, will read the content of s_unstakedRewardsDue[msg.sender]
     * (which can ONLY be written to when a user unstakes) into memory, clear storage and pay out value in memor.
     * THIRD BLOCK: will run when a user has a balance, and will compute and any rewards due having removed rewards paid out previously,
     * then increments rewards paid by the rewardsDue.
     */
    function payClaimableReward()
        external
        override
        nonReentrant
        whenNotPaused
        whenSystemNotPaused
        whenEnabled
        whenInitialized
        whenClaimable
    {
        if (
            s_userBalance[msg.sender] == 0 &&
            s_unstakedRewardsDue[msg.sender] == 0
        ) {
            revert Staking__NoClaimableRewards();
        } else if (
            s_userBalance[msg.sender] == 0 &&
            s_unstakedRewardsDue[msg.sender] > 0
        ) {
            uint256 rewardDue = s_unstakedRewardsDue[msg.sender];
            s_unstakedRewardsDue[msg.sender] = 0;
            pool.fundStaker(msg.sender, rewardDue);
            emit ClaimedRewards(msg.sender, rewardDue, totalAmountStaked);
        } else {
            uint256 rewardDue = _viewRewardsDue(msg.sender);
            s_rewardPaid[msg.sender] += rewardDue;
            pool.fundStaker(msg.sender, rewardDue);
            emit ClaimedRewards(msg.sender, rewardDue, totalAmountStaked);
        }

        //refactor
    }

    /**
     * @notice This function allows a user withdraw all the funds previously staked.
     * This function only works when the contract is not paused, and the pool is still active i.e isDisabled is FALSE.
     * A user may unstake at anytime. Once a user unstakes, the user stops earning rewards.
     */
    function unstake()
        external
        override
        nonReentrant
        whenNotPaused
        whenSystemNotPaused
        whenEnabled
        whenInitialized
    {
        require(s_userBalance[msg.sender] > 0, "You have zero balance");
        require(
            block.timestamp < raceStartDate || block.timestamp > raceEndDate,
            "Lock-up ends after the race ends"
        );
        uint256 amount = s_userBalance[msg.sender];
        if (block.timestamp > raceStartDate) {
            s_unstakedRewardsDue[msg.sender] = viewTotalRewards();
        }
        s_userBalance[msg.sender] = 0;
        totalAmountStaked -= amount;
        _addCheckpoint(msg.sender, 0, block.number);
        decrementCountStakers(msg.sender);
        token.safeTransfer(msg.sender, amount);

        emit Unstaked(
            msg.sender,
            amount,
            s_userBalance[msg.sender],
            totalAmountStaked
        );
    }

    /**
     * @dev function to pause contract only callable by admin
     * This is a local pause that allows this specific pool to be paused.
     *
     */
    function pauseContract() external override onlyStakingRole {
        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     * This is a local unpause that allows this specific pool to be unpaused.
     */
    function unpauseContract() external override onlyStakingRole {
        _unpause();
    }

    // supports system pause from staking manager
    function systemPause() external onlyStakingPauserRole {
        _pause();
    }

    // supports system pause from staking manager
    function systemUnpause() external onlyStakingPauserRole {
        _unpause();
    }

    /**
     * @dev function to disable staking pool, only callable by the factory
     * @notice This function allows the admin to Disable the pool via the factory contract.
     */
    function disablePool() external override whenSystemNotPaused {
        require(msg.sender == managerAddress, "Staking: Access Forbidden");
        isDisabled = true;
        emit PoolDisabled(msg.sender, address(this), isDisabled);
    }

    /**
     * Set Maximum interest rate
     * @param _maxInterestRate The maximum interest rate that can be set for
     */
    function setMaximumInterestRateInBasisPoints(
        uint256 _maxInterestRate
    ) external onlyStakingRole {
        require(
            _maxInterestRate > interestRateInBps,
            "Staking: the parameter must be > interestRateInBps"
        );
        uint256 prev = maximumInterestRateInBasisPoints;
        maximumInterestRateInBasisPoints = _maxInterestRate;
        uint256 current = maximumInterestRateInBasisPoints;
        //emit event
        emit MaximumInterestRateChanged(prev, current, msg.sender);
    }

    /**
     * @notice This function allow the user to get the balance for a user at a particular block number
     * @return uint256. User's balance at given block number
     */
    function getPastCheckpoint(
        address account,
        uint256 blockNumber
    ) external view override returns (uint256) {
        return _getPastCheckpoint(account, blockNumber);
    }

    /* ========== INTERNAL ========== */

    /**
     *
     * @dev This function allows a caller to view the rewards claimable by a user.
     * @param account: Pass in the account address you seek to view rewards for.
     * @notice This function returns the rewards that a user can claim.
     *
     */
    function _viewRewardsDue(
        address account
    ) internal view whenEnabled returns (uint256) {
        uint256 diff = raceEndDate - raceStartDate;

        uint256 rewardsDue = (diff *
            unbalancedInterestRatePerSecond *
            s_userBalance[account]) / 10e18;
        return (rewardsDue - s_rewardPaid[account]);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice This function allows the admin to view the rewards that can be claimed by a user.
     * @return uint256. Claimable rewards
     */
    function viewTotalRewardsAdmin(
        address account
    ) public view override onlyStakingRole returns (uint256) {
        return _viewRewardsDue(account);
    }

    /**
     * @dev function to check whether pool has expired
     * @notice This function allows a user to check whether this pool has exceeded its raceEndDate.
     * return bool: true if pool has expired
     */
    function hasPoolExpired() public view override returns (bool) {
        return (block.timestamp > raceEndDate);
    }

    /**
     * @dev This function is called to view the staked balance of a user
     * @param account: This function takes the address we seek to check the balance of
     * @notice This function allows the admin to view a user's balance
     * @return uint256. Returns user's staked balance
     */
    function viewUserBalance(
        address account
    ) public view override returns (uint256) {
        return s_userBalance[account];
    }

    /**
     * @dev This function returns the total number of stakers in uint
     * @notice This function allows a user view the total number of unique addresses
     */
    function totalStakers() public view override returns (uint256) {
        return numberOfStakers;
    }

    /**
     * @dev This function returns the total number of tokens staked
     * @notice This function allows a user view the total amount of tokens staked in the contract.
     */
    function totalStaked() public view override returns (uint256) {
        return totalAmountStaked;
    }

    /**
     * @notice This function allows a user to view the rewards that can be claimed by the caller.
     */
    function viewTotalRewards() public view override returns (uint256) {
        return _viewRewardsDue(msg.sender);
    }

    /**
     * @dev This function is a helper function that allows the caller to view all the vesting dates for the pool.
     * @return array: This function returns an array of vesting dates
     * @notice The first item in the array is start date of the vesting cliff
     */
    function printPitStopDates()
        external
        view
        override
        returns (uint256[] memory)
    {
        return pitStopDates;
    }

    /**
     * @notice View pool state
     */
    function readPoolState()
        external
        view
        returns (PoolState memory poolState)
    {
        poolState = PoolState(
            poolId,
            url,
            poolDesc,
            address(this),
            address(pool),
            totalAmountStaked,
            numberOfStakers,
            maximumNumberOfStakers,
            waitingRoomOpenDate,
            raceStartDate,
            raceEndDate,
            CLAIM_TIME_AFTER_ENDTIME,
            interestRateInBps,
            MINIMUM_STAKING_PER_USER,
            MAXIMUM_STAKING_PER_USER,
            isInitialized,
            isDisabled
        );
    }

    /**
     * @dev Calculates the total amount of payable rewards for a pool based on its total amount staked, race start and end dates, and the unbalanced interest rate per second.
     * @return The total amount of payable rewards as a uint256.
     */
    function getTotalPayableRewards() external view returns (uint256) {
        uint diff = raceEndDate - raceStartDate;
        uint val = (totalAmountStaked *
            diff *
            unbalancedInterestRatePerSecond) / 10e18;
        return val;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev The increment part of the counter feature for stakers
     * @notice This is a counter to increment the count for the number of stakers.
     */
    function incrementCountStakers(address beneficiary) private {
        uint256 oldCount = numberOfStakers;
        uint256 newCount;
        if (s_userBalance[beneficiary] == 0) {
            numberOfStakers++;
            newCount = oldCount + 1;
        }
        emit StakersCountChanged(oldCount, newCount, msg.sender);
    }

    /**
     * @dev The decrement part of the counter feature for stakers
     * @notice This is a counter to decrement the count for the number of stakers.
     */
    function decrementCountStakers(address beneficiary) private {
        uint256 oldCount = numberOfStakers;
        uint256 newCount;
        if (s_userBalance[beneficiary] == 0) {
            numberOfStakers--;
            newCount = oldCount - 1;
        }
        emit StakersCountChanged(oldCount, newCount, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //To DO: Discussison on whenPausedRelease
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/utils/Votes.sol)
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Checkpoints.sol";

abstract contract StakingCheckpoint {
    using Checkpoints for Checkpoints.History;

    /* ========== STATE VARIABLES ========== */

    mapping(address => Checkpoints.History) private _stakeCheckpoints;

    /* ========== INTERNAL ========== */

    /**
     * @dev Create a staking snapshot.
     */
    function _addCheckpoint(
        address account,
        uint256 amount,
        uint256 blockNumber
    ) internal {
        uint32 _blockNumber = SafeCast.toUint32(blockNumber);
        uint224 _amount = SafeCast.toUint224(amount);
        _stakeCheckpoints[account]._checkpoints.push(
            Checkpoints.Checkpoint(_blockNumber, _amount)
        );
    }

    /**
     * @dev Returns the amount of token that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function _getPastCheckpoint(
        address account,
        uint256 blockNumber
    ) internal view virtual returns (uint256) {
        Checkpoints.History storage history = _stakeCheckpoints[account];

        uint256 pos;

        history._checkpoints.length == 1 &&
            history._checkpoints[0]._blockNumber > blockNumber
            ? pos = 0
            : pos = _stakeCheckpoints[account].getAtProbablyRecentBlock(
            blockNumber
        );

        return pos;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../core/security/AbstractSystemPause.sol";
import "../../interfaces/IToken.sol";
import "../../interfaces/IAccess.sol";
import "../../interfaces/ISystemPause.sol";
import "../../interfaces/IRace.sol";
import "./Staking.sol";

/**
@notice StakingFactory contract
@notice this contract is the staking factory contract for creating staking contracts.
 
 */

contract StakingManager is Initializable, AbstractSystemPause, IRace {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// main access contract
    IAccess access;
    /// count of all pools
    uint256 public totalCount;
    /// count of all disabled pool
    uint256 public disabledCount;
    /// users are not allowed to have more than the maximum number of Active pools
    uint256 public maximumActivePools;
    /// mapping of id to pool address
    mapping(uint256 => address) public idToPoolAddress;
    /// mapping of id to bool isInitialized
    mapping(address => bool) private isInitialized;

    /// mapping of factory addresses
    mapping(address => bool) public factoryAddresses;
    /// mapping of staking address to bool
    mapping(address => bool) isStakingContract;
    /// staking pool's associated reward pool address
    mapping(address => address) public rewardPoolAddress;

    /* =========TENTATIVE VARIABLES ============ */
    address[] activePoolsArray;
    address[] expiredPoolsArray;
    address[] disabledPoolsArray;

    /* ========== REVERT STATEMENTS ========== */
    error CallUnsuccessful(address contractAddress);

    /* ========== EVENTS ========== */

    event NewPool(address stakingPoolAddress, address rewardPoolAddress);

    event DisabledPool(
        address stakingPoolAddress,
        address caller,
        uint256 timeOfDisablement,
        bool isActive,
        uint256 numOfDisabledPools
    );
    event FundedRewardPool(address caller, address token, uint256 amount);
    event SetMaximumPool(
        address caller,
        uint256 prevMaximumPool,
        uint256 currentMaximumPool
    );

    /* ========== MODIFIERS ========== */

    modifier onlyStakingManagerRole() {
        access.onlyStakingManagerRole(msg.sender);
        _;
    }

    modifier onlyStakingManagerOrFactory() {
        require(
            access.userHasRole(access.stakingManagerRole(), msg.sender) ||
                access.userHasRole(access.admin(), msg.sender) ||
                factoryAddresses[msg.sender],
            "Manager: Not allowed for non-admin, non-staking, non-factory"
        );
        _;
    }

    modifier onlyExecutiveOrStakingManager() {
        require(
            access.userHasRole(access.executive(), msg.sender) ||
                access.userHasRole(access.stakingManagerRole(), msg.sender),
            "StakingManager: access forbidden"
        );
        _;
    }

    modifier onlyFactoryRole() {
        require(
            factoryAddresses[msg.sender],
            "Manager: Not allowed for non-factory"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _accessAddress,
        address _systemPauseAddress
    ) public initializer {
        maximumActivePools = 6;
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
    }

    /* ========== EXTERNAL ========== */

    /**
     * @dev Update the parameters of a pool identified by the given index.
     * @param raceVariables The updated race variables to use for the pool.
     * @param index The index of the pool to update.
     * Requirements:
     * - The pool identified by the index must exist.
     * - The inputs in the race variables must be valid.
     * - The system must not be paused.
     * - The race start time for the pool must not have already passed.
     * Emits a {PoolInitialized} event if the pool was successfully initialized.
     * Reverts if the initialization of the pool failed.
     */
    function updatePool(
        PoolInitiator memory raceVariables,
        uint256 index
    ) external onlyStakingManagerOrFactory whenSystemNotPaused {
        require(
            idToPoolAddress[index] != address(0),
            "Manager: Pool does not exist"
        );

        require(
            _validateInputs(raceVariables),
            "Manager: Invalid fields in race Variable"
        );

        address val = idToPoolAddress[index];
        uint256 raceStartTime = Staking(val).raceStartDate();

        if (raceStartTime != 0) {
            require(
                block.timestamp < raceStartTime,
                "Cannot change, Race has begun"
            );
        }

        bool success = Staking(val).initializePoolValues(
            raceVariables._url,
            raceVariables.interestRateInBasisPoints,
            raceVariables.waitingRoomOpenDate,
            raceVariables.raceStartDate,
            raceVariables.raceEndDate,
            raceVariables.minimumStakePeruser,
            raceVariables.maximumStakePerUser,
            raceVariables.claimTimeAfterEndtime,
            raceVariables.pitStopDates,
            raceVariables.maximumNumberOfStakers
        );
        if (!isInitialized[val]) {
            activePoolsArray.push(val);
        }

        //emit something
        require(success, "Manager: Initialization Failed!");
    }

    /**
     * @dev Initializes the pool parameters for a pool identified by the given index with the provided race variables.
     * @param raceVariables The race variables to use for the pool.
     * @param index The index of the pool to express.
     * Requirements:
     * - The pool identified by the index must exist.
     * - The caller must have the factory role.
     * - The system must not be paused.
     * Emits a {PoolInitialized} event if the pool was successfully initialized.
     * Reverts if the initialization of the pool failed.
     */
    function expressPool(
        PoolInitiator memory raceVariables,
        uint256 index
    ) external onlyFactoryRole whenSystemNotPaused {
        require(
            idToPoolAddress[index] != address(0),
            "Manager: Pool does not exist"
        );
        address val = idToPoolAddress[index];
        bool success = Staking(val).initializePoolValues(
            raceVariables._url,
            raceVariables.interestRateInBasisPoints,
            raceVariables.waitingRoomOpenDate,
            raceVariables.raceStartDate,
            raceVariables.raceEndDate,
            raceVariables.minimumStakePeruser,
            raceVariables.maximumStakePerUser,
            raceVariables.claimTimeAfterEndtime,
            raceVariables.pitStopDates,
            raceVariables.maximumNumberOfStakers
        );

        require(success, "Manager: Initialization Failed!");
        activePoolsArray.push(val); //push to active array.
        isInitialized[val] = true;
    }

    /**
     * @notice disablePool
     * @dev Disables a staking pool. The function is only accessible by the staking manager.
     *
     * @param _index uint256: index of the pool to be disabled
     *
     * Throws When the staking system is paused
     * Throws When the caller is not the staking manager
     * Throws When the pool already has stakers
     * Throws When the staking pool is already disabled
     */

    function disablePool(uint256 _index) external onlyStakingManagerRole {
        address val = idToPoolAddress[_index];

        require(
            Staking(val).totalStaked() == 0,
            "Manager: Cannot disable, Pool already has stakers"
        );
        require(
            !Staking(val).isDisabled(),
            "Manager: Staking pool is disabled!"
        );
        require(activePoolsArray.length > 0, "Manager: Has no active pool!");

        uint length = activePoolsArray.length; //Check for uint 8; Identify the Active Pools max on Staging

        // create a replica in memory
        address[] memory replica = new address[](length);
        replica = activePoolsArray;
        for (uint i = 0; i < length; i++) {
            if (replica[i] == val) {
                //push to disabled
                disabledPoolsArray.push(replica[i]);
                //overwrite in array
                replica[i] = replica[length - 1];
                activePoolsArray = replica;
                activePoolsArray.pop();

                disabledCount++;

                Staking(val).disablePool();

                emit DisabledPool(
                    address(Staking(val)),
                    msg.sender,
                    block.timestamp,
                    Staking(val).isDisabled(),
                    disabledCount
                );
                break;
            }
        }
    }

    /**
     * @notice setMaximumActivePools
     * @dev Sets the maximum number of active staking pools. This function can only be executed by the executive.
     *
     * @param amount uint256: maximum number of active staking pools
     *
     * Throws When the caller is not the executive
     * Throws When the amount is less than 6
     *
     * EVENT: SetMaximumPool - Emits an event with the previous maximum number of active staking pools,
     * the new maximum number of active staking pools, and the address of the caller
     */

    function setMaximumActivePools(
        uint256 amount
    ) external onlyExecutiveOrStakingManager {
        require(amount >= 1, "Manager: amount must be >= 1"); //TO DO: Review the effects
        uint256 prev = maximumActivePools;
        maximumActivePools = amount;
        emit SetMaximumPool(msg.sender, prev, amount);
    }

    /**
     * @notice viewPoolCount
     * @dev Returns the total number of staking pools in the system.
     *
     * @return uint256 - the total number of staking pools in the system
     */

    function viewPoolCount() external view returns (uint256) {
        return totalCount;
    }

    /**
     * @notice viewDisabledPoolCount
     * @dev Returns the total number of disabled staking pools in the system.
     *
     * @return uint256 - the total number of disabled staking pools in the system
     */

    function viewDisabledPoolCount() external view returns (uint256) {
        return disabledCount;
    }

    /**
     * @notice viewAllPools
     * @dev Returns an array of all the staking pools in the system and their state.
     *
     * @return pools PoolState[] memory - an array of all the staking pools in the system and their state
     *
     * Throws When there are no active staking pools
     */

    function viewAllPools() external view returns (PoolState[] memory pools) {
        require(totalCount > 0, "StakingManager: No Active Pools");
        pools = new PoolState[](totalCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= pools.length; i++) {
            pools[counter] = Staking(idToPoolAddress[i]).readPoolState();
            counter++;
        }
        return pools;
    }

    /**
     * @notice viewAllPoolAddresses
     * @dev Returns an array of all the staking pool addresses in the system.
     *
     * @return pools address[] memory - an array of all the staking pool addresses in the system
     *
     * Throws When there are no active staking pools
     */

    function viewAllPoolAddresses()
        external
        view
        returns (address[] memory pools)
    {
        require(totalCount > 0, "StakingManager: No Active Pools");
        pools = new address[](totalCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= pools.length; i++) {
            pools[counter] = idToPoolAddress[i];
            counter++;
        }
        return pools;
    }

    /**
     * @notice viewActivePools
     * @dev Returns an array of all the active staking pool addresses in the system.
     *
     * @return pools address[] memory - an array of all the active staking pool addresses in the system
     *
     * Throws When there are no active staking pools
     */

    function viewActivePools() external view returns (address[] memory pools) {
        require(totalCount > 0, "StakingManager: No Active Pools");

        return activePoolsArray;
    }

    /**
     * @notice viewExpiredPoolsArray
     * @dev Returns an array of all the expired staking pool addresses in the system.
     *
     * @return pools address[] memory - an array of all the expired staking pool addresses in the system
     */

    function viewExpiredPoolsArray()
        public
        view
        returns (address[] memory pools)
    {
        return expiredPoolsArray;
    }

    /**
     * @notice viewDisabledPoolsArray
     * @dev Returns an array of all the disabled staking pool addresses in the system.
     *
     * @return  pools address[] memory - an array of all the disabled staking pool addresses in the system
     */

    function viewDisabledPoolsArray()
        external
        view
        returns (address[] memory pools)
    {
        return disabledPoolsArray;
    }

    /**
     * @notice viewRewardPoolTokenBalance
     * @dev Returns the balance of the staking pool in the specified token.
     *
     * @param _tokenAddress address: address of the token
     * @param _pool address: address of the staking pool
     *
     * @return uint256 - the balance of the staking pool in the specified token
     */

    function viewRewardPoolTokenBalance(
        address _tokenAddress,
        address _pool
    ) external view returns (uint256) {
        IToken token = IToken(_tokenAddress);
        return token.balanceOf(_pool);
    }

    /**
     * @notice viewPool
     * @dev Returns the state of the specified staking pool.
     *
     * @param _index uint256: index of the staking pool
     *
     * @return PoolState memory - the state of the specified staking pool
     */

    function viewPool(uint256 _index) external view returns (PoolState memory) {
        return Staking(idToPoolAddress[_index]).readPoolState();
    }

    /**
     * @notice viewPoolByAddress
     * @dev Returns the state of the staking pool with the specified address.
     *
     * @param _pool address: address of the staking pool
     *
     * @return PoolState memory - the state of the staking pool with the specified address
     */

    function viewPoolByAddress(
        address _pool
    ) external view returns (PoolState memory) {
        return Staking(_pool).readPoolState();
    }

    /**
     * @notice viewUserBalanceAcrossAllPools
     * @dev Returns the total balance of the specified user in all staking pools.
     *
     * @param _user address: address of the user
     *
     * @return uint256 - the total balance of the specified user in all staking pools
     *
     * Throws When there are no active staking pools
     */

    function viewUserBalanceAcrossAllPools(
        address _user
    ) external view returns (uint256) {
        require(totalCount > 0, "StakingManager: No Active Pools");
        uint256 accumulatedBalance;
        uint256 length = totalCount;

        for (uint256 i = 1; i <= length; i++) {
            uint256 userBalance = Staking(idToPoolAddress[i]).viewUserBalance(
                _user
            );
            accumulatedBalance += userBalance;
        }
        //

        return accumulatedBalance;
    }

    /**
     * @notice getUserBalanceAtBlockNumber
     * @dev Returns the total balance of the specified user in all staking pools at a specified block number.
     *
     * @param account address: address of the user
     * @param blockNumber uint256: block number to retrieve the balance at
     *
     * @return uint256 - the total balance of the specified user in all staking pools at the specified block number
     *
     * Throws When there are no active staking pools
     */

    function getUserBalanceAtBlockNumber(
        address account,
        uint256 blockNumber
    ) external view returns (uint256) {
        uint256 accumulatedBalance;
        if (totalCount > 0) {
            PoolState[] memory pools = new PoolState[](totalCount);
            pools = this.viewAllPools();
            for (uint256 i; i < pools.length; i++) {
                accumulatedBalance += Staking(pools[i].poolAddress)
                    .getPastCheckpoint(account, blockNumber);
            }
        }
        return accumulatedBalance;
    }

    // * ========== PUBLIC =========== *

    /**
     * @notice addNewPool
     * @dev Adds a new staking pool to the system.
     *
     * @param _id uint256: id of the staking pool
     * @param _contractAddress address: address of the staking pool contract
     *
     * @notice To increase the number of pools, the admin must either disable a pool with no deposits, or change the maximumActivePools function
     *
     * Throws When the sender is not the factory address
     * Throws When _id is not greater than 0
     * Throws When _id is not equal to the total count + 1
     * Throws When _contractAddress is equal to address(0)
     * Throws When there are already the maximum number of active staking pools
     */

    function addNewPool(
        uint256 _id,
        address _contractAddress,
        address _rewardPoolAddress
    ) public onlyFactoryRole {
        // require(factoryAddresses[msg.sender], "Manager: Access Forbidden");
        require(_id > 0, "Manager: _id must be greater than 0");
        require(_id == totalCount + 1, "Manager: invalid id");
        require(
            _contractAddress != address(0),
            "Manager: _contractAddress cannot be address(0)"
        );
        shiftExpiredPoolsFromActivePools();

        require(
            activePoolsArray.length < maximumActivePools,
            "Disable an existing pool, in order to add new pools"
        );
        idToPoolAddress[_id] = _contractAddress;

        totalCount = _id;
        isStakingContract[_contractAddress] = true;
        rewardPoolAddress[_contractAddress] = _rewardPoolAddress;

        emit NewPool(_contractAddress, _rewardPoolAddress);
    }

    /**
     * @dev This function is callable by Admin.
     * @param _factory: a new factory address
     */

    function addFactoryAddress(address _factory) public onlyStakingManagerRole {
        factoryAddresses[_factory] = true;
    }

    /**
     * @dev This function is callable by Admin.
     * @param _factory: the factory address to remove
     */

    function removeFactoryAddress(
        address _factory
    ) public onlyStakingManagerRole {
        factoryAddresses[_factory] = false;
    }

    /**
     * @notice poolChecker
     * @dev Returns true if the specified address is a staking pool contract, false otherwise.
     *
     * @param _pool address: address to check
     *
     * @return bool - true if the specified address is a staking pool contract, false otherwise
     */

    function poolChecker(address _pool) public view returns (bool) {
        return isStakingContract[_pool];
    }

    /**
     * @dev Pauses the system by setting the systemPaused flag to true and pausing all active and expired pools.
     * Accessible only to the SystemPause contract.
     * Emits a {SystemPaused} event.
     * Reverts if any of the calls to pause the pools are unsuccessful.
     */
    function pauseSystem() external virtual override onlySystemPauseContract {
        systemPaused = true;

        for (uint256 i; i < activePoolsArray.length; i++) {
            (bool success, ) = activePoolsArray[i].call(
                abi.encodeWithSignature("systemPause()")
            );
            if (!success) revert CallUnsuccessful(activePoolsArray[i]);
        }

        for (uint256 i; i < expiredPoolsArray.length; i++) {
            (bool success, ) = expiredPoolsArray[i].call(
                abi.encodeWithSignature("systemPause()")
            );
            if (!success) revert CallUnsuccessful(expiredPoolsArray[i]);
        }
    }

    /**
     * @dev Unpauses the system by setting the systemPaused flag to false and unpausing all active and expired pools.
     * Accessible only to the SystemPause contract.
     * Emits a {SystemUnpaused} event.
     * Reverts if any of the calls to unpause the pools are unsuccessful.
     */
    function unpauseSystem() external virtual override onlySystemPauseContract {
        systemPaused = false;

        for (uint256 i; i < activePoolsArray.length; i++) {
            (bool success, ) = activePoolsArray[i].call(
                abi.encodeWithSignature("systemUnpause()")
            );
            if (!success) revert CallUnsuccessful(activePoolsArray[i]);
        }

        for (uint256 i; i < expiredPoolsArray.length; i++) {
            (bool success, ) = expiredPoolsArray[i].call(
                abi.encodeWithSignature("systemUnpause()")
            );
            if (!success) revert CallUnsuccessful(expiredPoolsArray[i]);
        }
    }

    // * ========== INTERNAL =========== *
    /**
     * @notice shiftExpiredPoolsFromActivePools
     * @dev Transfers expired staking pools from the active pool array to the expired pool array.
     *
     * When a staking pool's end time has been reached, this function will identify the pool
     * and transfer it from the active pool array to the expired pool array.
     */

    function shiftExpiredPoolsFromActivePools() internal {
        // First create an array in memory with the maximum possible length

        uint counter = 0;
        uint[] memory indexArr = new uint[](activePoolsArray.length);

        for (uint i = 0; i < activePoolsArray.length; i++) {
            if (activePoolsArray.length == 0) {
                break;
            } else if (!Staking(activePoolsArray[i]).hasPoolExpired()) {
                indexArr[counter] = i;
                counter++;
            } else if (Staking(activePoolsArray[i]).hasPoolExpired()) {
                expiredPoolsArray.push(activePoolsArray[i]);
            }
        }

        // Create a new array with the actual length (i.e., counter)
        address[] memory newArray = new address[](counter);

        // Copy the relevant elements to the new array
        for (uint i = 0; i < counter; i++) {
            if (activePoolsArray.length == 0) {
                break;
            } else {
                newArray[i] = activePoolsArray[indexArr[i]];
            }
        }

        // Update the activePoolsArray with the newArray
        activePoolsArray = newArray;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
@title Staking contract
@notice This contract is the staking contract.
 
 */

abstract contract StakingStorage {
    /* ========== STATE VARIABLES ========== */
    /// Interest rate in basis points
    uint256 public interestRateInBps;

    /// Unbalanced Interest Rate
    uint256 public unbalancedInterestRatePerSecond;

    /// Maximum possible Interest Rate
    uint256 public maximumInterestRateInBasisPoints;

    /// The number of stakers
    uint256 public numberOfStakers;

    /// The maximum number of stakers allowed in the race
    uint256 public maximumNumberOfStakers;

    /// The Id for the staking pool
    uint256 public poolId;

    /// The description for the pool (string converted to bytes)
    bytes public poolDesc;

    /// TIME VARIABLES
    /// Time at which pool begins and the pool can begin receiving deposits
    uint256 public waitingRoomOpenDate;

    /// End of deposits and begining of the race
    uint256 public raceStartDate;

    /// Pit stops after the start of the race, and before the end of the race.
    uint256[] public pitStopDates;

    /// Total length of Race
    uint256 public totalVestingSecs;

    /// The end time after which users can unstake
    uint256 public raceEndDate;

    /// The time which a rewards may be claimed.
    uint256 public CLAIM_TIME_AFTER_ENDTIME;

    /// TOKEN STAKED VARIABLES
    /// Total amount of tokens staked
    uint256 totalAmountStaked;

    /// Minimum number of tokens that can be staked per user
    uint256 public MINIMUM_STAKING_PER_USER;

    /// Maximum staking per user that can be staked per user address
    uint256 public MAXIMUM_STAKING_PER_USER;

    /// The full value of the APR of the maximum pool size
    uint256 maximumReward;

    /// Holds the state of the pool, false when pool is ACTIVE, true when pool is closed.
    bool public isDisabled;

    bool public isInitialized;

    address public factoryAddress;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}