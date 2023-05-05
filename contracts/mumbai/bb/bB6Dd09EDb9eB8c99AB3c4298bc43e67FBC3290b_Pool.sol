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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/// @title Prime IPool contract interface
interface IPool {
  /// @notice Pool member data struct
  struct Member {
    bool isCreated; // True if the member is created
    bool isWhitelisted; // True if the member is whitelisted
    uint256 principal; // Principal amount
    uint256 accrualTs; // Timestamp of the last accrual
    uint256 totalOriginationFee;
    uint256 totalInterest;
  }

  /// @notice Roll data struct
  struct Roll {
    uint256 startDate; // Start date of the roll
    uint256 endDate; // End date of the roll
  }

  /// @notice Callback data struct
  struct CallBack {
    bool isCreated; // True if the callback is created
    uint256 timestamp; // Timestamp of the callback
  }

  /// @notice Struct to store lender deposits as separate position
  struct Position {
    uint256 interest; // total interest for entire deposit period
    uint256 startAt; // Timestamp of the deposit
  }

  /// @notice Struct to avoid stack too deep error
  struct PoolData {
    bool isBulletLoan; // True if the pool is bullet loan, False if the pool is term loan
    address asset;
    uint256 size;
    uint256 tenor;
    uint256 rateMantissa;
    uint256 depositWindow;
  }

  /// @notice Initialize the pool
  /// @dev This function is called only once during the pool creation
  /// @param _borrower - Pool borrower address
  /// @param _spreadRate - Pool protocol spread rate
  /// @param _originationRate - Pool origination fee rate
  /// @param _incrementPerRoll - Pool rolling increment rate of origination fee
  /// @param _penaltyRatePerYear - Pool penalty rate calculated for 1 year
  /// @param _poolData - Pool data struct: asset, size, tenor, rateMantissa, depositWindow
  /// @param _members - Pool members (lenders) addresses encoded in bytes
  function __Pool_init(
    address _borrower,
    uint256 _spreadRate,
    uint256 _originationRate,
    uint256 _incrementPerRoll,
    uint256 _penaltyRatePerYear,
    PoolData calldata _poolData,
    bytes calldata _members
  ) external;

  /// @notice Whitelists lenders
  /// @dev Can be called only by the borrower
  /// @param lenders - Lenders addresses encoded in bytes
  function whitelistLenders(bytes calldata lenders) external returns (bool);

  /// @notice Blacklists lenders
  /// @dev Can be called only by the borrower
  /// @param lenders - Lenders addresses encoded in bytes
  function blacklistLenders(bytes calldata lenders) external returns (bool);

  /// @notice Converts the pool to public
  /// @dev Can be called only by the borrower
  /// @return success - True if the pool is converted to public
  function switchToPublic() external returns (bool success);

  /// @notice Lends funds to the pool
  /// @dev Can be called only by the whitelisted Prime lenders
  /// @param amount - Amount of funds to lend
  /// @return success - True if the funds are lent
  function lend(uint256 amount) external returns (bool success);

  /// @notice Fully repays the lender with the principal and interest
  /// @dev Can be called only by the borrower
  /// @param lender - Lender address
  /// @return success - True if the lender is repaid
  function repay(address lender) external returns (bool success);

  /// @notice Repays all lenders with the principal and interest
  /// @dev Can be called only by the borrower
  /// @return success - True if all lenders are repaid
  function repayAll() external returns (bool success);

  /// @notice Repays interest to the lender
  /// @dev Can be called only by the borrower in monthly loans
  function repayInterest() external;

  /// @notice Creates the callback
  /// @dev Can be called only by the whitelisted Prime lenders
  /// @return success - True if the callback is created by the lender
  function requestCallBack() external returns (bool success);

  /// @notice Cancels the callback
  /// @dev Can be called only by the whitelisted Prime lenders
  /// @return success - True if the callback is cancelled by the lender
  function cancelCallBack() external returns (bool success);

  /// @notice Requests the roll
  /// @dev Can be called only by the borrower
  function requestRoll() external;

  /// @notice Accepts the roll
  /// @dev Can be called only by the whitelisted Prime lenders
  function acceptRoll() external;

  /// @notice Defaults the pool
  /// @dev Can be called only by lender or borrower if time conditions are met
  /// @dev Can be called by governor without time conditions
  function markPoolDefaulted() external;

  /// @notice Closes the pool
  /// @dev Can be called only by the borrower
  /// @return success - True if the pool is closed
  function close() external returns (bool success);

  /// @notice Calculates the total due amount for repayment including interestAccrued, penalty fee and spread for all lenders
  /// @return totalDue - Total due amount for repayment
  function totalDue() external view returns (uint256 totalDue);

  /// @notice Calculates the due amount for repayment including interestAccrued, penalty fee and spread for the lender
  /// @param lender - The address of the lender
  /// @return due - Due amount for repayment
  /// @return spreadFee - Protocol spread fee
  /// @return originationFee - Origination protocol fee
  function dueOf(
    address lender
  ) external view returns (uint256 due, uint256 spreadFee, uint256 originationFee);

  /// @notice Calculates the total interest and penalty amount for the next payment for all lenders
  /// @return totalInterest The interest amount
  function totalDueInterest() external returns (uint256 totalInterest);

