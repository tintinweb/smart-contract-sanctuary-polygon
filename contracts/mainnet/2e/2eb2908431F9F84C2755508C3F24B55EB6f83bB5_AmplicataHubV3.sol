// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
library SignedMathUpgradeable {
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

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.19;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/ILensHub.sol";
import "./libs/DataTypesV3.sol";

/**
 * @title AmplicataHub
 */
contract AmplicataHubV3 is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    // Lens Hub address
    ILensHub public lensHub;
    // Payment token instance
    IERC20Upgradeable public paymentToken;        
    // Fee divider, i.e amount * fee / feeBase >> 2000 * 50 / 1000 = 100 => 5%
    uint128 private constant feeBase = 1000;    
    // Contract config store
    DataTypes.Config public config;

    bool public paused;
    
    mapping(address => DataTypes.Account) public accountStats;

    // Promoter profileId => profile
    mapping(uint128 => DataTypes.Wallet) public wallets;    
    
    // Promoter profileId => pubId => dataLayerId => promotion
    mapping(uint128 => mapping(uint128 => mapping(uint128 => DataTypes.Promotion))) public promotions;  
    
    // Influencer profileId => Promoter profileId => publicationId => dataLayerId => mirrors
    mapping(uint128 => mapping(uint128 => mapping(uint128 => mapping(uint128 => DataTypes.Mirror)))) public mirrors;  
                        
    // --------------------- CONSTRUCT ---------------------
    /**
     * @dev The initializer sets the LensHub, paymentToken_ and config variables.
     *
     * @param lensHub_ LensHub contract.
     * @param paymentToken_ ERC20 token address.
     * @param config_ Config struct
     */
    function initialize(
        ILensHub lensHub_,
        IERC20Upgradeable paymentToken_,        
        DataTypes.Config memory config_
    ) public initializer {
        __Ownable_init_unchained();
        lensHub = lensHub_;
        paymentToken = paymentToken_;
        setConfig(config_);
    }
  
    // --------------------- VIEWS ---------------------

    /**
     * @dev Single method to get all major variables related to contract and profile for UI in single request.
     *
     * @param profileId If provided non 0 address profile data will be included in result.
     */
    function aggregatedData(uint128 profileId) public view returns (
        DataTypes.Config memory configData,
        uint256 feeBaseVal,
        address paymentTokenAddress,         
        DataTypes.Wallet memory walletData,  
        address profileOwner,    
        uint256 ethBalance,  
        uint256 paymentTokenBalance, 
        uint256 paymentTokenAllowance,
        uint256 profileCreationTime,
        DataTypes.Account memory accountStatsData         
	) {
        configData = config;
        feeBaseVal = feeBase;        
		paymentTokenAddress = address(paymentToken);

        if (lensHub.exists(profileId)) {
            walletData = wallets[profileId];
            profileOwner = lensHub.ownerOf(profileId);
            accountStatsData = accountStats[profileOwner];
            ethBalance = profileOwner.balance;
            paymentTokenBalance = paymentToken.balanceOf(profileOwner);
            paymentTokenAllowance = paymentToken.allowance(profileOwner, address(this));    
            profileCreationTime = lensHub.mintTimestampOf(profileId);     
        } 
	}
       
    // --------------------- PUBLIC ---------------------
      
    function deposit(uint128 profileId, uint128 amount) public whenNotPaused {
        if (amount == 0) 
            revert ErrorCode(DataTypes.ErrorCode.deposit_wrongAmount);
        
        if (!lensHub.exists(profileId)) 
            revert ErrorCode(DataTypes.ErrorCode.deposit_profileNotExist);
                        
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);

        DataTypes.Wallet storage wallet = wallets[profileId];        
        wallet.balance += amount;

        _emitEvent(DataTypes.EventCode.DEPOSIT, abi.encode(profileId, amount, wallet));
    }
    
    function withdraw(uint128 profileId, uint128 amount) external whenNotPaused { 
        _onlyProfileOwner(profileId);

        DataTypes.Wallet storage wallet = wallets[profileId];
        
        if (amount == 0) 
            revert ErrorCode(DataTypes.ErrorCode.withdraw_wrongAmount);
        
        if (amount > wallet.balance - wallet.locked) 
            revert ErrorCode(DataTypes.ErrorCode.withdraw_insufficientBalance);
        
        unchecked { 
            wallet.balance -= amount; 
        }
        
        paymentToken.safeTransfer(msg.sender, amount);
        
        _emitEvent(DataTypes.EventCode.WITHDRAW, abi.encode(profileId, amount, wallet));
	}
    
    function createPostAndPromotion(ILensHub.PostWithSigData calldata postWithSigData, DataTypes.PromotionData calldata promotionData) external returns (uint128 publicationId) {
        uint128 profileId = uint128(postWithSigData.profileId);
        publicationId = uint128(lensHub.postWithSig(postWithSigData));        
        // check if pub is post
        if (lensHub.getPubType(postWithSigData.profileId, publicationId) != ILensHub.PubType.Post)
            revert ErrorCode(DataTypes.ErrorCode.createPromotion_onlyOwnPublication);

        _createPromotion(profileId, publicationId, 0, promotionData);        
    }

    function createPromotion(uint128 profileId, uint128 pubId, uint128 dataLayerId, DataTypes.PromotionData calldata promotionData, bytes calldata serviceSignature) external {
        _checkServiceSignature(keccak256(abi.encode(profileId, pubId, dataLayerId, promotionData)), serviceSignature); 
        _createPromotion(profileId, pubId, dataLayerId, promotionData);
    }

    function _createPromotion(uint128 profileId, uint128 pubId, uint128 dataLayerId, DataTypes.PromotionData calldata promotionData) public whenNotPaused {
        _onlyProfileOwner(profileId);
                        
        DataTypes.Promotion storage promotion = promotions[profileId][pubId][dataLayerId];
        
        if (promotion.createdTimestamp != 0) // Promotion already created
            revert ErrorCode(DataTypes.ErrorCode.createPromotion_alreadyCreated);
        
        // Base promo config        
        DataTypes.Config memory config_ = config; 
        promotion.active = promotionData.active;    
        promotion.mustFollow = promotionData.mustFollow;           
        promotion.budget = promotionData.budget;
        promotion.createdTimestamp = uint32(block.timestamp); 
        promotion.duration = promotionData.duration; 
                
        if (promotionData.duration < config_.minDuration || promotionData.duration > config_.maxDuration) // Duration too long
            revert ErrorCode(DataTypes.ErrorCode.createPromotion_wrongDuration);                  
        
        // Profile Eligibility  
        if (promotionData.profileEligibility.mode == 0) { 
            if (promotionData.profileEligibility.minRank > promotionData.profileEligibility.maxRank) //
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_rankRange);
        } else if (promotionData.profileEligibility.mode == 1) {            
            if (promotionData.profileEligibility.minPostsToMirrorsRatio > 100) // Bad min posts to mirrors ratio
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_minPostsToMirrorsRatio);
            
            if (promotionData.profileEligibility.maxMirrors > config_.maxMirrors) // Bad min posts to mirrors ratio
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_maxMirrors);        
            if (promotionData.profileEligibility.mirrorsForLastDuration != 0) { 
                bool correctDuration;           
                for (uint256 i = 1; i <= config_.mirrorsForLastDuratioWeeks;) {
                    if (promotionData.profileEligibility.mirrorsForLastDuration == i * 1 weeks) {
                        correctDuration = true;
                        break;
                    }              
                    unchecked { i++; }
                }
                if (!correctDuration)
                    revert ErrorCode(DataTypes.ErrorCode.createPromotion_mirrorsForLastDuration);             
            }
        }         
                         
        // Reward Parameters 
        // publish duration
        if (promotionData.rewardParameters.publishDuration != 0) {
            if (promotionData.rewardParameters.publishDuration < config.minPublishDuration) // Bad min posts to mirrors ratio
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_minPublishedDuration);            
            if (promotionData.rewardParameters.publishDuration > config.maxPublishDuration) // Bad max posts to mirrors ratio
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_maxPublishedDuration);
        }  
        // receive duration      
        if (promotionData.rewardParameters.commentsReceived != 0 || promotionData.rewardParameters.likesReceived != 0) {
            if (promotionData.rewardParameters.receiveDuration < config.minReceiveDuration) // Bad min c/l receive duration
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_minCommentsAndLikesReceiveDuration);            
            if (promotionData.rewardParameters.receiveDuration > config.maxReceiveDuration) // Bad max c/l receive duration
                revert ErrorCode(DataTypes.ErrorCode.createPromotion_maxCommentsAndLikesReceiveDuration);
        }
        
        // Reward Tiers
        uint256 rewardTiersLength = promotionData.rewardTiers.length;
          
        if (rewardTiersLength > config.maxRewardTiers) // Max reward tiers
            revert ErrorCode(DataTypes.ErrorCode.createPromotion_maxRewardTiers);

        // prevRewardTier for checking each next tier has higher values
        DataTypes.RewardTier memory prevRewardTier; 
        for (uint256 i = 0; i < rewardTiersLength;) {
            DataTypes.RewardTier memory rewardTier = promotionData.rewardTiers[i];            
            if (i == 0) {
                // if first tier
                if (rewardTier.amount < config.minReward) // First reward tier bad reward
                    revert ErrorCode(DataTypes.ErrorCode.createPromotion_firstRewardTierAmount);              
            } else {
                // if second and each next
                if (rewardTier.followers <= prevRewardTier.followers) // Next reward tier bad followers
                    revert ErrorCode(DataTypes.ErrorCode.createPromotion_nextRewardTierFollowers);      
                if (rewardTier.amount <= prevRewardTier.amount) // Next reward tier bad amount
                    revert ErrorCode(DataTypes.ErrorCode.createPromotion_nextRewardTierAmount);      
            }
            prevRewardTier = rewardTier;
            unchecked { i++; }
        }

        accountStats[msg.sender].promotions += 1;
                
        _emitEvent(DataTypes.EventCode.PROMO_CREATE, abi.encode(profileId, pubId, dataLayerId, promotionData));
	}
   
    function updatePromotion(uint128 profileId, uint128 pubId, uint128 dataLayerId, DataTypes.Promotion calldata promotionData) external whenNotPaused {
        _onlyProfileOwner(profileId);

        DataTypes.Promotion storage promotion = promotions[profileId][pubId][dataLayerId];
        
        if (promotion.createdTimestamp == 0) // Promotion not found
            revert ErrorCode(DataTypes.ErrorCode.updatePromotion_notFound);

        bool updated;

        if (promotionData.duration != promotion.duration) {
            if (promotionData.duration == 0) {
                promotion.duration = config.maxDuration; 
            } else {
                promotion.duration = promotionData.duration; 
                if (promotion.duration > config.maxDuration) // Duration too long
                    revert ErrorCode(DataTypes.ErrorCode.updatePromotion_maxDuration);
            }    
            updated = true;
        }

        if (promotionData.active != promotion.active) { 
            promotion.active = promotionData.active;
            updated = true;
        }  

        if (promotionData.budget != promotion.budget) { 
            promotion.budget = promotionData.budget; 
            updated = true;
        }
        
        if (updated) {
            _emitEvent(DataTypes.EventCode.PROMO_UPDATE, abi.encode(profileId, pubId, dataLayerId, promotion));
        } else {
            revert ErrorCode(DataTypes.ErrorCode.updatePromotion_nothingToUpdate);
        }       
    }
   
    function removePromotion(uint128 profileId, uint128 pubId, uint128 dataLayerId) external whenNotPaused {
        _onlyProfileOwner(profileId);

        DataTypes.Promotion storage promotion = promotions[profileId][pubId][dataLayerId];
       
        if (promotion.createdTimestamp == 0) // Promotion not found
            revert ErrorCode(DataTypes.ErrorCode.removePromotion_notFound);
        
        if (promotion.locked != 0 || promotion.payout != 0) // Not allowed
            revert ErrorCode(DataTypes.ErrorCode.removePromotion_notAllowed);
        
        delete promotions[profileId][pubId][dataLayerId];

        accountStats[msg.sender].promotions -= 1;
          
        _emitEvent(DataTypes.EventCode.PROMO_REMOVE, abi.encode(profileId, pubId, dataLayerId));
    }

    /**
     * @notice Used if mirror already exist
     */
    function applyPromotion(DataTypes.MirrorData calldata mirrorData, bytes calldata serviceSignature) external {
        _checkServiceSignature(keccak256(abi.encode(mirrorData)), serviceSignature);        
        _applyPromotion(mirrorData);
    }
    /**
     * @notice Used if mirror already exist and promo required follow first
     */
    function followAndApply(ILensHub.FollowWithSigData calldata followWithSigData, DataTypes.MirrorData calldata mirrorData, bytes calldata serviceSignature) external {
        _checkServiceSignature(keccak256(abi.encode(followWithSigData, mirrorData)), serviceSignature);
        _followWithSig(followWithSigData);
        _applyPromotion(mirrorData);
    }
    
    /**
     * @notice Used for on-chain publications
     */
    function mirrorAndApply(ILensHub.MirrorWithSigData calldata mirrorWithSigData, DataTypes.MirrorData memory mirrorData, bytes calldata serviceSignature) external {
        _checkServiceSignature(keccak256(abi.encode(mirrorWithSigData, mirrorData)), serviceSignature);    
        mirrorData.pubId = uint128(lensHub.mirrorWithSig(mirrorWithSigData)); 
        _applyPromotion(mirrorData);
    }
    /**
     * @notice Used for on-chain publications that required follow first
     */
    function followAndMirrorAndApply(ILensHub.FollowWithSigData calldata followWithSigData, ILensHub.MirrorWithSigData calldata mirrorWithSigData, DataTypes.MirrorData memory mirrorData, bytes calldata serviceSignature) external {
        _checkServiceSignature(keccak256(abi.encode(followWithSigData, mirrorWithSigData, mirrorData)), serviceSignature);
        _followWithSig(followWithSigData);
        mirrorData.pubId = uint128(lensHub.mirrorWithSig(mirrorWithSigData));
        _applyPromotion(mirrorData);
    }

    function _followWithSig(ILensHub.FollowWithSigData calldata followWithSigData) internal {
        if (followWithSigData.profileIds.length != 1) // Only one follow supported
            revert ErrorCode(DataTypes.ErrorCode.follow_onlySingleFollowSupported);
        
        address followNft = lensHub.getFollowNFT(followWithSigData.profileIds[0]);  
        if (followNft == address(0) || ILensHub(followNft).balanceOf(msg.sender) == 0) {
            lensHub.followWithSig(followWithSigData);
        }
    }

    function _applyPromotion(DataTypes.MirrorData memory mirrorData) internal whenNotPaused {
        uint128 profileId = mirrorData.profileId;
        _onlyProfileOwner(profileId);
        
        uint128 profileIdPointed = mirrorData.profileIdPointed;
        uint128 pubIdPointed = mirrorData.pubIdPointed;   
        uint128 dataLayerIdPointed = mirrorData.dataLayerIdPointed;
                
        // own publication can't be reposted for rewards        
        if (mirrorData.profileIdPointed == profileId) // Own publication not allowed
            revert ErrorCode(DataTypes.ErrorCode.mirror_ownNotAllowed);
        
        DataTypes.Promotion storage promotion = promotions[profileIdPointed][pubIdPointed][dataLayerIdPointed];
        // check if promo created and active        
        if (promotion.createdTimestamp == 0) // Promotion not found
            revert ErrorCode(DataTypes.ErrorCode.mirror_promotionNotFound);
        if (!promotion.active) // Promotion disabled
            revert ErrorCode(DataTypes.ErrorCode.mirror_promotionDisabled);

        if (promotion.duration == 0) {
            if (block.timestamp > promotion.createdTimestamp + config.maxDuration) // Promotion max time limit
                revert ErrorCode(DataTypes.ErrorCode.mirror_maxDuration);
        } else {
            if (block.timestamp > promotion.createdTimestamp + promotion.duration) // Promotion time past
                revert ErrorCode(DataTypes.ErrorCode.mirror_duration);
        }
                
        // check influencer following promoter         
        if (promotion.mustFollow) {
            address followNft = lensHub.getFollowNFT(profileIdPointed);            
            if (ILensHub(followNft).balanceOf(msg.sender) == 0) // Must follow post owner
                revert ErrorCode(DataTypes.ErrorCode.mirror_mustFollow);
        }

        // mirror params
        DataTypes.Mirror storage mirror = mirrors[profileId][profileIdPointed][pubIdPointed][dataLayerIdPointed];
        
        if (mirror.pubId != 0) // Already reposted
            revert ErrorCode(DataTypes.ErrorCode.mirror_alreadyCreated);

        mirror.profileId = profileId;
        mirror.pubId = mirrorData.pubId;
        mirror.dataLayerId = mirrorData.dataLayerId;        
        mirror.reward = mirrorData.reward;
        mirror.serviceFee = mirrorData.reward * config.serviceFee / feeBase;
        
        // if budget is set check if promo not out of limit
        uint128 locked = mirror.reward + mirror.serviceFee;
        promotion.locked += locked;

        // if budget is set check if promo not out of limit
        if (promotion.budget != 0) {            
            if (promotion.budget < promotion.locked + promotion.payout) // Out of promotion budget
                revert ErrorCode(DataTypes.ErrorCode.mirror_promotionBudget);
        }
        
        // update promoter wallet locked and balance check
        DataTypes.Wallet storage wallet = wallets[profileIdPointed];        
        wallet.locked += locked;    

        address promoterWallet = lensHub.ownerOf(profileIdPointed);
        accountStats[promoterWallet].mirrors += 1;    

        accountStats[msg.sender].mirrored += 1;  
        
        if (wallet.balance < wallet.locked) // Low promoter budget
            revert ErrorCode(DataTypes.ErrorCode.mirror_promoterBudget);
                                     
        _emitEvent(DataTypes.EventCode.MIRROR, abi.encode(mirrorData, mirror, promotion.locked, wallet.locked));
	}
    
    // --------------------- RESTRICTED ---------------------
    
    function pauseToggle() external onlyOwner() {
        paused = !paused;
        _emitEvent(DataTypes.EventCode.PAUSE, abi.encode(paused));
    }
    modifier whenNotPaused() {
        if (paused) // Low promoter budget
            revert ErrorCode(DataTypes.ErrorCode.paused);
        _;
    }
    
    // migration
    struct MigWallData {
        uint128 profileId;        
        DataTypes.Wallet wallet;
    }
    function migrateWallets(MigWallData[] calldata migArr) external onlyOwner {
        for (uint256 i = 0; i < migArr.length; i++) {
            wallets[migArr[i].profileId] = migArr[i].wallet;
        }
    }

    struct MigAccData {
        address wallet;        
        DataTypes.Account account;
    }
    function migrateAccounts(MigAccData[] calldata migArr) external onlyOwner {
        for (uint256 i = 0; i < migArr.length; i++) {
            accountStats[migArr[i].wallet] = migArr[i].account;
        }
    }

    struct MigPromData {
        uint128 profileId;
        uint128 pubId;
        uint128 dataLayerId;
        DataTypes.Promotion promotion;
    }
    function migratePromotions(MigPromData[] calldata migArr) external onlyOwner {
        for (uint256 i = 0; i < migArr.length; i++) {
            promotions[migArr[i].profileId][migArr[i].pubId][migArr[i].dataLayerId] = migArr[i].promotion;
        }
    }

    struct MigMirrData {
        uint128 infProfileId;  
        uint128 promProfileId;     
        uint128 pubId;
        uint128 dataLayerId;   
        DataTypes.Mirror mirror;
    }
    function migrateMirrors(MigMirrData[] calldata migArr) external onlyOwner {
        for (uint256 i = 0; i < migArr.length; i++) {
            mirrors[migArr[i].infProfileId][migArr[i].promProfileId][migArr[i].pubId][migArr[i].dataLayerId] = migArr[i].mirror;
        }
    }
   
    /**
     * @notice Release rewards + serviceFees of eligible influencers previously locked on repost
     * @dev Only service wallet can call this method (from server side script) 
     * Server side should check each mirror is met all conditions before call
     *
     * @param items Arrayy of Distribution struct items 
     */   
        
    function distribute(DataTypes.Distribution[] calldata items) external returns (uint8[] memory result) {       
        if (msg.sender != config.serviceWallet) // 
            revert ErrorCode(DataTypes.ErrorCode.distribute_serviceWallet);

        uint256 serviceFees;
        result = new uint8[](items.length);

        for (uint256 i = 0; i < items.length;) {
            DataTypes.Distribution calldata item = items[i];  

            uint128 profileId = item.profileId;
            uint128 profileIdPointed = item.profileIdPointed;
            uint128 pubIdPointed = item.pubIdPointed;
            uint128 dataLayerIdPointed = item.dataLayerIdPointed;
            
            DataTypes.Mirror storage mirror = mirrors[profileId][profileIdPointed][pubIdPointed][dataLayerIdPointed];                       
            
            if (mirror.pubId == 0) { 
                result[i] = 1;// Mirror not found
                continue; 
            } 
           
            if (mirror.reward == 0) { 
                result[i] = 2;// Already rewarded
                continue;
            }                
                            
            DataTypes.Promotion storage promotion = promotions[profileIdPointed][pubIdPointed][dataLayerIdPointed];
                        
            // total promoter locked payout
            uint128 payout = mirror.reward + mirror.serviceFee;

            DataTypes.Wallet storage wallet = wallets[profileIdPointed];  
                          
            if (promotion.locked < payout) { // Not enough locked funds
                result[i] = 3;
                continue;
            }
                                
            if (wallet.locked < payout) { // Not enough locked funds
                result[i] = 4;
                continue;
            }                
                
            // unlock payout from promotion locked   
            unchecked { 
                promotion.locked -= payout; 
                wallet.locked -= payout;
            } 

            address promoterWallet = lensHub.ownerOf(profileIdPointed);

            DataTypes.EventCode eventCode;
            if (lensHub.exists(profileId)) {                
                // full payout    
                if (item.isReward) {
                    wallet.balance -= payout;
                    wallet.rewards += mirror.reward;
                    wallet.serviceFees += mirror.serviceFee;
                    promotion.payout += payout;  

                    address influencerWallet = lensHub.ownerOf(profileId);                  
                    paymentToken.safeTransfer(influencerWallet, mirror.reward); 

                    eventCode = DataTypes.EventCode.REWARD;
                    result[i] = 10;

                    accountStats[promoterWallet].spent += payout;
                    accountStats[influencerWallet].mirroredSuccessful += 1;
                    accountStats[influencerWallet].earned += mirror.reward;
                } else {  
                    eventCode = DataTypes.EventCode.UNLOCK;
                    result[i] = 20;
                }              
            } else {   
                // payout only service fee in case if profile is burned and return rewards to promoter                
                wallet.balance -= mirror.serviceFee; 
                wallet.serviceFees += mirror.serviceFee;
                promotion.payout += mirror.serviceFee;                
                eventCode = DataTypes.EventCode.RETURN;
                result[i] = 30;

                accountStats[promoterWallet].spent += mirror.serviceFee;
            } 
            _emitEvent(eventCode, abi.encode(profileId, profileIdPointed, pubIdPointed, dataLayerIdPointed, mirror.reward, mirror.serviceFee, promotion.locked, promotion.payout, wallet));

            // wipe reward amount to exclude double reward
            mirror.reward = 0;

            // service fee incurred in any case
            serviceFees += mirror.serviceFee;
                        
            unchecked { i++; }
        }

        // transfer only in case if service fee issued
        if (serviceFees != 0) {
            paymentToken.safeTransfer(config.serviceWallet, serviceFees); 
            _emitEvent(DataTypes.EventCode.SERVICE_FEE, abi.encode(serviceFees)); 
        }        
	}
    
    function setConfig(DataTypes.Config memory configData) public onlyOwner {   
        config = configData;
        _emitEvent(DataTypes.EventCode.CONFIG, abi.encode(config));                   
	}
    
    function recover(address token, uint128 amount) external onlyOwner {
        if (amount == 0) 
            revert ErrorCode(DataTypes.ErrorCode.recover_wrongAmount);
        
        if (token == address(0)) {
            // eth
			(bool success, ) = payable(owner()).call{ value: amount }("");
            if (!success) 
                revert ErrorCode(DataTypes.ErrorCode.recover_ethSendError);			
		} else {
            IERC20Upgradeable(token).safeTransfer(owner(), amount);
		} 

        _emitEvent(DataTypes.EventCode.RECOVER, abi.encode(token, amount)); 
	}

    // --------------------- PERIPHERALS ---------------------
        
    /**
     * @dev Performs check if caller is profile owner 
     */
    function _onlyProfileOwner(uint256 profileId) internal view virtual {
        if (lensHub.ownerOf(profileId) != msg.sender) //Not profile owner
            revert ErrorCode(DataTypes.ErrorCode.onlyProfileOwner);
    }

    /**
     * @dev Performs ECDSA signature check 
     */
    function _checkServiceSignature(bytes32 dataHash, bytes calldata signature) internal view {
		if (ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(dataHash), signature) != config.serviceWallet) // 
            revert ErrorCode(DataTypes.ErrorCode.signatureInvalid);
	}

    /**
     * @dev Events emitter for tracking only single event listener on server side.
     * Provides action name, action encoded data, tx of caller and timestamp.
     * Data must be decoded on server side according to emited action format.
     */
    function _emitEvent(DataTypes.EventCode eventCode, bytes memory data) internal {
		emit Event(eventCode, data, tx.origin, block.timestamp);
	}
    event Event(DataTypes.EventCode indexed eventCode, bytes data, address indexed caller, uint256 indexed timestamp);

    error ErrorCode(DataTypes.ErrorCode errorCode);
}

