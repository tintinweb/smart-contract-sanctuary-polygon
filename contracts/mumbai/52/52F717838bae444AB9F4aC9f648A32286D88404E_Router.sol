// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// Modifications by @stevieraykatz to make compatible with OZ Upgradable Proxy

pragma solidity >=0.8.8;

import {IVault} from "../core/vault/interfaces/IVault.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AxelarExecutable is IAxelarExecutable, Initializable {
  IAxelarGateway public gateway;

  // We want this to be intializeable by an OZ upgradable pattern so move the constructor logic to _init_ methods
  function __AxelarExecutable_init(address gateway_) internal onlyInitializing {
    __AxelarExecutable_init_unchained(gateway_);
  }

  function __AxelarExecutable_init_unchained(address gateway_) internal onlyInitializing {
    if (gateway_ == address(0)) revert InvalidAddress();
    gateway = IAxelarGateway(gateway_);
  }

  function execute(
    bytes32 commandId,
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) public virtual override {
    bytes32 payloadHash = keccak256(payload);
    if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
      revert NotApprovedByGateway();
    _execute(sourceChain, sourceAddress, payload);
  }

  function executeWithToken(
    bytes32 commandId,
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) public virtual override {
    bytes32 payloadHash = keccak256(payload);
    if (
      !gateway.validateContractCallAndMint(
        commandId,
        sourceChain,
        sourceAddress,
        payloadHash,
        tokenSymbol,
        amount
      )
    ) revert NotApprovedByGateway();

    _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
  }

  function _execute(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) internal virtual returns (IVault.VaultActionData memory) {}

  function _executeWithToken(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) internal virtual returns (IVault.VaultActionData memory) {}
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IVault} from "../../vault/interfaces/IVault.sol";
import {LocalRegistrarLib} from "../lib/LocalRegistrarLib.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface ILocalRegistrar {
  /*////////////////////////////////////////////////
                        EVENTS
    */ ////////////////////////////////////////////////
  event RebalanceParamsChanged(LocalRegistrarLib.RebalanceParams _newRebalanceParams);
  event AngelProtocolParamsChanged(LocalRegistrarLib.AngelProtocolParams _newAngelProtocolParams);
  event AccountsContractStorageChanged(
    string indexed _chainName,
    string indexed _accountsContractAddress
  );
  event TokenAcceptanceChanged(address indexed _tokenAddr, bool _isAccepted);
  event StrategyApprovalChanged(
    bytes4 indexed _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event StrategyParamsChanged(
    bytes4 indexed _strategyId,
    address indexed _lockAddr,
    address indexed _liqAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event GasFeeUpdated(address indexed _tokenAddr, uint256 _gasFee);
  event FeeUpdated(AngelCoreStruct.FeeTypes _fee, uint256 _rate, address _payout);

  /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */ ////////////////////////////////////////////////

  // View methods for returning stored params
  function getRebalanceParams() external view returns (LocalRegistrarLib.RebalanceParams memory);

  function getAngelProtocolParams()
    external
    view
    returns (LocalRegistrarLib.AngelProtocolParams memory);

  function getAccountsContractAddressByChain(
    string calldata _targetChain
  ) external view returns (string memory);

  function getStrategyParamsById(
    bytes4 _strategyId
  ) external view returns (LocalRegistrarLib.StrategyParams memory);

  function isTokenAccepted(address _tokenAddr) external view returns (bool);

  function getGasByToken(address _tokenAddr) external view returns (uint256);

  function getStrategyApprovalState(
    bytes4 _strategyId
  ) external view returns (LocalRegistrarLib.StrategyApprovalState);

  function getFeeSettingsByFeeType(
    AngelCoreStruct.FeeTypes _feeType
  ) external view returns (AngelCoreStruct.FeeSetting memory);

  function getVaultOperatorApproved(address _operator) external view returns (bool);

  // Setter methods for granular changes to specific params
  function setRebalanceParams(LocalRegistrarLib.RebalanceParams calldata _rebalanceParams) external;

  function setAngelProtocolParams(
    LocalRegistrarLib.AngelProtocolParams calldata _angelProtocolParams
  ) external;

  function setAccountsContractAddressByChain(
    string memory _chainName,
    string memory _accountsContractAddress
  ) external;

  /// @notice Change whether a strategy is approved
  /// @dev Set the approval bool for a specified strategyId.
  /// @param _strategyId a uid for each strategy set by:
  /// bytes4(keccak256("StrategyName"))
  function setStrategyApprovalState(
    bytes4 _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  ) external;

  /// @notice Change which pair of vault addresses a strategy points to
  /// @dev Set the approval bool and both locked/liq vault addrs for a specified strategyId.
  /// @param _strategyId a uid for each strategy set by:
  /// bytes4(keccak256("StrategyName"))
  /// @param _liqAddr address to a comptaible Liquid type Vault
  /// @param _lockAddr address to a compatible Locked type Vault
  function setStrategyParams(
    bytes4 _strategyId,
    address _liqAddr,
    address _lockAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  ) external;

  function setTokenAccepted(address _tokenAddr, bool _isAccepted) external;

  function setGasByToken(address _tokenAddr, uint256 _gasFee) external;

  function setFeeSettingsByFeesType(
    AngelCoreStruct.FeeTypes _feeType,
    uint256 _rate,
    address _payout
  ) external;

  function setVaultOperatorApproved(address _operator, bool _isApproved) external;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IVault} from "../../vault/interfaces/IVault.sol";
import {AngelCoreStruct} from "../../struct.sol";

library LocalRegistrarLib {
  /*////////////////////////////////////////////////
                      DEPLOYMENT DEFAULTS
  */ ////////////////////////////////////////////////
  bool constant REBALANCE_LIQUID_PROFITS = false;
  uint32 constant LOCKED_REBALANCE_TO_LIQUID = 75; // 75%
  uint32 constant INTEREST_DISTRIBUTION = 20; // 20%
  bool constant LOCKED_PRINCIPLE_TO_LIQUID = false;
  uint32 constant PRINCIPLE_DISTRIBUTION = 0;
  uint32 constant BASIS = 100;

  // DEFAULT ANGEL PROTOCOL PARAMS
  address constant ROUTER_ADDRESS = address(0);
  address constant REFUND_ADDRESS = address(0);

  /*////////////////////////////////////////////////
                      CUSTOM TYPES
  */ ////////////////////////////////////////////////
  struct RebalanceParams {
    bool rebalanceLiquidProfits;
    uint32 lockedRebalanceToLiquid;
    uint32 interestDistribution;
    bool lockedPrincipleToLiquid;
    uint32 principleDistribution;
    uint32 basis;
  }

  struct AngelProtocolParams {
    address routerAddr;
    address refundAddr;
  }

  enum StrategyApprovalState {
    NOT_APPROVED,
    APPROVED,
    WITHDRAW_ONLY,
    DEPRECATED
  }

  struct StrategyParams {
    StrategyApprovalState approvalState;
    VaultParams Locked;
    VaultParams Liquid;
  }

  struct VaultParams {
    IVault.VaultType Type;
    address vaultAddr;
  }

  struct LocalRegistrarStorage {
    RebalanceParams rebalanceParams;
    AngelProtocolParams angelProtocolParams;
    mapping(bytes32 => string) AccountsContractByChain;
    mapping(bytes4 => StrategyParams) VaultsByStrategyId;
    mapping(address => bool) AcceptedTokens;
    mapping(address => uint256) GasFeeByToken;
    mapping(AngelCoreStruct.FeeTypes => AngelCoreStruct.FeeSetting) FeeSettingsByFeeType;
    mapping(address => bool) ApprovedVaultOperators;
  }

  /*////////////////////////////////////////////////
                        STORAGE MGMT
    */ ////////////////////////////////////////////////
  bytes32 constant LOCAL_REGISTRAR_STORAGE_POSITION = keccak256("local.registrar.storage");

  function localRegistrarStorage() internal pure returns (LocalRegistrarStorage storage lrs) {
    bytes32 position = LOCAL_REGISTRAR_STORAGE_POSITION;
    assembly {
      lrs.slot := position
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IVault} from "../vault/interfaces/IVault.sol";

interface IRouter is IAxelarExecutable {
  /*////////////////////////////////////////////////
                        EVENTS
    */ ////////////////////////////////////////////////

  event TokensSent(IVault.VaultActionData action, uint256 amount);
  event FallbackRefund(IVault.VaultActionData action, uint256 amount);
  event Deposit(IVault.VaultActionData action);
  event Redemption(IVault.VaultActionData action, uint256 amount);
  event Harvest(IVault.VaultActionData action);
  event LogError(IVault.VaultActionData action, string message);
  event LogErrorBytes(IVault.VaultActionData action, bytes data);

  /*////////////////////////////////////////////////
                    CUSTOM TYPES
    */ ////////////////////////////////////////////////

  function executeLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) external returns (IVault.VaultActionData memory);

  function executeWithTokenLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) external returns (IVault.VaultActionData memory);
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.8;

import {AngelCoreStruct} from "../struct.sol";
import {IRouter} from "./IRouter.sol";
import {RouterLib} from "./RouterLib.sol";
import {IVault} from "../vault/interfaces/IVault.sol";
import {ILocalRegistrar} from "../registrar/interfaces/ILocalRegistrar.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";
import {StringToAddress} from "../../lib/StringAddressUtils.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AxelarExecutable} from "../../axelar/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";

contract Router is IRouter, OwnableUpgradeable, AxelarExecutable {
  string public chain;
  ILocalRegistrar public registrar;
  IAxelarGasService public gasReceiver;

  uint256 constant PRECISION = 10 ** 6;

  /*///////////////////////////////////////////////
                        PROXY INIT
    */ ///////////////////////////////////////////////

  function initialize(
    string calldata _chain,
    address _gateway,
    address _gasReceiver,
    address _registrar
  ) public initializer {
    chain = _chain;
    registrar = ILocalRegistrar(_registrar);
    gasReceiver = IAxelarGasService(_gasReceiver);
    __AxelarExecutable_init_unchained(_gateway);
    __Ownable_init_unchained();
  }

  /*///////////////////////////////////////////////
                    MODIFIERS
    */ ///////////////////////////////////////////////

  modifier onlyOneAccount(IVault.VaultActionData memory _action) {
    require(_action.accountIds.length == 1, "Only one account allowed");
    _;
  }

  modifier onlySelf() {
    require(msg.sender == address(this));
    _;
  }

  modifier validateDeposit(
    IVault.VaultActionData memory action,
    string calldata tokenSymbol,
    uint256 amount
  ) {
    // Only one account accepted for deposit calls
    require(action.accountIds.length == 1, "Only one account allowed");
    // deposit only
    require(action.selector == IVault.deposit.selector, "Only deposit accepts tokens");
    // token fwd is token expected
    address tokenAddress = gateway.tokenAddresses(tokenSymbol);
    require(tokenAddress == action.token, "Token mismatch");
    // amt fwd equal expected amt
    require(amount == (action.liqAmt + action.lockAmt), "Amount mismatch");
    // check that at least one vault is expected to receive a deposit
    require(action.lockAmt > 0 || action.liqAmt > 0, "No vault deposit specified");
    // check that token is accepted by angel protocol
    require(registrar.isTokenAccepted(tokenAddress), "Token not accepted");
    // Get parameters from registrar if approved
    require(
      registrar.getStrategyApprovalState(action.strategyId) ==
        LocalRegistrarLib.StrategyApprovalState.APPROVED,
      "Strategy not approved"
    );
    _;
  }

  modifier validateCall(IVault.VaultActionData memory action) {
    require(
      (registrar.getStrategyApprovalState(action.strategyId) ==
        LocalRegistrarLib.StrategyApprovalState.APPROVED) ||
        registrar.getStrategyApprovalState(action.strategyId) ==
        LocalRegistrarLib.StrategyApprovalState.WITHDRAW_ONLY,
      "Strategy not approved"
    );
    _;
  }

  /*///////////////////////////////////////////////
                    ANGEL PROTOCOL ROUTER
    */ ///////////////////////////////////////////////

  function _callSwitch(
    LocalRegistrarLib.StrategyParams memory _params,
    IVault.VaultActionData memory _action
  ) internal validateCall(_action) returns (IVault.VaultActionData memory) {
    // REDEEM
    if (_action.selector == IVault.redeem.selector) {
      return _redeem(_params, _action);
    }
    // REDEEM ALL
    else if (_action.selector == IVault.redeemAll.selector) {
      return _redeemAll(_params, _action);
    }
    // HARVEST
    else if (_action.selector == IVault.harvest.selector) {
      return _harvest(_params, _action);
    }
    // INVALID SELCTOR
    else {
      revert("Invalid function selector provided");
    }
  }

  // Vault action::Deposit
  /// @notice Deposit into the associated liquid or locked vaults
  /// @dev onlySelf restricted public method to enable try/catch in caller
  function deposit(
    IVault.VaultActionData memory action,
    string calldata tokenSymbol,
    uint256 amount
  ) public onlySelf validateDeposit(action, tokenSymbol, amount) {
    LocalRegistrarLib.StrategyParams memory params = registrar.getStrategyParamsById(
      action.strategyId
    );

    if (action.lockAmt > 0) {
      // Send tokens to locked vault and call deposit
      require(IERC20Metadata(action.token).transfer(params.Locked.vaultAddr, action.lockAmt));
      IVault lockedVault = IVault(params.Locked.vaultAddr);
      lockedVault.deposit(action.accountIds[0], action.token, action.lockAmt);
    }

    if (action.liqAmt > 0) {
      // Send tokens to liquid vault and call deposit
      require(IERC20Metadata(action.token).transfer(params.Liquid.vaultAddr, action.liqAmt));
      IVault liquidVault = IVault(params.Liquid.vaultAddr);
      liquidVault.deposit(action.accountIds[0], action.token, action.liqAmt);
    }
  }

  // Vault action::Redeem
  function _redeem(
    LocalRegistrarLib.StrategyParams memory _params,
    IVault.VaultActionData memory _action
  ) internal onlyOneAccount(_action) returns (IVault.VaultActionData memory) {
    IVault lockedVault = IVault(_params.Locked.vaultAddr);
    IVault liquidVault = IVault(_params.Liquid.vaultAddr);

    // Redeem tokens from vaults which sends them from the vault to this contract
    IVault.RedemptionResponse memory _redemptionLock = lockedVault.redeem(
      _action.accountIds[0],
      _action.lockAmt
    );
    require(
      IERC20Metadata(_action.token).transferFrom(
        _params.Locked.vaultAddr,
        address(this),
        _redemptionLock.amount
      )
    );

    IVault.RedemptionResponse memory _redemptionLiquid = liquidVault.redeem(
      _action.accountIds[0],
      _action.liqAmt
    );
    require(
      IERC20Metadata(_action.token).transferFrom(
        _params.Liquid.vaultAddr,
        address(this),
        _redemptionLiquid.amount
      )
    );

    // Pack and send the tokens back to Accounts contract
    uint256 _redeemedAmt = _redemptionLock.amount + _redemptionLiquid.amount;
    _action.lockAmt = _redemptionLock.amount;
    _action.liqAmt = _redemptionLiquid.amount;
    _action = _prepareToSendTokens(_action, _redeemedAmt);
    emit Redemption(_action, _redeemedAmt);
    if (
      (_redemptionLock.status == IVault.VaultActionStatus.POSITION_EXITED) &&
      (_redemptionLiquid.status == IVault.VaultActionStatus.POSITION_EXITED)
    ) {
      _action.status = IVault.VaultActionStatus.POSITION_EXITED;
    } else {
      _action.status = IVault.VaultActionStatus.SUCCESS;
    }
    return _action;
  }

  // Vault action::RedeemAll
  function _redeemAll(
    LocalRegistrarLib.StrategyParams memory _params,
    IVault.VaultActionData memory _action
  ) internal onlyOneAccount(_action) returns (IVault.VaultActionData memory) {
    IVault lockedVault = IVault(_params.Locked.vaultAddr);
    IVault liquidVault = IVault(_params.Liquid.vaultAddr);

    // Redeem tokens from vaults and txfer them to the Router
    IVault.RedemptionResponse memory lockResponse = lockedVault.redeemAll(_action.accountIds[0]);
    if (lockResponse.amount > 0) {
      require(
        IERC20Metadata(_action.token).transferFrom(
          _params.Locked.vaultAddr,
          address(this),
          lockResponse.amount
        )
      );
    }
    _action.lockAmt = lockResponse.amount;

    IVault.RedemptionResponse memory liqResponse = liquidVault.redeemAll(_action.accountIds[0]);
    if (liqResponse.amount > 0) {
      require(
        IERC20Metadata(_action.token).transferFrom(
          _params.Liquid.vaultAddr,
          address(this),
          liqResponse.amount
        )
      );
    }
    _action.liqAmt = liqResponse.amount;

    // Pack and send the tokens back
    uint256 _redeemedAmt = lockResponse.amount + liqResponse.amount;
    _action = _prepareToSendTokens(_action, _redeemedAmt);
    emit Redemption(_action, _redeemedAmt);
    _action.status = IVault.VaultActionStatus.POSITION_EXITED;
    return _action;
  }

  // Vault action::Harvest
  function _harvest(
    LocalRegistrarLib.StrategyParams memory _params,
    IVault.VaultActionData memory _action
  ) internal returns (IVault.VaultActionData memory) {
    IVault liquidVault = IVault(_params.Liquid.vaultAddr);
    IVault lockedVault = IVault(_params.Locked.vaultAddr);
    liquidVault.harvest(_action.accountIds);
    lockedVault.harvest(_action.accountIds);
    emit Harvest(_action);
    return _action;
  }

  /*////////////////////////////////////////////////
                        AXELAR IMPL.
    */ ////////////////////////////////////////////////

  function executeLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) external override onlyLocalAccountsContract returns (IVault.VaultActionData memory) {
    return _execute(sourceChain, sourceAddress, payload);
  }

  function executeWithTokenLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) external override onlyLocalAccountsContract returns (IVault.VaultActionData memory) {
    return _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
  }

  modifier onlyLocalAccountsContract() {
    string memory accountAddress = registrar.getAccountsContractAddressByChain(chain);
    require(StringToAddress.toAddress(accountAddress) == msg.sender, "Unauthorized local call");
    _;
  }

  modifier onlyAccountsContract(string calldata _sourceChain, string calldata _sourceAddress) {
    string memory accountsContractAddress = registrar.getAccountsContractAddressByChain(
      _sourceChain
    );
    require(
      keccak256(bytes(_sourceAddress)) == keccak256(bytes(accountsContractAddress)),
      "Unauthorized Call"
    );
    _;
  }

  modifier notZeroAddress(string calldata _sourceAddress) {
    require(StringToAddress.toAddress(_sourceAddress) != address(0), "Unauthorized Call");
    _;
  }

  function _prepareToSendTokens(
    IVault.VaultActionData memory _action,
    uint256 _sendAmt
  ) internal returns (IVault.VaultActionData memory) {
    if (keccak256(bytes(_action.destinationChain)) == keccak256(bytes(chain))) {
      return _prepareAndSendTokensLocal(_action, _sendAmt);
    } else {
      return _prepareAndSendTokensGMP(_action, _sendAmt);
    }
  }

  function _prepareAndSendTokensLocal(
    IVault.VaultActionData memory _action,
    uint256 _sendAmt
  ) internal returns (IVault.VaultActionData memory) {
    string memory accountsContractAddress = registrar.getAccountsContractAddressByChain(
      (_action.destinationChain)
    );
    IERC20Metadata(_action.token).transfer(
      StringToAddress.toAddress(accountsContractAddress),
      _sendAmt
    );
    emit TokensSent(_action, _sendAmt);
    return _action;
  }

  function _prepareAndSendTokensGMP(
    IVault.VaultActionData memory _action,
    uint256 _sendAmt
  ) internal returns (IVault.VaultActionData memory) {
    // Pack the tokens and calldata for bridging back out over GMP
    LocalRegistrarLib.AngelProtocolParams memory apParams = registrar.getAngelProtocolParams();

    // Prepare gas
    uint256 gasFee = registrar.getGasByToken(_action.token);
    require(_sendAmt > gasFee, "Send amount does not cover gas");
    uint256 amtLessGasFee = _sendAmt - gasFee;

    // Split gas proportionally between liquid and lock amts
    uint256 liqGas = (gasFee * ((_action.liqAmt * PRECISION) / _sendAmt)) / PRECISION;
    uint256 lockGas = gasFee - liqGas;
    _action.liqAmt -= liqGas;
    _action.lockAmt -= lockGas;

    bytes memory payload = RouterLib.packCallData(_action);
    try
      this.sendTokens(
        _action.destinationChain,
        registrar.getAccountsContractAddressByChain(_action.destinationChain),
        payload,
        IERC20Metadata(_action.token).symbol(),
        amtLessGasFee,
        _action.token,
        gasFee
      )
    {
      emit TokensSent(_action, amtLessGasFee);
    } catch Error(string memory reason) {
      emit LogError(_action, reason);
      IERC20Metadata(_action.token).transfer(apParams.refundAddr, _sendAmt);
      emit FallbackRefund(_action, _sendAmt);
      _action.status = IVault.VaultActionStatus.FAIL_TOKENS_FALLBACK;
    } catch (bytes memory data) {
      emit LogErrorBytes(_action, data);
      IERC20Metadata(_action.token).transfer(apParams.refundAddr, _sendAmt);
      emit FallbackRefund(_action, _sendAmt);
      _action.status = IVault.VaultActionStatus.FAIL_TOKENS_FALLBACK;
    }
    return _action;
  }

  function sendTokens(
    string memory destinationChain,
    string memory destinationAddress,
    bytes memory payload,
    string memory symbol,
    uint256 amount,
    address gasToken,
    uint256 gasFeeAmt
  ) public onlySelf {
    address tokenAddress = gateway.tokenAddresses(symbol);
    require(IERC20Metadata(tokenAddress).approve(address(gateway), amount));
    require(IERC20Metadata(gasToken).approve(address(gasReceiver), gasFeeAmt));

    AngelCoreStruct.FeeSetting memory feeSetting = registrar.getFeeSettingsByFeeType(
      AngelCoreStruct.FeeTypes.Default
    );

    gasReceiver.payGasForContractCallWithToken(
      address(this),
      destinationChain,
      destinationAddress,
      payload,
      symbol,
      amount,
      gasToken,
      gasFeeAmt,
      feeSetting.payoutAddress
    );

    gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
  }

  function _executeWithToken(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  )
    internal
    override
    onlyAccountsContract(sourceChain, sourceAddress)
    notZeroAddress(sourceAddress)
    returns (IVault.VaultActionData memory)
  {
    // decode payload
    IVault.VaultActionData memory action = RouterLib.unpackCalldata(payload);

    // Leverage this.call() to enable try/catch logic
    try this.deposit(action, tokenSymbol, amount) {
      emit Deposit(action);
      action.status = IVault.VaultActionStatus.SUCCESS;
      return action;
    } catch Error(string memory reason) {
      emit LogError(action, reason);
      action.status = IVault.VaultActionStatus.FAIL_TOKENS_RETURNED; // Optimistically set to RETURN status, FALLBACK changes if necessary
      return _prepareToSendTokens(action, amount);
    } catch (bytes memory data) {
      emit LogErrorBytes(action, data);
      action.status = IVault.VaultActionStatus.FAIL_TOKENS_RETURNED;
      return _prepareToSendTokens(action, amount);
    }
  }

  function _execute(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  )
    internal
    override
    onlyAccountsContract(sourceChain, sourceAddress)
    notZeroAddress(sourceAddress)
    returns (IVault.VaultActionData memory)
  {
    // decode payload
    IVault.VaultActionData memory action = RouterLib.unpackCalldata(payload);
    LocalRegistrarLib.StrategyParams memory params = registrar.getStrategyParamsById(
      action.strategyId
    );

    // Switch for calling appropriate vault/method
    return _callSwitch(params, action);
  }
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;
import {IVault} from "../vault/interfaces/IVault.sol";

library RouterLib {
  /*////////////////////////////////////////////////
                        METHODS
    */ ////////////////////////////////////////////////

  // Data packing methods
  function unpackCalldata(
    bytes memory _calldata
  ) internal pure returns (IVault.VaultActionData memory) {
    (
      string memory destinationChain,
      bytes4 strategyId,
      bytes4 selector,
      uint32[] memory accountIds,
      address token,
      uint256 lockAmt,
      uint256 liqAmt,
      IVault.VaultActionStatus status
    ) = abi.decode(
        _calldata,
        (string, bytes4, bytes4, uint32[], address, uint256, uint256, IVault.VaultActionStatus)
      );

    return
      IVault.VaultActionData(
        destinationChain,
        strategyId,
        selector,
        accountIds,
        token,
        lockAmt,
        liqAmt,
        status
      );
  }

  function packCallData(
    IVault.VaultActionData memory _calldata
  ) internal pure returns (bytes memory) {
    return
      abi.encode(
        _calldata.destinationChain,
        _calldata.strategyId,
        _calldata.selector,
        _calldata.accountIds,
        _calldata.token,
        _calldata.lockAmt,
        _calldata.liqAmt,
        _calldata.status
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
  enum AccountType {
    Locked,
    Liquid
  }

  enum Tier {
    None,
    Level1,
    Level2,
    Level3
  }

  enum EndowmentType {
    Charity,
    Normal
  }

  enum AllowanceAction {
    Add,
    Remove
  }

  struct TokenInfo {
    address addr;
    uint256 amnt;
  }

  struct BalanceInfo {
    mapping(address => uint256) locked;
    mapping(address => uint256) liquid;
  }

  struct IndexFund {
    uint256 id;
    string name;
    string description;
    uint32[] members;
    //Fund Specific: over-riding SC level setting to handle a fixed split value
    // Defines the % to split off into liquid account, and if defined overrides all other splits
    uint256 splitToLiquid;
    // Used for one-off funds that have an end date (ex. disaster recovery funds)
    uint256 expiryTime; // datetime int of index fund expiry
  }

  ///TODO: need to test this same names already declared in other libraries
  struct BeneficiaryData {
    uint32 endowId;
    uint256 fundId;
    address addr;
  }

  enum BeneficiaryEnum {
    EndowmentId,
    IndexFund,
    Wallet,
    None
  }

  struct Beneficiary {
    BeneficiaryData data;
    BeneficiaryEnum enumData;
  }

  struct SplitDetails {
    uint256 max;
    uint256 min;
    uint256 defaultSplit; // for when a user splits are not used
  }

  function checkSplits(
    SplitDetails memory splits,
    uint256 userLocked,
    uint256 userLiquid,
    bool userOverride
  ) public pure returns (uint256, uint256) {
    // check that the split provided by a user meets the endowment's
    // requirements for splits (set per Endowment)
    if (userOverride) {
      // ignore user splits and use the endowment's default split
      return (100 - splits.defaultSplit, splits.defaultSplit);
    } else if (userLiquid > splits.max) {
      // adjust upper range up within the max split threshold
      return (splits.max, 100 - splits.max);
    } else if (userLiquid < splits.min) {
      // adjust lower range up within the min split threshold
      return (100 - splits.min, splits.min);
    } else {
      // use the user entered split as is
      return (userLocked, userLiquid);
    }
  }

  struct NetworkInfo {
    string name;
    uint256 chainId;
    address router; //SHARED
    address axelarGateway;
    string ibcChannel; // Should be removed
    string transferChannel;
    address gasReceiver; // Should be removed
    uint256 gasLimit; // Should be used to set gas limit
  }

  ///TODO: need to check this and have a look at this
  enum VaultType {
    Native, // Juno native Vault contract
    Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
    Evm, // the address of the Vault contract on it's EVM chain
    None
  }

  enum veTypeEnum {
    Constant,
    Linear,
    SquarRoot
  }

  struct veTypeData {
    uint128 value;
    uint256 scale;
    uint128 slope;
    uint128 power;
  }

  struct veType {
    veTypeEnum ve_type;
    veTypeData data;
  }

  enum TokenType {
    Existing,
    New,
    VeBonding
  }

  struct DaoTokenData {
    address existingData;
    uint256 newInitialSupply;
    string newName;
    string newSymbol;
    veType veBondingType;
    string veBondingName;
    string veBondingSymbol;
    uint256 veBondingDecimals;
    address veBondingReserveDenom;
    uint256 veBondingReserveDecimals;
    uint256 veBondingPeriod;
  }

  struct DaoToken {
    TokenType token;
    DaoTokenData data;
  }

  struct DaoSetup {
    uint256 quorum; //: Decimal,
    uint256 threshold; //: Decimal,
    uint256 votingPeriod; //: u64,
    uint256 timelockPeriod; //: u64,
    uint256 expirationPeriod; //: u64,
    uint128 proposalDeposit; //: Uint128,
    uint256 snapshotPeriod; //: u64,
    DaoToken token; //: DaoToken,
  }

  struct Delegate {
    address addr;
    uint256 expires; // datetime int of delegation expiry
  }

  enum DelegateAction {
    Set,
    Revoke
  }

  function delegateIsValid(
    Delegate storage delegate,
    address sender,
    uint256 envTime
  ) public view returns (bool) {
    return (delegate.addr != address(0) &&
      sender == delegate.addr &&
      (delegate.expires == 0 || envTime <= delegate.expires));
  }

  function canChange(
    SettingsPermission storage permissions,
    address sender,
    address owner,
    uint256 envTime
  ) public view returns (bool) {
    // Can be changed if both critera are satisfied:
    // 1. permission is not locked forever (read: `locked` == true)
    // 2. sender is a valid delegate address and their powers have not expired OR
    //    sender is the endow owner (ie. owner must first revoke their delegation)
    return (!permissions.locked &&
      (delegateIsValid(permissions.delegate, sender, envTime) || sender == owner));
  }

  struct SettingsPermission {
    bool locked;
    Delegate delegate;
  }

  struct SettingsController {
    SettingsPermission acceptedTokens;
    SettingsPermission lockedInvestmentManagement;
    SettingsPermission liquidInvestmentManagement;
    SettingsPermission allowlistedBeneficiaries;
    SettingsPermission allowlistedContributors;
    SettingsPermission maturityAllowlist;
    SettingsPermission maturityTime;
    SettingsPermission earlyLockedWithdrawFee;
    SettingsPermission withdrawFee;
    SettingsPermission depositFee;
    SettingsPermission balanceFee;
    SettingsPermission name;
    SettingsPermission image;
    SettingsPermission logo;
    SettingsPermission sdgs;
    SettingsPermission splitToLiquid;
    SettingsPermission ignoreUserSplits;
  }

  enum ControllerSettingOption {
    AcceptedTokens,
    LockedInvestmentManagement,
    LiquidInvestmentManagement,
    AllowlistedBeneficiaries,
    AllowlistedContributors,
    MaturityAllowlist,
    EarlyLockedWithdrawFee,
    MaturityTime,
    WithdrawFee,
    DepositFee,
    BalanceFee,
    Name,
    Image,
    Logo,
    Sdgs,
    SplitToLiquid,
    IgnoreUserSplits
  }

  enum FeeTypes {
    Default,
    Harvest,
    WithdrawCharity,
    WithdrawNormal,
    EarlyLockedWithdrawCharity,
    EarlyLockedWithdrawNormal
  }

  struct FeeSetting {
    address payoutAddress;
    uint256 bps;
  }

  function validateFee(FeeSetting memory fee) public pure {
    if (fee.bps > 0 && fee.payoutAddress == address(0)) {
      revert("Invalid fee payout zero address given");
    } else if (fee.bps > FEE_BASIS) {
      revert("Invalid fee basis points given. Should be between 0 and 10000.");
    }
  }

  uint256 constant FEE_BASIS = 10000; // gives 0.01% precision for fees (ie. Basis Points)
  uint256 constant PERCENT_BASIS = 100; // gives 1% precision for declared percentages
  uint256 constant BIG_NUMBA_BASIS = 1e24;

  // Interface IDs
  bytes4 constant InterfaceId_Invalid = 0xffffffff;
  bytes4 constant InterfaceId_ERC165 = 0x01ffc9a7;
  bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import "../../../core/router/IRouter.sol";

abstract contract IVault {
  /*////////////////////////////////////////////////
                    CUSTOM TYPES
  */ ////////////////////////////////////////////////
  uint256 constant PRECISION = 10 ** 24;

  /// @notice Angel Protocol Vault Type
  /// @dev Vaults have different behavior depending on type. Specifically access to redemptions and
  /// principle balance
  enum VaultType {
    LOCKED,
    LIQUID
  }

  struct VaultConfig {
    VaultType vaultType;
    bytes4 strategySelector;
    address strategy;
    address registrar;
    address baseToken;
    address yieldToken;
    string apTokenName;
    string apTokenSymbol;
    address admin;
  }

  /// @notice Gerneric AP Vault action data
  /// @param destinationChain The Axelar string name of the blockchain that will receive redemptions/refunds
  /// @param strategyId The 4 byte truncated keccak256 hash of the strategy name, i.e. bytes4(keccak256("Goldfinch"))
  /// @param selector The Vault method that should be called
  /// @param accountId The endowment uid
  /// @param token The token (if any) that was forwarded along with the calldata packet by GMP
  /// @param lockAmt The amount of said token that is intended to interact with the locked vault
  /// @param liqAmt The amount of said token that is intended to interact with the liquid vault
  struct VaultActionData {
    string destinationChain;
    bytes4 strategyId;
    bytes4 selector;
    uint32[] accountIds;
    address token;
    uint256 lockAmt;
    uint256 liqAmt;
    VaultActionStatus status;
  }

  /// @notice Structure for storing account principle information necessary for yield calculations
  /// @param baseToken The qty of base tokens deposited into the vault
  /// @param costBasis_withPrecision The cost per share for entry into the vault (baseToken / share)
  struct Principle {
    uint256 baseToken;
    uint256 costBasis_withPrecision;
  }

  enum VaultActionStatus {
    UNPROCESSED, // INIT state
    SUCCESS, // Ack
    POSITION_EXITED, // Position fully exited
    FAIL_TOKENS_RETURNED, // Tokens returned to accounts contract
    FAIL_TOKENS_FALLBACK // Tokens failed to be returned to accounts contract
  }

  struct RedemptionResponse {
    uint256 amount;
    VaultActionStatus status;
  }

  /*////////////////////////////////////////////////
                        EVENTS
  */ ////////////////////////////////////////////////

  /// @notice Event emited on each Deposit call
  /// @dev Upon deposit, emit this event. Index the account and staking contract for analytics
  event DepositMade(
    uint32 indexed accountId,
    VaultType vaultType,
    address tokenDeposited,
    uint256 amtDeposited
  );

  /// @notice Event emited on each Redemption call
  /// @dev Upon redemption, emit this event. Index the account and staking contract for analytics
  event Redemption(
    uint32 indexed accountId,
    VaultType vaultType,
    address tokenRedeemed,
    uint256 amtRedeemed
  );

  /// @notice Event emited on each Harvest call
  /// @dev Upon harvest, emit this event. Index the accounts harvested for.
  /// Rewards that are re-staked or otherwise reinvested will call other methods which will emit events
  /// with specific yield/value details
  /// @param accountIds a list of the Accounts harvested for
  event Harvest(uint32[] indexed accountIds);

  /*////////////////////////////////////////////////
                        ERRORS
  */ ////////////////////////////////////////////////
  error OnlyAdmin();
  error OnlyRouter();
  error OnlyApproved();
  error OnlyBaseToken();
  error OnlyNotPaused();
  error ApproveFailed();
  error TransferFailed();

  /*////////////////////////////////////////////////
                    EXTERNAL METHODS
  */ ////////////////////////////////////////////////

  /// @notice returns the vault config
  function getVaultConfig() external view virtual returns (VaultConfig memory);

  /// @notice set the vault config
  function setVaultConfig(VaultConfig memory _newConfig) external virtual;

  /// @notice deposit tokens into vault position of specified Account
  /// @dev the deposit method allows the Vault contract to create or add to an existing
  /// position for the specified Account. In the case that multiple different tokens can be deposited,
  /// the method requires the deposit token address and amount. The transfer of tokens to the Vault
  /// contract must occur before the deposit method is called.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @param token the deposited token
  /// @param amt the amount of the deposited token
  function deposit(uint32 accountId, address token, uint256 amt) external payable virtual;

  /// @notice redeem value from the vault contract
  /// @dev allows an Account to redeem from its staked value. The behavior is different dependent on VaultType.
  /// Before returning the redemption amt, the vault must approve the Router to spend the tokens.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @param amt the amount of shares to redeem
  /// @return RedemptionResponse returns the number of base tokens redeemed by the call and the status
  function redeem(
    uint32 accountId,
    uint256 amt
  ) external payable virtual returns (RedemptionResponse memory);

  /// @notice redeem all of the value from the vault contract
  /// @dev allows an Account to redeem all of its staked value. Good for rebasing tokens wherein the value isn't
  /// known explicitly. Before returning the redemption amt, the vault must approve the Router to spend the tokens.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @return RedemptionResponse returns the number of base tokens redeemed by the call and the status
  function redeemAll(uint32 accountId) external payable virtual returns (RedemptionResponse memory);

  /// @notice restricted method for harvesting accrued rewards
  /// @dev Claim reward tokens accumulated to the staked value. The underlying behavior will vary depending
  /// on the target yield strategy and VaultType. Only callable by an Angel Protocol Keeper
  /// @param accountIds Used to specify which accounts to call harvest against. Structured so that this can
  /// be called in batches to avoid running out of gas.
  function harvest(uint32[] calldata accountIds) external virtual;

  /*////////////////////////////////////////////////
                INTERNAL HELPER METHODS
    */ ////////////////////////////////////////////////

  /// @notice internal method for validating that calls came from the approved AP router
  /// @dev The registrar will hold a record of the approved Router address. This method must implement a method of
  /// checking that the msg.sender == ApprovedRouter
  function _isApprovedRouter() internal view virtual returns (bool);

  /// @notice internal method for checking whether the caller is the paired locked/liquid vault
  /// @dev can be used for more gas efficient rebalancing between the two sibling vaults
  function _isSiblingVault() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
  error InvalidAddressString();

  function toAddress(string memory addressString) internal pure returns (address) {
    bytes memory stringBytes = bytes(addressString);
    uint160 addressNumber = 0;
    uint8 stringByte;

    if (stringBytes.length != 42 || stringBytes[0] != "0" || stringBytes[1] != "x")
      revert InvalidAddressString();

    for (uint256 i = 2; i < 42; ++i) {
      stringByte = uint8(stringBytes[i]);

      if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
      else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
      else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
      else revert InvalidAddressString();

      addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
    }
    return address(addressNumber);
  }
}

library AddressToString {
  function toString(address addr) internal pure returns (string memory) {
    bytes memory addressBytes = abi.encodePacked(addr);
    uint256 length = addressBytes.length;
    bytes memory characters = "0123456789abcdef";
    bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

    stringBytes[0] = "0";
    stringBytes[1] = "x";

    for (uint256 i; i < length; ++i) {
      stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
      stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
    }
    return string(stringBytes);
  }
}