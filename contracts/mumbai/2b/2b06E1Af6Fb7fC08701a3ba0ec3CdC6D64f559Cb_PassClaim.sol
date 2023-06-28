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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: UNLICSENSED
pragma solidity ^0.8.17;

interface IFeeDistributor {
    struct Fee {
        address payable payee;
        bytes32 token;
        uint256 amount;
    }

    function distributeFees(Fee[] calldata fees) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IHotWallet {
    function getHotWallet(address coldWallet) external view returns (address);

    function balanceOf(address contractAddress, address owner) external view returns (uint256);

    function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFeeDistributor } from "./IFeeDistributor.sol";

interface IIncinerator {
    struct NFTItem {
        address collection;
        uint256 tokenId;
    }

    function burnItems(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        bytes calldata signature
    ) external payable;

    function burnItemsHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { INFTRegistry } from "./INFTRegistry.sol";

interface INFT is IERC721 {
    function setRegistry(INFTRegistry registry) external;

    function setRegistryDisabled(bool registryDisabled) external;

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;

    function mint(uint256 tokenId, address receiver, string calldata tokenURI) external;

    function burn(uint256 tokenId) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFeeDistributor } from "./IFeeDistributor.sol";
import { IRoyaltySplitter } from "./IRoyaltySplitter.sol";

interface INFTFactory {
    struct CreateCollectionParams {
        uint256 transactionId;
        uint256 collectionId;
        string name;
        string symbol;
        uint256 itemLimit;
        IRoyaltySplitter.Royalty[] royalties;
        IFeeDistributor.Fee[] fees;
    }

    struct MintItemParams {
        uint256 transactionId;
        uint256 collectionId;
        uint256 deduplicationId;
        uint256 maxItemSupply;
        uint256 tokenId;
        address tokenReceiver;
        string tokenURI;
        IRoyaltySplitter.Royalty[] royalties;
        IFeeDistributor.Fee[] fees;
    }

    function createCollection(CreateCollectionParams calldata params, bytes calldata signature) external payable;

    function mintItem(MintItemParams calldata params, bytes calldata signature) external payable;

    function mintItemUnsigned(MintItemParams calldata params) external payable;

    function computeCollectionAddress(
        uint256 collectionId,
        string calldata name,
        string calldata symbol
    ) external view returns (address);

    function createCollectionHash(
        CreateCollectionParams calldata params,
        address sender
    ) external pure returns (bytes32);

    function mintItemHash(MintItemParams calldata params, address sender) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Required interface of an Registry compliant contract.
 */
interface INFTRegistry {
    /**
     * @dev Emitted when address trying to transfer is not allowed on the registry
     */
    error TransferNotAllowed(address from, address to, uint256 tokenId);

