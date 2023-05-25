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
pragma solidity >=0.8.17;

interface AvoCoreStructs {
    /// @notice a pair of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature signature, e.g. ECDSA signature for default flow
        bytes signature;
        ///
        /// @param signer signer of the signature, required for smart contract signatures
        address signer;
    }

    /// @notice an executable action, including operation (call or delegateCall), target, data and value
    struct Action {
        ///
        /// @param target the target to execute the actions on
        address target;
        ///
        /// @param data the data to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on AvoSafe
        ///                       or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source e.g. referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for future flexibility
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Required:
        ///                       As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects against potential gas griefing attacks & ensures the relayer sends enough gas
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum fee allowed to be paid for tx execution
        uint256 maxFee;
        ///
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       is valid for, or 0 if request should be valid forever.
        ///                       Protects against executing a certain transaction at a later moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validUntil;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be executed in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against executing a certain transaction at  an earlier moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validAfter;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoForwarder } from "./interfaces/IAvoForwarder.sol";
import { IAvoWalletV1 } from "./interfaces/IAvoWalletV1.sol";
import { IAvoWalletV2 } from "./interfaces/IAvoWalletV2.sol";
import { IAvoWalletV3 } from "./interfaces/IAvoWalletV3.sol";
import { IAvoMultisigV3 } from "./interfaces/IAvoMultisigV3.sol";
import { IAvoSafe } from "./AvoSafe.sol";

abstract contract AvoForwarderConstants is IAvoForwarder {
    /// @notice  AvoFactory that this contract uses to find or create AvoSafe deployments
    /// @dev     Note that if this changes then the deployment addresses for AvoWallet change too
    ///          Relayers might want to pass in version as new param then to forward to the correct factory
    IAvoFactory public immutable avoFactory;

    /// @dev cached AvoSafe Bytecode to optimize gas usage.
    /// If this changes because of a AvoFactory (and AvoSafe change) upgrade,
    /// then this variable must be updated through an upgrade deploying a new AvoForwarder!
    bytes32 public immutable avoSafeBytecode;

    /// @dev cached AvoMultiSafe Bytecode to optimize gas usage.
    /// If this changes because of an AvoFactory (and AvoMultiSafe change) upgrade,
    /// then this variable must be updated through an upgrade deploying a new AvoForwarder!
    bytes32 public immutable avoMultiSafeBytecode;

    constructor(IAvoFactory avoFactory_) {
        avoFactory = avoFactory_;

        // get AvoSafe & AvoSafeMultsig bytecode from factory.
        // @dev Note if a new AvoFactory is deployed (upgraded), a new AvoForwarder must be deployed
        // to update these bytecodes. See Readme for more info.
        avoSafeBytecode = avoFactory.avoSafeBytecode();
        avoMultiSafeBytecode = avoFactory.avoMultiSafeBytecode();
    }
}

abstract contract AvoForwarderVariables is AvoForwarderConstants, Initializable, OwnableUpgradeable {
    /// @dev variables here start at storage slot 101, before is:
    /// - Initializable with storage slot 0:
    /// uint8 private _initialized;
    /// bool private _initializing;
    /// - OwnableUpgradeable with slots 1 to 100:
    /// uint256[50] private __gap; (from ContextUpgradeable, slot 1 until slot 50)
    /// address private _owner; (at slot 51)
    /// uint256[49] private __gap; (slot 52 until slot 100)

    // ---------------- slot 101 -----------------

    /// @notice allowed broadcasters that can call execute() methods. allowed if set to 1
    mapping(address => uint256) public broadcasters;

    // ---------------- slot 102 -----------------

    /// @notice allowed auths. allowed if set to 1
    mapping(address => uint256) public auths;
}

abstract contract AvoForwarderErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoForwarder__InvalidParams();

    /// @notice thrown when a caller is not authorized to execute a certain action
    error AvoForwarder__Unauthorized();

    /// @notice thrown when trying to execute legacy methods for a not yet deployed AvoSafe
    error AvoForwarder__LegacyVersionNotDeployed();
}