  /// @notice Calculates the total interest and penalty for the next payment to the lender
  /// @param lender The lender address
  /// @return due The interest amount
  /// @return spreadFee The spread amount
  function dueInterestOf(address lender) external view returns (uint256 due, uint256 spreadFee);

  /// @notice Calculates the accrued amount until today, excluding penalty
  /// @param lender - The address of the lender
  /// @return interestAccrued - Accrued amount until today
  function balanceOf(address lender) external view returns (uint256);

  /// @notice When maturity date passed, calculates the penalty fee for the lender
  /// @param lender - The address of the lender
  /// @return penaltyFee - Penalty fee
  function penaltyOf(address lender) external view returns (uint256);

  /// @notice Calculates the next payment timestamp for the borrower
  /// @return payableToTimestamp - The timestamp of the next payment
  function getNextPaymentTimestamp() external view returns (uint256);

  /// @notice Checks if the pool can be defaulted by borrower or lender
  /// @return isAbleToDefault True if the pool can be defaulted
  function canBeDefaulted() external view returns (bool isAbleToDefault);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {IPool} from './IPool.sol';
import {IPrime} from '../PrimeMembership/IPrime.sol';

/// @title Prime IPoolFactory interface
interface IPoolFactory {
  /// @notice Initialize the contract
  /// @dev This function is called only once during the contract deployment
  /// @param _prime Prime contract address
  /// @param _poolBeacon Beacon address for pool proxy pattern
  function __PoolFactory_init(address _prime, address _poolBeacon) external;

  /// @notice Creates a new pool
  /// @dev Callable only by prime members
  /// @param pooldata Bla bla bla
  /// @param members Pool members address encoded in bytes
  function createPool(IPool.PoolData calldata pooldata, bytes calldata members) external;

