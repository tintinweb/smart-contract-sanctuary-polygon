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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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
pragma solidity ^0.8.0;

interface IGame {
    struct RequestResult {
        uint256 requestId;
        address player;
        uint16 numResource; // 1, 2, ... số lần hiện shop; 20 = 1 shop hiện 20 resource, 30 = 1 shop hiện 30 resource
        uint16 numItem; // 1, 2, ... số lần xuất hiện shop
        uint8 shop2Resource; // 0 = ko shop nào, 1 shop đầu có 2 resource
        uint8 must; // 0 = tự do, 1 = phải chọn 1 resource, 2 = phải skip resource
        uint8 end; // 0 = chưa chọn, 1 = đã chọn
        uint8 option; //option = 0: bình thường, option = 1: rare + veryRare, 2: veryRare
        uint16 ratio;
        uint16[] resources;
        uint16[] items;
        uint16[] essences;
    }


    event LandDeposited(address from, uint256 landId);
    event LandWithdrew(address from, uint256 landId);
    event Rolled(address from, uint256 landId, uint256 requestId, uint256[20] position);
    event BoughtFromShop(
        address from,
        uint256 landId, 
        uint16[] resourceId, 
        uint16[] itemId, 
        uint16[] essenceId
    );

    function cogResources() external view returns (address);

    function getType(uint8 level, bool option, uint256 number, uint16 ratio) external view returns (uint256 type_);

    function executeRoll(uint256[] memory randomNumber, uint256 requestId) external;

