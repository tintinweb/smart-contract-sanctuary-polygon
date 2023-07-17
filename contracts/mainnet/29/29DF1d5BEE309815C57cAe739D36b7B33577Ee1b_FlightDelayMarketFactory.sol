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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFlightStatusOracle } from "./interfaces/IFlightStatusOracle.sol";
import { IProduct } from "./interfaces/IProduct.sol";
import { ITokensRepository } from "./interfaces/ITokensRepository.sol";
import { PredictionMarket } from "./PredictionMarket.sol";

contract FlightDelayMarket is PredictionMarket {
    event FlightCompleted(
        string indexed flightName,
        uint64 indexed departureDate,
        bytes1 status,
        uint32 delay
    );

    struct FlightInfo {
        string flightName;
        uint64 departureDate;
        uint32 delay;
    }

    struct Outcome {
        bytes1 status;
        uint32 delay;
    }

    FlightInfo private _flightInfo;
    Outcome private _outcome;

    function initialize(
        FlightInfo memory flightInfo_,
        Config memory config_,
        uint256 uniqueId_,
        bytes32 marketId_,
        ITokensRepository tokensRepo_,
        address payable feeCollector_,
        IProduct product_,
        address trustedForwarder_
    ) external initializer {
        __PredictionMarket_init(
            config_,
            uniqueId_,
            marketId_,
            tokensRepo_,
            feeCollector_,
            product_,
            trustedForwarder_
        );
        _flightInfo = flightInfo_;
    }

    function flightInfo() external view returns (FlightInfo memory) {
        return _flightInfo;
    }

    function outcome() external view returns (Outcome memory) {
        return _outcome;
    }

    function _trySettle() internal override {
        IFlightStatusOracle(_config.oracle).requestFlightStatus(
            _flightInfo.flightName,
            _flightInfo.departureDate,
            this.recordDecision.selector
        );
    }

    function _renderDecision(
        bytes calldata payload
    ) internal override returns (DecisionState state, Result result) {
        (bytes1 status, uint32 delay) = abi.decode(payload, (bytes1, uint32));

        if (status == "C") {
            // YES wins
            state = DecisionState.DECISION_RENDERED;
            result = Result.YES;
        } else if (status == "L") {
            state = DecisionState.DECISION_RENDERED;

            if (delay >= _flightInfo.delay) {
                // YES wins
                result = Result.YES;
            } else {
                // NO wins
                result = Result.NO;
            }
        } else {
            // not arrived yet
            // will have to reschedule the check
            state = DecisionState.DECISION_NEEDED;
            // TODO: also add a cooldown mechanism
        }

        if (state == DecisionState.DECISION_RENDERED) {
            _outcome = Outcome(status, delay);
            emit FlightCompleted(_flightInfo.flightName, _flightInfo.departureDate, status, delay);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ITokensRepository } from "./interfaces/ITokensRepository.sol";
import { IProduct } from "./interfaces/IProduct.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { RegistryMixin } from "./utils/RegistryMixin.sol";
import { PredictionMarket } from "./PredictionMarket.sol";
import { FlightDelayMarket } from "./FlightDelayMarket.sol";

contract FlightDelayMarketFactory is RegistryMixin {
    address private immutable implementation;

    constructor(IRegistry registry_) {
        _setRegistry(registry_);

        implementation = address(new FlightDelayMarket());
    }

    function createMarket(
        uint256 uniqueId,
        bytes32 marketId,
        PredictionMarket.Config calldata config,
        FlightDelayMarket.FlightInfo calldata flightInfo
    ) external onlyProduct returns (FlightDelayMarket) {
        FlightDelayMarket market = FlightDelayMarket(Clones.clone(implementation));
        market.initialize(
            flightInfo,
            config,
            uniqueId,
            marketId,
            ITokensRepository(_registry.getAddress(2)) /* tokens repo */,
            payable(_registry.getAddress(100)) /* fee collector */,
            IProduct(msg.sender),
            _registry.getAddress(101) /* trusted forwarder */
        );
        return market;
    }

    function getMarketId(
        string calldata flightName,
        uint64 departureDate,
        uint32 delay
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(flightName, departureDate, delay));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IFlightStatusOracle {
    function requestFlightStatus(
        string calldata flightName,
        uint64 departureDate,
        bytes4 callback
    ) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMarket {
    enum DecisionState {
        NO_DECISION,
        DECISION_NEEDED,
        DECISION_LOADING,
        DECISION_RENDERED
    }

    enum Result {
        UNDEFINED,
        YES,
        NO
    }

    enum Mode {
        BURN,
        BUYER
    }

    struct FinalBalance {
        uint256 bank;
        uint256 yes;
        uint256 no;
    }

    struct Config {
        uint64 cutoffTime;
        uint64 closingTime;
        uint256 lpBid;
        uint256 minBid;
        uint256 maxBid;
        uint16 initP;
        uint16 fee;
        Mode mode;
        address oracle;
    }

    function provideLiquidity() external payable returns (bool success);

    function product() external view returns (address);

    function marketId() external view returns (bytes32);

    function tokenIds() external view returns (uint256 tokenIdYes, uint256 tokenIdNo);

    function tokenBalances() external view returns (uint256 tokenBalanceYes, uint256 tokenBalanceNo);

    function finalBalance() external view returns (FinalBalance memory);

    function decisionState() external view returns (DecisionState);

    function config() external view returns (Config memory);

    function tvl() external view returns (uint256);

    function result() external view returns (Result);

    function currentDistribution() external view returns (uint256);

    function canBeSettled() external view returns (bool);

    function trySettle() external;

    function priceETHToYesNo(uint256 amountIn) external view returns (uint256, uint256);

    function priceETHForYesNoMarket(uint256 amountOut) external view returns (uint256, uint256);

    function priceETHForYesNo(
        uint256 amountOut,
        address account
    ) external view returns (uint256, uint256);

    function participate(bool betYes) external payable;

    function withdrawBet(uint256 amount, bool betYes) external;

    function claim() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IProduct {
    function getMarket(bytes32 marketId) external view returns (address);

    // hooks
    function onMarketLiquidity(bytes32 marketId, address provider, uint256 value) external;

    function onMarketParticipate(
        bytes32 marketId,
        address account,
        uint256 value,
        bool betYes,
        uint256 amount
    ) external;

    function onMarketWithdraw(
        bytes32 marketId,
        address account,
        uint256 amount,
        bool betYes,
        uint256 value
    ) external;

    function onMarketSettle(bytes32 marketId, bool yesWin, bytes calldata outcome) external;

    function onMarketClaim(bytes32 marketId, address account, uint256 value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRegistry {
    function getAddress(uint64 id) external view returns (address);

    function getId(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITokensRepository {
    function totalSupply(uint256 tokenId) external view returns (uint256);

    function mint(address to, uint256 tokenId, uint256 amount) external;

    function burn(address holder, uint256 tokenId, uint256 amount) external;

    function balanceOf(address holder, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { ITokensRepository } from "./interfaces/ITokensRepository.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { IProduct } from "./interfaces/IProduct.sol";

abstract contract PredictionMarket is IMarket, IERC165, ReentrancyGuard, ERC2771Context, Initializable {
    event DecisionRendered(Result result);
    event DecisionPostponed();
    event LiquidityProvided(address provider, uint256 amount);
    event ParticipatedInMarket(address indexed participant, uint256 amount, bool betYes);
    event BetWithdrawn(address indexed participant, uint256 amount, bool betYes);
    event RewardWithdrawn(address indexed participant, uint256 amount);

    bytes32 internal _marketId;
    uint256 internal _uniqueId;
    DecisionState internal _decisionState;
    Result internal _result;
    uint256 internal _ammConst;

    ITokensRepository internal _tokensRepo;
    FinalBalance internal _finalBalance;
    address payable internal _liquidityProvider;
    address payable internal _feeCollector;
    address private _createdBy;
    IProduct internal _product;

    Config internal _config;

    mapping(address => uint256) internal _bets;
    uint256 internal _tvl;

    uint256 private immutable _tokensBase = 10000;

    address private _trustedForwarder;

    constructor() ERC2771Context(address(0)) {}

    function __PredictionMarket_init(
        Config memory config_,
        uint256 uniqueId_,
        bytes32 marketId_,
        ITokensRepository tokensRepo_,
        address payable feeCollector_,
        IProduct product_,
        address trustedForwarder_
    ) internal onlyInitializing {
        _config = config_;
        _uniqueId = uniqueId_;
        _marketId = marketId_;
        _tokensRepo = tokensRepo_;
        _feeCollector = feeCollector_;
        _product = product_;
        _trustedForwarder = trustedForwarder_;

        _createdBy = msg.sender;
    }

    function product() external view returns (address) {
        return address(_product);
    }

    function marketId() external view returns (bytes32) {
        return _marketId;
    }

    function createdBy() external view returns (address) {
        return _createdBy;
    }

    function tokenSlots() external pure returns (uint8) {
        return 2;
    }

    function finalBalance() external view returns (FinalBalance memory) {
        return _finalBalance;
    }

    function decisionState() external view returns (DecisionState) {
        return _decisionState;
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function tvl() external view returns (uint256) {
        return _tvl;
    }

    function result() external view returns (Result) {
        return _result;
    }

    function tokenIds() external view returns (uint256 tokenIdYes, uint256 tokenIdNo) {
        tokenIdYes = _tokenIdYes();
        tokenIdNo = _tokenIdNo();
    }

    function tokenBalances() external view returns (uint256 tokenBalanceYes, uint256 tokenBalanceNo) {
        tokenBalanceYes = _tokensRepo.totalSupply(_tokenIdYes());
        tokenBalanceNo = _tokensRepo.totalSupply(_tokenIdNo());
    }

    /// @dev Returns the current distribution of tokens in the market. 2384 = 2.384%
    function currentDistribution() external view returns (uint256) {
        uint256 lpYes = _tokensRepo.balanceOf(_liquidityProvider, _tokenIdYes()); // 250
        uint256 lpNo = _tokensRepo.balanceOf(_liquidityProvider, _tokenIdNo()); // 10240

        uint256 lpTotal = lpYes + lpNo; // 10490
        return (lpNo * _tokensBase) / lpTotal; // 250 * 10000 / 10490 = 2384
    }

    function canBeSettled() external view returns (bool) {
        bool stateCheck = _decisionState == DecisionState.NO_DECISION ||
            _decisionState == DecisionState.DECISION_NEEDED;
        bool timeCheck = _config.closingTime < block.timestamp;
        return stateCheck && timeCheck;
    }

    function trySettle() external {
        require(block.timestamp > _config.cutoffTime, "Market is not closed yet");
        require(
            _decisionState == DecisionState.NO_DECISION ||
                _decisionState == DecisionState.DECISION_NEEDED,
            "Wrong market state"
        );

        _trySettle();

        _decisionState = DecisionState.DECISION_LOADING;

        _finalBalance = FinalBalance(
            _tvl,
            _tokensRepo.totalSupply(_tokenIdYes()),
            _tokensRepo.totalSupply(_tokenIdNo())
        );
    }

    function recordDecision(bytes calldata payload) external {
        require(msg.sender == address(_config.oracle), "Unauthorized sender");
        require(_decisionState == DecisionState.DECISION_LOADING, "Wrong state");

        (_decisionState, _result) = _renderDecision(payload);

        if (_decisionState == DecisionState.DECISION_RENDERED) {
            _claim(_liquidityProvider, true);
            emit DecisionRendered(_result);
            _product.onMarketSettle(_marketId, _result == Result.YES, payload);
        } else if (_decisionState == DecisionState.DECISION_NEEDED) {
            emit DecisionPostponed();
        }
    }

    function priceETHToYesNo(uint256 amountIn) external view returns (uint256, uint256) {
        // adjusts the fee
        amountIn -= _calculateFees(amountIn);

        return _priceETHToYesNo(amountIn);
    }

    function priceETHForYesNoMarket(uint256 amountOut) external view returns (uint256, uint256) {
        return _priceETHForYesNo(amountOut);
    }

    function priceETHForYesNo(
        uint256 amountOut,
        address account
    ) external view returns (uint256, uint256) {
        return _priceETHForYesNoWithdrawal(amountOut, account);
    }

    function priceETHForPayout(
        uint256 amountOut,
        address account,
        bool isYes
    ) external view returns (uint256) {
        return _priceETHForPayout(amountOut, account, isYes);
    }

    function provideLiquidity() external payable override returns (bool) {
        require(_liquidityProvider == address(0), "Already provided");
        require(msg.value == _config.lpBid, "Not enough to init");

        // it should be opposite for token types - initP indicates YES probability, but we mint NO tokens
        uint256 amountLPNo = (_tokensBase * (10 ** 18) * uint256(_config.initP)) / 10000;
        uint256 amountLPYes = (_tokensBase * (10 ** 18) * (10000 - uint256(_config.initP))) / 10000;

        // slither-disable-next-line divide-before-multiply
        _ammConst = amountLPYes * amountLPNo;
        _liquidityProvider = payable(msg.sender);
        _tvl += msg.value;

        _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), amountLPYes);
        _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), amountLPNo);

        emit LiquidityProvided(_liquidityProvider, msg.value);

        _product.onMarketLiquidity(_marketId, msg.sender, msg.value);

        return true;
    }

    function participate(bool betYes) external payable nonReentrant {
        // TODO: add slippage guard
        _beforeAddBet(_msgSender(), msg.value);
        _addBet(_msgSender(), betYes, msg.value);
    }

    function registerParticipant(address account, bool betYes) external payable nonReentrant {
        require(msg.sender == address(_product), "Unknown caller");

        _beforeAddBet(account, msg.value);
        _addBet(account, betYes, msg.value);
    }

    function withdrawBet(uint256 amount, bool betYes) external nonReentrant {
        require(_decisionState == DecisionState.NO_DECISION, "Wrong state");
        require(_config.cutoffTime > block.timestamp, "Market is closed");

        _withdrawBet(_msgSender(), betYes, amount);
    }

    function claim() external nonReentrant {
        require(_decisionState == DecisionState.DECISION_RENDERED);
        require(_result != Result.UNDEFINED);

        _claim(_msgSender(), false);
    }

    function _priceETHToYesNo(
        uint256 amountIn
    ) internal view returns (uint256 amountOutYes, uint256 amountOutNo) {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        amountOutYes = (amountIn * totalYes) / amountBank;
        amountOutNo = (amountIn * totalNo) / amountBank;
    }

    function _priceETHForYesNo(
        uint256 amountOut
    ) internal view returns (uint256 amountInYes, uint256 amountInNo) {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        amountInYes = (amountOut * amountBank) / totalYes;
        amountInNo = (amountOut * amountBank) / totalNo;
    }

    /**
     * Calculates the amount of ETH that needs to be sent to the contract to withdraw a given amount of YES/NO tokens
     * Compares existing market price with the price of the account's position (existing account's bank / account's YES/NO tokens)
     * The lesser of the two is used to calculate the amount of ETH that needs to be sent to the contract
     * @param amountOut - amount of YES/NO tokens to withdraw
     * @param account - account to withdraw from
     * @return amountInYes - amount of ETH to send to the contract for YES tokens
     * @return amountInNo - amount of ETH to send to the contract for NO tokens
     */
    function _priceETHForYesNoWithdrawal(
        uint256 amountOut,
        address account
    ) internal view returns (uint256 amountInYes, uint256 amountInNo) {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        uint256 marketAmountInYes = (amountOut * amountBank) / totalYes;
        uint256 marketAmountInNo = (amountOut * amountBank) / totalNo;

        uint256 accountBankAmount = _bets[account];
        uint256 accountTotalYes = _tokensRepo.balanceOf(account, _tokenIdYes());
        uint256 accountTotalNo = _tokensRepo.balanceOf(account, _tokenIdNo());

        uint256 accountAmountInYes = accountTotalYes == 0
            ? 0
            : (amountOut * accountBankAmount) / accountTotalYes;
        uint256 accountAmountInNo = accountTotalNo == 0
            ? 0
            : (amountOut * accountBankAmount) / accountTotalNo;

        amountInYes = marketAmountInYes > accountAmountInYes
            ? accountAmountInYes
            : marketAmountInYes;
        amountInNo = marketAmountInNo > accountAmountInNo ? accountAmountInNo : marketAmountInNo;
    }

    /**
     * Calculates the amount of ETH that could be paid out to the account if the market is resolved with a given result
     * and the account's position is YES/NO + amount of ETH sent to the contract
     * @param amountIn - amount of ETH potentially sent to the contract
     * @param account - account to calculate payout for or zero address if calculating for the new account (no wallet yet)
     * @param resultYes - potential result of the market
     */
    function _priceETHForPayout(
        uint256 amountIn,
        address account,
        bool resultYes
    ) internal view returns (uint256 payout) {
        // zero account addr check
        bool isAccountZero = account == address(0);
        // 1. Calculate the amount of ETH that the account has in the market + current total supply of YES/NO tokens
        uint256 accountTotalYes = isAccountZero ? 0 : _tokensRepo.balanceOf(account, _tokenIdYes());
        uint256 accountTotalNo = isAccountZero ? 0 : _tokensRepo.balanceOf(account, _tokenIdNo());

        uint256 amountLPYes = _tokensRepo.balanceOf(_liquidityProvider, _tokenIdYes());
        uint256 amountLPNo = _tokensRepo.balanceOf(_liquidityProvider, _tokenIdNo());

        uint256 finalYesSupply = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 finalNoSupply = _tokensRepo.totalSupply(_tokenIdNo());

        // 2. Adjust with the amount of fees that the account could paid
        amountIn -= _calculateFees(amountIn);

        // 3. Calculate the amount of ETH that the market could have + YES/NO tokens that the account could get for amountIn
        uint256 finalBankAmount = _tvl + amountIn;

        uint256 userPurchaseYes;
        uint256 userPurchaseNo;
        (userPurchaseYes, userPurchaseNo) = _priceETHToYesNo(amountIn);

        if (resultYes) {
            // 5. Calculate the amount of ETH that the account could get for the final YES tokens
            accountTotalYes += userPurchaseYes;
            finalYesSupply += userPurchaseYes;
            amountLPNo += userPurchaseNo;
            finalNoSupply += userPurchaseNo;

            uint256 toBurn;
            uint256 toMint;
            (toBurn, toMint) = _calculateLPBalanceChange(resultYes, amountLPYes, amountLPNo);
            finalYesSupply = toBurn > 0 ? finalYesSupply - toBurn : finalYesSupply + toMint;
            // to stimulate YES bets, we need to add the burned tokens back to the account and final supply
            if (toBurn > 0) {
                accountTotalYes += toBurn;
                finalYesSupply += toBurn;
            }
            payout = (accountTotalYes * finalBankAmount) / finalYesSupply;
        } else {
            // 5. Calculate the amount of ETH that the account could get for the final NO tokens
            accountTotalNo += userPurchaseNo;
            finalNoSupply += userPurchaseNo;
            amountLPYes += userPurchaseYes;
            finalYesSupply += userPurchaseYes;

            uint256 toBurn;
            uint256 toMint;
            (toBurn, toMint) = _calculateLPBalanceChange(resultYes, amountLPYes, amountLPNo);
            finalNoSupply = toBurn > 0 ? finalNoSupply - toBurn : finalNoSupply + toMint;
            // for buyer mode, we need to add the burned tokens back to the account and final supply
            if (toBurn > 0 && _config.mode == Mode.BUYER) {
                accountTotalNo += toBurn;
                finalNoSupply += toBurn;
            }
            payout = (accountTotalNo * finalBankAmount) / finalNoSupply;
        }
    }

    // slither-disable-next-line reentrancy-no-eth reentrancy-eth
    function _addBet(address account, bool betYes, uint256 value) internal {
        uint256 fee = _calculateFees(value);
        value -= fee;

        uint256 userPurchaseYes;
        uint256 userPurchaseNo;
        (userPurchaseYes, userPurchaseNo) = _priceETHToYesNo(value);

        // 4. Mint for user and for DFI
        // 5. Also balance out DFI
        uint256 userPurchase;
        if (betYes) {
            userPurchase = userPurchaseYes;
            _tokensRepo.mint(account, _tokenIdYes(), userPurchaseYes);
            _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), userPurchaseNo);
        } else {
            userPurchase = userPurchaseNo;
            _tokensRepo.mint(account, _tokenIdNo(), userPurchaseNo);
            _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), userPurchaseYes);
        }

        _balanceLPTokens(account, betYes, false);

        _bets[account] += value;
        _tvl += value;

        (bool sent, ) = _feeCollector.call{value: fee}("");
        require(sent, "Cannot distribute the fee");

        // Check in AMM product is the same
        // FIXME: will never be the same because of rounding
        // amountLPYes = balanceOf(address(_lpWallet), tokenIdYes);
        // amountLPNo = balanceOf(address(_lpWallet), tokenIdNo);
        // require(ammConst == amountDfiYes * amountDfiNo, "AMM const is wrong");

        emit ParticipatedInMarket(account, value, betYes);
        _product.onMarketParticipate(_marketId, account, value, betYes, userPurchase);
    }

    // slither-disable-next-line reentrancy-eth reentrancy-no-eth
    function _withdrawBet(address account, bool betYes, uint256 amount) internal {
        uint256 userRefundYes;
        uint256 userRefundNo;
        (userRefundYes, userRefundNo) = _priceETHForYesNoWithdrawal(amount, account);

        uint256 userRefund;
        if (betYes) {
            userRefund = userRefundYes;

            _tokensRepo.burn(account, _tokenIdYes(), amount);
        } else {
            userRefund = userRefundNo;

            _tokensRepo.burn(account, _tokenIdNo(), amount);
        }

        // 6. Check in AMM product is the same
        // FIXME: will never be the same because of rounding
        // amountLpYes = balanceOf(address(_lpWallet), tokenIdYes);
        // amountLpNo = balanceOf(address(_lpWallet), tokenIdNo);
        // require(ammConst == amountLpYes * amountLpNo, "AMM const is wrong");

        if (userRefund > _bets[account]) {
            _bets[account] = 0;
        } else {
            _bets[account] -= userRefund;
        }
        _tvl -= userRefund;

        // TODO: add a fee or something
        (bool sent, ) = payable(account).call{value: userRefund}("");
        require(sent, "Cannot withdraw");

        emit BetWithdrawn(account, userRefund, betYes);
        _product.onMarketWithdraw(_marketId, account, amount, betYes, userRefund);
    }

    function _balanceLPTokens(address account, bool fixYes, bool isWithdraw) internal {
        uint256 tokenIdYes = _tokenIdYes();
        uint256 tokenIdNo = _tokenIdNo();

        uint256 amountLPYes = _tokensRepo.balanceOf(_liquidityProvider, tokenIdYes);
        uint256 amountLPNo = _tokensRepo.balanceOf(_liquidityProvider, tokenIdNo);

        // Pre-calculate the amount of tokens to burn/mint for the LP balance
        uint256 toBurn;
        uint256 toMint;
        (toBurn, toMint) = _calculateLPBalanceChange(fixYes, amountLPYes, amountLPNo);

        if (fixYes) {
            if (toBurn > 0) {
                // to stimulate YES bets, we need to add the burned tokens back to the account and final supply
                if (!isWithdraw) {
                    _tokensRepo.burn(_liquidityProvider, tokenIdYes, toBurn);
                    _tokensRepo.mint(account, tokenIdYes, toBurn);
                } else {
                    _tokensRepo.burn(_liquidityProvider, tokenIdYes, toBurn);
                }
            } else {
                _tokensRepo.mint(_liquidityProvider, tokenIdYes, toMint);
            }
        } else {
            if (toBurn > 0) {
                if (_config.mode == Mode.BUYER && !isWithdraw) {
                    _tokensRepo.burn(_liquidityProvider, tokenIdNo, toBurn);
                    _tokensRepo.mint(account, tokenIdNo, toBurn);
                } else {
                    _tokensRepo.burn(_liquidityProvider, tokenIdNo, toBurn);
                }
            } else {
                _tokensRepo.mint(_liquidityProvider, tokenIdNo, toMint);
            }
        }
    }

    // slither-disable-next-line reentrancy-eth reentrancy-no-eth
    function _claim(address account, bool silent) internal {
        bool yesWins = _result == Result.YES;

        uint256 reward;
        // TODO: if Yes wins and you had NoTokens - it will never be burned
        if (yesWins) {
            uint256 balance = _tokensRepo.balanceOf(account, _tokenIdYes());
            if (!silent) {
                require(balance > 0, "Nothing to withdraw");
            }

            reward = (balance * _finalBalance.bank) / _finalBalance.yes;

            _tokensRepo.burn(account, _tokenIdYes(), balance);
        } else {
            uint256 balance = _tokensRepo.balanceOf(account, _tokenIdNo());
            if (!silent) {
                require(balance > 0, "Nothing to withdraw");
            }

            reward = (balance * _finalBalance.bank) / _finalBalance.no;

            _tokensRepo.burn(account, _tokenIdNo(), balance);
        }

        if (reward > 0) {
            (bool sent, ) = payable(account).call{value: reward}("");
            require(sent, "Cannot withdraw");

            emit RewardWithdrawn(account, reward);
            _product.onMarketClaim(_marketId, account, reward);
        }
    }

    /**
     * Based on the existing balances of the LP tokens, calculate the amount of tokens to burn OR mint
     * In order to keep the AMM constant stable
     * @param fixYes - if true, fix the Yes token, otherwise fix the No token
     * @param amountLPYes - actual amount of Yes tokens in the LP wallet
     * @param amountLPNo - actual amount of No tokens in the LP wallet
     * @return amountToBurn - amount of tokens to burn to fix the AMM
     * @return amountToMint - amount of tokens to mint to fix the AMM
     */
    function _calculateLPBalanceChange(
        bool fixYes,
        uint256 amountLPYes,
        uint256 amountLPNo
    ) internal view returns (uint256 amountToBurn, uint256 amountToMint) {
        if (fixYes) {
            uint256 newAmountYes = _ammConst / (amountLPNo);
            amountToBurn = amountLPYes > newAmountYes ? amountLPYes - newAmountYes : 0;
            amountToMint = amountLPYes > newAmountYes ? 0 : newAmountYes - amountLPYes;
            return (amountToBurn, amountToMint);
        } else {
            uint256 newAmountNo = _ammConst / (amountLPYes);
            amountToBurn = amountLPNo > newAmountNo ? amountLPNo - newAmountNo : 0;
            amountToMint = amountLPNo > newAmountNo ? 0 : newAmountNo - amountLPNo;
            return (amountToBurn, amountToMint);
        }
    }

    /**
     * Calculate the value of the fees to hold from the given amountIn
     * @param amount - amountIn from which to calculate the fees
     */
    function _calculateFees(uint256 amount) internal view returns (uint256) {
        return (amount * uint256(_config.fee)) / 10000;
    }

    function _tokenIdYes() internal view returns (uint256) {
        return _uniqueId;
    }

    function _tokenIdNo() internal view returns (uint256) {
        return _uniqueId + 1;
    }

    function _beforeAddBet(address account, uint256 amount) internal view virtual {
        require(_config.cutoffTime > block.timestamp, "Market is closed");
        require(_decisionState == DecisionState.NO_DECISION, "Wrong state");
        require(amount >= _config.minBid, "Value included is less than min-bid");

        uint256 balance = _bets[account];
        uint256 fee = _calculateFees(amount);
        require(balance + amount - fee <= _config.maxBid, "Exceeded max bid");
    }

    function _trySettle() internal virtual;

    function _renderDecision(bytes calldata) internal virtual returns (DecisionState, Result);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0xc79fd359 || interfaceId == type(IMarket).interfaceId;
    }

    function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
        return forwarder == _trustedForwarder;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IProduct.sol";
import "../interfaces/IRegistry.sol";

abstract contract RegistryMixin {
    IRegistry internal _registry;

    function isValidMarket(address operator) internal view returns (bool) {
        // check if it's even a market
        bool isMarket = IERC165(operator).supportsInterface(type(IMarket).interfaceId);
        require(isMarket);

        // get the product market claims it belongs to
        IMarket market = IMarket(operator);
        address productAddr = market.product();
        // check if the product is registered
        require(_registry.getId(productAddr) != 0, "Unknown product");

        // check that product has the market with the same address
        IProduct product = IProduct(productAddr);
        require(product.getMarket(market.marketId()) == operator, "Unknown market");

        return true;
    }

    modifier onlyMarket(address operator) {
        require(isValidMarket(operator));
        _;
    }

    modifier onlyMarketTokens(address operator, uint256 tokenId) {
        require(isValidMarket(operator));

        IMarket market = IMarket(operator);

        // check that market is modifying the tokens it controls
        (uint256 tokenIdYes, uint256 tokenIdNo) = market.tokenIds();
        require(tokenId == tokenIdYes || tokenId == tokenIdNo, "Wrong tokens");

        _;
    }

    modifier onlyMarketTokensMultiple(address operator, uint256[] calldata tokenIds) {
        require(isValidMarket(operator));

        IMarket market = IMarket(operator);

        // check that market is modifying the tokens it controls
        (uint256 tokenIdYes, uint256 tokenIdNo) = market.tokenIds();
        for (uint32 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] == tokenIdYes || tokenIds[i] == tokenIdNo, "Wrong tokens");
        }

        _;
    }

    modifier onlyProduct() {
        require(_registry.getId(msg.sender) != 0, "Unknown product");
        _;
    }

    function _setRegistry(IRegistry registry_) internal {
        _registry = registry_;
    }
}

abstract contract RegistryMixinUpgradeable is Initializable, RegistryMixin {
    function __RegistryMixin_init(IRegistry registry_) internal onlyInitializing {
        _setRegistry(registry_);
    }
}