  function prime() external view returns (IPrime);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {IPool} from './IPool.sol';
import {IPoolFactory} from './IPoolFactory.sol';
import {IPrime} from '../PrimeMembership/IPrime.sol';

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import {NZAGuard} from '../utils/NZAGuard.sol';
import {AddressCoder} from '../utils/AddressCoder.sol';

/// @title Pool contract is responsible for managing the pool
contract Pool is IPool, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, NZAGuard {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Standart year in seconds
  uint256 public constant YEAR = 360 days;

  /// @notice Pool repayment option. Bullet loan or monthly repayment
  bool public isBulletLoan;

  /// @notice Pool publicity status
  bool public isPublic;

  /// @notice Pool availability status
  bool public isClosed;

  /// @notice Roll request status
  bool public isRollRequested;

  /// @notice Pool borrower address
  address public borrower;

  /// @notice Asset address of the pool
  address public asset;

  /// @notice Pool factory address
  IPoolFactory public factory;

  /// @notice Pool current size
  uint256 public currentSize;

  /// @notice Pool maximum size
  uint256 public maxSize;

  /// @notice Pool interest rate (in mantissa)
  uint256 public rateMantissa;

  /// @notice Protocol spread rate
  uint256 public spreadRate;

  /// @notice Origination fee rate
  uint256 public originationRate;

  /// @notice Pool rolling increment fee rate
  uint256 public incrementPerRoll;

  /// @notice Pool deposit window (in seconds)
  uint256 public depositWindow;

  /// @notice Pool deposit maturity
  uint256 public depositMaturity;

  /// @notice Pool tenor
  uint256 public tenor;

  /// @notice Pool maturity date
  uint256 public maturityDate;

  /// @notice Pool active roll id
  uint256 public activeRollId;

  /// @notice The last timestamp at which a payment was made or received in monthly repayment pool.
  uint256 public lastPaidTimestamp;

  /// @notice If pool is defaulted, this is the timestamp of the default
  uint256 public defaultedAt;

  /// @notice Pool lenders array
  address[] private _lenders;

  /// @notice Pool next roll id counter
  uint256 private _nextRollId;

  /// @notice Pool active lenders count
  uint256 internal _activeLendersCount;

  /// @notice Pool active callbacks count
  uint256 private _activeCallbacksCount;

  /// @notice Pool members mapping (lender address => Member struct)
  mapping(address => Member) private poolMembers;

  /// @notice Pool rolls mapping (roll id => Roll struct)
  mapping(uint256 => Roll) private _poolRolls;

  /// @notice Pool lender's positions (lender address => Positions array)
  mapping(address => Position[]) private _lenderPositions;

  /// @notice Pool callbacks mapping (lender address => CallBack struct)
  mapping(address => CallBack) private _poolCallbacks;

  /// @notice Pool penalty rate calculated for 1 year
  uint256 public penaltyRatePerYear;

  /// @notice Emitted when the pool is activated
  /// @param depositMaturity - Lender can deposit until this timestamp
  /// @param maturityDate - Borrower's maturity date (timestamp)
  event Activated(uint256 depositMaturity, uint256 maturityDate);

  /// @notice Emitted when pool is converted to public
  event ConvertedToPublic();

  /// @notice Emitted when pool is defaulted
  event Defaulted();

  /// @notice Emitted when the pool is closed
  event Closed();

  /// @notice Emitted when the roll is requested
  /// @param rollId - Id of the roll
  event RollRequested(uint256 indexed rollId);

  /// @notice Emitted when the pool is rolled
  /// @param rollId - Id of the new roll
  /// @param newMaturity - New maturity date (timestamp)
  event RollAccepted(uint256 indexed rollId, uint256 newMaturity);

  /// @notice Emitted when the roll is rejected
  /// @param rollId - Id of the roll
  /// @param user - Address of the user who rejected the roll
  event RollRejected(uint256 indexed rollId, address user);

  /// @notice Emitted when new lender is added to the pool
  event LenderWhitelisted(address lender);

  /// @notice Emitted when lender is removed from the pool
  event LenderBlacklisted(address lender);

  /// @notice Emitted when funds are lent to the pool
  event Lent(address indexed lender, uint256 amount);

  /// @notice Emitted when lender is fully repayed
  event Repayed(address indexed lender, uint256 repayed, uint256 spreadFee, uint256 originationFee);

  /// @notice Emitted when interest is repayed to the lender
  event RepayedInterest(address indexed lender, uint256 repayed, uint256 spreadFee);

  /// @notice Emitted when callback is created
  event CallbackCreated(address indexed lender);

  /// @notice Emitted when callback is cancelled
  event CallbackCancelled(address indexed lender);

  /// @notice Modifier to check if the caller is a prime member
  modifier onlyPrime() {
    _isPrimeMember(msg.sender);
    _;
  }

  /// @notice Modifier to check if the caller is a pool borrower
  modifier onlyBorrower() {
    require(msg.sender == borrower, 'NCR');
    _;
  }

  /// @notice Modifier to check if the pool is not closed
  modifier nonClosed() {
    require(!isClosed, 'OAC');
    _;
  }

  /// @notice Modifier to check if the pool is not defaulted
  modifier nonDefaulted() {
    require(defaultedAt == 0, 'PDD');
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @inheritdoc IPool
  function __Pool_init(
    address _borrower,
    uint256 _spreadRate,
    uint256 _originationRate,
    uint256 _incrementPerRoll,
    uint256 _penaltyRatePerYear,
    PoolData calldata _poolData,
    bytes calldata _members
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pool_init_unchained(
      _borrower,
      _spreadRate,
      _originationRate,
      _incrementPerRoll,
      _penaltyRatePerYear,
      _poolData,
      _members
    );
  }

  /// @dev The __Pool_init_unchained sets initial parameters for the pool
  /// @param _borrower The address of the borrower that created the pool
  /// @param _spreadRate The rate at which protocol will earn spread
  /// @param _originationRate The rate of yield enhancement intended to incentivize collateral providers
  /// @param _penaltyRatePerYear The rate at which borrower will pay additional interest for 1 year
  /// @param _incrementPerRoll - Pool rolling increment fee rate
  /// @param _poolData Data regarding the pool
  /// @param _members The list of members who rose the funds for the borrower
  function __Pool_init_unchained(
    address _borrower,
    uint256 _spreadRate,
    uint256 _originationRate,
    uint256 _incrementPerRoll,
    uint256 _penaltyRatePerYear,
    PoolData calldata _poolData,
    bytes calldata _members
  ) internal onlyInitializing {
    /// @dev Fill pool data
    borrower = _borrower;
    asset = _poolData.asset;
    maxSize = _poolData.size;
    tenor = _poolData.tenor;
    rateMantissa = _poolData.rateMantissa;
    depositWindow = _poolData.depositWindow;
    isBulletLoan = _poolData.isBulletLoan;
    spreadRate = _spreadRate;
    originationRate = _originationRate;
    incrementPerRoll = _incrementPerRoll;
    penaltyRatePerYear = _penaltyRatePerYear;

    /// @dev Starting new rolls from 1
    ++_nextRollId;

    /// @dev Factory is caller of initializer
    factory = IPoolFactory(msg.sender);

    /// @dev Pool is available for all prime users if it is public
    if (_members.length == 0) {
      isPublic = true;
    } else {
      _parseLenders(true, _members);
    }
  }

  /// @inheritdoc IPool
  function whitelistLenders(
    bytes calldata lenders
  ) external override onlyBorrower nonReentrant returns (bool success) {
    require(lenders.length != 0, 'LLZ');

    /// @dev Pool converts to private if it is public
    if (isPublic) {
      isPublic = false;
    }
    _parseLenders(true, lenders);
    return true;
  }

  /// @inheritdoc IPool
  function blacklistLenders(
    bytes calldata lenders
  ) external override onlyBorrower nonReentrant returns (bool success) {
    require(!isPublic, 'OPP');
    require(lenders.length != 0, 'LLZ');

    _parseLenders(false, lenders);
    return true;
  }

  /// @inheritdoc IPool
  function switchToPublic() external override onlyBorrower nonReentrant returns (bool success) {
    require(!isPublic, 'AAD');

    isPublic = true;

    emit ConvertedToPublic();
    return true;
  }

  /// @inheritdoc IPool
  function lend(
    uint256 amount
  )
    external
    override
    nonReentrant
    onlyPrime
    nonZeroValue(amount)
    nonClosed
    nonDefaulted
    returns (bool success)
  {
    return _lend(amount, msg.sender);
  }

  /// @inheritdoc IPool
  function repay(
    address lender
  )
    external
    override
    onlyBorrower
    nonZeroAddress(lender)
    nonDefaulted
    nonReentrant
    returns (bool success)
  {
    return _repayTo(lender);
  }

  /// @inheritdoc IPool
  function repayAll()
    external
    override
    onlyBorrower
    nonDefaulted
    nonReentrant
    returns (bool success)
  {
    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      _repayTo(_lenders[i]);
    }
    return true;
  }

  /// @inheritdoc IPool
  function repayInterest() external override onlyBorrower nonDefaulted nonReentrant {
    require(!isBulletLoan, 'NML');
    _repayInterest();
  }

  /// @inheritdoc IPool
  function requestCallBack()
    external
    override
    onlyPrime
    nonDefaulted
    nonClosed
    returns (bool success)
  {
    /// @dev Lender should have principal
    require(poolMembers[msg.sender].principal != 0, 'LZL');

    /// @dev Lender should not have created callback
    require(!_poolCallbacks[msg.sender].isCreated, 'AAD');

    /// @dev Callback can be created only before the maturity date
    require(block.timestamp < maturityDate, 'EMD');

    /// @dev If last lender requests callback and roll is requested
    /// @dev then roll is rejected
    if (isRollRequested) {
      _rejectRoll();
    }

    /// @dev Increases the number of active callbacks
    _activeCallbacksCount++;

    /// @dev Saves callback as a struct
    _poolCallbacks[msg.sender] = CallBack(true, block.timestamp);

    emit CallbackCreated(msg.sender);
    return true;
  }

  /// @inheritdoc IPool
  function cancelCallBack()
    external
    override
    nonDefaulted
    nonClosed
    onlyPrime
    returns (bool success)
  {
    /// @dev Lender should have created callback
    require(_poolCallbacks[msg.sender].isCreated, 'AAD');

    /// @dev Removes callback
    delete _poolCallbacks[msg.sender];

    emit CallbackCancelled(msg.sender);
    return true;
  }

  /// @inheritdoc IPool
  function requestRoll() external override onlyBorrower nonDefaulted nonClosed {
    /// @dev Roll should not be requested
    require(!isRollRequested, 'RAR');

    /// @dev Roll can be requested only if there is one active lender and no active callbacks
    require(_activeLendersCount == 1, 'RCR');

    /// @dev New roll can be activated only after deposit window until 48 hours before the maturity date
    require(
      block.timestamp > depositMaturity &&
        block.timestamp > _poolRolls[activeRollId].startDate &&
        block.timestamp < maturityDate - 2 days,
      'RTR'
    );

    isRollRequested = true;

    emit RollRequested(_nextRollId);
  }

  /// @inheritdoc IPool
  function acceptRoll() external override onlyPrime nonClosed nonDefaulted {
    /// @notice check if the roll was requested
    require(isRollRequested, 'ARM');

    /// @dev Lender can accept roll only before it starts
    require(block.timestamp < maturityDate, 'RTR');

    Member storage member = poolMembers[msg.sender];

    /// @dev Should be an authorized lender
    require(member.principal != 0, 'IMB');

    isRollRequested = false; // renew request status

    /// @dev Get the current roll id
    uint256 currentRollId = _nextRollId;

    /// @dev Increment the rolls counter
    ++_nextRollId;

    /// @dev Update the roll id tracker
    activeRollId = currentRollId;

    /// @dev Save the new roll as Roll struct
    _poolRolls[currentRollId] = Roll(maturityDate, maturityDate + tenor);

    /// @dev Prolongate the maturity date
    maturityDate += tenor;

    member.totalInterest += (member.principal * _annualRate(rateMantissa, tenor)) / 1e18;

    emit RollAccepted(currentRollId, maturityDate);
  }

  /// @inheritdoc IPool
  function markPoolDefaulted() external nonClosed nonDefaulted {
    /// @dev Governor is able to mark pool as defaulted through the Factory
    if (msg.sender != address(factory)) {
      /// @dev Lender or the borrower with loan can mark pool as defaulted
      _isPrimeMember(msg.sender);

      if (msg.sender != borrower) {
        /// @dev Lender should have principal
        require(poolMembers[msg.sender].principal != 0, 'IMB');
      }

      require(canBeDefaulted(), 'EDR');
    }

    /// @dev Set the pool default timestamp
    defaultedAt = block.timestamp;

    emit Defaulted();
  }

  /// @inheritdoc IPool
  function close() external override onlyBorrower nonClosed returns (bool success) {
    /// @dev The pool can be closed only if it's size is 0
    require(currentSize == 0, 'OHD');
    _close();
    return true;
  }

  /// @inheritdoc IPool
  function totalDue() external view override returns (uint256 totalDueAmount) {
    /// @dev Gas optimization
    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      (uint256 due, uint256 spreadFee, uint256 originationFee) = dueOf(_lenders[i]);
      totalDueAmount += due + spreadFee + originationFee;
    }
  }