    function ownerOfLand(address account, uint256 landId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "./../land/logic/resources/interfaces/ICoGResources.sol";
import "./../interfaces/IGame.sol";

contract CalRandomResource is OwnableUpgradeable {
    IGame public game;

    struct LoopResult {
        uint8[] shop;
        uint8[43] array0;
        uint8[50] array1;
        uint8[37] array2;
        uint8[8] array3;
        uint8 count0;
        uint8 count1;
        uint8 count2;
        uint8 count3;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function setGame(address game_) external onlyOwner {
        game = IGame(game_);
    }

    function randShopResource(uint256 number, uint8 num, uint8 level, uint16 ratio, uint8 option) public view returns (uint8[] memory) {
        LoopResult memory res = loop3(number, level, num, ratio, option);        
        return res.shop;     
    }

    function firstResource(uint256 number, uint8 num, uint8 level, uint16 ratio, uint8 option) public view returns(
        LoopResult memory res
    ) {
        res.array0 = [2,5,6,11,13,17,19,21,22,23,26,30,33,36,37,38,39,45,48,49,55,57,61,63,78,80,81,84,93,95,96,98,103,104,105,108,111,121,122,124,133,136,137];
        res.array1 = [7,9,14,15,16,18,20,25,27,29,31,32,40,43,53,62,64,65,66,67,68,69,70,71,74,75,76,82,86,100,102,106,109,112,113,114,115,118,119,120,125,129,130,131,132,138,139,140,142,144];
        res.array2 = [1,3,4,8,10,12,24,28,34,35,41,44,46,51,54,56,58,60,73,77,79,83,85,94,97,99,101,107,116,117,123,126,127,128,134,135,143];
        res.array3 = [42,50,59,72,91,92,110,141];
        res.count0 = 43;
        res.count1 = 50;
        res.count2 = 37;
        res.count3 = 8;
        res.shop = new uint8[](num);
        if (option == 1) {
            uint8 temp = uint8(((number / 100000) % 100000) % 2);
            uint8 type_ = temp == 0 ? 3 : 4;
            if (type_ == 3) {
                uint8 temp2 = getTemp2(number/ (1e5), res.count2, 0);
                res.shop[0] = res.array2[temp2];
                res.array2[temp2] = res.array2[res.count2 - 1];
                res.count2 -= 1;
            } else if(type_ == 4) {
                uint8 temp2 = getTemp2(number/ (1e5), res.count3, 0);
                res.shop[0] = res.array3[temp2];
                res.array3[temp2] = res.array3[res.count3 - 1];
                res.count3 -= 1;
            }
        } else if (option == 2) {
            uint8 temp2 = getTemp2(number/ (1e5), res.count3, 0);
            res.shop[0] = res.array3[temp2];
            res.array3[temp2] = res.array3[res.count3 - 1];
            res.count3 -= 1;
        } else {
            uint256 temp = ((number / 100000) % 100000) % 10000;
            uint8 type_ = uint8(game.getType(level, true, temp, ratio));
            if (type_ == 1) {
                uint8 temp2 = getTemp2(number/ (1e5), res.count0, 0);
                res.shop[0] = res.array0[temp2];
                res.array0[temp2] = res.array0[res.count0 - 1];
                res.count0 -= 1;
            } else if (type_ == 2) {
                uint8 temp2 = getTemp2(number/ (1e5), res.count1, 0);
                res.shop[0] = res.array1[temp2];
                res.array1[temp2] = res.array1[res.count1 - 1];
                res.count1 -= 1;
            } else if (type_ == 3) {
                uint8 temp2 = getTemp2(number/ (1e5), res.count2, 0);
                res.shop[0] = res.array2[temp2];
                res.array2[temp2] = res.array2[res.count2 - 1];
                res.count2 -= 1;
            } else if(type_ == 4) {
                uint8 temp2 = getTemp2(number/ (1e5), res.count3, 0);
                res.shop[0] = res.array3[temp2];
                res.array3[temp2] = res.array3[res.count3 - 1];
                res.count3 -= 1;
            }
        }
    }

    function loop3(uint256 number, uint8 num, uint8 level, uint16 ratio, uint8 option) public view returns(
        LoopResult memory res
    ) {
        res = firstResource(
            number,
            num,
            level,
            ratio,
            option
        );
        for (uint8 i = 0; i < num - 1; i++) {
            // uint256 temp = ((number / (1e8 * (100000 ** i))) % 100000) % 10000;
            uint256 temp = getTemp(number / (1e8), i);
            uint8 type_ = uint8(game.getType(level, true, temp, ratio));
            if (type_ == 1) {
                uint8 temp2 = getTemp2(number/ (1e18), res.count0, i);
                res.shop[i + 1] = res.array0[temp2];
                res.array0[temp2] = res.array0[res.count0 - 1];
                res.count0 -= 1;
            } else if (type_ == 2) {
                uint8 temp2 = getTemp2(number/ (1e18), res.count1, i);
                res.shop[i + 1] = res.array1[temp2];
                res.array1[temp2] = res.array1[res.count1 - 1];
                res.count1 -= 1;
            } else if (type_ == 3) {
                uint8 temp2 = getTemp2(number/ (1e18), res.count2, i);
                res.shop[i + 1] = res.array2[temp2];
                res.array2[temp2] = res.array2[res.count2 - 1];
                res.count2 -= 1;
            } else if(type_ == 4) {
                uint8 temp2 = getTemp2(number/ (1e18), res.count3, i);
                res.shop[i + 1] = res.array3[temp2];
                res.array3[temp2] = res.array3[res.count3 - 1];
                res.count3 -= 1;
            }
        }

    }

    function loop0(uint256[4] calldata number, uint8 num, uint8 level, uint16 ratio, uint8 option) public view returns(
        LoopResult memory res
    ) {
        res = firstResource(
            number[0],
            num,
            level,
            ratio,
            option
        );
        for (uint8 i = 0; i < 15 ; i ++) {
            // uint256 temp = ((number[1] / (100000 ** i)) % 100000) % 10000;
            uint256 temp = getTemp(number[1], i);
            uint8 type_ = uint8(game.getType(level, true, temp, ratio));
            if (type_ == 1 || (type_ == 3 && res.count2 == 0) || (type_ == 4 && res.count3 == 0)) {
                uint8 temp2 = getTemp2(number[2], res.count0, i);
                res.shop[i + 1] = res.array0[temp2];
                res.array0[temp2] = res.array0[res.count0 - 1];
                res.count0 -= 1;
            } else if (type_ == 2) {
                uint8 temp2 = getTemp2(number[2], res.count1, i);
                res.shop[i + 1] = res.array1[temp2];
                res.array1[temp2] = res.array1[res.count1 - 1];
                res.count1 -= 1;
            } else if (type_ == 3) {
                uint8 temp2 = getTemp2(number[2], res.count2, i);
                res.shop[i + 1] = res.array2[temp2];
                res.array2[temp2] = res.array2[res.count2 - 1];
                res.count2 -= 1;
            } else if(type_ == 4) {
                uint8 temp2 = getTemp2(number[2], res.count3, i);
                res.shop[i + 1] = res.array3[temp2];
                res.array3[temp2] = res.array3[res.count3 - 1];
                res.count3 -= 1;
            }
        }
    }

    function loop1(uint256[4] calldata number, uint8 num, uint8 level, uint16 ratio, uint8 option) public view returns(
        LoopResult memory res
    )  {
        res = loop0(number, num, level, ratio, option);
        for (uint8 i = 0; i < 14 ; i ++) {
            // uint256 temp = ((number[3] / (100000 ** i)) % 100000) % 10000;
            uint256 temp = getTemp(number[3], i);
            uint8 type_ = uint8(game.getType(level, true, temp, ratio));
            if (type_ == 1 || (type_ == 3 && res.count2 == 0) || (type_ == 4 && res.count3 == 0)) {
                uint8 temp2 = getTemp2(number[0] / (1e8), res.count0, i);
                res.shop[i + 16] = res.array0[temp2];
                res.array0[temp2] = res.array0[res.count0 - 1];
                res.count0 -= 1;
            } else if (type_ == 2) {
                uint8 temp2 = getTemp2(number[0] / (1e8), res.count1, i);
                res.shop[i + 16] = res.array1[temp2];
                res.array1[temp2] = res.array1[res.count1 - 1];
                res.count1 -= 1;
            } else if (type_ == 3) {
                uint8 temp2 = getTemp2(number[0] / (1e8), res.count2, i);
                res.shop[i + 16] = res.array2[temp2];
                res.array2[temp2] = res.array2[res.count2 - 1];
                res.count2 -= 1;
            } else if(type_ == 4) {
                uint8 temp2 = getTemp2(number[0] / (1e8), res.count3, i);
                res.shop[i + 16] = res.array3[temp2];
                res.array3[temp2] = res.array3[res.count3 - 1];
                res.count3 -= 1;
            }
        }
        // return shop;
    }

    function loop2(uint256[4] calldata number, uint8 num, uint8 level, uint16 ratio, uint8 option) public view returns(uint8[] memory) {
        LoopResult memory res = loop0(number, num, level, ratio, option);
        for (uint8 i = 0; i < 4 ; i ++) {
            // uint256 temp = ((number[0] / (1e8 * (100000 ** i))) % 100000) % 10000;
            uint256 temp = getTemp(number[0] / (1e8), i);
            uint8 type_ = uint8(game.getType(level, true, temp, ratio));            
            if (type_ == 1 || (type_ == 3 && res.count2 == 0) || (type_ == 4 && res.count3 == 0)) {
                uint8 temp2 = getTemp2(number[3], res.count0, i);
                res.shop[i + 16] = res.array0[temp2];
                res.array0[temp2] = res.array0[res.count0 - 1];
                res.count0 -= 1;
            } else if (type_ == 2) {
                uint8 temp2 = getTemp2(number[3], res.count1, i);
                res.shop[i + 16] = res.array1[temp2];
                res.array1[temp2] = res.array1[res.count1 - 1];
                res.count1 -= 1;
            } else if (type_ == 3) {
                uint8 temp2 = getTemp2(number[3], res.count2, i);
                res.shop[i + 16] = res.array2[temp2];
                res.array2[temp2] = res.array2[res.count2 - 1];
                res.count2 -= 1;
            } else if(type_ == 4) {
                uint8 temp2 = getTemp2(number[3], res.count3, i);
                res.shop[i + 16] = res.array3[temp2];
                res.array3[temp2] = res.array3[res.count3 - 1];
                res.count3 -= 1;
            }
        }
        return res.shop;
    }

    function randShop20Resource(uint256[4] calldata number, uint8 level, uint16 ratio, uint8 option) public view returns (uint8[] memory) {
        (uint8[] memory shop) = loop2(number, 20, level, ratio, option);        
        return shop;  
    }

    function randShop30Resource(uint256[4] calldata number, uint8 level, uint16 ratio, uint8 option) public view returns (uint8[] memory) {
        LoopResult memory res = loop1(number, 30, level, ratio, option);        
        return res.shop;  
    }

    function getTemp2(uint256 number, uint8 count, uint8 i) public pure returns (uint8) {
        return uint8(((number / (1000 ** i)) % 1000) % count);
    }

    function getTemp(uint256 number, uint8 i) public pure returns (uint256) {
        return ((number / (100000 ** i)) % 100000) % 10000;
    }
}