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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/// @dev A multiplier for calculating royalties with some digits of presicion
uint16 constant HUNDRED_PERCENT = 10000; // For two digits precision

/// @dev Lower boundary for beign able to calculates fees with the given HUNDRED_PERCENT presicion
uint256 constant MINIMUM_ASK = 10000; // For fee calculation

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import {HUNDRED_PERCENT} from './Constants.sol';

/**
 * @dev Transfers funds to a given address.
 * @dev Necesary to avoid gas error since eip 2929, more info in eip 2930.
 * @param to The address to transfer the funds to
 * @param amount The amount to be transfered
 */
function transferFundsSupportingGnosisSafe(address to, uint256 amount) {
    (bool sent, ) = payable(to).call{value: amount, gas: 2600}(''); // solhint-disable-line
    assert(sent);
}

/**
 *  @dev Calculated a fee given an amount and a fee percentage
 *  @dev HUNDRED_PERCENT is used as 100% to enhanced presicion.
 *  @param totalAmount The total amount to be paid
 *  @param fee The percentage of the fee over the full amount.
 */
function calculateFee(uint256 totalAmount, uint256 fee) pure returns (uint256) {
    return (totalAmount * fee) / HUNDRED_PERCENT;
}

function transferERC20ToAccount(
    address erc20token,
    address sender,
    address receipient,
    uint256 amount
) {
    bool status = IERC20(erc20token).transferFrom{gas: 2600}(sender, receipient, amount);
    assert(status);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/* Structs */

/// @dev Properties assigned to a particular ticket, including royalties and sellable status.
struct AssetProperties {
    uint256 creatorRoyalty;
    uint256 primaryMarketRoyalty;
    uint256 secondaryMarketRoyalty;
    address creator;
    bool isResellable;
}

/// @dev A particular sale Models.Offer made by a owner, including price and amount.
struct Offer {
    uint256 amount;
    uint256 price;
}

/// @dev all required information for publishing a new ticket.
struct NewAssetSaleInfo {
    uint256 amount;
    uint256 price;
    uint256 royalty;
    uint256 amountToSell;
    bool isResellable;
    string uri;
    bool isPrivate;
    AllowanceInput[] allowances;
    address erc20token;
}

/// @dev ERC721 & ERC1155 memberships management.
struct AllowedMemberships {
    mapping(address => bool) allowedByAddress;
    mapping(address => uint256) tokenIdsAmountAllowedByAddress;
    mapping(address => mapping(uint256 => bool)) allowedTokenIds;
}

/// @dev Memberships input management.
struct MembershipsInfo {
    address[][] addresses;
    uint256[][][] ids;
}

/// @dev Allowance pools e.g. for custom claiming rights for tickets.
struct Allowance {
    uint256 amount;
    mapping(address => bool) allowed;
}

/// @dev Allowance pools input e.g. for custom claiming rights for tickets.
struct AllowanceInput {
    uint256 amount;
    address[] allowedAddresses;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './lib/MarketplaceHelper.sol' as MarketplaceHelper;
import './lib/Models.sol' as Models;
import {HUNDRED_PERCENT, MINIMUM_ASK} from './lib/Constants.sol';

/**
 * @title Admin Contract Interface
 * @dev See https://github.com/Fanz/contracts/blob/main/src/Admin.sol
 */
interface IAdmin {
    // @dev for allowing tickets to be claimed by memberships owners
    function assignMemberships(
        uint256[] calldata ticketsIds,
        address[][] calldata membershipsAddresses,
        uint256[][][] calldata membershipsIds
    ) external;

    // @dev Get the current primary marketplace royalty
    function primaryMarketplaceRoyalty() external view returns (uint16);

    // @dev Get the current secondary marketplace royalty
    function secondaryMarketplaceRoyalty() external view returns (uint16);

    // @dev for retriving if a memberships is allowed to a ticket
    function isMembershipAllowedForTicket(uint256 ticketId, address contractAddress) external view returns (bool);

    // @dev for retriving if a membership token is allowed to a ticket
    function isTokenIdAllowedForTicket(
        uint256 ticketId,
        address contractAddress,
        uint256 tokenId
    ) external view returns (bool);

    // @dev for retriving if a membership token is needed for claiming a ticket
    function isTokenIdNeededForTicket(uint256 ticketId, address contractAddress) external view returns (bool);

    // @dev for retriving if an event is paused
    function pausedEvents(uint256 eventId) external view returns (bool);

    // @dev for retriving if an address is collaborator of an event
    function collaborators(uint256 eventId, address collaborator) external view returns (bool);
}

/**
 * @title Ticket Tokens Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/Tickets.sol
 */
interface ITicket is IERC1155 {
    /// @dev for publishing new Tickets
    function mintBatch(
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        string[] calldata uris,
        bytes memory data
    ) external;

    /// @dev for deleting Tickets
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    // @dev for editing Tickets metadata
    function setUri(uint256 tokenId, string calldata tokenURI) external;
}

/**
 * @title Events Tokens Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/Events.sol
 */
interface IEvent is IERC721 {

}

/**
 * @title The Fanz's Tickets Marketplace
 * @dev The Fanz's Tickets Marketplace is a smart contract that allows you manage events and tickets.
 * @author The Fanz's Team. See https://fanz.events/
 * Features: create/delete events and tickets, buy and sell tickets, modify royalties.
 */
contract TicketsMarketplace is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* Structs */
    struct BulkTicketsInfo {
        uint256[] newTicketIds;
        uint256[] amounts;
        string[] uris;
    }

    /* Storage */

    /// @dev Reference to Ticket (ERC1155) contract
    address public ticketAddress;

    /// @dev Reference to Event (ERC721) contract
    address public eventAddress;

    /// @dev Reference to Admin contract
    address public adminAddress;

    /// @dev Reference to Membership contract
    address public membershipAddress;

    /// @dev Mapping of ticket per event - [eventId, [ticketIds]]
    mapping(uint256 => uint256[]) public eventTickets;

    /// @dev Mapping of ticket properties (creator, royalties, etc.) - [ticketId, Models.AssetProperties]
    mapping(uint256 => Models.AssetProperties) public ticketsProperties;

    /// @dev Market offers: Mapping of selling info - [seller, [ticketId, Models.Offer]]
    mapping(address => mapping(uint256 => Models.Offer)) public offers;

    /// @dev the Ticket's Id's counter
    CountersUpgradeable.Counter internal _ticketIds;

    /// @dev Mapping of event per ticket - [ticketId, [eventId]]
    mapping(uint256 => uint256) public eventOfTicket;

    /// @dev Mapping of private tickets
    mapping(uint256 => bool) public privateTickets;

    /// @dev the Allowance's Id's counter
    CountersUpgradeable.Counter internal _allowanceIds;

    /// @dev Mapping of allowances per ticket [ticketId, [allowanceId, Allowance]]
    mapping(uint256 => mapping(uint256 => Models.Allowance)) public allowances;

    /// @dev Mapping of ERC20 payments [ticketId, addressERC]
    mapping(address => mapping(uint256 => address)) public tokenPaymentType;

    /// @dev Allowed ERC20 token for payment
    address[] public validErc20;

    /* Events */

    /// @dev Event emitted when a new ticket is created and published on the marketplace
    event TicketPublished(
        uint256 indexed eventId,
        address organizer,
        uint256 indexed ticketId,
        uint256 amount,
        Models.NewAssetSaleInfo saleInfo,
        string uri
    );

    /// @dev Event emitted when an ticket's URI is modified
    event TicketEdited(uint256 indexed ticketId, string newUri);

    /// @dev Event emitted when a ticket is deleted
    event TicketsDeleted(uint256[] ids, address owner, uint256[] amounts);

    /// @dev Event emitted when a ticket is sold
    event TicketBought(uint256 indexed ticketId, address seller, address buyer, uint256 price, uint256 amount);

    /// @dev Event emitted when a ticket is claimed by membership
    event TicketClaimed(uint256 indexed ticketId, address seller, address buyer);

    /// @dev Event emitted when a new sale Models.Offer is published
    event AskSetted(uint256 indexed ticketId, address indexed seller, uint256 ticketPrice, uint256 amount, address erc20token);

    /// @dev Event emitted when a sale Models.Offer is deleted
    event AskRemoved(address indexed seller, uint256 indexed ticketId);

    /// @dev Event emmited when the primary marketplace royalty is modified on a ticket
    event PrimaryMarketRoyaltyModifiedOnTicket(uint256 indexed ticketId, uint256 newRoyalty);

    /// @dev Event emmited when the secondary marketplace royalty is modified on a ticket
    event SecondaryMarketRoyaltyModifiedOnTicket(uint256 indexed ticketId, uint256 newRoyalty);

    /// @dev Event emmited when the creator royalty is modified on a ticket
    event CreatorRoyaltyModifiedOnTicket(uint256 indexed ticketId, uint256 newRoyalty);

    /// @dev Event emmited when an allowance is added to a ticket
    event AllowanceAdded(uint256 indexed ticketId, uint256 indexed allowanceId, Models.AllowanceInput allowance);

    /// @dev Event emmited when an allowance is removed from a ticket
    event AllowanceRemoved(uint256 indexed ticketId, uint256 indexed allowanceId);

    /// @dev Event emmited when an allowance is consumed
    event AllowanceConsumed(uint256 indexed allowanceId);

    /* Modifiers */

    /// @dev Verifies that the sender is either the marketplace's owner or the given ticket's creator.
    modifier onlyTicketCreatorOrOwner(uint256 ticketId) {
        require(ticketsProperties[ticketId].creator == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        _;
    }

    /// @dev Verifies that the sender is the given ticket's creator.
    modifier onlyTicketCreator(uint256 ticketId) {
        require(ticketsProperties[ticketId].creator == msg.sender, 'Only creator is allowed!');
        _;
    }

    /// @dev Verifies that the sender is the given ticket's creator.
    modifier onlyEventCollaborator(uint256 ticketId) {
        require(
            ticketsProperties[ticketId].creator == msg.sender || IAdmin(adminAddress).collaborators(eventOfTicket[ticketId], msg.sender) == true,
            'Only collaborator is allowed!'
        );
        _;
    }

    /// @dev Verifies that the sender is the Admin Contract.
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, 'Only Admin contract is allowed!');
        _;
    }

    /// @dev Verifies that the sender is the Admin Contract.
    modifier onlyAdminOrOrganizer(uint256 eventId) {
        require(msg.sender == adminAddress || msg.sender == IEvent(eventAddress).ownerOf(eventId), 'Only Admin or organizer!');
        _;
    }

    /// @dev Verifies that the sender has an allowed membership for the given ticket.
    modifier hasAllowedMembership(
        address claimer,
        uint256 ticketId,
        address contractAddress,
        uint256 tokenId
    ) {
        bool isTokenNeeded = IAdmin(adminAddress).isTokenIdNeededForTicket(ticketId, contractAddress);
        // Check if the membership is allowed fot the given ticket
        require(IAdmin(adminAddress).isMembershipAllowedForTicket(ticketId, contractAddress), 'Membership not allowed!');
        require(
            !isTokenNeeded || IAdmin(adminAddress).isTokenIdAllowedForTicket(ticketId, contractAddress, tokenId),
            'Membership token not allowed!'
        );
        require(
            ERC165Checker.supportsERC165(contractAddress) &&
                (IERC165(contractAddress).supportsInterface(type(IERC721).interfaceId) ||
                    IERC165(contractAddress).supportsInterface(type(IERC1155).interfaceId)),
            'Contract dont support ERC165!'
        );

        // Check if sender owns the membership
        if (IERC165(contractAddress).supportsInterface(type(IERC721).interfaceId)) {
            // Membership is ERC721 compatible
            if (!isTokenNeeded) {
                require(IERC721(contractAddress).balanceOf(claimer) > 0, 'Membership not owned!');
            } else {
                require(IERC721(contractAddress).ownerOf(tokenId) == claimer, 'Membership token not owned!');
            }
        } else {
            require(IERC1155(contractAddress).balanceOf(claimer, tokenId) > 0, 'Membership token not owned!');
        }
        _;
    }

    /// @dev Verifies that the erc20address is valid.
    modifier isValidErc20Address(address erc20Address) {
        bool isValid = erc20Address == address(0);
        for (uint256 i = 0; i < validErc20.length; i++) {
            if (validErc20[i] == erc20Address) {
                isValid = true;
            }
        }
        require(isValid, 'Address is not an ERC20 token.');
        _;
    }

    /* Initializer */

    /**
     *  @dev Constructor.
     *  @param _ticketAddress Address of the Ticket contract
     *  @param _eventAddress Address of the Event contract
     */
    function initialize(
        address _ticketAddress,
        address _eventAddress,
        address _adminAddress,
        address _membershipAddress
    ) external initializer {
        ticketAddress = _ticketAddress;
        eventAddress = _eventAddress;
        adminAddress = _adminAddress;
        membershipAddress = _membershipAddress;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /* External */

    /**
     *  @dev Publish new tickets for an event.
     *  @param eventId The id of the event which will contain the new tickets
     *  @param tickets Ticket's information (metadata's uri, amount to sell, price, etc.), See NewTicket struct.
     *  @param memberships The memberships to be assigned for each ticket
     */
    function publishTickets(
        uint256 eventId,
        Models.NewAssetSaleInfo[] calldata tickets,
        Models.MembershipsInfo calldata memberships
    ) external whenNotPaused returns (uint256[] memory ticketIds) {
        return publishTicketsForOrganizer(eventId, msg.sender, tickets, memberships);
    }

    /**
     *  @dev Modifies tickets URIs.
     *  @param ticketIds The ids of the tickets to be edited
     *  @param newUris The new URIs
     */
    function setTicketUriBatch(uint256[] memory ticketIds, string[] calldata newUris) external whenNotPaused {
        for (uint256 i = 0; i < ticketIds.length; i++) {
            setTicketUri(ticketIds[i], newUris[i]);
        }
    }

    /**
     *  @dev Bulk deletes a ticket.
     *  @param ids The ids of the tickets to be deleted
     *  @param amounts The amounts of the tickets to be deleted
     */
    function deleteTickets(uint256[] memory ids, uint256[] memory amounts) external whenNotPaused {
        require(ids.length == amounts.length, 'Ids and amounts count mismatch.');
        for (uint256 i = 0; i < ids.length; i++) {
            require(ticketsProperties[ids[i]].creator == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        }

        ITicket(ticketAddress).burnBatch(msg.sender, ids, amounts);

        emit TicketsDeleted(ids, msg.sender, amounts);
    }

    /**
     *  @dev Claim free Ticket.
     *  @param ticketId The id of the ticket to be claimed
     *  @param claimer Address of the person who would be the ticket holder
     *  @param allowanceId Allowance used to claim ticket in case its private
     */
    function claimFreeTicket(
        uint256 ticketId,
        address claimer,
        uint256 allowanceId
    ) external whenNotPaused {
        _buyMarketTicket(ticketId, ticketsProperties[ticketId].creator, 1, allowanceId, claimer);
    }

    /**
     *  @dev Claim a ticket with an allowed membership.
     *  @param ticketId The id of the ticket to be claimed
     *  @param contractAddress The address of the contract of the membership
     *  @param tokenId The id of the membership if needed
     *  @param claimer The address of the future holder of the ticket
     */
    function claimTicketByMembership(
        uint256 ticketId,
        address contractAddress,
        uint256 tokenId,
        address claimer,
        uint256 allowanceId
    ) external hasAllowedMembership(claimer, ticketId, contractAddress, tokenId) whenNotPaused {
        require(IAdmin(adminAddress).pausedEvents(eventOfTicket[ticketId]) == false, 'Event is paused.');
        address creator = ticketsProperties[ticketId].creator;
        require(ITicket(ticketAddress).balanceOf(creator, ticketId) >= 1, 'Creator hasnt enough tickets.');
        require(ITicket(ticketAddress).balanceOf(claimer, ticketId) == 0, 'Claimer has one ticket.');
        require(offers[creator][ticketId].amount >= 1, 'Not enough tickets for claim');
        if (privateTickets[ticketId] == true) {
            _consumeAllowance(claimer, ticketId, allowanceId, 1);
        }

        ITicket(ticketAddress).safeTransferFrom(address(creator), claimer, ticketId, 1, '');
        offers[creator][ticketId].amount -= 1;

        emit TicketClaimed(ticketId, creator, claimer);
    }

    /**
     *  @dev Buy market Tickets.
     *  @param ticketId The id of the ticket to buy
     *  @param seller The seller from whom would like to buy (should be a sale Models.Offer setted)
     *  @param amount Amount of tickets to buy (Tickets are ERC1155)
     */
    function buyMarketTicket(
        uint256 ticketId,
        address seller,
        uint256 amount,
        uint256 allowanceId
    ) external payable whenNotPaused nonReentrant {
        _buyMarketTicket(ticketId, seller, amount, allowanceId, msg.sender);
    }

    /**
     *  @dev Buy market Tickets.
     *  @param ticketId The id of the ticket to buy
     *  @param seller The seller from whom would like to buy (should be a sale Models.Offer setted)
     *  @param amount Amount of tickets to buy (Tickets are ERC1155)
     *  @param recipient Address that will receive the ticket
     */
    function buyMarketTicketWithRecipient(
        uint256 ticketId,
        address seller,
        uint256 amount,
        uint256 allowanceId,
        address recipient
    ) external payable whenNotPaused nonReentrant {
        _buyMarketTicket(ticketId, seller, amount, allowanceId, recipient);
    }

    function claimAllowanceAndBuyTicket(
        uint256 ticketId,
        address seller,
        Models.AllowanceInput calldata allowance
    ) external payable whenNotPaused nonReentrant onlyEventCollaborator(ticketId) {
        require(allowance.allowedAddresses.length == 1, 'The should be one recipient');
        require(offers[seller][ticketId].price == 0, 'The ticket must be free');
        uint256 allowanceId = _addAllowance(ticketId, allowance);
        _buyMarketTicket(ticketId, seller, allowance.amount, allowanceId, allowance.allowedAddresses[0]);
    }

    /**
     *  @dev Sets a new sale Models.Offer.
     *  @param ticketId The id of the ticket to set the sale Models.Offer (sender should have balance of this one)
     *  @param ticketPrice The price to be setted for this Models.Offer
     *  @param amount The amount of tickets that will be available for sale
     */
    function setAsk(
        uint256 ticketId,
        uint256 ticketPrice,
        uint256 amount
    ) external whenNotPaused {
        _setAsk(ticketId, ticketPrice, amount, address(0));
    }

    /**
     *  @dev Sets a new sale Models.Offer.
     *  @param ticketId The id of the ticket to set the sale Models.Offer (sender should have balance of this one)
     *  @param ticketPrice The price to be setted for this Models.Offer
     *  @param amount The amount of tickets that will be available for sale
     */
    function setAskWithErc20(
        uint256 ticketId,
        uint256 ticketPrice,
        uint256 amount,
        address erc20address
    ) external whenNotPaused {
        _setAsk(ticketId, ticketPrice, amount, erc20address);
    }

    /**
     *  @dev Removes a sale Models.Offer
     *  @param ticketId The id of the ticket to remove the sale Models.Offer (only sender's Models.Offer)
     */
    function removeAsk(uint256 ticketId) external whenNotPaused {
        require(IAdmin(adminAddress).pausedEvents(eventOfTicket[ticketId]) == false, 'Event is paused.');
        require(ITicket(ticketAddress).balanceOf(msg.sender, ticketId) > 0, 'Sender has no ticket.');

        delete offers[msg.sender][ticketId];
        emit AskRemoved(msg.sender, ticketId);
    }

    /**
     *  @dev Modifies creator's royalty for a given Ticket.
     *  @param ticketId The id of the ticket whose royalty will be modified
     *  @param newCreatorRoyalty The new royalty to be setted
     */
    function modifyCreatorRoyaltyOnTicket(uint256 ticketId, uint256 newCreatorRoyalty) external onlyTicketCreator(ticketId) whenNotPaused {
        require(newCreatorRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketId].secondaryMarketRoyalty), 'Above 100%.');

        ticketsProperties[ticketId].creatorRoyalty = newCreatorRoyalty;

        emit CreatorRoyaltyModifiedOnTicket(ticketId, newCreatorRoyalty);
    }

    function modifyCreatorRoyaltyOnEvent(uint256 eventId, uint256 newCreatorRoyalty) external onlyAdmin whenNotPaused {
        uint256[] memory ticketIds = eventTickets[eventId];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            require(newCreatorRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketIds[i]].secondaryMarketRoyalty), 'Above 100%.');
            ticketsProperties[ticketIds[i]].creatorRoyalty = newCreatorRoyalty;
            emit CreatorRoyaltyModifiedOnTicket(ticketIds[i], newCreatorRoyalty);
        }
    }

    function deleteEvent(uint256 eventId) external onlyAdmin whenNotPaused {
        delete eventTickets[eventId];
    }

    function changeEventOwnerInTicketsForEvent(uint256 eventId, address newOwner) external onlyAdmin whenNotPaused {
        uint256[] memory tickets = eventTickets[eventId];
        for (uint256 i = 0; i < tickets.length; i++) {
            ticketsProperties[tickets[i]].creator = newOwner;
        }
    }

    /**
     *  @dev Modifies Primary Marketplace royalty for a given ticket.
     *  @param ticketId The id of the ticket whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifyPrimaryMarketplaceRoyaltyOnTicket(uint256 ticketId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        ticketsProperties[ticketId].primaryMarketRoyalty = newMarketplaceRoyalty;

        emit PrimaryMarketRoyaltyModifiedOnTicket(ticketId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Secondary Marketplace royalty for a given ticket.
     *  @param ticketId The id of the ticket whose royalty will be modified
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifySecondaryMarketplaceRoyaltyOnTicket(uint256 ticketId, uint256 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        require(newMarketplaceRoyalty <= (HUNDRED_PERCENT - ticketsProperties[ticketId].creatorRoyalty), 'Above 100%.');

        ticketsProperties[ticketId].secondaryMarketRoyalty = newMarketplaceRoyalty;

        emit SecondaryMarketRoyaltyModifiedOnTicket(ticketId, newMarketplaceRoyalty);
    }

    /**
     *  @dev Add allowed ERC20 address.
     *  @param erc20Addresses address of token to add.
     */
    function setAllowedErc20(address[] calldata erc20Addresses) external onlyOwner whenNotPaused {
        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            require(erc20Addresses[i] != address(0), 'Cant use address 0x0');
        }
        delete validErc20;
        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            validErc20.push(erc20Addresses[i]);
        }
    }

    function ticketCreator(uint256 ticketId) external view returns (address) {
        return ticketsProperties[ticketId].creator;
    }

    /**
     *  @dev Modifies a ticket's URI.
     *  @param ticketId The id of the ticket to be edited
     *  @param newUri The new URI
     */
    function setTicketUri(uint256 ticketId, string calldata newUri) public whenNotPaused onlyTicketCreatorOrOwner(ticketId) {
        ITicket(ticketAddress).setUri(ticketId, newUri);

        emit TicketEdited(ticketId, newUri);
    }

    /**
     *  @dev Adds an Allowance (amount for allowed addresses) for a ticket
     */
    function addAllowance(uint256 ticketId, Models.AllowanceInput calldata allowance) public onlyEventCollaborator(ticketId) returns (uint256) {
        return _addAllowance(ticketId, allowance);
    }

    /**
     *  @dev Removes an Allowance (amount for allowed addresses) for a ticket
     */
    function removeAllowance(uint256 ticketId, uint256 allowanceId) public onlyEventCollaborator(ticketId) {
        _removeAllowance(ticketId, allowanceId);
    }

    /* public */

    /**
     *  @dev Publish new tickets for an event.
     *  @param eventId The id of the event which will contain the new tickets
     *  @param organizer The address of the event organizer, to own the tickets
     *  @param tickets Ticket's information (metadata's uri, amount to sell, price, etc.), See NewTicket struct.
     *  @param memberships The memberships to be assigned for each ticket
     */
    function publishTicketsForOrganizer(
        uint256 eventId,
        address organizer,
        Models.NewAssetSaleInfo[] calldata tickets,
        Models.MembershipsInfo calldata memberships
    ) public whenNotPaused nonReentrant onlyAdminOrOrganizer(eventId) returns (uint256[] memory ticketIds) {
        uint256 ticketsLength = tickets.length;
        BulkTicketsInfo memory bulkInfo = BulkTicketsInfo(
            new uint256[](ticketsLength),
            new uint256[](ticketsLength),
            new string[](ticketsLength)
        );

        // Create Ticket
        for (uint256 i = 0; i < ticketsLength; i++) {
            require(
                tickets[i].royalty <= (HUNDRED_PERCENT - IAdmin(adminAddress).secondaryMarketplaceRoyalty()),
                'Creator royalty above the limit.'
            );
            require(tickets[i].price == 0 || tickets[i].price >= MINIMUM_ASK, 'Asking price below minimum.');
            require(tickets[i].amountToSell <= tickets[i].amount, 'Amount to sell is too high.');

            bool isValidErc20 = (address(0) == tickets[i].erc20token);
            for (uint256 j = 0; j < validErc20.length; j++) {
                if (validErc20[j] == tickets[i].erc20token) {
                    isValidErc20 = true;
                }
            }
            require(isValidErc20, 'Address is not an ERC20 token.');
            require(tickets[i].erc20token == address(0) || tickets[i].price > 0, 'Ticket is free when ERC20 used');

            _ticketIds.increment();
            uint256 ticketId = _ticketIds.current();
            ticketsProperties[ticketId] = Models.AssetProperties(
                tickets[i].royalty,
                IAdmin(adminAddress).primaryMarketplaceRoyalty(),
                IAdmin(adminAddress).secondaryMarketplaceRoyalty(),
                organizer,
                tickets[i].isResellable
            );
            offers[organizer][ticketId] = Models.Offer(tickets[i].amountToSell, tickets[i].price);
            tokenPaymentType[organizer][ticketId] = tickets[i].erc20token;
            bulkInfo.newTicketIds[i] = ticketId;
            eventTickets[eventId].push(ticketId);
            eventOfTicket[ticketId] = eventId;
            bulkInfo.amounts[i] = tickets[i].amount;
            bulkInfo.uris[i] = tickets[i].uri;
            if (tickets[i].isPrivate == true) {
                privateTickets[ticketId] = true;
            }
            for (uint256 a = 0; a < tickets[i].allowances.length; a++) {
                _addAllowance(ticketId, tickets[i].allowances[a]);
            }
        }

        if (memberships.addresses.length > 0) {
            IAdmin(adminAddress).assignMemberships(bulkInfo.newTicketIds, memberships.addresses, memberships.ids);
        }

        ITicket(ticketAddress).mintBatch(organizer, bulkInfo.newTicketIds, bulkInfo.amounts, bulkInfo.uris, '');

        for (uint256 i = 0; i < ticketsLength; i++) {
            emit TicketPublished(eventId, organizer, bulkInfo.newTicketIds[i], bulkInfo.amounts[i], tickets[i], bulkInfo.uris[i]);
        }

        return eventTickets[eventId];
    }

    /**
     *  @dev Pauses the contract in case of an emergency. Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *  @dev Re-plays the contract in case a prior emergency has been solved. Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *  @dev Retrieves if the event is paused.
     */
    function pausedEvents(uint256 ticketId) public view returns (bool) {
        return IAdmin(adminAddress).pausedEvents(eventOfTicket[ticketId]);
    }

    /**
     *  @dev Retrieves if the given address is allowed for the give allowance.
     */
    function isAddressAllowed(
        uint256 ticketId,
        uint256 allowanceId,
        address operator
    ) public view returns (bool) {
        return allowances[ticketId][allowanceId].allowed[operator];
    }

    /**
     *  @dev Retrieves the amount left in a given allowance.
     */
    function allowanceAmountLeft(uint256 ticketId, uint256 allowanceId) public view returns (uint256) {
        return allowances[ticketId][allowanceId].amount;
    }

    /**
     *  @dev Consumes a ticket from an allowance.
     */
    function _consumeAllowance(
        address sender,
        uint256 ticketId,
        uint256 allowanceId,
        uint256 amount
    ) internal {
        require(_isAllowed(sender, ticketId, allowanceId), 'Not allowed!');
        require(allowances[ticketId][allowanceId].amount >= amount, 'Available amount is not enough.');
        allowances[ticketId][allowanceId].amount -= amount;
        emit AllowanceConsumed(allowanceId);
        if (allowances[ticketId][allowanceId].amount == 0) {
            _removeAllowance(ticketId, allowanceId);
        }
    }

    /**
     *  @dev Sets a new sale Models.Offer.
     *  @param ticketId The id of the ticket to set the sale Models.Offer (sender should have balance of this one)
     *  @param ticketPrice The price to be setted for this Models.Offer
     *  @param amount The amount of tickets that will be available for sale
     *  @param erc20Address The erc20 address of the ticket
     */
    function _setAsk(
        uint256 ticketId,
        uint256 ticketPrice,
        uint256 amount,
        address erc20Address
    ) internal whenNotPaused isValidErc20Address(erc20Address) {
        require(IAdmin(adminAddress).pausedEvents(eventOfTicket[ticketId]) == false, 'Event is paused.');
        require(ticketPrice >= MINIMUM_ASK, 'Price below minimum.');
        require(ITicket(ticketAddress).balanceOf(msg.sender, ticketId) >= amount, 'Sender does not have ticket.');
        require(
            ticketsProperties[ticketId].isResellable == true || ticketsProperties[ticketId].creator == msg.sender,
            'Ticket is not resellable.'
        );
        require(erc20Address == address(0) || ticketPrice > 0, 'Ticket cant be free with ERC20');

        offers[msg.sender][ticketId].price = ticketPrice;
        offers[msg.sender][ticketId].amount = amount;
        tokenPaymentType[msg.sender][ticketId] = erc20Address;

        emit AskSetted(ticketId, msg.sender, ticketPrice, amount, erc20Address);
    }

    /**
     *  @dev Adds an Allowance (amount for allowed addresses) for a ticket
     */
    function _addAllowance(uint256 ticketId, Models.AllowanceInput calldata allowance) internal returns (uint256) {
        uint256 id = _allowanceIds.current();
        _allowanceIds.increment();
        for (uint256 i = 0; i < allowance.allowedAddresses.length; i++) {
            allowances[ticketId][id].allowed[allowance.allowedAddresses[i]] = true;
        }
        allowances[ticketId][id].amount = allowance.amount;
        emit AllowanceAdded(ticketId, id, allowance);
        return id;
    }

    /**
     *  @dev Removes an Allowance (amount for allowed addresses) for a ticket
     */
    function _removeAllowance(uint256 ticketId, uint256 allowanceId) internal {
        delete allowances[ticketId][allowanceId];
        emit AllowanceRemoved(ticketId, allowanceId);
    }

    function _buyMarketTicket(
        uint256 ticketId,
        address seller,
        uint256 amount,
        uint256 allowanceId,
        address recipient
    ) internal {
        require(IAdmin(adminAddress).pausedEvents(eventOfTicket[ticketId]) == false, 'Event is paused.');
        require(ITicket(ticketAddress).balanceOf(seller, ticketId) >= amount, 'Seller hasnt enough ticket.');
        require(amount <= offers[seller][ticketId].amount, 'Not enough ticket for sale');
        require(recipient != seller, 'You cant buy your own ticket');

        if (tokenPaymentType[seller][ticketId] == address(0)) {
            require(msg.value == (amount * offers[seller][ticketId].price), 'Value does not match price');
        } else {
            require(msg.value == 0, 'Payments with ERC20 value is 0');
        }

        address creator = ticketsProperties[ticketId].creator;
        if (privateTickets[ticketId] == true && seller == creator) {
            _consumeAllowance(recipient, ticketId, allowanceId, amount);
        }

        uint256 ticketPrice = offers[seller][ticketId].price;
        uint256 previousBalance = address(this).balance;
        offers[seller][ticketId].amount -= amount;

        uint256 marketplaceShare = MarketplaceHelper.calculateFee(ticketPrice, ticketsProperties[ticketId].primaryMarketRoyalty);
        uint256 creatorShare = ticketPrice - marketplaceShare;
        uint256 sellerShare = 0;

        if (seller != creator && ticketPrice != 0) {
            marketplaceShare = MarketplaceHelper.calculateFee(ticketPrice, ticketsProperties[ticketId].secondaryMarketRoyalty);
            creatorShare = MarketplaceHelper.calculateFee(ticketPrice, ticketsProperties[ticketId].creatorRoyalty);
            sellerShare = ticketPrice - marketplaceShare - creatorShare;
        }

        if (tokenPaymentType[seller][ticketId] == address(0)) {
            if (ticketPrice == 0) {
                require(amount == 1, 'Can only buy one free ticket');
                require(ITicket(ticketAddress).balanceOf(recipient, ticketId) == 0, 'Claimer has one ticket.');
            } else {
                // primary sale, selling by event organizer
                if (sellerShare != 0) {
                    MarketplaceHelper.transferFundsSupportingGnosisSafe(seller, sellerShare * amount);
                } // Untrusted transfer
                MarketplaceHelper.transferFundsSupportingGnosisSafe(creator, creatorShare * amount); // Untrusted transfer
                MarketplaceHelper.transferFundsSupportingGnosisSafe(owner(), marketplaceShare * amount); // Trusted transfer, Gnosis Safe Wallet
            }
        } else {
            require(
                IERC20(tokenPaymentType[seller][ticketId]).allowance(address(this), msg.sender) >= amount * offers[seller][ticketId].price,
                'Not enough erc20 allowed'
            );

            require(
                IERC20(tokenPaymentType[seller][ticketId]).balanceOf(msg.sender) >= amount * offers[seller][ticketId].price,
                'Not enough erc20'
            );
            if (sellerShare != 0) {
                MarketplaceHelper.transferERC20ToAccount(tokenPaymentType[seller][ticketId], msg.sender, seller, sellerShare * amount); // Untrusted transfer
            }
            MarketplaceHelper.transferERC20ToAccount(tokenPaymentType[seller][ticketId], msg.sender, creator, creatorShare * amount); // Untrusted transfer
            MarketplaceHelper.transferERC20ToAccount(tokenPaymentType[seller][ticketId], msg.sender, owner(), marketplaceShare * amount);
        }
        ITicket(ticketAddress).safeTransferFrom(address(seller), recipient, ticketId, amount, '');

        assert((previousBalance - address(this).balance) == msg.value); // All value should be distributed.

        emit TicketBought(ticketId, seller, recipient, ticketPrice, amount);
    }

    /**
     *  @dev Retrieves true if the claimer is allowed to claim.
     */
    function _isAllowed(
        address operator,
        uint256 ticketId,
        uint256 allowanceId
    ) internal view returns (bool) {
        return allowances[ticketId][allowanceId].allowed[operator] == true && allowances[ticketId][allowanceId].amount > 0;
    }
}