  /// @inheritdoc IPool
  function dueOf(
    address lender
  ) public view override returns (uint256 due, uint256 spreadFee, uint256 originationFee) {
    /// @dev Gas saving link to lender's member struct
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, due is zero too
    if (member.principal == 0) {
      return (0, 0, 0);
    }

    (due, spreadFee, originationFee) = _dueOf(lender);
    due += member.principal;
  }

  /// @inheritdoc IPool
  function totalDueInterest() external view override returns (uint256 totalInterest) {
    /// @dev Gas optimization
    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      /// @dev Lenders address from the array
      address lender = _lenders[i];
      (uint256 interest, uint256 spreadAmount) = dueInterestOf(lender);
      totalInterest += interest + spreadAmount;
    }
  }

  /// @inheritdoc IPool
  function dueInterestOf(
    address lender
  ) public view override returns (uint256 due, uint256 spreadFee) {
    /// @dev Gas saving link to lender's member struct
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, interest is zero too
    if (member.principal == 0) {
      return (0, 0);
    }

    if (isBulletLoan) {
      (due, spreadFee, ) = _dueOf(lender);
    } else {
      uint256 timestamp = getNextPaymentTimestamp();
      uint256 endDate = block.timestamp > timestamp ? block.timestamp : timestamp;
      (due, spreadFee) = _dueInterestAtTime(lender, endDate);
      due += _penaltyOf(lender);
    }
  }

