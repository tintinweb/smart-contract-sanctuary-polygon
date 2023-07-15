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
pragma solidity ^0.8.16;

import {IEndowmentMultiSigEmitter} from "./interfaces/IEndowmentMultiSigEmitter.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice the endowment multisig emitter contract
 * @dev the endowment multisig emitter contract is a contract that emits events for all the endowment multisigs across AP
 */
contract EndowmentMultiSigEmitter is IEndowmentMultiSigEmitter, Initializable {
  /*
   * Events
   */
  event EndowmentMultisigCreated(
    address multisigAddress,
    uint256 endowmentId,
    address emitter,
    address[] owners,
    uint256 required,
    bool requireExecution,
    uint256 transactionExpiry
  );
  event TransactionSubmitted(uint256 endowmentId, address owner, uint256 transactionId);
  event TransactionConfirmed(uint256 endowmentId, address owner, uint256 transactionId);
  event TransactionConfirmationRevoked(uint256 endowmentId, address owner, uint256 transactionId);
  event TransactionConfirmationOfFormerOwnerRevoked(
    uint256 endowmentId,
    address formerOwner,
    uint256 transactionId
  );
  event TransactionExecuted(uint256 endowmentId, uint256 transactionId);
  event OwnersAdded(uint256 endowmentId, address[] owners);
  event OwnersRemoved(uint256 endowmentId, address[] owners);
  event OwnerReplaced(uint256 endowmentId, address currOwner, address newOwner);
  event ApprovalsRequirementChanged(uint256 endowmentId, uint256 approvalsRequired);
  event RequireExecutionChanged(uint256 endowmentId, bool requireExecution);
  event ExpiryChanged(uint256 endowmentId, uint256 transactionExpiry);

  address multisigFactory;
  mapping(address => bool) isMultisig;

  function initEndowmentMultiSigEmitter(address _multisigFactory) public initializer {
    require(_multisigFactory != address(0), "Invalid Address");
    multisigFactory = _multisigFactory;
  }

  modifier isEmitter() {
    require(isMultisig[msg.sender], "Unauthorized");
    _;
  }
  modifier isOwner() {
    require(msg.sender == multisigFactory, "Not multisig factory");
    _;
  }

  /**
   * @notice emits EndowmentMultisigCreated event
   * @param multisigAddress the multisig address
   * @param endowmentId the endowment id
   * @param emitter the emitter of the multisig
   * @param owners the owners of the multisig
   * @param required the required number of signatures
   * @param requireExecution the require execution flag
   * @param transactionExpiry duration of validity for newly created transactions
   */
  function createEndowmentMultisig(
    address multisigAddress,
    uint256 endowmentId,
    address emitter,
    address[] memory owners,
    uint256 required,
    bool requireExecution,
    uint256 transactionExpiry
  ) public isOwner {
    isMultisig[multisigAddress] = true;
    emit EndowmentMultisigCreated(
      multisigAddress,
      endowmentId,
      emitter,
      owners,
      required,
      requireExecution,
      transactionExpiry
    );
  }

  /**
   * @notice emits the EndowmentSubmitted event
   * @param endowmentId the endowment id
   * @param transactionId the transaction id
   */
  function transactionSubmittedEndowment(
    uint256 endowmentId,
    address owner,
    uint256 transactionId
  ) public isEmitter {
    emit TransactionSubmitted(endowmentId, owner, transactionId);
  }

  /**
   * @notice emits the EndowmentConfirmed event
   * @param endowmentId the endowment id
   * @param owner the sender of the transaction
   * @param transactionId the transaction id
   */
  function transactionConfirmedEndowment(
    uint256 endowmentId,
    address owner,
    uint256 transactionId
  ) public isEmitter {
    emit TransactionConfirmed(endowmentId, owner, transactionId);
  }

  /**
   * @notice emits the ConfirmationRevoked event
   * @param endowmentId the endowment id
   * @param owner the sender of the transaction
   * @param transactionId the transaction id
   */
  function transactionConfirmationRevokedEndowment(
    uint256 endowmentId,
    address owner,
    uint256 transactionId
  ) public isEmitter {
    emit TransactionConfirmationRevoked(endowmentId, owner, transactionId);
  }

  /**
   * @notice emits the ConfirmationOfFormerOwnerRevoked event
   * @param endowmentId the endowment id
   * @param formerOwner the former owner being revoked
   * @param transactionId the transaction id
   */
  function transactionConfirmationOfFormerOwnerRevokedEndowment(
    uint256 endowmentId,
    address formerOwner,
    uint256 transactionId
  ) public isEmitter {
    emit TransactionConfirmationOfFormerOwnerRevoked(endowmentId, formerOwner, transactionId);
  }

  /**
   * @notice emits the TransactionExecuted event
   * @param endowmentId the endowment id
   * @param transactionId the transaction id
   */
  function transactionExecutedEndowment(
    uint256 endowmentId,
    uint256 transactionId
  ) public isEmitter {
    emit TransactionExecuted(endowmentId, transactionId);
  }

  /**
   * @notice emits the OwnersAdded event
   * @param endowmentId the endowment id
   * @param owners the added owners of the endowment
   */
  function ownersAddedEndowment(uint256 endowmentId, address[] memory owners) public isEmitter {
    emit OwnersAdded(endowmentId, owners);
  }

  /**
   * @notice emits the OwnersRemoved event
   * @param endowmentId the endowment id
   * @param owners the removed owners of the endowment
   */
  function ownersRemovedEndowment(uint256 endowmentId, address[] memory owners) public isEmitter {
    emit OwnersRemoved(endowmentId, owners);
  }

  /**
   * @notice emits the OwnerReplaced event
   * @param endowmentId the endowment id
   * @param newOwner the added owner of the endowment
   */
  function ownerReplacedEndowment(
    uint256 endowmentId,
    address currOwner,
    address newOwner
  ) public isEmitter {
    emit OwnerReplaced(endowmentId, currOwner, newOwner);
  }

  /**
   * @notice emits the ApprovalsRequirementChanged event
   * @param endowmentId the endowment id
   * @param approvalsRequired the required number of confirmations
   */
  function approvalsRequirementChangedEndowment(
    uint256 endowmentId,
    uint256 approvalsRequired
  ) public isEmitter {
    emit ApprovalsRequirementChanged(endowmentId, approvalsRequired);
  }

  /**
   * @notice emits the ApprovalsRequirementChanged event
   * @param endowmentId the endowment id
   * @param requireExecution Explicit execution step is needed
   */
  function requireExecutionChangedEndowment(
    uint256 endowmentId,
    bool requireExecution
  ) public isEmitter {
    emit RequireExecutionChanged(endowmentId, requireExecution);
  }

  /**
   * @notice emits the EndowmentTransactionExpiryChanged event
   * @param endowmentId the endowment id
   * @param transactionExpiry the duration a newly created transaction is valid for
   */
  function expiryChangedEndowment(uint256 endowmentId, uint256 transactionExpiry) public isEmitter {
    emit ExpiryChanged(endowmentId, transactionExpiry);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IEndowmentMultiSigEmitter {
  function transactionConfirmedEndowment(
    uint256 endowmentId,
    address owner,
    uint256 transactionId
  ) external;

  function transactionConfirmationRevokedEndowment(
    uint256 endowmentId,
    address owner,
    uint256 transactionId
  ) external;

  function transactionConfirmationOfFormerOwnerRevokedEndowment(
    uint256 endowmentId,
    address formerOwner,
    uint256 transactionId
  ) external;

  function transactionSubmittedEndowment(
    uint256 endowmentId,
    address owner,
    uint256 transactionId
  ) external;

  function transactionExecutedEndowment(uint256 endowmentId, uint256 transactionId) external;

  function ownersAddedEndowment(uint256 endowmentId, address[] memory owners) external;

  function ownersRemovedEndowment(uint256 endowmentId, address[] memory owners) external;

  function ownerReplacedEndowment(
    uint256 endowmentId,
    address currOwner,
    address newOwner
  ) external;

  function approvalsRequirementChangedEndowment(
    uint256 endowmentId,
    uint256 approvalsRequired
  ) external;

  function requireExecutionChangedEndowment(uint256 endowmentId, bool requireExecution) external;

  function expiryChangedEndowment(uint256 endowmentId, uint256 transactionExpiry) external;

  function createEndowmentMultisig(
    address multisigAddress,
    uint256 endowmentId,
    address emitter,
    address[] memory owners,
    uint256 required,
    bool requireExecution,
    uint256 transactionExpiry
  ) external;
}