// SPDX-License-Identifier: none
pragma solidity ^0.8.19;

interface ILensHub {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct FollowWithSigData {
        address follower;
        uint256[] profileIds;
        bytes[] datas;
        EIP712Signature sig;
    }

    struct PostWithSigData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    struct MirrorWithSigData {
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    } 

    enum PubType {
        Post,
        Comment,
        Mirror,
        Nonexistent
    } 

    function getFollowNFT(uint256 profileId) external view returns (address);
    function getPubType(uint256 profileId, uint256 pubId) external view returns (PubType);
    
    function exists(uint256 tokenId) external view returns (bool);
    function mintTimestampOf(uint256 tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function sigNonces(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function followWithSig(FollowWithSigData calldata vars) external returns (uint256[] memory);
    function postWithSig(PostWithSigData calldata vars) external returns (uint256);
    function mirrorWithSig(MirrorWithSigData calldata vars) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title DataTypes
 * @author Amplicata
 *
 * @notice A standard library of data types used throughout the Amplicata
 */
library DataTypes {  

    struct PromotionData {
        bool active;
        bool mustFollow;        
        uint32 duration;
        uint128 budget;
        ProfileEligibility profileEligibility;
        RewardParameters rewardParameters;                
        RewardTier[] rewardTiers;
    }
    struct ProfileEligibility {
        uint8 mode;
        uint32 minRank;
        uint32 maxRank;
        uint32 minPosts;
        uint32 minComments;
        uint32 minAge;
        uint8 minPostsToMirrorsRatio;
        uint32 maxMirrors;
        uint32 mirrorsForLastDuration;        
    }
    
    struct RewardParameters {
        uint32 publishDuration;
        uint32 commentsReceived;
        uint32 likesReceived;
        uint32 receiveDuration;
    }
    
    struct RewardTier {
        uint32 followers;
        uint128 amount;
    }

    struct Promotion {
        bool active;
        bool mustFollow;        
        uint32 createdTimestamp;
        uint32 duration;
        uint128 budget;
        uint128 locked;
        uint128 payout;
    }
        
    struct Mirror {   
        uint128 profileId;     
        uint128 pubId;
        uint128 dataLayerId; 
        uint128 reward;
        uint128 serviceFee;
    }
    
    struct Wallet {
        uint128 balance;
        uint128 locked;
        uint128 rewards;
        uint128 serviceFees;
    }

    struct Account {
        uint128 spent;
        uint128 earned; 
        uint32 promotions;
        uint32 mirrors;
        uint32 mirrored;  
        uint32 mirroredSuccessful;  
    }
        
    struct Config { 
        address serviceWallet;
        uint128 minReward; 
        uint32 minDuration;
        uint32 maxDuration;
        uint32 minPublishDuration;
        uint32 maxPublishDuration;
        uint32 minReceiveDuration;
        uint32 maxReceiveDuration;          
        uint8 serviceFee;                
        uint8 maxRewardTiers;              
        uint8 maxMirrors;
        uint8 mirrorsForLastDuratioWeeks;                
    }
    
    struct Distribution {
        uint128 profileId;
        uint128 profileIdPointed;
        uint128 pubIdPointed;
        uint128 dataLayerIdPointed;
        bool isReward;
    }
    
    
    struct MirrorData {
        uint128 profileId;        
        uint128 pubId;
        uint128 dataLayerId;               
        uint128 profileIdPointed;        
        uint128 pubIdPointed;
        uint128 dataLayerIdPointed; 
        uint128 reward;       
    }
          
    enum EventCode {
        DEPOSIT,
        WITHDRAW,
        PROMO_CREATE,
        PROMO_UPDATE,
        PROMO_REMOVE,
        MIRROR,
        REWARD,
        UNLOCK,
        RETURN,
        SERVICE_FEE,
        CONFIG,
        RECOVER,
        PAUSE
    }

    enum ErrorCode {
        paused,
        onlyProfileOwner,
        signatureInvalid,
        deposit_wrongAmount,
        deposit_profileNotExist,
        withdraw_wrongAmount,
        withdraw_insufficientBalance,  
        postAndPromote_publicationIdNotMatch,
        follow_onlySingleFollowSupported,        
        createPromotion_onlyOwnPublication,
        createPromotion_alreadyCreated,
        createPromotion_wrongDuration,
        createPromotion_rankRange,
        createPromotion_minPostsToMirrorsRatio,
        createPromotion_mustSetPublishedOrReceived,
        createPromotion_minPublishedDuration,
        createPromotion_maxPublishedDuration,
        createPromotion_maxMirrors,
        createPromotion_mirrorsForLastDuration,
        createPromotion_minCommentsAndLikesReceiveDuration,
        createPromotion_maxCommentsAndLikesReceiveDuration,
        createPromotion_maxRewardTiers,
        createPromotion_firstRewardTierAmount,
        createPromotion_nextRewardTierFollowers,
        createPromotion_nextRewardTierAmount,
        updatePromotion_notFound,
        updatePromotion_maxDuration,
        updatePromotion_nothingToUpdate,
        setPromotionActive_notFound,
        setPromotionActive_alreadySet,
        removePromotion_notFound,
        removePromotion_notAllowed,
        mirror_serviceSignature,
        mirror_ownNotAllowed,
        mirror_promotionNotFound,
        mirror_promotionDisabled,
        mirror_maxDuration,
        mirror_duration,
        mirror_mustFollow,
        mirror_minAge,
        mirror_alreadyCreated,
        mirror_rewardTierIdx,
        mirror_lensHubMirrorWithSig,
        mirror_promotionBudget,
        mirror_promoterBudget,
        distribute_serviceWallet,
        distribute_mirrorNotFound,
        distribute_noAlreadyRewarded,
        distribute_promotionNotFound,
        distribute_promotionLowLocked,   
        distribute_walletLowLocked, 
        setConfig_serviceWallet,
        setConfig_serviceFee,
        setConfig_feeBase,
        setConfig_maxRewardTiers,
        setConfig_maxDuration,
        setConfig_minPublishDuration,
        setConfig_maxPublishDuration,
        setConfig_minReceiveDuration,
        setConfig_maxReceiveDuration,
        setConfig_maxMirrors,
        setConfig_mirrorsForLastDuratioWeeks,
        recover_wrongAmount,
        recover_ethSendError,
        recover_profileId,
        recover_profileNotBurned,
        recover_profileLowBalance               
    }    
}