  /// @inheritdoc IPool
  function balanceOf(address lender) external view override returns (uint256 balance) {
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, balance is zero too
    if (member.principal == 0) {
      return 0;
    }

    balance = member.principal;
    uint256 positionsLength = _lenderPositions[lender].length;
    for (uint256 i = 0; i < positionsLength; ++i) {
      Position memory position = _lenderPositions[lender][i];
      balance +=
        (position.interest * (block.timestamp - position.startAt)) /
        (maturityDate - position.startAt);
    }
  }

  /// @inheritdoc IPool
  function penaltyOf(address lender) public view override returns (uint256 penalty) {
    /// @dev In common case, penalty starts from maturity date in case of bullet loan
    /// @dev or from the last paid timestamp in case of monthly loan
    return _penaltyOf(lender);
  }

  /// @inheritdoc IPool
  function getNextPaymentTimestamp() public view returns (uint256 payableToTimestamp) {
    /// @dev Initial timestamp is the last paid timestamp
    payableToTimestamp = lastPaidTimestamp;

    /// @dev If pool is active and last month is paid, next month is payable
    if (payableToTimestamp != 0 && payableToTimestamp < block.timestamp + 30 days) {
      payableToTimestamp += 30 days;

      if (payableToTimestamp > maturityDate) {
        payableToTimestamp = maturityDate;
      }
    }
    return payableToTimestamp;
  }

  /// @inheritdoc IPool
  function canBeDefaulted() public view virtual override returns (bool isAbleToDefault) {
    /// @dev Pool can be marked as defaulted only if it is not defaulted already and has lenders
    if (defaultedAt != 0 || _activeLendersCount == 0) {
      return false;
    }

    if (isBulletLoan) {
      /// @dev Pool can be marked as defaulted by lender only after (72 hours + maturity date) in case of bullet loan
      return block.timestamp > maturityDate + 3 days;
    } else {
      /// @dev Otherwise, pool can be marked as defaulted by lender only after 33 days since last payment
      return block.timestamp > lastPaidTimestamp + 33 days;
    }
  }

  /**
   * @notice Calculates the penalty rate for a given interval
   * @param interval The interval in seconds
   * @return The penalty rate as a mantissa between [0, 1e18]
   */
  function penaltyRate(uint256 interval) public view returns (uint256) {
    return (penaltyRatePerYear * interval) / YEAR;
  }

  /// @notice Returns Prime address
  /// @dev Prime converted as IPrime interface
  /// @return primeInstance - Prime address
  function prime() public view returns (IPrime primeInstance) {
    /// @dev Factory should keep actual link to Prime
    return factory.prime();
  }

  /// @notice Parses the members encoded in bytes and calls _parseLender() for each member
  /// @dev Internal function
  /// @param isWhitelistOperation - True if the operation is a whitelist operation
  /// @param members - The encoded members bytes
  function _parseLenders(bool isWhitelistOperation, bytes calldata members) internal {
    if (members.length == 20) {
      _parseLender(isWhitelistOperation, AddressCoder.decodeAddress(members)[0]);
    } else {
      address[] memory addresses = AddressCoder.decodeAddress(members);
      uint256 length = addresses.length;

      require(length <= 60, 'EAL');

      for (uint256 i = 0; i < length; i++) {
        _parseLender(isWhitelistOperation, addresses[i]);
      }
    }
  }

  /// @notice Creates lender if not exists and updates the whitelist status
  /// @dev Internal function
  /// @param isWhitelistOperation - True if the operation is a whitelist operation
  /// @param member - The address of the lender
  function _parseLender(bool isWhitelistOperation, address member) internal {
    _isPrimeMember(member);

    /// @dev Gas saving link to lender's member struct
    Member storage memberStruct = poolMembers[member];

    /// @dev Whitelist Lender
    if (isWhitelistOperation) {
      /// @dev Creates member if not exists
      if (!memberStruct.isCreated) {
        _initLender(member, true);
      } else {
        /// @dev Whitelists member if it is not whitelisted
        memberStruct.isWhitelisted = true;
      }

      emit LenderWhitelisted(member);
    } else {
      /// @dev If we blacklist a lender, it should exist
      require(memberStruct.isCreated, 'IMB');

      memberStruct.isWhitelisted = false;

      emit LenderBlacklisted(member);
    }
  }

