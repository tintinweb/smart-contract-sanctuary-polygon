/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

/**
 *Submitted for verification at BscScan.com on 2023-06-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-06-06
*/

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: OTCAQL.sol

//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;





interface AQLToken{
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}

contract _OTC_platform   is OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Project Token
    AQLToken public token ;
    // Platform Fee
    uint256 public platformTokenFee;
    // OTC Ids;
    // uint256 private otcIds;
    uint256 public _otcID;
    // Created Offers
    mapping(address=>mapping(uint256=>Offer)) public userOffers;
    mapping(uint256=>Offer) public getOffers;
    mapping(address=>uint256[]) private getActiveOffers;
    // Open Offers
    mapping(uint256=>Offer) public OpenOffers;
    //users Id
    mapping(address=>uint256) private Ids;
    // Checking  funds are Received or not 
    mapping(address=>mapping(uint256=>bool)) public isFunded;
    // All Open offers Ids;
    uint256[] AllOpenOrdersIds;
    // maxFunding Time
    uint256 public maxTimeToDepositFunds;
    // transaction Fee
    uint256 public transactionFee;
    mapping(uint256=>_counterOffer)public _counterDetails;
    mapping(uint256=>bool)public isCounter;
    // Burn Percentage
    uint256 public burnPercentage;
    // burn Fee for Not funded Offers
    uint256 public burnFeePercentForNotFunded;
    // Tx Fee Total Collected Amount
    mapping(address=>uint256) public totalTxTokenFee;
    // holding tokenAmount
    mapping(address=>uint256) public  holdingAmount;
    // Counter Offer Accepted
    mapping(uint256=>bool) public isOfferAccepted;
    //Total Pending Tax
    mapping(address=>uint256) private pendingTaxes;
    // Avoiding to pay multiple times tax
    mapping(address=>mapping(uint256=>bool)) private isPaidFee;
   
   struct _counterOffer{
        address creator;
        address accepter;
        address offerToken;
        uint256 offerAmount;
        address _requestToken;
        uint256 _requestAmount;
    }

    struct Offer{
        uint256 OtcId;
        uint256 userIds;
        address _creator;
        address _Accepter;
        address _offerToken;
        uint256 _offerAmount;
        address _requestToken;
        uint256 _requestAmount;
        uint256 _offerAcceptTime;
        string _status;
    }

    

    //Events
    event SetPlatformFee(uint256 _newFee);
    event SetAddress(address _newToken);
    event SetLimitTime(uint256 _timeToFund);
    event CreateOffer(uint256 otcID, uint256 userId, address user, address _offerToke, uint256 _offerAmount,address requestToken, uint256 requestAmount);
    event AccetOffer(uint256 otcId, address _accepterAddress,uint256 acceptedTime, uint256 feeAmount, string tradeStatus);
    event CounterOffer(uint256 otcId, address _accepterAddress,uint256 acceptedTime, uint256 feeAmount, address offerToken, uint256 offerAmount);
    event ReleaseFunds(uint256 otcID, address user,uint256 amount,bool isFunded);
    event RejectOffer(uint256 otcID, address _user);
    event RevokeOffer(uint256 otcId,address user,address offerToken,uint256 offerAmount);
    event SettleFunds(uint256 otcId,address user,address accepter,address tokenAddress, uint256 tokenAmount, address requestToken, uint256 requestAmount);
    event SetBurnPercentage(uint256 _burn);
    event WithdrawExcessTokens(address _tokenAddress, uint256 amount);
    event ClaimFunds(uint256 otcId, uint256 burnAmount);
    event AcceptCounterOffer(uint256 otcID, address _accepter, uint256 acceptTime, address requestToken,uint256 requestAmount, string status);
    event RejectCounterOffer(uint256 otcId, uint256 platformFee);
    event SetTransactionFee(uint256 _txFee);
    event BurnFeePercentage(uint256 _burnFee);
    event RejectPrivateOffer(address _accepter, uint256 otcID,uint256 _userID);

    // Initialize the Funtion 
     function initialize(address _token, uint256 _fee, uint256 _timeToFund,uint256 _txFee,uint256 _burnPercentage, uint256 _burnFeePercentForNotFunded)external initializer{
            platformTokenFee=_fee;
            _otcID=1;
            burnPercentage=_burnPercentage;
            maxTimeToDepositFunds=_timeToFund*1 minutes;
            token=AQLToken(_token);
            __Ownable_init();
            burnFeePercentForNotFunded=_burnFeePercentForNotFunded;
            transactionFee=_txFee;
        }

    // Create offer with required Tokens
    function createOffer(address _offerToken, uint256 _offerAmount, address _requestToken, uint256 _requestAmount, address accepter)external{
          uint256 userId=Ids[msg.sender]+1;
          Ids[msg.sender]++;
          Offer storage _offer=userOffers[msg.sender][userId];
          uint256 id=_otcID;
          _offer.OtcId=id;
          _otcID++;
          _offer.userIds=userId;
          _offer._offerToken=_offerToken;
          _offer._offerAmount=_offerAmount;
          _offer._requestToken=_requestToken;
          _offer._requestAmount=_requestAmount;
          _offer._creator=msg.sender;
          if(accepter!=address(0))
                _offer._Accepter=accepter;
          else 
                _offer._Accepter=address(0);
          _offer._status="Pending"; 
          getActiveOffers[msg.sender].push(userId);
          AllOpenOrdersIds.push(id);
          OpenOffers[id]=_offer;
          getOffers[id]=_offer;
          pendingTaxes[address(token)]+=platformTokenFee;
          token.transferFrom(msg.sender,address(this),platformTokenFee);
          emit CreateOffer(id,userId,msg.sender,_offerToken,_offerAmount,_requestToken,_requestAmount);
    }

    function rejectOwnoffer(uint256 _otcId)external {
      address _creator=getOffers[_otcId]._creator;
      require(_creator==msg.sender,"Not Creator");
      uint256 __userId=getOffers[_otcId].userIds;
      delete userOffers[_creator][__userId];
      delete getOffers[_otcId];
      removeId(_creator,_otcId,true); 
      removeId(msg.sender,_otcId,false);
      pendingTaxes[address(token)]-=platformTokenFee;
      token.transfer(_creator,platformTokenFee);
    }

    

    // Function to accept only direct Offers not counter Offers
    function acceptOffer(uint256 otcId)external{
        require(!isCounter[otcId],"Check Offer Type");
        uint256 Id=getOffers[otcId].userIds ;
        address creator=getOffers[otcId]._creator ;
         Offer storage _offer=userOffers[creator][Id];
          if(_offer._Accepter!=address(0)){
              require(_offer._Accepter==msg.sender,"Not a Exact User");
          }
        //   require(getOffers[otcId]._Accepter==address(0),"Already Offer Accepted");
          require(creator!=msg.sender && keccak256(bytes(getOffers[otcId]._status))==keccak256(bytes("Pending")) ,"Not Allowed");
          delete OpenOffers[otcId];
          removeId(msg.sender,otcId,false);
          _offer._status="Active";
          isOfferAccepted[otcId]=true;
          if(_offer._Accepter!=address(0))
               _offer._Accepter =_offer._Accepter;
          else 
               _offer._Accepter=msg.sender;
          _offer._offerAcceptTime=block.timestamp;
          pendingTaxes[address(token)]+=platformTokenFee;
          getOffers[otcId]=_offer;
          token.transferFrom(msg.sender,address(this),platformTokenFee);
          emit AccetOffer(otcId,msg.sender,block.timestamp,platformTokenFee,"Active");
    }
    
    // Once  UserA and UserB Accepted offer, user need to depositFunds
    function depositFunds(uint256 otcId)external{
          Offer memory offer = getOfferDetails(otcId);
          (address creator,address accept,address offerToken,uint256 offerAmount,address requestToken,uint256 requestAmount)=(offer._creator,offer._Accepter,offer._offerToken,offer._offerAmount,offer._requestToken,offer._requestAmount);
          require(creator==msg.sender ||accept==msg.sender,"No Allowed");
          require(keccak256(bytes(getOffers[otcId]._status))==keccak256(bytes("Active")) && !isFunded[msg.sender][otcId],"Check Order status & isFunded");
          if(creator==msg.sender){
              isFunded[msg.sender][otcId]=true;
              holdingAmount[address(offerToken)]+=offerAmount;
              IERC20Upgradeable(offerToken).safeTransferFrom(msg.sender,address(this),offerAmount);
          }else{
              isFunded[msg.sender][otcId]=true;
              holdingAmount[address(requestToken)]+=requestAmount;
              IERC20Upgradeable(requestToken).safeTransferFrom(msg.sender,address(this),requestAmount);
          }
          emit ReleaseFunds(otcId,msg.sender,offerAmount,isFunded[msg.sender][otcId]);
    }

    // function to reject offer 
    function rejectOffer(uint256 otcId)external {
          Offer memory offer = getOfferDetails(otcId);
          require(keccak256(bytes(getOffers[otcId]._status))==keccak256(bytes("Active")),"Check Order status");
          (address creator,address accept, uint256 userID,address offerToken, uint256 offerAmount,address requestToken,uint256  requestAmount)=(offer._creator,offer._Accepter,offer.userIds,offer._offerToken,offer._offerAmount,offer._requestToken, offer._requestAmount);
          require(creator==msg.sender ||accept==msg.sender,"No Allowed");
          uint256 _amount=((2*platformTokenFee)*burnPercentage)/10000;
          require(!isFunded[creator][otcId] || !isFunded[accept][otcId],"Both Users Funded");
          delete userOffers[creator][userID];
          delete getOffers[otcId];
          removeId(creator,otcId,true); 
          if(creator==msg.sender){
            token.transfer(accept,(2*platformTokenFee)-_amount);
          }else{
            token.transfer(creator,(2*platformTokenFee)-_amount);

          }
          if(isFunded[creator][otcId]){
                holdingAmount[address(offerToken)]-=offerAmount;
                IERC20Upgradeable(offerToken).safeTransfer(creator,offerAmount);
            }
          if(isFunded[accept][otcId]){
                holdingAmount[address(requestToken)]-=requestAmount;
                IERC20Upgradeable(requestToken).safeTransfer(accept,requestAmount);
            }
          pendingTaxes[address(token)]-=(2*platformTokenFee);
           token.burn(_amount);
          emit RejectOffer(otcId,msg.sender);
    }



    function rejectPrivateOffer(uint256 _otcId)external {
        address _accepter=getOffers[_otcId]._Accepter ;
        address _creator=getOffers[_otcId]._creator;
        uint256 __userId=getOffers[_otcId].userIds;
         require(keccak256(bytes(getOffers[_otcId]._status))==keccak256(bytes("Pending")),"Check Order status");
        require(msg.sender==_accepter,"Not a Assigned Accepter");
        removeId(_creator,_otcId,true); 
        removeId(msg.sender,_otcId,false);
        uint256 amount=(platformTokenFee*10)/100;
        token.transfer(msg.sender,amount);
        pendingTaxes[address(token)]-=platformTokenFee;
        token.transfer(_creator,platformTokenFee-amount);
        emit RejectPrivateOffer(_accepter,_otcId,__userId);

    }

    function revokeOffer(uint256 otcId)external{
        Offer memory offer = getOfferDetails(otcId);
        require(keccak256(bytes(getOffers[otcId]._status))==keccak256(bytes("Active"))  ,"Check Order status");
        (uint256 userID,
        address creator,
        address accept,
         uint256 offerAcceptTime, 
         uint256 offerAmount, 
         address offerToken,
         address requestToken,
         uint256 requestAmount)=(
            offer.userIds,
            offer._creator,
            offer._Accepter,
            offer._offerAcceptTime, 
            offer._offerAmount, 
            offer._offerToken,
            offer._requestToken,
            offer._requestAmount);
        require(creator==msg.sender || accept==msg.sender,"invalid Users");
        require(isFunded[msg.sender][otcId],"Not Funed");
        require(block.timestamp>=offerAcceptTime+maxTimeToDepositFunds,"Wait for Funding Time");

        address _user;
        if(isFunded[creator][otcId] && isFunded[accept][otcId]){
             withdrawFunds(otcId);
        }else{

        delete userOffers[creator][userID];
        delete getOffers[otcId];
        removeId(creator,otcId,true); 
        if(msg.sender==creator){
           _user=creator;
           if(isFunded[creator][otcId]){
               holdingAmount[address(offerToken)]-=offerAmount;
               IERC20Upgradeable(offerToken).safeTransfer(msg.sender,offerAmount);
               }
               
        }
        else {
           _user=accept;
           if(isFunded[accept][otcId]){
                 holdingAmount[address(requestToken)]-=requestAmount;
                 IERC20Upgradeable(requestToken).safeTransfer(msg.sender,requestAmount);}
           }
        uint256 _amount= ((2*platformTokenFee)*burnPercentage)/10000;
        pendingTaxes[address(token)]-=2*platformTokenFee;
        require(token.transfer(_user,(2*platformTokenFee)-_amount),"Failed");
        token.burn(_amount);}
        emit RevokeOffer(otcId,msg.sender,offerToken,offerAmount);
    }
  
   // set Burn fee for not funded offers
    function setburnFeePercentForNotFunded(uint256 _burnFee)external onlyOwner{
        burnFeePercentForNotFunded=_burnFee;
        emit BurnFeePercentage(_burnFee);
    }

    // Function to Cancel Offer if users not Funded
    function cancelNotFundedOffers(uint256 otcId) external onlyOwner{
        require(getOffers[otcId].userIds !=0,"No Offers Found");
        uint256 _offerAcceptTime=  getOffers[otcId]._offerAcceptTime;
        address accepter = getOffers[otcId]._Accepter;
        address creator=getOffers[otcId]._creator;
        uint256 userID=getOffers[otcId].userIds;
        require(block.timestamp>=_offerAcceptTime+maxTimeToDepositFunds && !isFunded[accepter][otcId] && !isFunded[creator][otcId],"Check Funding Status");
        delete userOffers[creator][userID];
        delete getOffers[otcId];
        removeId(creator,otcId,false);       
        removeId(creator,otcId,true); 
        uint256 burnFee=(platformTokenFee*burnFeePercentForNotFunded)/10000;
        uint256 __ammount= platformTokenFee-burnFee;
        totalTxTokenFee[address(token)]-=(2*burnFee); 
        totalTxTokenFee[address(token)]+=(2*__ammount);
        pendingTaxes[address(token)]-=2*platformTokenFee;
        token.burn((2*burnFee));
        emit ClaimFunds(otcId,2*burnFee);
    }


    //Once Users Deposit funds. they can call withdrawFunds to get their Funds
    function withdrawFunds(uint256 otcId) public{
          require(keccak256(bytes(getOffers[otcId]._status))==keccak256(bytes("Active")),"Check Order status");
          Offer memory offer = getOfferDetails(otcId);
          (uint256 userID,address creator,address accept,address offerToken,uint256 offerAmount,address requestToken,uint256 requestAmount)=(offer.userIds,offer._creator,offer._Accepter,offer._offerToken,offer._offerAmount,offer._requestToken,offer._requestAmount);
          require(creator==msg.sender ||accept==msg.sender,"No Allowed");
          require(isFunded[creator][otcId] &&isFunded[accept][otcId],"Waiting for User Funds");
          uint256 _requestAmount=requestAmount-((requestAmount*transactionFee)/10000);
          uint256 _offerAmount=offerAmount-((offerAmount*transactionFee)/10000);
          totalTxTokenFee[requestToken]+=((requestAmount*transactionFee)/10000);
          totalTxTokenFee[offerToken]+=((offerAmount*transactionFee)/10000);
          holdingAmount[requestToken]-=requestAmount;
          holdingAmount[offerToken]-=offerAmount;
          totalTxTokenFee[address(token)]+=2*platformTokenFee;
          pendingTaxes[address(token)]-=2*platformTokenFee;
          delete userOffers[creator][userID];
          delete getOffers[otcId];
          removeId(creator,otcId,false);       
          removeId(creator,otcId,true);       
          IERC20Upgradeable(requestToken).safeTransfer(creator,_requestAmount);
          IERC20Upgradeable(offerToken).safeTransfer(accept,_offerAmount);
          emit SettleFunds(otcId,creator,accept,offerToken,_offerAmount,requestToken,_requestAmount);
    }

    function counterOffer(address offerToken, uint256 offerAmount,address requestToken, uint256 requestAmount,uint256 otcId)external {
        require(!isOfferAccepted[otcId],"Already Offer Accepted");
        address creator=getOffers[otcId]._creator ;
        if(getOffers[otcId]._Accepter!=address(0)){
            require(creator ==msg.sender ||getOffers[otcId]._Accepter==msg.sender ,"Already Offer Accepted");   
        }
        require(keccak256(bytes(getOffers[otcId]._status))==keccak256(bytes("Pending")) ,"Not Allowed");
        _counterOffer storage _counter=_counterDetails[otcId];
        isCounter[otcId]=true;
        _counter._requestToken=requestToken;
        _counter._requestAmount=requestAmount;
        if(msg.sender!=creator){
            _counter.accepter=msg.sender;
        }
       _counter.creator=creator;
        _counter.offerToken=offerToken;
        _counter.offerAmount=offerAmount;
        pendingTaxes[address(token)]+=platformTokenFee;
        if(!isPaidFee[msg.sender][otcId]){
              isPaidFee[msg.sender][otcId]=true;
              token.transferFrom(msg.sender,address(this),platformTokenFee);}
        emit CounterOffer(otcId,msg.sender,block.timestamp,platformTokenFee,offerToken,offerAmount);
    }

 

    function acceptCounterOffer(uint256 otcID)external {
        require(isCounter[otcID] ,"! Counter offer");
        require( !isOfferAccepted[otcID],"Already Accepted");
        _counterOffer memory _counter=_counterDetails[otcID];
        require(getOffers[otcID]._creator==msg.sender || _counter.accepter!=address(0) || _counter.accepter==msg.sender,"! Creator");
        delete OpenOffers[otcID];
        removeId(msg.sender,otcID,false);
        uint256 Id=getOffers[otcID].userIds;
        Offer storage _offer=userOffers[_counter.creator][Id];
        isOfferAccepted[otcID]=true;
        _offer._status="Active";

        if( _offer._Accepter==address(0))
            _offer._Accepter =_counter.accepter;
        else  
            _offer._Accepter=_offer._Accepter;  
        
        _offer._offerAcceptTime=block.timestamp;
        _offer._requestToken=_counter.offerToken;
        _offer._requestAmount=_counter.offerAmount;
        _offer._offerToken=_counter.offerToken;
        _offer._offerAmount=_counter.offerAmount;
        getOffers[otcID]=_offer;
        delete _counterDetails[otcID];
        emit AcceptCounterOffer(otcID, _offer._Accepter, _offer._offerAcceptTime,_offer._requestToken,_offer._requestAmount,_offer._status);
    }

    function rejectCounterOffer(uint256 otcId)external{
        require(isCounter[otcId],"! Counter offer");
        require(getOffers[otcId]._creator==msg.sender,"! Creator");
        _counterOffer memory _counter=_counterDetails[otcId];
        address accepter=_counter.accepter;
        delete _counterDetails[otcId];
        pendingTaxes[address(token)]-=platformTokenFee;
        token.transfer(accepter,platformTokenFee);
        emit RejectCounterOffer(otcId, platformTokenFee);
    }

    function getOfferDetails(uint256 otcId)public view returns(Offer memory  ){
      return getOffers[otcId];
    }

    function getUserActiveOffers(address _userAddress)external  view returns(uint256[] memory){
        return getActiveOffers[_userAddress];
    }

    function getAllOpenOffers()external view returns(uint256[] memory){
        return AllOpenOrdersIds;
    }
    function counterOfferDetails(uint256 __otcID)public view returns(_counterOffer memory){
        return _counterDetails[__otcID];
        
    }

    

    
    function removeId(address user,uint256 _Id, bool isUser) internal {
        uint256[] storage _ids;
        if(!isUser)
           _ids = AllOpenOrdersIds;
        else 
           _ids=getActiveOffers[user];
        for (uint256 i = 0; i < _ids.length; i++) {
            if (_ids[i] == _Id) {
                _ids[i] = _ids[_ids.length - 1];
                _ids.pop();
                break;
            }
        }
     }
      // Platform should be given in wei format
    function setPlatformFeeForToken(uint256 _newFee)external onlyOwner{
        platformTokenFee=_newFee;
        emit SetPlatformFee(_newFee);
    }
    function setTokenAddress(address _tokenAddress)external onlyOwner{
        token=AQLToken(_tokenAddress);
        emit SetAddress(_tokenAddress);
    }
     // _timeToFund should be given in normal Number 1= 1 day
    function setMaxTimeToDepositFunds(uint256 _timeToFund)external onlyOwner{
        maxTimeToDepositFunds=_timeToFund*1 minutes;
        emit SetLimitTime(_timeToFund);
    }
    // Set burn percentage for RejectOffer  1% = 100 || 0.1% = 10 || 0.01% =1

    function setBurnPercentage(uint256 _burn)external onlyOwner{
        burnPercentage=_burn;
        emit SetBurnPercentage(_burn);
    }

    //  owner need to give ERC20 tokenAddress and amount in wei format
    function withdrawExcessTokens(address _tokenAddress,uint256 amount)external onlyOwner{
        uint256 _amount=getTokenBalances(_tokenAddress);
        require(((_amount+totalTxTokenFee[_tokenAddress])-(holdingAmount[_tokenAddress] + pendingTaxes[_tokenAddress]))>=amount,"No Enough Funds");

        if(amount>totalTxTokenFee[_tokenAddress] )
             totalTxTokenFee[_tokenAddress]=0;
        else
            totalTxTokenFee[_tokenAddress]-=amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(msg.sender,amount);
        emit WithdrawExcessTokens(_tokenAddress,amount);
    }

    function getTokenBalances(address _tokenAddress)public view returns(uint256){
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }

    // _newTxFee should be 1% = 100 || 0.1% = 10 || 0.01% =1
    function setTransactionFee(uint256 _newTxFee)external onlyOwner{
        transactionFee=_newTxFee;
        emit SetTransactionFee(_newTxFee);
    }


}