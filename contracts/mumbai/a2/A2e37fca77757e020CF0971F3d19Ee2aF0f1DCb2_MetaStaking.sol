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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./StakingInterface.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// main node -> light node -> user
contract MetaStaking is StakingInterface, ReentrancyGuardUpgradeable {

    address public implementation;
    address public admin;
    mapping (uint256 => MainNodeInfo) public mainNodeInfo;  // node id -> info
    mapping (uint256 => LightNodeInfo) public lightNodeInfo; // node id -> info
    mapping (address => uint256) public ownerLightNodeId; // owner address -> node id
    mapping (address => StakeInfo) public stakeInfo; // address -> stake info
    mapping (address => uint256) public referRewards; // address -> refer award 
    mapping (address => bool) public lightNodeBlacklist; // address -> refer award 
    mapping (uint256 => mapping(address => uint256)) public dynamicReward; // date -> (address -> award) 
    mapping (address => uint256) public firstDynamicRecord; // address -> date 
    mapping (address => uint256) public dynamicRewardClaimed; // address -> amount claimed
    mapping(address => UnstakeInfo[]) public unstakeInfo; // user -> unstakeInfo 

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;  // seconds per day
    uint256 constant DEFAULT_RATE = 10000;  // default APR rate 
    uint256 public currentTotalStaked;  // current total staked in the contract
    uint256 public currentTotalReward;  // current total reward available for claiming
    uint256 public totalStaked;     // total staked amount (including unstaked)
    uint256 public totalReward;     // total reward generated (inlcuding claimed)
    uint256 public totalUnstaked;   // total unstaked 
    uint256 public totalRewardClaimed; // total reward claimed
    uint256 public stopLimit; // stop limit of light node 

    uint256 public mainNodeCap;     // staking cap for every main node  
    uint256 public currentMainNodeIndex; // start from 1
    uint256 public currentLightNodeIndex; // start from 1
    uint256 public initTime; // init time for staking 

    constructor () {
        admin = msg.sender;
    }

    function upgrade(address newImplementation) external {
        require(msg.sender == admin, "only admin authorized");
        implementation = newImplementation;
    }

    function _setInitTime(uint256 timestamp) external {
        require(msg.sender == admin);
        initTime = timestamp;
    }

    function _setStopLimit(uint256 limit) external  {
        require(msg.sender == admin, "only admin authorized");
        stopLimit = limit;
    }

    function _setMainNodeStakeCapacity(uint256 cap) external  {
        require(msg.sender == admin, "only admin authorized");
        mainNodeCap = cap;
    }

    function _setMainNodeStakeRate(uint256 id, uint256 ratio) external  {
        require(msg.sender == admin, "only admin authorized");
        MainNodeInfo storage node = mainNodeInfo[id];
        require(node.isUsed, "main node does not exists.");
        uint256 oldRate = node.rate;
        node.rate = ratio;
        emit NewStakeRate(id, oldRate, node.rate);
    }

    function _setMainNodeCommissionRate(uint256 id, uint256 rate) external  {
        require(msg.sender == admin, "only admin authorized");
        MainNodeInfo storage node = mainNodeInfo[id];
        require(node.isUsed, "main node does not exists.");
        uint256 oldRate = node.commissionRate;
        node.commissionRate = rate;
        emit NewMainNodeCommission(id, oldRate, rate);
    }

    function _setLightNodeCommissionRate(uint256 id, uint256 rate) external {
        require(rate <= 500, "ratio must be lower than 5%");
        require(ownerLightNodeId[msg.sender] == id, "only owner of light node authorized");
        LightNodeInfo storage node = lightNodeInfo[id];
        require(node.isUsed, "light node does not exists.");
        uint256 oldRate = node.commissionRate;
        node.commissionRate = rate;
        emit NewLightNodeCommission(id, oldRate, rate);
    }

    function _initMainNode(uint256 num) external  returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](num);
        for(uint256 i = currentMainNodeIndex; i < currentMainNodeIndex + num; i++)
        {
            MainNodeInfo memory node = MainNodeInfo(0, 0, 0, 0, 0, DEFAULT_RATE, 500, false, true);
            mainNodeInfo[i] = node;
            ids[i-currentMainNodeIndex] = i;
            emit NewMainNode(i, block.timestamp);
        }
        currentMainNodeIndex += num;
        return ids;
    }
    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient)  external {
        require(msg.sender == admin, "only admin authorized");
        Address.sendValue(payable(recipient), address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient)  external { 
        require(msg.sender == admin, "only admin authorized");
        (bool success, ) = asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
        require(success, "rescue failed.");
    }

    // update nodes info related
    function updateNodesInfo(address account, uint256 amount) internal {
        StakeInfo storage info = stakeInfo[account];
        require(info.isUsed, "invalid account");
        info.rewardAmount += amount;
        info.totalRewardAmount += amount;
        uint256 lightNodeId = info.lightNodeId;
        LightNodeInfo storage lightNode = lightNodeInfo[lightNodeId];
        require(lightNode.isUsed, "invalid light node");
        lightNode.rewardAmount += amount;
        lightNode.totalRewardAmount += amount;

        MainNodeInfo storage mainNode = mainNodeInfo[lightNode.mainNodeId];
        require(mainNode.isUsed, "invalid main node");
        mainNode.rewardAmount += amount;
        mainNode.totalRewardAmount += amount;

        currentTotalReward += amount;
        totalReward += amount;
    }

    function _setReferReward(uint256 batchNo, address[] calldata accounts, uint256[] calldata values) external  {
        require(msg.sender == admin, "only admin authorized");
        require(batchNo != 0, "batchNo cannot be empty");
        require(accounts.length == values.length, "length not match");
        
        uint256 key = block.timestamp / SECONDS_PER_DAY;
        for(uint i=0; i<accounts.length; i++)
        {
            if(firstDynamicRecord[accounts[i]] == 0)
                firstDynamicRecord[accounts[i]] = key;
            dynamicReward[key][accounts[i]] += values[i];
            updateNodesInfo(accounts[i], values[i]);
        }
        emit ReferRewardSet(batchNo);
    }

    // get claimable dynamic principal 
    function getDynamicPrincipal(address account) public view returns(uint256) {
        uint256 leftAmount = 0;
        for(uint i=0; i<unstakeInfo[account].length; i++)
        {
            UnstakeInfo memory info = unstakeInfo[account][i];
            if(info.isClaimed == false) 
                leftAmount += info.amount;
        }
        return leftAmount;
    }
    // get claimable dynamic reward
    function getDynamicReward(address account) public view returns(uint256) {
        uint256 day = block.timestamp / SECONDS_PER_DAY;
        uint256 firstDate = firstDynamicRecord[account];
        if(firstDate == 0)
            return 0;

        uint256 totalDynamicReward = 0;
        for(uint i = 0; i < 100; i++)
        {
            uint256 key = day - i;
            if(key < firstDate)
                break;
            totalDynamicReward += dynamicReward[key][account]*(i+1)/100;
        }
        uint256 k = day - 100;
        while(k >= firstDate)
        {
            totalDynamicReward += dynamicReward[k][account];
            k--;
        }
        return totalDynamicReward;
    }

    function registerLightNode(uint256 id, address account, address referee, uint256 rate) external  returns(uint256) {
        require(msg.sender == admin, "only admin authorized");
        require(!lightNodeBlacklist[account], "account has a lightnode already");
        require(rate <= 500, "ratio must be lower than 500");
        MainNodeInfo storage node = mainNodeInfo[id];
        require(node.isUsed, "main node not exist");

        if(referee != address(0))
        {
            StakeInfo memory refereeUser = stakeInfo[referee];
            require(refereeUser.isUsed, "referee not exist");
        }
        node.totalLightNodes += 1;
        LightNodeInfo memory lightNode = LightNodeInfo(id, 0, 0, 0, 0, 0, block.timestamp, rate, account, false, true);
        uint256 lightNodeId = currentLightNodeIndex;
        lightNodeInfo[lightNodeId] = lightNode;
        ownerLightNodeId[account] = lightNodeId;
        currentLightNodeIndex += 1;
        emit NewLightNode(lightNodeId, id, account, block.timestamp);

        // register a new user
        StakeInfo storage info = stakeInfo[account];
        require(!info.isUsed, "has been registered");
        StakeInfo memory newInfo = StakeInfo(
            lightNodeId,
            block.timestamp,
            0,
            0,
            0,
            0,
            0,
            referee,
            true
        );
        stakeInfo[account] = newInfo;
        LightNodeInfo storage lnode = lightNodeInfo[lightNodeId];
        lnode.totalUsers += 1;
        lightNodeBlacklist[account] = true;
        emit NewUser(account, lightNodeId, id, referee, block.timestamp);

        return lightNodeId;
    }

    function reward(address account) public view returns (uint256) {
        StakeInfo memory info = stakeInfo[account];
        if(info.isUsed)
        {
            return info.rewardAmount - dynamicRewardClaimed[account];
        }else
            return 0;
    }

    function unstakeRecordSize(address account) public view returns (uint256) {
        UnstakeInfo[] memory infos = unstakeInfo[account];
        return infos.length;
    }

    function unstakeRecords(address account) public view returns (UnstakeInfo[] memory) {
        UnstakeInfo[] memory infos = unstakeInfo[account];
        return infos;
    }

    function totalUnstakedAmount(address account) public view returns (uint256) {
        UnstakeInfo[] memory infos = unstakeInfo[account];
        uint256 amount = 0;
        for(uint i=0; i<infos.length; i++)
            amount += infos[i].amount;
        return amount;
    }

    function totalUnstakeReleasedAmount(address account) public view returns (uint256) {
        UnstakeInfo[] memory infos = unstakeInfo[account];
        uint256 amount = 0;
        for(uint i=0; i<infos.length; i++)
        {
            if((block.timestamp - infos[i].timestamp) > 21 * 86400)
                amount += infos[i].amount;
        }
        return amount;
    }

    // register a new user 
    function registerUser(address referee) public {

        require(referee != address(0), "referee is invalid");
        StakeInfo storage info = stakeInfo[msg.sender];
        require(!info.isUsed, "has been registered");
        
        uint256 lightNodeId = ownerLightNodeId[referee];
        if(lightNodeId == 0)
        {
            StakeInfo memory referInfo = stakeInfo[referee];
            lightNodeId = referInfo.lightNodeId;
        }
        require(lightNodeId > 0, "invalid light node id");

        StakeInfo memory newInfo = StakeInfo(
            lightNodeId,
            block.timestamp,
            0,
            0,
            0,
            0,
            0,
            referee,
            true
        );
        stakeInfo[msg.sender] = newInfo;

        LightNodeInfo storage lightNode = lightNodeInfo[lightNodeId];
        require(lightNode.isUsed, "invalid light node id");
        lightNode.totalUsers += 1;
        uint256 mainNodeId = lightNode.mainNodeId;

        MainNodeInfo storage mainNode = mainNodeInfo[lightNode.mainNodeId];
        require(mainNode.isUsed, "invalid main node");

        emit NewUser(msg.sender, lightNodeId, mainNodeId, referee, block.timestamp);
    }

    // stake from light nodes
    function stake() public payable {

        require(block.timestamp >= initTime, "staking not started");

        StakeInfo storage info = stakeInfo[msg.sender];
        require(info.isUsed, "user not registered");
        require(info.lightNodeId != 0, "light node id not match");

        uint256 rate = DEFAULT_RATE;
        uint256 mainNodeId = 0;
        info.stakeAmount += msg.value;
        info.totalStakeAmount += msg.value;
        info.updateTime = block.timestamp;

        LightNodeInfo storage lightNode = lightNodeInfo[info.lightNodeId];
        require(lightNode.isUsed && !lightNode.isStopped, "light node stopped");
        lightNode.stakeAmount += msg.value;
        lightNode.totalStakeAmount += msg.value;
        mainNodeId = lightNode.mainNodeId;
        
        MainNodeInfo storage mainNode = mainNodeInfo[lightNode.mainNodeId];
        require(mainNode.isUsed && !mainNode.isStopped, "main node stopped");
        require(msg.value + mainNode.totalStakeAmount <= mainNodeCap, "exceeds main node capacity");
        mainNode.stakeAmount += msg.value;
        mainNode.totalStakeAmount += msg.value;
        currentTotalStaked += msg.value;
        totalStaked += msg.value;

        emit Staked(msg.sender, info.lightNodeId, mainNodeId, msg.value, rate, block.timestamp);
    }

    // restake
    function restake() public {

        require(block.timestamp >= initTime, "staking not started");

        StakeInfo storage info = stakeInfo[msg.sender];
        require(info.isUsed, "no stake record");
        uint256 dReward = getDynamicReward(msg.sender);
        uint256 amount = dReward - dynamicRewardClaimed[msg.sender];
        dynamicRewardClaimed[msg.sender] = dReward;

        info.stakeAmount += amount;
        info.totalStakeAmount += amount;
        info.totalRewardAmount += amount;
        info.updateTime = block.timestamp;

        LightNodeInfo storage lightNode = lightNodeInfo[info.lightNodeId];
        require(lightNode.isUsed && !lightNode.isStopped, "light node stopped");
        lightNode.stakeAmount += amount;
        lightNode.rewardAmount += amount;
        lightNode.totalStakeAmount += amount;
        lightNode.totalRewardAmount += amount;
        uint256 mainNodeId = lightNode.mainNodeId;
        
        MainNodeInfo storage mainNode = mainNodeInfo[lightNode.mainNodeId];
        require(mainNode.isUsed && !mainNode.isStopped, "main node stopped");
        mainNode.stakeAmount += amount;
        mainNode.rewardAmount += amount;
        mainNode.totalStakeAmount += amount;
        mainNode.totalRewardAmount += amount;

        currentTotalReward += amount;
        totalReward += amount;
        currentTotalStaked += amount;
        totalStaked += amount;

        emit ReStaked(msg.sender, info.lightNodeId, mainNodeId, amount, block.timestamp);
    }

    function claimReward(uint256 amount) public nonReentrant {
        require(block.timestamp >= initTime, "staking not started");
        require(amount > 0, "invalid amount");
        StakeInfo storage info = stakeInfo[msg.sender];
        require(info.isUsed, "no stake reward");

        uint256 claimableAmount = getDynamicReward(msg.sender) - dynamicRewardClaimed[msg.sender];
        require(amount <= claimableAmount, "Insufficient rewards");
        dynamicRewardClaimed[msg.sender] += amount;
        info.updateTime = block.timestamp;

        LightNodeInfo storage lightNode = lightNodeInfo[info.lightNodeId];
        lightNode.rewardAmount -= amount;

        MainNodeInfo storage mainNode = mainNodeInfo[lightNode.mainNodeId];
        mainNode.rewardAmount -= amount;
        
        currentTotalReward -= amount;
        totalRewardClaimed += amount;

        Address.sendValue(payable(msg.sender), amount);

        emit RewardClaimed(msg.sender, info.lightNodeId, lightNode.mainNodeId, amount, block.timestamp);
    }

    function unstake(uint256 amount) public nonReentrant{
        require(block.timestamp >= initTime, "staking not started");
        StakeInfo storage info = stakeInfo[msg.sender];
        require(info.isUsed, "no stake record");
        require(amount > 0 && info.stakeAmount >= amount, "no enough tokens to withdraw");

        info.updateTime = block.timestamp;
        info.stakeAmount -= amount;
        if(info.stakeAmount < stopLimit * 1e18)
            info.unstakeCount += 1;

        LightNodeInfo storage lightNode = lightNodeInfo[info.lightNodeId];
        lightNode.stakeAmount -= amount;
        if(ownerLightNodeId[msg.sender] == info.lightNodeId && info.unstakeCount >= 3)
            lightNode.isStopped = true;

        MainNodeInfo storage mainNode = mainNodeInfo[lightNode.mainNodeId];
        mainNode.stakeAmount -= amount;

        currentTotalStaked -= amount;
        totalUnstaked += amount;
        unstakeInfo[msg.sender].push(UnstakeInfo(block.timestamp, amount, false, true));

        emit Unstaked(msg.sender, info.lightNodeId, lightNode.mainNodeId, amount, info.stakeAmount, block.timestamp);
    }

    function withdrawById(uint256 id) public nonReentrant{
        require(block.timestamp >= initTime, "staking not started");
        require(id < unstakeInfo[msg.sender].length, "invalid unstake id");
        UnstakeInfo storage info = unstakeInfo[msg.sender][id];
        require(info.isUsed, "no unstake record");
        require((block.timestamp - info.timestamp) >= 21 * 86400, "not released within 21 days"); 
        Address.sendValue(payable(msg.sender), info.amount);
        info.isClaimed = true;
        uint256 leftAmount = getDynamicPrincipal(msg.sender);
        emit Withdraw(msg.sender, info.amount, leftAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

interface StakingInterface {
    struct MainNodeInfo {
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 totalLightNodes;
        uint256 rate;            // rate for APR base is 10000
        uint256 commissionRate;  // commission rate of main node 
        bool isStopped;
        bool isUsed;
    }

    struct LightNodeInfo {
        uint256 mainNodeId;
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 totalUsers;
        uint256 registerTime;
        uint256 commissionRate;
        address ownerAddress;
        bool isStopped;
        bool isUsed;
    }

    struct StakeInfo {
        uint256 lightNodeId;
        uint256 updateTime;
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 unstakeCount;
        address referee; 
        bool isUsed;
    }

    struct UnstakeInfo {
        uint256 timestamp;
        uint256 amount;
        bool isClaimed;
        bool isUsed;
    }

    event NewUser(address indexed user, uint256 lightId, uint256 mainId, address referee, uint256 timestamp);
    event Staked( address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 amount, uint256 rate, uint256 timestamp);
    event Unstaked(address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 amount, uint256 leftAmount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 leftAmount);
    event RewardClaimed(address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 amount, uint256 timestamp);
    event NewStakeRate(uint256 nodeId, uint256 oldRate, uint256 newRate);
    event NewMainNodeCommission(uint256 nodeId, uint256 oldRate, uint256 rate);
    event NewLightNodeCommission(uint256 nodeId, uint256 oldRate, uint256 rate);
    event NewMainNode(uint256 id, uint256 timestamp);
    event NewLightNode(uint256 id, uint256 mainId, address owner, uint256 timestamp);
    event ReferRewardSet(uint256 batchNo);
    event ReStaked(address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 reward, uint256 timestamp);
}