abstract contract AvoForwarderStructs {
    /// @notice struct mapping an address value to a boolean flag.
    /// @dev when used as input param, removes need to make sure two input arrays are of same length etc.
    struct AddressBool {
        address addr;
        bool value;
    }
}

abstract contract AvoForwarderEvents is AvoForwarderStructs {
    /// @notice emitted when all actions for AvoWallet.cast() are executed successfully
    event Executed(
        address indexed avoSafeOwner,
        address indexed avoSafeAddress,
        address indexed source,
        bytes metadata
    );

    /// @notice emitted if one of the actions in AvoWallet.cast() fails
    event ExecuteFailed(
        address indexed avoSafeOwner,
        address indexed avoSafeAddress,
        address indexed source,
        bytes metadata,
        string reason
    );

    /// @notice emitted if a broadcasters allowed status is updated
    event BroadcasterUpdated(address indexed broadcaster, bool indexed status);

    /// @notice emitted if a auths allowed status is updated
    event AuthUpdated(address indexed auth, bool indexed status);
}

abstract contract AvoForwarderCore is
    AvoForwarderConstants,
    AvoForwarderVariables,
    AvoForwarderStructs,
    AvoForwarderEvents,
    AvoForwarderErrors
{
    /***********************************|
    |             MODIFIERS             |
    |__________________________________*/

    /// @notice checks if msg.sender is an allowed broadcaster, reverts if not
    modifier onlyBroadcaster() {
        if (broadcasters[msg.sender] != 1) {
            revert AvoForwarder__Unauthorized();
        }
        _;
    }

    /// @notice checks if an address is not 0x000..., revert if it is
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert AvoForwarder__InvalidParams();
        }
        _;
    }

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    /// @notice constructor sets the immutable avoFactory address and avoSafeBytecode derived from it
    constructor(IAvoFactory avoFactory_) validAddress(address(avoFactory_)) AvoForwarderConstants(avoFactory_) {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev gets or if necessary deploys an AvoSafe for owner `from_` and returns the address
    function _getDeployedAvoWallet(address from_) internal returns (address) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return computedAvoSafeAddress_;
        } else {
            return avoFactory.deploy(from_);
        }
    }

    /// @dev gets or if necessary deploys an AvoMultiSafe for owner `from_` and returns the address
    function _getDeployedAvoMultisig(address from_) internal returns (address) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddressMultisig(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return computedAvoSafeAddress_;
        } else {
            return avoFactory.deployMultisig(from_);
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for a AvoSafe deployment for `owner_`
    function _computeAvoSafeAddress(address owner_) internal view returns (address computedAddress_) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSalt(owner_), avoSafeBytecode)
        );

        // cast last 20 bytes of hash to address
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev computes the deterministic contract address `computedAddress_` for a AvoSafeMultsig deployment for `owner_`
    function _computeAvoSafeAddressMultisig(address owner_) internal view returns (address computedAddress_) {
        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSaltMultisig(owner_), avoMultiSafeBytecode)
        );

        // cast last 20 bytes of hash to address
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev  gets the bytes32 salt used for deterministic deployment for `owner_`
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev  gets the bytes32 salt used for deterministic Multisig deployment for `owner_`
    function _getSaltMultisig(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    function _getDeployedLegacyAvoWallet(address from_) internal view returns (address) {
        // For legacy versions, AvoWallet must already be deployed
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (!Address.isContract(computedAvoSafeAddress_)) {
            revert AvoForwarder__LegacyVersionNotDeployed();
        }

        return computedAvoSafeAddress_;
    }
}

