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
pragma solidity >=0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoVersionsRegistry, IAvoFeeCollector } from "./interfaces/IAvoVersionsRegistry.sol";

abstract contract AvoVersionsRegistryConstants is IAvoVersionsRegistry {
    /// @notice  AvoFactory where new AvoWallet versions get registered automatically as newest version on registerAvoVersion calls
    IAvoFactory public immutable avoFactory;

    constructor(IAvoFactory avoFactory_) {
        avoFactory = avoFactory_;
    }
}

abstract contract AvoVersionsRegistryVariables is IAvoVersionsRegistry, Initializable, OwnableUpgradeable {
    /// @dev variables here start at storage slot 101, before is:
    /// - Initializable with storage slot 0:
    /// uint8 private _initialized;
    /// bool private _initializing;
    /// - OwnableUpgradeable with slots 1 to 100:
    /// uint256[50] private __gap; (from ContextUpgradeable, slot 1 until slot 50)
    /// address private _owner; (at slot 51)
    /// uint256[49] private __gap; (slot 52 until slot 100)

    // ---------------- slot 101 -----------------

    /// @notice fee config. Configurable by owner
    /// @dev address avoFactory used to be at this storage slot until incl. v2.0. Storage slot repurposed with upgrade v2.1
    FeeConfig public feeConfig;

    // ---------------- slot 102 -----------------

    /// @notice mapping to store allowed AvoWallet versions
    ///         modifiable by owner
    mapping(address => bool) public avoWalletVersions;

    // ---------------- slot 103 -----------------

    /// @notice mapping to store allowed AvoForwarder versions
    ///         modifiable by owner
    mapping(address => bool) public avoForwarderVersions;

    // ---------------- slot 104 -----------------

    /// @notice mapping to store allowed Avo Multisig versions
    ///         modifiable by owner
    mapping(address => bool) public avoMultisigVersions;
}

abstract contract AvoVersionsRegistryErrors {
    /// @notice thrown for requireVersion methods e.g. for AvoForwarder or AvoWallet
    error AvoVersionsRegistry__InvalidVersion();

    /// @notice thrown when a requested fee mode is not implemented
    error AvoVersionsRegistry__FeeModeNotImplemented(uint8 mode);

    /// @notice thrown when a method is called with invalid params
    error AvoVersionsRegistry__InvalidParams();
}

abstract contract AvoVersionsRegistryEvents is IAvoVersionsRegistry {
    /// @notice emitted when the status for a certain AvoWallet version is updated
    event SetAvoWalletVersion(address indexed avoWalletVersion, bool indexed allowed, bool indexed setDefault);

    /// @notice emitted when the status for a certain AvoWallet Multsig version is updated
    event SetAvoMultisigVersion(address indexed avoMultisigVersion, bool indexed allowed, bool indexed setDefault);

    /// @notice emitted when the status for a certain AvoForwarder version is updated
    event SetAvoForwarderVersion(address indexed avoForwarderVersion, bool indexed allowed);

    /// @notice emitted when owner updates the fee config
    event FeeConfigUpdated(address indexed feeCollector, uint8 indexed mode, uint88 indexed fee);
}

