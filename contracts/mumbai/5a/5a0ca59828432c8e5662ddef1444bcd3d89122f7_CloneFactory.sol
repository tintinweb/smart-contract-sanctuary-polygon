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
library ClonesUpgradeable {
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

// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "./Factory.sol";
import "./ICloneableV1.sol";
import "./ICloneFactoryV1.sol";
import "../interpreter/deploy/DeployerDiscoverableMetaV1.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// Thrown when an implementation is the zero address which is always a mistake.
error ZeroImplementation();

bytes32 constant CLONE_FACTORY_META_HASH = bytes32(
    0xae0fb5b68fe1791c72509bf46ea6abf6a982d21451265be0a017f7959712a67e
);

contract CloneFactory is ICloneableFactoryV1, DeployerDiscoverableMetaV1 {
    constructor(
        DeployerDiscoverableMetaV1ConstructionConfig memory config_
    ) DeployerDiscoverableMetaV1(CLONE_FACTORY_META_HASH, config_) {}

    /// @inheritdoc ICloneableFactoryV1
    function clone(
        address implementation_,
        bytes calldata data_
    ) external returns (address) {
        if (implementation_ == address(0)) {
            revert ZeroImplementation();
        }
        address clone_ = Clones.clone(implementation_);
        emit NewClone(msg.sender, implementation_, clone_);
        ICloneableV1(clone_).initialize(data_);
        return clone_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {IFactory} from "./IFactory.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// Thrown when a new factory deployment creates a child that was already created
/// by a previous deployment. This should never happen without some kind of
/// precompute such as CREATE2 and is generally unsupported at this time.
error DuplicateChild(address child);

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    /// @dev state to track each deployed contract address. A `Factory` will
    /// never lie about deploying a child, unless `isChild` is overridden to do
    /// so.
    mapping(address => bool) private contracts;

    constructor() {
        // Technically `ReentrancyGuard` is initializable but allowing it to be
        // initialized is a foot-gun as the status will be set to _NOT_ENTERED.
        // This would allow re-entrant behaviour upon initialization of the
        // `Factory` and is unnecessary as the reentrancy guard always restores
        // _NOT_ENTERED after every call anyway.
        _disableInitializers();
    }

    /// Implements `IFactory`.
    ///
    /// `_createChild` hook must be overridden to actually create child
    /// contract.
    ///
    /// Implementers may want to overload this function with a typed equivalent
    /// to expose domain specific structs etc. to the compiled ABI consumed by
    /// tooling and other scripts. To minimise gas costs for deployment it is
    /// expected that the tooling will consume the typed ABI, then encode the
    /// arguments and pass them to this function directly.
    ///
    /// @param data_ ABI encoded data to pass to child contract constructor.
    function _createChild(
        bytes memory data_
    ) internal virtual returns (address);

    /// Implements `IFactory`.
    ///
    /// Calls the `_createChild` hook that inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewChild` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(
        bytes memory data_
    ) public virtual override nonReentrant returns (address) {
        // Create child contract using hook.
        address child_ = _createChild(data_);

        // Ensure the child at this address has not previously been deployed.
        if (contracts[child_]) {
            revert DuplicateChild(child_);
        }

        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewChild` event with child contract address.
        emit IFactory.NewChild(msg.sender, child_);
        return child_;
    }

    /// Implements `IFactory`.
    ///
    /// Checks if address is registered as a child contract of this factory.
    ///
    /// @param maybeChild_ Address of child contract to look up.
    /// @return Returns `true` if address is a contract created by this
    /// contract factory, otherwise `false`.
    function isChild(
        address maybeChild_
    ) external view virtual override returns (bool) {
        return contracts[maybeChild_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

interface ICloneableV1 {
    function initialize(bytes calldata data) external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

interface ICloneableFactoryV1 {
    event NewClone(address sender, address implementation, address clone);

    /// Creates a new child contract.
    ///
    /// @param data As per `ICloneableV1`.
    /// @return New child contract address.
    function clone(
        address implementation,
        bytes calldata data
    ) external returns (address);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewChild` event
    /// containing the new child contract address MUST be emitted.
    /// @param sender `msg.sender` that deployed the contract (factory).
    /// @param child address of the newly deployed child.
    event NewChild(address sender, address child);

    /// Factories that clone a template contract MUST emit an event any time
    /// they set the implementation being cloned. Factories that deploy new
    /// contracts without cloning do NOT need to emit this.
    /// @param sender `msg.sender` that deployed the implementation (factory).
    /// @param implementation address of the implementation contract that will
    /// be used for future clones if relevant.
    event Implementation(address sender, address implementation);

    /// Creates a new child contract.
    ///
    /// @param data_ Domain specific data for the child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_) external returns (address);

    /// Checks if address is registered as a child contract of this factory.
    ///
    /// Addresses that were not deployed by `createChild` MUST NOT return
    /// `true` from `isChild`. This is CRITICAL to the security guarantees for
    /// any contract implementing `IFactory`.
    ///
    /// @param maybeChild_ Address to check registration for.
    /// @return `true` if address was deployed by this contract factory,
    /// otherwise `false`.
    function isChild(address maybeChild_) external view returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "sol.metadata/IMetaV1.sol";
import "sol.metadata/LibMeta.sol";
import "./LibDeployerDiscoverable.sol";

struct DeployerDiscoverableMetaV1ConstructionConfig {
    address deployer;
    bytes meta;
}

/// @title DeployerDiscoverableMetaV1
/// @notice Checks metadata against a known hash, emits it then touches the
/// deployer (deploy an empty expression). This allows indexers to discover the
/// metadata of the `DeployerDiscoverableMetaV1` contract by indexing the
/// deployer. In this way the deployer acts as a pseudo-registry by virtue of it
/// being a natural hub for interactions.
abstract contract DeployerDiscoverableMetaV1 is IMetaV1 {
    constructor(
        bytes32 metaHash_,
        DeployerDiscoverableMetaV1ConstructionConfig memory config_
    ) {
        LibMeta.checkMetaHashed(metaHash_, config_.meta);
        emit MetaV1(msg.sender, uint256(uint160(address(this))), config_.meta);
        LibDeployerDiscoverable.touchDeployer(config_.deployer);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.17;

import "../run/IInterpreterV1.sol";

/// @title IExpressionDeployerV1
/// @notice Companion to `IInterpreterV1` responsible for onchain static code
/// analysis and deploying expressions. Each `IExpressionDeployerV1` is tightly
/// coupled at the bytecode level to some interpreter that it knows how to
/// analyse and deploy expressions for. The expression deployer can perform an
/// integrity check "dry run" of candidate source code for the intepreter. The
/// critical analysis/transformation includes:
///
/// - Enforcement of no out of bounds memory reads/writes
/// - Calculation of memory required to eval the stack with a single allocation
/// - Replacing index based opcodes with absolute interpreter function pointers
/// - Enforcement that all opcodes and operands used exist and are valid
///
/// This analysis is highly sensitive to the specific implementation and position
/// of all opcodes and function pointers as compiled into the interpreter. This
/// is what makes the coupling between an interpreter and expression deployer
/// so tight. Ideally all responsibilities would be handled by a single contract
/// but this introduces code size issues quickly by roughly doubling the compiled
/// logic of each opcode (half for the integrity check and half for evaluation).
///
/// Interpreters MUST assume that expression deployers are malicious and fail
/// gracefully if the integrity check is corrupt/bypassed and/or function
/// pointers are incorrect, etc. i.e. the interpreter MUST always return a stack
/// from `eval` in a read only way or error. I.e. it is the expression deployer's
/// responsibility to do everything it can to prevent undefined behaviour in the
/// interpreter, and the interpreter's responsibility to handle the expression
/// deployer completely failing to do so.
interface IExpressionDeployerV1 {
    /// This is the literal InterpreterOpMeta bytes to be used offchain to make
    /// sense of the opcodes in this interpreter deployment, as a human. For
    /// formats like json that make heavy use of boilerplate, repetition and
    /// whitespace, some kind of compression is recommended.
    /// @param sender The `msg.sender` providing the op meta.
    /// @param opMeta The raw binary data of the op meta. Maybe compressed data
    /// etc. and is intended for offchain consumption.
    event DISpair(
        address sender,
        address deployer,
        address interpreter,
        address store,
        bytes opMeta
    );

    /// Expressions are expected to be deployed onchain as immutable contract
    /// code with a first class address like any other contract or account.
    /// Technically this is optional in the sense that all the tools required to
    /// eval some expression and define all its opcodes are available as
    /// libraries.
    ///
    /// In practise there are enough advantages to deploying the sources directly
    /// onchain as contract data and loading them from the interpreter at eval:
    ///
    /// - Loading and storing binary data is gas efficient as immutable contract
    ///   data
    /// - Expressions need to be immutable between their deploy time integrity
    ///   check and runtime evaluation
    /// - Passing the address of an expression through calldata to an interpreter
    ///   is cheaper than passing an entire expression through calldata
    /// - Conceptually a very simple approach, even if implementations like
    ///   SSTORE2 are subtle under the hood
    ///
    /// The expression deployer MUST perform an integrity check of the source
    /// code before it puts the expression onchain at a known address. The
    /// integrity check MUST at a minimum (it is free to do additional static
    /// analysis) calculate the memory required to be allocated for the stack in
    /// total, and that no out of bounds memory reads/writes occur within this
    /// stack. A simple example of an invalid source would be one that pushes one
    /// value to the stack then attempts to pops two values, clearly we cannot
    /// remove more values than we added. The `IExpressionDeployerV1` MUST revert
    /// in the case of any integrity failure, all integrity checks MUST pass in
    /// order for the deployment to complete.
    ///
    /// Once the integrity check is complete the `IExpressionDeployerV1` MUST do
    /// any additional processing required by its paired interpreter.
    /// For example, the `IExpressionDeployerV1` MAY NEED to replace the indexed
    /// opcodes in the `ExpressionConfig` sources with real function pointers
    /// from the corresponding interpreter.
    ///
    /// @param sources Sources verbatim. These sources MUST be provided in their
    /// sequential/index opcode form as the deployment process will need to index
    /// into BOTH the integrity check and the final runtime function pointers.
    /// This will be emitted in an event for offchain processing to use the
    /// indexed opcode sources. The first N sources are considered entrypoints
    /// and will be integrity checked by the expression deployer against a
    /// starting stack height of 0. Non-entrypoint sources MAY be provided for
    /// internal use such as the `call` opcode but will NOT be integrity checked
    /// UNLESS entered by an opcode in an entrypoint.
    /// @param constants Constants verbatim. Constants are provided alongside
    /// sources rather than inline as it allows us to avoid variable length
    /// opcodes and can be more memory efficient if the same constant is
    /// referenced several times from the sources.
    /// @param minOutputs The first N sources on the state config are entrypoints
    /// to the expression where N is the length of the `minOutputs` array. Each
    /// item in the `minOutputs` array specifies the number of outputs that MUST
    /// be present on the final stack for an evaluation of each entrypoint. The
    /// minimum output for some entrypoint MAY be zero if the expectation is that
    /// the expression only applies checks and error logic. Non-entrypoint
    /// sources MUST NOT have a minimum outputs length specified.
    /// @return interpreter The interpreter the deployer believes it is qualified
    /// to perform integrity checks on behalf of.
    /// @return store The interpreter store the deployer believes is compatible
    /// with the interpreter.
    /// @return expression The address of the deployed onchain expression. MUST
    /// be valid according to all integrity checks the deployer is aware of.
    function deployExpression(
        bytes[] memory sources,
        uint256[] memory constants,
        uint256[] memory minOutputs
    )
        external
        returns (
            IInterpreterV1 interpreter,
            IInterpreterStoreV1 store,
            address expression
        );
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.17;

import "./IExpressionDeployerV1.sol";

library LibDeployerDiscoverable {
    /// Hack so that some deployer will emit an event with the sender as the
    /// caller of `touchDeployer`. This MAY be needed by indexers such as
    /// subgraph that can only index events from the first moment they are aware
    /// of some contract. The deployer MUST be registered in ERC1820 registry
    /// before it is touched, THEN the caller meta MUST be emitted after the
    /// deployer is touched. This allows indexers such as subgraph to index the
    /// deployer, then see the caller, then see the caller's meta emitted in the
    /// same transaction.
    /// This is NOT required if ANY other expression is deployed in the same
    /// transaction as the caller meta, there only needs to be one expression on
    /// ANY deployer known to ERC1820.
    function touchDeployer(address deployer_) internal {
        IExpressionDeployerV1(deployer_).deployExpression(
            new bytes[](0),
            new uint256[](0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import "../store/IInterpreterStoreV1.sol";

/// @dev The index of a source within a deployed expression that can be evaluated
/// by an `IInterpreterV1`. MAY be an entrypoint or the index of a source called
/// internally such as by the `call` opcode.
type SourceIndex is uint256;
/// @dev Encoded information about a specific evaluation including the expression
/// address onchain, entrypoint and expected return values.
type EncodedDispatch is uint256;
/// @dev The namespace for state changes as requested by the calling contract.
/// The interpreter MUST apply this namespace IN ADDITION to namespacing by
/// caller etc.
type StateNamespace is uint256;
/// @dev Additional bytes that can be used to configure a single opcode dispatch.
/// Commonly used to specify the number of inputs to a variadic function such
/// as addition or multiplication.
type Operand is uint256;

/// @dev The default state namespace MUST be used when a calling contract has no
/// particular opinion on or need for dynamic namespaces.
StateNamespace constant DEFAULT_STATE_NAMESPACE = StateNamespace.wrap(0);

/// @title IInterpreterV1
/// Interface into a standard interpreter that supports:
///
/// - evaluating `view` logic deployed onchain by an `IExpressionDeployerV1`
/// - receiving arbitrary `uint256[][]` supporting context to be made available
///   to the evaluated logic
/// - handling subsequent state changes in bulk in response to evaluated logic
/// - namespacing state changes according to the caller's preferences to avoid
///   unwanted key collisions
/// - exposing its internal function pointers to support external precompilation
///   of logic for more gas efficient runtime evaluation by the interpreter
///
/// The interface is designed to be stable across many versions and
/// implementations of an interpreter, balancing minimalism with features
/// required for a general purpose onchain interpreted compute environment.
///
/// The security model of an interpreter is that it MUST be resilient to
/// malicious expressions even if they dispatch arbitrary internal function
/// pointers during an eval. The interpreter MAY return garbage or exhibit
/// undefined behaviour or error during an eval, _provided that no state changes
/// are persisted_ e.g. in storage, such that only the caller that specifies the
/// malicious expression can be negatively impacted by the result. In turn, the
/// caller must guard itself against arbitrarily corrupt/malicious reverts and
/// return values from any interpreter that it requests an expression from. And
/// so on and so forth up to the externally owned account (EOA) who signs the
/// transaction and agrees to a specific combination of contracts, expressions
/// and interpreters, who can presumably make an informed decision about which
/// ones to trust to get the job done.
///
/// The state changes for an interpreter are expected to be produces by an `eval`
/// and passed to the `IInterpreterStoreV1` returned by the eval, as-is by the
/// caller, after the caller has had an opportunity to apply their own
/// intermediate logic such as reentrancy defenses against malicious
/// interpreters. The interpreter is free to structure the state changes however
/// it wants but MUST guard against the calling contract corrupting the changes
/// between `eval` and `set`. For example a store could sandbox storage writes
/// per-caller so that a malicious caller can only damage their own state
/// changes, while honest callers respect, benefit from and are protected by the
/// interpreter store's state change handling.
///
/// The two step eval-state model allows eval to be read-only which provides
/// security guarantees for the caller such as no stateful reentrancy, either
/// from the interpreter or some contract interface used by some word, while
/// still allowing for storage writes. As the storage writes happen on the
/// interpreter rather than the caller (c.f. delegate call) the caller DOES NOT
/// need to trust the interpreter, which allows for permissionless selection of
/// interpreters by end users. Delegate call always implies an admin key on the
/// caller because the delegatee contract can write arbitrarily to the state of
/// the delegator, which severely limits the generality of contract composition.
interface IInterpreterV1 {
    /// Exposes the function pointers as `uint16` values packed into a single
    /// `bytes` in the same order as they would be indexed into by opcodes. For
    /// example, if opcode `2` should dispatch function at position `0x1234` then
    /// the start of the returned bytes would be `0xXXXXXXXX1234` where `X` is
    /// a placeholder for the function pointers of opcodes `0` and `1`.
    ///
    /// `IExpressionDeployerV1` contracts use these function pointers to
    /// "compile" the expression into something that an interpreter can dispatch
    /// directly without paying gas to lookup the same at runtime. As the
    /// validity of any integrity check and subsequent dispatch is highly
    /// sensitive to both the function pointers and overall bytecode of the
    /// interpreter, `IExpressionDeployerV1` contracts SHOULD implement guards
    /// against accidentally being deployed onchain paired against an unknown
    /// interpreter. It is very easy for an apparent compatible pairing to be
    /// subtly and critically incompatible due to addition/removal/reordering of
    /// opcodes and compiler optimisations on the interpreter bytecode.
    ///
    /// This MAY return different values during construction vs. all other times
    /// after the interpreter has been successfully deployed onchain. DO NOT rely
    /// on function pointers reported during contract construction.
    function functionPointers() external view returns (bytes memory);

    /// The raison d'etre for an interpreter. Given some expression and per-call
    /// additional contextual data, produce a stack of results and a set of state
    /// changes that the caller MAY OPTIONALLY pass back to be persisted by a
    /// call to `IInterpreterStoreV1.set`.
    /// @param store The storage contract that the returned key/value pairs
    /// MUST be passed to IF the calling contract is in a non-static calling
    /// context. Static calling contexts MUST pass `address(0)`.
    /// @param namespace The state namespace that will be fully qualified by the
    /// interpreter at runtime in order to perform gets on the underlying store.
    /// MUST be the same namespace passed to the store by the calling contract
    /// when sending the resulting key/value items to storage.
    /// @param dispatch All the information required for the interpreter to load
    /// an expression, select an entrypoint and return the values expected by the
    /// caller. The interpreter MAY encode dispatches differently to
    /// `LibEncodedDispatch` but this WILL negatively impact compatibility for
    /// calling contracts that hardcode the encoding logic.
    /// @param context A 2-dimensional array of data that can be indexed into at
    /// runtime by the interpreter. The calling contract is responsible for
    /// ensuring the authenticity and completeness of context data. The
    /// interpreter MUST revert at runtime if an expression attempts to index
    /// into some context value that is not provided by the caller. This implies
    /// that context reads cannot be checked for out of bounds reads at deploy
    /// time, as the runtime context MAY be provided in a different shape to what
    /// the expression is expecting.
    /// Same as `eval` but allowing the caller to specify a namespace under which
    /// the state changes will be applied. The interpeter MUST ensure that keys
    /// will never collide across namespaces, even if, for example:
    ///
    /// - The calling contract is malicious and attempts to craft a collision
    ///   with state changes from another contract
    /// - The expression is malicious and attempts to craft a collision with
    ///   other expressions evaluated by the same calling contract
    ///
    /// A malicious entity MAY have access to significant offchain resources to
    /// attempt to precompute key collisions through brute force. The collision
    /// resistance of namespaces should be comparable or equivalent to the
    /// collision resistance of the hashing algorithms employed by the blockchain
    /// itself, such as the design of `mapping` in Solidity that hashes each
    /// nested key to produce a collision resistant compound key.
    /// @return stack The list of values produced by evaluating the expression.
    /// MUST NOT be longer than the maximum length specified by `dispatch`, if
    /// applicable.
    /// @return kvs A list of pairwise key/value items to be saved in the store.
    function eval(
        IInterpreterStoreV1 store,
        StateNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context
    ) external view returns (uint256[] memory stack, uint256[] memory kvs);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import "../run/IInterpreterV1.sol";

/// A fully qualified namespace includes the interpreter's own namespacing logic
/// IN ADDITION to the calling contract's requested `StateNamespace`. Typically
/// this involves hashing the `msg.sender` into the `StateNamespace` so that each
/// caller operates within its own disjoint state universe. Intepreters MUST NOT
/// allow either the caller nor any expression/word to modify this directly on
/// pain of potential key collisions on writes to the interpreter's own storage.
type FullyQualifiedNamespace is uint256;

IInterpreterStoreV1 constant NO_STORE = IInterpreterStoreV1(address(0));

/// @title IInterpreterStoreV1
/// @notice Tracks state changes on behalf of an interpreter. A single store can
/// handle state changes for many calling contracts, many interpreters and many
/// expressions. The store is responsible for ensuring that applying these state
/// changes is safe from key collisions with calls to `set` from different
/// `msg.sender` callers. I.e. it MUST NOT be possible for a caller to modify the
/// state changes associated with some other caller.
///
/// The store defines the shape of its own state changes, which is opaque to the
/// calling contract. For example, some store may treat the list of state changes
/// as a pairwise key/value set, and some other store may treat it as a literal
/// list to be stored as-is.
///
/// Each interpreter decides for itself which store to use based on the
/// compatibility of its own opcodes.
///
/// The store MUST assume the state changes have been corrupted by the calling
/// contract due to bugs or malicious intent, and enforce state isolation between
/// callers despite arbitrarily invalid state changes. The store MUST revert if
/// it can detect invalid state changes, such as a key/value list having an odd
/// number of items, but this MAY NOT be possible if the corruption is
/// undetectable.
interface IInterpreterStoreV1 {
    /// Mutates the interpreter store in bulk. The bulk values are provided in
    /// the form of a `uint256[]` which can be treated e.g. as pairwise keys and
    /// values to be stored in a Solidity mapping. The `IInterpreterStoreV1`
    /// defines the meaning of the `uint256[]` for its own storage logic.
    ///
    /// @param namespace The unqualified namespace for the set that MUST be
    /// fully qualified by the `IInterpreterStoreV1` to prevent key collisions
    /// between callers. The fully qualified namespace forms a compound key with
    /// the keys for each value to set.
    /// @param kvs The list of changes to apply to the store's internal state.
    function set(StateNamespace namespace, uint256[] calldata kvs) external;

    /// Given a fully qualified namespace and key, return the associated value.
    /// Ostensibly the interpreter can use this to implement opcodes that read
    /// previously set values. The interpreter MUST apply the same qualification
    /// logic as the store that it uses to guarantee consistent round tripping of
    /// data and prevent malicious behaviours. Technically also allows onchain
    /// reads of any set value from any contract, not just interpreters, but in
    /// this case readers MUST be aware and handle inconsistencies between get
    /// and set while the state changes are still in memory in the calling
    /// context and haven't yet been persisted to the store.
    ///
    /// `IInterpreterStoreV1` uses the same fallback behaviour for unset keys as
    /// Solidity. Specifically, any UNSET VALUES SILENTLY FALLBACK TO `0`.
    /// @param namespace The fully qualified namespace to get a single value for.
    /// @param key The key to get the value for within the namespace.
    /// @return The value OR ZERO IF NOT SET.
    function get(
        FullyQualifiedNamespace namespace,
        uint256 key
    ) external view returns (uint256);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Thrown when hashed metadata does NOT match the expected hash.
/// @param expectedHash The hash expected by the `IMetaV1` contract.
/// @param actualHash The hash of the metadata seen by the `IMetaV1` contract.
error UnexpectedMetaHash(bytes32 expectedHash, bytes32 actualHash);

/// Thrown when some bytes are expected to be rain meta and are not.
/// @param unmeta the bytes that are not meta.
error NotRainMetaV1(bytes unmeta);

/// @dev Randomly generated magic number with first bytes oned out.
/// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
uint64 constant META_MAGIC_NUMBER_V1 = 0xff0a89c674ee7874;

/// @title IMetaV1
interface IMetaV1 {
    /// An onchain wrapper to carry arbitrary Rain metadata. Assigns the sender
    /// to the metadata so that tooling can easily drop/ignore data from unknown
    /// sources. As metadata is about something, the subject MUST be provided.
    /// @param sender The msg.sender.
    /// @param subject The entity that the metadata is about. MAY be the address
    /// of the emitting contract (as `uint256`) OR anything else. The
    /// interpretation of the subject is context specific, so will often be a
    /// hash of some data/thing that this metadata is about.
    /// @param meta Rain metadata V1 compliant metadata bytes.
    /// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
    event MetaV1(address sender, uint256 subject, bytes meta);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./IMetaV1.sol";

/// @title LibMeta
/// @notice Need a place to put data that can be handled offchain like ABIs that
/// IS NOT etherscan.
library LibMeta {
    /// Returns true if the metadata bytes are prefixed by the Rain meta magic
    /// number. DOES NOT attempt to validate the body of the metadata as offchain
    /// tooling will be required for this.
    /// @param meta_ The data that may be rain metadata.
    /// @return True if `meta_` is metadata, false otherwise.
    function isRainMetaV1(bytes memory meta_) internal pure returns (bool) {
        if (meta_.length < 8) return false;
        uint256 mask_ = type(uint64).max;
        uint256 magicNumber_ = META_MAGIC_NUMBER_V1;
        assembly ("memory-safe") {
            magicNumber_ := and(mload(add(meta_, 8)), mask_)
        }
        return magicNumber_ == META_MAGIC_NUMBER_V1;
    }

    /// Reverts if the provided `meta_` is NOT metadata according to
    /// `isRainMetaV1`.
    /// @param meta_ The metadata bytes to check.
    function checkMetaUnhashed(bytes memory meta_) internal pure {
        if (!isRainMetaV1(meta_)) {
            revert NotRainMetaV1(meta_);
        }
    }

    /// Reverts if the provided `meta_` is NOT metadata according to
    /// `isRainMetaV1` OR it does not match the expected hash of its data.
    /// @param meta_ The metadata to check.
    function checkMetaHashed(bytes32 expectedHash_, bytes memory meta_) internal pure {
        bytes32 actualHash_ = keccak256(meta_);
        if (expectedHash_ != actualHash_) {
            revert UnexpectedMetaHash(expectedHash_, actualHash_);
        }
        checkMetaUnhashed(meta_);
    }
}