  /// @dev Creates lender if not exists and updates the whitelist status
  /// @param member - The address of the lender
  /// @param isWhitelistOperation - True if the operation is a whitelist operation
  function _initLender(address member, bool isWhitelistOperation) internal {
    /// @dev Creates lender if not exists
    if (!poolMembers[member].isCreated) {
      /// @dev Borrower cannot be a lender
      require(borrower != member, 'BLS');
      /// @dev Init struct for lender's data
      poolMembers[member] = Member(true, isWhitelistOperation, 0, 0, 0, 0);
      _lenders.push(member);
    }
  }

  /// @notice Lends funds to the pool
  /// @dev Internal function
  /// @param amount - Amount of funds to lend
  /// @param lender - Lender address
  /// @return success - True if the funds are lent
  function _lend(uint256 amount, address lender) internal returns (bool success) {
    /// @dev New size of the pool shouldn't be greater than max allowed size
    require(currentSize + amount <= maxSize, 'OSE');

    /// @dev Gas saving link to lender's member struct
    Member storage member = poolMembers[lender];

    /// @dev If roll is public, we should create it's data structure
    if (isPublic) {
      _initLender(lender, true);
    } else {
      /// @dev If roll is private, lender should be whitelisted
      require(member.isWhitelisted, 'IMB');
    }

    /// @dev If depositMaturity is zero, it means that the pool is not activated yet
    if (depositMaturity == 0) {
      /// @dev Set depositMaturity and maturityDate
      depositMaturity = block.timestamp + depositWindow;
      maturityDate = block.timestamp + tenor;

      if (!isBulletLoan) {
        lastPaidTimestamp = block.timestamp;
      }
      emit Activated(depositMaturity, maturityDate);
    } else {
      require(block.timestamp <= depositMaturity, 'DWC');
    }
    /// @dev Increase pool size, lender's deposit and active lenders count
    currentSize += amount;

    if (member.principal == 0) {
      ++_activeLendersCount;
      member.accrualTs = block.timestamp;
    }
    uint256 timeInTenor = maturityDate - block.timestamp;

    _lenderPositions[lender].push(
      Position({
        interest: (amount * _annualRate(rateMantissa, timeInTenor)) / 1e18,
        startAt: block.timestamp
      })
    );

    member.totalInterest += (amount * _annualRate(rateMantissa, timeInTenor)) / 1e18;
    member.totalOriginationFee += (amount * _annualRate(originationRate, timeInTenor)) / 1e18;

    /// @dev Update lender's member struct
    member.principal += amount;

    emit Lent(lender, amount);

    _safeTransferFrom(asset, lender, borrower, amount);
    return true;
  }

  /// @notice Repays all the funds to the lender and Pool.
  /// @dev Internal function
  /// @param lender - Lender address
  /// @return success - True if the lender is repaid
  function _repayTo(address lender) internal returns (bool success) {
    /// @dev Member struct link
    Member storage member = poolMembers[lender];

    /// @dev Short circuit for non lenders
    if (member.principal == 0) {
      return true;
    }

    /// @dev Calculate the amount of funds to repay
    (uint256 memberDueAmount, uint256 spreadFee, uint256 originationFee) = dueOf(lender);

    /// @dev Cleanup lender callbacks
    if (_poolCallbacks[lender].isCreated) {
      _poolCallbacks[lender].isCreated = false;
    }

    /// @dev Cleanup lender roll
    if (activeRollId != 0) {
      activeRollId = 0;
    }

    /// @dev Emit repay event before potential pool closure
    emit Repayed(lender, memberDueAmount, spreadFee, originationFee);

    /// @dev Cleanup related data
    currentSize -= member.principal;
    member.totalInterest = 0;
    member.totalOriginationFee = 0;
    member.principal = 0;
    member.accrualTs = block.timestamp;
    --_activeLendersCount;

    /// @dev Remove all lender positions
    delete _lenderPositions[lender];

    /// @dev Close pool if it is empty and deposit window is over
    if (currentSize == 0 && depositMaturity <= block.timestamp) {
      _close();
    }

    uint256 totalFees = spreadFee + originationFee;

    /// @dev Treasury is always not zero address. Pay protocol fees if any
    if (totalFees != 0) {
      _safeTransferFrom(asset, msg.sender, prime().treasury(), totalFees);
    }
    _safeTransferFrom(asset, msg.sender, lender, memberDueAmount);
    return true;
  }

  /// @dev Repays the interest to all lenders
  function _repayInterest() internal {
    /// @dev Get next payment timestamp
    uint256 newPaidTimestamp = getNextPaymentTimestamp();

    uint256 lendersLength = _lenders.length;
    for (uint256 i = 0; i < lendersLength; ++i) {
      /// @dev Iterate over all lenders and repay interest to each of them
      _repayInterestTo(_lenders[i], newPaidTimestamp);
    }
    lastPaidTimestamp = newPaidTimestamp;
  }

