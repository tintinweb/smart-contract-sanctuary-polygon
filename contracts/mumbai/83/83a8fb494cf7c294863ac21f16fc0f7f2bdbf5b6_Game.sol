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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
pragma experimental ABIEncoderV2;

interface IAffiliate {
    event Clicked(address endUser, address publisher);
    event RewardUpdated(address publisher, address endUser, uint256 amountBefore, uint256 amountAfter);
    event Claimed(address publisher, uint256 amount);

    function getClicked(address endUser) external view returns (address);
    function getRate() external view returns (uint256);
    function getWhitelistRate() external view returns (uint256);
    function isWhitelist(address account) external view returns (bool);
    function isTransferMissile(address account) external view returns (bool);
    function updateReward(address endUser, uint256 amount) external;
    function click(address endUser, address publisher) external;
    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
 
 interface IGame {
    struct FreeEvent {
        uint32 typeMissileFree;
        uint32 amountFree; 
        uint96 startTime;
        uint96 endTime;
        uint8 freeObject; // only whitelist = 0; only new players = 1; whitelist and new players = 2; not only new player but also whitelist = 3; for all players = 4
        uint24 freeEventId;
        uint112 totalFree;
        uint112 amountFreeUsed;
    }

    struct Blacklist {
        address account;
        uint128 limitSpend;
        uint128 spent;
        uint32 limitNumber;
        uint32 numberUsed;
        uint96 lastestUpdateNumber;
        uint96 lastestUpdateSpend;
    }

    struct UseCache {
        uint256 amountUserUsed;
        uint256 amountUsed;
    }

    struct LastestRequest {
        uint256 requestId;
        uint256 price;
    }

    event TypeMissileAdded(uint256[] typeMissile, uint256[] value);
    event MissileArranged(address account, uint256[12] missilePositions);
    event Shot(
        uint256 playNumber,
        address account, 
        uint256 reward, 
        uint256[12] positions, 
        uint256[12] mapPosistion, 
        uint256 goldBoatPosition, 
        uint256 ghostBoatPosition, 
        uint256 price,
        uint256 boatShot
    );
    event FreeStarted(
        uint256 index,
        uint256 typeMissileFree_, 
        uint256 amount_,
        uint256 startTime_,
        uint256 endTime_, 
        uint256 totalFree_,
        uint256 object_,
        uint256 freeEventId_
    );
    event FreeEnded(uint256 eventId);
    event RewardStarted(uint256 startTime, uint256 endTime, uint256 object, uint256 multiplier);
    event RewardEnded();

    function getMissile(address account) external view returns (uint256[12] memory);

    function getWhitelistLength() external view returns (uint256);

    function getWhitelistFreeLength(uint256 freeEventId_) external view returns (uint256);

    function getFreeEventLength() external view returns (uint256);

    function currentDay() external view returns (uint256);

    function canShoot(address account) external view returns (bool, uint256);

    function getAvailableMissile() external view returns (uint256[] memory, uint256[] memory);

    function arrangeMissile(uint256[12] memory positions) external;

    function shoot() external;

    function calPrice(uint256[12] memory positions, address account) external view returns (uint256 price, uint256[] memory, UseCache[] memory, uint256[] memory, uint256);

    function getEventPerAccount(address account) external view returns (uint256[] memory, bool, bool);

    function getFreeMissilePerAccount(address account) external view returns (uint256[] memory);

    function calPosition(uint256 randomNumber, address account) external view returns (uint256[12] memory map, uint256 firstPosition, uint256 secondPosition, uint256 finalReward, uint256 boatShot);
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
 
