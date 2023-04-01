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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
pragma solidity 0.8.17;
import "../lib/Types.sol";

/* @title An interface for a Mission contract
 * @notice Mission contract is used to verify certain mission logic and cache mission status
 * @notice MUST define data schema to decode object node.data in validateMission() method.
 * Quest Admin utilizing Dquest::createQuest will follow schema to encode the data
 */
interface IMission {
    /**
     * @dev Validates the mission submitted.
     * @notice caller MUST belong to d.quest's quest contracts. Use DQuest::isQuest() method to verify
     * @param quester The address of the quester submitting the mission.
     * @param node The mission to be validated.
     * @return isComplete Returns validation result
     */
    function validateMission(address quester, Types.MissionNode calldata node) external returns (bool isComplete);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../lib/Types.sol";

/*
 * @title An interface for a Quest contract
 * @notice Quest contract is use to manage Questers, Missions and Outcomes
 */
interface IQuest {
    /// @dev Defines the possible states of a quester's status to current quest.
    /// States:
    /// - NotEnrolled = The quester hasn't joined the quest.
    /// - InProgress = The quester has joined the quest and doing mission.
    /// - Completed = The quester has finished all missions in the quest.
    /// - Rewarded = The quester has successfully completed the quest and received a reward.
    enum QuesterProgress {
        NotEnrolled,
        InProgress,
        Completed,
        Rewarded
    }

    /// EVENTS

    /// @notice This event is triggered when the set of mission nodes is updated.
    /// @param missionFormulas An array of MissionNode objects.
    event MissionNodeFormulasSet(Types.MissionNode[] missionFormulas);

    /// @notice This event is triggered when the set of outcomes is updated.
    /// @param outcomes An array of Outcome objects.
    event OutcomeSet(Types.Outcome[] outcomes);

    /// @notice This event is triggered when an outcome is executed on a quester.
    /// @param quester The address of the quester who outcome is being executed on.
    event OutcomeExecuted(address indexed quester);

    /// @notice This event is triggered when a new quester is enrolled to the system.
    /// @param quester The address of the newly added quester.
    event QuesterJoined(address indexed quester);

    /// @notice This event is triggered when native coin is transfered to Quest contract
    /// @param sender The address of sender.
    /// @param amount The total amount of native coin reward.
    event Received(address indexed sender, uint indexed amount);

    /// @notice this event is triggered when a mission status is updated
    /// @param quester the quester address
    /// @param missionNodeId the id of the mission node whose status to be updated
    /// @param result the mission validation result sent back from mission handlers
    event MissionStatusSet(address quester, uint256 missionNodeId, bool result);

    /**
     * @dev Sets the formulas for the mission nodes.
     * @notice Only the contract owner can call this function.
     * @param nodes The array of mission nodes to set. MUST be a directed binary tree.
     * Emits a `MissionNodeFormulasSet` event.
     *
     * We have 2 kinds of node:
     *  - Mission node (see the M* nodes at the tree below)
     *  - Operator node (see AND and OR node at the tree below)
     *
     * Input constraints (`nodes`'s constraints):
     *  - Nodes' ids MUST be unique.
     *  - Nodes' ids MUST be positive integers in range [1:].
     *  - LeftNode/RightNode MUST be either 0 or refer to other nodes' ids.
     *  - In case of leafNode (also Mission node(not "operator" node)), its LeftNode/RightNode must be both 0.
     *  - The input array `nodes` MUST not contain any cycles.
     *
     *                             OR(1)
     *                           /        `
     *                          /            `
     *                         /                `
     *                     AND(2)                  `AND(3)
     *                    /      `                 /      `
     *                   /         `              /         `
     *               AND(4)          `M3(5)     M4(6)         `M1(7)
     *              /    `
     *             /       `
     *           M1(8)       `M2(9)
     *
     * FYI:
     *  - The numbers in the parentheses are the indexes of the nodes
     */
    function setMissionNodeFormulas(Types.MissionNode[] calldata nodes) external;

    /**
     * @notice Set the outcomes for this quest.
     * @param outcomes An array of Outcome structs.
     */
    function setOutcomes(Types.Outcome[] calldata outcomes) external;

    /**
     * @dev Sets the status of a mission for a specific quester.
     * Only dquest oracle can call this function.
     * @param quester The address of the quester.
     * @param missionNodeId The ID of the mission node.
     * @param isMissionDone The status of the mission.
     */
    function setMissionStatus(address quester, uint256 missionNodeId, bool isMissionDone) external;

