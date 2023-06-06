// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

interface IRandomiserCallback {
    /// @notice Receive random words from a randomiser.
    /// @dev Ensure that proper access control is enforced on this function;
    ///     only the designated randomiser may call this function and the
    ///     requestId should be as expected from the randomness request.
    /// @param requestId The identifier for the original randomness request
    /// @param randomWords An arbitrary array of random numbers
    function receiveRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

interface IRandomiserGen2 {
    function getRandomNumber(
        address callbackContract,
        uint32 callbackGasLimit,
        uint16 minConfirmations
    ) external payable returns (uint256 requestId);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {ChainlinkVRFV2Randomiser} from "../randomisers/ChainlinkVRFV2Randomiser.sol";

interface IRandomProvider {
    /// @notice Compute the required ETH to get a random number
    /// @param callbackGasLimit Gas limit to use for callback
    function computeRandomNumberRequestCost(uint32 callbackGasLimit)
        external
        view
        returns (uint256);

    /// @notice Get a random number from
    /// @param callbackGasLimit Gas limit to use for callback
    /// @param minBlocksToWait Minimum confirmations to wait
    function getRandomNumber(uint32 callbackGasLimit, uint16 minBlocksToWait)
        external
        payable
        returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
/**
    The MIT License (MIT)

    Copyright (c) 2018 SmartContract ChainLink, Ltd.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

pragma solidity ^0.8;

abstract contract TypeAndVersion {
    function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
//
// This file is part of the RaffleChef family of contracts, by Fairy, Inc. and
// is made available under Business Source License 1.1.
//
// ----------------------------------------------------------------------------
//
// Parameters
//
// Licensor:             Fairy, Inc.
//
// Licensed Work:        RaffleChef
//                       The Licensed Work is (c) 2023 Fairy, Inc.
//
// Additional Use Grant: Any uses listed and defined at
//                       rafflechef-additional-use-grant.fairydev.eth
//
// Change Date:          The earlier of 2027-02-16 or a date specified at
//                       rafflechef-change-date.fairydev.eth
//
// Change License:       GNU General Public License v2.0 or later
//
// ----------------------------------------------------------------------------
//
pragma solidity 0.8.18;

// solhint-disable not-rely-on-time

import {TypeAndVersion} from "./interfaces/TypeAndVersion.sol";
import {IRandomiserCallback} from "./interfaces/IRandomiserCallback.sol";
import {IRandomProvider} from "./interfaces/IRandomProvider.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PrizeDistributor} from "./util/PrizeDistributor.sol";
import {FeistelShuffleOptimised} from "./util/FeistelShuffleOptimised.sol";

/// @title NFTHolderRaffle
/// @author kevincharm
/// @notice Performs a raffle with the participants being holders of an ERC-721
///     token. This contract also serves as a prize distributor. The owner of
///     the raffle may load ERC-721, ERC-1155 and/or ERC-20 tokens onto this
///     contract as claimable prizes.
///     There is ***no practical limit*** on the number of prizes/raffle
///     winners you can draw; it will always cost the raffler a ~constant
///     amount of gas to execute the raffle & draw all winners.
///     The winner(s) must claim their prize(s) by calling the `claim` function
///     on this contract (same process as claiming an airdrop).
/// @dev Assumptions about the ERC-721 contract being consumed:
///     - Contract implements the {IERC721Enumerable-totalSupply} function
///     - Contract mints tokenIds sequentially starting from tokenId 0 or 1
contract NFTHolderRaffle is
    IRandomiserCallback,
    TypeAndVersion,
    OwnableUpgradeable,
    PrizeDistributor
{
    /// @notice Randomiser
    address public randomiser;
    /// @notice FairyRaffleFactory
    address public factory;

    /// @notice ERC-721 contract whose token holders are the participants of
    ///     this raffle.
    address public participantsNFTContract;
    /// @notice Starting token ID of the NFT contract. Conventionally, this is
    ///     1, but some NFT contracts start minting at tokenId 0.
    uint256 public startingTokenId;
    /// @notice Timestamp of when the raffle can be rolled
    uint256 public raffleActivationTimestamp;
    /// @notice Number of raffle participants
    uint256 public nParticipants;
    /// @notice Minimum blocks to wait until a VRF request can be fulfilled
    uint16 public minBlocksToWait;

    /// @notice The requestId returned by the randomiser
    uint256 public requestId;
    /// @notice The randomness received from the random provider.
    uint256 public randomness;
    /// @notice Callback gas limit for receiving random numbers
    uint32 public constant CALLBACK_GAS_LIMIT = 500_000;
    /// @notice Feistel rounds
    uint256 public constant FEISTEL_ROUNDS = 4;

    /// @notice Minimum period that must be awaited before a reroll is possible
    /// @dev NB: 24h is the period for which a VRF request can stay pending
    uint256 public constant MINIMUM_REROLL_PERIOD = 24 hours;
    /// @notice Last time a random number was requested
    uint256 public lastRolledAt;

    error Uninitialised();
    error RerollNotYetPossible(uint256 secondsLeft);
    error AlreadyFinalised(uint256 randomness);
    error CallerNotRandomProvider(
        address caller,
        address expectedRandomProvider
    );
    error NotRolledYet();
    error RequestIdMismatch(
        uint256 receivedRequestId,
        uint256 expectedRequestId
    );
    error NotFinalised();
    error InvalidNumberOfWinners(uint256 participants, uint256 winners);
    error InvalidNFTContract();
    error InvalidStartingTokenId();
    error TokenIdExcluded(
        uint256 nParticipants,
        uint256 startingTokenId,
        uint256 tokenId
    );
    error ClaimerNotTokenHolder(
        address claimooor,
        address nftContract,
        uint256 tokenId
    );
    error NotAWinner(uint256 place);

    constructor() {
        _disableInitializers();
    }

    function typeAndVersion() external pure override returns (string memory) {
        return "NFTHolderRaffle 1.0.0";
    }

    /// @notice Commit to a participants list and start the raffle by
    ///     requesting a random number from drand.
    /// @dev Assumes this is called by the factory.
    /// @param minBlocksToWait_ How many (minimum) block confirmations before
    ///     the VRF
    function init(
        address randomiser_,
        address participantsNFTContract_,
        uint16 minBlocksToWait_,
        uint256 raffleActivationTimestamp_,
        uint256 prizeExpiryTimestamp_
    ) public payable initializer {
        __Ownable_init();

        // Ensure activation & expiry time are valid
        bool isActivationInThePast = raffleActivationTimestamp_ <=
            block.timestamp;
        bool isActivationOnOrAfterExpiry = raffleActivationTimestamp_ >=
            prizeExpiryTimestamp_;
        bool isClaimDurationTooShort = raffleActivationTimestamp_ + 1 hours >
            prizeExpiryTimestamp_;
        if (
            isActivationInThePast ||
            isActivationOnOrAfterExpiry ||
            isClaimDurationTooShort
        ) {
            revert InvalidTimestamp(raffleActivationTimestamp_);
        }
        raffleActivationTimestamp = raffleActivationTimestamp_;
        __PrizeDistributor_init(prizeExpiryTimestamp_);

        // Randomiser stuff
        randomiser = randomiser_;
        minBlocksToWait = minBlocksToWait_;

        if (participantsNFTContract_ == address(0)) {
            revert InvalidNFTContract();
        }
        // Figure out the starting tokenId (used as the offset for shuffling)
        if (_safeGetOwnerOf(participantsNFTContract_, 1) != address(0)) {
            // This case is most likely
            startingTokenId = 1;
        } else if (_safeGetOwnerOf(participantsNFTContract_, 0) != address(0)) {
            // Nothing to do; this is at zero by default anyway
            // startingTokenId = 0;
        } else {
            revert InvalidStartingTokenId();
        }
        participantsNFTContract = participantsNFTContract_;

        factory = msg.sender;
    }

    /// @notice Invoke NFT.ownerOf(<tokenId>) without reverting
    /// @return address of owner if it exists, otherwise zero address
    function _safeGetOwnerOf(address nftContract, uint256 tokenId)
        internal
        view
        returns (address)
    {
        try IERC721Enumerable(nftContract).ownerOf(tokenId) returns (
            address tokenOwner
        ) {
            return tokenOwner;
        } catch {
            return address(0);
        }
    }

    /// @notice Is raffle ready for activation? Ready for activation means that
    ///     a random number can be requested/rolled.
    function isReadyForActivation() public view returns (bool) {
        return block.timestamp >= raffleActivationTimestamp;
    }

    /// @dev Assert that the raffle is ready for activation
    function _assertReadyForActivation() internal view {
        if (!isReadyForActivation()) {
            revert RaffleActivationPending(
                raffleActivationTimestamp - block.timestamp
            );
        }
    }

    /// @notice Is raffle finalised? Finalised means a random number has been
    ///     received from the random provider and winners should be able to
    ///     claim their prizes.
    function isFinalised() public view returns (bool) {
        return randomness != 0;
    }

    /// @dev Assert that the raffle has not been finalised
    function _assertNotFinalised() internal view {
        if (isFinalised()) {
            revert AlreadyFinalised(randomness);
        }
    }

    /// @dev Assert that the raffle has been finalised
    function _assertFinalised() internal view {
        if (!isFinalised()) {
            revert NotFinalised();
        }
    }

    /// @notice Record the number of participants that will be included in the
    ///     raffle.
    function _freezeParticipants() internal {
        address participantsNFTContract_ = participantsNFTContract;
        IERC721Enumerable nftContract = IERC721Enumerable(
            participantsNFTContract_
        );
        // Get # of participants from total supply of ERC-721
        uint256 nParticipants_ = nftContract.totalSupply();
        nParticipants = nParticipants_;
    }

    /// @notice Roll a random number. This function can be invoked by anyone,
    ///     as long as the raffle is ready for activation.
    function roll() external payable {
        _assertReadyForActivation();
        _assertNotFinalised();
        if (block.timestamp - lastRolledAt <= MINIMUM_REROLL_PERIOD) {
            revert RerollNotYetPossible(lastRolledAt + MINIMUM_REROLL_PERIOD);
        }
        lastRolledAt = block.timestamp;
        _freezeParticipants();
        requestId = IRandomProvider(factory).getRandomNumber{value: msg.value}(
            500_000,
            minBlocksToWait
        );
    }

    /// @notice See {IRandomiserCallback-receiveRandomWords}
    function receiveRandomWords(
        uint256 requestId_,
        uint256[] calldata randomWords
    ) external {
        if (msg.sender != randomiser) {
            revert CallerNotRandomProvider(msg.sender, randomiser);
        }
        uint256 rid = requestId;
        if (rid == 0) {
            revert NotRolledYet();
        }
        if (requestId_ != rid) {
            revert RequestIdMismatch(requestId_, rid);
        }
        _assertNotFinalised();
        randomness = randomWords[0];
    }

    /// @notice Get the token ID of the nth winner
    /// @param n 0-indexed winning place to compute
    /// @return tokenId of winner at nth place
    function getWinningTokenId(uint256 n) public view returns (uint256) {
        _assertFinalised();
        return
            startingTokenId +
            FeistelShuffleOptimised.deshuffle(
                n,
                nParticipants,
                randomness,
                FEISTEL_ROUNDS
            );
    }

    /// @notice Get a paginated list of winning token IDs
    /// @param offset Winner index to start slice at (0-based)
    /// @param limit How many winning token IDs to fetch at maximum (may return
    ///     fewer)
    function getWinningTokenIdsPaginated(uint256 offset, uint256 limit)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        _assertFinalised();
        uint256 len = getPrizeCount();
        if (len == 0 || offset >= len) {
            return new uint256[](0);
        }
        limit = offset + limit >= len ? len - offset : limit;
        tokenIds = new uint256[](limit);
        uint256 startingTokenId_ = startingTokenId;
        uint256 nParticipants_ = nParticipants;
        uint256 randomness_ = randomness;
        for (uint256 i; i < limit; ++i) {
            tokenIds[i] =
                startingTokenId_ +
                FeistelShuffleOptimised.deshuffle(
                    offset + i,
                    nParticipants_,
                    randomness_,
                    FEISTEL_ROUNDS
                );
        }
    }

    /// @notice Query whether or not `tokenId` is a winner (and the draw #)
    /// @param tokenId Token ID to query
    function isWinner(uint256 tokenId) external view returns (bool, uint256) {
        _assertFinalised();
        uint256 xPrime = FeistelShuffleOptimised.shuffle(
            tokenId - startingTokenId,
            nParticipants,
            randomness,
            FEISTEL_ROUNDS
        );
        return (xPrime < getPrizeCount(), xPrime);
    }

    /// @notice Claim a prize and transfer it to the (current) token holder.
    /// @param claimooor The recipient of the prize; also must be the current
    ///     token holder of `tokenId`.
    /// @param tokenId Token ID used as an entry ticket to the raffle.
    function claim(address claimooor, uint256 tokenId) external {
        _assertFinalised();

        IERC721Enumerable nftContract = IERC721Enumerable(
            participantsNFTContract
        );
        if (nftContract.ownerOf(tokenId) != claimooor) {
            // The current holder of the token is the participant; not
            // necessarily the caller or the original token holder.
            revert ClaimerNotTokenHolder(
                claimooor,
                address(nftContract),
                tokenId
            );
        }
        uint256 startingTokenId_ = startingTokenId;
        uint256 nParticipants_ = nParticipants;
        if (tokenId - startingTokenId_ >= nParticipants_) {
            // Token ID was not a participant when the raffle was committed
            revert TokenIdExcluded(nParticipants_, startingTokenId_, tokenId);
        }

        // tokenId is a winner iff x' < nWinners holds
        uint256 xPrime = FeistelShuffleOptimised.shuffle(
            tokenId - startingTokenId_,
            nParticipants_,
            randomness,
            FEISTEL_ROUNDS
        );
        if (xPrime >= getPrizeCount()) {
            revert NotAWinner(xPrime);
        }

        _claim(xPrime, claimooor);
    }

    /// @notice See {PrizeDistributor-addERC20Prize}
    function addERC20Prize(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        _addERC20Prize(tokenAddress, msg.sender, amount);
    }

    /// @notice See {PrizeDistributor-addERC20UniformPrizes}
    function addERC20UniformPrizes(
        address tokenAddress,
        uint256 amount,
        uint256 n
    ) external onlyOwner {
        _addERC20UniformPrizes(tokenAddress, msg.sender, amount, n);
    }

    /// @notice See {PrizeDistributor-addERC721Prize}
    function addERC721Prize(address nftContract, uint256 tokenId)
        external
        onlyOwner
    {
        _addERC721Prize(nftContract, msg.sender, tokenId);
    }

    /// @notice See {PrizeDistributor-addERC1155Prize}
    function addERC1155Prize(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _addERC1155Prize(nftContract, msg.sender, tokenId, amount);
    }

    /// @notice See {PrizeDistributor-addERC1155SequentialPrizes}
    function addERC1155SequentialPrizes(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _addERC1155SequentialPrizes(nftContract, msg.sender, tokenId, amount);
    }

    /// @notice See {PrizeDistributor-withdrawERC20}
    function withdrawERC20(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        _withdrawERC20(tokenAddress, amount);
    }

    /// @notice See {PrizeDistributor-withdrawERC721}
    function withdrawERC721(address nftContract, uint256 tokenId)
        external
        onlyOwner
    {
        _withdrawERC721(nftContract, tokenId);
    }

    /// @notice See {PrizeDistributor-withdrawERC1155}
    function withdrawERC1155(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _withdrawERC1155(nftContract, tokenId, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import {IRandomiserGen2} from "../interfaces/IRandomiserGen2.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {Authorised} from "../util/Authorised.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";

/// @title ChainlinkVRFV2Randomiser
/// @author kevincharm
/// @notice Consume Chainlink's subscription-managed VRFv2 wrapper to return a
///     random number.
/// @dev NB: Not audited.
contract ChainlinkVRFV2Randomiser is
    IRandomiserGen2,
    TypeAndVersion,
    Authorised,
    VRFConsumerBaseV2
{
    /// --- VRF SHIT ---
    /// @notice VRF Coordinator (V2)
    /// @dev https://docs.chain.link/vrf/v2/subscription/supported-networks
    address public immutable vrfCoordinator;
    /// @notice LINK token (make sure it's the ERC-677 one)
    /// @dev PegSwap: https://pegswap.chain.link
    address public immutable linkToken;
    /// @notice LINK token unit
    uint256 public immutable juels;
    /// @dev VRF Coordinator LINK premium per request
    uint256 public immutable linkPremium;
    /// @notice Each gas lane has a different key hash; each gas lane
    ///     determines max gwei that will be used for the callback
    bytes32 public immutable gasLaneKeyHash;
    /// @notice Max gas price for gas lane used in gasLaneKeyHash
    /// @dev This is used purely for gas estimation
    uint256 public immutable gasLaneMaxWei;
    /// @notice Absolute gas limit for callbacks
    uint32 public immutable callbackGasLimit;
    /// @notice VRF subscription ID; created during deployment
    uint64 public immutable subId;

    /// @notice requestId => contract to callback
    /// @dev contract must implement IRandomiserCallback
    mapping(uint256 => address) public callbackTargets;

    event RandomNumberRequested(uint256 indexed requestId);
    event RandomNumberFulfilled(uint256 indexed requestId, uint256 randomness);

    error InvalidFeedConfig(address feed, uint8 decimals);
    error InvalidFeedAnswer(
        int256 price,
        uint256 latestRoundId,
        uint256 updatedAt
    );

    constructor(
        address vrfCoordinator_,
        address linkToken_,
        uint256 linkPremium_,
        bytes32 gasLaneKeyHash_,
        uint256 gasLaneMaxWei_,
        uint32 callbackGasLimit_,
        uint64 subId_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        vrfCoordinator = vrfCoordinator_;
        linkToken = linkToken_;
        juels = 10**LinkTokenInterface(linkToken_).decimals();
        linkPremium = linkPremium_;
        gasLaneKeyHash = gasLaneKeyHash_;
        gasLaneMaxWei = gasLaneMaxWei_;
        callbackGasLimit = callbackGasLimit_;
        // NB: This contract must be added as a consumer to this subscription
        subId = subId_;
    }

    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "ChainlinkVRFV2Randomiser 2.0.0";
    }

    /// @notice Request a random number
    /// @param callbackContract Target contract to callback with random numbers
    /// @param minConfirmations Number of block confirmations to wait.
    function getRandomNumber(
        address callbackContract,
        uint32, /** callbackGasLimit */
        uint16 minConfirmations
    ) public payable override onlyAuthorised returns (uint256 requestId) {
        requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                gasLaneKeyHash,
                subId,
                minConfirmations,
                callbackGasLimit,
                1
            );
        callbackTargets[requestId] = callbackContract;
        emit RandomNumberRequested(requestId);
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness)
        internal
        override
    {
        address target = callbackTargets[requestId];
        delete callbackTargets[requestId];
        IRandomiserCallback(target).receiveRandomWords(requestId, randomness);
        emit RandomNumberFulfilled(requestId, randomness[0]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

/// @title Authorised
/// @notice Restrict functions to whitelisted admins with the `onlyAdmin`
///     modifier. Deployer of contract is automatically added as an admin.
contract Authorised {
    /// @notice Whitelisted admins
    mapping(address => bool) public isAuthorised;

    error NotAuthorised(address culprit);

    constructor() {
        isAuthorised[msg.sender] = true;
    }

    /// @notice Restrict function to whitelisted admins only
    modifier onlyAuthorised() {
        if (!isAuthorised[msg.sender]) {
            revert NotAuthorised(msg.sender);
        }
        _;
    }

    /// @notice Set authorisation of a specific account
    /// @param toggle `true` to authorise account as an admin
    function authorise(address guy, bool toggle) public onlyAuthorised {
        isAuthorised[guy] = toggle;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

/// @title FeistelShuffleOptimised
/// @author kevincharm
/// @notice Feistel shuffle implemented in Yul.
library FeistelShuffleOptimised {
    error InvalidInputs(
        uint256 x,
        uint256 domain,
        uint256 seed,
        uint256 rounds
    );

    /// @notice Compute a Feistel shuffle mapping for index `x`
    /// @param x index of element in the list
    /// @param domain Number of elements in the list
    /// @param seed Random seed; determines the permutation
    /// @param rounds Number of Feistel rounds to perform
    /// @return resulting shuffled index
    function shuffle(
        uint256 x,
        uint256 domain,
        uint256 seed,
        uint256 rounds
    ) internal pure returns (uint256) {
        // (domain != 0): domain must be non-zero (value of 1 also doesn't really make sense)
        // (xPrime < domain): index to be permuted must lie within the domain of [0, domain)
        // (rounds is even): we only handle even rounds to make the code simpler
        if (domain == 0 || x >= domain || rounds & 1 == 1) {
            revert InvalidInputs(x, domain, seed, rounds);
        }

        assembly {
            // Calculate sqrt(s) using Babylonian method
            function sqrt(s) -> z {
                switch gt(s, 3)
                // if (s > 3)
                case 1 {
                    z := s
                    let r := add(div(s, 2), 1)
                    for {

                    } lt(r, z) {

                    } {
                        z := r
                        r := div(add(div(s, r), r), 2)
                    }
                }
                default {
                    if and(not(iszero(s)), 1) {
                        // else if (s != 0)
                        z := 1
                    }
                }
            }

            // nps <- nextPerfectSquare(domain)
            let sqrtN := sqrt(domain)
            let nps
            switch eq(exp(sqrtN, 2), domain)
            case 1 {
                nps := domain
            }
            default {
                let sqrtN1 := add(sqrtN, 1)
                // pre-check for square overflow
                if gt(sqrtN1, sub(exp(2, 128), 1)) {
                    // overflow
                    revert(0, 0)
                }
                nps := exp(sqrtN1, 2)
            }
            // h <- sqrt(nps)
            let h := sqrt(nps)
            // Allocate scratch memory for inputs to keccak256
            let packed := mload(0x40)
            mstore(0x40, add(packed, 0x80)) // 128B
            // When calculating hashes for Feistel rounds, seed and domain
            // do not change. So we can set them here just once.
            mstore(add(packed, 0x40), seed)
            mstore(add(packed, 0x60), domain)
            // Loop until x < domain
            for {

            } 1 {

            } {
                let L := mod(x, h)
                let R := div(x, h)
                // Loop for desired number of rounds
                for {
                    let i := 0
                } lt(i, rounds) {
                    i := add(i, 1)
                } {
                    // Load R and i for next keccak256 round
                    mstore(packed, R)
                    mstore(add(packed, 0x20), i)
                    // roundHash <- keccak256([R, i, seed, domain])
                    let roundHash := keccak256(packed, 0x80)
                    // nextR <- (L + roundHash) % h
                    let nextR := mod(add(L, roundHash), h)
                    L := R
                    R := nextR
                }
                // x <- h * R + L
                x := add(mul(h, R), L)
                if lt(x, domain) {
                    break
                }
            }
        }
        return x;
    }

    /// @notice Compute the inverse Feistel shuffle mapping for the shuffled
    ///     index `xPrime`
    /// @param xPrime shuffled index of element in the list
    /// @param domain Number of elements in the list
    /// @param seed Random seed; determines the permutation
    /// @param rounds Number of Feistel rounds that was performed in the
    ///     original shuffle.
    /// @return resulting shuffled index
    function deshuffle(
        uint256 xPrime,
        uint256 domain,
        uint256 seed,
        uint256 rounds
    ) internal pure returns (uint256) {
        // (domain != 0): domain must be non-zero (value of 1 also doesn't really make sense)
        // (xPrime < domain): index to be permuted must lie within the domain of [0, domain)
        // (rounds is even): we only handle even rounds to make the code simpler
        if (domain == 0 || xPrime >= domain || rounds & 1 == 1) {
            revert InvalidInputs(xPrime, domain, seed, rounds);
        }

        assembly {
            // Calculate sqrt(s) using Babylonian method
            function sqrt(s) -> z {
                switch gt(s, 3)
                // if (s > 3)
                case 1 {
                    z := s
                    let r := add(div(s, 2), 1)
                    for {

                    } lt(r, z) {

                    } {
                        z := r
                        r := div(add(div(s, r), r), 2)
                    }
                }
                default {
                    if and(not(iszero(s)), 1) {
                        // else if (s != 0)
                        z := 1
                    }
                }
            }

            // nps <- nextPerfectSquare(domain)
            let sqrtN := sqrt(domain)
            let nps
            switch eq(exp(sqrtN, 2), domain)
            case 1 {
                nps := domain
            }
            default {
                let sqrtN1 := add(sqrtN, 1)
                // pre-check for square overflow
                if gt(sqrtN1, sub(exp(2, 128), 1)) {
                    // overflow
                    revert(0, 0)
                }
                nps := exp(sqrtN1, 2)
            }
            // h <- sqrt(nps)
            let h := sqrt(nps)
            // Allocate scratch memory for inputs to keccak256
            let packed := mload(0x40)
            mstore(0x40, add(packed, 0x80)) // 128B
            // When calculating hashes for Feistel rounds, seed and domain
            // do not change. So we can set them here just once.
            mstore(add(packed, 0x40), seed)
            mstore(add(packed, 0x60), domain)
            // Loop until x < domain
            for {

            } 1 {

            } {
                let L := mod(xPrime, h)
                let R := div(xPrime, h)
                // Loop for desired number of rounds
                for {
                    let i := 0
                } lt(i, rounds) {
                    i := add(i, 1)
                } {
                    // Load L and i for next keccak256 round
                    mstore(packed, L)
                    mstore(add(packed, 0x20), sub(sub(rounds, i), 1))
                    // roundHash <- keccak256([L, rounds - i - 1, seed, domain])
                    // NB: extra arithmetic to avoid underflow
                    let roundHash := mod(keccak256(packed, 0x80), h)
                    // nextL <- (R - roundHash) % h
                    // NB: extra arithmetic to avoid underflow
                    let nextL := mod(sub(add(R, h), roundHash), h)
                    R := L
                    L := nextL
                }
                // x <- h * R + L
                xPrime := add(mul(h, R), L)
                if lt(xPrime, domain) {
                    break
                }
            }
        }
        return xPrime;
    }
}

// SPDX-License-Identifier: BUSL-1.1
//
// This file is part of the RaffleChef family of contracts, by Fairy, Inc. and
// is made available under Business Source License 1.1.
//
// ----------------------------------------------------------------------------
//
// Parameters
//
// Licensor:             Fairy, Inc.
//
// Licensed Work:        RaffleChef
//                       The Licensed Work is (c) 2023 Fairy, Inc.
//
// Additional Use Grant: Any uses listed and defined at
//                       rafflechef-additional-use-grant.fairydev.eth
//
// Change Date:          The earlier of 2027-02-16 or a date specified at
//                       rafflechef-change-date.fairydev.eth
//
// Change License:       GNU General Public License v2.0 or later
//
// ----------------------------------------------------------------------------
//
pragma solidity 0.8.18;

// solhint-disable not-rely-on-time
// solhint-disable no-inline-assembly
// solhint-disable func-name-mixedcase

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title PrizeDistributor
/// @author kevincharm
/// @notice This contract records and enables distribution of prizes after the
///     activation timestamp has passed.
///     Most of the functions here are internal functions. The inheriting
///     contract MUST implement function(s) that call:
///         __PrizeDistributor_init
///         _claim
///         _withdrawERC20
///         _withdrawERC721
///         _withdrawERC1155
///     and optionally implement function(s) that call:
///         _addERC20Prize
///         _addERC20UniformPrizes
///         _addERC721Prize
///         _addERC1155Prize
///         _addERC1155SequentialPrizes
contract PrizeDistributor is IERC721Receiver, IERC1155Receiver, Initializable {
    using SafeERC20 for ERC20;

    /// @notice Type of prize
    enum PrizeType {
        ERC721,
        ERC1155,
        ERC20
    }

    /// @notice Array of bytes representing prize data
    bytes[] private prizes;

    /// @notice The block timestamp after which the owner may reclaim the
    ///     prizes from this contract. CANNOT be changed after initialisation.
    uint256 public prizeExpiryTimestamp;

    /// @notice Prize index => claimed by address
    mapping(uint256 => address) public claimooors;

    event Claimed(address claimooor, uint256 prizeIndex, bytes rawPrizeData);
    event ERC20Received(address tokenAddress, uint256 amount);
    event ERC721Received(address nftContract, uint256 tokenId);
    event ERC1155Received(address nftContract, uint256 tokenId, uint256 amount);
    event ERC20Reclaimed(address tokenAddress, uint256 amount);
    event ERC721Reclaimed(address nftContract, uint256 tokenId);
    event ERC1155Reclaimed(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    );

    error InvalidPrizeType(uint8 prizeType);
    error InvalidTimestamp(uint256 timestamp);
    error RaffleActivationPending(uint256 secondsLeft);
    error PrizeExpiryTimestampPending(uint256 secondsLeft);
    error PrizeExpired();
    error InvalidRecipient();
    error AlreadyClaimed(uint256 prizeIndex);

    function __PrizeDistributor_init(uint256 prizeExpiryTimestamp_)
        public
        onlyInitializing
    {
        prizeExpiryTimestamp = prizeExpiryTimestamp_;
    }

    /// @notice {IERC165-supportsInterface}
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /// @notice Revert if raffle has not passed its deadline
    modifier onlyAfterExpiry() {
        if (!isPrizeExpired()) {
            revert PrizeExpiryTimestampPending(
                prizeExpiryTimestamp - block.timestamp
            );
        }
        _;
    }

    modifier onlyBeforeExpiry() {
        if (isPrizeExpired()) {
            revert PrizeExpired();
        }
        _;
    }

    function isPrizeExpired() public view returns (bool) {
        return block.timestamp >= prizeExpiryTimestamp;
    }

    /// @notice Claim/transfer a prize to a recipient
    /// @param prizeIndex Index of the prize in the prizes array
    /// @param recipient The address to transfer the prize to
    function _claim(uint256 prizeIndex, address recipient)
        internal
        onlyBeforeExpiry
    {
        if (recipient == address(0)) {
            revert InvalidRecipient();
        }
        if (claimooors[prizeIndex] != address(0)) {
            revert AlreadyClaimed(prizeIndex);
        }
        claimooors[prizeIndex] = recipient;

        // Decode the prize & transfer it to the recipient
        bytes memory rawPrize = prizes[prizeIndex];
        PrizeType prizeType = _getPrizeType(rawPrize);
        if (prizeType == PrizeType.ERC721) {
            (address nftContract, uint256 tokenId) = _getERC721Prize(rawPrize);
            IERC721(nftContract).safeTransferFrom(
                address(this),
                recipient,
                tokenId
            );
        } else if (prizeType == PrizeType.ERC1155) {
            (
                address nftContract,
                uint256 tokenId,
                uint256 amount
            ) = _getERC1155Prize(rawPrize);
            IERC1155(nftContract).safeTransferFrom(
                address(this),
                recipient,
                tokenId,
                amount,
                bytes("")
            );
        } else {
            // if (prizeType == PrizeType.ERC20)
            (address tokenAddress, uint256 amount) = _getERC20Prize(rawPrize);
            ERC20(tokenAddress).safeTransfer(recipient, amount);
        }

        emit Claimed(recipient, prizeIndex, rawPrize);
    }

    /// @notice Add an ERC-20 token as the next prize.
    /// @param tokenAddress Contract address
    /// @param from Where the token should be transferred from
    /// @param amount Token amount
    function _addERC20Prize(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal {
        // Take custody of ERC-20; assumes contract has allowance
        ERC20(tokenAddress).safeTransferFrom(from, address(this), amount);

        // Record prize
        bytes memory prize = abi.encode(
            uint8(PrizeType.ERC20),
            tokenAddress,
            amount
        );
        prizes.push(prize);
        emit ERC20Received(tokenAddress, amount);
    }

    /// @notice Add a fixed, uniform amount of an ERC-20 token as the next N
    ///     prizes. `from` must hold and approve at least `amount * n` of the
    ///     token to be added.
    /// @param tokenAddress Contract address
    /// @param from Where the token should be transferred from
    /// @param amount Token amount for each prize
    /// @param n How many times the prize should be added
    function _addERC20UniformPrizes(
        address tokenAddress,
        address from,
        uint256 amount,
        uint256 n
    ) internal {
        // Take custody of ERC-20; assumes contract has allowance
        ERC20(tokenAddress).safeTransferFrom(from, address(this), amount * n);

        // Record prize(s)
        for (uint256 i; i < n; ++i) {
            bytes memory prize = abi.encode(
                uint8(PrizeType.ERC20),
                tokenAddress,
                amount
            );
            prizes.push(prize);
        }
        emit ERC20Received(tokenAddress, amount * n);
    }

    /// @dev Dummy; always succeeds
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Add an ERC-721 token as the next prize.
    /// @param nftContract NFT contract address
    /// @param from Address to take ERC-721 from
    /// @param tokenId Token ID of the NFT to accept
    function _addERC721Prize(
        address nftContract,
        address from,
        uint256 tokenId
    ) internal {
        // Take custody of ERC-721; assumes contract has allowance
        IERC721(nftContract).safeTransferFrom(
            from,
            address(this),
            tokenId,
            bytes("")
        );

        // Record prize
        bytes memory prize = abi.encode(
            uint8(PrizeType.ERC721),
            nftContract,
            tokenId
        );
        prizes.push(prize);
        emit ERC721Received(nftContract, tokenId);
    }

    /// @dev Dummy; always succeeds
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev Dummy; always succeeds
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Add prize as nth prize if ERC1155 token is already loaded into
    ///     this contract.
    /// @notice NB: The contract does not check that there is enough ERC1155
    ///     tokens to distribute as prizes.
    /// @param nftContract NFT contract address
    /// @param from Address to take ERC-1155 from
    /// @param tokenId Token ID of the NFT to accept
    /// @param amount Amount of ERC1155 tokens
    function _addERC1155Prize(
        address nftContract,
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Take custody of ERC-721; assumes contract has allowance
        IERC1155(nftContract).safeTransferFrom(
            from,
            address(this),
            tokenId,
            amount,
            bytes("")
        );

        // Record prize
        bytes memory prize = abi.encode(
            uint8(PrizeType.ERC1155),
            nftContract,
            tokenId,
            amount
        );
        prizes.push(prize);
        emit ERC1155Received(nftContract, tokenId, amount);
    }

    /// @notice Add k ERC1155 tokens as the [n+0..n+k)th prizes
    /// @notice NB: The contract does not check that there is enough ERC1155
    ///     tokens to distribute as prizes.
    /// @param nftContract NFT contract address
    /// @param from Address to take ERC-1155 from
    /// @param tokenId Token ID of the NFT to accept
    /// @param amount Amount of ERC1155 tokens
    function _addERC1155SequentialPrizes(
        address nftContract,
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Take custody of ERC-721; assumes contract has allowance
        IERC1155(nftContract).safeTransferFrom(
            from,
            address(this),
            tokenId,
            amount,
            bytes("")
        );

        // Record prizes
        for (uint256 i; i < amount; ++i) {
            bytes memory prize = abi.encode(
                uint8(PrizeType.ERC1155),
                nftContract,
                tokenId,
                1
            );
            prizes.push(prize);
        }
        emit ERC1155Received(nftContract, tokenId, amount);
    }

    /// @notice Helper to decode the PrizeType enum from raw prize data
    /// @param prize raw prize data
    function _getPrizeType(bytes memory prize)
        internal
        pure
        returns (PrizeType)
    {
        uint8 rawType;
        assembly {
            rawType := and(mload(add(prize, 0x20)), 0xff)
        }
        if (PrizeType(rawType) > type(PrizeType).max) {
            revert InvalidPrizeType(rawType);
        }
        return PrizeType(rawType);
    }

    /// @notice Helper to decode an ERC-20 prize, assumes that the passed-in
    ///     raw prize data is of type {PrizeType.ERC20}.
    /// @param prize raw prize data
    function _getERC20Prize(bytes memory prize)
        internal
        pure
        returns (address tokenAddress, uint256 amount)
    {
        (, tokenAddress, amount) = abi.decode(prize, (uint8, address, uint256));
    }

    /// @notice Helper to decode an ERC-721 prize, assumes that the passed-in
    ///     raw prize data is of type {PrizeType.ERC721}.
    /// @param prize raw prize data
    function _getERC721Prize(bytes memory prize)
        internal
        pure
        returns (address nftContract, uint256 tokenId)
    {
        (, nftContract, tokenId) = abi.decode(prize, (uint8, address, uint256));
    }

    /// @notice Helper to decode an ERC-1155 prize, assumes that the passed-in
    ///     raw prize data is of type {PrizeType.ERC1155}.
    /// @param prize raw prize data
    function _getERC1155Prize(bytes memory prize)
        internal
        pure
        returns (
            address nftContract,
            uint256 tokenId,
            uint256 amount
        )
    {
        (, nftContract, tokenId, amount) = abi.decode(
            prize,
            (uint8, address, uint256, uint256)
        );
    }

    /// @notice Number of prizes loaded
    function getPrizeCount() public view returns (uint256) {
        return prizes.length;
    }

    /// @notice Return the raw data describing the prize at the specified index
    /// @param i Index of prize
    function getPrize(uint256 i) public view returns (bytes memory) {
        return prizes[i];
    }

    /// @notice Get a slice of the prize list at the desired offset. The prize
    ///     list is represented in raw bytes, with the 0th byte signifying
    ///     whether it's an ERC-721 or ERC-1155 prize. See {_getPrizeType},
    ///     {_getERC721Prize}, and {_getERC1155Prize} functions for how to
    ///     decode each prize.
    /// @param offset Prize index to start slice at (0-based)
    /// @param limit How many prizes to fetch at maximum (may return fewer)
    function getPrizes(uint256 offset, uint256 limit)
        public
        view
        returns (bytes[] memory prizes_)
    {
        uint256 len = prizes.length;
        if (len == 0 || offset >= len) {
            return new bytes[](0);
        }
        limit = offset + limit >= len ? len - offset : limit;
        prizes_ = new bytes[](limit);
        for (uint256 i; i < limit; ++i) {
            prizes_[i] = prizes[offset + i];
        }
    }

    /// @dev 🔥 DOES NOT HANDLE AUTHORISATION. BYO AUTH. 🔥
    /// @notice Withdraw ERC-20 after deadline has passed
    /// @param tokenAddress ERC-20 contract address
    /// @param amount Amount of token to withdraw
    function _withdrawERC20(address tokenAddress, uint256 amount)
        internal
        onlyAfterExpiry
    {
        if (amount == 0) {
            amount = ERC20(tokenAddress).balanceOf(address(this));
        }
        ERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit ERC20Reclaimed(tokenAddress, amount);
    }

    /// @dev 🔥 DOES NOT HANDLE AUTHORISATION. BYO AUTH. 🔥
    /// @notice Withdraw ERC-721 after deadline has passed
    /// @param nftContract ERC-721 contract address
    /// @param tokenId Token id to withdraw
    function _withdrawERC721(address nftContract, uint256 tokenId)
        internal
        onlyAfterExpiry
    {
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit ERC721Reclaimed(nftContract, tokenId);
    }

    /// @dev 🔥 DOES NOT HANDLE AUTHORISATION. BYO AUTH. 🔥
    /// @notice Withdraw ERC-1155 after deadline has passed
    /// @param nftContract ERC-1155 contract address
    /// @param tokenId Token id to withdraw
    /// @param amount Amount of token id to withdraw
    function _withdrawERC1155(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) internal onlyAfterExpiry {
        IERC1155(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            bytes("")
        );
        emit ERC1155Reclaimed(nftContract, tokenId, amount);
    }
}