 interface IRandom {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    function requestRandomWords() external returns (uint256 requestId);
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256 randomWords);
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CoreUtility {
    function _calDay(uint256 time, uint256 LAUNCH_TIME) internal pure returns (uint256) {
        return ((time - LAUNCH_TIME) / 1 days);
    }

    function _calRandom(
        uint256 randomNumber, 
        uint256 ghostRate,
        uint256 goldRate,
        uint256 playNumbers
    ) internal pure returns (uint256[12] memory map, uint256 firstPosition, uint256 secondPosition) {
        uint256 ghostBoatNumber = ((randomNumber / 1000000 ** 7) % 1000000) % (ghostRate);
        uint256 goldBoatNumber = ((randomNumber / 1000000 ** 8) % 1000000) % (goldRate);       
        uint256 loopNumber = 6;
        uint256 temp = randomNumber % 1000000;
        firstPosition = temp % 12;
        map[firstPosition] += 1; 
        if (playNumbers % goldRate != goldBoatNumber) {
            firstPosition = 12;
        }
        temp = (randomNumber / (1000000 ** 1)) % 1000000;
        secondPosition = temp % 12;
        map[secondPosition] += 1;
        if (playNumbers % ghostRate != ghostBoatNumber) {
            secondPosition = 12;
        } else {
            loopNumber = 7;
        }
        for (uint256 i = 2; i< loopNumber; i++) {
            temp = (randomNumber / (1000000 ** i)) % 1000000;
            map[temp % 12] += 1;
        }
    }

    function check(uint256 object, uint256 id, bool newPlayer) internal pure returns (bool) {
        return object == 4 || 
                (object == 0 && id != 0) || 
                (object == 2 && (id != 0 || newPlayer)) ||
                (object == 1 && newPlayer) ||
                (object == 3 && id != 0 && newPlayer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./../library/SafeToken.sol"; 
import "./../library/CoreUtility.sol";
import "./../interfaces/IAffiliate.sol";
import "./../interfaces/IRandom.sol";
import "./../interfaces/IGameSpepe.sol";

contract Game is IGame, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeToken for address;
    //start at 0
    uint256 public playNumbers;
    IAffiliate public affiliate;
    IRandom public random;
    IERC20Upgradeable public token;
    address public treasury;
    address public operator;
    uint256 public cost;
    uint256 public reward;
    uint256 public countTypeMissile;
    uint256 public countEventFree;
    uint256 public goldRate;
    uint256 public ghostRate;
    uint256 public minimumAmount;
    uint256 public goldReward;
    uint256 public LAUNCH_TIME;
    uint256 public typeFreeAffiliate;
    uint256 public numberFreeAffilate;

    uint256 public startTimeEvent;
    uint256 public endTimeEvent;
    uint256 public objectEvent;
    uint256 public multiplier;

    address[] public whitelist;
    mapping (address => uint256) public whitelistIds;
    
    mapping (uint256 => address[]) public whitelistFree;
    mapping (address => mapping(uint256 => uint256)) public whitelistFreeIds;
    mapping (address => mapping(uint256 => uint256)) public freeMissileUsed;
    mapping (address => mapping(uint256 => uint256)) public freeAffiliate;

    Blacklist[] public blacklistInfos;
    FreeEvent[] public freeEventInfos;

    mapping (uint256 => uint256[12]) private missilePositions;
    mapping (address => LastestRequest) private userRequests;
    mapping (uint256 => bool) public requestIdUsed;
    //start at 1
    mapping (uint256 => uint256) public missileValues;
    mapping (address => uint256) public blacklistIds;

    function initialize(
        address token_,
        uint256 cost_, 
        uint256 reward_, 
        address affiliate_, 
        address random_, 
        address treasury_, 
        uint256 launchTime_
    ) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
        token = IERC20Upgradeable(token_);
        cost = cost_;
        reward = reward_;
        affiliate = IAffiliate(affiliate_);
        random = IRandom(random_);
        treasury = treasury_;
        operator = treasury_;
        LAUNCH_TIME = launchTime_;
        goldRate = 10;
        ghostRate = 20;
        goldReward = 2;
        blacklistInfos.push(Blacklist({
            account: address(0),
            limitSpend: 0,
            spent: 0,
            limitNumber: 0,
            numberUsed: 0,
            lastestUpdateNumber: 0,
            lastestUpdateSpend:0
        })); 
        whitelist.push(address(0));
    }

    function getMissile(address account) external override view returns (uint256[12] memory) {
        return missilePositions[userRequests[account].requestId];
    }

    function getWhitelistLength() external override view returns (uint256) {
        return whitelist.length;
    }

    function getWhitelistFreeLength(uint256 freeEventId_) external override view returns (uint256) {
        return whitelistFree[freeEventId_].length;
    }

    function getFreeEventLength() external override view returns (uint256) {
        return freeEventInfos.length;
    } 

    function currentDay() external override view returns (uint256) {
        return CoreUtility._calDay(block.timestamp, LAUNCH_TIME);
    }

    function nonZero(uint256[12] memory positions) private view {
        uint256 valuePosition;
        bool invalid;
        for (uint256 i = 0; i < 12; i++) {
            if (missileValues[positions[i]] == 0 && positions[i] != 0) {
                invalid = true;
            }
            valuePosition += positions[i];
        }
        require(valuePosition > 0 && !invalid, "ind");
    }

    function canShoot(address account) public override view returns (bool, uint256) {
        LastestRequest memory request = userRequests[account];
        if (requestIdUsed[request.requestId] || request.requestId == 0) {
            return (false, 0);
        } else {
            (bool fulfilled, uint256 randomNumber) = random.getRequestStatus(request.requestId);
            return (fulfilled, randomNumber);
        }
    }

    function getAvailableMissile() external override view returns (uint256[] memory, uint256[] memory) {
        uint256 count;
        uint256[] memory temp = new uint256[](countTypeMissile);
        for(uint256 i = 0; i < countTypeMissile; i++) {
            if (missileValues[i + 1] != 0) {
                temp[i] = countTypeMissile;
                count += 1;
            }
        }
        uint256[] memory available = new uint256[](count);
        uint256[] memory availableValue = new uint256[](count);
        uint256 id;
        for(uint256 i = 0; i < countTypeMissile; i++) {
            if (temp[i] == countTypeMissile) {
                available[id] = i + 1; 
                availableValue[id] = missileValues[i + 1];
                id += 1;
            }
        } 
        return (available, availableValue);
    }

    function addTypeMissile(uint256[] memory missileValues_) public onlyOwner {
        uint256[] memory typeMissile_ = new uint256[](missileValues_.length);
        for (uint256 i = 0; i < missileValues_.length; i++) {
            missileValues[countTypeMissile + 1] = missileValues_[i];
            typeMissile_[i] = countTypeMissile + 1;
            countTypeMissile += 1;
        }
        emit TypeMissileAdded(typeMissile_, missileValues_);
    }

    function deleteTypeMissile(uint256 typeMissile) public onlyOwner {
        require(typeMissile <= countTypeMissile && typeMissile != 0, "ind");
        missileValues[typeMissile] = 0;
    }

    function arrangeMissile(uint256[12] memory positions) external override nonReentrant whenNotPaused {
        nonZero(positions);
        (uint256 price, uint256[] memory events, UseCache[] memory useCache, uint256[] memory amountAff, uint256 amountToMinimum) = calPrice(positions, msg.sender);
        require(amountToMinimum == 0, "minimum");
        require(token.balanceOf(msg.sender) >= price, "not enough");
        token.transferFrom(msg.sender, treasury, price);
        uint256 requestId = random.requestRandomWords();
        for (uint256 i = 0; i < events.length; i++) {
            if (useCache[i].amountUserUsed != freeMissileUsed[msg.sender][uint256(freeEventInfos[events[i]].freeEventId)] && 
                useCache[i].amountUsed != uint256(freeEventInfos[events[i]].amountFreeUsed)
            ) {
                freeMissileUsed[msg.sender][uint256(freeEventInfos[events[i]].freeEventId)] = useCache[i].amountUserUsed;
                freeEventInfos[events[i]].amountFreeUsed = uint112(useCache[i].amountUsed);
            }
        }
       for (uint256 i = 1; i < countTypeMissile + 1; i++) {
            if (amountAff[i] > 0) {
                freeAffiliate[msg.sender][i] -= amountAff[i];
            }
        }
        address endUser = msg.sender;
        if (affiliate.isTransferMissile(endUser)) {
            freeAffiliate[affiliate.getClicked(endUser)][typeFreeAffiliate] += numberFreeAffilate;
        }
        affiliate.updateReward(msg.sender, price);
        LastestRequest memory req = LastestRequest({
            requestId: requestId,
            price: price
        });
        userRequests[msg.sender] = req;
        missilePositions[requestId] = positions;
        emit MissileArranged(msg.sender, positions);
    } 

    function shoot() external override nonReentrant whenNotPaused {
        (bool access, uint256 randomNumber) = canShoot(msg.sender);
        require(access, "unavail");
        LastestRequest memory request = userRequests[msg.sender];
        requestIdUsed[request.requestId] = true;
        uint256[12] memory positions = missilePositions[request.requestId];          
        (uint256[12] memory boatPosition, uint256 firstPosition, uint256 secondPosition, uint256 finalReward, uint256 boatShot) = calPosition(randomNumber, msg.sender);
        playNumbers += 1;
        SafeToken.safeTransfer(address(token), msg.sender, finalReward);
        uint256 price = request.price;
        emit Shot(playNumbers - 1, msg.sender, finalReward, positions, boatPosition, firstPosition, secondPosition, price, boatShot);
    }

    function rewardMul(uint256 reward_, address account_) internal view returns (uint256, bool) {
        bool newPlayer = userRequests[account_].requestId == 0 && affiliate.getClicked(account_) == address(0);
        bool condition = CoreUtility.check(objectEvent, whitelistIds[account_], newPlayer);
        if (block.timestamp >= startTimeEvent && block.timestamp < endTimeEvent && condition) {
            return (reward_ * multiplier, true);
        }
        return (reward_, false);
    }

    function calPrice(
        uint256[12] memory positions, 
        address account
    ) public override view returns (uint256 price, uint256[] memory, UseCache[] memory, uint256[] memory, uint256) {
        uint256 value;
        (uint256[] memory events,,) = getEventPerAccount(account);
        UseCache[] memory useCache = new UseCache[](events.length);
        uint256[] memory amountAff = new uint256[](countTypeMissile + 1);
        for (uint256 i = 0; i < events.length; i++) {
            useCache[i].amountUserUsed = freeMissileUsed[account][uint256(freeEventInfos[events[i]].freeEventId)];
            useCache[i].amountUsed = uint256(freeEventInfos[events[i]].amountFreeUsed);
        }
        for (uint256 i = 0; i < 12; i++) {
            bool free;
            for (uint256 j = 0; j < events.length; j++) {
                if (positions[i] == freeEventInfos[events[j]].typeMissileFree && 
                    useCache[j].amountUserUsed < freeEventInfos[events[j]].amountFree && 
                    useCache[j].amountUsed < freeEventInfos[events[j]].totalFree
                ) {
                    useCache[j].amountUserUsed += 1;
                    useCache[j].amountUsed += 1;
                    free = true;
                    break;
                }
            }
            if (!free) {
                if (missileValues[positions[i]] != 0 && freeAffiliate[account][positions[i]] > amountAff[positions[i]]) {
                    amountAff[positions[i]] += 1;
                } else {
                    value += missileValues[positions[i]];
                }
            }
        }
        price = value * cost;
        if (price >= minimumAmount) {
            return (price, events, useCache, amountAff, 0);
        }    
        return (price, events, useCache, amountAff, minimumAmount - price);
    }

    function getEventPerAccount(address account) public override view returns (uint256[] memory, bool, bool) {
        uint256 infoLength = freeEventInfos.length;
        uint256[] memory temp = new uint256[](infoLength);
        uint256 lengthEvent;
        bool affi = affiliate.getClicked(account) == address(0);
        bool newPlayer = userRequests[account].requestId == 0 && affi;
        for (uint256 i = 0; i < infoLength; i++) {
            uint256 freeEventId_ = freeEventInfos[i].freeEventId;
            bool condition = CoreUtility.check(freeEventInfos[i].freeObject, whitelistFreeIds[account][freeEventId_], newPlayer);
            if(block.timestamp >= freeEventInfos[i].startTime && 
                block.timestamp < freeEventInfos[i].endTime && 
                condition && missileValues[freeEventInfos[i].typeMissileFree] != 0
            ) {
                temp[i] = infoLength;
                lengthEvent += 1;
            }
        }
        uint256[] memory eventId = new uint256[](lengthEvent);
        uint256 id;
        for (uint256 i = 0; i < infoLength; i++) {
            if (temp[i] == infoLength) {
                eventId[id] = i;
                id += 1;
            }
        }
        (, bool eventReward) =  rewardMul(0, account);
        return (eventId, eventReward, affi);
    }

    function getFreeMissilePerAccount(address account) external override view returns (uint256[] memory) {
        (uint256[] memory events,,) = getEventPerAccount(account);
        uint256[] memory amountFree = new uint256[](countTypeMissile + 1);
        for (uint256 i = 0; i < events.length; i++) {
            FreeEvent memory eventFree = freeEventInfos[events[i]];
            amountFree[eventFree.typeMissileFree] += eventFree.amountFree - freeMissileUsed[account][eventFree.freeEventId];
        }
        for (uint256 i = 0; i < amountFree.length; i++) {
            if(missileValues[i] != 0 && freeAffiliate[account][i] > 0) {
                amountFree[i] += freeAffiliate[account][i];
            }
        }
        return amountFree;
    }

    function calPosition(uint256 randomNumber, address account) public override view returns (
        uint256[12] memory map, 
        uint256 firstPosition, 
        uint256 secondPosition, 
        uint256 finalReward,
        uint256 boatShot
    ) {        
        (map, firstPosition, secondPosition) = CoreUtility._calRandom(randomNumber, ghostRate, goldRate, playNumbers);
        LastestRequest memory request = userRequests[account];
        uint256[12] memory positions = missilePositions[request.requestId]; 
        uint256 userReward;
        for (uint256 i = 0; i < 12; i++) {
            uint256 value;
            if (positions[i] != 0) {
                if (map[i] == 0) {
                    value = 0;
                } else if (map[i] == 1) {
                    value = missileValues[positions[i]] * 2;
                    boatShot += 1;
                } else if (map[i] == 2) {
                    value = missileValues[positions[i]] * 3;
                    boatShot += 2;
                } else if (map[i] == 3) {
                    value = missileValues[positions[i]] * 4;
                    boatShot += 3;
                } else if (map[i] == 4) {
                    value = missileValues[positions[i]] * 5;
                    boatShot += 4;
                } else if (map[i] == 5) {
                    value = missileValues[positions[i]] * 6;
                    boatShot += 5;
                } else if (map[i] == 6) {
                    value = missileValues[positions[i]] * 10;
                    boatShot += 6;
                } else if (map[i] == 7) {
                    value = missileValues[positions[i]] * 100;
                    boatShot += 7;
                }
                if (i == firstPosition) {
                    value *= goldReward;
                }
            }
            userReward += value * reward;
        }
        (finalReward,) = rewardMul(userReward, account);
    }

    function setConfig(
        uint256 newReward, 
        uint256 newCost, 
        uint256 newGoldReward, 
        uint256 newMinimum,
        address treasury_,
        address random_
    ) external onlyOwner {
        reward = newReward;
        cost = newCost;
        goldReward = newGoldReward;
        minimumAmount = newMinimum;
        treasury = treasury_;
        random = IRandom(random_);
    }

    function setRate(uint256 newGoldRate, uint256 newGhostRate) external onlyOwner {
        require(newGoldRate < 1000000 && newGoldRate != 0 && newGhostRate < 1000000 && newGhostRate != 0, "ind");
        ghostRate = newGhostRate;
        goldRate = newGoldRate;
    }

    function setFreeAffiliate(uint256 typeFreeAffiliate_, uint256 numberFreeAffilate_) external onlyOwner {
        typeFreeAffiliate = typeFreeAffiliate_;
        numberFreeAffilate = numberFreeAffilate_;
    }

    function addToWhitelist(address[] memory accounts_) external onlyOwner {
        for(uint256 i = 0; i < accounts_.length; i++) {
            address account_ = accounts_[i];
            if(whitelistIds[account_] == 0 && account_ != address(0)) {
                whitelistIds[account_] = whitelist.length;
                whitelist.push(account_);
            }
        }
    }

    function removeFromWhitelist(address account) external onlyOwner {
        uint256 id = whitelistIds[account];
        require(id != 0 && account != address(0), "wl");
        if (id != whitelist.length - 1) {
            whitelist[id] = whitelist[whitelist.length - 1];
            whitelistIds[whitelist[whitelist.length - 1]] = id;
        }        
        whitelistIds[account] = 0;
        whitelist.pop();
    }

    function addToWhitelistFree(address[] memory accounts_, uint256 freeEventId_) external onlyOwner {
        require(freeEventId_ < countEventFree, "E");
        for(uint256 i = 0; i < accounts_.length; i++) {
            if (whitelistFreeIds[accounts_[i]][freeEventId_] == 0 && accounts_[i] != address(0)) {
                whitelistFreeIds[accounts_[i]][freeEventId_] = whitelistFree[freeEventId_].length;
                whitelistFree[freeEventId_].push(accounts_[i]);
            }
        }
    }

    function removeFromWhitelistFree(address account_, uint256 freeEventId_) external onlyOwner {
        require(freeEventId_ < countEventFree, "E");
        uint256 id = whitelistFreeIds[account_][freeEventId_];
        require(id != 0 && account_ != address(0), "wl");
        if (id != whitelistFree[freeEventId_].length - 1) {
            whitelistFree[freeEventId_][id] = whitelistFree[freeEventId_][whitelistFree[freeEventId_].length - 1];
            whitelistFreeIds[whitelistFree[freeEventId_][whitelistFree[freeEventId_].length - 1]][freeEventId_] = id;
        }        
        whitelistFreeIds[account_][freeEventId_] = 0;
        whitelistFree[freeEventId_].pop();
    }

    function startEventFree(
        uint256 typeMissile_, 
        uint256 amount_, 
        uint256 totalFree_, 
        uint256 startTime_,
        uint256 endTime_,
        uint256 object_
    ) external onlyOwner {
        require(object_ < 5 && startTime_ < endTime_ && typeMissile_ != 0 && typeMissile_ <= countTypeMissile, "ind");
        FreeEvent memory freeEvent = FreeEvent({
            typeMissileFree: uint32(typeMissile_),
            amountFree: uint32(amount_),
            startTime: uint96(startTime_),
            endTime: uint96(endTime_),
            freeObject: uint8(object_),
            freeEventId: uint24(countEventFree),
            totalFree: uint112(totalFree_),
            amountFreeUsed: 0
        });
        freeEventInfos.push(freeEvent);
        whitelistFree[countEventFree].push(address(0));
        countEventFree += 1;
        emit FreeStarted(freeEventInfos.length - 1, typeMissile_, amount_, startTime_, endTime_, totalFree_, object_, countEventFree - 1);
    }

    function removeEventFree(uint256 eventId) external onlyOwner {
        require(eventId < freeEventInfos.length, "E");
        if (eventId < freeEventInfos.length - 1) {
            freeEventInfos[eventId] = freeEventInfos[freeEventInfos.length - 1];
        }
        freeEventInfos.pop();
    }

    function startEventReward(uint256 startTime_, uint256 endTime_, uint256 object_, uint256 multiplier_) external onlyOwner {        
        require(startTime_ < endTime_ && object_ < 5, "ind");
        startTimeEvent = startTime_;
        endTimeEvent = endTime_;
        objectEvent = object_;
        multiplier = multiplier_;
        emit RewardStarted(startTime_, endTime_, object_, multiplier_);
    }

    function endEvenReward() external onlyOwner {
        endTimeEvent = block.timestamp;
        emit RewardEnded();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawEmergency(address token_, address to, uint256 value) external onlyOwner {
        SafeToken.safeTransfer(token_, to, value);
    }
    
    uint256[47] private __gap;
}