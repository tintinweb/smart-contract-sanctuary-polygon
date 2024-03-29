// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
/**
 * @title LuckyBall Event Contract
 * @author Atomrigs Lab
 *
 * Supports ChainLink VRF_V2
 * Supports Relay transaction using EIP712 signTypedData_v4 for relay signature verification
 * Supports BeaconProxy Upgradeable pattern
 **/

pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; 

abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    function __VRFConsumerBaseV2Upgradeable_init(
        address _vrfCoordinator
    ) internal onlyInitializing {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

contract LuckyBallV2 is VRFConsumerBaseV2Upgradeable{

    uint32 private _ballId;
    uint16 private _seasonId;
    uint32 private _revealGroupId;    
    address private _owner;
    address private _operator;
    uint32 public ballCount;
    bool public revealNeeded;

    struct BallGroup {
        uint32 endBallId;
        address owner;
    }

    struct Season {
        uint16 seasonId;
        uint32 startBallId;
        uint32 endBallId;
        uint32 winningBallId;
        uint32 winningCode;
    }

    BallGroup[] public ballGroups;

    //chainlink 
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId; //= 5320; //https://vrf.chain.link/
    //address vrfCoordinator; //= 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; //Mumbai 
    bytes32 s_keyHash; // = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 constant callbackGasLimit = 400000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords =  1;
    uint256 public lastRequestId;

    struct RequestStatus {
        bool exists; // whether a requestId exists        
        bool isSeasonPick; //True if this random is for picking up the season BallId winner 
        uint256 seed;
    }
    mapping(uint256 => RequestStatus) public s_requests; // requestId --> requestStatus 
    //

    //** EIP 712 related
    bytes32 private DOMAIN_SEPARATOR;
    mapping (address => uint256) private _nonces;
    //

    mapping(uint16 => Season) public seasons;
    mapping(address => mapping(uint16 => uint32[])) public userBallGroups; //user addr => seasonId => ballGroupPos
    mapping(uint32 => uint32) public revealGroups; //ballId => revealGroupId
    mapping(uint32 => uint256) public revealGroupSeeds; // revealGroupId => revealSeed 
    mapping(address => uint32) public newRevealPos;
    //mapping(address => mapping(uint16 => uint32)) public userBallCounts; //userAddr => seasonId => count
    mapping(uint32 => uint32[]) public ballPosByRevealGroup; // revealGroupId => [ballPos]

    event BallIssued(uint16 seasonId, address indexed recipient, uint32 qty, uint32 endBallId);
    event RevealRequested(uint16 seasonId, uint32 revealGroupId, address indexed requestor);
    event SeasonStarted(uint16 seasonId);
    event SeasonEnded(uint16 seasonId);
    event CodeSeedRevealed(uint16 seasonId, uint32 revealGroupId);
    event WinnerPicked(uint16 indexed seasonId, uint32 ballId);
    event OwnerTransfered(address owner);
    event SetOperator(address operator);

    modifier onlyOperators() {
        require(_operator == msg.sender || _owner == msg.sender, "LuckyBall: caller is not the operator address!");
        _;
    } 
    modifier onlyOwner() {
        require(_owner == msg.sender, "LuckyBall: caller is not the owner address!");
        _;
    }       
/* Omitted for version 2
    function initialize(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) public initializer {
        require(_owner == address(0), "LuckyBall: already initialized"); 
        __VRFConsumerBaseV2Upgradeable_init(_vrfCoordinator);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        _owner = msg.sender;
        _setDomainSeparator(); //EIP712
        _revealGroupId++;
    }
*/
    function getVersion() public pure returns (string memory) {
        return "2";
    }

    //** EIP 712 and Relay functions
    function nonces(address _user) public view returns (uint256) {
        return _nonces[_user];
    }   

    function getDomainInfo() public view returns (string memory, string memory, uint, address) {
        string memory name = "LuckyBall_Relay";
        string memory version = getVersion();
        uint256 chainId = block.chainid;
        address verifyingContract = address(this);
        return (name, version, chainId, verifyingContract);
    }

    function getRelayMessageTypes() public pure returns (string memory) {
        string memory dataTypes = "Relay(address owner,uint256 deadline,uint256 nonce)";
        return dataTypes;      
    }

    function _setDomainSeparator() public {
        string memory EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
        ( string memory name, string memory version, uint256 chainId, address verifyingContract ) = getDomainInfo();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(abi.encodePacked(EIP712_DOMAIN_TYPE)),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                chainId,
                verifyingContract
            )
        );
    }

    function getEIP712Hash(address _user, uint256 _deadline, uint256 _nonce) public view returns (bytes32) {
        string memory MESSAGE_TYPE = getRelayMessageTypes();
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01", // backslash is needed to escape the character
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256(abi.encodePacked(MESSAGE_TYPE)),
                        _user,
                        _deadline,
                        _nonce
                    )
                )
            )
        );
        return hash;
    }

    function verifySig(address _user, uint256 _deadline, uint256 _nonce,  uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes32 hash = getEIP712Hash(_user, _deadline, _nonce);
        if (v < 27) {
          v += 27;
        }
        return _user == ecrecover(hash, v, r, s);
    }

    //**

    function transferOwner(address _newOwner) external onlyOwner {
        _owner = _newOwner;
        emit OwnerTransfered(_newOwner);
    }

    function setOperator(address _newOperator) external onlyOwner {
        _operator = _newOperator;
        emit SetOperator(_newOperator);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }    

    function getOperator() public view returns (address) {
        return _operator;
    }

    function getCurrentSeasonId() public view returns (uint16) {
        return _seasonId;
    }

    function getCurrentBallGroupPos() public view returns (uint32) {
        return uint32(ballGroups.length);
    }

    function getCurrentRevealGroupId() public view returns (uint32) {
        return _revealGroupId;
    }     

    function startSeason() external onlyOperators() {
        if (_seasonId > 0 && seasons[_seasonId].winningBallId == 0) {
            revert('LuckyBall: the current season should be ended first');
        }        
        _seasonId++;
        uint32 start;
        if (ballGroups.length == 0) {
            start = 1;    
        } else {
            start = ballGroups[getCurrentBallGroupPos()-1].endBallId + 1;
        }    
        seasons[_seasonId] = 
                Season(_seasonId, 
                        start, 
                        0, 
                        0,
                        generateWinningCode());

        emit SeasonStarted(_seasonId);
    }

    function isSeasonActive() public view returns (bool) {
        if(seasons[_seasonId].winningBallId > 0) {
            return false;
        }
        if (_seasonId == uint(0)) {
            return false;
        }
        return true;
    }    

    function issueBalls(address[] calldata _tos, uint32[] calldata _qty) external onlyOperators() {
        require(_tos.length == _qty.length, "LuckBall: address and qty counts do not match");
        require(isSeasonActive(), "LuckyBall: Season is not active");
        uint256 length = _tos.length; 
        unchecked {
            for(uint256 i=0; i<length; ++i) {
                address to = _tos[i];
                uint32 qty = _qty[i];
                require(qty > 0, "LuckyBall: qty should be bigger than 0");
                ballCount += qty;
                ballGroups.push(BallGroup(ballCount, to));
                userBallGroups[to][_seasonId].push(uint32(ballGroups.length-1));
                emit BallIssued(_seasonId, to, qty, ballCount);
            } 
        }
    }

    function getUserBallGroups(address addr, uint16 seasonId) public view returns (uint32[] memory) {
        uint32[] memory myGroups = userBallGroups[addr][seasonId];
        return myGroups;
    }    

    function getUserBallCount(address _user, uint16 seasonId_) public view returns (uint32) {
        uint32[] memory groupPos = userBallGroups[_user][seasonId_];
        uint32 count;
        uint256 length = groupPos.length;
        unchecked {
            for(uint256 i=0; i<length; ++i) {
                BallGroup memory group = ballGroups[groupPos[i]];
                uint32 start;
                //uint32 end;
                if (groupPos[i]==0) {
                    start = 0;
                } else {
                    start = ballGroups[groupPos[i]-1].endBallId; 
                }
                count += group.endBallId - start; 
            }
        }
        return count;
    }

    function ownerOf(uint32 ballId_) public view returns (address) {
        if (ballId_ == 0) {
            return address(0);
        }
        uint256 length = ballGroups.length;
        for(uint256 i=0; i < length; ++i) {
            if(ballId_ <= ballGroups[i].endBallId) {
                return ballGroups[i].owner;
            }
        }
        return address(0);
    }         

    function generateWinningCode() internal view returns (uint32) {
        return extractCode(uint256(keccak256(abi.encodePacked(blockhash(block.number -1), block.timestamp))));        
    }

    function extractCode(uint256 n) internal pure returns (uint32) {
        uint256 r = n % 1000000;
        if (r < 100000) { r += 100000; }
        return uint32(r);
    } 

    function requestReveal() external returns (bool) {
        return _requestReveal(msg.sender);
    }

    function _requestReveal(address _addr) internal returns (bool) {
        uint32[] memory myGroups = userBallGroups[_addr][_seasonId];
        uint256 myLength = myGroups.length;
        uint32 newPos = newRevealPos[_addr];
        require(myLength > 0, "LuckyBall: No balls to reveal");
        require(myLength > newPos, "LuckyBall: No new balls to reveal");
        unchecked {
            for (uint256 i=newPos; i<myLength; ++i) {
                revealGroups[myGroups[i]] = _revealGroupId;
                ballPosByRevealGroup[_revealGroupId].push(myGroups[i]);
            }          
        }  
        newRevealPos[_addr] = uint32(myLength);

        if (!revealNeeded) {
            revealNeeded = true;
        }
        emit RevealRequested(_seasonId, _revealGroupId, _addr);
        return false;
    }

    function getRevealGroup(uint32 ballId_) public view returns (uint32) {
        return revealGroups[getBallGroupPos(ballId_)];
    }

    function getBallGroupPos(uint32 ballId_) public view returns (uint32) {
        uint32 groupLength = uint32(ballGroups.length);
        require (ballId_ > 0 && ballId_ <= ballCount, "LuckyBall: ballId is out of range");
        require (groupLength > 0, "LuckyBall: No ball issued");
        unchecked {
            for (uint32 i=groupLength-1; i >= 0; --i) {
                uint32 start;
                if (i == 0) {
                    start = 1;
                } else {
                    start = ballGroups[i-1].endBallId + 1;
                }
                uint32 end = ballGroups[i].endBallId;

                if (ballId_ <= end && ballId_ >= start) {
                    return i;
                }
                continue;
            }
        }
        revert("LuckyBall: BallId is not found");
    } 

    function getBallCode(uint32 ballId_) public view returns (uint32) {
        uint256 randSeed = revealGroupSeeds[getRevealGroup(ballId_)];
        if (randSeed > 0) {
            return extractCode(uint(keccak256(abi.encodePacked(randSeed, ballId_))));
        }
        return uint32(0);
    }

    function getBalls(address addr, uint16 seasonId) public view returns (uint32[] memory) {
        uint32[] memory myGroups = userBallGroups[addr][seasonId];
        uint32[] memory ballIds = new uint32[](getUserBallCount(addr, seasonId));

        uint256 pos = 0;
        unchecked {
            for (uint256 i=0; i < myGroups.length; ++i) {
                uint32 end = ballGroups[myGroups[i]].endBallId;
                uint32 start;
                if (myGroups[i] == 0) {
                    start = 1;    
                } else {
                    start = ballGroups[myGroups[i] - 1].endBallId + 1;
                }
                for (uint32 j=start; j<=end; ++j) {
                    ballIds[pos] = j;
                    ++pos;
                }                           
            }
        }
        return ballIds;
    }

    function getBalls() public view returns(uint32[] memory) {
        return getBalls(msg.sender, _seasonId);
    }

    function getBallsByRevealGroup(uint32 revealGroupId) public view returns (uint32[] memory) {
        uint32[] memory ballPos = ballPosByRevealGroup[revealGroupId];
        uint256 posLength = ballPos.length;
        uint32 groupBallCount;
        unchecked {
            for (uint256 i=0; i < posLength; i++) {
                uint32 start;
                uint32 end = ballGroups[ballPos[i]].endBallId;
                if (ballPos[i] == 0) {
                    start = 1;
                } else {
                    start = ballGroups[ballPos[i] - 1].endBallId + 1; 
                }
                groupBallCount += (end - start + 1);
            }
            uint32[] memory ballIds = new uint32[](groupBallCount);
            uint256 pos = 0;
            for (uint256 i=0; i < posLength; i++) {
                uint32 end = ballGroups[ballPos[i]].endBallId;            
                uint32 start;
                if (ballPos[i] == 0) {
                    start = 1;
                } else {
                    start = ballGroups[ballPos[i] - 1].endBallId + 1; 
                }
                for (uint32 j=start; j <= end; j++) {
                    ballIds[pos] = j;
                    pos++;
                }
            }
            return ballIds;
        }
    }

    function relayRequestReveal(        
        address user,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) 
        public returns (bool) {

        require(deadline >= block.timestamp, "LuckyBall: expired deadline");
        require(verifySig(user, deadline, _nonces[user], v, r, s), "LuckyBall: user sig does not match");
        
        _requestReveal(user);
        _nonces[user]++;
        return true;
    }

    function relayRequestRevealBatch(
        address[] calldata users,
        uint256[] calldata deadlines,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss) 
        public returns(bool) {
        uint256 length = users.length;
        for(uint256 i=0; i<length; i++) {
            relayRequestReveal(users[i],deadlines[i], vs[i], rs[i], ss[i]);
        }
        return true;
    }

    function endSeason() external onlyOperators() returns (bool) {
        require(ballGroups.length > 0, "LuckyBall: No balls issued yet");
        if (revealNeeded) {
            requestRevealGroupSeed();
        }
        seasons[_seasonId].endBallId = ballGroups[ballGroups.length-1].endBallId;
        requestRandomSeed(true); 
        return true;
    }

    function requestRevealGroupSeed() public onlyOperators() returns (uint256) {
        if (revealNeeded) {
            return requestRandomSeed(false);
        } else {
            return uint256(0);      
        }
    }

    function setRevealGroupSeed(uint256 randSeed) internal {
        revealGroupSeeds[_revealGroupId] = randSeed;
        emit CodeSeedRevealed(_seasonId, _revealGroupId);
        revealNeeded = false;        
        _revealGroupId++;
    }

    function requestRandomSeed(bool _isSeasonPick) internal returns (uint256) {
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        lastRequestId = requestId;
        s_requests[requestId] = RequestStatus(true, _isSeasonPick, 0);
        return requestId;    
    }

    function setSeasonWinner(uint256 randSeed) internal {
        Season storage season = seasons[_seasonId];
        uint256 seasonBallCount = uint256(season.endBallId - season.startBallId + 1);
        season.winningBallId = season.startBallId + uint32(randSeed % seasonBallCount);
        emit WinnerPicked(_seasonId, season.winningBallId); 
        emit SeasonEnded(_seasonId);
    }    

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 seed =  uint(keccak256(abi.encodePacked(randomWords[0], block.timestamp)));
        s_requests[requestId].seed = seed;
        if (s_requests[requestId].isSeasonPick) {
            setSeasonWinner(seed);
        } else {
            setRevealGroupSeed(seed);
        }
    }
}