  /// @dev Repays the interest to the lender
  function _repayInterestTo(address lender, uint256 lastPaidTs) internal {
    /// @dev Member struct link
    Member storage member = poolMembers[lender];

    /// @dev Do not repay interest to non lenders or if already paid
    if (member.principal == 0) {
      return;
    }

    (uint256 interest, uint spreadFee) = dueInterestOf(lender);

    /// @dev Substract borrow interest from total interest
    member.totalInterest -=
      (member.totalInterest * (lastPaidTs - member.accrualTs)) /
      (maturityDate - member.accrualTs);
    member.accrualTs = lastPaidTs;
    emit RepayedInterest(lender, interest, spreadFee);

    /// @dev Repay fees if any
    if (spreadFee != 0) {
      _safeTransferFrom(asset, msg.sender, prime().treasury(), spreadFee);
    }
    /// @dev Repay interest and penalty if any.
    /// @dev interest == 0 is not possible because of the check above for member.accrualTs
    _safeTransferFrom(asset, msg.sender, lender, interest);
  }

  /// @dev Rejects the roll
  function _rejectRoll() internal {
    isRollRequested = false;
    emit RollRejected(_nextRollId, msg.sender);
  }

  /// @dev Closes the pool
  function _close() internal {
    isClosed = true;
    emit Closed();
  }

  function _getOriginationFee(address lender) internal view returns (uint256 originationFee) {
    if (originationRate == 0) {
      return 0;
    }

    /// @dev Member struct link
    Member storage member = poolMembers[lender];

    originationFee = member.totalOriginationFee;

    /// @dev Initial maturity date equals to [depositMaturity - depositWindow + tenor].
    if (
      _poolCallbacks[lender].isCreated && block.timestamp < depositMaturity - depositWindow + tenor
    ) {
      /// @dev If lender hasn't created callback, and borrower repays the loan before the maturity date,
      /// @dev not all origination fee is used.
      uint256 unusedTime = maturityDate - block.timestamp;

      originationFee -= (member.principal * (_annualRate(originationRate, unusedTime))) / 1e18;
    }

    /// @dev If there was a roll and increment per roll is not zero, adjust origination fee
    if (_nextRollId != 1 && incrementPerRoll != 0) {
      /// @dev originationFeeAmount is applied only on the original tenure set on the pool,
      /// @dev and an additional X% annualized added to the originationFeeAmount for every roll.
      uint256 fullOriginationFeePerRoll = (((member.principal *
        _annualRate(originationRate, tenor)) / 1e18) * incrementPerRoll) / 1e18;

      if (
        _poolCallbacks[lender].isCreated &&
        block.timestamp > _poolRolls[1].startDate &&
        block.timestamp < maturityDate
      ) {
        /// @dev If Callback been requested, origination fee is calculated from the start of the roll
        /// @dev [times of tenor passed from maturity date] == (daysPassed) / tenor
        /// @dev Summ origination fee with rolling origination fee
        originationFee +=
          (fullOriginationFeePerRoll * (block.timestamp - _poolRolls[1].startDate)) /
          tenor;
      } else {
        originationFee += (fullOriginationFeePerRoll * (_nextRollId - 1));
      }
    }
  }

  function _dueOf(
    address lender
  ) internal view returns (uint256 due, uint256 spreadFee, uint256 originationFee) {
    uint256 currentTs = block.timestamp;
    if (currentTs < maturityDate && !_poolCallbacks[lender].isCreated) {
      currentTs = maturityDate;
    }
    (due, spreadFee) = _dueInterestAtTime(lender, currentTs);

    /// @dev Due calculation. due == interest + penalty - spreadFee
    due += _penaltyOf(lender);
    originationFee = _getOriginationFee(lender);
  }

  /// @dev Calculates the annual rate for a given interest rate and specific interval
  /// @param _rateMantissa The interest rate as a mantissa between [0, 1e18]
  /// @param _timeDelta The interval in seconds
  /// @return rate as a mantissa between [0, 1e18]
  function _annualRate(uint256 _rateMantissa, uint256 _timeDelta) internal pure returns (uint256) {
    return (_rateMantissa * _timeDelta) / YEAR;
  }

  /// @dev Checks if the address is a prime member
  /// @param _member - The address of the member
  function _isPrimeMember(address _member) internal view {
    require(prime().isMember(_member), 'NPM');
  }

  /// @dev Calculates the interest for the lender
  /// @param lender - The address of the lender
  /// @param timestamp - The timestamp to which the interest is calculated
  /// @return interest - The interest amount for given timestamp (spread is substracted)
  /// @return spreadAmount - The spread amount
  function _dueInterestAtTime(
    address lender,
    uint256 timestamp
  ) internal view returns (uint256 interest, uint256 spreadAmount) {
    /// @dev Link to member's data struct
    Member storage member = poolMembers[lender];

    /// @dev If principal is zero, due is zero too
    if (member.principal == 0) {
      return (0, 0);
    }

    interest =
      (member.totalInterest * (timestamp - member.accrualTs)) /
      (maturityDate - member.accrualTs);
    spreadAmount = (interest * spreadRate) / 1e18;
    interest -= spreadAmount;
  }

