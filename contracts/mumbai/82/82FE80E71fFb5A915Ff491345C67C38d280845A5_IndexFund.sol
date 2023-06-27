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
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";

library AccountMessages {
  struct CreateEndowmentRequest {
    bool withdrawBeforeMaturity;
    uint256 maturityTime;
    string name;
    uint256[] sdgs;
    AngelCoreStruct.Tier tier;
    AngelCoreStruct.EndowmentType endowType;
    string logo;
    string image;
    address[] members;
    uint256 threshold;
    uint256 duration;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
    AngelCoreStruct.FeeSetting withdrawFee;
    AngelCoreStruct.FeeSetting depositFee;
    AngelCoreStruct.FeeSetting balanceFee;
    uint256 proposalLink;
    AngelCoreStruct.SettingsController settingsController;
    uint32 parent;
    address[] maturityAllowlist;
    bool ignoreUserSplits;
    AngelCoreStruct.SplitDetails splitToLiquid;
    uint256 referralId;
  }

  struct UpdateEndowmentSettingsRequest {
    uint32 id;
    bool donationMatchActive;
    uint256 maturityTime;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    address[] maturity_allowlist_add;
    address[] maturity_allowlist_remove;
    AngelCoreStruct.SplitDetails splitToLiquid;
    bool ignoreUserSplits;
  }

  struct UpdateEndowmentControllerRequest {
    uint32 id;
    AngelCoreStruct.SettingsController settingsController;
  }

  struct UpdateEndowmentDetailsRequest {
    uint32 id;
    address owner;
    string name;
    uint256[] sdgs;
    string logo;
    string image;
    LocalRegistrarLib.RebalanceParams rebalance;
  }

  struct Strategy {
    string vault; // Vault SC Address
    uint256 percentage; // percentage of funds to invest
  }

  struct UpdateProfileRequest {
    uint32 id;
    string overview;
    string url;
    string registrationNumber;
    string countryOfOrigin;
    string streetAddress;
    string contactEmail;
    string facebook;
    string twitter;
    string linkedin;
    uint16 numberOfEmployees;
    string averageAnnualBudget;
    string annualRevenue;
    string charityNavigatorRating;
  }

  ///TODO: response struct should be below this

  struct ConfigResponse {
    address owner;
    string version;
    address registrarContract;
    uint256 nextAccountId;
    uint256 maxGeneralCategoryId;
    address subDao;
    address gateway;
    address gasReceiver;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
  }

  struct StateResponse {
    bool closingEndowment;
    AngelCoreStruct.Beneficiary closingBeneficiary;
  }

  struct EndowmentDetailsResponse {
    address owner;
    address dao;
    address daoToken;
    string description;
    AngelCoreStruct.EndowmentType endowType;
    uint256 maturityTime;
    LocalRegistrarLib.RebalanceParams rebalance;
    address donationMatchContract;
    address[] maturityAllowlist;
    uint256 pendingRedemptions;
    string logo;
    string image;
    string name;
    uint256[] sdgs;
    AngelCoreStruct.Tier tier;
    uint256 copycatStrategy;
    uint256 proposalLink;
    uint256 parent;
    AngelCoreStruct.SettingsController settingsController;
  }

  struct DepositRequest {
    uint32 id;
    uint256 lockedPercentage;
    uint256 liquidPercentage;
  }

  struct UpdateFeeSettingRequest {
    uint32 id;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
    AngelCoreStruct.FeeSetting depositFee;
    AngelCoreStruct.FeeSetting withdrawFee;
    AngelCoreStruct.FeeSetting balanceFee;
  }

  enum DonationMatchEnum {
    HaloTokenReserve,
    Cw20TokenReserve
  }

  struct DonationMatchData {
    address reserveToken;
    address uniswapFactory;
    uint24 poolFee;
  }

  struct DonationMatch {
    DonationMatchEnum enumData;
    DonationMatchData data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//Libraries
import "./storage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IndexFundMessage} from "./message.sol";
import {AngelCoreStruct} from "../struct.sol";
import {Array, Array32} from "../../lib/array.sol";
import {Utils} from "../../lib/utils.sol";
import {IRegistrar} from "../registrar/interfaces/IRegistrar.sol";
import {RegistrarStorage} from "../registrar/storage.sol";
import {AccountMessages} from "../accounts/message.sol";

// TODO: Edit Query functions with start and limit to optimise the size of data being returned

/**
 * @title IndexFund
 * @notice User can deposit/donate to a collection of endowments (index funds) through this contract
 * @dev IndexFund is a contract that manages the funds of the angelcore platform
 * It is responsible for creating new funds, adding members to funds, and
 * distributing funds to members
 */
contract IndexFund is StorageIndexFund, ReentrancyGuard, Initializable {
  event OwnerUpdated(address newOwner);
  event RegistrarUpdated(address newRegistrar);
  event ConfigUpdated();
  event IndexFundCreated(uint256 id);
  event IndexFundRemoved(uint256 id);
  event MemberRemoved(uint256 fundId, uint32 memberId);
  event MembersUpdated(uint256 fundId, uint32[] members);
  event DonationMessagesUpdated(uint256 fundId);
  event ActiveFundUpdated(uint256 fundId);
  event StateUpdated();

  uint256 maxLimit;
  uint256 defaultLimit;

  using SafeMath for uint256;

  /**
   * @notice Initializer function for index fund contract, to be called when proxy is deployed
   * @dev This function is called by deployer only once at the time of initialization
   * @param details IndexFundMessage.InstantiateMessage
   */
  function initIndexFund(IndexFundMessage.InstantiateMessage memory details) public initializer {
    require(details.registrarContract != address(0), "invalid registrar address");

    maxLimit = 30;
    defaultLimit = 10;

    state.config = IndexFundStorage.Config({
      owner: msg.sender,
      registrarContract: details.registrarContract,
      fundRotation: details.fundRotation,
      fundMemberLimit: details.fundMemberLimit,
      fundingGoal: details.fundingGoal
    });
    emit ConfigUpdated();
    emit OwnerUpdated(msg.sender);

    state.state = IndexFundStorage._State({
      totalFunds: 0,
      activeFund: 0,
      nextFundId: 1,
      roundDonations: 0,
      nextRotationBlock: block.number + state.config.fundRotation
    });
    emit StateUpdated();
  }

  /**
   * @notice function to update ownder of the contract
   * @dev can be called by rent owner to set new owner
   * @param newOwner address of new owner
   */
  function updateOwner(address newOwner) public nonReentrant returns (bool) {
    if (msg.sender != state.config.owner) {
      revert("Unauthorized");
    }

    require(newOwner != address(0), "invalid input address");

    state.config.owner = newOwner;
    emit OwnerUpdated(newOwner);
    return true;
  }

  /**
   * @notice function to update registrar contract address
   * @dev can be called by rent owner to set new registrar contract address
   * @param newRegistrar address of new registrar contract
   */
  function updateRegistrar(address newRegistrar) public nonReentrant returns (bool) {
    if (msg.sender != state.config.owner) {
      revert("Unauthorized");
    }

    require(newRegistrar != address(0), "invalid input address");

    state.config.registrarContract = newRegistrar;

    emit RegistrarUpdated(newRegistrar);
    return true;
  }

  /**
   * @notice function to update config of index fund
   * @dev can be called by rent owner to set new config
   * @param details IndexFundMessage.UpdateConfigMessage
   */
  function updateConfig(
    IndexFundMessage.UpdateConfigMessage memory details
  ) public nonReentrant returns (bool) {
    if (msg.sender != state.config.owner) {
      revert("Unauthorized");
    }

    if (details.fundingGoal != 0) {
      if (details.fundingGoal < state.state.roundDonations) {
        revert("Invalid Inputs");
      }
      state.config.fundingGoal = details.fundingGoal;
    } else {
      state.config.fundingGoal = 0;
    }

    state.config.fundRotation = details.fundRotation;
    state.config.fundMemberLimit = details.fundMemberLimit;
    emit ConfigUpdated();
    return true;
  }

  /**
   * @notice function to create index fund
   * @dev can be called by rent owner to create index fund
   * @param name name of index fund
   * @param description description of index fund
   * @param members array of members of index fund
   * @param rotatingFund boolean to indicate if index fund is rotating fund
   * @param splitToLiquid split of index fund to liquid fund
   * @param expiryTime expiry time of index fund
   */
  function createIndexFund(
    string memory name,
    string memory description,
    uint32[] memory members,
    bool rotatingFund,
    uint256 splitToLiquid,
    uint256 expiryTime
  ) public nonReentrant returns (bool) {
    if (msg.sender != state.config.owner) {
      revert("Unauthorized");
    }

    require(splitToLiquid <= 100, "invalid split, must be less or equal to 100");

    state.FUNDS[state.state.nextFundId] = AngelCoreStruct.IndexFund({
      id: state.state.nextFundId,
      name: name,
      description: description,
      members: members,
      splitToLiquid: splitToLiquid,
      expiryTime: expiryTime
    });

    for (uint8 i = 0; i < members.length; i++) {
      state.FUNDS_BY_ENDOWMENT[members[i]].push(state.state.nextFundId);
    }

    emit IndexFundCreated(state.state.nextFundId);

    // If there are no funds created or no active funds yet, set the new
    // fund being created now to be the active fund
    if (state.state.totalFunds == 0 || state.state.activeFund == 0) {
      state.state.activeFund = state.state.nextFundId;
      emit ActiveFundUpdated(state.state.activeFund);
    }

    if (rotatingFund) {
      state.rotatingFunds.push(state.state.nextFundId);
    }

    state.state.totalFunds += 1;
    state.state.nextFundId += 1;

    return true;
  }

  /**
   * @notice function to remove index fund
   * @dev can be called by rent owner to remove an index fund
   * @param fundId id of index fund to be removed
   */
  function removeIndexFund(uint256 fundId) public nonReentrant returns (bool) {
    require(msg.sender != state.config.owner, "Unauthorized");
    require(state.FUNDS[fundId].members.length >= 0, "Invalid Fund");

    if (state.state.activeFund == fundId) {
      state.state.activeFund = rotateFund(fundId, block.timestamp);
      emit ActiveFundUpdated(state.state.activeFund);
    }

    // remove from rotating funds list
    bool found;
    uint256 index;
    (index, found) = Array.indexOf(state.rotatingFunds, fundId);
    if (found) {
      Array.remove(state.rotatingFunds, index);
    }

    state.state.totalFunds -= 1;
    delete state.FUNDS[fundId];
    emit IndexFundRemoved(fundId);
    return true;
  }

  /**
   *  @notice function to remove member from all the index funds
   *  @dev can be called by rent owner to remove a member from all the index funds
   *  @param member member to be removed from index fund
   */
  function removeMember(uint32 member) public nonReentrant returns (bool) {
    RegistrarStorage.Config memory registrar_config = IRegistrar(state.config.registrarContract)
      .queryConfig();

    require(address(0) != registrar_config.accountsContract, "accounts contract not configured");
    require(msg.sender == registrar_config.accountsContract, "Unauthorized");
    require(state.FUNDS_BY_ENDOWMENT[member].length >= 0);

    // remove member from all involved funds if in their members array
    bool found;
    uint32 index;
    for (uint32 i = 0; i < state.FUNDS_BY_ENDOWMENT[member].length; i++) {
      uint256 fundId = state.FUNDS_BY_ENDOWMENT[member][i];
      (index, found) = Array32.indexOf(state.FUNDS[fundId].members, member);
      if (found) {
        Array32.remove(state.FUNDS[fundId].members, index);
        emit MemberRemoved(fundId, member);
      }
    }
    delete state.FUNDS_BY_ENDOWMENT[member];
    return true;
  }

  /**
   *  @notice function to update fund members
   *  @dev can be called by rent owner to add/remove member to an index fund
   *  @param fundId the id of index fund to be updated
   *  @param members array of members to be set for the index fund
   */
  function updateFundMembers(
    uint256 fundId,
    uint32[] memory members
  ) public nonReentrant returns (bool) {
    require(msg.sender == state.config.owner, "Unauthorized");
    require(members.length < state.config.fundMemberLimit, "Fund member limit exceeded");
    require(!fundIsExpired(state.FUNDS[fundId], block.timestamp), "Index Fund Expired");

    // set members on fund
    state.FUNDS[fundId].members = members;

    // update members by endowment records
    bool found;
    uint256 index;
    for (uint i = 0; i < members.length; i++) {
      uint256[] memory funds = state.FUNDS_BY_ENDOWMENT[members[i]];
      (index, found) = Array.indexOf(funds, fundId);
      if (!found) {
        state.FUNDS_BY_ENDOWMENT[members[i]].push(fundId);
      }
    }

    emit MembersUpdated(fundId, members);

    return true;
  }

  /**
   * @notice deposit function which can be called by user to add funds to index fund
   * @dev converted from rust implementation, handles donations by managing limits and rotating active fund
   * @param fundId index fund ID
   * @param token address of Token being deposited
   * @param amount amount of Token being deposited
   * @param splitToLiquid integer % of deposit to be split to liquid balance
   */
  function depositERC20(
    uint256 fundId,
    address token,
    uint256 amount,
    uint256 splitToLiquid
  ) public nonReentrant {
    require(token != address(0), "Invalid Token Address");

    uint256 depositAmount = amount;

    // check if time limit is reached
    if (state.config.fundRotation != 0) {
      if (block.number >= state.state.nextRotationBlock) {
        uint256 newFundId = rotateFund(state.state.activeFund, block.timestamp);
        state.state.activeFund = newFundId;
        emit ActiveFundUpdated(state.state.activeFund);
        state.state.roundDonations = 0;

        while (block.number >= state.state.nextRotationBlock) {
          state.state.nextRotationBlock += state.config.fundRotation;
        }
      }
    }

    RegistrarStorage.Config memory registrar_config = IRegistrar(state.config.registrarContract)
      .queryConfig();

    if (fundId != 0) {
      require(state.FUNDS[fundId].members.length != 0, "Empty Fund");

      require(!fundIsExpired(state.FUNDS[fundId], block.timestamp), "Expired Fund");

      updateDonationMessages(
        fundId,
        calculateSplit(
          registrar_config.splitToLiquid,
          state.FUNDS[fundId].splitToLiquid,
          splitToLiquid
        ),
        amount,
        state.donationMessages
      );
    } else {
      if (state.config.fundingGoal != 0) {
        uint256 loopDonation = 0;

        while (depositAmount > 0) {
          // This will revert the transaction and donation will fail. TODO: check with team
          require(state.FUNDS[state.state.activeFund].members.length != 0, "Empty Index Fund");

          require(
            !fundIsExpired(state.FUNDS[state.state.activeFund], block.timestamp),
            "Expired Fund"
          );
          uint256 goalLeftover = state.config.fundingGoal - state.state.roundDonations;

          uint256 activeFund = state.state.activeFund;

          if (depositAmount >= goalLeftover) {
            state.state.roundDonations = 0;
            // set state active fund to next fund for next loop iteration

            state.state.activeFund = rotateFund(state.state.activeFund, block.timestamp);

            emit ActiveFundUpdated(state.state.activeFund);
            loopDonation = goalLeftover;
          } else {
            state.state.roundDonations += depositAmount;
            loopDonation = depositAmount;
          }

          updateDonationMessages(
            activeFund,
            calculateSplit(
              registrar_config.splitToLiquid,
              state.FUNDS[activeFund].splitToLiquid,
              splitToLiquid
            ),
            loopDonation,
            state.donationMessages
          );
          // deduct donated amount in this round from total donation amt
          depositAmount -= loopDonation;
        }
      } else {
        require(state.FUNDS[state.state.activeFund].members.length != 0, "Empty Index Fund");

        require(
          !fundIsExpired(state.FUNDS[state.state.activeFund], block.timestamp),
          "Expired Fund"
        );

        updateDonationMessages(
          state.state.activeFund,
          calculateSplit(
            registrar_config.splitToLiquid,
            state.FUNDS[state.state.activeFund].splitToLiquid,
            splitToLiquid
          ),
          amount,
          state.donationMessages
        );
      }
    }

    // transfer funds from msg sender to here
    require(
      IERC20(token).transferFrom(msg.sender, address(this), amount),
      "Failed to transfer funds"
    );

    // give allowance to accounts
    require(
      IERC20(token).approve(registrar_config.accountsContract, amount),
      "Failed to approve funds"
    );

    (
      address[] memory target,
      uint256[] memory value,
      bytes[] memory callData
    ) = buildDonationMessages(registrar_config.accountsContract, state.donationMessages, token);

    Utils._execute(target[0], value[0], callData[0]);

    // Clean up storage for next call
    delete state.donationMessages.member_ids;
    delete state.donationMessages.locked_donation_amount;
    delete state.donationMessages.liquid_donation_amount;
    delete state.donationMessages.lockedSplit;
    delete state.donationMessages.liquidSplit;

    emit StateUpdated();
  }

  /**
   * @dev Update donation messages
   * @param fundId index fund ID
   * @param liquidSplit Split to liquid
   * @param balance Balance of fund
   * @param donationMessages Donation messages
   */
  function updateDonationMessages(
    uint256 fundId,
    uint256 liquidSplit,
    uint256 balance,
    IndexFundStorage.DonationMessages storage donationMessages
  ) internal {
    uint256 memberPortion = balance;

    uint32[] memory members = state.FUNDS[fundId].members;

    if (members.length > 0) {
      memberPortion = memberPortion.div(members.length);
    }

    uint256 lockSplit = 100 - liquidSplit;

    for (uint256 i = 0; i < members.length; i++) {
      // check if member is in membersidsm, then modify, else push
      bool alreadyExists = false;
      uint256 index = 0;

      for (uint256 j = 0; j < donationMessages.member_ids.length; j++) {
        if (donationMessages.member_ids[j] == members[i]) {
          alreadyExists = true;
          index = j;
          break;
        }
      }

      if (alreadyExists) {
        donationMessages.lockedSplit[index] = lockSplit;
        donationMessages.liquidSplit[index] = liquidSplit;
        donationMessages.locked_donation_amount[index] += (memberPortion * lockSplit) / 100;
        // avoid any over and under flows
        donationMessages.liquid_donation_amount[index] += (
          (memberPortion - ((memberPortion * lockSplit) / 100))
        );
      } else {
        donationMessages.member_ids.push(members[i]);
        donationMessages.lockedSplit.push(lockSplit);
        donationMessages.liquidSplit.push(liquidSplit);
        donationMessages.locked_donation_amount.push((memberPortion * lockSplit) / 100);
        // avoid any over and under flows
        donationMessages.liquid_donation_amount.push(
          (memberPortion - ((memberPortion * lockSplit) / 100))
        );
      }
    }
    emit DonationMessagesUpdated(fundId);
  }

  /**
   * @dev Build donation messages
   * @param accountscontract Accounts contract address
   * @param donationMessages Donation messages
   * @param tokenaddress Token address
   */
  function buildDonationMessages(
    address accountscontract,
    IndexFundStorage.DonationMessages storage donationMessages,
    address tokenaddress
  )
    internal
    view
    returns (address[] memory target, uint256[] memory value, bytes[] memory callData)
  {
    target = new address[](donationMessages.member_ids.length);
    value = new uint256[](donationMessages.member_ids.length);
    callData = new bytes[](donationMessages.member_ids.length);
    // TODO: check with andrey for the split logic in index fund
    for (uint256 i = 0; i < donationMessages.member_ids.length; i++) {
      target[i] = accountscontract;
      value[i] = 0;
      callData[i] = abi.encodeWithSignature(
        "depositERC20((uint256,uint256,uint256),address,uint256)",
        AccountMessages.DepositRequest({
          id: donationMessages.member_ids[i],
          lockedPercentage: donationMessages.lockedSplit[i],
          liquidPercentage: donationMessages.liquidSplit[i]
        }),
        tokenaddress,
        donationMessages.locked_donation_amount[i] + donationMessages.liquid_donation_amount[i]
      );
    }
  }

  /**
   * @dev Calculate split
   * @param registrar_split Registrar split
   * @param fundSplit Fund split (set on index fund contract)
   * @param userSplit User split
   */

  function calculateSplit(
    AngelCoreStruct.SplitDetails memory registrar_split,
    uint256 fundSplit,
    uint256 userSplit
  ) internal pure returns (uint256) {
    uint256 split = 0;

    if (fundSplit == 0) {
      if (userSplit == 0) {
        split = registrar_split.defaultSplit;
      } else {
        if (userSplit > registrar_split.min && userSplit < registrar_split.max) {
          split = userSplit;
        }
      }
    } else {
      split = fundSplit;
    }

    return split;
  }

  // QUERIES

  /**
   * @dev Query config
   * @return Config
   */
  function queryConfig()
    public
    view
    returns (
      // TODO: Add reentrancy guard to `view` functions
      IndexFundStorage.Config memory
    )
  {
    return state.config;
  }

  /**
   * @dev Query state
   * @return State
   */
  function queryState() public view returns (IndexFundMessage.StateResponseMessage memory) {
    return
      IndexFundMessage.StateResponseMessage({
        totalFunds: state.state.totalFunds,
        activeFund: state.state.activeFund,
        roundDonations: state.state.roundDonations,
        nextRotationBlock: state.state.nextRotationBlock
      });
  }

  /**
   * @dev Query fund details
   * @param fundId Fund id
   * @return Fund details
   */
  function queryFundDetails(uint256 fundId) public view returns (AngelCoreStruct.IndexFund memory) {
    return state.FUNDS[fundId];
  }

  /**
   * @dev Query in which index funds is an endowment part of
   * @param endowmentId Endowment id
   * @return Fund details
   */
  function queryInvolvedFunds(
    uint32 endowmentId
  ) public view returns (AngelCoreStruct.IndexFund[] memory) {
    // make memory and allocate to response object
    AngelCoreStruct.IndexFund[] memory resp = new AngelCoreStruct.IndexFund[](
      state.FUNDS_BY_ENDOWMENT[endowmentId].length
    );

    for (uint256 i = 0; i < state.FUNDS_BY_ENDOWMENT[endowmentId].length; i++) {
      resp[i] = state.FUNDS[state.FUNDS_BY_ENDOWMENT[endowmentId][i]];
    }

    return resp;
  }

  /**
   * @dev Query active fund details
   * @return Fund details
   */
  function queryActiveFundDetails() public view returns (AngelCoreStruct.IndexFund memory) {
    return state.FUNDS[state.state.activeFund];
  }

  // Internal functions
  /**
   * @dev Check if fund is expired
   * @param fund Fund
   * @param envTime rent block time
   * @return True if fund is expired
   */
  function fundIsExpired(
    AngelCoreStruct.IndexFund memory fund,
    uint256 envTime
  ) internal pure returns (bool) {
    return (fund.expiryTime != 0 && envTime >= fund.expiryTime);
  }

  /**
   * @dev rotate active based if investment goal is fulfilled
   * @param rFund rent Active fund
   * @param envTime rent block time
   * @return New active fund
   */
  function rotateFund(uint256 rFund, uint256 envTime) internal view returns (uint256) {
    AngelCoreStruct.IndexFund[] memory activeFunds = new AngelCoreStruct.IndexFund[](
      state.rotatingFunds.length
    );

    for (uint256 i = 0; i < state.rotatingFunds.length; i++) {
      if (!fundIsExpired(state.FUNDS[state.rotatingFunds[i]], envTime)) {
        activeFunds[i] = state.FUNDS[state.rotatingFunds[i]];
      }
    }

    // check if the rent active fund is in the rotation and not expired
    bool found;
    uint256 index;
    (index, found) = Array.indexOf(state.rotatingFunds, rFund);
    if (!found || index == activeFunds.length - 1) {
      // set to the first fund in the list
      return activeFunds[0].id;
    } else {
      return activeFunds[index + 1].id;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library IndexFundMessage {
  struct InstantiateMessage {
    address registrarContract;
    uint256 fundRotation; // how many blocks are in a rotation cycle for the active IndexFund
    uint256 fundMemberLimit; // limit to number of members an IndexFund can have
    uint256 fundingGoal; // donation funding limit to trigger early cycle of the Active IndexFund
  }

  struct UpdateConfigMessage {
    uint256 fundRotation;
    uint256 fundMemberLimit;
    uint256 fundingGoal;
  }

  struct StateResponseMessage {
    uint256 totalFunds;
    uint256 activeFund; // index ID of the Active IndexFund
    uint256 roundDonations; // total donations given to active charity this round
    uint256 nextRotationBlock; // block height to perform next rotation on
  }

  struct DonationDetailsResponse {
    address addr;
    uint256 total;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library IndexFundStorage {
  struct Config {
    address owner; // DANO Address
    address registrarContract; // Address of Registrar SC
    uint256 fundRotation; // how many blocks are in a rotation cycle for the active IndexFund
    uint256 fundMemberLimit; // limit to number of members an IndexFund can have
    uint256 fundingGoal; // donation funding limit (in UUSD) to trigger early cycle of the Active IndexFund
  }

  struct _State {
    uint256 totalFunds;
    uint256 activeFund; // ID of the Active IndexFund in the rent rotation set
    uint256 roundDonations; // total donations given to active charity this round
    uint256 nextRotationBlock; // block height to perform next rotation on
    uint256 nextFundId;
  }

  struct DonationMessages {
    uint32[] member_ids;
    uint256[] locked_donation_amount;
    uint256[] liquid_donation_amount;
    uint256[] lockedSplit;
    uint256[] liquidSplit;
  }

  struct State {
    Config config;
    _State state;
    mapping(uint256 => AngelCoreStruct.IndexFund) FUNDS;
    mapping(uint32 => uint256[]) FUNDS_BY_ENDOWMENT; // Endow ID >> [Fund IDs]
    uint256[] rotatingFunds; // list of active, rotating funds (ex. 17 funds, 1 for each of the UNSDGs)
    DonationMessages donationMessages;
  }
}

contract StorageIndexFund {
  IndexFundStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {LocalRegistrarLib} from "../lib/LocalRegistrarLib.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface ILocalRegistrar {
  /*////////////////////////////////////////////////
                        EVENTS
    */ ////////////////////////////////////////////////
  event RebalanceParamsUpdated();
  event AngelProtocolParamsUpdated();
  event AccountsContractStorageUpdated(string _chainName, string _accountsContractAddress);
  event TokenAcceptanceUpdated(address _tokenAddr, bool _isAccepted);
  event StrategyApprovalUpdated(
    bytes4 _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event StrategyParamsUpdated(
    bytes4 _strategyId,
    address _lockAddr,
    address _liqAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event GasFeeUpdated(address _tokenAddr, uint256 _gasFee);
  event FeeSettingsUpdated(
    AngelCoreStruct.FeeTypes _feeType,
    uint256 _bpsRate,
    address _payoutAddress
  );

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {ILocalRegistrar} from "./ILocalRegistrar.sol";

interface IRegistrar is ILocalRegistrar {
  function updateConfig(RegistrarMessages.UpdateConfigRequest memory details) external;

  function updateOwner(address newOwner) external;

  function updateTokenPriceFeed(address token, address priceFeed) external;

  function vaultAdd(RegistrarMessages.VaultAddRequest memory details) external;

  function vaultRemove(string memory _stratagyName) external;

  function vaultUpdate(
    string memory _stratagyName,
    bool approved,
    AngelCoreStruct.EndowmentType[] memory restrictedfrom
  ) external;

  function updateNetworkConnections(
    AngelCoreStruct.NetworkInfo memory networkInfo,
    string memory action
  ) external;

  // Query functions for contract

  function queryConfig() external view returns (RegistrarStorage.Config memory);

  function queryTokenPriceFeed(address token) external view returns (address);

  function queryAllStrategies() external view returns (bytes4[] memory allStrategies);

  function queryNetworkConnection(
    uint256 chainId
  ) external view returns (AngelCoreStruct.NetworkInfo memory response);

  function owner() external view returns (address);
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
    address uniswapRouter;
    address uniswapFactory;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
  struct InstantiateRequest {
    address treasury;
    // uint256 taxRate;
    // AngelCoreStruct.RebalanceDetails rebalance;
    AngelCoreStruct.SplitDetails splitToLiquid;
    // AngelCoreStruct.AcceptedTokens acceptedTokens;
    address router;
    address axelarGateway;
    address axelarGasRecv;
  }

  struct UpdateConfigRequest {
    address accountsContract;
    // uint256 taxRate;
    // AngelCoreStruct.RebalanceDetails rebalance;
    string[] approved_charities;
    uint256 splitMax;
    uint256 splitMin;
    uint256 splitDefault;
    uint256 collectorShare;
    // AngelCoreStruct.AcceptedTokens acceptedTokens;

    // CONTRACT ADDRESSES
    address indexFundContract;
    address govContract;
    address treasury;
    address donationMatchCharitesContract;
    address donationMatchEmitter;
    address haloToken;
    address haloTokenLpContract;
    address charitySharesContract;
    address fundraisingContract;
    address applicationsReview;
    address uniswapRouter;
    address uniswapFactory;
    address multisigFactory;
    address multisigEmitter;
    address charityProposal;
    address lockedWithdrawal;
    address proxyAdmin;
    address usdcAddress;
    address wMaticAddress;
    address subdaoGovContract;
    address subdaoTokenContract;
    address subdaoBondingTokenContract;
    address subdaoCw900Contract;
    address subdaoDistributorContract;
    address subdaoEmitter;
    address donationMatchContract;
    address cw900lvAddress;
  }

  struct VaultAddRequest {
    // chainid of network
    uint256 network;
    string stratagyName;
    address inputDenom;
    address yieldToken;
    AngelCoreStruct.EndowmentType[] restrictedFrom;
    AngelCoreStruct.AccountType acctType;
    AngelCoreStruct.VaultType vaultType;
  }

  struct UpdateFeeRequest {
    AngelCoreStruct.FeeTypes feeType;
    address payout;
    uint256 rate;
  }

  struct ConfigResponse {
    uint256 version;
    address accountsContract;
    address treasury;
    // uint256 taxRate;
    // AngelCoreStruct.RebalanceDetails rebalance;
    address indexFund;
    // AngelCoreStruct.SplitDetails splitToLiquid;
    address haloToken;
    address govContract;
    address charitySharesContract;
    uint256 endowmentMultisigContract;
    // AngelCoreStruct.AcceptedTokens acceptedTokens;
    address applicationsReview;
    address uniswapRouter;
    address uniswapFactory;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
  struct Config {
    //Application review multisig
    address applicationsReview; // Endowment application review team's multisig (set as owner to start). Owner can set and change/revoke.
    address indexFundContract;
    address accountsContract;
    address treasury;
    address subdaoGovContract; // subdao gov wasm code
    address subdaoTokenContract; // subdao gov cw20 token wasm code
    address subdaoBondingTokenContract; // subdao gov bonding ve token wasm code
    address subdaoCw900Contract; // subdao gov ve-vE contract for locked token voting
    address subdaoDistributorContract; // subdao gov fee distributor wasm code
    address subdaoEmitter;
    address donationMatchContract; // donation matching contract wasm code
    address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
    address donationMatchEmitter;
    AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
    //TODO: pending check
    address haloToken; // TerraSwap HALO token addr
    address haloTokenLpContract;
    address govContract; // AP governance contract
    uint256 collectorShare;
    address charitySharesContract;
    // AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
    //PROTOCOL LEVEL
    address fundraisingContract;
    // AngelCoreStruct.RebalanceDetails rebalance;
    address uniswapRouter;
    address uniswapFactory;
    address multisigFactory;
    address multisigEmitter;
    address charityProposal;
    address lockedWithdrawal;
    address proxyAdmin;
    address usdcAddress;
    address wMaticAddress;
    address cw900lvAddress;
  }

  struct State {
    Config config;
    bytes4[] STRATEGIES;
    mapping(AngelCoreStruct.FeeTypes => AngelCoreStruct.FeeSetting) FeeSettingsByFeeType;
    mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
    mapping(address => address) PriceFeeds;
  }
}

contract Storage {
  RegistrarStorage.State state;
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

  event Transfer(IVault.VaultActionData action, uint256 amount);
  event Refund(IVault.VaultActionData action, uint256 amount);
  event Deposit(IVault.VaultActionData action);
  event Redeem(IVault.VaultActionData action, uint256 amount);
  event RewardsHarvested(IVault.VaultActionData action);
  event ErrorLogged(IVault.VaultActionData action, string message);
  event ErrorBytesLogged(IVault.VaultActionData action, bytes data);

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
  event Deposit(
    uint32 accountId,
    VaultType vaultType,
    address tokenDeposited,
    uint256 amtDeposited
  );

  /// @notice Event emited on each Redemption call
  /// @dev Upon redemption, emit this event. Index the account and staking contract for analytics
  event Redeem(uint32 accountId, VaultType vaultType, address tokenRedeemed, uint256 amtRedeemed);

  /// @notice Event emited on each Harvest call
  /// @dev Upon harvest, emit this event. Index the accounts harvested for.
  /// Rewards that are re-staked or otherwise reinvested will call other methods which will emit events
  /// with specific yield/value details
  /// @param accountIds a list of the Accounts harvested for
  event RewardsHarvested(uint32[] accountIds);

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
pragma solidity ^0.8.16;

library Array {
  function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint256(i)] < pivot) i++;
      while (pivot < arr[uint256(j)]) j--;
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, left, j);
    if (i < right) quickSort(arr, i, right);
  }

  function sort(uint256[] memory data) internal pure returns (uint256[] memory) {
    quickSort(data, int256(0), int256(data.length - 1));
    return data;
  }

  function max(uint256[] memory data) internal pure returns (uint256) {
    uint256 maxVal = data[0];
    for (uint256 i = 1; i < data.length; i++) {
      if (maxVal < data[i]) {
        maxVal = data[i];
      }
    }

    return maxVal;
  }

  // function min(uint256[] memory data) internal pure returns (uint256) {
  //     uint256 min = data[0];
  //     for (uint256 i = 1; i < data.length; i++) {
  //         if (min > data[i]) {
  //             min = data[i];
  //         }
  //     }

  //     return min;
  // }

  function indexOf(uint256[] memory arr, uint256 searchFor) internal pure returns (uint256, bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return (i, true);
      }
    }
    // not found
    return (0, false);
  }

  function remove(uint256[] storage data, uint256 index) internal returns (uint256[] memory) {
    if (index >= data.length) {
      revert("Error in remove: internal");
    }

    for (uint256 i = index; i < data.length - 1; i++) {
      data[i] = data[i + 1];
    }
    data.pop();
    return data;
  }
}

library Array32 {
  function indexOf(uint32[] memory arr, uint32 searchFor) internal pure returns (uint32, bool) {
    for (uint32 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return (i, true);
      }
    }
    // not found
    return (0, false);
  }

  function remove(uint32[] storage data, uint32 index) internal returns (uint32[] memory) {
    if (index >= data.length) {
      revert("Error in remove: internal");
    }

    for (uint32 i = index; i < data.length - 1; i++) {
      data[i] = data[i + 1];
    }
    data.pop();
    return data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

library Utils {
  function _execute(address target, uint256 value, bytes memory data) internal {
    string memory errorMessage = "call reverted without message";
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    Address.verifyCallResult(success, returndata, errorMessage);
  }
}