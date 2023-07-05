// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../upgradeable/utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

import "./IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../../proxy/utils/Initializable.sol";

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
import "../../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title ERC721 contract for crowdfunds from allowed artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {ICrowdfund} from "./interfaces/ICrowdfund.sol";
import {IERC721Art} from "./interfaces/IERC721Art.sol";
import {IManagement} from "./interfaces/IManagement.sol";

///@dev security settings.
import {SecurityUpgradeable, OwnableUpgradeable} from "./SecurityUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract Crowdfund is ICrowdfund, SecurityUpgradeable {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    // fund settings
    uint256 private s_minSoldRate; // over 10000
    uint256 private s_dueDate;
    uint256 private s_nextInvestId; // 0 is for invalid invest ID
    mapping(address investor => uint256[] investIds)
        private s_investIdsPerInvestor;
    mapping(QuotaClass class => QuotaInfos infos) private s_quotaInfos;
    mapping(uint256 investId => InvestIdInfos infos) private s_investIdInfos;

    // donation
    uint256 private s_donationFee; // over 10000
    address private s_donationReceiver;

    // investments made per coin
    mapping(address investor => mapping(IManagement.Coin coin => uint256 amount))
        private s_paymentsPerCoin;

    // ERC721Art contract
    IERC721Art private s_collection;

    // constants
    uint256 private constant MAX_UINT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant MIN_SOLD_RATE = 2500; //over 10000
    uint256 private constant MAX_SOLD_RATE = 10000;
    uint256 private constant RATIO_DENOMINATOR = 10000;
    uint256 private constant CREATORSPRO_ROYALTY_FEE = 900; // royalty to CreatorsPRO = 9% (over 10000)
    uint256 private constant CROWDFUND_DURATION = 6 * 30 days; // crowdfund duration = 6 months
    uint256 private constant SEVEN_DAYS = 7 days;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    ///@dev checks if the caller has still shares/is an investor
    function __checkIfInvestor(address _investor) private view {
        if (!(s_investIdsPerInvestor[_investor].length > 0)) {
            revert Crowdfund__CallerNotInvestor();
        }
    }

    ///@dev checks if minimum goal/objective is reached
    function __checkIfMinGoalReached() private view {
        uint256 soldQuotaAmount = s_quotaInfos[QuotaClass.LOW].bought +
            s_quotaInfos[QuotaClass.REGULAR].bought +
            s_quotaInfos[QuotaClass.HIGH].bought;
        uint256 maxQuotasAmount = s_quotaInfos[QuotaClass.LOW].amount +
            s_quotaInfos[QuotaClass.REGULAR].amount +
            s_quotaInfos[QuotaClass.HIGH].amount;
        if (
            (soldQuotaAmount * RATIO_DENOMINATOR) / maxQuotasAmount <
            s_minSoldRate
        ) {
            revert Crowdfund__MinGoalNotReached();
        }
    }

    ///@dev checks if crowdfund is still ongoing
    function __checkIfCrowdfundOngoing() private view {
        if (!(block.timestamp < s_dueDate)) {
            revert Crowdfund__PastDue();
        }
    }

    /// -----------------------------------------------------------------------
    /// Receive function
    /// -----------------------------------------------------------------------

    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    /// @dev initializer modifier added.
    /// @inheritdoc ICrowdfund
    function initialize(
        uint256[3] memory valuesLowQuota,
        uint256[3] memory valuesRegQuota,
        uint256[3] memory valuesHighQuota,
        uint256 amountLowQuota,
        uint256 amountRegQuota,
        uint256 amountHighQuota,
        address donationReceiver,
        uint256 donationFee,
        uint256 minSoldRate,
        address collection
    ) public override(ICrowdfund) initializer {
        if (amountLowQuota + amountRegQuota + amountHighQuota == 0) {
            revert Crowdfund__MaxSupplyIs0();
        }
        if (minSoldRate < MIN_SOLD_RATE || minSoldRate > MAX_SOLD_RATE) {
            revert Crowdfund__InvalidMinSoldRate();
        }

        // checking _collection address
        s_collection = IERC721Art(collection);

        if (
            msg.sender !=
            address(
                SecurityUpgradeable(address(s_collection)).getManagement()
            ) ||
            s_collection.getMaxSupply() !=
            amountLowQuota + amountRegQuota + amountHighQuota ||
            s_collection.getPricePerCoin(IManagement.Coin.ETH_COIN) !=
            MAX_UINT ||
            s_collection.getPricePerCoin(IManagement.Coin.USD_TOKEN) !=
            MAX_UINT ||
            s_collection.getPricePerCoin(IManagement.Coin.CREATORS_TOKEN) !=
            MAX_UINT
        ) {
            revert Crowdfund__InvalidCollection();
        }

        _SecurityUpgradeable_init(OwnableUpgradeable(collection).owner());

        s_quotaInfos[QuotaClass.LOW].amount = amountLowQuota;
        s_quotaInfos[QuotaClass.REGULAR].amount = amountRegQuota;
        s_quotaInfos[QuotaClass.HIGH].amount = amountHighQuota;

        s_quotaInfos[QuotaClass.LOW].values = valuesLowQuota;
        s_quotaInfos[QuotaClass.REGULAR].values = valuesRegQuota;
        s_quotaInfos[QuotaClass.HIGH].values = valuesHighQuota;

        s_quotaInfos[QuotaClass.REGULAR].nextTokenId = amountLowQuota;
        s_quotaInfos[QuotaClass.HIGH].nextTokenId =
            amountLowQuota +
            amountRegQuota;

        s_donationReceiver = donationReceiver;
        s_donationFee = donationFee;
        s_minSoldRate = minSoldRate;

        s_management = IManagement(msg.sender);

        s_dueDate = block.timestamp + CROWDFUND_DURATION; // standard duration of crowdfund (6 months)
        s_nextInvestId = 1;
    }

    /// -----------------------------------------------------------------------
    /// Implemented functions
    /// -----------------------------------------------------------------------

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function invest(
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) external payable override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();
        __checkIfCrowdfundOngoing();
        _onlyValidCoin(coin);

        uint256 totalPayment = __invest(
            msg.sender,
            msg.sender,
            amountOfLowQuota,
            amountOfRegularQuota,
            amountOfHighQuota,
            coin
        );

        emit Invested(
            msg.sender,
            s_nextInvestId - 1,
            amountOfLowQuota,
            amountOfRegularQuota,
            amountOfHighQuota,
            totalPayment,
            coin
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only authorized parties 
    can call this function. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function investForAddress(
        address investor,
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) public payable override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        _onlyAuthorized();
        __checkIfCrowdfundOngoing();
        _onlyValidCoin(coin);

        uint256 totalPayment = __invest(
            investor,
            msg.sender,
            amountOfLowQuota,
            amountOfRegularQuota,
            amountOfHighQuota,
            coin
        );

        emit Invested(
            investor,
            s_nextInvestId - 1,
            amountOfLowQuota,
            amountOfRegularQuota,
            amountOfHighQuota,
            totalPayment,
            coin
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function donate(
        uint256 amount,
        IManagement.Coin coin
    ) external payable override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();
        __checkIfCrowdfundOngoing();
        _onlyValidCoin(coin);

        __donate(msg.sender, msg.sender, amount, coin);

        emit DonationTransferred(msg.sender, amount, coin);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only authorized parties 
    can call this function. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function donateForAddress(
        address donor,
        uint256 amount,
        IManagement.Coin coin
    ) public payable override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        _onlyAuthorized();
        __checkIfCrowdfundOngoing();
        _onlyValidCoin(coin);

        __donate(donor, msg.sender, amount, coin);

        emit DonationTransferred(donor, amount, coin);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only investors will be able to
    refund. If the invest ID is not in the refund period or the minimum sold rate is reached, it will be disconsiderd.
    If creator/collection has been corrupted, the refund will continue without the checks previously explained.  */
    /// @inheritdoc ICrowdfund
    function refundAll() external override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        __checkIfInvestor(msg.sender);

        uint256 soldQuotaAmount = s_quotaInfos[QuotaClass.LOW].bought +
            s_quotaInfos[QuotaClass.REGULAR].bought +
            s_quotaInfos[QuotaClass.HIGH].bought;
        uint256 maxQuotasAmount = s_quotaInfos[QuotaClass.LOW].amount +
            s_quotaInfos[QuotaClass.REGULAR].amount +
            s_quotaInfos[QuotaClass.HIGH].amount;

        bool isCorrupted = s_management.getIsCorrupted(owner());
        if (
            !isCorrupted &&
            (!((soldQuotaAmount * RATIO_DENOMINATOR) / maxQuotasAmount <
                s_minSoldRate) || block.timestamp < s_dueDate)
        ) {
            revert Crowdfund__RefundNotPossible();
        }

        (
            uint256[] memory amountPerCoin,
            uint256[] memory investIdsRefunded
        ) = __refundAll(
                msg.sender,
                isCorrupted,
                (soldQuotaAmount * RATIO_DENOMINATOR) / maxQuotasAmount <
                    s_minSoldRate &&
                    !(block.timestamp < s_dueDate)
            );

        emit RefundedAll(
            msg.sender,
            amountPerCoin[0],
            amountPerCoin[1],
            amountPerCoin[2],
            investIdsRefunded
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only investors can refund.
    It will revert if either the 7 days period has past or the min rate of sold quotas has been reached (if not corrupted).
    If corrupted, investors can refund at any time. */
    /// @inheritdoc ICrowdfund
    function refundWithInvestId(uint256 investId) public override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        __checkIfInvestor(msg.sender);

        if (s_investIdInfos[investId].investor != msg.sender) {
            revert Crowdfund__NotInvestIdOwner();
        }

        uint256 soldQuotaAmount = s_quotaInfos[QuotaClass.LOW].bought +
            s_quotaInfos[QuotaClass.REGULAR].bought +
            s_quotaInfos[QuotaClass.HIGH].bought;
        uint256 maxQuotasAmount = s_quotaInfos[QuotaClass.LOW].amount +
            s_quotaInfos[QuotaClass.REGULAR].amount +
            s_quotaInfos[QuotaClass.HIGH].amount;

        (bool success, uint256 amount, IManagement.Coin coin) = __refund(
            msg.sender,
            investId,
            s_management.getIsCorrupted(owner()),
            (soldQuotaAmount * RATIO_DENOMINATOR) / maxQuotasAmount <
                s_minSoldRate &&
                !(block.timestamp < s_dueDate)
        );

        if (!success) {
            revert Crowdfund__RefundNotPossible();
        }

        emit RefundedInvestId(msg.sender, investId, amount, coin);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only investors can be refunded. */
    /// @inheritdoc ICrowdfund
    function refundToAddress(address investor) external override(ICrowdfund) {
        _nonReentrant();
        _onlyAuthorized();
        __checkIfInvestor(investor);

        (
            uint256[] memory amountPerCoin,
            uint256[] memory investIdsRefunded
        ) = __refundAll(investor, true, true);

        emit RefundedAllToAddress(
            msg.sender,
            investor,
            amountPerCoin[0],
            amountPerCoin[1],
            amountPerCoin[2],
            investIdsRefunded
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. Only creator/owner can execute function. It will revert if the min 
    rate of sold quotas has been reached. */
    /// @inheritdoc ICrowdfund
    function withdrawFund() external override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        _onlyAuthorized();
        __checkIfMinGoalReached();

        address multisig = s_management.getMultiSig();
        uint256[] memory amounts = new uint256[](3);
        uint256[] memory donationAmounts = new uint256[](3);
        for (uint256 ii = 1; ii < 4; ++ii) {
            IManagement.Coin coin = IManagement.Coin(ii - 1);
            uint256 coinBalance = coin == IManagement.Coin.ETH_COIN
                ? address(this).balance
                : s_management.getTokenContract(coin).balanceOf(address(this));

            if (coinBalance == 0) {
                continue;
            }

            uint256 donationAmount = (coinBalance * s_donationFee) /
                RATIO_DENOMINATOR;
            uint256 creatorsProRoyalty = (coinBalance *
                CREATORSPRO_ROYALTY_FEE) / RATIO_DENOMINATOR;
            uint256 amount = s_donationReceiver != address(0)
                ? coinBalance - donationAmount - creatorsProRoyalty
                : coinBalance - creatorsProRoyalty;

            if (s_donationReceiver != address(0)) {
                __executeTransfer(
                    donationAmount,
                    coin,
                    address(this),
                    s_donationReceiver
                );
            }
            __executeTransfer(
                creatorsProRoyalty,
                coin,
                address(this),
                multisig
            );
            __executeTransfer(amount, coin, address(this), owner());

            amounts[ii - 1] = amount;
            donationAmounts[ii - 1] = donationAmount;
        }

        emit CreatorWithdrawed(amounts[0], amounts[1], amounts[2]);
        emit DonationSent(
            s_donationReceiver,
            donationAmounts[0],
            donationAmounts[1],
            donationAmounts[2]
        );
    }

    /** @dev function to be used by the creator. Same rules for the mint public function (below) */
    /// @inheritdoc ICrowdfund
    function mint() external override(ICrowdfund) {
        mint(msg.sender);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. It will revert if array of invest IDs for a given investor
    address is empty. Once minted, the list of invest IDs per investor and the list of token IDs per 
    invest ID are deleted.  */
    /// @inheritdoc ICrowdfund
    function mint(address investor) public override(ICrowdfund) {
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();
        __checkIfMinGoalReached();

        uint256[] memory investIds = s_investIdsPerInvestor[investor];
        if (investIds.length == 0) {
            revert Crowdfund__NoMoreTokensToMint();
        }

        uint256[] memory tokenAmounts = new uint256[](3);
        bool deleteInvestIds = true;
        unchecked {
            for (uint256 jj; jj < investIds.length; ++jj) {
                InvestIdInfos memory investIdInfos = s_investIdInfos[
                    investIds[jj]
                ];
                if (
                    block.timestamp < investIdInfos.sevenDaysPeriod &&
                    (investIdInfos.lowQuotaAmount > 0 ||
                        investIdInfos.regQuotaAmount > 0 ||
                        investIdInfos.highQuotaAmount > 0)
                ) {
                    deleteInvestIds = false;
                    continue;
                }

                tokenAmounts[0] += investIdInfos.lowQuotaAmount;
                tokenAmounts[1] += investIdInfos.regQuotaAmount;
                tokenAmounts[2] += investIdInfos.highQuotaAmount;

                delete s_investIdInfos[investIds[jj]];
            }
        }

        if (deleteInvestIds) {
            delete s_investIdsPerInvestor[investor];
        }

        uint256[] memory nextTokenIds = new uint256[](3);
        nextTokenIds[0] = s_quotaInfos[QuotaClass.LOW].nextTokenId;
        nextTokenIds[1] = s_quotaInfos[QuotaClass.REGULAR].nextTokenId;
        nextTokenIds[2] = s_quotaInfos[QuotaClass.HIGH].nextTokenId;

        s_quotaInfos[QuotaClass.LOW].nextTokenId += tokenAmounts[0];
        s_quotaInfos[QuotaClass.REGULAR].nextTokenId += tokenAmounts[1];
        s_quotaInfos[QuotaClass.HIGH].nextTokenId += tokenAmounts[2];

        uint256[] memory tokenIds = new uint256[](
            tokenAmounts[0] + tokenAmounts[1] + tokenAmounts[2]
        );
        uint8[] memory classes = new uint8[](tokenIds.length);

        unchecked {
            uint256 kk;
            for (uint8 ii; ii < 3; ++ii) {
                for (uint256 jj; jj < tokenAmounts[ii]; ++jj) {
                    tokenIds[kk] = nextTokenIds[ii] + jj;
                    classes[kk] = ii;
                    ++kk;
                }
            }
        }

        s_collection.mintForCrowdfund(tokenIds, classes, investor);

        emit InvestorMinted(investor, msg.sender);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only managers are allowed 
    to execute this function. */
    /// @inheritdoc ICrowdfund
    function withdrawToAddress(
        address receiver,
        uint256 amount
    ) external override(ICrowdfund) {
        _nonReentrant();
        _onlyManagers();

        _transferTo(receiver, amount);

        emit WithdrawnToAddress(msg.sender, receiver, amount);
    }

    /// -----------------------------------------------------------------------
    /// Setter functions
    /// -----------------------------------------------------------------------

    // --- Pause and Unpause functions ---

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc SecurityUpgradeable
    function pause() public override(SecurityUpgradeable) {
        _onlyAuthorized();

        SecurityUpgradeable.pause();
        s_collection.pause();
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc SecurityUpgradeable
    function unpause() public override(SecurityUpgradeable) {
        _onlyAuthorized();

        SecurityUpgradeable.unpause();
        s_collection.unpause();
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /** @dev executes all the transfers
        @param amount: amount to be transferred
        @param coin: coin of transfer
        @param from: the address from which the transfer should be executed
        @param to: the recipient of the transfer */
    function __executeTransfer(
        uint256 amount,
        IManagement.Coin coin,
        address from,
        address to
    ) private {
        if (coin != IManagement.Coin.ETH_COIN) {
            _transferERC20To(coin, from, to, amount);
        } else {
            if (from == address(this)) {
                _transferTo(to, amount);
            } else {
                if (msg.value < amount) {
                    revert Crowdfund__NotEnoughValueSent();
                } else if (msg.value > amount) {
                    uint256 aboveValue = msg.value - amount;
                    _transferTo(from, aboveValue);
                }
            }
        }
    }

    /** @dev performs refund of a given invest ID for a given user
        @param user: user address
        @param investId: ID of the investment to be refunded
        @param isCorrupted: specifies if owner is corrupted (true) or not (false)
        @param flexTagNotReachedAndDueDateReached: specifies if flextag was not reached and crowdfund has past due date (true) or not (false)
        @return bool that specifies if process was successful (true) or not (false), amount of payment refunded, and the coin of refund */
    function __refund(
        address user,
        uint256 investId,
        bool isCorrupted,
        bool flexTagNotReachedAndDueDateReached
    ) private returns (bool, uint256, IManagement.Coin) {
        if (
            !isCorrupted &&
            !(block.timestamp < s_investIdInfos[investId].sevenDaysPeriod) &&
            !flexTagNotReachedAndDueDateReached
        ) {
            return (false, 0, IManagement.Coin(0));
        }

        uint256[] storage p_investIds = s_investIdsPerInvestor[user];
        uint256 last_index = p_investIds.length - 1;

        p_investIds[s_investIdInfos[investId].index] = p_investIds[last_index];
        s_investIdInfos[p_investIds[last_index]].index = s_investIdInfos[
            investId
        ].index;
        p_investIds.pop();

        s_quotaInfos[QuotaClass.LOW].bought -= s_investIdInfos[investId]
            .lowQuotaAmount;
        s_quotaInfos[QuotaClass.REGULAR].bought -= s_investIdInfos[investId]
            .regQuotaAmount;
        s_quotaInfos[QuotaClass.HIGH].bought -= s_investIdInfos[investId]
            .highQuotaAmount;
        uint256 amount = s_investIdInfos[investId].totalPayment;
        IManagement.Coin coin = s_investIdInfos[investId].coin;
        delete s_investIdInfos[investId];

        s_paymentsPerCoin[user][coin] -= amount;
        __executeTransfer(amount, coin, address(this), user);

        return (true, amount, coin);
    }

    /** @dev performs refund of all investments for given investor user
        @param user: user address
        @param isCorrupted: specifies if owner is corrupted (true) or not (false)
        @param flexTagNotReachedAndDueDateReached: specifies if flextag was not reached and crowdfund has past due date (true) or not (false)
        @return uint256[3] array of payments per coin and uint256[] array invest IDs refunded */
    function __refundAll(
        address user,
        bool isCorrupted,
        bool flexTagNotReachedAndDueDateReached
    ) private returns (uint256[] memory, uint256[] memory) {
        uint256[] memory m_investIds = s_investIdsPerInvestor[user];
        uint256[] memory investIdsRefunded = new uint256[](m_investIds.length);
        uint256[] memory amountPerCoin = new uint256[](3);
        unchecked {
            uint256 jj;
            for (uint256 ii; ii < m_investIds.length; ++ii) {
                (
                    bool success,
                    uint256 amount,
                    IManagement.Coin coin
                ) = __refund(
                        user,
                        m_investIds[ii],
                        isCorrupted,
                        flexTagNotReachedAndDueDateReached
                    );
                if (!success) {
                    continue;
                }

                amountPerCoin[uint8(coin)] += amount;
                investIdsRefunded[jj] = m_investIds[ii];
                ++jj;
            }
        }

        return (amountPerCoin, investIdsRefunded);
    }

    /** @dev performs every invest computation
        @param investor: investor's address
        @param paymentFrom: address from which the payment will be transferred
        @param amountOfLowQuota: amount of low quotas to be bought
        @param amountOfRegularQuota: amount of regular quotas to be bought
        @param amountOfHighQuota: amount of high quotas to be bought
        @param coin: coin of transfer
        @return uint256 value for the total amount paid */
    function __invest(
        address investor,
        address paymentFrom,
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) private returns (uint256) {
        if (
            s_quotaInfos[QuotaClass.LOW].bought + amountOfLowQuota >
            s_quotaInfos[QuotaClass.LOW].amount
        ) {
            revert Crowdfund__LowQuotaMaxAmountReached();
        }
        if (
            s_quotaInfos[QuotaClass.REGULAR].bought + amountOfRegularQuota >
            s_quotaInfos[QuotaClass.REGULAR].amount
        ) {
            revert Crowdfund__RegQuotaMaxAmountReached();
        }
        if (
            s_quotaInfos[QuotaClass.HIGH].bought + amountOfHighQuota >
            s_quotaInfos[QuotaClass.HIGH].amount
        ) {
            revert Crowdfund__HighQuotaMaxAmountReached();
        }

        uint256 totalPayment = amountOfLowQuota *
            s_quotaInfos[QuotaClass.LOW].values[uint8(coin)] +
            amountOfRegularQuota *
            s_quotaInfos[QuotaClass.REGULAR].values[uint8(coin)] +
            amountOfHighQuota *
            s_quotaInfos[QuotaClass.HIGH].values[uint8(coin)];

        __executeTransfer(totalPayment, coin, paymentFrom, address(this));

        unchecked {
            uint256 nextInvestId = s_nextInvestId;
            s_investIdInfos[nextInvestId].index = s_investIdsPerInvestor[
                investor
            ].length;
            s_investIdInfos[nextInvestId].investor = investor;
            s_investIdInfos[nextInvestId].totalPayment = totalPayment;
            s_investIdInfos[nextInvestId].coin = coin;
            s_investIdInfos[nextInvestId].sevenDaysPeriod =
                block.timestamp +
                SEVEN_DAYS;
            s_investIdInfos[nextInvestId].lowQuotaAmount = amountOfLowQuota;
            s_investIdInfos[nextInvestId].regQuotaAmount = amountOfRegularQuota;
            s_investIdInfos[nextInvestId].highQuotaAmount = amountOfHighQuota;
            s_investIdsPerInvestor[investor].push(nextInvestId);

            s_quotaInfos[QuotaClass.LOW].bought += amountOfLowQuota;
            s_quotaInfos[QuotaClass.REGULAR].bought += amountOfRegularQuota;
            s_quotaInfos[QuotaClass.HIGH].bought += amountOfHighQuota;

            s_paymentsPerCoin[investor][coin] += totalPayment;

            s_nextInvestId++;
        }

        return totalPayment;
    }

    /** @dev performs every donation computation
        @param donor: donor's address
        @param paymentFrom: address from which the payment will be transferred
        @param amount: donation amount
        @param coin: coin/token for donation */
    function __donate(
        address donor,
        address paymentFrom,
        uint256 amount,
        IManagement.Coin coin
    ) private {
        if (coin == IManagement.Coin.ETH_COIN) {
            amount = msg.value;
        }

        __executeTransfer(amount, coin, paymentFrom, address(this));

        unchecked {
            uint256 nextInvestId = s_nextInvestId;
            s_investIdInfos[nextInvestId].index = s_investIdsPerInvestor[donor]
                .length;
            s_investIdInfos[nextInvestId].investor = donor;
            s_investIdInfos[nextInvestId].totalPayment = amount;
            s_investIdInfos[nextInvestId].coin = coin;
            s_investIdInfos[nextInvestId].sevenDaysPeriod =
                block.timestamp +
                SEVEN_DAYS;
            s_investIdsPerInvestor[donor].push(nextInvestId);

            s_paymentsPerCoin[donor][coin] += amount;

            s_nextInvestId++;
        }
    }

    /// -----------------------------------------------------------------------
    /// Getter functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ICrowdfund
    function getMinSoldRate()
        external
        view
        override(ICrowdfund)
        returns (uint256)
    {
        return s_minSoldRate;
    }

    /// @inheritdoc ICrowdfund
    function getDueDate() external view override(ICrowdfund) returns (uint256) {
        return s_dueDate;
    }

    /// @inheritdoc ICrowdfund
    function getNextInvestId()
        external
        view
        override(ICrowdfund)
        returns (uint256)
    {
        return s_nextInvestId;
    }

    /// @inheritdoc ICrowdfund
    function getInvestIdsPerInvestor(
        address investor,
        uint256 index
    ) external view override(ICrowdfund) returns (uint256) {
        return s_investIdsPerInvestor[investor][index];
    }

    /// @inheritdoc ICrowdfund
    function getDonationFee()
        external
        view
        override(ICrowdfund)
        returns (uint256)
    {
        return s_donationFee;
    }

    /// @inheritdoc ICrowdfund
    function getDonationReceiver()
        external
        view
        override(ICrowdfund)
        returns (address)
    {
        return s_donationReceiver;
    }

    /// @inheritdoc ICrowdfund
    function getPaymentsPerCoin(
        address investor,
        IManagement.Coin coin
    ) external view override(ICrowdfund) returns (uint256) {
        return s_paymentsPerCoin[investor][coin];
    }

    /// @inheritdoc ICrowdfund
    function getCollection()
        external
        view
        override(ICrowdfund)
        returns (IERC721Art)
    {
        return s_collection;
    }

    /// @inheritdoc ICrowdfund
    function getAllInvestIdsPerInvestor(
        address investor
    ) external view override(ICrowdfund) returns (uint256[] memory) {
        return s_investIdsPerInvestor[investor];
    }

    /// @inheritdoc ICrowdfund
    function getQuotaInfos(
        QuotaClass class
    ) external view override(ICrowdfund) returns (QuotaInfos memory) {
        return s_quotaInfos[class];
    }

    /// @inheritdoc ICrowdfund
    function getInvestIdInfos(
        uint256 investId
    ) external view override(ICrowdfund) returns (InvestIdInfos memory) {
        return s_investIdInfos[investId];
    }

    /// -----------------------------------------------------------------------
    /// Storage space for upgrades
    /// -----------------------------------------------------------------------

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC721 contract for crowdfunds from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC721Art} from "./IERC721Art.sol";
import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICrowdfund {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the crowdfund has past due data
    error Crowdfund__PastDue();

    ///@dev error for when the caller is not an investor
    error Crowdfund__CallerNotInvestor();

    ///@dev error for when low class quota maximum amount has reached
    error Crowdfund__LowQuotaMaxAmountReached();

    ///@dev error for when regular class quota maximum amount has reached
    error Crowdfund__RegQuotaMaxAmountReached();

    ///@dev error for when low high quota maximum amount has reached
    error Crowdfund__HighQuotaMaxAmountReached();

    ///@dev error for when minimum fund goal is not reached
    error Crowdfund__MinGoalNotReached();

    ///@dev error for when not enough ETH value is sent
    error Crowdfund__NotEnoughValueSent();

    ///@dev error for when the resulting max supply is 0
    error Crowdfund__MaxSupplyIs0();

    ///@dev error for when the caller has no more tokens to mint
    error Crowdfund__NoMoreTokensToMint();

    ///@dev error for when the caller is not invest ID owner
    error Crowdfund__NotInvestIdOwner();

    ///@dev error for when an invalid collection address is given
    error Crowdfund__InvalidCollection();

    ///@dev error for when refund is not possible
    error Crowdfund__RefundNotPossible();

    ///@dev error for when an invalid minimum sold rate is given
    error Crowdfund__InvalidMinSoldRate();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the quota class 
        @param LOW: low class
        @param REGULAR: regular class
        @param HIGH: high class */
    enum QuotaClass {
        LOW,
        REGULAR,
        HIGH
    }

    /** @dev struct with important informations of an invest ID 
        @param index: invest ID index in investIdsPerInvestor array
        @param totalPayment: total amount paid in the investment
        @param sevenDaysPeriod: 7 seven days period end timestamp
        @param coin: coin used for the investment
        @param lowQuotaAmount: low class quota amount bought 
        @param regQuotaAmount: regular class quota amount bought 
        @param highQuotaAmount: high class quota amount bought */
    struct InvestIdInfos {
        uint256 index;
        uint256 totalPayment;
        uint256 sevenDaysPeriod;
        IManagement.Coin coin;
        address investor;
        uint256 lowQuotaAmount;
        uint256 regQuotaAmount;
        uint256 highQuotaAmount;
    }

    /** @dev struct with important information about each quota 
        @param values: array of price values for each coin. Array order: [ETH, US dollar token, CreatorsPRO token]
        @param amount: total amount
        @param bough: amount of bought quotas
        @param nextTokenId: next token ID for the current quota */
    struct QuotaInfos {
        uint256[3] values;
        uint256 amount;
        uint256 bought;
        uint256 nextTokenId;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when shares are bought 
        @param investor: investor's address
        @param investId: ID of the investment
        @param lowQuotaAmount: amount of low class quota
        @param regQuotaAmount: amount of regular class quota
        @param highQuotaAmount: amount of high class quota
        @param totalPayment: amount of shares bought 
        @param coin: coin of investment */
    event Invested(
        address indexed investor,
        uint256 indexed investId,
        uint256 lowQuotaAmount,
        uint256 regQuotaAmount,
        uint256 highQuotaAmount,
        uint256 totalPayment,
        IManagement.Coin coin
    );

    /** @dev event for when an investor withdraws investment 
        @param investor: investor's address 
        @param investId: ID of investment 
        @param amount: amount to be withdrawed
        @param coin: coin of withdrawal */
    event RefundedInvestId(
        address indexed investor,
        uint256 indexed investId,
        uint256 amount,
        IManagement.Coin coin
    );

    /** @dev event for when investor refunds his/her whole investment at once
        @param investor: investor's address 
        @param ETHAmount: amount refunded in ETH/MATIC
        @param USDAmount: amount refunded in USD 
        @param CreatorsCoinAmount: amount refunded in CreatorsCoin 
        @param investIdsRefunded: array of refunded invest IDs */
    event RefundedAll(
        address indexed investor,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount,
        uint256[] investIdsRefunded
    );

    /** @dev event for when the crowdfund creator withdraws funds 
        @param ETHAmount: amount withdrawed in ETH/MATIC
        @param USDAmount: amount withdrawed in USD
        @param CreatorsCoinAmount: amount withdrawed in CreatorsCoin */
    event CreatorWithdrawed(
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount
    );

    /** @dev event for when the donantion is sent
        @param _donationReceiver: receiver address of the donation
        @param ETHAmount: amount donated in ETH
        @param USDAmount: amount donated in USD
        @param CreatorsCoinAmount: amount donated in CreatorsCoin */
    event DonationSent(
        address indexed _donationReceiver,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount
    );

    /** @dev event for when an investor has minted his/her tokens
        @param investor: address of investor 
        @param caller: function's caller address */
    event InvestorMinted(address indexed investor, address indexed caller);

    /** @dev event for when a donation is made
        @param caller: function caller address
        @param amount: donation amount
        @param coin: coin of donation */
    event DonationTransferred(
        address indexed caller,
        uint256 amount,
        IManagement.Coin coin
    );

    /** @dev event for when a manager refunds all quotas to given investor address 
        @param manager: manager address that called the function
        @param investor: investor address
        @param ETHAmount: amount refunded in ETH/MATIC
        @param USDAmount: amount refunded in USD 
        @param CreatorsCoinAmount: amount refunded in CreatorsCoin 
        @param investIdsRefunded: array of refunded invest IDs */
    event RefundedAllToAddress(
        address indexed manager,
        address indexed investor,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount,
        uint256[] investIdsRefunded
    );

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes this contract.
        @param valuesLowQuota: array of values for low quota
        @param valuesRegQuota: array of values for regular quota
        @param valuesHighQuota: array of values for high quota 
        @param amountLowQuota: amount for low quota 
        @param amountRegQuota: amount for regular quota 
        @param amountHighQuota: amount for high quota 
        @param donationReceiver: address for donation 
        @param donationFee: fee for donation 
        @param minSoldRate: minimum rate for sold quotas 
        @param collection: ERC721Art collection address */
    function initialize(
        uint256[3] memory valuesLowQuota,
        uint256[3] memory valuesRegQuota,
        uint256[3] memory valuesHighQuota,
        uint256 amountLowQuota,
        uint256 amountRegQuota,
        uint256 amountHighQuota,
        address donationReceiver,
        uint256 donationFee,
        uint256 minSoldRate,
        address collection
    ) external;

    /** @notice buys the given amount of shares in the given coin/token. Payable function.
        @param amountOfLowQuota: amount of low quotas to be bought
        @param amountOfRegularQuota: amount of regular quotas to be bought
        @param amountOfHighQuota: amount of high quotas to be bought
        @param coin: coin of transfer */
    function invest(
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) external payable;

    /** @notice buys the given amount of shares in the given coin/token for given address. Payable function.
        @param amountOfLowQuota: amount of low quotas to be bought
        @param amountOfRegularQuota: amount of regular quotas to be bought
        @param amountOfHighQuota: amount of high quotas to be bought 
        @param coin: coin of transfer */
    function investForAddress(
        address investor,
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) external payable;

    /** @notice donates the given amount of the given to the crowdfund (will not get ERC721 tokens as reward) 
        @param amount: donation amount
        @param coin: coin/token for donation */
    function donate(uint256 amount, IManagement.Coin coin) external payable;

    /** @notice donates the given amount to the crowdfund (will not get ERC721 tokens as reward) for the given address
        @param donor: donor's address
        @param amount: donation amount
        @param coin: coin/token for donation */
    function donateForAddress(
        address donor,
        uint256 amount,
        IManagement.Coin coin
    ) external payable;

    /** @notice withdraws the fund invested to the calling investor address */
    function refundAll() external;

    /** @notice withdraws the fund invested for the given invest ID to the calling investor address 
        @param investId: ID of the investment */
    function refundWithInvestId(uint256 investId) external;

    /** @notice refunds all quotas to the given investor address
        @param investor: investor address */
    function refundToAddress(address investor) external;

    /** @notice withdraws fund to the calling collection's creator wallet address */
    function withdrawFund() external;

    /** @notice mints token IDs for an investor */
    function mint() external;

    /** @notice mints token IDs for an investor 
        @param investor: investor's address */
    function mint(address investor) external;

    /** @notice withdraws funds to given address
        @param receiver: fund receiver address
        @param amount: amount to withdraw */
    function withdrawToAddress(address receiver, uint256 amount) external;

    // --- From storage variables ---

    /** @notice reads minSoldRate public storage variable 
        @return uint256 value for the minimum rate of sold quotas */
    function getMinSoldRate() external view returns (uint256);

    /** @notice reads dueDate public storage variable 
        @return uint256 value for the crowdfunding due date timestamp */
    function getDueDate() external view returns (uint256);

    /** @notice reads nextInvestId public storage variable 
        @return uint256 value for the next investment ID */
    function getNextInvestId() external view returns (uint256);

    /** @notice reads investIdsPerInvestor public storage mapping
        @param investor: address of the investor
        @param index: array index
        @return uint256 value for the investment ID  */
    function getInvestIdsPerInvestor(
        address investor,
        uint256 index
    ) external view returns (uint256);

    /** @notice reads donationFee public storage variable 
        @return uint256 value for fee of donation (over 10000) */
    function getDonationFee() external view returns (uint256);

    /** @notice reads donationReceiver public storage variable 
        @return address of the donation receiver */
    function getDonationReceiver() external view returns (address);

    /** @notice reads paymentsPerCoin public storage mapping
        @param investor: address of the investor
        @param coin: coin of transfer
        @return uint256 value for amount deposited from the given investor, of the given coin  */
    function getPaymentsPerCoin(
        address investor,
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads collection public storage variable 
        @return IERC721Art instance of ERC721Art interface */
    function getCollection() external view returns (IERC721Art);

    /** @notice reads the investIdsPerInvestor public storage mapping 
        @param investor: address of the investor 
        @return uint256 array of invest IDs */
    function getAllInvestIdsPerInvestor(
        address investor
    ) external view returns (uint256[] memory);

    /** @notice reads the quotaInfos public storage mapping 
        @param class: QuotaClass class of quota 
        @return QuotaInfos struct of information about the given quota class */
    function getQuotaInfos(
        QuotaClass class
    ) external view returns (QuotaInfos memory);

    /** @notice reads the investIdInfos public storage mapping 
        @param investId: ID of the investment
        @return all information of the given invest ID */
    function getInvestIdInfos(
        uint256 investId
    ) external view returns (InvestIdInfos memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the reward contract of CreatorsPRO NFTs */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICRPReward {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error CRPReward__NotAllowed();

    ///@dev error for when the input arrays have not the same length
    error CRPReward__InputArraysNotSameLength();

    ///@dev error for when time unit is zero
    error CRPReward__TimeUnitZero();

    ///@dev error for when there are no rewards
    error CRPReward__NoRewards();

    ///@dev error for when an invalid coin is given
    error CRPReward__InvalidCoin();

    ///@dev error for when an invalid collection is calling a function
    error CRPReward__InvalidCollection();

    ///@dev error for when new interaction points precision is 0
    error CRPReward__InteracPointsPrecisionIsZero();

    ///@dev error for when new max reward claim value is 0
    error CRPReward__InvalidMaxRewardClaimValue();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev struct to store important token infos
        @param index: index of the token ID in the tokenIdsPerUser mapping
        @param hashpower: CreatorsPRO hashpower
        @param characteristId: CreatorsPRO characterist ID */
    struct TokenInfo {
        uint256 index; // 0 is for no longer listed
        uint256 hashpower;
        uint256 characteristId;
    }

    /** @dev struct to store user's info
        @param index: user index in usersArray storage array
        @param score: sum of the hashpowers from the NFTs owned by the user
        @param points: sum of interactions points done by the user
        @param timeOfLastUpdate: timestamp for the last information update
        @param unclaimedRewards: total amount of rewards still unclaimed
        @param conditionIdOflastUpdate: condition ID for the last update 
        @param collections: array of collection addresses of the user's NFTs */
    struct User {
        uint256 index; // 0 is for address no longer a user
        uint256 score;
        uint256 points;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
        address[] collections;
    }

    /** @dev struct for staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit)
        @param startTimestamp: timestamp for when the condition begins
        @param endTimestamp: timestamp for when the condition ends */
    struct RewardCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when points are added/increased
        @param user: user address
        @param tokenId: ID of the token
        @param points: amount of points increased
        @param value: value added/subtracted */
    event PointsSet(
        address indexed user,
        uint256 indexed tokenId,
        uint256 points,
        uint256 value
    );

    /** @dev event for when a token has been removed from tokenInfo mapping for
    the given user address
        @param user: user address
        @param tokenId: ID of the token */
    event TokenRemoved(address indexed user, uint256 indexed tokenId);

    /** @dev event for when rewards are claimed
        @param caller: address of the function caller (user)
        @param amount: amount of reward tokens claimed */
    event RewardsClaimed(address indexed caller, uint256 amount);

    /** @dev event for when the hash object for the tokenId is set.
        @param manager: address of the manager that has set the hash object
        @param collection: address of the collection
        @param tokenId: array of IDs of ERC721 token
        @param hashpower: array of hashpowers set by manager
        @param characteristId: array of IDs of the characterist */
    event HashObjectSet(
        address indexed manager,
        address indexed collection,
        uint256[] indexed tokenId,
        uint256[] hashpower,
        uint256[] characteristId
    );

    /** @dev event for when a new reward condition is set
        @param caller: function caller address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    event NewRewardCondition(
        address indexed caller,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    );

    /** @dev event for when new interacion points precision is set
        @param manager: manager address
        @param precision: array of precision values */
    event InteracPointsPrecisionSet(
        address indexed manager,
        uint256[3] precision
    );

    /** @dev event for when new max reward claim value is set
        @param manager: manager address
        @param maxRewardClaim: value for maximum reward claim */
    event MaxRewardClaimSet(address indexed manager, uint256 maxRewardClaim);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param management: Management contract address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time
        @param interacPoints: array of interaction points for each interaction (0: min, 1: send transfer, 2: receive transfer)
        @param maxRewardClaim:  maximum amount of claimable rewards */
    function initialize(
        address management,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime,
        uint256[3] calldata interacPoints,
        uint256 maxRewardClaim
    ) external;

    /** @notice increases the user score by the given amount
        @param user: user address
        @param tokenId: ID of the token 
        @param value: value added/subtracted
        @param coin: coin of transfer
        @param isSell: bool that specifies if is selling (true) or not (false) */
    function setPoints(
        address user,
        uint256 tokenId,
        uint256 value,
        uint8 coin,
        bool isSell
    ) external;

    /** @notice removes given token ID from given user address
        @param user: user address
        @param tokenId: token ID to be removed 
        @param emitEvent: true to emit event (external call), false otherwise (internal call)*/
    function removeToken(
        address user,
        uint256 tokenId,
        bool emitEvent
    ) external;

    /** @notice claims rewards to the caller wallet */
    function claimRewards() external;

    /** @notice sets hashpower and characterist ID for the given token ID
        @param collection: collection address
        @param tokenId: array of token IDs
        @param hashPower: array of hashpowers for the token ID
        @param characteristId: array of characterit IDs */
    function setHashObject(
        address collection,
        uint256[] memory tokenId,
        uint256[] memory hashPower,
        uint256[] memory characteristId
    ) external;

    /** @notice sets new reward condition
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    function setRewardCondition(
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    ) external;

    /** @notice sets new interaction points precision
        @param precision: array of new precision values */
    function setInteracPointsPrecision(uint256[3] calldata precision) external;

    /** @notice sets new maximum value for rewards claim
        @param maxRewardClaim: value for maximum reward claim */
    function setMaxRewardClaim(uint256 maxRewardClaim) external;

    // --- From storage variables ---

    /** @notice reads nextConditionId public storage variable 
        @return uint256 value for the next condition ID */
    function getNextConditionId() external view returns (uint256);

    // /** @notice reads totalScore public storage variable
    //     @return uint256 value for the sum of scores from all CreatorsPRO users */
    // function totalScore() external view returns (uint256);

    /** @notice reads usersArray public storage array 
        @param index: index of the array
        @return address of a user */
    function getUsersArray(uint256 index) external view returns (address);

    /** @notice reads collectionIndex public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 value for the collection index in User struct */
    function getCollectionIndex(
        address user,
        address collection
    ) external view returns (uint256);

    /** @notice reads tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @param index: index value for token IDs array
        @return uint256 value for the token ID  */
    function getTokenIdsPerUser(
        address user,
        address collection,
        uint256 index
    ) external view returns (uint256);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads hashObjects public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection
        @return uint256 values for hashpower and characterist ID */
    function getHashObject(
        address collection,
        uint256 tokenId
    ) external view returns (uint256, uint256);

    /** @notice reads tokenInfo public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection 
        @return TokenInfo struct with token infos */
    function getTokenInfo(
        address collection,
        uint256 tokenId
    ) external view returns (TokenInfo memory);

    /** @notice reads users public storage mapping 
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUser(address user) external view returns (User memory);

    /** @notice reads users public storage mapping, but the values are updated
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUserUpdated(address user) external view returns (User memory);

    /** @notice reads rewardCondition public storage mapping 
        @return RewardCondition struct with current reward condition info */
    function getCurrentRewardCondition()
        external
        view
        returns (RewardCondition memory);

    /** @notice reads rewardCondition public storage mapping 
        @param conditionId: condition ID
        @return RewardCondition struct with reward condition info */
    function getRewardCondition(
        uint256 conditionId
    ) external view returns (RewardCondition memory);

    /** @notice reads all token IDs from the array of tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 array for the token IDs  */
    function getAllTokenIdsPerUser(
        address user,
        address collection
    ) external view returns (uint256[] memory);

    /** @notice reads interacPointsPrecision storage variable
        @return uint256[3] array with interaction points precision values */
    function getInteracPointsPrecision()
        external
        view
        returns (uint256[3] memory);

    /** @notice reads maxRewardClaim storage variable
        @return uint256 value for maximum allowed rewards claim */
    function getMaxRewardClaim() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC20 burnable contract */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Metadata} from "../@openzeppelin/token/IERC20Metadata.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC20Burnable is IERC20Metadata {
    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @notice mints given amount of tokens to given address.       
        @param to: address for which tokens will be minted.
        @param amount: amount of tokens to mint .
        @return bool that specifies if mint was successful (true) or not (false). */
    function mint(address to, uint256 amount) external returns (bool);

    /** @notice burns given amount tokens from given account address.      
        @param account: account address from which tokens will be burned
        @param amount: amount of tokens to burn
        @return bool that specifies if tokens burn was successful (true) or not (false) */
    function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC721Art {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the collection max supply is reached (when maxSupply > 0)
    error ERC721Art__MaxSupplyReached();

    ///@dev error for when the value sent or the allowance is not enough to mint/buy token
    error ERC721Art__NotEnoughValueOrAllowance();

    ///@dev error for when caller is neighter manager nor collection creator
    error ERC721Art__NotAllowed();

    ///@dev error for when caller is not token owner
    error ERC721Art__NotTokenOwner();

    ///@dev error for when collection is for a crowdfund
    error ERC721Art__CollectionForFund();

    ///@dev error for when an invalid crowdfund address is set
    error ERC721Art__InvalidCrowdFund();

    ///@dev error for when the caller is not the crowdfund contract
    error ERC721Art__CallerNotCrowdfund();

    ///@dev error for when a crowfund address is already set
    error ERC721Art__CrodFundIsSet();

    ///@dev error for when input arrays don't have same length
    error ERC721Art__ArraysDoNotMatch();

    ///@dev error for when an invalid ERC20 contract address is given
    error ERC721Art__InvalidAddress();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new mint price is set.
        @param newPrice: new mint price 
        @param coin: token/coin of transfer */
    event PriceSet(uint256 indexed newPrice, IManagement.Coin indexed coin);

    /** @dev event for when owner sets new price for his/her token.
        @param tokenId: ID of ERC721 token
        @param price: new token price
        @param coin: token/coin of transfer */
    event TokenPriceSet(
        uint256 indexed tokenId,
        uint256 price,
        IManagement.Coin indexed coin
    );

    /** @dev event for when royalties transfers are done (mint).
        @param tokenId: ID of ERC721 token
        @param creatorsProRoyalty: royalty to CreatorsPRO
        @param creatorRoyalty: royalty to collection creator 
        @param fromWallet: address from which the payments was made */
    event RoyaltiesTransferred(
        uint256 indexed tokenId,
        uint256 creatorsProRoyalty,
        uint256 creatorRoyalty,
        address fromWallet
    );

    /** @dev event for when owner payments are done (creatorsProSafeTransferFrom).
        @param tokenId: ID of ERC721 token
        @param owner: owner address
        @param amount: amount transferred */
    event OwnerPaymentDone(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 amount
    );

    /** @dev event for when a new royalty fee is set
        @param _royalty: new royalty fee value */
    event RoyaltySet(uint256 _royalty);

    /** @dev event for when a new crowdfund address is set
        @param _crowdfund: address from crowdfund */
    event CrowdfundSet(address indexed _crowdfund);

    /** @dev event for when a new max discount for an ERC20 contract is set
        @param token: ERC20 contract address
        @param discount: discount value */
    event MaxDiscountSet(address indexed token, uint256 discount);

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /** @notice event for when a new coreSFT address is set
        @param caller: function's caller address
        @param _coreSFT: new address for the SFT protocol */
    event NewCoreSFTSet(address indexed caller, address _coreSFT);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param name_: name of the NFT collection
        @param symbol_: symbol of the NFT collection
        @param owner_: collection owner/creator
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price_: mint price of a single NFT
        @param priceInUSD: mint price of a single NFT
        @param priceInCreatorsCoin: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
            (final value = _royalty / 10000 (ERC2981Upgradeable._feeDenominator())) */
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 maxSupply,
        uint256 price_,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice mints given the NFT of given tokenId, using the given coin for transfer. Payable function.
        @param tokenId: tokenId to be minted 
        @param coin: token/coin of transfer 
        @param discount: discount given for NFT mint */
    function mint(
        uint256 tokenId,
        IManagement.Coin coin,
        uint256 discount
    ) external payable;

    /** @notice mints NFT of the given tokenId to the given address
        @param to: address to which the ticket is going to be minted
        @param tokenId: tokenId (batch) of the ticket to be minted */
    function mintToAddress(address to, uint256 tokenId) external;

    /** @notice mints token for crowdfunding        
        @param tokenIds: array of token IDs to mint
        @param classes: array of classes 
        @param to: address from tokens owner */
    function mintForCrowdfund(
        uint256[] memory tokenIds,
        uint8[] memory classes,
        address to
    ) external;

    /** @notice burns NFT of the given tokenId.
        @param tokenId: token ID to be burned */
    function burn(uint256 tokenId) external;

    /** @notice safeTransferFrom function especifically for CreatorPRO. It enforces (onchain) the transfer of the 
        correct token price. Payable function.
        @param coin: which coin to use (0 => ETH, 1 => USD, 2 => CreatorsCoin)
        The other parameters are the same from safeTransferFrom function. */
    function creatorsProSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        IManagement.Coin coin
    ) external payable;

    /** @notice sets NFT mint price.
        @param price: new NFT mint price 
        @param coin: coin/token to be set */
    function setPrice(uint256 price, IManagement.Coin coin) external;

    /** @notice sets the price of the ginve token ID.
        @param tokenId: ID of token
        @param price: new price to be set 
        @param coin: coin/token to be set */
    function setTokenPrice(
        uint256 tokenId,
        uint256 price,
        IManagement.Coin coin
    ) external;

    /** @notice sets new base URI for the collection.
        @param uri: new base URI to be set */
    function setBaseURI(string memory uri) external;

    /** @notice sets new royaly value for NFT transfer
        @param royalty: new value for royalty */
    function setRoyalty(uint256 royalty) external;

    /** @notice sets the crowdfund address 
        @param crowdfund: crowdfund contract address */
    function setCrowdfund(address crowdfund) external;

    /** @notice sets maxDiscount mapping for given ERC20 address
        @param token: ERC20 contract address
        @param maxDiscount_: max discount value */
    function setMaxDiscount(address token, uint256 maxDiscount_) external;

    /** @notice sets new coreSFT address
        @param coreSFT_: new address for the SFT protocol */
    function setCoreSFT(address coreSFT_) external;

    /** @notice gets the price of mint for the given address
        @param token: ERC20 token contract address 
        @return uint256 price value in the given ERC20 token */
    function price(address token) external view returns (uint256);

    /** @notice withdraws funds to given address
        @param receiver: fund receiver address
        @param amount: amount to withdraw */
    function withdrawToAddress(address receiver, uint256 amount) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- From storage variables ---

    /** @notice reads maxSupply public storage variable
        @return uint256 value of maximum supply */
    function getMaxSupply() external view returns (uint256);

    /** @notice reads baseURI public storage variable 
        @return string of the base URI */
    function getBaseURI() external view returns (string memory);

    /** @notice reads price public storage mapping
        @param coin: coin/token for price
        @return uint256 value for price */
    function getPricePerCoin(
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads lastTransfer public storage mapping 
        @param tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function getLastTransfer(uint256 tokenId) external view returns (uint256);

    /** @notice reads tokenPrice public storage mapping 
        @param tokenId: ID of the token
        @param coin: coin/token for specific token price 
        @return uint256 value for price of specific token */
    function getTokenPrice(
        uint256 tokenId,
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads crowdfund public storage variable 
        @return address of the set crowdfund contract */
    function getCrowdfund() external view returns (address);

    /** @notice reads maxDiscountPerCoin public storage mapping by address
        @param token: ERC20 contract address
        @return uint256 for the max discount of the SFTRec protocol */
    function maxDiscount(address token) external view returns (uint256);

    /** @notice gets the royalty info (address and value) from ERC2981
        @return royalty receiver address and value */
    function getRoyalty() external view returns (address, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the management contract from CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Burnable} from "./IERC20Burnable.sol";
import {ICRPReward} from "./ICRPReward.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IManagement {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error Management__NotAllowed();

    ///@dev error for when collection name is invalid
    error Management__InvalidName();

    ///@dev error for when collection symbol is invalid
    error Management__InvalidSymbol();

    ///@dev error for when the input is an invalid address
    error Management__InvalidAddress();

    ///@dev error for when the resulting max supply is 0
    error Management__FundMaxSupplyIs0();

    ///@dev error for when a token contract address is set for ETH/MATIC
    error Management__CannotSetAddressForETH();

    ///@dev error for when creator is corrupted
    error Management__CreatorCorrupted();

    ///@dev error for when an invalid collection address is given
    error Management__InvalidCollection();

    ///@dev error for when not the collection creator address calls function
    error Management__NotCollectionCreator();

    ///@dev error for when given address is not allowed creator
    error Management__AddressNotCreator();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the coin/token of transfer 
        @param ETH_COIN: ETH
        @param USD_TOKEN: a US dollar stablecoin        
        @param CREATORS_TOKEN: ERC20 token from CreatorsPRO
        @param REPUTATION_TOKEN: ERC20 token for reputation */
    enum Coin {
        ETH_COIN,
        USD_TOKEN,
        CREATORS_TOKEN,
        REPUTATION_TOKEN
    }

    /** @dev struct to be used as imput parameter that comprises with values for
    setting the crowdfunding contract   
        @param valuesLowQuota: array of values for the low class quota in ETH, USD token, and CreatorsPRO token
        @param valuesRegQuota: array of values for the regular class quota in ETH, USD token, and CreatorsPRO token 
        @param valuesHighQuota: array of values for the high class quota in ETH, USD token, and CreatorsPRO token 
        @param amountLowQuota: amount of low class quotas available 
        @param amountRegQuota: amount of low regular quotas available
        @param amountHighQuota: amount of low high quotas available 
        @param donationReceiver: address for the donation receiver 
        @param donationFee: fee value for the donation
        @param minSoldRate: minimum rate of sold quotas */
    struct CrowdFundParams {
        uint256[3] valuesLowQuota;
        uint256[3] valuesRegQuota;
        uint256[3] valuesHighQuota;
        uint256 amountLowQuota;
        uint256 amountRegQuota;
        uint256 amountHighQuota;
        address donationReceiver;
        uint256 donationFee;
        uint256 minSoldRate;
    }

    /** @dev struct used for store creators info
        @param escrow: escrow address for a creator
        @param isAllowed: defines if address is an allowed creator (true) or not (false) */
    struct Creator {
        address escrow;
        bool isAllowed;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new ERC721 art collection is instantiated
        @param collection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event ArtCollection(
        address indexed collection,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a new ERC721 crowdfund collection is instantiated
        @param fundCollection: new ERC721 crowdfund collection address
        @param artCollection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event Crowdfund(
        address indexed fundCollection,
        address indexed artCollection,
        address indexed creator,
        address caller
    );

    /** @dev event for when a new ERC721 collection from CreatorsPRO staff is instantiated
        @param collection: new ERC721 address
        @param creator: creator address of the ERC721 collection */
    event CreatorsCollection(
        address indexed collection,
        address indexed creator
    );

    /** @dev event for when a creator address is set
        @param creator: the creator address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event CreatorSet(
        address indexed creator,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new beacon admin address for ERC721 art collection contract is set
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminArt(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 crowdfund collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminFund(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 CreatorsPRO collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminCreators(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new multisig wallet address is set
        @param multisig: new multisig wallet address
        @param manager: the manager address that has done the setting */
    event NewMultiSig(address indexed multisig, address indexed manager);

    /** @dev event for when a new royalty fee is set
        @param newFee: new royalty fee
        @param manager: the manager address that has done the setting */
    event NewFee(uint256 indexed newFee, address indexed manager);

    /** @dev event for when a creator address is set
        @param setManager: the manager address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event ManagerSet(
        address indexed setManager,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new token contract address is set
        @param manager: address of the manager that has set the hash object
        @param token: address of the token contract 
        @param coin: coin/token of the contract */
    event TokenContractSet(
        address indexed manager,
        address indexed token,
        Coin coin
    );

    /** @dev event for when a new ERC721 staking contract is instantiated
        @param staking: new ERC721 staking contract address
        @param creator: contract creator address 
        @param caller: caller address of the function */
    event CRPStaking(
        address indexed staking,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a creator's address is set to corrupted (true) or not (false) 
        @param manager: maanger's address
        @param creator: creator's address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    event CorruptedAddressSet(
        address indexed manager,
        address indexed creator,
        bool corrupted
    );

    /** @dev event for when a new beacon admin address for ERC721 staking contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminStaking(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new proxy address for reward contract is set 
        @param proxy: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewProxyReward(address indexed proxy, address indexed manager);

    /** @dev event for when a CreatorsPRO collection is set
        @param collection: collection address
        @param set: true if collection is from CreatorsPRO, false otherwise */
    event CollectionSet(address indexed collection, bool set);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @dev smart contract's initializer/constructor.
        @param beaconAdminArt: address of the beacon admin for the creators ERC721 art smart contract 
        @param beaconAdminFund: address of the beacon admin for the creators ERC721 fund smart contract
        @param beaconAdminCreators: address of the beacon admin for the CreatorPRO ERC721 smart contract 
        @param erc20USD: address of a stablecoin contract (USDC/USDT/DAI)
        @param multiSig: address of the Multisig smart contract
        @param fee: royalty fee */
    function initialize(
        address beaconAdminArt,
        address beaconAdminFund,
        address beaconAdminCreators,
        address erc20USD,
        address multiSig,
        uint256 fee
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
        @param owner: owner address of the collection */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty,
        address owner
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param owner: owner address of the collection
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        address owner,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new CreatorPRO NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata */
    function newCreatorsCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSDC,
        uint256 priceInCreatorsCoin,
        string memory baseURI
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward
        @param owner: owner address of the collection */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime,
        address owner
    ) external;

    // --- Setter functions ---

    /** @notice sets creator permission.
        @param creator: creator address
        @param allowed: boolean that specifies if creator address has permission (true) or not (false) */
    function setCreator(address creator, bool allowed) external;

    /** @notice sets manager permission.
        @param manager: manager address
        @param allowed: boolean that specifies if manager address has permission (true) or not (false) */
    function setManager(address manager, bool allowed) external;

    /** @notice sets new beacon admin address for the creators ERC721 art smart contract.
        @param beacon: new address */
    function setBeaconAdminArt(address beacon) external;

    /** @notice sets new beacon admin address for the creators ERC721 fund smart contract.
        @param beacon: new address */
    function setBeaconAdminFund(address beacon) external;

    /** @notice sets new beacon admin address for the CreatorPRO ERC721 smart contract.
        @param beacon: new address */
    function setBeaconAdminCreators(address beacon) external;

    /** @notice sets new address for the Multisig smart contract.
        @param multisig: new address */
    function setMultiSig(address multisig) external;

    /** @notice sets new fee for NFT minting.
        @param fee: new fee */
    function setFee(uint256 fee) external;

    /** @notice sets new contract address for the given token 
        @param coin: coin/token for the given contract address
        @param token: new address of the token contract */
    function setTokenContract(Coin coin, address token) external;

    /** @notice sets given creator address to corrupted (true) or not (false)
        @param creator: creator address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    function setCorrupted(address creator, bool corrupted) external;

    /** @notice sets new beacon admin address for the ERC721 staking smart contract.
        @param beacon: new address */
    function setBeaconAdminStaking(address beacon) external;

    /** @notice sets new proxy address for the reward smart contract.
        @param proxy: new address */
    function setProxyReward(address proxy) external;

    /** @notice sets new collection address
        @param collection: collection address
        @param set: true (collection from CreatorsPRO) or false */
    function setCollections(address collection, bool set) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- Getter functions ---

    // --- From storage variables ---

    /** @notice reads beaconAdminArt storage variable
        @return address of the beacon admin for the art collection (ERC721) contract */
    function getBeaconAdminArt() external view returns (address);

    /** @notice reads beaconAdminFund storage variable
        @return address of the beacon admin for the crowdfund (ERC721) contract */
    function getBeaconAdminFund() external view returns (address);

    /** @notice reads beaconAdminCreators storage variable
        @return address of the beacon admin for the CreatorsPRO collection (ERC721) contract */
    function getBeaconAdminCreators() external view returns (address);

    /** @notice reads beaconAdminStaking storage variable
        @return address of the beacon admin for staking contract */
    function getBeaconAdminStaking() external view returns (address);

    /** @notice reads proxyReward storage variable
        @return address of the beacon admin for staking contract */
    function getProxyReward() external view returns (ICRPReward);

    /** @notice reads multiSig storage variable 
        @return address of the multisig wallet */
    function getMultiSig() external view returns (address);

    /** @notice reads fee storage variable 
        @return the royalty fee */
    function getFee() external view returns (uint256);

    /** @notice reads managers storage mapping
        @param caller: address to check if is manager
        @return boolean if the given address is a manager */
    function getManagers(address caller) external view returns (bool);

    /** @notice reads tokenContract storage mapping
        @param coin: coin/token for the contract address
        @return IERC20 instance for the given coin/token */
    function getTokenContract(Coin coin) external view returns (IERC20Burnable);

    /** @notice reads isCorrupted storage mapping 
        @param creator: creator address
        @return bool that sepcifies if creator is corrupted (true) or not (false) */
    function getIsCorrupted(address creator) external view returns (bool);

    /** @notice reads collections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if collection is from CreatorsPRO (true) or not (false)  */
    function getCollections(address collection) external view returns (bool);

    /** @notice reads stakingCollections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if staking collection is from CreatorsPRO (true) or not (false)  */
    function getStakingCollections(
        address collection
    ) external view returns (bool);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads creators storage mapping
        @param caller: address to check if is allowed creator
        @return Creator struct with creator info */
    function getCreator(address caller) external view returns (Creator memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Security settings for upgradeable smart contracts */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IManagement} from "./interfaces/IManagement.sol";

///@dev security settings.
import {Initializable} from "./@openzeppelin/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "./@openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "./@openzeppelin/upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "./@openzeppelin/upgradeable/security/PausableUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Errors
/// -----------------------------------------------------------------------

///@dev error for when the crowdfund has past due data
error SecurityUpgradeable__NotAllowed();

///@dev error for when the collection/creator has been corrupted
error SecurityUpgradeable__CollectionOrCreatorCorrupted();

///@dev error for when ETH/MATIC transfer fails
error SecurityUpgradeable__TransferFailed();

///@dev error for when ERC20 transfer fails
error SecurityUpgradeable__ERC20TransferFailed();

///@dev error for when ERC20 mint fails
error SecurityUpgradeable__ERC20MintFailed();

///@dev error for when an invalid coin is used
error SecurityUpgradeable__InvalidCoin();

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract SecurityUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    ///@dev Management contract
    IManagement internal s_management;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    ///@dev internal function for whenNotPaused modifier
    function _whenNotPaused() internal view whenNotPaused {}

    ///@dev internal function for nonReentrant modifier
    function _nonReentrant() internal nonReentrant {}

    ///@dev internal function for onlyOwner modifier
    function _onlyOwner() internal view onlyOwner {}

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    function _onlyManagers() internal view virtual {
        if (!s_management.getManagers(msg.sender)) {
            revert SecurityUpgradeable__NotAllowed();
        }
    }

    ///@dev checks if caller is authorized
    function _onlyAuthorized() internal view virtual {
        if (!s_management.getIsCorrupted(owner())) {
            if (
                !(s_management.getManagers(msg.sender) ||
                    msg.sender == address(s_management) ||
                    msg.sender == owner())
            ) {
                revert SecurityUpgradeable__NotAllowed();
            }
        } else {
            if (
                !(s_management.getManagers(msg.sender) ||
                    msg.sender == address(s_management))
            ) {
                revert SecurityUpgradeable__NotAllowed();
            }
        }
    }

    ///@dev checks if collection/creator is corrupted
    function _notCorrupted() internal view virtual {
        if (s_management.getIsCorrupted(owner())) {
            revert SecurityUpgradeable__CollectionOrCreatorCorrupted();
        }
    }

    ///@dev checks if used coin is valid
    function _onlyValidCoin(IManagement.Coin coin) internal pure virtual {
        if (coin == IManagement.Coin.REPUTATION_TOKEN) {
            revert SecurityUpgradeable__InvalidCoin();
        }
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @dev initiates all security dependencies. Uses onlyInitializing modifier.
        @param owner_: address of contract owner */
    function _SecurityUpgradeable_init(
        address owner_
    ) internal onlyInitializing {
        __Ownable_init();
        transferOwnership(owner_);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // --- Pause and Unpause functions ---

    /** @notice pauses the contract so that functions cannot be executed.
        Uses _pause internal function from PausableUpgradeable. */
    function pause() public virtual {
        _nonReentrant();

        _pause();
    }

    /** @notice unpauses the contract so that functions can be executed        
        Uses _pause internal function from PausableUpgradeable. */
    function unpause() public virtual {
        _nonReentrant();

        _unpause();
    }

    // --- Implemented functions ---

    /** @notice performs ETH/MATIC transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferTo(address to, uint256 amount) internal virtual {
        (bool success, ) = payable(to).call{value: amount}("");

        if (!success) {
            revert SecurityUpgradeable__TransferFailed();
        }
    }

    /** @notice performs ERC20 transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param coin: ERC20 coin to transfer
        @param from: transfer sender address
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferERC20To(
        IManagement.Coin coin,
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (coin == IManagement.Coin.ETH_COIN) {
            revert SecurityUpgradeable__InvalidCoin();
        }

        bool success;
        if (from == address(this)) {
            success = s_management.getTokenContract(coin).transfer(to, amount);
        } else {
            success = s_management.getTokenContract(coin).transferFrom(
                from,
                to,
                amount
            );
        }

        if (!success) {
            revert SecurityUpgradeable__ERC20TransferFailed();
        }
    }

    /** @notice performs ERC20 mint using the call low-level function. It reverts if
        mint fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param coin: ERC20 coin to mint
        @param to: mint receiver address
        @param amount: amount to mint */
    function _mintERC20Token(
        IManagement.Coin coin,
        address to,
        uint256 amount
    ) internal {
        if (coin == IManagement.Coin.ETH_COIN) {
            revert SecurityUpgradeable__InvalidCoin();
        }

        bool success = s_management.getTokenContract(coin).mint(to, amount);

        if (!success) {
            revert SecurityUpgradeable__ERC20MintFailed();
        }
    }

    /** @notice reads management public storage variable 
        @return IManagement instance of Management interface */
    function getManagement() external view returns (IManagement) {
        return s_management;
    }
}