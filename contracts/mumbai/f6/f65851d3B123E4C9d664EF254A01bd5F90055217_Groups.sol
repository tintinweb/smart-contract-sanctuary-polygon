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

    @title Groups
    v0.2.1
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IUserProfiles.sol";
import "./interfaces/IGroupTokens.sol";

contract Groups is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Trusted Contracts
    mapping (address => bool) public trustedContracts;

    struct GroupDetails {
        address ownerAddress;
        address[] members;
        string groupName;
        address groupAddress;
        string details;
        string uri;
        string[3] colors;
    }

    // Max length of details to save
    uint256 public maxDetailsLength;

    // Mapping of Group ID to Group Details
    mapping (uint256 => GroupDetails) public groupDetails;

    // Group Address to Group ID mapping
    mapping(address => uint256) public groupAddressToID;

    // User Member Mapping to Groups
    mapping(address => uint256[]) public groupMemberships;

    // Member of groups (Address of member => Group Token ID => True/False is Member)
    mapping (address => mapping (uint256 => bool)) public isMemberOf;

    uint256 public maxMembersPerGroup;

    // Link the KUtils
    IKUtils public KUtils;

    // Link the User Profiles
    IUserProfiles public UserProfiles;

    // Link the Group Tokens
    IGroupTokens public GroupTokens;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxMembersPerGroup, uint256 _maxDetailsLength) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        // Setup the default Admin
        admins[msg.sender] = true;

        // Set max members per group
        maxMembersPerGroup = _maxMembersPerGroup;

        // Set max Details length
        maxDetailsLength = _maxDetailsLength;
    }


    /*

    EVENTS

    */

    event logLeaveGroup(uint256 indexed groupID, address indexed member);
    event logJoinGroup(uint256 indexed groupID, address indexed member);
    event logUpdateGroupNameFormat(uint256 indexed groupID, string groupName);


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier onlyTrustedContracts() {
        require(trustedContracts[msg.sender], "Only trusted contracts can call this function.");
        _;
    }

    modifier onlyGroupOwners(uint256 groupID) {
        require(groupDetails[groupID].ownerAddress == msg.sender, "Only group owners can call this function.");
        _;
    }

    modifier onlyGroupMembers(uint256 groupID, address member) {
        require(isMemberOf[member][groupID], "They are not a member of this group");
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateTrustedContract(address contractAddress, bool status) public onlyAdmins {
        trustedContracts[contractAddress] = status;
    }

    function updateContracts(address _kutils, address _userProfiles, address _groupTokens) public onlyAdmins {
        // Update the KUtils contract address
        KUtils = IKUtils(_kutils);

        // Update the User Profiles contract address
        UserProfiles = IUserProfiles(_userProfiles);

        // Update the Group Tokens contract address
        GroupTokens = IGroupTokens(_groupTokens);
    }

    function updateMaxMembers(uint256 newMax) public onlyAdmins {
        maxMembersPerGroup = newMax;
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Get the address of the owner of a group
    * @param groupID : the unique Group ID of the group to lookup
    * @return address : the address of the owner of a group
    */
    function getOwnerOfGroupByID(uint256 groupID) public view whenNotPaused returns (address){
        return groupDetails[groupID].ownerAddress;
    }

    /**
    * @dev Get the members of a group
    * @param groupID : the unique Group ID of the group to lookup
    * @return address[] : an array of addresses of members of a group
    */
    function getMembersOfGroupByID(uint256 groupID) public view whenNotPaused returns (address[] memory){
        return groupDetails[groupID].members;
    }

    /**
    * @dev Check if a user or group is a member of a group
    * @param groupID : the unique Group ID of the group to lookup
    * @param member : the address of the member you want to lookup
    * @return bool : True = they are a member / False = they are not a member
    */
    function isMemberOfGroupByID(uint256 groupID, address member) public view whenNotPaused returns (bool){
        return isMemberOf[member][groupID];
    }

    /**
    * @dev Get the Group ID of a group from the group name
    * @param groupName : the name of the group to lookup
    * @return uint256 : the unique group ID of the group
    */
    function getGroupID(string calldata groupName) public view whenNotPaused returns (uint256){
        bytes32 groupBytes = keccak256(bytes(KUtils._toLower(groupName)));
        return uint256(groupBytes);
    }

    /**
    * @dev Get the Group Address of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return address : the address of the group
    */
    function getGroupAddressFromID(uint256 groupID) public view whenNotPaused returns (address){
        return groupDetails[groupID].groupAddress;
    }

    /**
    * @dev Get the Group ID of a group from the group address
    * @param groupAddress : the address of the group to lookup
    * @return uint256 : the unique Group ID of the group
    */
    function getGroupIDFromAddress(address groupAddress) public view whenNotPaused returns (uint256){
        return groupAddressToID[groupAddress];
    }

    /**
    * @dev Get the address of the owner of a group
    * @param groupAddress : the address of the group to lookup
    * @return address : the address of the owner of the group
    */
    function getOwnerOfGroupByAddress(address groupAddress) public view whenNotPaused returns (address){
        return groupDetails[groupAddressToID[groupAddress]].ownerAddress;
    }

    /**
    * @dev Get a list of groups that a user or group belongs to
    * @param lookupAddress : the address of the user or group to lookup
    * @return uint256[] : a list of group IDs that the user or group belongs to
    */
    function getGroupMemberships(address lookupAddress) public view whenNotPaused returns (uint256[] memory){
        return groupMemberships[lookupAddress];
    }

    /**
    * @dev Check to see if a group is available to mint
    * @param groupName : the name of the group to lookup
    * @return bool : True = the group is available to mint / False = the group has already been minted
    */
    function isGroupAvailable(string calldata groupName) public view whenNotPaused returns (bool){
        if (groupDetails[getGroupID(groupName)].groupAddress != address(0)){
            return false;
        }
        return true;
    }

    /**
    * @dev Get the Group Name of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string : the name of the group
    */
    // Get the group name from an ID
    function getGroupNameFromID(uint256 groupID) public view returns (string memory){
        return groupDetails[groupID].groupName;
    }

    /**
    * @dev Get the Group Details of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string : the details of the group
    */
    // Get the group details from an ID
    function getGroupDetailsFromID(uint256 groupID) public view returns (string memory){
        return groupDetails[groupID].details;
    }

    /**
    * @dev Get the Group URI of a group from the group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string : the URI of the group
    */
    function getGroupURIFromID(uint256 groupID) public view returns (string memory){
        return groupDetails[groupID].uri;
    }

    /**
    * @dev Get the colors used as the backgroun of the NFT of a group ID
    * @param groupID : the unique Group ID of the group to lookup
    * @return string[3] : an array of the three colors in hex format used to make the background color of the group NFT
    */
    function getGroupColorsFromID(uint256 groupID) public view returns (string[3] memory){
        return groupDetails[groupID].colors;
    }

    /**
    * @dev Add a user as a member to a group
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group to add the user to
    * @param member : the address of the user or group to add as a user to the group
    */
    function addMemberToGroup(uint256 groupID, address member) public onlyGroupOwners(groupID) whenNotPaused nonReentrant{
        // Add them to the group
        addMember(groupID, member);
    }

    /**
    * @dev Remove a user from a group
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group to remove the user from
    * @param member : the address of the user to remove from the group
    */
    function removeMemberFromGroup(uint256 groupID, address member) public onlyGroupOwners(groupID) whenNotPaused {
        removeMember(groupID, member);
    }

    /**
    * @dev Leave a group (self)
    * @dev Can only be called by a user in the group provided
    * @param groupID : the unique Group ID of the group to leave from
    */
    function leaveGroup(uint256 groupID) public onlyGroupMembers(groupID, msg.sender) whenNotPaused nonReentrant{
        removeMember(groupID, msg.sender);
    }

    /**
    * @dev This allows owners to change the case of their group name (mygroup => MyGroup)
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group modify the case of the name
    * @param groupName : the formatting of the group name to change to
    */
    function updateGroupNameFormat(uint256 groupID, string calldata groupName) public onlyGroupOwners(groupID) whenNotPaused  {
        // Ensure the group name is not empty
        require(bytes(groupName).length > 0, "Group name cannot be empty");

        // Make sure the name is still the same
        require(groupID == getGroupID(groupName), "Can only change the case");

        // Set the group name
        groupDetails[groupID].groupName = groupName;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);

        // Log the change
        emit logUpdateGroupNameFormat(groupID, groupName);
    }

    /**
    * @dev This allows users to change colors of their group image (Hex format)
    * @dev Can only be called by the owner of the group
    * @dev (000000 = Black / FFFFFF = White / b154f0 = Purple)
    * @param groupID : the unique Group ID of the group modify colors for
    * @param color1 : the first color in hex format to set the NFT background to
    * @param color2 : the second color in hex format to set the NFT background to
    * @param color3 : the third color in hex format to set the NFT background to
    */
    function updateGroupNFTColors(uint256 groupID, string calldata color1, string calldata color2, string calldata color3) public onlyGroupOwners(groupID) whenNotPaused {
        // Ensure valid hex length
        require(bytes(color1).length <= 6, "Invalid Hex color");
        require(bytes(color2).length <= 6, "Invalid Hex color");
        require(bytes(color3).length <= 6, "Invalid Hex color");

        groupDetails[groupID].colors[0] = color1;
        groupDetails[groupID].colors[1] = color2;
        groupDetails[groupID].colors[2] = color3;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);
    }

    /**
    * @dev This allows owners to change details associated with their group. These are written to the NFT metadata
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group modify
    * @param details : the details of the group to be written to the metadata of the NFT
    */
    function updateGroupNFTDetails(uint256 groupID, string calldata details) public onlyGroupOwners(groupID) whenNotPaused {
        // Make sure the details are within length limits
        require(bytes(details).length <= maxDetailsLength, "Details too long");

        groupDetails[groupID].details = details;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);
    }

    /**
    * @dev This allows owners to change details associated with their group. These are written to the NFT metadata
    * @dev Can only be called by the owner of the group
    * @param groupID : the unique Group ID of the group modify
    * @param uri : the URI of the group to be written to the metadata of the NFT
    */
    function updateGroupNFTURI(uint256 groupID, string calldata uri) public onlyGroupOwners(groupID) whenNotPaused {
        // Require a Avatar with RCF compliant characters only
        require(KUtils.isValidURI(uri), "Bad characters in URI");

        groupDetails[groupID].uri = uri;

        // Update the stored metadata for the group profile
        GroupTokens.adminUpdateGroupMetadata(groupID);
    }


    /*

    INTERNAL FUNCTIONS

    */

    function addMember(uint256 groupID, address member) internal {
        // Make sure there's room for membership in the group
        require(groupDetails[groupID].members.length < maxMembersPerGroup, "You have reached the max amount of members for this group");

        // Make sure they're not already a member
        require(!isMemberOf[member][groupID], "Already member of group");

        // Add them to the group
        isMemberOf[member][groupID] = true;

        // Add to the group member count
        groupDetails[groupID].members.push(member);

        // Add the group to their list of memberships
        groupMemberships[member].push(groupID);

        // Emit to the logs for external reference
        emit logJoinGroup(groupID, member);
    }

    function removeMember(uint256 groupID, address member) internal {
        // Remove them from the group
        isMemberOf[member][groupID] = false;

        // Remove it from the group members array
        uint256 place = 0;
        string memory addressString = KUtils.addressToString(member);
        for (uint i=0; i < groupDetails[groupID].members.length; i++) {
            if (KUtils.stringsEqual(KUtils.addressToString(groupDetails[groupID].members[i]), addressString)){
                place = i;
                break;
            }
        }

        // Swap the last entry with this one
        groupDetails[groupID].members[place] = groupDetails[groupID].members[groupDetails[groupID].members.length-1];

        // Remove the last element
        groupDetails[groupID].members.pop();

        // Remove the groups from membership
        place = 0;
        for (uint i=0; i < groupMemberships[member].length; i++) {
            if (groupMemberships[member][i] == groupID){
                place = i;
                break;
            }
        }

        // Swap the last entry with this one
        groupMemberships[member][place] = groupMemberships[member][groupMemberships[member].length-1];

        // Remove the last element
        groupMemberships[member].pop();

        // Emit to the logs for external reference
        emit logLeaveGroup(groupID, member);
    }


    /*

    CONTRACT CALL FUNCTIONS

    */

    // Update token ownership only callable from the Token contract overrides
    function onTransfer(address from, address to, uint256 tokenId) public onlyTrustedContracts nonReentrant {
        // If transferred to new owner
        if (from != address(0)){
            // Add new owner to mapping
            groupDetails[tokenId].ownerAddress = to;
            groupAddressToID[to] = tokenId;
            groupDetails[tokenId].groupAddress = to;
            removeMember(tokenId, from);
            addMember(tokenId, to);
        }

        // If Burned
        if (to == address(0)){
            // Remove old owner from mapping
            delete groupDetails[tokenId];

            // Reset the group address mapping
            delete groupAddressToID[to];
        }
    }

    function setInitialDetails(uint256 _groupID, address _owner, string memory groupName, address tokenContractAddress) public onlyTrustedContracts {
        // Make it so that we can only do this on mint
        require(groupDetails[_groupID].ownerAddress == address(0), "Can't edit existing group");

        // Set the owner
        groupDetails[_groupID].ownerAddress = _owner;

        // Set the owner as the first member of the group and add to member count
        isMemberOf[_owner][_groupID] = true;

        // Add to the group member count
        groupDetails[_groupID].members.push(_owner);

        // Set the group name
        groupDetails[_groupID].groupName = groupName;

        // Add the group to the owners list of memberships
        groupMemberships[_owner].push(_groupID);

        // Set the default colors for the NFT
        groupDetails[_groupID].colors[0] = 'ad81fc';
        groupDetails[_groupID].colors[1] = '8855d5';
        groupDetails[_groupID].colors[2] = '5e13d1';

        // Generate and store an address for the group
        address groupAddress = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp)))));
        groupAddressToID[groupAddress] = _groupID;
        groupDetails[_groupID].groupAddress = groupAddress;

        // Update the group profile to the initial details
        UserProfiles.setupNewGroup(groupAddress, groupName, _groupID, tokenContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGroupTokens {

    // Get a Group ID from a name
    function getGroupID(string calldata groupName) external view returns (uint256);

    // Check if a group is available to mint
    function isGroupAvailable(string calldata groupName) external view returns (bool);

    // Mint a new group
    function mintGroup(string calldata groupName) external payable;

    // Update the Group Token Metadata
    function adminUpdateGroupMetadata(uint256 groupID) external;
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