    /**
     * @dev Pauses the quest.
     * Only the contract owner can call this function.
     * Emits a `Paused` event.
     */
    function pauseQuest() external;

    /**
     * @dev Resumes the quest.
     * Only the contract owner can call this function.
     * Emits a `Unpaused` event.
     */
    function resumeQuest() external;

    /**
     * @dev A function to evaluate the tree for a user
     * @return isComplete Returns validation result.
     */
    function validateQuest() external returns (bool isComplete);

    /**
     * @dev Validates a mission for the given mission node ID.
     * @param missionNodeId MUST be the id of mission node (isMission == true).
     * @return isComplete Returns validation result.
     */
    function validateMission(uint256 missionNodeId) external returns (bool isComplete);

    /**
     * @notice Execute a defined outcome of the quest.
     * @dev This function is public and can only be called by anyone.
     * Whether the quester is eligible to receive the outcome depends on the allQuesterStatuses mapping.
     * @param quester The quester who wants to receive the quest's outcome.
     */
    function executeQuestOutcome(address quester) external;

    /**
     * @dev quester calls this function to get enrolled.
     * Only callable when the contract is active and only when user has not joined before.
     * Emits a `QuesterJoined` event.
     */
    function join() external;

    /**
     * @dev Returns the total number of questers.
     * @return totalQuesters total number of questers.
     */
    function getTotalQuesters() external view returns (uint256 totalQuesters);

    /**
     * @dev Marks an ERC721 token as used for this Quest.
     * @param missionNodeId The ID of the mission node to associate the token with.
     * @param tokenAddr The address of the ERC721 token contract.
     * @param tokenId The ID of the ERC721 token to mark as used.
     * @notice This function can only be called by the mission handler associated with the specified mission node.
     * @notice Once a token has been marked as used for a quest, it cannot be used by any other questers on that Quest.
     */
    function erc721SetTokenUsed(uint256 missionNodeId, address tokenAddr, uint256 tokenId) external;

    /**
     * @dev Checks if an ERC721 token has been marked as used for this Quest.
     * @param addr The address of the ERC721 token contract.
     * @param tokenId The ID of the token to check.
     * @return bool Returns true if the token has been marked as used for the specified mission node, false otherwise.
     */
    function erc721GetTokenUsed(address addr, uint256 tokenId) external view returns (bool);

    /**
     * @dev get missions.
     * @return missions an array of mission nodes.
     */
    function getMissions() external view returns (Types.MissionNode[] memory missions);

    /**
     * @dev get outcomes.
     * @return outcomes an array of mission outcomes.
     */
    function getOutcomes() external view returns (Types.Outcome[] memory outcomes);

    /**
     * @dev get quester's progress.
     * @param quester the address of a quester
     * @return progress an enum defined at `enum QuesterProgress`.
     */
    function getQuesterProgress(address quester) external view returns (QuesterProgress progress);