abstract contract AvoVersionsRegistryCore is
    AvoVersionsRegistryConstants,
    AvoVersionsRegistryVariables,
    AvoVersionsRegistryErrors,
    AvoVersionsRegistryEvents
{
    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice checks if an address is not 0x000...
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert AvoVersionsRegistry__InvalidParams();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(IAvoFactory avoFactory_) validAddress(address(avoFactory_)) AvoVersionsRegistryConstants(avoFactory_) {
        // ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }
}

abstract contract AvoFeeCollector is AvoVersionsRegistryCore {
    /// @inheritdoc IAvoFeeCollector
    function calcFee(uint256 gasUsed_) public view returns (uint256 feeAmount_, address payable feeCollector_) {
        FeeConfig memory feeConfig_ = feeConfig;

        if (feeConfig_.fee > 0) {
            if (feeConfig_.mode == 0) {
                // percentage of gasUsed fee amount mode
                if (gasUsed_ == 0) {
                    revert AvoVersionsRegistry__InvalidParams();
                }

                // fee amount = gasUsed * fee percentage
                feeAmount_ = (gasUsed_ * feeConfig_.fee) / 1e8; // 1e8 = 100%
            } else if (feeConfig_.mode == 1) {
                // absolute fee amount mode
                feeAmount_ = feeConfig_.fee;
            } else {
                // theoretically not reachable because of check in `updateFeeConfig` but doesn't hurt to have this here
                revert AvoVersionsRegistry__FeeModeNotImplemented(feeConfig_.mode);
            }
        }

        return (feeAmount_, feeConfig_.feeCollector);
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice sets `feeConfig_` as the new fee config in storage
    function updateFeeConfig(FeeConfig calldata feeConfig_) external onlyOwner validAddress(feeConfig_.feeCollector) {
        if (feeConfig_.mode > 1) {
            revert AvoVersionsRegistry__FeeModeNotImplemented(feeConfig_.mode);
        }

        feeConfig = feeConfig_;

        emit FeeConfigUpdated(feeConfig_.feeCollector, feeConfig_.mode, feeConfig_.fee);
    }
}

/// @title      AvoVersionsRegistry v3.0.0
/// @notice     Registry for various config data and general actions for Avo contracts:
///             - holds lists of valid versions for AvoWallet & AvoForwarder
///             - handles fees
/// @dev        Upgradeable through AvoVersionsRegistryProxy
contract AvoVersionsRegistry is AvoVersionsRegistryCore, AvoFeeCollector {
    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(IAvoFactory avoFactory_) AvoVersionsRegistryCore(avoFactory_) {}

    /// @notice initializes the contract with `owner_` as owner
    function initialize(address owner_) public initializer validAddress(owner_) {
        _transferOwnership(owner_);
    }

    /// @notice clears storage slot 101. up to v2.1.0 avoFactory address was at that slot, since v2.1.0 feeConfig
    function reinitialize() public reinitializer(2) {
        assembly {
            sstore(0x65, 0) // overwrite storage slot 101 completely
        }
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view {
        if (avoWalletVersions[avoWalletVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view {
        if (avoMultisigVersions[avoMultisigVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) public view {
        if (avoForwarderVersions[avoForwarderVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice                 sets the status for a certain address as valid AvoWallet version
    /// @param avoWallet_       the address of the contract to treat as AvoWallet version
    /// @param allowed_         flag to set this address as valid version (true) or not (false)
    /// @param setDefault_      flag to indicate whether this version should automatically be set as new
    ///                         default version for new deployments at the linked AvoFactory
    function setAvoWalletVersion(
        address avoWallet_,
        bool allowed_,
        bool setDefault_
    ) external onlyOwner validAddress(avoWallet_) {
        if (!allowed_ && setDefault_) {
            // can't be not allowed but supposed to be set as default
            revert AvoVersionsRegistry__InvalidParams();
        }

        avoWalletVersions[avoWallet_] = allowed_;

        if (setDefault_) {
            // register the new version as default version at the linked AvoFactory
            avoFactory.setAvoWalletImpl(avoWallet_);
        }

        emit SetAvoWalletVersion(avoWallet_, allowed_, setDefault_);
    }

    /// @notice                 sets the status for a certain address as valid AvoForwarder (proxy) version
    /// @param avoForwarder_    the address of the contract to treat as AvoForwarder version
    /// @param allowed_         flag to set this address as valid version (true) or not (false)
    function setAvoForwarderVersion(
        address avoForwarder_,
        bool allowed_
    ) external onlyOwner validAddress(avoForwarder_) {
        avoForwarderVersions[avoForwarder_] = allowed_;

        emit SetAvoForwarderVersion(avoForwarder_, allowed_);
    }

    /// @notice                 sets the status for a certain address as valid AvoMultisig version
    /// @param avoMultisig_     the address of the contract to treat as AvoMultisig version
    /// @param allowed_         flag to set this address as valid version (true) or not (false)
    /// @param setDefault_      flag to indicate whether this version should automatically be set as new
    ///                         default version for new deployments at the linked AvoFactory
    function setAvoMultisigVersion(
        address avoMultisig_,
        bool allowed_,
        bool setDefault_
    ) external onlyOwner validAddress(avoMultisig_) {
        if (!allowed_ && setDefault_) {
            // can't be not allowed but supposed to be set as default
            revert AvoVersionsRegistry__InvalidParams();
        }

        avoMultisigVersions[avoMultisig_] = allowed_;

        if (setDefault_) {
            // register the new version as default version at the linked AvoFactory
            avoFactory.setAvoMultisigImpl(avoMultisig_);
        }

        emit SetAvoMultisigVersion(avoMultisig_, allowed_, setDefault_);
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