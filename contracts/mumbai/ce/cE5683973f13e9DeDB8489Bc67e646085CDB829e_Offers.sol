// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarketplace {
    function checkAllowedNFT(address _nftAddress) external view;
    function checkNFTOwner(address _nftAddress, uint256 _tokenId, address _owner) external view;
    function checkPriceAndDuration(uint256 _price, uint256 _duration) external view;
    function checkApprovedMarketplace(address _nftAddress, uint256 _tokenId) external view;
    function checkCollectionWithModels(address _nftAddress) external view;

    function doTransferOfNFT(address _nftAddress, uint256 _tokenId, address _from, address _to) external;
    
    function getModelIdForNFT(address _nftAddress, uint256 _tokenId) external view returns (uint256);
    function isNFTFree(address _nftAddress, uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISubMarket {
    function isFree(address _nftAddress, uint256 _tokenId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISwapper {
    function baseToken() external view returns (address);

    function executePayment(uint256 _amount, address _from, address _to) external;
    function holdAuctionPayment(uint256 _amount, address _from) external;
    function releaseAuctionPaymentLoser(uint256 _amount, address _to) external;
    function releaseAuctionPaymentWinner(uint256 _amount, address _to) external;
    function swapAndPay(address _tokenIn, uint256 _amountOut, address _from, address _to) external;
    function checkInputPrice(address _tokenIn, uint256 _amountOut) external returns (uint256);
    function checkCanOffer(address _buyer, uint256 _amount) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "./ISwapper.sol";
import "./IMarketplace.sol";
import "./ISubMarket.sol";

error IncorrectIndex(uint256 index);
error NotOwner();
error LifetimeEnded();
error ArraysLengthNotMatching();
error ArrayEmpty();
error AlreadyListed(uint256 tokenId);
error UnknownCallError();

contract Offers is OwnableUpgradeable, PausableUpgradeable, ERC2771Recipient, MulticallUpgradeable, ISubMarket {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;
    
    struct Offer {
        uint256 price;
        address buyer;
        uint256 endTime;
    }

    struct NFTtrade {
        address buyer;

        address[] collections;
        uint256[] tokenIds;

        uint256 tokenAmount;

        uint256 endTime;
    }

    ISwapper public swapper;                                                                                // swapper used for payment
    IMarketplace public marketplace;                                                                        // marketplace used for checks and transfers

    mapping(address => mapping(uint256 => Offer[])) private offers;                                         // offers for each tokenId
    mapping(address => mapping(uint256 => Offer[])) private offersByModel;                                  // listings for each model

    mapping(address => mapping(uint256 => NFTtrade[])) private trades;                                      // trades offers for each tokenId
    mapping(address => mapping(uint256 => NFTtrade[])) private tradesByModel;                               // trades offers for each model
    mapping(address => BitMaps.BitMap) private nftInTradeOffer;                                             // nft in trade offer

     event NewOffer(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId,
        uint256 price,
        uint256 endTime
    );

    event NewOfferByModel(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed model,
        uint256 offerId,
        uint256 price,
        uint256 endTime
    );

    event OfferCanceled(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId
    );

    event OfferByModelCanceled(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed model,
        uint256 offerId
    );

    event OfferAccepted(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId,
        uint256 price
    );

    event NewNFTTradeOffer(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId,
        uint256 endTime
    );

    event NFTTradeOfferCanceled(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId
    );

    event NFTTradeOfferAccepted(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerId
    );

    event NewNFTTradeOfferByModel(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed model,
        uint256 offerId,
        uint256 endTime
    );

    event NFTTradeOfferByModelCanceled(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed model,
        uint256 offerId
    );

    event NFTTradeOfferByModelAccepted(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed model,
        uint256 offerId
    );

    /**
     * @notice Initialize the contract
     * @param _swapperAddress Address of the swapper used for payment
     * @param _marketplace Address of the marketplace used for checks and transfers
     * @param _multisig Address of the multisig owning the contract
     * @dev equivalent to constructor but for proxied contracts
     */
    function initialize(address _swapperAddress, address _marketplace, address _multisig) public initializer {
        __Ownable_init();
        __Pausable_init();

        marketplace = IMarketplace(_marketplace);
        swapper = ISwapper(_swapperAddress);

        transferOwnership(_multisig);
    }

    /**
     * @notice Method for placing a bid
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _price bid price
     * @param _duration duration of bid (in seconds)
     */
    function createOffer(address _nftAddress, uint256 _tokenId, uint256 _price, uint256 _duration) public 
        whenNotPaused  
    {
        marketplace.checkAllowedNFT(_nftAddress);
        marketplace.checkPriceAndDuration(_price, _duration);

        swapper.checkCanOffer(_msgSender(), _price);
        
        Offer memory newOffer = Offer(_price, _msgSender(), block.timestamp + _duration);
        offers[_nftAddress][_tokenId].push(newOffer);

        uint256 offerId = offers[_nftAddress][_tokenId].length - 1;

        emit NewOffer(_msgSender(), _nftAddress, _tokenId, offerId, _price, block.timestamp + _duration);
    }

    /**
     * @notice Method for cancelling an offer
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _offerIndex Offer index in the offers lists
     */
    function cancelOffer(address _nftAddress, uint256 _tokenId, uint256 _offerIndex) public 
        whenNotPaused 
    {
        if(_offerIndex >= offers[_nftAddress][_tokenId].length){
            revert IncorrectIndex(_offerIndex);
        }

        if(offers[_nftAddress][_tokenId][_offerIndex].buyer != _msgSender()){
            revert NotOwner();
        }

        offers[_nftAddress][_tokenId][_offerIndex] = offers[_nftAddress][_tokenId][offers[_nftAddress][_tokenId].length - 1];
        offers[_nftAddress][_tokenId].pop();

        emit OfferCanceled(_msgSender(), _nftAddress, _tokenId, _offerIndex);
    }

    /**
     * @notice Method for placing a bid for all NFTs with a given model
     * @param _nftAddress Address of the NFT
     * @param _model model id
     * @param _price bid price
     * @param _duration duration of bid (in seconds)
     */
    function createOfferForModel(address _nftAddress, uint256 _model, uint256 _price, uint256 _duration) public 
        whenNotPaused  
    {
        marketplace.checkAllowedNFT(_nftAddress);
        marketplace.checkPriceAndDuration(_price, _duration);
        marketplace.checkCollectionWithModels(_nftAddress);

        swapper.checkCanOffer(_msgSender(), _price);
        
        Offer memory newOffer = Offer(_price, _msgSender(), block.timestamp + _duration);
        offersByModel[_nftAddress][_model].push(newOffer);

        uint256 offerId = offersByModel[_nftAddress][_model].length - 1;

        emit NewOfferByModel(_msgSender(), _nftAddress, _model, offerId, _price, block.timestamp + _duration);
    }

    /**
     * @notice Method for cancelling an offer for all NFTs with a given model
     * @param _nftAddress Address of the NFT
     * @param _model model id
     * @param _offerIndex Offer index in the offers lists
     */
    function cancelOfferForModel(address _nftAddress, uint256 _model, uint256 _offerIndex) public 
        whenNotPaused
    {
        if(_offerIndex >= offersByModel[_nftAddress][_model].length){
            revert IncorrectIndex(_offerIndex);
        }

        if(offersByModel[_nftAddress][_model][_offerIndex].buyer != _msgSender()){
            revert NotOwner();
        }

        offersByModel[_nftAddress][_model][_offerIndex] = offersByModel[_nftAddress][_model][offersByModel[_nftAddress][_model].length - 1];
        offersByModel[_nftAddress][_model].pop();

        emit OfferByModelCanceled(_msgSender(), _nftAddress, _model, _offerIndex);
    }

    /**
     * @notice Method for accepting a bid
     * @param _nftAddress Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _offerIndex index of the offer
     * @dev this ends the auction and deletes it
     */
    function acceptOffer(address _nftAddress, uint256 _tokenId, uint256 _offerIndex) external 
        whenNotPaused 
    {
        marketplace.checkNFTOwner(_nftAddress, _tokenId, _msgSender());
        marketplace.checkApprovedMarketplace(_nftAddress, _tokenId);

        if(_offerIndex >= offers[_nftAddress][_tokenId].length){
            revert IncorrectIndex(_offerIndex);
        }

        if(offers[_nftAddress][_tokenId][_offerIndex].endTime < block.timestamp){
            revert LifetimeEnded();
        }

        address buyer = offers[_nftAddress][_tokenId][_offerIndex].buyer;
        uint256 price = offers[_nftAddress][_tokenId][_offerIndex].price;

        swapper.checkCanOffer(buyer, price);

        offers[_nftAddress][_tokenId][_offerIndex] = offers[_nftAddress][_tokenId][offers[_nftAddress][_tokenId].length - 1];
        offers[_nftAddress][_tokenId].pop();
        
        marketplace.doTransferOfNFT(_nftAddress, _tokenId, _msgSender(), buyer);

        swapper.executePayment(price, buyer, _msgSender());

        emit OfferAccepted(buyer, _nftAddress, _tokenId, _offerIndex, price);
    }

    /**
     * @notice Method for accepting a bid for all NFTs with a given model
     * @param _nftAddress Address of the NFT
     * @param _tokenId token id
     * @param _offerIndex index of the offer
     */
    function acceptOfferForModel(address _nftAddress, uint256 _tokenId, uint256 _offerIndex) external 
        whenNotPaused
    {
        marketplace.checkNFTOwner(_nftAddress, _tokenId, _msgSender());
        marketplace.checkApprovedMarketplace(_nftAddress, _tokenId);

        uint256 model = marketplace.getModelIdForNFT(_nftAddress, _tokenId);

        if(_offerIndex >= offersByModel[_nftAddress][model].length){
            revert IncorrectIndex(_offerIndex);
        }

        if(offersByModel[_nftAddress][model][_offerIndex].endTime < block.timestamp){
            revert LifetimeEnded();
        }

        address buyer = offersByModel[_nftAddress][model][_offerIndex].buyer;
        uint256 price = offersByModel[_nftAddress][model][_offerIndex].price;

        swapper.checkCanOffer(buyer, price);

        offersByModel[_nftAddress][model][_offerIndex] = offersByModel[_nftAddress][model][offersByModel[_nftAddress][model].length - 1];
        offersByModel[_nftAddress][model].pop();

        marketplace.doTransferOfNFT(_nftAddress, _tokenId, _msgSender(), buyer);

        swapper.executePayment(price, buyer, _msgSender());

        emit OfferAccepted(buyer, _nftAddress, _tokenId, _offerIndex, price);
    }

    /**
     * @notice creates a new trade offer
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _proposedCollections proposed collections to trade from
     * @param _proposedTokensIds proposed token IDs to trade from
     * @param _tokenAmount proposed base token amount in addition to NFTs
     * @param _duration duration of the offer (in seconds)
     */
    function createTradeOffer(address _collection, uint256 _tokenId, address[] calldata _proposedCollections, uint256[] calldata _proposedTokensIds, 
        uint256 _tokenAmount, uint256 _duration) external whenNotPaused
    {
        marketplace.checkAllowedNFT(_collection);

        if(_proposedCollections.length != _proposedTokensIds.length){
            revert ArraysLengthNotMatching(); 
        }

        if(_proposedCollections.length == 0){
            revert ArrayEmpty();
        }
        else {
            uint256 len = _proposedCollections.length;
            for(uint256 i = 0; i < len;){
                if(!marketplace.isNFTFree(_proposedCollections[i], _proposedTokensIds[i])){
                    revert AlreadyListed(_proposedTokensIds[i]);
                }

                if(IERC721(_proposedCollections[i]).ownerOf(_proposedTokensIds[i]) != _msgSender()){
                    revert NotOwner();
                }

                nftInTradeOffer[_proposedCollections[i]].set(_proposedTokensIds[i]);

                unchecked {
                    ++i;
                }
            }
        }

        uint256 endTime = block.timestamp + _duration;

        trades[_collection][_tokenId].push(NFTtrade(_msgSender(), _proposedCollections, _proposedTokensIds, _tokenAmount, endTime));
        uint256 tradeIndex = trades[_collection][_tokenId].length - 1;
        
        emit NewNFTTradeOffer(_msgSender(), _collection, _tokenId, tradeIndex, endTime);
    }

    /**
     * @notice Method for cancelling a trade offer
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _tradeOfferId Offer index in the nft trades offers lists
     */
    function cancelTradeOffer(address _collection, uint256 _tokenId, uint256 _tradeOfferId) external whenNotPaused {
        if(_tradeOfferId >= trades[_collection][_tokenId].length){
            revert IncorrectIndex(_tradeOfferId);
        }

        NFTtrade memory trade = trades[_collection][_tokenId][_tradeOfferId];
        if(trade.buyer != _msgSender()){
            revert NotOwner();
        }

        uint256 collectionsLen = trade.collections.length;
        for(uint256 i = 0; i < collectionsLen;){
            nftInTradeOffer[trade.collections[i]].unset(trade.tokenIds[i]);

            unchecked {
                ++i;
            }
        }

        trades[_collection][_tokenId][_tradeOfferId] = trades[_collection][_tokenId][trades[_collection][_tokenId].length - 1];
        trades[_collection][_tokenId].pop();

        emit NFTTradeOfferCanceled(_msgSender(), _collection, _tokenId, _tradeOfferId);
    }

    /**
     * @notice Method for accepting a trade offer
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT
     * @param _tradeOfferId Offer index in the nft trades offers lists
     */
    function acceptTradeOffer(address _collection, uint256 _tokenId, uint256 _tradeOfferId) external whenNotPaused 
    {
        marketplace.checkNFTOwner(_collection, _tokenId, _msgSender());

        if(_tradeOfferId >= trades[_collection][_tokenId].length){
            revert IncorrectIndex(_tradeOfferId);
        }

        NFTtrade memory trade = trades[_collection][_tokenId][_tradeOfferId];

        if(trade.endTime <= block.timestamp){
            revert LifetimeEnded();                 //also reverts if there is no offer
        }

        trades[_collection][_tokenId][_tradeOfferId] = trades[_collection][_tokenId][trades[_collection][_tokenId].length - 1];
        trades[_collection][_tokenId].pop();

        if(trade.tokenAmount > 0){
            swapper.executePayment(trade.tokenAmount, trade.buyer, _msgSender());
        }

        uint256 collectionsLen = trade.collections.length;
        for(uint256 i = 0; i < collectionsLen;){
            nftInTradeOffer[trade.collections[i]].unset(trade.tokenIds[i]);
            marketplace.doTransferOfNFT(trade.collections[i], trade.tokenIds[i], trade.buyer, _msgSender());

            unchecked {
                ++i;
            }
        }

        marketplace.doTransferOfNFT(_collection, _tokenId, _msgSender(), trade.buyer);

        emit NFTTradeOfferAccepted(_msgSender(), _collection, _tokenId, _tradeOfferId);
    }

    /**
     * @notice creates a new trade offer for a model
     * @param _collection Address of the NFT
     * @param _model Model targeted
     * @param _proposedCollections proposed collections to trade from
     * @param _proposedTokensIds proposed token IDs to trade from
     * @param _tokenAmount proposed base token amount in addition to NFTs
     * @param _duration duration of the offer (in seconds)
     */
    function createTradeOfferForModel(address _collection, uint256 _model, address[] calldata _proposedCollections, uint256[] calldata _proposedTokensIds, 
        uint256 _tokenAmount, uint256 _duration) external whenNotPaused
    {
        marketplace.checkAllowedNFT(_collection);
        marketplace.checkCollectionWithModels(_collection);

        if(_proposedCollections.length != _proposedTokensIds.length){
            revert ArraysLengthNotMatching(); 
        }

        if(_proposedCollections.length == 0){
            revert ArrayEmpty();
        }
        else {
            uint256 len = _proposedCollections.length;
            for(uint256 i = 0; i < len;){
                if(!marketplace.isNFTFree(_proposedCollections[i], _proposedTokensIds[i])){
                    revert AlreadyListed(_proposedTokensIds[i]);
                }

                if(IERC721(_proposedCollections[i]).ownerOf(_proposedTokensIds[i]) != _msgSender()){
                    revert NotOwner();
                }

                nftInTradeOffer[_proposedCollections[i]].set(_proposedTokensIds[i]);

                unchecked {
                    ++i;
                }
            }
        }

        uint256 endTime = block.timestamp + _duration;

        tradesByModel[_collection][_model].push(NFTtrade(_msgSender(), _proposedCollections, _proposedTokensIds, _tokenAmount, endTime));
        uint256 tradeIndex = tradesByModel[_collection][_model].length - 1;
        
        emit NewNFTTradeOfferByModel(_msgSender(), _collection, _model, tradeIndex, endTime);
    }

    /**
     * @notice Method for cancelling a trade offer for a model
     * @param _collection Address of the NFT
     * @param _model targeted model
     * @param _tradeOfferId Offer index in the nft trades offers lists
     */
    function cancelTradeOfferForModel(address _collection, uint256 _model, uint256 _tradeOfferId) external whenNotPaused {
        if(_tradeOfferId >= tradesByModel[_collection][_model].length){
            revert IncorrectIndex(_tradeOfferId);
        }

        NFTtrade memory trade = tradesByModel[_collection][_model][_tradeOfferId];
        if(trade.buyer != _msgSender()){
            revert NotOwner();
        }

        uint256 collectionsLen = trade.collections.length;
        for(uint256 i = 0; i < collectionsLen;){
            nftInTradeOffer[trade.collections[i]].unset(trade.tokenIds[i]);

            unchecked {
                ++i;
            }
        }

        tradesByModel[_collection][_model][_tradeOfferId] = tradesByModel[_collection][_model][tradesByModel[_collection][_model].length - 1];
        tradesByModel[_collection][_model].pop();

        emit NFTTradeOfferByModelCanceled(_msgSender(), _collection, _model, _tradeOfferId);
    }

    /**
     * @notice Method for accepting a trade offer on a model
     * @param _collection Address of the NFT
     * @param _tokenId Token ID of NFT that should be of the given model
     * @param _tradeOfferId Offer index in the nft trades offers lists
     */
    function acceptTradeOfferForModel(address _collection, uint256 _tokenId, uint256 _tradeOfferId) external whenNotPaused 
    {
        marketplace.checkNFTOwner(_collection, _tokenId, _msgSender());
        marketplace.checkAllowedNFT(_collection);

        uint256 model = marketplace.getModelIdForNFT(_collection, _tokenId);

        if(_tradeOfferId >= tradesByModel[_collection][model].length){
            revert IncorrectIndex(_tradeOfferId);
        }

        NFTtrade memory trade = tradesByModel[_collection][model][_tradeOfferId];

        if(trade.endTime <= block.timestamp){
            revert LifetimeEnded();                 //also reverts if there is no offer
        }

        tradesByModel[_collection][model][_tradeOfferId] = tradesByModel[_collection][model][tradesByModel[_collection][model].length - 1];
        tradesByModel[_collection][model].pop();

        if(trade.tokenAmount > 0){
            swapper.executePayment(trade.tokenAmount, trade.buyer, _msgSender());
        }

        uint256 collectionsLen = trade.collections.length;
        for(uint256 i = 0; i < collectionsLen;){
            nftInTradeOffer[trade.collections[i]].unset(trade.tokenIds[i]);
            marketplace.doTransferOfNFT(trade.collections[i], trade.tokenIds[i], trade.buyer, _msgSender());

            unchecked {
                ++i;
            }
        }

        marketplace.doTransferOfNFT(_collection, _tokenId, _msgSender(), trade.buyer);

        emit NFTTradeOfferByModelAccepted(_msgSender(), _collection, _tokenId, _tradeOfferId);
    }

    /**
     * @notice Method for updating the marketplace
     * @param _marketplace New contract address
     */
    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = IMarketplace(_marketplace);
    }

    /**
     * @notice Allows pause of the contract
     * @dev Can only be called by the owner
     */
    function pause(bool p) external onlyOwner {
        if(p)
            _pause();
        else
            _unpause();
    }

    /**
     * @notice Allows receiving ETH
     * @dev Called automatically
     */
    receive() external payable {
        (bool ok, ) = address(swapper).call{value: msg.value}("");
        if(!ok){
            revert UnknownCallError();
        }
    }

    /**
     * @notice Allows owners to recover NFT sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).safeTransferFrom(address(this), address(_msgSender()), _tokenId);
    }

    /**
     * @notice Allows owners to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20(_token).safeTransfer(address(_msgSender()), balance);
    }

    /**
     * @notice Is the NFT free (not in a trade offer)
     * @param _nftAddress: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function isFree(address _nftAddress, uint256 _tokenId) external view returns(bool) {
        return !isInTradeOffer(_nftAddress, _tokenId);
    }

    /**
     * @notice Is the NFT in a trade offer
     * @param _nftAddress: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function isInTradeOffer(address _nftAddress, uint256 _tokenId) public view returns (bool) {
        return nftInTradeOffer[_nftAddress].get(_tokenId);
    }

    /**
     * @notice Get all offers (classic or trade) for an NFT
     * @param _nftAddress: NFT address
     * @param _tokenId: id of the NFT
     * @dev gather getOffers and getTradesOffers
     */
    function getAllOffers(address _nftAddress, uint256 _tokenId) external view returns 
        (uint256[] memory offersIds, Offer[] memory _offers,
        uint256[] memory tradesOffersIds, NFTtrade[] memory tradesOffers) {
            (offersIds, _offers) = getOffers(_nftAddress, _tokenId);
            (tradesOffersIds, tradesOffers) = getTradesOffers(_nftAddress, _tokenId);
    }

    /**
     * @notice Get all offers by model (classic or trade) for an NFT
     * @param _nftAddress: NFT address
     * @param _tokenId: id of the NFT
     * @dev gather getOffersByModel and getTradesOffersByModel
     */
    function getAllOffersByModel(address _nftAddress, uint256 _tokenId) external view returns 
        (uint256[] memory offersByModelIds, Offer[] memory _offersByModel, 
        uint256[] memory tradesOffersIds, NFTtrade[] memory tradesOffers) {
            marketplace.checkCollectionWithModels(_nftAddress);

            uint256 modelId = marketplace.getModelIdForNFT(_nftAddress, _tokenId);

            (offersByModelIds, _offersByModel) = getOffersByModel(_nftAddress, modelId);
            (tradesOffersIds, tradesOffers) = getTradesOffersByModel(_nftAddress, modelId);
    }

    /**
     * @notice Compute active offers for an NFT
     * @param _nftAddress: NFT address
     * @param _tokenId: id of the NFT
     */
    function getOffers(address _nftAddress, uint256 _tokenId) public view returns 
        (uint256[] memory, Offer[] memory) 
    {
        uint256 offersNb = 0;
        uint256 offersLen = offers[_nftAddress][_tokenId].length;
        for(uint256 i = 0; i < offersLen;){
            if(offers[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                    ++offersNb;
            }

            unchecked {
                ++i;
            }
        }

        Offer[] memory offersActive = new Offer[](offersNb);
        uint256[] memory offersActiveIds = new uint256[](offersNb);
        uint256 index = 0;
        for(uint256 i = 0; i < offersLen;){
            if(offers[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                offersActive[index] = offers[_nftAddress][_tokenId][i];
                offersActiveIds[index] = i;
                ++index;
            }

            unchecked {
                ++i;
            }
        }

        return (offersActiveIds, offersActive);
    }

    /**
     * @notice Compute active offers by model for an NFT
     * @param _nftAddress: NFT address
     * @param _tokenId: id of the NFT
     */
    function getOffersByModel(address _nftAddress, uint256 _tokenId) public view returns 
        (uint256[] memory, Offer[] memory) 
    {
        uint256 offersNb = 0;
        uint256 offersLen = offersByModel[_nftAddress][_tokenId].length;
        for(uint256 i = 0; i < offersLen;){
            if(offersByModel[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                    ++offersNb;
            }

            unchecked {
                ++i;
            }
        }

        Offer[] memory offersByModelActive = new Offer[](offersNb);
        uint256[] memory offersByModelActiveIds = new uint256[](offersNb);
        uint256 index = 0;
        for(uint256 i = 0; i < offersLen;){
            if(offersByModel[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                offersByModelActive[index] = offersByModel[_nftAddress][_tokenId][i];
                offersByModelActiveIds[index] = i;
                ++index;
            }

            unchecked {
                ++i;
            }
        }

        return (offersByModelActiveIds, offersByModelActive);
    }

    /**
     * @notice Compute active trade offers for an NFT
     * @param _nftAddress: NFT address
     * @param _tokenId: id of the NFT
     */
    function getTradesOffers(address _nftAddress, uint256 _tokenId) public view returns 
        (uint256[] memory, NFTtrade[] memory) 
    {
        uint256 offersNb = 0;
        uint256 offersLen = trades[_nftAddress][_tokenId].length;
        for(uint256 i = 0; i < offersLen;){
            if(trades[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                    ++offersNb;
            }

            unchecked {
                ++i;
            }
        }

        NFTtrade[] memory tradeOffersActive = new NFTtrade[](offersNb);
        uint256[] memory tradeOffersActiveIds = new uint256[](offersNb);
        uint256 index = 0;
        for(uint256 i = 0; i < offersLen;){
            if(trades[_nftAddress][_tokenId][i].endTime >= block.timestamp){
                tradeOffersActive[index] = trades[_nftAddress][_tokenId][i];
                tradeOffersActiveIds[index] = i;
                ++index;
            }

            unchecked {
                ++i;
            }
        }

        return (tradeOffersActiveIds, tradeOffersActive);
    }

    /**
     * @notice Compute active trade offers for a model of NFT
     * @param _nftAddress: NFT address
     * @param _model: targeted model
     */
    function getTradesOffersByModel(address _nftAddress, uint256 _model) public view returns 
        (uint256[] memory, NFTtrade[] memory)
    {
        uint256 offersNb = 0;
        uint256 offersLen = tradesByModel[_nftAddress][_model].length;
        for(uint256 i = 0; i < offersLen;){
            if(tradesByModel[_nftAddress][_model][i].endTime >= block.timestamp){
                    ++offersNb;
            }

            unchecked {
                ++i;
            }
        }

        NFTtrade[] memory tradeOffersActive = new NFTtrade[](offersNb);
        uint256[] memory tradeOffersActiveIds = new uint256[](offersNb);
        uint256 index = 0;
        for(uint256 i = 0; i < offersLen;){
            if(tradesByModel[_nftAddress][_model][i].endTime >= block.timestamp){
                tradeOffersActive[index] = tradesByModel[_nftAddress][_model][i];
                tradeOffersActiveIds[index] = i;
                ++index;
            }

            unchecked {
                ++i;
            }
        }

        return (tradeOffersActiveIds, tradeOffersActive);
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (address) {
        return ERC2771Recipient._msgSender();
    }
}