  /// @dev Calculates penalty fee for the lender
  /// @param lender - The address of the lender
  function _penaltyOf(address lender) internal view returns (uint256) {
    /// @dev Link to member's data struct
    Member storage member = poolMembers[lender];
    /// @dev If principal is zero, no penalty fee is charged.
    /// @dev If monthly loan penalty fee does not charged if it is a first on time payment.
    if (member.principal == 0) {
      return 0;
    }

    /// @dev Penalty fee is charged from the next month after the last payment in case of monthly loan,
    /// @dev and from the maturity in case of bullet loan.
    uint256 startingDate = isBulletLoan ? maturityDate : member.accrualTs + 30 days;

    /// @dev Adjust starting date if it is greater than maturity date
    if (!isBulletLoan && startingDate > maturityDate) {
      startingDate = maturityDate;
    }

    /// @dev In common case, penalty fee is calculated to the current time
    uint256 endingDate = block.timestamp;

    if (defaultedAt != 0) {
      /// @dev If pool is defaulted, penalty fee is calculated to the default date
      endingDate = defaultedAt;
    }

    /// @dev Calculate overdue amounts only if pool is overdue or defaulted
    if (endingDate > startingDate) {
      uint256 penaltyRateMantissa = penaltyRate(endingDate - startingDate);

      /// @dev If penalty rate is zero, no penalty fee is charged
      if (penaltyRateMantissa == 0) {
        return 0;
      }

      /// @dev Penalty fee == (penaltyRateForTime * principal)
      /// @dev function callable only if principal is not zero
      return (penaltyRateMantissa * member.principal) / 1e18;
    } else {
      /// @dev Else return zero
      return 0;
    }
  }

  function _safeTransferFrom(
    address token,
    address sender,
    address receiver,
    uint256 amount
  ) internal {
    return IERC20Upgradeable(token).safeTransferFrom(sender, receiver, amount);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 * @title Interface of the Prime membership contract
 */
interface IPrime {
  /// @notice Member status enum
  enum MemberStatus {
    PENDING,
    WHITELISTED,
    BLACKLISTED
  }

  /// @notice A record of member info
  struct Member {
    uint256 riskScore;
    MemberStatus status;
    bool created;
  }

  /**
   * @notice Check membership status for a given `_member`
   * @param _member The address of member
   * @return Boolean flag containing membership status
   */
  function isMember(address _member) external view returns (bool);

  /**
   * @notice Check Stablecoin existence for a given `asset` address
   * @param asset The address of asset
   * @return Boolean flag containing asset availability
   */
  function isAssetAvailable(address asset) external view returns (bool);

  /**
   * @notice Get membership info for a given `_member`
   * @param _member The address of member
   * @return The member info struct
   */
  function membershipOf(address _member) external view returns (Member memory);

  /**
   * @notice Returns current protocol rate value
   * @return The protocol rate as a mantissa between [0, 1e18]
   */
  function spreadRate() external view returns (uint256);

  /**
   * @notice Returns current originated fee value
   * @return originated fee rate as a mantissa between [0, 1e18]
   */
  function originationRate() external view returns (uint256);

  /**
   * @notice Returns current rolling increment fee
   * @return rolling fee rate as a mantissa between [0, 1e18]
   */
  function incrementPerRoll() external view returns (uint256);

  /**
   * @notice Returns current protocol fee collector address
   * @return address of protocol fee collector
   */
  function treasury() external view returns (address);

  /**
   * @notice Returns current penalty rate for 1 year
   * @return penalty fee rate as a mantissa between [0, 1e18]
   */
  function penaltyRatePerYear() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library AddressCoder {
  function encodeAddress(address[] calldata addresses) internal pure returns (bytes memory data) {
    for (uint256 i = 0; i < addresses.length; i++) {
      data = abi.encodePacked(data, addresses[i]);
    }
  }

  function decodeAddress(bytes calldata data) internal pure returns (address[] memory addresses) {
    uint256 n = data.length / 20;
    addresses = new address[](n);

    for (uint256 i = 0; i < n; i++) {
      addresses[i] = bytesToAddress(data[i * 20:(i + 1) * 20]);
    }
  }

  function bytesToAddress(bytes calldata data) private pure returns (address addr) {
    bytes memory b = data;
    assembly {
      addr := mload(add(b, 20))
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/// @title NZAGuard contract contains modifiers to check inputs for non-zero address, non-zero value, non-same address, non-same value, and non-more-than-one
abstract contract NZAGuard {
  modifier nonZeroAddress(address _address) {
    require(_address != address(0), 'NZA');
    _;
  }
  modifier nonZeroValue(uint256 _value) {
    require(_value != 0, 'ZVL');
    _;
  }
  modifier nonSameValue(uint256 _value1, uint256 _value2) {
    require(_value1 != _value2, 'SVR');
    _;
  }
  modifier nonSameAddress(address _address1, address _address2) {
    require(_address1 != _address2, 'SVA');
    _;
  }
  modifier nonMoreThenOne(uint256 _value) {
    require(_value <= 1e18, 'UTR');
    _;
  }
}