    /**
     * @dev get quester's mission status.
     * @param quester the quester's address
     * @param missionId the id of the mission (it's the node id in mission formula)
     * @return status mission status of a quester on a mission whose id is missionId.
     */
    function getMissionStatus(address quester, uint256 missionId) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Types.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title MissionFormula
 * @dev This library defines data structures and functions related to mission formulas.
 */
library MissionFormula {
    // Use EnumerableSetUpgradeable to manage node ids
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @dev Defines a formula data structure which stores mission nodes in a mapping.
     * @param _values Mapping to store mission nodes.
     * @param _keys EnumerableSetUpgradeable to manage node ids.
     */
    struct Formula {
        mapping(uint256 => Types.MissionNode) _values;
        EnumerableSetUpgradeable.UintSet _keys;
    }

    /**
     * @dev Defines an efficiently resetable formula data structure which stores formulas in a mapping.
     * @param erf Mapping to store formulas.
     * @param rstPtr Pointer to the current formula in the mapping.
     */
    struct EfficientlyResetableFormula {
        mapping(uint256 => Formula) erf;
        uint256 rstPtr;
    }

    // check if nodeid is the root of the tree
    function _isRoot(EfficientlyResetableFormula storage f, uint256 nodeId) private view returns (bool) {
        require(f.erf[f.rstPtr]._keys.contains(nodeId), "Null node");
        Formula storage formula = f.erf[f.rstPtr];
        uint256 len = formula._keys.length();
        for (uint256 index = 0; index < len; index++) {
            uint256 key = formula._keys.at(index);
            Types.MissionNode memory node = formula._values[key];
            // if it is node to be checked, continue
            if (node.id == nodeId) continue;
            // if node is a child node, node is not a root node
            if (node.leftNode == nodeId || node.rightNode == nodeId) return false;
        }
        return true;
    }

    /**
     * @dev Adds nodes to the given formula and resets it.
     * @param f Formula to add nodes to.
     * @param nodes Array of mission nodes to add to the formula.
     * @return Boolean indicating success.
     */
    function _set(EfficientlyResetableFormula storage f, Types.MissionNode[] memory nodes) internal returns (bool) {
        _reset(f);
        if (nodes.length != 0) {
            for (uint256 idx = 0; idx < nodes.length; idx++) {
                f.erf[f.rstPtr]._values[nodes[idx].id] = nodes[idx];
                assert(f.erf[f.rstPtr]._keys.add(nodes[idx].id));
            }
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Resets the given formula by incrementing the pointer to the next formula in the mapping.
     * @param f Formula to reset.
     */
    function _reset(EfficientlyResetableFormula storage f) private {
        // inc pointer to reset mapping; omit id #0
        f.rstPtr++;
    }

    /**
     * @dev Returns the mission node with the given id from the given formula.
     * @param f Formula to get mission node from.
     * @param nodeId Id of the mission node to get. Must exist.
     * @return Mission node with the given id.
     */
    function _getNode(
        EfficientlyResetableFormula storage f,
        uint256 nodeId
    ) internal view returns (Types.MissionNode memory) {
        require(f.erf[f.rstPtr]._keys.contains(nodeId), "Null node");
        return f.erf[f.rstPtr]._values[nodeId];
    }

    /**
     * @dev Returns the length of mission formula.
     * @param f Formula to get mission node from.
     * @return Mission length of the formula (the number of nodes).
     */
    function _length(EfficientlyResetableFormula storage f) internal view returns (uint256) {
        return f.erf[f.rstPtr]._keys.length();
    }

    /**
     * @dev Returns an array of mission nodes.
     * @param f Formula to get mission node from.
     * @return an array of mission nodes.
     */
    function _getMissions(EfficientlyResetableFormula storage f) internal view returns (Types.MissionNode[] memory) {
        uint256 len = _length(f);
        Types.MissionNode[] memory result = new Types.MissionNode[](len);
        for (uint256 index = 0; index < len; index++) {
            uint256 keyIndex = f.erf[f.rstPtr]._keys.at(index);
            result[index] = f.erf[f.rstPtr]._values[keyIndex];
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Types.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title OutcomeManager
 * @dev This library defines data structures and functions related to outcome for quest.
 */
library OutcomeManager {
    // Use EnumerableSetUpgradeable to manage node ids
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @dev Defines a outcomes data structure which stores each outcome in a mapping.
     * @param _values Mapping to store outcome.
     * @param _keys EnumerableSetUpgradeable to manage outcome ids.
     */
    struct Outcomes {
        mapping(uint256 => Types.Outcome) _values;
        EnumerableSetUpgradeable.UintSet _keys;
    }

    /**
     * @dev Defines an efficiently resetable outcomes data structure which stores formulas in a mapping.
     * @param ero Mapping to store outcomes.
     * @param outPtr Pointer to the current formula in the mapping.
     */
    struct EfficientlyResetableOutcome {
        mapping(uint256 => Outcomes) ero;
        uint256 outPtr;
    }

    /**
     * @dev Adds outcome to the given EfficientlyResetableOutcome and resets it.
     * @param o EfficientlyResetableOutcome to add outcome to.
     * @param outcomes Array of outcomes.
     * @return Boolean indicating success.
     */
    function _set(EfficientlyResetableOutcome storage o, Types.Outcome[] memory outcomes) internal returns (bool) {
        _reset(o);
        if (outcomes.length != 0) {
            for (uint256 idx = 0; idx < outcomes.length; idx++) {
                o.ero[o.outPtr]._values[idx] = outcomes[idx];
                // outcome index(in the array) is the outcomeId
                assert(o.ero[o.outPtr]._keys.add(idx));
            }
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns the outcome with the given id from the given EfficientlyResetableOutcome.
     * @param o EfficientlyResetableOutcome to get outcome from.
     * @param outcomeId Id of the outcome to get. Must exist.
     * @return Outcome with the given id.
     */
    function _getOutcome(
        EfficientlyResetableOutcome storage o,
        uint256 outcomeId
    ) internal view returns (Types.Outcome memory) {
        require(o.ero[o.outPtr]._keys.contains(outcomeId), "Null Outcome");
        return o.ero[o.outPtr]._values[outcomeId];
    }

    /**
     * @dev Resets the given EfficientlyResetableOutcome by incrementing the pointer to the next Outcome in the mapping.
     * @param o Outcome to reset.
     */
    function _reset(EfficientlyResetableOutcome storage o) private {
        // inc pointer to reset mapping; omit id #0
        o.outPtr++;
    }

    /**
     * @dev Replace the current outcome with the new one for the given id in EfficientlyResetableOutcome.
     * @param o EfficientlyResetableOutcome to replace outcome to.
     * @param outcomeId Id of the outcome to replace. Must exist.
     */
    function _replace(EfficientlyResetableOutcome storage o, uint256 outcomeId, Types.Outcome memory outcome) internal {
        require(o.ero[o.outPtr]._keys.contains(outcomeId), "Null Outcome");
        o.ero[o.outPtr]._values[outcomeId] = outcome;
    }

    /**
     * @dev Returns the outcome length of the given EfficientlyResetableOutcome.
     * @param o EfficientlyResetableOutcome to get length from.
     * @return outcomeLength with the given EfficientlyResetableOutcome.
     */
    function _length(EfficientlyResetableOutcome storage o) internal view returns (uint256) {
        return EnumerableSetUpgradeable.length(o.ero[o.outPtr]._keys);
    }

    /**
     * @dev Returns an array of outcomes.
     * @param o EfficientlyResetableOutcome to get length from.
     * @return an array of outcomes.
     */
    function _getOutcomes(EfficientlyResetableOutcome storage o) internal view returns (Types.Outcome[] memory) {
        uint256 len = _length(o);
        Types.Outcome[] memory result = new Types.Outcome[](len);
        for (uint256 index = 0; index < len; index++) {
            uint256 keyIndex = o.ero[o.outPtr]._keys.at(index);
            result[index] = o.ero[o.outPtr]._values[keyIndex];
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Types {
    /// @dev Defines the possible types of operators for a mission node.
    /// States:
    /// - And = All child nodes must evaluate to true for this node to be true.
    /// - Or = At least one child node must evaluate to true for this node to be true.
    enum OperatorType {
        AND,
        OR
    }

    /// @notice MissionNode stands for a mission parameters
    /// @dev MisisonNode can be an operator or a mission with parameters defined inside of Slot0/Slot1 fields
    /// @param id The index of the node in the array of missionNodeFormula.
    /// @param isMission Is the node a mission or an operator
    /// @param missionHandlerAddress The address of MissionHandler contract to validate the mission with given parameters
    /// @param operatorType The operator type = And/Or if isMission = false
    /// @param leftNode Left side node of this Node
    /// @param rightNode Right side node of this Node
    /// @param data An array of bytes to represent arbitrary data for mission handler
    struct MissionNode {
        uint256 id;
        bool isMission;
        address missionHandlerAddress;
        OperatorType operatorType;
        uint256 leftNode;
        uint256 rightNode;
        bytes[] data;
    }

    /// @notice Outcome stands for each Outcome Reward for this Quest.
    /// @param tokenAddress The token address reward for this Quest.
    /// @param functionSelector The functionSelector to execute the Outcome.
    /// @param data The first Outcome data formed for this Quest in case of token reward.
    /// @param nativeAmount native reward for each Quester if successfully completed the Quest.
    /// @param isNative To define if this Outcome reward is native coin.
    /// @param totalReward The total reward for this Quest.
    /// @param isLimited identify if this Outcome has limited reward amount.
    struct Outcome {
        address tokenAddress;
        bytes4 functionSelector;
        bytes data;
        bool isNative;
        uint256 nativeAmount;
        bool isLimitedReward;
        uint256 totalReward;
    }
}

// A helper in validating input mission formula
library mNodeId2Iterator {
    struct ResetableId2iterator {
        mapping(uint256 => mapping(uint256 => uint256)) rmap;
        uint256 rst;
    }

    function _setIterators(ResetableId2iterator storage id2itr, Types.MissionNode[] memory nodes) internal {
        id2itr.rst++;
        for (uint256 index = 0; index < nodes.length; index++) {
            id2itr.rmap[id2itr.rst][nodes[index].id] = index;
        }
    }

    function _getIterator(ResetableId2iterator storage id2itr, uint256 nodeId) internal view returns (uint256) {
        return id2itr.rmap[id2itr.rst][nodeId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./lib/Types.sol";
import "./lib/MissionFormula.sol";
import "./lib/OutcomeManager.sol";
import "./interface/IQuest.sol";
import "./interface/IMission.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Quest is IQuest, Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using MissionFormula for MissionFormula.EfficientlyResetableFormula;
    using OutcomeManager for OutcomeManager.EfficientlyResetableOutcome;
    using mNodeId2Iterator for mNodeId2Iterator.ResetableId2iterator;

    // binary tree cycles detection helpers
    mNodeId2Iterator.ResetableId2iterator private id2itr1;
    mNodeId2Iterator.ResetableId2iterator private id2itr2;
    uint256 private formulaRootNodeId;

    // contract storage
    MissionFormula.EfficientlyResetableFormula private missionNodeFormulas;
    OutcomeManager.EfficientlyResetableOutcome private outcomes;
    address[] public allQuesters;
    mapping(address => QuesterProgress) private questerProgresses;
    mapping(address => mapping(uint256 => bool)) private questerMissionsDone;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    bool public isRewardAvailable;

    bytes4 constant SELECTOR_TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant SELECTOR_SAFETRANSFERFROM = bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256)")));
    bytes4 constant SELECTOR_NFTSTANDARDMINT = bytes4(keccak256(bytes("mint(uint256,address[],uint256,uint256[],bytes32[])")));
    bytes4 constant SELECTOR_SBTMINT = bytes4(keccak256(bytes("mint(address[],uint256)")));

    // utility mapping for NFT handler only
    mapping(address => mapping(uint256 => bool)) private tokenUsed;

    // TODO: check allQuesters's role
    modifier onlyQuester() {
        require(questerProgresses[msg.sender] != QuesterProgress.NotEnrolled, "For questers only");
        _;
    }

    modifier questerNotEnrolled() {
        require(questerProgresses[msg.sender] == QuesterProgress.NotEnrolled, "Quester already joined");
        _;
    }

    // when quest is inactive
    modifier whenInactive() {
        require(block.timestamp < startTimestamp, "Quest has started");
        _;
    }

    // when quest is active
    modifier whenActive() {
        //require(status == QuestStatus.Active, "Quest is not Active");
        require(startTimestamp <= block.timestamp && block.timestamp <= endTimestamp, "Quest is not Active");
        _;
    }

    // when quest is closed/expired
    modifier whenClosed() {
        //require(status != QuestStatus.Closed, "Quest is expired");
        require(block.timestamp > endTimestamp, "Quest is expired");
        _;
    }

    // prettier-ignore
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with the specified mission nodes and quest start/end times.
     * @notice This function can only be called during the initialization phase of the contract.
     * @notice Check docstrings of setMissionNodeFormulas carefully
     * @param nodes The array of mission nodes to set.
     * @param outcomeList The array of outcomes to be executed.
     * @param questStartTime The timestamp at which the quest starts.
     * @param questEndTime The timestamp at which the quest ends.
     * Emits a `MissionNodeFormulasSet` event.
     */
    function init(
        address owner,
        Types.MissionNode[] calldata nodes,
        Types.Outcome[] calldata outcomeList,
        uint256 questStartTime,
        uint256 questEndTime
    ) external initializer {
        //TODO check carefully
        require(questStartTime < questEndTime, "Invalid quest lifetime");
        require(block.timestamp < questStartTime, "Starting time is over");
        startTimestamp = questStartTime;
        endTimestamp = questEndTime;
        __Ownable_init();
        __Pausable_init();
        setMissionNodeFormulas(nodes);
        setOutcomes(outcomeList);
        // d.quest's transfering ownership to quest admin
        transferOwnership(owner);
    }

    function setMissionStatus(
        address quester,
        uint256 missionNodeId,
        bool isMissionDone
    ) external whenActive {
        
        Types.MissionNode memory node = missionNodeFormulas._getNode(missionNodeId);
        require(msg.sender == node.missionHandlerAddress,"States update not allowed");
        require(questerProgresses[quester] != QuesterProgress.NotEnrolled, "Not a quester");
        questerMissionsDone[quester][missionNodeId] = isMissionDone;
        emit MissionStatusSet(quester, missionNodeId, isMissionDone);
    }

    function setMissionNodeFormulas(Types.MissionNode[] calldata nodes)
        public
        override
        onlyOwner
        whenInactive
    {
        // TODO: improve validation of input mission nodes
        _validateFormulaInput(nodes);
        require(missionNodeFormulas._set(nodes), "Fail to set mission formula");
        emit MissionNodeFormulasSet(nodes);
    }

    /**
     * @dev evaluate mission formula
     * @param nodeId Always the root node of the formula
     */
    function _evaluateMissionFormulaTree(
        uint256 nodeId
    ) private returns (bool) {
        //TODO validate the binary tree's depth
        Types.MissionNode memory node = missionNodeFormulas._getNode(nodeId);
        if (node.isMission) {
            return validateMission(node.id);
        } else {
            bool leftResult = _evaluateMissionFormulaTree(node.leftNode);
            bool rightResult = _evaluateMissionFormulaTree(node.rightNode);
            if (node.operatorType == Types.OperatorType.AND) {
                return leftResult && rightResult;
            } else {
                return leftResult || rightResult;
            }
        }
    }

    function validateQuest() external override whenActive whenNotPaused returns (bool) {
        return _validateQuest(msg.sender);
    }

    function validateMission(uint256 missionNodeId) public override whenActive whenNotPaused returns (bool) {
        _enroll(msg.sender);
        Types.MissionNode memory node = missionNodeFormulas._getNode(missionNodeId);
        require(node.isMission == true, "Not a mission");
        bool cache = questerMissionsDone[msg.sender][missionNodeId];
        // if false, proceed validation at mission handler contract
        if (cache == false) {
            IMission mission = IMission(node.missionHandlerAddress);
            // subsequent call at this trigger will update back the cache
            return mission.validateMission(msg.sender, node);
        }
        return cache;
    }

    function pauseQuest() external override onlyOwner whenActive {
        _pause();
    }

    function resumeQuest() external override onlyOwner whenActive {
        _unpause();
    }

    function join() external override whenActive questerNotEnrolled {
        allQuesters.push(msg.sender);
        questerProgresses[msg.sender] = QuesterProgress.InProgress;
        emit QuesterJoined(msg.sender);
    }

    function getTotalQuesters() external view override returns (uint256 totalQuesters) {
        return allQuesters.length;
    }

    /**
     * @dev Sets the list of possible outcomes for the quest.
     * Only the contract owner can call this function.
     * @param _outcomes The list of possible outcomes to set.
     */
    function setOutcomes(Types.Outcome[] calldata _outcomes) public override onlyOwner whenInactive {
        require(_outcomes.length > 0, "No outcome provided");
        
        for (uint256 i = 0; i < _outcomes.length; i++) {
            if (_outcomes[i].isNative) {
                require(_outcomes[i].nativeAmount > 0, "Insufficient native reward");
            } else {
                require(_outcomes[i].tokenAddress != address(0), "Outcome address is invalid");
                require(_outcomes[i].functionSelector != 0, "functionSelector can't be empty");
                require(
                    keccak256(abi.encodePacked(_outcomes[i].data)) != keccak256(abi.encodePacked("")),
                    "outcomeData can't be empty"
                );
            if (_outcomes[i].isLimitedReward) {
                require(_outcomes[i].totalReward > 0, "Insufficient token reward");
            }}
        }
        outcomes._set(_outcomes);
        isRewardAvailable = true;

        emit OutcomeSet(_outcomes);
    }

    // check if quest has sufficient reward amount for Quester to claim
    function _checkSufficientReward() private {
        for (uint i = 0; i < outcomes._length(); i++)
        {
            Types.Outcome memory outcome = outcomes._getOutcome(i);
            if (outcome.isLimitedReward == false) {
                isRewardAvailable = true;
                break;
            }
            else if (outcome.isLimitedReward && outcome.totalReward > 0)
            {
                isRewardAvailable = true;
                break;
            }
            else {
                isRewardAvailable = false;
            }
        }
    }

    function executeQuestOutcome(address _quester) external override whenActive nonReentrant {
        _validateQuest(_quester);
        require(isRewardAvailable, "The Quest's run out of Reward");
        require(questerProgresses[_quester] == QuesterProgress.Completed, "Quest validation not completed");
        questerProgresses[_quester] = QuesterProgress.Rewarded;
        
        for (uint256 i = 0; i < outcomes._length(); i++) {
            Types.Outcome memory outcome = outcomes._getOutcome(i);
            if (outcome.isNative) {
                outcome.totalReward = _executeNativeOutcome(_quester, outcome);
                outcomes._replace(i, outcome);
            }
            // If one of the Outcome has run out of Reward
            if (outcome.isLimitedReward && outcome.totalReward == 0)
            {
                continue;
            } 
            if (outcome.functionSelector == SELECTOR_TRANSFERFROM) {
                outcome.totalReward = _executeERC20Outcome(_quester, outcome);
                outcomes._replace(i, outcome); 
            }
            if (outcome.functionSelector == SELECTOR_SAFETRANSFERFROM) {
                (outcome.data, outcome.totalReward) = _executeERC721Outcome(_quester, outcome);
                outcomes._replace(i, outcome);
            }
            if (outcome.functionSelector == SELECTOR_SBTMINT) {
                _executeSBTOutcome(_quester, outcome);
            }
            if (outcome.functionSelector == SELECTOR_NFTSTANDARDMINT) {
                _executeNFTStandardOutcome(_quester, outcome);
            }
        }
        _checkSufficientReward();
        emit OutcomeExecuted(_quester);  
    }

    function _executeERC20Outcome(address _quester, Types.Outcome memory outcome)
        internal
        returns(uint256 totalRewardLeft)
    {
        address spender;
        uint256 value;
        bytes memory data = outcome.data;

        assembly {
            spender := mload(add(data, 36))
            value := mload(add(data, 100))
        }

        (bool success, bytes memory response) = outcome.tokenAddress.call(
            abi.encodeWithSelector(SELECTOR_TRANSFERFROM, spender, _quester, value)
        );

        require(success, string(response));

        uint256 _totalRewardLeft = outcome.totalReward - value;
        return _totalRewardLeft;
    }

    /**
    * @dev Executes the ERC721Outcome for the specified quester.
    * It's currently implemented with 
    * Admin: setApprovalForAll from Admin's balance
    * tokenId: sequential tokenId with 1st tokenId passing to Outcome.data
    * @param _quester The address of the quester whose outcome to execute.
    * @return newData for Outcome Struct 
    */
    function _executeERC721Outcome(address _quester, Types.Outcome memory outcome)
        internal
        returns (bytes memory newData, uint256 totalRewardLeft)
    {
        address spender;
        uint256 tokenId;
        bytes memory data = outcome.data;

        assembly {
            spender := mload(add(data, 36))
            tokenId := mload(add(data, 100))
        }

        (bool success, bytes memory response) = outcome.tokenAddress.call(
            abi.encodeWithSelector(SELECTOR_SAFETRANSFERFROM, spender, _quester, tokenId)
        );
        require(success, string(response));

        tokenId++;
        uint256 _totalRewardLeft = outcome.totalReward - 1;
        bytes memory _newData = abi.encodeWithSelector(SELECTOR_SAFETRANSFERFROM, spender, _quester, tokenId);

        return (_newData, _totalRewardLeft);
    }

    function _executeNFTStandardOutcome(address _quester, Types.Outcome memory outcome)
        internal
    {
        bytes memory data = outcome.data;
        uint256 mintingConditionId;
        uint256 amount;
        address[] memory quester = new address[](1);
        uint256[] memory clientIds;
        bytes32[] memory merkleRoot = new bytes32[](1);

        quester[0] = _quester;
        merkleRoot[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;

        assembly {
            mintingConditionId := mload(add(data, 164))
            amount := mload(add(data, 228))
        }

        (bool success, bytes memory response) = outcome.tokenAddress.call(
            abi.encodeWithSelector(
                SELECTOR_NFTSTANDARDMINT,
                mintingConditionId,
                quester,
                amount,
                clientIds,
                merkleRoot
            )
        );
        
        require(success, string(response));
    }

    function _executeSBTOutcome(address _quester, Types.Outcome memory outcome)
        internal
    {
        bytes memory data = outcome.data;   
        uint256 expiration;
        address[] memory quester = new address[](1);
        quester[0] = _quester;

        assembly {
            expiration := mload(add(data, 196))
        }

        (bool success, bytes memory response) = outcome.tokenAddress.call(
            abi.encodeWithSelector(SELECTOR_SBTMINT, quester, expiration)
        );

        require(success, string(response));
    }

    function _executeNativeOutcome(address _quester, Types.Outcome memory outcome)
        internal
        returns(uint256 totalRewardLeft)
    {
        (bool success, bytes memory response) = payable(_quester).call{value: outcome.nativeAmount}("");
        require(success, string(response));

        uint256 _totalRewardLeft = outcome.totalReward - outcome.nativeAmount;
        return _totalRewardLeft;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // validate mission formula input
    function _validateFormulaInput(Types.MissionNode[] memory nodes) private {
        require(nodes.length > 0, "formula input empty");
        // Check for repeated IDs
        for (uint256 i = 0; i < nodes.length; i++) {
            require(nodes[i].id != 0, "A node's id must not be 0");
            if(nodes[i].isMission == true) {
                // validate for mission node
                require(nodes[i].missionHandlerAddress != address(0x0), "handler address mustn't be 0x0");
                require((nodes[i].leftNode | nodes[i].rightNode) == 0, "M node's left/right id must be 0");
                require(nodes[i].data.length != 0, "data must not be empty");
            } else {
                // when node is an operator
                require(((nodes[i].leftNode != 0) && (nodes[i].rightNode != 0)), "OP node's l&r node must != 0");
            }
            for (uint256 j = i + 1; j < nodes.length; j++) {
                if (nodes[i].id == nodes[j].id) {
                    revert("repetitive id");
                }
            }
        }

        // Validate and find root node
        uint256 rootId = _findRoot(nodes);

        //TODO Check for loops/cycles
        if(_hasCycle(nodes, rootId))
            revert("mission formula has cycles");

        formulaRootNodeId = rootId;
    }

    // detect Cycle in a directed binary tree
    function _hasCycle(Types.MissionNode[] memory nodes, uint256 rootNodeId) private returns(bool) {
        bool[] memory visited = new bool[](nodes.length);
        id2itr1._setIterators(nodes);
        return _hasCycleUtil(nodes, visited, rootNodeId);
    }

    // cycle detection helper
    function _hasCycleUtil(
        Types.MissionNode[] memory nodes,
        bool[] memory visited,
        uint256 id
    ) private returns (bool) {
        Types.MissionNode memory node = nodes[id2itr1._getIterator(id)];
        visited[id2itr1._getIterator(id)] = true;
        if (node.leftNode != 0) {
            if (visited[id2itr1._getIterator(node.leftNode)]) {
                return true;
            }
            if (_hasCycleUtil(nodes, visited, node.leftNode)) {
                return true;
            }
        }
        if (node.rightNode != 0) {
            if (visited[id2itr1._getIterator(node.rightNode)]) {
                return true;
            }
            if (_hasCycleUtil(nodes, visited, node.rightNode)) {
                return true;
            }
        }
        return false;
    }

    // support find root node of a binary tree
    function _findRoot(Types.MissionNode[] memory tree) private returns (uint256) {
        uint256 n = tree.length;
        id2itr2._setIterators(tree);
        bool[] memory isChild = new bool[](n);

        for (uint256 i = 0; i < n; i++) {
            if (tree[i].leftNode != 0) {
                isChild[id2itr2._getIterator(tree[i].leftNode)] = true;
            }
            if (tree[i].rightNode != 0) {
                isChild[id2itr2._getIterator(tree[i].rightNode)] = true;
            }
        }

        uint256 rootNode = 0;
        uint256 rootCount = 0;
        for (uint256 i = 0; i < n; i++) {
            if (!isChild[i]) {
                rootCount++;
                rootNode = tree[i].id;
                if (rootCount > 1)
                    revert("tree has several root nodes");
            }
        }

        // there's no node that's referenced by nothing(the root node)
        if (rootCount == 0)
            revert("no root found");

        return rootNode;
    }

    function erc721SetTokenUsed(uint256 missionNodeId, address addr, uint256 tokenId) external whenActive override {
        Types.MissionNode memory node = missionNodeFormulas._getNode(missionNodeId);
        require(msg.sender == node.missionHandlerAddress, "States update not allowed");
        tokenUsed[addr][tokenId] = true;
    }

    function erc721GetTokenUsed(address addr, uint256 tokenId) external whenActive view override returns(bool) {
        return tokenUsed[addr][tokenId];
    }

    // Enroll quester. used at validateQuest and validateMission
    function _enroll(address quester) private {
        if (questerProgresses[quester] == QuesterProgress.NotEnrolled) {
            allQuesters.push(quester);
            questerProgresses[quester] = QuesterProgress.InProgress;
            emit QuesterJoined(quester);
        }
    }

    // a  private copy of validateQuest() function with an open parameter. Used at executeQuestOutcome
    // TODO remove when validateQuest() is upgraded to validateQuest(address quester)
    function _validateQuest(address quester) private returns (bool) {
        _enroll(quester);
        if (questerProgresses[quester] == QuesterProgress.Completed)
            return true;

        bool result = _evaluateMissionFormulaTree(formulaRootNodeId);
        if (result == true)
            if (questerProgresses[quester] == QuesterProgress.InProgress)
                questerProgresses[quester] = QuesterProgress.Completed;

        return result;
    }

    function getMissions() external view override returns(Types.MissionNode[] memory) {
        return missionNodeFormulas._getMissions();
    }

    function getOutcomes() external view override returns(Types.Outcome[] memory) {
        return outcomes._getOutcomes();
    }

    function getQuesterProgress(address quester) external view returns(QuesterProgress progress) {
        return questerProgresses[quester];
    }

    function getMissionStatus(address quester, uint256 missionId) external view returns(bool status) {
        return questerMissionsDone[quester][missionId];
    }
}