    /**
     * @dev Checks whether `operator` is valid on the registry; let the registry
     * decide across both allow and blocklists.
     */
    function isAllowedOperator(address operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { INFTFactory } from "./INFTFactory.sol";

interface IPassClaim {
    struct NFTItem {
        address collection;
        uint256 tokenId;
        uint256 deduplicationId;
        uint256 maxUsage;
    }

    function mintItem(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        bytes calldata signature
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IFeeDistributor } from "./IFeeDistributor.sol";

interface IPayment {
    function pay(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        bytes calldata signature
    ) external payable;

    function payHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRoyaltySplitter {
    struct Royalty {
        address payable payee;
        uint96 share;
    }

    function registerCollectionRoyalty(
        address collection,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) external returns (address, uint96);

    function registerTokenRoyalty(
        address collection,
        uint256 tokenId,
        Royalty[] calldata royalties
    ) external returns (address royaltyForwarder, uint96 totalShares);

    function releaseRoyalty() external payable;

    function releaseRoyalty(IERC20Upgradeable token, uint256 amount) external;

    function computeCollectionRoyaltyForwarderAddress(address collection) external view returns (address);

    function computeTokenRoyaltyForwarderAddress(address collection, uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVerifier {
    error SignerNotVerified(bytes32 hash, bytes signature);

    function verifySigner(bytes32 hash, bytes memory signature) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFeeDistributor } from "../interfaces/IFeeDistributor.sol";
import { IRoyaltySplitter } from "../interfaces/IRoyaltySplitter.sol";
import { IPassClaim } from "../interfaces/IPassClaim.sol";
import { IIncinerator } from "../interfaces/IIncinerator.sol";
import { IPayment } from "../interfaces/IPayment.sol";

library ParamEncoder {
    function encodeFees(IFeeDistributor.Fee[] calldata fees) internal pure returns (bytes memory encodedFees) {
        uint256 feeCount = fees.length;
        for (uint256 i = 0; i < feeCount; ) {
            IFeeDistributor.Fee calldata fee = fees[i];
            encodedFees = bytes.concat(encodedFees, abi.encodePacked(fee.payee, fee.token, fee.amount));
            unchecked {
                i++;
            }
        }
    }

    function encodeRoyalty(
        IRoyaltySplitter.Royalty[] calldata royalties
    ) internal pure returns (bytes memory encodedRoyalties) {
        uint256 royaltyCount = royalties.length;
        for (uint256 i = 0; i < royaltyCount; ) {
            IRoyaltySplitter.Royalty calldata royalty = royalties[i];
            encodedRoyalties = bytes.concat(encodedRoyalties, abi.encodePacked(royalty.payee, royalty.share));
            unchecked {
                i++;
            }
        }
    }

    function encodeNFTItems(
        IPassClaim.NFTItem[] calldata nftItems
    ) internal pure returns (bytes memory encodedNFTItems) {
        uint256 nftItemCount = nftItems.length;
        for (uint256 i = 0; i < nftItemCount; ) {
            IPassClaim.NFTItem calldata nftItem = nftItems[i];
            bytes.concat(
                encodedNFTItems,
                abi.encodePacked(nftItem.collection, nftItem.tokenId, nftItem.deduplicationId, nftItem.maxUsage)
            );
            unchecked {
                i++;
            }
        }
    }

    function encodeNFTItems(
        IIncinerator.NFTItem[] calldata nftItems
    ) internal pure returns (bytes memory encodedNFTItems) {
        uint256 nftItemCount = nftItems.length;
        for (uint256 i = 0; i < nftItemCount; ) {
            IIncinerator.NFTItem calldata nftItem = nftItems[i];
            bytes.concat(encodedNFTItems, abi.encodePacked(nftItem.collection, nftItem.tokenId));
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { IPassClaim } from "./interfaces/IPassClaim.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { INFTFactory } from "./interfaces/INFTFactory.sol";
import { INFT } from "./interfaces/INFT.sol";
import { IHotWallet } from "./interfaces/IHotWallet.sol";
import { ParamEncoder } from "./libraries/ParamEncoder.sol";

error NFTItemRangeMissed(uint8[2] nftItemRange, uint256 currentNFTItemCount);
error MaxItemUsageReached(address collection, uint256 deduplicationId, uint256 currentUsage);
error InvalidTokenOwner(address collection, uint256 tokenId, address sender);

contract PassClaim is IPassClaim, Initializable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant VERSION = "1.0.1";

    IVerifier public verifier;
    INFTFactory public nftFactory;
    IHotWallet public hotWallet;
    uint8[2] public nftItemRange;
    // collectionId => deduplicationId => itemUsage
    // slither-disable-next-line uninitialized-state
    mapping(address => mapping(uint256 => CountersUpgradeable.Counter)) public itemUsages;

    event VerifierSet(IVerifier indexed verifier);
    event NFTFactorySet(INFTFactory indexed nftFactory);
    event HotWalletSet(IHotWallet indexed hotWallet);
    event NFTItemRangeSet(uint8[2] nftItemRange);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVerifier verifier_,
        INFTFactory nftFactory_,
        IHotWallet hotWallet_,
        uint8[2] calldata nftItemRange_
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        verifier = IVerifier(verifier_);
        nftFactory = INFTFactory(nftFactory_);
        nftItemRange = nftItemRange_;

        if (address(hotWallet_) != address(0)) {
            hotWallet = hotWallet_;
            emit HotWalletSet(hotWallet_);
        }
    }

    function setVerifier(IVerifier verifier_) external onlyOwner {
        verifier = verifier_;
        emit VerifierSet(verifier_);
    }

    function setNFTFactory(INFTFactory nftFactory_) external onlyOwner {
        nftFactory = nftFactory_;
        emit NFTFactorySet(nftFactory_);
    }

    function setHotWallet(IHotWallet hotWallet_) external onlyOwner {
        hotWallet = hotWallet_;
        emit HotWalletSet(hotWallet_);
    }

    function setNFTItemRange(uint8[2] calldata nftItemRange_) external onlyOwner {
        nftItemRange = nftItemRange_;
        emit NFTItemRangeSet(nftItemRange_);
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    function mintItem(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        bytes calldata signature
    ) external payable whenNotPaused {
        bytes32 hash = _mintItemHash(nftItems, params, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _checkNFTItems(nftItems);
        nftFactory.mintItemUnsigned{ value: msg.value }(params);
    }

    function mintItemHash(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        address sender
    ) external pure returns (bytes32) {
        return _mintItemHash(nftItems, params, sender);
    }

    function _checkNFTItems(NFTItem[] calldata nftItems) private {
        uint256 nftItemCount = nftItems.length;
        if (nftItemCount < nftItemRange[0] || nftItemCount > nftItemRange[1]) {
            revert NFTItemRangeMissed(nftItemRange, nftItemCount);
        }

        bool shouldCheckHotWallet = address(hotWallet) != address(0);
        for (uint256 i = 0; i < nftItemCount; ) {
            NFTItem calldata nftItem = nftItems[i];
            _setItemUsage(nftItem.collection, nftItem.deduplicationId, nftItem.maxUsage);

            shouldCheckHotWallet
                ? _checkHotWalletOwner(nftItem.collection, nftItem.tokenId)
                : _checkColdWalletOwner(nftItem.collection, nftItem.tokenId);

            unchecked {
                i++;
            }
        }
    }

    function _setItemUsage(address collection, uint256 deduplicationId, uint256 maxUsage) private {
        CountersUpgradeable.Counter storage currentUsage = itemUsages[collection][deduplicationId];
        if (maxUsage != 0 && currentUsage.current() == maxUsage) {
            revert MaxItemUsageReached(collection, deduplicationId, currentUsage.current());
        }
        currentUsage.increment();
    }

    function _checkHotWalletOwner(address collection, uint256 tokenId) private view {
        address tokenOwner = hotWallet.ownerOf(collection, tokenId);
        if (tokenOwner != msg.sender && tokenOwner != hotWallet.getHotWallet(msg.sender)) {
            revert InvalidTokenOwner(collection, tokenId, msg.sender);
        }
    }

    function _checkColdWalletOwner(address collection, uint256 tokenId) private view {
        address tokenOwner = INFT(collection).ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert InvalidTokenOwner(collection, tokenId, msg.sender);
        }
    }

    function _mintItemHash(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    ParamEncoder.encodeNFTItems(nftItems),
                    params.transactionId,
                    params.collectionId,
                    params.tokenReceiver,
                    params.tokenId,
                    params.tokenURI,
                    params.deduplicationId,
                    params.maxItemSupply,
                    ParamEncoder.encodeRoyalty(params.royalties),
                    ParamEncoder.encodeFees(params.fees),
                    sender
                )
            );
    }
}