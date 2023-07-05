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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Staking for NFTArt after fundraising with supporters of the Dreamfunding contract CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IManagement} from "./interfaces/IManagement.sol";
import {ICRPStaking} from "./interfaces/ICRPStaking.sol";
import {ICrowdfund} from "./interfaces/ICrowdfund.sol";

///@dev ERC721 token standard.
import {IERC721ArtHandle} from "./interfaces/IERC721ArtHandle.sol";

///@dev security settings.
import {SecurityUpgradeable, OwnableUpgradeable} from "./SecurityUpgradeable.sol";

///@dev implementation helpers
import {SafeMath} from "./@openzeppelin/utils/math/SafeMath.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract CRPStaking is ICRPStaking, SecurityUpgradeable {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    ///@dev Address of ERC721 NFT contract -- staked tokens belong to this contract.
    IERC721ArtHandle private s_stakingToken;

    ///@dev Flag to check direct transfers of staking tokens.
    uint8 private s_isStaking = 1;

    ///@dev Next staking condition Id. Tracks number of conditon updates so far.
    uint256 private s_nextConditionId;

    ///@dev Sum of split factos of all stakers
    uint256 private s_totalSplitFactor;

    ///@dev List of token-ids ever staked.
    uint256[] private s_indexedTokens;

    ///@dev List of accounts that have staked their NFTs.
    address[] private s_stakersArray;

    ///@dev Mapping from token-id to whether it is indexed or not.
    mapping(uint256 tokenId => bool isIndexed) private s_isIndexed;

    ///@dev Mapping from staker address to Staker struct. See {struct ICRPStaking.Staker}.
    mapping(address staker => Staker info) private s_stakers;

    ///@dev Mapping from staked token-id to staker address.
    mapping(uint256 tokenId => address staker) private s_stakerAddress;

    ///@dev Mapping from condition Id to staking condition. See {struct ICRPStaking.StakingCondition}
    mapping(uint256 conditionId => StakingCondition info)
        private s_stakingConditions;

    ///@dev amount of quotas (tokens) for each class
    mapping(ICrowdfund.QuotaClass class => uint256 amount)
        private s_classAmounts;

    ///@dev mapping that specifies the total split factor for each staker
    mapping(address staker => uint256 splitFactor) private s_splitFactor;

    ///@dev mapping that specifies amount of USD token unclaimed for each staker
    mapping(address staler => uint256 amountOfUnclaimedUSD)
        private s_unclaimedUSD;

    ///constants
    uint256 private constant CREATORS_PRO_ROYALTY = 500; //  royalty from CreatorsPRO = 5% (over 10000)
    uint256 private constant RATIO_DENOMINATOR = 10000;
    uint256 private constant MIN_TIMEUNIT = 30 days;
    uint8 private constant LOW_CLASS_POINT = 1;
    uint8 private constant REGULAR_CLASS_POINT = 2;
    uint8 private constant HIGH_CLASS_POINT = 3;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external initializer {
        if (stakingToken == address(0)) {
            revert CRPStaking__TokenAddressZero();
        }

        if (IERC721ArtHandle(stakingToken).getCrowdfund() == address(0)) {
            revert CRPStaking__NotCrowdfundingToken();
        }

        _SecurityUpgradeable_init(OwnableUpgradeable(stakingToken).owner());

        s_stakingToken = IERC721ArtHandle(stakingToken);
        s_management = IManagement(msg.sender);
        ICrowdfund cf = ICrowdfund(s_stakingToken.getCrowdfund());

        s_classAmounts[ICrowdfund.QuotaClass.LOW] = cf
            .getQuotaInfos(ICrowdfund.QuotaClass.LOW)
            .amount;
        s_classAmounts[ICrowdfund.QuotaClass.REGULAR] = cf
            .getQuotaInfos(ICrowdfund.QuotaClass.REGULAR)
            .amount;
        s_classAmounts[ICrowdfund.QuotaClass.HIGH] = cf
            .getQuotaInfos(ICrowdfund.QuotaClass.HIGH)
            .amount;

        setStakingCondition(timeUnit, rewardsPerUnitTime);
    }

    /// -----------------------------------------------------------------------
    /// Implemented functions
    /// -----------------------------------------------------------------------

    /** @dev nonReetrant and whenNotPaused third parties modifiers. */
    /// @inheritdoc ICRPStaking
    function stake(uint256[] calldata tokenIds) external override(ICRPStaking) {
        _nonReentrant();
        _whenNotPaused();

        uint256 len = tokenIds.length;
        if (len == 0) {
            revert CRPStaking__NoTokensGiven();
        }

        IERC721ArtHandle stakingToken = s_stakingToken;
        uint256 amountLow = s_classAmounts[ICrowdfund.QuotaClass.LOW];
        uint256 amountReg = s_classAmounts[ICrowdfund.QuotaClass.REGULAR];
        uint256 amountHigh = s_classAmounts[ICrowdfund.QuotaClass.HIGH];

        if (
            s_stakers[msg.sender].amountStaked[0] > 0 ||
            s_stakers[msg.sender].amountStaked[1] > 0 ||
            s_stakers[msg.sender].amountStaked[2] > 0
        ) {
            _updateUnclaimedRewardsForStaker(msg.sender);
        } else {
            s_stakersArray.push(msg.sender);
            s_stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            s_stakers[msg.sender].conditionIdOflastUpdate =
                s_nextConditionId -
                1;
        }

        uint256[] memory amount = new uint256[](3);
        uint256 splitFactor;
        for (uint256 i = 0; i < len; ++i) {
            if (
                !(stakingToken.ownerOf(tokenIds[i]) == msg.sender &&
                    (stakingToken.getApproved(tokenIds[i]) == address(this) ||
                        stakingToken.isApprovedForAll(
                            msg.sender,
                            address(this)
                        )))
            ) {
                revert CRPStaking__NotTokenOwnerOrApproved();
            }

            s_isStaking = 2;
            stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            s_isStaking = 1;

            s_stakerAddress[tokenIds[i]] = msg.sender;

            if (!s_isIndexed[tokenIds[i]]) {
                s_isIndexed[tokenIds[i]] = true;
                s_indexedTokens.push(tokenIds[i]);
            }

            if (tokenIds[i] < amountLow) {
                amount[0]++;
                splitFactor += LOW_CLASS_POINT;
            } else if (tokenIds[i] < amountLow + amountReg) {
                amount[1]++;
                splitFactor += REGULAR_CLASS_POINT;
            } else if (tokenIds[i] < amountLow + amountReg + amountHigh) {
                amount[2]++;
                splitFactor += HIGH_CLASS_POINT;
            } else {
                revert CRPStaking__TokenIDOutOfTier();
            }
        }
        s_stakers[msg.sender].amountStaked[0] += amount[0];
        s_stakers[msg.sender].amountStaked[1] += amount[1];
        s_stakers[msg.sender].amountStaked[2] += amount[2];

        s_totalSplitFactor += splitFactor;
        s_splitFactor[msg.sender] += splitFactor;

        emit TokensStaked(msg.sender, tokenIds);
    }

    /** @dev nonReetrant and whenNotPaused third parties modifiers. */
    /// @inheritdoc ICRPStaking
    function withdraw(
        uint256[] calldata tokenIds
    ) external override(ICRPStaking) {
        _nonReentrant();
        _whenNotPaused();

        uint256 rewards = s_stakers[msg.sender].unclaimedRewards +
            _calculateRewards(msg.sender);

        _claimRewards(msg.sender, rewards);
        _claimUSD(msg.sender);
        _withdraw(msg.sender, tokenIds);

        emit TokensWithdrawn(msg.sender, tokenIds);
    }

    /** @dev nonReetrant and whenNotPaused third parties modifiers. */
    /// @inheritdoc ICRPStaking
    function withdrawToAddress(
        address staker,
        uint256[] calldata tokenIds
    ) external override(ICRPStaking) {
        _nonReentrant();
        _onlyAuthorized();

        uint256 rewards = s_stakers[staker].unclaimedRewards +
            _calculateRewards(staker);

        _claimRewards(staker, rewards);
        _claimUSD(staker);
        _withdraw(staker, tokenIds);

        emit WithdrawnToAddress(msg.sender, staker, tokenIds);
    }

    /** @dev nonReetrant and whenNotPaused third parties modifiers. */
    /// @inheritdoc ICRPStaking
    function claimRewards() external override(ICRPStaking) {
        _nonReentrant();
        _whenNotPaused();

        uint256 rewards = s_stakers[msg.sender].unclaimedRewards +
            _calculateRewards(msg.sender);

        if (rewards == 0) {
            revert CRPStaking__NoRewards();
        }

        uint256 creatorsRoyalty = _claimRewards(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards - creatorsRoyalty);
    }

    /** @dev nonReetrant and whenNotPaused third parties modifiers. */
    /// @inheritdoc ICRPStaking
    function splitUSD(
        address from,
        uint256 amount
    ) external override(ICRPStaking) {
        _nonReentrant();
        _whenNotPaused();
        _onlyAuthorized();

        _transferERC20To(
            IManagement.Coin.USD_TOKEN,
            from,
            address(this),
            amount
        );

        address[] memory _stakers = s_stakersArray;
        uint256 _totalSplitFactor = s_totalSplitFactor;
        for (uint256 ii; ii < _stakers.length; ++ii) {
            s_unclaimedUSD[_stakers[ii]] =
                (amount * s_splitFactor[_stakers[ii]]) /
                _totalSplitFactor;
        }

        emit USDTokenSplitted(msg.sender, amount);
    }

    /** @dev nonReetrant and whenNotPaused third parties modifiers. */
    /// @inheritdoc ICRPStaking
    function claimUSD() external override(ICRPStaking) {
        _nonReentrant();
        _whenNotPaused();

        (uint256 amount, uint256 creatorsRoyalty) = _claimUSD(msg.sender);

        emit USDTokenClaimed(msg.sender, amount - creatorsRoyalty);
    }

    // --- Setter functions ---

    /** @dev nonReetrant and whenNotPaused third parties modifiers. Only authorized addresses can call
    this function. */
    /// @inheritdoc ICRPStaking
    function setStakingCondition(
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) public override(ICRPStaking) {
        _nonReentrant();
        _onlyAuthorized();
        _whenNotPaused();

        if (timeUnit < MIN_TIMEUNIT) {
            revert CRPStaking__InvalidTimeUnit();
        }

        uint256 conditionId = s_nextConditionId;
        s_nextConditionId += 1;

        s_stakingConditions[conditionId] = StakingCondition({
            timeUnit: timeUnit,
            rewardsPerUnitTime: rewardsPerUnitTime,
            startTimestamp: block.timestamp,
            endTimestamp: 0
        });

        if (conditionId > 0) {
            s_stakingConditions[conditionId - 1].endTimestamp = block.timestamp;
        }

        emit StakingConditionSet(conditionId, timeUnit, rewardsPerUnitTime);
    }

    // --- Pause and Unpause functions ---

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc SecurityUpgradeable
    function pause() public override(SecurityUpgradeable) {
        _onlyAuthorized();

        SecurityUpgradeable.pause();
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc SecurityUpgradeable
    function unpause() public override(SecurityUpgradeable) {
        _onlyAuthorized();

        SecurityUpgradeable.unpause();
    }

    /** @dev won't work if not for staking */
    /// @inheritdoc ICRPStaking
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override(ICRPStaking) returns (bytes4) {
        if (s_isStaking != 2) {
            revert CRPStaking__DirectERC721TokenTransfer();
        }

        return this.onERC721Received.selector;
    }

    // --- Internal functions ---

    /// @dev update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(address staker) internal virtual {
        uint256 rewards = _calculateRewards(staker);
        if (rewards > 0) {
            s_stakers[staker].unclaimedRewards += rewards;
            s_stakers[staker].timeOfLastUpdate = block.timestamp;
            s_stakers[staker].conditionIdOflastUpdate = s_nextConditionId - 1;
        }
    }

    /// @dev calculate rewards for a staker.
    function _calculateRewards(
        address staker
    ) internal view virtual returns (uint256 rewards) {
        Staker memory m_staker = s_stakers[staker];

        uint256 stakerConditionId = m_staker.conditionIdOflastUpdate;
        uint256 nextConditionId = s_nextConditionId;

        for (uint256 i = stakerConditionId; i < nextConditionId; ++i) {
            StakingCondition memory condition = s_stakingConditions[i];

            uint256 startTime = i != stakerConditionId
                ? condition.startTimestamp
                : m_staker.timeOfLastUpdate;
            uint256 endTime = condition.endTimestamp != 0
                ? condition.endTimestamp
                : block.timestamp;

            if ((endTime - startTime) / condition.timeUnit > 0) {
                for (uint8 j = 0; j < 3; ++j) {
                    (bool noOverflowProduct, uint256 rewardsProduct) = SafeMath
                        .tryMul(
                            (endTime - startTime) * m_staker.amountStaked[j],
                            condition.rewardsPerUnitTime[j]
                        );
                    (bool noOverflowSum, uint256 rewardsSum) = SafeMath.tryAdd(
                        rewards,
                        rewardsProduct / condition.timeUnit
                    );

                    rewards = noOverflowProduct && noOverflowSum
                        ? rewardsSum
                        : rewards;
                }
            }
        }
    }

    /** @dev performs the staking withdrawal computations
        @param staker: staker address
        @param tokenIds: array of token IDs to withdraw */
    function _withdraw(address staker, uint256[] calldata tokenIds) internal {
        uint256[3] memory amountStaked = s_stakers[staker].amountStaked;
        uint256 len = tokenIds.length;
        if (len == 0) {
            revert CRPStaking__NoTokensGiven();
        }

        if (amountStaked[0] + amountStaked[1] + amountStaked[2] < len) {
            revert CRPStaking__WithdrawingMoreThanStaked();
        }

        IERC721ArtHandle stakingToken = s_stakingToken;

        _updateUnclaimedRewardsForStaker(staker);

        if (amountStaked[0] + amountStaked[1] + amountStaked[2] == len) {
            address[] memory stakersArray = s_stakersArray;
            for (uint256 i = 0; i < stakersArray.length; ++i) {
                if (stakersArray[i] == staker) {
                    s_stakersArray[i] = stakersArray[stakersArray.length - 1];
                    s_stakersArray.pop();
                    break;
                }
            }
        }

        uint256 amountLow = s_classAmounts[ICrowdfund.QuotaClass.LOW];
        uint256 amountReg = s_classAmounts[ICrowdfund.QuotaClass.REGULAR];
        uint256 amountHigh = s_classAmounts[ICrowdfund.QuotaClass.HIGH];
        uint256[] memory amount = new uint256[](3);
        uint256 splitFactor;
        for (uint256 i = 0; i < len; ++i) {
            if (s_stakerAddress[tokenIds[i]] != staker) {
                revert CRPStaking__NotTokenStaker();
            }
            if (tokenIds[i] < amountLow) {
                amount[0]++;
                splitFactor += LOW_CLASS_POINT;
            } else if (tokenIds[i] < amountLow + amountReg) {
                amount[1]++;
                splitFactor += REGULAR_CLASS_POINT;
            } else if (tokenIds[i] < amountLow + amountReg + amountHigh) {
                amount[2]++;
                splitFactor += HIGH_CLASS_POINT;
            } else {
                revert CRPStaking__TokenIDOutOfTier();
            }
            s_stakerAddress[tokenIds[i]] = address(0);
            stakingToken.safeTransferFrom(address(this), staker, tokenIds[i]);
        }

        s_stakers[staker].amountStaked[0] -= amount[0];
        s_stakers[staker].amountStaked[1] -= amount[1];
        s_stakers[staker].amountStaked[2] -= amount[2];

        s_totalSplitFactor -= splitFactor;
        s_splitFactor[staker] -= splitFactor;
    }

    /** @dev performs the reward claiming computations
        @param staker: staker address 
        @param rewards: amount of rewards to be claimed 
        @return uint256 value for CreatorsPRO royalty amount */
    function _claimRewards(
        address staker,
        uint256 rewards
    ) internal returns (uint256) {
        uint256 creatorsRoyalty = (rewards * CREATORS_PRO_ROYALTY) /
            RATIO_DENOMINATOR; // CreatorsPRO royalty = 5%

        s_stakers[staker].timeOfLastUpdate = block.timestamp;
        s_stakers[staker].unclaimedRewards = 0;
        s_stakers[staker].conditionIdOflastUpdate = s_nextConditionId - 1;

        _mintERC20Token(
            IManagement.Coin.REPUTATION_TOKEN,
            staker,
            rewards - creatorsRoyalty
        );

        return creatorsRoyalty;
    }

    /** @dev performs the USD claiming computations
        @param staker: staker address 
        @return (uint256, uint256) values for amount claimed and CreatorsPRO royalty amount */
    function _claimUSD(address staker) internal returns (uint256, uint256) {
        uint256 amount = s_unclaimedUSD[staker];
        delete s_unclaimedUSD[staker];

        uint256 creatorsRoyalty = (amount * CREATORS_PRO_ROYALTY) /
            RATIO_DENOMINATOR; // CreatorsPRO royalty = 5%

        // CreatorsPRO royalty
        _transferERC20To(
            IManagement.Coin.USD_TOKEN,
            address(this),
            s_management.getMultiSig(),
            creatorsRoyalty
        );

        // user claim
        _transferERC20To(
            IManagement.Coin.USD_TOKEN,
            address(this),
            staker,
            amount - creatorsRoyalty
        );

        return (amount, creatorsRoyalty);
    }

    // --- Getter functions ---

    /// @inheritdoc ICRPStaking
    function getStakingToken()
        external
        view
        override(ICRPStaking)
        returns (IERC721ArtHandle)
    {
        return s_stakingToken;
    }

    /// @inheritdoc ICRPStaking
    function getNextConditionId()
        external
        view
        override(ICRPStaking)
        returns (uint256)
    {
        return s_nextConditionId;
    }

    /// @inheritdoc ICRPStaking
    function getTotalSplitFactor()
        external
        view
        override(ICRPStaking)
        returns (uint256)
    {
        return s_totalSplitFactor;
    }

    /// @inheritdoc ICRPStaking
    function getStakersArray(
        uint256 index
    ) external view override(ICRPStaking) returns (address) {
        return s_stakerAddress[index];
    }

    /// @inheritdoc ICRPStaking
    function getIndexedTokens(
        uint256 index
    ) external view override(ICRPStaking) returns (uint256) {
        return s_indexedTokens[index];
    }

    /// @inheritdoc ICRPStaking
    function getIsIndexed(
        uint256 tokenId
    ) external view override(ICRPStaking) returns (bool) {
        return s_isIndexed[tokenId];
    }

    /// @inheritdoc ICRPStaking
    function getStakerAddress(
        uint256 tokenId
    ) external view override(ICRPStaking) returns (address) {
        return s_stakerAddress[tokenId];
    }

    /// @inheritdoc ICRPStaking
    function getClassAmounts(
        ICrowdfund.QuotaClass class
    ) external view override(ICRPStaking) returns (uint256) {
        return s_classAmounts[class];
    }

    /// @inheritdoc ICRPStaking
    function getSplitFactor(
        address staker
    ) external view override(ICRPStaking) returns (uint256) {
        return s_splitFactor[staker];
    }

    /// @inheritdoc ICRPStaking
    function getUnclaimedUSD(
        address staker
    ) external view override(ICRPStaking) returns (uint256) {
        return s_unclaimedUSD[staker];
    }

    /// @inheritdoc ICRPStaking
    function getAllStakersArray()
        external
        view
        override(ICRPStaking)
        returns (address[] memory)
    {
        return s_stakersArray;
    }

    /// @inheritdoc ICRPStaking
    function getAllIndexedTokens()
        external
        view
        override(ICRPStaking)
        returns (uint256[] memory)
    {
        return s_indexedTokens;
    }

    /// @inheritdoc ICRPStaking
    function getCurrentStakingCondition()
        external
        view
        override(ICRPStaking)
        returns (StakingCondition memory)
    {
        return s_stakingConditions[s_nextConditionId - 1];
    }

    /// @inheritdoc ICRPStaking
    function getStakingCondition(
        uint256 conditionId
    ) external view override(ICRPStaking) returns (StakingCondition memory) {
        return s_stakingConditions[conditionId];
    }

    /// @inheritdoc ICRPStaking
    function getStaker(
        address staker
    ) external view override(ICRPStaking) returns (Staker memory) {
        return s_stakers[staker];
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
    @title Interface for the CRPStaking contract for staking crowdfunding NFTart  */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";
import {IERC721ArtHandle} from "./IERC721ArtHandle.sol";
import {ICrowdfund} from "./ICrowdfund.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICRPStaking {
    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    ///@dev error for when staker attempted to withdraw tokens more than staked
    error CRPStaking__WithdrawingMoreThanStaked();

    ///@dev error for when token IDs array is empty
    error CRPStaking__NoTokensGiven();

    ///@dev error for when given staking token address is 0
    error CRPStaking__TokenAddressZero();

    ///@dev error for when given staking token address is not crowdfunded
    error CRPStaking__NotCrowdfundingToken();

    ///@dev error for when caller is not token owner or contract is not approved
    error CRPStaking__NotTokenOwnerOrApproved();

    ///@dev error for when given token ID doesn't belong to any of the three tiers (LOW, REGULAR, HIGH)
    error CRPStaking__TokenIDOutOfTier();

    ///@dev error for when caller has no rewards left
    error CRPStaking__NoRewards();

    ///@dev error for when given time unit is invalid
    error CRPStaking__InvalidTimeUnit();

    ///@dev error for when a direct ERC721 token transfer attempted (i.e. isStaking != 2)
    error CRPStaking__DirectERC721TokenTransfer();

    ///@dev error for when token ID is not owned by given staker/caller
    error CRPStaking__NotTokenStaker();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev struct to store staker's info
        @param amountStaked: array of staked amount for each token tier (LOW, REGULAR, HIGH)
        @param timeOfLastUpdate: timestamp for the last information update
        @param unclaimedRewards: total amount of rewards still unclaimed
        @param conditionIdOflastUpdate: condition ID for the last update */
    struct Staker {
        uint256[3] amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
    }

    /** @dev struct for staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit) for each token tier (LOW, REGULAR, HIGH)
        @param startTimestamp: timestamp for when the condition begins
        @param endTimestamp: timestamp for when the condition ends */
    struct StakingCondition {
        uint256 timeUnit;
        uint256[3] rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a set of token-ids are staked 
        @param staker: staker address
        @param tokenIds: array of staked token IDs */
    event TokensStaked(address indexed staker, uint256[] indexed tokenIds);

    /** @dev event for when a set of staked token-ids are withdrawn
        @param staker: staker address
        @param tokenIds: array of withdrawn token IDs */
    event TokensWithdrawn(address indexed staker, uint256[] indexed tokenIds);

    /** @dev event for when a staker claims staking rewards 
        @param staker: staker address
        @param rewardAmount: amount of rewards claimed */
    event RewardsClaimed(address indexed staker, uint256 rewardAmount);

    /** @dev event for when USD tokens are splitted between current stakers
        @param depositor: depositor address
        @param amount: total amount of tokens splitted */
    event USDTokenSplitted(address indexed depositor, uint256 amount);

    /** @dev event for when USD tokens are claimed by staker
        @param claimer: claimer address
        @param amount: total amount of tokens claimed */
    event USDTokenClaimed(address indexed claimer, uint256 amount);

    /** @dev event for when a new staking condition is set
        @param _conditionId: new condition ID
        @param _timeUnit: unit of time to be considered when calculating rewards
        @param _rewardsPerUnitTime: array of rewards per time unit (timeUnit) for each token tier (LOW, REGULAR, HIGH) */
    event StakingConditionSet(
        uint256 indexed _conditionId,
        uint256 _timeUnit,
        uint256[3] _rewardsPerUnitTime
    );

    /** @dev event for when a manager withdraws staked token IDs to staker
        @param manager: manager address
        @param staker: staker address
        @param tokenIds: array of withdrawn token IDs */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed staker,
        uint256[] indexed tokenIds
    );

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward */
    function initialize(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external;

    /** @notice stakes the given array of token IDs
        @param tokenIds: array of token IDs to be staked */
    function stake(uint256[] calldata tokenIds) external;

    /** @notice withdraws staked token IDs
        @param tokenIds: array of staked token IDs  */
    function withdraw(uint256[] calldata tokenIds) external;

    /** @notice withdraws staked token IDs for the given staker address
        @param staker: staker address
        @param tokenIds: array of staked token IDs */
    function withdrawToAddress(
        address staker,
        uint256[] calldata tokenIds
    ) external;

    /** @notice claims staking rewards to the caller */
    function claimRewards() external;

    /** @notice splits the given amount of USD token among all current stakers
        @param from: address from which the transfer is done
        @param amount: token amount to be splitted */
    function splitUSD(address from, uint256 amount) external;

    /** @notice claims splitted USD tokens to the caller */
    function claimUSD() external;

    /** @notice sets a new staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit) for each token tier (LOW, REGULAR, HIGH) */
    function setStakingCondition(
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external;

    ///@notice standard function to receive ERC721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4);

    // --- From storage variables ---

    /** @notice reads stakingToken public storage variable
        @return IERC721Art interface instance for the ERC721Art contract */
    function getStakingToken() external view returns (IERC721ArtHandle);

    /** @notice reads nextConditionId public storage variable 
        @return uint256 value for the next condition ID */
    function getNextConditionId() external view returns (uint256);

    /** @notice reads totalSplitFactor public storage variable 
        @return uint256 value for the sum of the split factors from each staker */
    function getTotalSplitFactor() external view returns (uint256);

    /** @notice reads stakersArray public storage array 
        @param index: stakersArray index
        @return address of a staker */
    function getStakersArray(uint256 index) external view returns (address);

    /** @notice reads indexedTokens public storage array 
        @param index: indexedTokens index
        @return uint256 value for the sum of the split factors from each staker */
    function getIndexedTokens(uint256 index) external view returns (uint256);

    /** @notice reads isIndexed public storage mapping 
        @param tokenId: token ID
        @return bool that specifies if given token ID is indexed (true) or not (false) */
    function getIsIndexed(uint256 tokenId) external view returns (bool);

    /** @notice reads stakerAddress public storage mapping 
        @param tokenId: token ID
        @return address from the staker */
    function getStakerAddress(uint256 tokenId) external view returns (address);

    /** @notice reads classAmounts public storage mapping 
        @param class: quota class
        @return uint256 value for the amount of the given quota class */
    function getClassAmounts(
        ICrowdfund.QuotaClass class
    ) external view returns (uint256);

    /** @notice reads splitFactor public storage mapping 
        @param staker: staker address
        @return uint256 value for the split factor of the given address */
    function getSplitFactor(address staker) external view returns (uint256);

    /** @notice reads unclaimedUSD public storage mapping 
        @param staker: staker address
        @return uint256 value for the amount of unclaimed USD tokens */
    function getUnclaimedUSD(address staker) external view returns (uint256);

    /** @notice gets the whole stakersArray storage array 
        @return address array of all current stakers */
    function getAllStakersArray() external view returns (address[] memory);

    /** @notice gets all the token IDs ever staked
        @return uint256 array of all ever staked token IDs */
    function getAllIndexedTokens() external view returns (uint256[] memory);

    /** @notice get staking conditions for the current condition ID
        @return StakingCondition struct with the staking conditions info */
    function getCurrentStakingCondition()
        external
        view
        returns (StakingCondition memory);

    /** @notice get staking conditions for the given condition ID
        @param conditionId: condition ID
        @return StakingCondition struct with the staking conditions info */
    function getStakingCondition(
        uint256 conditionId
    ) external view returns (StakingCondition memory);

    /** @notice gets staker info of the given staker address
        @param staker: staker address
        @return Staker struct of the staker info */
    function getStaker(address staker) external view returns (Staker memory);
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
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC721ArtHandle {
    // ---- From IERC721 (OpenZeppelin) ----

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // ---- From OwnableUpgradeable (OpenZeppelin) ----

    function owner() external view returns (address);

    // ---- Owned implemented logic ----

    /** @notice reads crowdfund public storage variable 
        @return address of the set crowdfund contract */
    function getCrowdfund() external view returns (address);

    /** @notice reads lastTransfer public storage mapping 
        @param tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function getLastTransfer(uint256 tokenId) external view returns (uint256);
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