abstract contract AvoForwarderViews is AvoForwarderCore {
    /// @notice checks if a `broadcaster_` address is an allowed broadcaster
    function isBroadcaster(address broadcaster_) external view returns (bool) {
        return broadcasters[broadcaster_] == 1;
    }

    /// @notice checks if a `broadcaster_` address is an allowed auth
    function isAuth(address auth_) external view returns (bool) {
        return auths[auth_] == 1;
    }

    /// @notice         Retrieves the current avoSafeNonce of AvoWallet for owner address, needed for signatures
    /// @param owner_   AvoSafe Owner to retrieve the nonce for. Address signing a tx
    /// @return         returns the avoSafeNonce for the owner necessary to sign a meta transaction
    function avoSafeNonce(address owner_) external view returns (uint88) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (Address.isContract(avoAddress_)) {
            return IAvoWalletV3(avoAddress_).avoSafeNonce();
        }

        return 0;
    }

    /// @notice         Retrieves the current AvoWallet implementation name for owner address, needed for signatures
    /// @param owner_   AvoSafe Owner to retrieve the name for. Address signing a tx
    /// @return         returns the domain separator name for the owner necessary to sign a meta transaction
    function avoWalletVersionName(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoWallet is deployed, return value from deployed contract
            return IAvoWalletV3(avoAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoWalletV3(avoFactory.avoWalletImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice         Retrieves the current AvoWallet implementation version for owner address, needed for signatures
    /// @param owner_   AvoSafe Owner to retrieve the version for. Address signing a tx
    /// @return         returns the domain separator version for the owner necessary to sign a meta transaction
    function avoWalletVersion(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoWallet is deployed, return value from deployed contract
            return IAvoWalletV3(avoAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoWalletV3(avoFactory.avoWalletImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice Computes the deterministic AvoSafe address for `owner_` based on Create2
    function computeAddress(address owner_) external view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeAvoSafeAddress(owner_);
    }
}

abstract contract AvoForwarderViewsMultisig is AvoForwarderCore {
    /// @notice         Retrieves the current avoSafeNonce of AvoMultisig for owner address, needed for signatures
    /// @param owner_   AvoMultisig owner to retrieve the nonce for. Address signing a tx
    /// @return         returns the avoSafeNonce for the owner necessary to sign a meta transaction
    function avoSafeNonceMultisig(address owner_) external view returns (uint88) {
        address avoAddress_ = _computeAvoSafeAddressMultisig(owner_);
        if (Address.isContract(avoAddress_)) {
            return IAvoMultisigV3(avoAddress_).avoSafeNonce();
        }

        return 0;
    }

    /// @notice         Retrieves the current AvoMultisig implementation name for owner address, needed for signatures
    /// @param owner_   AvoMultisig owner to retrieve the name for. Address signing a tx
    /// @return         returns the domain separator name for the owner necessary to sign a meta transaction
    function avoMultisigVersionName(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddressMultisig(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoMultisig is deployed, return value from deployed contract
            return IAvoMultisigV3(avoAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoMultisigV3(avoFactory.avoMultisigImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice         Retrieves the current AvoMultisig implementation version for owner address, needed for signatures
    /// @param owner_   AvoMultisig owner to retrieve the version for. Address signing a tx
    /// @return         returns the domain separator version for the owner necessary to sign a meta transaction
    function avoMultisigVersion(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddressMultisig(owner_);
        if (Address.isContract(avoAddress_)) {
            // if AvoMultisig is deployed, return value from deployed contract
            return IAvoMultisigV3(avoAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoMultisigV3(avoFactory.avoMultisigImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice Computes the deterministic AvoMultiSafe address for `owner_` based on Create2
    function computeAddressMultisig(address owner_) external view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeAvoSafeAddressMultisig(owner_);
    }
}

abstract contract AvoForwarderV1 is AvoForwarderCore {
    /// @notice               Calls `cast` on an already deployed AvoWallet. For AvoWallet version 1.0.0
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    function executeV1(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) public payable onlyBroadcaster {
        IAvoWalletV1 avoWallet_ = IAvoWalletV1(_getDeployedLegacyAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            actions_,
            validUntil_,
            gas_,
            source_,
            metadata_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), source_, metadata_);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), source_, metadata_, revertReason_);
        }
    }

    /// @notice               Verify the transaction is valid and can be executed. For AvoWallet version 1.0.0
    ///                       IMPORTANT: Expected to be called via callStatic
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    /// @dev                  not marked as view to make as similar as possible to legacy version. Expected to be called via callStatic
    function verifyV1(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) public returns (bool) {
        IAvoWalletV1 avoWallet_ = IAvoWalletV1(_getDeployedLegacyAvoWallet(from_));

        return avoWallet_.verify(actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /***********************************|
    |      LEGACY DEPRECATED FOR V1     |
    |__________________________________*/

    /// @custom:deprecated    DEPRECATED: Use executeV1() instead. Will be removed in the next version
    /// @notice               see executeV1() for details
    function execute(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable onlyBroadcaster {
        return executeV1(from_, actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /// @custom:deprecated    DEPRECATED: Use executeV1() instead. Will be removed in the next version
    /// @notice               see verifyV1() for details
    function verify(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external returns (bool) {
        return verifyV1(from_, actions_, validUntil_, gas_, source_, metadata_, signature_);
    }
}

abstract contract AvoForwarderV2 is AvoForwarderCore {
    /// @notice               Calls `cast` on an already deployed AvoWallet. For AvoWallet version ~2
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    function executeV2(
        address from_,
        IAvoWalletV2.Action[] calldata actions_,
        IAvoWalletV2.CastParams calldata params_,
        bytes calldata signature_
    ) external payable onlyBroadcaster {
        IAvoWalletV2 avoWallet_ = IAvoWalletV2(_getDeployedLegacyAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            actions_,
            params_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice               Verify the transaction is valid and can be executed. For deployed AvoWallet version ~2
    ///                       IMPORTANT: Expected to be called via callStatic
    ///                       Returns true if valid, reverts otherwise:
    ///                       e.g. if input params, signature or avoSafeNonce etc. are invalid.
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    /// @dev                  not marked as view because it does potentially state by deploying the AvoWallet for "from" if it does not exist yet.
    ///                       Expected to be called via callStatic
    function verifyV2(
        address from_,
        IAvoWalletV2.Action[] calldata actions_,
        IAvoWalletV2.CastParams calldata params_,
        bytes calldata signature_
    ) external returns (bool) {
        IAvoWalletV2 avoWallet_ = IAvoWalletV2(_getDeployedLegacyAvoWallet(from_));

        return avoWallet_.verify(actions_, params_, signature_);
    }
}

abstract contract AvoForwarderV3 is AvoForwarderCore {
    /// @notice                 Deploys AvoSafe for owner if necessary and calls `cast` on it. For AvoWallet version ~3
    ///                         This method should be called by relayers.
    /// @param from_            AvoSafe Owner (not the one who signed the signature, but rather the owner of the AvoSafe)
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    function executeV3(
        address from_,
        IAvoWalletV3.CastParams calldata params_,
        IAvoWalletV3.CastForwardParams calldata forwardParams_,
        IAvoWalletV3.SignatureParams calldata signatureParams_
    ) external payable onlyBroadcaster {
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoWalletV3 avoWallet_ = IAvoWalletV3(_getDeployedAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            params_,
            forwardParams_,
            signatureParams_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice                 Verify the transaction is valid and can be executed. For AvoWallet version ~3
    ///                         IMPORTANT: Expected to be called via callStatic
    ///                         Returns true if valid, reverts otherwise:
    ///                         e.g. if input params, signature or avoSafeNonce etc. are invalid.
    /// @param from_            AvoSafe Owner (not the one who signed the signature, but rather the owner of the AvoSafe)
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    /// @dev                    can not be marked as view because it does potentially modify state by deploying the
    ///                         AvoWallet for "from" if it does not exist yet. Thus expected to be called via callStatic
    function verifyV3(
        address from_,
        IAvoWalletV3.CastParams calldata params_,
        IAvoWalletV3.CastForwardParams calldata forwardParams_,
        IAvoWalletV3.SignatureParams calldata signatureParams_
    ) external returns (bool) {
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        IAvoWalletV3 avoWallet_ = IAvoWalletV3(_getDeployedAvoWallet(from_));

        return avoWallet_.verify(params_, forwardParams_, signatureParams_);
    }
}

abstract contract AvoForwarderMultisig is AvoForwarderCore {
    /// @notice                  Deploys AvoMultiSafe for owner if necessary and calls `cast` on it.
    ///                          This method should be called by relayers.
    /// @param from_             AvoMultiSafe owner (not the one who signed the signature, but rather the owner of the AvoMultiSafe)
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ array of struct for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                          For smart contract signatures it must fulfill the requirements for the relevant
    ///                          smart contract `.isValidSignature()` EIP1271 logic
    ///                          -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                          If defined, it must match the actual signature signer or refer to the smart contract
    ///                          that must be an allowed signer and validates signature via EIP1271
    function executeMultisigV3(
        address from_,
        IAvoMultisigV3.CastParams calldata params_,
        IAvoMultisigV3.CastForwardParams calldata forwardParams_,
        IAvoMultisigV3.SignatureParams[] calldata signaturesParams_
    ) external payable onlyBroadcaster {
        // _getDeployedAvoMultisig automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoMultisigV3 avoMultisig_ = IAvoMultisigV3(_getDeployedAvoMultisig(from_));

        (bool success_, string memory revertReason_) = avoMultisig_.cast{ value: msg.value }(
            params_,
            forwardParams_,
            signaturesParams_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoMultisig_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(from_, address(avoMultisig_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice                  Verify the transaction is valid and can be executed.
    ///                          IMPORTANT: Expected to be called via callStatic
    ///                          Returns true if valid, reverts otherwise:
    ///                          e.g. if input params, signature or avoSafeNonce etc. are invalid.
    /// @param from_             AvoMultiSafe owner (not the one who signed the signature, but rather the owner of the AvoMultiSafe)
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ array of struct for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                          For smart contract signatures it must fulfill the requirements for the relevant
    ///                          smart contract `.isValidSignature()` EIP1271 logic
    ///                          -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                          If defined, it must match the actual signature signer or refer to the smart contract
    ///                          that must be an allowed signer and validates signature via EIP1271
    /// @return                  returns true if everything is valid, otherwise reverts
    /// @dev                     can not be marked as view because it does potentially modify state by deploying the
    ///                          AvoMultisig for "from" if it does not exist yet. Thus expected to be called via callStatic
    function verifyMultisigV3(
        address from_,
        IAvoMultisigV3.CastParams calldata params_,
        IAvoMultisigV3.CastForwardParams calldata forwardParams_,
        IAvoMultisigV3.SignatureParams[] calldata signaturesParams_
    ) external returns (bool) {
        // _getDeployedAvoMultisig automatically checks if AvoMultiSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoMultisigV3 avoMultisig_ = IAvoMultisigV3(_getDeployedAvoMultisig(from_));

        return avoMultisig_.verify(params_, forwardParams_, signaturesParams_);
    }
}

abstract contract AvoForwarderOwnerActions is AvoForwarderCore {
    /// @dev modifier checks if `msg.sender` is either owner or allowed auth, reverts if not.
    modifier onlyAuthOrOwner() {
        if (!(msg.sender == owner() || auths[msg.sender] == 1)) {
            revert AvoForwarder__Unauthorized();
        }

        _;
    }

    /// @notice updates allowed status for broadcasters based on `broadcastersStatus_` and emits `BroadcastersUpdated`.
    /// Executable by allowed auths or owner only
    function updateBroadcasters(AddressBool[] calldata broadcastersStatus_) external onlyAuthOrOwner {
        uint256 length_ = broadcastersStatus_.length;
        for (uint256 i; i < length_; ) {
            if (broadcastersStatus_[i].addr == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            broadcasters[broadcastersStatus_[i].addr] = broadcastersStatus_[i].value ? 1 : 0;

            emit BroadcasterUpdated(broadcastersStatus_[i].addr, broadcastersStatus_[i].value);

            unchecked {
                i++;
            }
        }
    }

    /// @notice updates allowed status for a auths based on `authsStatus_` and emits `AuthsUpdated`.
    /// Executable by allowed auths or owner only. auths can only remove themselves
    function updateAuths(AddressBool[] calldata authsStatus_) external onlyAuthOrOwner {
        uint256 length_ = authsStatus_.length;

        bool isMsgSenderOwner = msg.sender == owner();

        for (uint256 i; i < length_; ) {
            if (authsStatus_[i].addr == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            uint256 setStatus_ = authsStatus_[i].value ? 1 : 0;

            // if msg.sender is auth, then operation must be remove and address to be removed must be auth itself
            if (!(isMsgSenderOwner || (setStatus_ == 0 && msg.sender == authsStatus_[i].addr))) {
                revert AvoForwarder__Unauthorized();
            }

            auths[authsStatus_[i].addr] = setStatus_;

            emit AuthUpdated(authsStatus_[i].addr, authsStatus_[i].value);

            unchecked {
                i++;
            }
        }
    }
}

/// @title    AvoForwarder v3.0.0
/// @notice   Only compatible with forwarding `cast` calls to AvoWallet contracts. This is not a generic forwarder.
///           This is NOT a "TrustedForwarder" as proposed in EIP-2770. See notice in AvoWallet.
/// @dev      Does not validate the EIP712 signature (instead this is done in the AvoWallet)
///           contract is Upgradeable through AvoForwarderProxy
contract AvoForwarder is
    AvoForwarderCore,
    AvoForwarderViews,
    AvoForwarderViewsMultisig,
    AvoForwarderV1,
    AvoForwarderV2,
    AvoForwarderV3,
    AvoForwarderMultisig,
    AvoForwarderOwnerActions
{
    /// @notice constructor sets the immutable avoFactory address and avoSafeBytecode derived from it
    constructor(IAvoFactory avoFactory_) AvoForwarderCore(avoFactory_) {}

    /// @notice initializes the contract
    function initialize(address owner_) public validAddress(owner_) initializer {
        _transferOwnership(owner_);
    }

    /// @notice reinitiliaze to set owner, configuring OwnableUpgradeable added in version 2.1.0.
    /// skips setting owner if it is already set. for fresh deployments, owner set in initialize() can not be overwritten
    /// @param owner_                address of owner_ allowed to executed auth limited methods
    /// @param allowedBroadcasters_  initial list of allowed broadcasters to be enabled right away
    function reinitialize(
        address owner_,
        address[] calldata allowedBroadcasters_
    ) public validAddress(owner_) reinitializer(2) {
        if (owner() == address(0)) {
            // only set owner if it's not already set. but do not revert so initializer storage var is set to 2 always
            _transferOwnership(owner_);
        }

        // set initial allowed broadcasters
        uint256 length_ = allowedBroadcasters_.length;
        for (uint256 i; i < length_; ) {
            if (allowedBroadcasters_[i] == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            broadcasters[allowedBroadcasters_[i]] = 1;

            emit BroadcasterUpdated(allowedBroadcasters_[i], true);

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title   IAvoSafe
/// @notice  interface to access _avoWalletImpl on-chain
interface IAvoSafe {
    function _avoWalletImpl() external view returns (address);
}

/// @title      AvoSafe
/// @notice     Proxy for AvoWallets as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
/// @dev        If this contract changes then the deployment addresses for new AvoSafes through factory change too!!
///             Relayers might want to pass in version as new param then to forward to the correct factory
contract AvoSafe {
    /// @notice address of the Avo wallet logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    _avoWalletImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         To reduce deployment costs this variable is internal but can still be retrieved with
    ///         _avoWalletImpl(), see code and comments in fallback below
    address internal _avoWalletImpl;

    /// @notice   sets _avoWalletImpl address, fetching it from msg.sender via avoWalletImpl()
    /// @dev      avoWalletImpl_ is not an input param to not influence the deterministic Create2 address!
    constructor() {
        // "\x8e\x7d\xaf\x69" is hardcoded bytes of function selector for avoWalletImpl()
        (bool success_, bytes memory data_) = msg.sender.call(bytes("\x8e\x7d\xaf\x69"));

        address avoWalletImpl_;
        assembly {
            // cast last 20 bytes of hash to address
            avoWalletImpl_ := mload(add(data_, 32))
        }

        if (!success_ || avoWalletImpl_.code.length == 0) {
            revert();
        }

        _avoWalletImpl = avoWalletImpl_;
    }

    /// @notice Delegates the current call to `_avoWalletImpl` unless _avoWalletImpl() is called
    ///         if _avoWalletImpl() is called then the address for _avoWalletImpl is returned
    /// @dev    Mostly based on OpenZeppelin Proxy.sol
    fallback() external payable {
        assembly {
            // load address avoWalletImpl_ from storage
            let avoWalletImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == 87e9052a (function selector for _avoWalletImpl()) then we return the _avoWalletImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0x87e9052a00000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoWalletImpl_) // store address avoWalletImpl_ at memory address 0x0
                return(0, 0x20) // send first 20 bytes of address at memory address 0x0
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoWalletImpl_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoVersionsRegistry (proxy) address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice returns Avo wallet logic contract address that new AvoSafe deployments point to
    function avoWalletImpl() external view returns (address);

    /// @notice returns AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    function avoMultisigImpl() external view returns (address);

    /// @notice           Checks if a certain address is an AvoSafe instance. only works for already deployed AvoSafes
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice                    Computes the deterministic address for owner based on Create2
    /// @param owner_              AvoSafe owner
    /// @return computedAddress_   computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address computedAddress_);

    /// @notice                      Computes the deterministic Multisig address for owner based on Create2
    /// @param owner_                AvoMultiSafe owner
    /// @return computedAddress_     computed address for the contract (AvoSafe)
    function computeAddressMultisig(address owner_) external view returns (address computedAddress_);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                    Deploys an AvoSafe with non-default version for an owner deterministcally using Create2.
    ///                            ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                            Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_              AvoSafe owner
    /// @param avoWalletVersion_   Version of AvoWallet logic contract to deploy
    /// @return                    deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice         Deploys an AvoMultiSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoMultiSafe owner
    /// @return         deployed address for the contract (AvoMultiSafe)
    function deployMultisig(address owner_) external returns (address);

    /// @notice                      Deploys an AvoMultiSafe with non-default version for an owner
    ///                              deterministcally using Create2.
    ///                              Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_                AvoMultiSafe owner
    /// @param avoMultisigVersion_   Version of AvoMultisig logic contract to deploy
    /// @return                      deployed address for the contract (AvoMultiSafe)
    function deployMultisigWithVersion(address owner_, address avoMultisigVersion_) external returns (address);

    /// @notice                     registry can update the current AvoWallet implementation contract set as default
    ///                             `_ avoWalletImpl` logic contract address for new AvoSafe (proxy) deployments
    /// @param avoWalletImpl_       the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice                     registry can update the current AvoMultisig implementation contract set as default
    ///                             `_ avoMultisigImpl` logic contract address for new AvoMultiSafe (proxy) deployments
    /// @param avoMultisigImpl_     the new avoWalletImpl address
    function setAvoMultisigImpl(address avoMultisigImpl_) external;

    /// @notice      returns the byteCode for the AvoSafe contract used for Create2 address computation
    function avoSafeBytecode() external view returns (bytes32);

    /// @notice      returns  the byteCode for the AvoSafe contract used for Create2 address computation
    function avoMultiSafeBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoFactory } from "./IAvoFactory.sol";

interface IAvoForwarder {
    /// @notice returns the AvoFactory (proxy) address
    function avoFactory() external view returns (IAvoFactory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoMultisigV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoMultisig version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoMultisig logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               returns non-sequential nonce that will be marked as used when the request with the matching
    ///                       `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 non sequential nonce
    function nonSequentialNonce(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   returns non-sequential nonce that will be marked as used when the request with the matching
    ///                           `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the transaction signature for a `cast()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the transaction signature for a `castAuthorized()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   executes arbitrary `actions_` with a valid signature executable by AvoForwarder
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   executes arbitrary `actions_` through authorized tx sent with valid signatures.
    ///                           Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice             checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);
}

/// @notice full interface with some getters for storage variables
interface IAvoMultisigV3 is IAvoMultisigV3Base {
    /// @notice             AvoMultisig Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoFeeCollector {
    /// @notice FeeConfig params used to determine the fee
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        // for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%);
        // for static mode: absolute amount in native gas token to charge (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the fee for an AvoSafe (msg.sender) transaction `gasUsed_` based on fee configuration
    /// @param gasUsed_ amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version and reverts if not
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version
    ///                              and reverts if it is not
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version and reverts if not
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoWalletV1 {
    /// @notice an executable action via low-level call, including target, data and value
    struct Action {
        address target; // the targets to execute the actions on
        bytes data; // the data to be passed to the .call for each target
        uint256 value; // the msg.value to be passed to the .call for each target. set to 0 if none
    }

    /// @notice             AvoSafe Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint96);

    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice             Verify the transaction is valid and can be executed.
    ///                     Does not revert and returns successfully if the input is valid.
    ///                     Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_         As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_      Source like e.g. referral for this tx
    /// @param metadata_    Optional metadata for future flexibility
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary actions according to datas on targets
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call for every action.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects against potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fail
    function cast(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoWalletV2 {
    /// @notice an executable action via low-level call, including operation (call or delegateCall), target, data and value
    struct Action {
        /// @param target the target to execute the actions on
        address target;
        /// @param data the data to be passed to the call for each target
        bytes data;
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call), id must be 0 or 2
        uint256 operation;
    }

    /// @notice `cast()` and `castAuthorized()` input params
    struct CastParams {
        /// @param validUntil     Similar to EIP-2770: the highest block timestamp (instead of block number)
        ///                       that the request can be forwarded in, or 0 if request validity is not time-limited.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       (Given that the transaction is not executed right away for some reason)
        uint256 validUntil;
        /// @param gas            As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects against potential gas griefing attacks & ensures the relayer sends enough gas
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        /// @param source         Source like e.g. referral for this tx
        address source;
        /// @param id             id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        /// @param metadata       Optional metadata for future flexibility
        bytes metadata;
    }

    /// @notice             AvoSafe Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               Verify the transaction signature is valid and can be executed.
    ///                       This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary `actions_` with a valid signature
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call or .delegateCall for every action (depending on params).
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fails
    function cast(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice               executes arbitrary `actions_` through authorized tx sent by owner.
    ///                       Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  executes a .call or .delegateCall for every action (depending on params)
    /// @param actions_       the actions to execute (target, data, value, operation)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param maxFee_        the maximum acceptable fee expected to be paid (gas premium)
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fails
    function castAuthorized(
        Action[] calldata actions_,
        CastParams calldata params_,
        uint80 maxFee_
    ) external payable returns (bool success, string memory revertReason);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoWalletV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               returns non-sequential nonce that will be marked as used when the request with the matching
    ///                       `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 non sequential nonce
    function nonSequentialNonce(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice               returns non-sequential nonce that will be marked as used when the request with the matching
    ///                       `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_   Cast params related to execution through owner such as maxFee
    /// @return               bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                 Verify the transaction signature is valid and can be executed.
    ///                         This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                         Does not revert and returns successfully if the input is valid.
    ///                         Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external view returns (bool);

    /// @notice                 executes arbitrary `actions_` with a valid signature
    ///                         if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                    validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                 executes arbitrary `actions_` through authorized tx sent by owner.
    ///                         Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                         if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                    executes a .call or .delegateCall for every action (depending on params)
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_     Cast params related to execution through owner such as maxFee
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice             checks if an address `authority` is an allowed authority (returns true if allowed)
    function isAuthority(address authority_) external view returns (bool);
}

/// @notice full interface with some getters for storage variables
interface IAvoWalletV3 is IAvoWalletV3Base {
    /// @notice             AvoWallet Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);
}