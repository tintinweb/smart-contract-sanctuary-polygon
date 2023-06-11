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
pragma solidity ^0.8.0;

interface IBlocking {

    // Update the whitelist
    function updateWhitelist(address toToggle) external;

    // Update the blacklist
    function updateBlacklist(address toToggle) external;

    // Check if a requester is allowed to interact with target
    function isAllowed(address requesterAddress, address targetAddress) external view returns (bool);

    // Enable or disable whitelist functionality for self
    function toggleWhiteList() external;

    // Clear our a whitelist or blacklist with a single call
    function clearList(bool clearWhitelist) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IContractHook {

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        int reposts;
        uint256 tipsReceived;
        address tipContract;
        uint256 tipERC20Amount;
        uint postByContract;
        uint256 time;
        uint256 block;
    }

    // The Message data struct
    struct MsgData {
        uint msgID;
        address[2] postedBy;
        string message;
        uint256 paid;
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        MsgStats msgStats;
    }

    // External Contract to call with message details
    function KuthuluHook(MsgData memory msgData) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDOOM {

    // Burn tokens
    function burnTokens(address from, uint256 amount) external returns (bool);

    // Mint Tokens
    function publicMint(uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGroups {

    struct GroupDetails {
        address ownerAddress;
        address[] members;
        string groupName;
        address groupAddress;
        string details;
        string uri;
        string[3] colors;
    }

    // Function to set group details on initial mint
    function setInitialDetails(uint256 _groupID, address _owner, string memory groupName, address setInitialDetails) external;

    // Get group owner address by Group ID
    function getOwnerOfGroupByID(uint256 groupID) external view returns (address);

    // Get a list of members of a group
    function getMembersOfGroupByID(uint256 groupID) external view returns (address[] memory);

    // Check if a user is a member of a group
    function isMemberOfGroupByID(uint256 groupID, address member) external view returns (bool);

    // Get a Group ID from the Group Name
    function getGroupID(string calldata groupName) external view returns (uint256);

    // Get a generated Group Address from a Group ID
    function getGroupAddressFromID(uint256 groupID) external view returns (address);

    // Get Group Name from a Group ID
    function getGroupNameFromID(uint256 groupID) external view returns (string memory);

    // Get Group Details from a Group ID
    function getGroupDetailsFromID(uint256 groupID) external view returns (string memory);

    // Get Group URI from a Group ID
    function getGroupURIFromID(uint256 groupID) external view returns (string memory);

    // Get Avatar Colors from a Group ID
    function getGroupColorsFromID(uint256 groupID) external view returns (string[3] memory);

    // Get a group ID from their generated address
    function getGroupIDFromAddress(address groupAddress) external view returns (uint256);

    // Get the owner address of a group by the group address
    function getOwnerOfGroupByAddress(address groupAddress) external view returns (address);

    // Check if a group is available
    function isGroupAvailable(string calldata groupName) external view returns (bool);

    // Get Group Details
    function groupDetails(uint256 groupID) external view returns (GroupDetails memory);

    // Update Group Ownership on Token transfer (only callable from Token contract overrides)
    function onTransfer(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHashtags {

    // Get Message IDs from a hashtag
    function getMsgIDsFromHashtag(string memory hashtag, uint256 startFrom) external view returns(uint256[] memory);

    // Remove a hashtag from a message
    function removeHashtags(uint256 msgID, string[] calldata hashtagsToToggle) external;

    // Add a hashtag to a message
    function addHashtags(uint256 msgID, string[] memory hashtagsToToggle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IKUtils {
    // Append a string
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) external pure returns (string memory);

    // Convert an address to a string
    function addressToString(address addr) external pure returns (string memory);

    // Is a valid URI
    function isValidURI(string memory str) external pure returns (bool);

    // Is a valid string
    function isValidString(string memory str) external pure returns (bool);

    // Is a valid string for group names
    function isValidGroupString(string memory str) external pure returns (bool);

    // Convert a uint to string
    function toString(uint256 value) external pure returns (string memory);

    // Returns a lowercase version of the string provided
    function _toLower(string memory str) external pure returns (string memory);

    // Check if 2 strings are the same
    function stringsEqual(string memory a, string memory b) external pure returns (bool);

    // Check literal string length (10x gas cost)
    function strlen(string memory s) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILikes {

    // Get a list of a users that liked a post
    function getLikesFromMsgID(uint256 msgID, uint256 startFrom) external view returns(address[] memory);

    // Add a like to a users post
    function removeLike(uint256 msgID, address likedBy) external;

    // Remove a like from a users post
    function addLike(uint256 msgID, address likedBy) external;

    // Check if a user liked a post
    function checkUserLikeMsg(address usrAddress, uint256 msgID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMessageData {

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        uint256 totalInThread;
        int reposts;
        uint256 tipsReceived;
        address tipContract;
        uint256 tipERC20Amount;
        uint postByContract;
        uint256 time;
        uint256 block;
    }

    // The Message data struct
    struct MsgData {
        uint msgID;
        address[2] postedBy;
        string message;
        uint256 paid;
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        uint256 commentID;
        MsgStats msgStats;
    }

    // Get a list of a users posts
    function getMsgsByIDs(uint256[] calldata msgIDs, bool onlyFollowers, address addrFollowing) external view returns (string[][] memory);

    // Add a post to a users mapping
    function removeMsg(uint256 msgID, address requester) external;

    // Remove a post from a user mapping
    function saveMsg(MsgData memory msgData) external;

    // Add Stats to a message
    function addStat(uint8 statType, uint256 msgID, int amount, uint256 tips) external;

    // Get the comment level of a message
    function getMsgCommentLevel(uint256 msgID) external view returns (uint256);

    // Get the address of the poster of a message
    function getPoster(uint256 msgID) external view returns (address);

    // Get a list of groups a message was posted into
    function getInGroups(uint256 msgID) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPosts {

    // Get a list of a users posts or posts of a message
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, uint256[] calldata whatToGet) external view returns(uint256[] memory);

    // Remove a post from a user mapping
    function addPost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) external;

    // Add a post to a users mapping
    function removePost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITagged {

    // Get a list of a messages a user is tagged in
    function getTaggedMsgIDs(address usrAddress, uint256 startFrom) external view returns(uint256[] memory);

    // Add a tag to a users post
    function removeTags(uint256 msgID, address[] memory addressesTagged) external;

    // Remove a tag from a users post
    function addTags(uint256 msgID, address[] memory addressTagged) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITips {
    // Add tips to a users post
    function addTip(uint256 msgID, address tippedBy, uint256 tips) external;

    // Add tips to tagged accounts
    function addTaggedTips(address[] memory taggedAccounts, uint256 tipPerTag, address tipContract) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserProfiles {

    // Update the post count for a user
    function updatePostCount(address posterAddress, bool isComment) external;

    // Log a post to the contract
    function recordPost(address posterAddress, uint256 tipPerTag, address[] calldata tipReceivers, uint256 isCommentOf, address tipContract, uint256 erc20Tips, uint256 msgID) external;

    // Update a users tips sent/received
    function updateUserTips(address targetAddress, uint256 tipsReceived, uint256 tipsSent) external;

    // Update a user profile
    function updateProfile(string calldata handle, string calldata location, string calldata avatar, string calldata _uri, string calldata _bio, bool isGroup) external;

    // Get the profile details of a user
    function getUserDetails(address usrAddress) external view returns(string[] memory);

    // Get a list of addresses that a user is following
    function getFollowings(address posterAddress, uint256 startFrom) external view returns(address[] memory);

    // Get a list of addresses that are following a user
    function getFollowers(address usrAddress, uint256 startFrom) external view returns(string memory);

    // Follow a user
    function followUser(address addressRequester, address addressToFollow) external;

    // Unfollow a user
    function unfollowUser(address addressRequester, address addressToUnfollow) external;

    // Update a users handle and verification level
    function updateHandleVerify(address userAddress, string calldata handle, uint256 verified) external;

    // Update a new groups profiles details
    function setupNewGroup(address groupAddress, string memory groupName, uint256 groupID, address _nftContract) external;

    // Update profile token metadata
    function updateMetadata(address _address, string memory _metadata) external;

    // Update a users avatar
    function setAvatar(address profileAddress, string calldata imageURI, address _nftContract, uint256 tokenId, string calldata metadata, uint256 _networkID) external;

    // Get a users Contract Hook address
    function getContractHook(address usrAddress) external view returns(address);
}

/*

                                   :-++++++++=:.
                                -++-.   ..   .-++-
                              -*=      *==*      -*-
                             ++.                   ++
                            +*     =++:    :+*=.    ++
                           :*.    .: .:    :: :.    .*-
                           =*                        *+
                           =**==+=:            .=*==**+
                .-----:.  =*..--..*=          =*:.--..*=  .:-----:
                 -******= *: *::* .+          +: *-:* :* =******=
                  -*****= *: *..*.              .*. *..* =*****=
                  -****** ++ =**=                =**= =* +*****-
                    :****= ++-:                    :-++ =****:
                   :--:.:+***:-.                  .-:+**+:.:--:.
                 -*-::-+= .**                        +*. =*-::-*-
                 -*-:   +*.+*.  .--            :-.   *+.++   .:*-
                   :*+  :*+--=*=*-=*    --.   *+:*++=--+*-  =*:
                    ++  -*:    +* :*  .*--*.  *- *+    :*=  =*
                    ++  -*=*+  :* :*  .*. *.  *- *:  +*=*=  +*
                    **  .+=*+  :*++*  .*++*.  *+=*:  +*=*.  +*.
                  =*-*=    +*  :*.-*  .*::*.  *-.*-  *+    =*-++.
                 *=   -++- =*  .*=++  .*..*:  ++-*.  *= -++-   =*.
                -*       .  *=   ::   ++  ++   ::   -*.         *=
                -*:..........**=:..:=*+....+*=-..:-**:.........:*=

   ▄█   ▄█▄ ███    █▄      ███        ▄█    █▄    ███    █▄   ▄█       ███    █▄
  ███ ▄███▀ ███    ███ ▀█████████▄   ███    ███   ███    ███ ███       ███    ███
  ███▐██▀   ███    ███    ▀███▀▀██   ███    ███   ███    ███ ███       ███    ███
 ▄█████▀    ███    ███     ███   ▀  ▄███▄▄▄▄███▄▄ ███    ███ ███       ███    ███
▀▀█████▄    ███    ███     ███     ▀▀███▀▀▀▀███▀  ███    ███ ███       ███    ███
  ███▐██▄   ███    ███     ███       ███    ███   ███    ███ ███       ███    ███
  ███ ▀███▄ ███    ███     ███       ███    ███   ███    ███ ███▌    ▄ ███    ███
  ███   ▀█▀ ████████▀     ▄████▀     ███    █▀    ████████▀  █████▄▄██ ████████▀
  ▀                                                          ▀

    @title KUTHULU
    @dev https://www.KUTHULU.xyz
    v0.9.1
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IUserProfiles.sol";
import "./interfaces/IKUtils.sol";
import "./interfaces/IHashtags.sol";
import "./interfaces/ITagged.sol";
import "./interfaces/IPosts.sol";
import "./interfaces/ILikes.sol";
import "./interfaces/IMessageData.sol";
import "./interfaces/IDOOM.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/ITips.sol";
import "./interfaces/IBlocking.sol";
import "./interfaces/IContractHook.sol";



contract KUTHULU is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) private admins;

    // ERC20 Contract Counters
    mapping(address => uint256) contractCounters;

    struct Counters {
        uint256 messages;   // Total messages posted ever
        uint256 comments;   // Total comments posted ever
        uint256 groupPosts; // Total group posts posted ever
        uint256 reposts;    // Total reposts posted ever
        uint256 hashtags;   // Total hashtags posted ever
        uint256 tags;       // Total tags posted ever
        uint256 likes;      // Total likes posted ever
        uint256 tips;       // Total tips posted ever
        uint256 follows;    // Total follows posted ever
    }
    
    Counters counters;

    // Max length of messages to save (UTF-8 single byte characters only)
    uint256 public maxMessageLength;

    // ERC20 Receiver for payment via ERC20
    IERC20Upgradeable public paymentToken;

    // Cost to post a message
    uint256 public costToPost;

    // Cost to like aa post
    uint256 public cutToPoster;

    // The max number of messages that can be returned at once
    uint256 public maxMsgReturnCount;

    // Link the User Profiles contract
    IUserProfiles public userProfiles;

    // Link to the KUtils
    IKUtils public KUtils;

    // Link to the Hashtags
    IHashtags public Hashtags;

    // Link to the Tagged Accounts
    ITagged public Tagged;

    // Link to the Posts
    IPosts public Posts;

    // Link to the Likes
    ILikes public Likes;

    // Link to the Message Data
    IMessageData public MessageData;

    // Link to the DOOM Token
    IDOOM public DOOM;

    // Link to the Groups
    IGroups public Groups;

    // Link to the Tips
    ITips public Tips;

    // Link to the Blocking
    IBlocking public Blocking;

    // Link to the ContractHook
    IContractHook public ContractHook;

    // Canary
    string public canary;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20Upgradeable _paymentToken, address _userProfiles, address _kutils, uint256 _costToPost, uint256 _maxMessageLength, uint256 _maxMsgReturnCount, uint256 _cutToPoster) initializer public {
        //    constructor(uint256 _maxHashtagLength) {
        __Pausable_init();
        __Ownable_init();

        // Setup the payment token
        paymentToken = IERC20Upgradeable(_paymentToken);

        // Setup link to User Profiles
        userProfiles = IUserProfiles(_userProfiles);

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup the default Admin
        admins[msg.sender] = true;

        // Initialize the stats
        counters.messages = 0;
        counters.comments = 0;
        counters.groupPosts = 0;
        counters.reposts = 0;
        counters.hashtags = 0;
        counters.tags = 0;
        counters.likes = 0;
        counters.tips = 0;
        counters.follows = 0;

        costToPost = _costToPost;
        maxMessageLength = _maxMessageLength;
        maxMsgReturnCount = _maxMsgReturnCount;
        cutToPoster = _cutToPoster;

        // Initialize the canary
        canary = "safe";
    }



    /*

    EVENTS

    */

    event logMsgPostMsg1(uint256 indexed msgID, address indexed postedBy, string message, string[] hashtags, address[] taggedAccounts);
    event logMsgPostMsg2(uint256 indexed msgID, address indexed proxy, string uri, uint256[5] attribs, uint256[] inGroups);
    event logEraseMsg(uint256 indexed msgID, address indexed poster);



    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Admins Only");
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function setParams(uint256 _maxMsgReturnCount, uint256 _maxMessageLength) public onlyAdmins {
        maxMsgReturnCount = _maxMsgReturnCount;
        maxMessageLength = _maxMessageLength;
    }

    function updateCosts(uint256 _costToPost, uint256 _cutToPoster) public onlyAdmins {
        //  Update the cost of DOOM in wei to post a new message
        costToPost = _costToPost;

        //  Update the cost of DOOM in wei to like a message
        cutToPoster = _cutToPoster;
    }

    function updateCanary(string memory _canary) public onlyAdmins{
        canary = _canary;
    }

    // Contract Addresses
    // 0 = _userProfiles
    // 1 = _hashtags
    // 2 = _tagged
    // 3 = _posts
    // 4 = _likes
    // 5 = _messageData
    // 6 = _doom
    // 7 = _groups
    // 8 = _tips
    // 9 = _blocking
    function updateContracts(IERC20Upgradeable _payments, address[] calldata contracts) public onlyAdmins {
        // Update the contract address of the ERC20 token to be used as payment
        paymentToken = IERC20Upgradeable(_payments);

        // Update the User Profiles contract address
        userProfiles = IUserProfiles(contracts[0]);

        // Update the Hashtags address
        Hashtags = IHashtags(contracts[1]);

        // Update the Tagged addresses
        Tagged = ITagged(contracts[2]);

        // Update the Posts addresses
        Posts = IPosts(contracts[3]);

        // Update the Likes addresses
        Likes = ILikes(contracts[4]);

        // Update the Message Data addresses
        MessageData = IMessageData(contracts[5]);

        // Update the DOOM Token address
        DOOM = IDOOM(contracts[6]);

        // Update the Comments
        Groups = IGroups(contracts[7]);

        // Update the Tips
        Tips = ITips(contracts[8]);

        // Update Blocking
        Blocking = IBlocking(contracts[9]);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Post a new message into KUTHULU
    * @param message : The message you want to post
    * @param _hashtags : (optional) an array of hashtags to associate with the post. Limit to maxHashtags
    * @param taggedAccounts : (optional) an array of addresses to tag with the post. Limit to maxTaggedAccounts
    * @param uri : (optional) a URI to attach to the post. Can be used to attach images / movies / etc
    * @param attribs : an array of post attributes (comment level / comment to / repost of / group ID)
    * @param inGroups : (optional) an array of group ID that this message is being posted into. Must be member of groups
    * @dev Comment Attributes Array
    * @dev 0 = Comment Level Allowed (0 = No comments Allowed, 1 = Comments Allowed)
    * @dev 1 = Message ID of the post it is a comment to
    * @dev 2 = Message ID of post if it's a repost of another post
    * @dev 3 = Group ID to be posted as
    * @dev 4 = 0 = MATIC tips / 1 = Tips from ERC20 Contract (Contract Address is last address in taggedAccount array posted)
    */
    function postMsg(string calldata message, string[] memory _hashtags, address[] calldata taggedAccounts, string calldata uri, uint256[5] calldata attribs, uint256[] memory inGroups) public payable whenNotPaused {

        // Burn DOOM Payment to make post if not an admin
        if(!admins[msg.sender]){
            require(DOOM.burnTokens(msg.sender, costToPost), "No DOOM");
        }

        // Make sure the message is within length limits or that it's a repost
        require(bytes(message).length <= maxMessageLength && (bytes(message).length > 0 || attribs[2] > 0), "Message too long");

        // Initialize the poster address
        address posterAddress = msg.sender;

        // Check for valid comment levels
        require(attribs[0] < 2, "Bad Comment Level");

        // If this is a comment ensure the post exists first
        if (attribs[1] > 0){
            require(attribs[1] <= counters.messages, "Bad Comment Post ID");
        }

        // If this is a repost ensure the post exists first
        if (attribs[2] > 0){
            require(attribs[2] <= counters.messages, "Bad Repost ID");
        }

        // Check for group membership
        if (attribs[3] > 0){
            require(Groups.isMemberOfGroupByID(attribs[3], msg.sender), "Not Member of Group");

            // Set the poster address to be the group
            posterAddress = Groups.getGroupAddressFromID(attribs[3]);
        }

        // Check if blocked from posting in a group
        for (uint g=0; g < inGroups.length; g++) {
            if (inGroups[g] > 0){
                require(Blocking.isAllowed(msg.sender, Groups.getGroupAddressFromID(inGroups[g])), "Group Blocked-0");
            }
        }

        // Check if they're being blocked from tagging a user
        for (uint t=0; t < taggedAccounts.length; t++) {
            require(Blocking.isAllowed(msg.sender, taggedAccounts[t]), "Tag Blocked");
        }

        address tipContract = address(0);

        // If there are tips in ERC20, send those first to ensure they can
        if (attribs[4] != 0){
            // Set the contract address for tips (from the posted taggedAccounts)
            tipContract = taggedAccounts[taggedAccounts.length - 1];
        }

        // If they tipped, send it
        if (msg.value > 0 || attribs[4] > 0){
            Tips.addTaggedTips{value: msg.value}(taggedAccounts, attribs[4], tipContract);
        }

        // If the new message is a comment
        if (attribs[1] > 0){
            // Get the OG poster of this thread
            address origPoster = MessageData.getPoster(attribs[1]);

            // check if the original message is allowing comments
            require(MessageData.getMsgCommentLevel(attribs[1]) == 1, "Comments not allowed");

            // Make sure they're not banned from any groups the original post is part of
            require(Blocking.isAllowed(msg.sender, origPoster) , "Group Blocked-1");

            // Check if blocked from posting in a group that's in the message being commented on
            uint256[] memory origInGroups = MessageData.getInGroups(attribs[1]);
            for (uint g=0; g < origInGroups.length; g++) {
                if (origInGroups[g] > 0){
                    require(Blocking.isAllowed(msg.sender, Groups.getGroupAddressFromID(origInGroups[g])), "Group Blocked-2");
                }
            }

            // If this is a comment, then we don't need the inGroups as it's inheriting it from the post it's a comment to
            inGroups = new uint256[](0);

            // Cut the poster in on the token
            require(paymentToken.transferFrom(msg.sender, origPoster, cutToPoster), "No Payment Token");
        }

        // Increment the amount of messages we have posted
        counters.messages++;

        // Update the hashtag Mapping with this message ID and hashtag
        if (_hashtags.length > 0){
            Hashtags.addHashtags(counters.messages, _hashtags);
        }

        // See if this message is posted via a proxy
        address postProxy = msg.sender == posterAddress ? address(0) : msg.sender;

        IMessageData.MsgData memory newMsg;

        newMsg.msgID = counters.messages;
        newMsg.postedBy = [posterAddress, postProxy];
        newMsg.message = message;
        newMsg.paid = costToPost;
        newMsg.hashtags = _hashtags;
        newMsg.taggedAccounts = taggedAccounts;
        newMsg.asGroup = attribs[3];
        newMsg.inGroups = inGroups;
        newMsg.uri = uri;
        newMsg.commentLevel = attribs[0];
        newMsg.isCommentOf = attribs[1];
        newMsg.isRepostOf = attribs[2];
        newMsg.msgStats.postByContract = tx.origin == msg.sender ? 0 : 1;
        newMsg.msgStats.time = block.timestamp;
        newMsg.msgStats.block = block.number;
        newMsg.msgStats.tipsReceived = msg.value;
        newMsg.msgStats.tipERC20Amount = attribs[4];
        newMsg.msgStats.tipContract = tipContract;

        MessageData.saveMsg(newMsg);

        // Record the message post
        if (taggedAccounts.length > 0 && msg.value > 0){
            userProfiles.recordPost(posterAddress, msg.value / taggedAccounts.length, taggedAccounts, attribs[1], tipContract, attribs[4], counters.messages);
        } else {
            userProfiles.recordPost(posterAddress, 0, taggedAccounts, attribs[1], tipContract, attribs[4], counters.messages);
        }

        // Update Stats
        updateStats(attribs, msg.value, _hashtags.length, taggedAccounts.length, tipContract, attribs[4]);

        // Log it
        emit logMsgPostMsg1(counters.messages, posterAddress, message, _hashtags, taggedAccounts);
        emit logMsgPostMsg2(counters.messages, postProxy, uri, attribs, inGroups);

        // Update the tagged accounts with this message ID and tagged user address
        // Doing this after saving the message so the hook can interact with this post

        if (taggedAccounts.length > 0){

            Tagged.addTags(counters.messages, taggedAccounts);

            for (uint t=0; t < taggedAccounts.length; t++) {

                // Don't do the last address if ERC20 tips were added, as that's the contract address
                if (attribs[4] > 0 && t == taggedAccounts.length){
                    break;
                }

                // Get the Contract Hook for the tagged user if they have one
                address contractHook = userProfiles.getContractHook(taggedAccounts[t]);

                // If they have a contract in place, call it (unless it's back to itself)
                if (contractHook != address(0) && contractHook != msg.sender){
                    // Hook up the interface to the contract
                    ContractHook = IContractHook(contractHook);

                    IContractHook.MsgData memory newMsgCH;

                    newMsgCH.msgID = counters.messages;
                    newMsgCH.postedBy = [posterAddress, postProxy];
                    newMsgCH.message = message;
                    newMsgCH.paid = costToPost;
                    newMsgCH.hashtags = _hashtags;
                    newMsgCH.taggedAccounts = taggedAccounts;
                    newMsgCH.asGroup = attribs[3];
                    newMsgCH.inGroups = inGroups;
                    newMsgCH.uri = uri;
                    newMsgCH.commentLevel = attribs[0];
                    newMsgCH.isCommentOf = attribs[1];
                    newMsgCH.isRepostOf = attribs[2];
                    newMsgCH.msgStats.postByContract = newMsg.msgStats.postByContract;
                    newMsgCH.msgStats.time = block.timestamp;
                    newMsgCH.msgStats.block = block.number;
                    newMsgCH.msgStats.tipsReceived = msg.value;
                    newMsgCH.msgStats.tipERC20Amount = attribs[4];
                    newMsgCH.msgStats.tipContract = tipContract;

                    // Users Contract Hook must return true otherwise we fail the entire post and let the poster know
                    require(ContractHook.KuthuluHook(newMsgCH) == true, string(abi.encodePacked('Contract Hook failed for user: ', KUtils.addressToString(taggedAccounts[t]))));
                }
            }
        }
    }

    /**
    * @dev Erase a message that a user posted
    * @dev Can only erase your own messages
    * @param msgID : The message ID you want to erase
    */
    function eraseMsg(uint256 msgID) public whenNotPaused {

        // Erase the message
        MessageData.removeMsg(msgID, msg.sender);

        emit logEraseMsg(msgID, msg.sender);

    }

    /**
    * @dev Toggle liking a message. Like / Unlike
    * @param msgID : The message ID you want to toggle the like for
    */
    function toggleLike(uint256 msgID) public whenNotPaused {

        // Make sure it's a valid post
        require(msgID <= counters.messages, "Bad Post ID");

        // Check if this user already liked the post
        if (Likes.checkUserLikeMsg(msg.sender, msgID)) {
            // Unlike a post if so
            Likes.removeLike(msgID, msg.sender);
        } else {
            // Transfer the Payment Token to the contract
            require(paymentToken.transferFrom(msg.sender, MessageData.getPoster(msgID), cutToPoster), "No Payment Token");

            // Like a post
            Likes.addLike(msgID, msg.sender);

            // Increment the amount of likes we have posted
            counters.likes++;
        }
    }

    /**
    * @dev Follow a user or group
    * @param addressToFollow : The user or group address to follow
    */
    function followUser(address addressToFollow) public whenNotPaused nonReentrant {
        // Follow the user
        userProfiles.followUser(msg.sender,addressToFollow);

        // Increment the amount of likes we have posted
        counters.follows++;
    }

    /**
    * @dev Unfollow a user or group
    * @param addressToUnFollow : The user or group address to unfollow
    */
    function unfollowUser(address addressToUnFollow) public whenNotPaused nonReentrant {
        // Follow the user
        userProfiles.unfollowUser(msg.sender, addressToUnFollow);
    }

    /**
    * @dev Get the message IDs posted by a specific user or group
    * @param usrAddress : The user or group address to get message IDs for
    * @param startFrom : The place to start from for paginating
    * @param getUserComments : (optional) true = get only the comments of a user
    * @param getUserReposts : (optional) true = get only the reposts of a user
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, bool getUserComments, bool getUserReposts) public view whenNotPaused returns (uint256[] memory) {

        // Initialize the array as 256 to sent to Posts
        uint256[] memory whatToGet = new uint256[](3);

        // If we're getting posts from a user for a specific post, swap the flag
        if (getUserComments){
            whatToGet[0] = 1;
        } else if (getUserReposts){
            whatToGet[2] = 1;
        }

        return Posts.getMsgIDsByAddress(usrAddress, startFrom, whatToGet);
    }


    /**
    * @dev Returns a list of comment IDs or repost IDs of a given message ID
    * @param msgID : The message ID to get comments or reposts for
    * @param startFrom : The place to start from for paginating
    * @param isRepost : (optional) true = get only the reposts of the message
    * @return uint256[] : an array of message IDs
    */
    function getSubIDsByPost(uint256 msgID, uint256 startFrom, bool isRepost) public view whenNotPaused returns (uint256[] memory) {
        // Initialize the array as 256 to sent to Posts
        uint256[] memory whatToGet = new uint256[](3);

        // Set the vars
        if (isRepost){
            // Get Reposts
            whatToGet[2] = 2;
        } else {
            // Get Comments
            whatToGet[0] = 2;
        }
        whatToGet[1] = msgID;

        return Posts.getMsgIDsByAddress(address(0), startFrom, whatToGet);
    }

    /**
    * @dev Returns a list of message IDs that have a hashtag
    * @param hashtag : The hashtag to get messages for
    * @param startFrom : The place to start from for paginating
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByHashtag(string memory hashtag, uint256 startFrom) public view whenNotPaused returns (uint256[] memory) {
        return Hashtags.getMsgIDsFromHashtag(hashtag, startFrom);
    }

    /**
    * @dev Returns a list of message IDs that have a certain user or group tagged in them
    * @param taggedAddress : The user or group to get messages for that they are tagged in
    * @param startFrom : The place to start from for paginating
    * @return uint256[] : an array of message IDs
    */
    function getMsgIDsByTag(address taggedAddress, uint256 startFrom) public view whenNotPaused returns (uint256[] memory) {
        return Tagged.getTaggedMsgIDs(taggedAddress, startFrom);
    }

    /**
    * @dev Returns a multi-dimensional array of message data from a given list of message IDs
    * @dev See the MessageData contract for data structure
    * @dev The amount of IDs must be less than maxMsgReturnCount
    * @param msgIDs : The user or group to get messages for that they are tagged in
    * @param onlyFollowers : Return only messages of accounts the provided address follows
    * @param userToCheck : The address of the user account to get a filtered response of only those following
    * @return string[][] : multi-dimensional array of message data
    */
    function getMsgsByIDs(uint256[] calldata msgIDs, bool onlyFollowers, address userToCheck) public view whenNotPaused returns (string[][] memory) {
        require(msgIDs.length <= maxMsgReturnCount , "Too many requested");

        return MessageData.getMsgsByIDs(msgIDs, onlyFollowers, userToCheck);
    }

    /**
    * @dev Returns an array of all the stats for the app
    * @dev messages, comments, groupPosts, reposts, hashtags, tags, likes, tips, follows
    * @return uint256[] : an array of stats
    */
    function getStats() public view whenNotPaused returns (uint256[] memory) {
        // Initialize the array
        uint256[] memory stats = new uint256[](9);

        stats[0] = counters.messages;
        stats[1] = counters.comments;
        stats[2] = counters.groupPosts;
        stats[3] = counters.reposts;
        stats[4] = counters.hashtags;
        stats[5] = counters.tags;
        stats[6] = counters.likes;
        stats[7] = counters.tips;
        stats[8] = counters.follows;

        return stats;
    }


    /*

    INTERNAL  FUNCTIONS

    */

    function updateStats(uint256[5] calldata attribs, uint256 msgVal, uint256 totalHashTags, uint256 totalTaggedAccounts, address tipContract,  uint256 tipsInERC20) internal {
        // Increment the amount of comments we have posted
        if (attribs[1] > 0){
            counters.comments++;
        }

        // Increment the amount of reposts we have posted
        if (attribs[2] > 0){
            counters.reposts++;
        }

        // Increment the amount of group posts we have posted
        if (attribs[3] > 0){
            counters.groupPosts++;
        }

        // Increment the amount of group posts we have posted
        counters.hashtags += totalHashTags;

        // Increment the amount of tips we have posted
        counters.tips += msgVal;

        // Increment the amount of tips received in ERC20 tokens
        if (tipContract != address(0)){
            contractCounters[tipContract] += tipsInERC20;
        }

        // Increment the amount of group posts we have posted
        counters.tags += totalTaggedAccounts;
    }
}