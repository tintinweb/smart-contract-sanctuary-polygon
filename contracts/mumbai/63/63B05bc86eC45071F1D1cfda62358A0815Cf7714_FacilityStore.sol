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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title Interface default functionality for traders.
*/
interface ITrader {

    /**
    * @notice Generic struct containing information about a timed build for a ITrader.
    * @param orderId, id for unique order.
    * @param orderAmount, amount of tokens requested in order.
    * @param createdAt, timestamp of creation for order.
    * @param speedUpDeductedAmount, total speed up time for order.
    * @param totalCompletionTime, default time for creation minus speedUpDeductedAmount.
    */
    struct Order {
        uint orderId;
        uint orderAmount; //can be multiple on wasteToCash, will be 1 on IfacilityStore, multiple for prospecting?
        uint createdAt; //start time for order. epoch Time
        uint speedUpDeductedAmount; //time that has been deducted.
        uint totalCompletionTime; // defaultOrdertime - speedUpDeductedAmount. In seconds.
    }

    /**
    * @notice Get all active orders for user.
    * @param _player, address for orders to be requested from.
    * @return All unclaimed orders.
    */
    function getOrders(address _player) external view returns (Order[] memory);

    /**
    * @notice Speed up one order.
    * @param _numSpeedUps, how many times you want to speed up an order.
    * @param _orderId, chosen order to speed up.
    */
    function speedUpOrder(uint _numSpeedUps, uint _orderId) external;

    /**
    * @notice Claim order single order.
    * @param _orderId, chosen order to claim
    */
    function claimOrder(uint _orderId) external;

    /**
    * @notice Claim all orders that are finished for user.
    */
    function claimBatchOrder() external;

    function setIXTSpeedUpParams(address _pixt, address _beneficiary, uint _pixtSpeedupSplitBps, uint _pixtSpeedupCost) external;

    function IXTSpeedUpOrder(uint _numSpeedUps, uint _orderId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IFacilityStore.sol";
import "./IAssetManager.sol";
import "../util/VRFManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../util/Burnable.sol";

/* Errors */
error OnlyCoordinatorCanFulfill(address have, address want);
error OnlyGovCanCall();
error AdditionalBiomodsWrongLength(uint256 have, uint256 want);
error MaxOpenOrdersReached();
error MsgSenderIsNotOrderOwner(address have, address want);
error OrderIsNotFinished();
error OrderClaimIsAlreadyRequested();
error BiomodTokenIdsAndPriceLengthsAreDifferent();
error BiomodTokensAndFacilityTokensLengthsAreDifferent();
error FacilityTokenIdsAndWeightsLengthsAreDifferent();
error NoOrders(address player);
error NoClaimableOrders(address player);
error InvalidSpeedupAmount();
error NoPossibleSpeedUps();
error InvalidOrderId(uint orderId);
error OrderNotClaimed();

struct InitializeParams {
    address _assetManager;
    address _feeWallet;
    uint256 _facilityTime;
    uint256 _speedupPriceTokenId;
    uint256 _speedupPrice;
    uint256 _speedupTime;
    uint256 _maxOrders;
    uint256[] _fixedPriceTokenIds;
    uint256[] _fixedPriceTokenAmounts;
    uint256[] _biomodTokenIds;
    uint256[] _biomodPriceAmounts;
    uint256[] _facilityTokenIds;
    uint256[] _facilityProbabilityWeights;
    address _vrfCoordinator;
}

contract FacilityStore is IFacilityStore, OwnableUpgradeable, IRNGConsumer {
    /* Type Declarations */
    uint256 public nextOrderId;
    mapping(address => Order[]) s_facilityOrders;
    mapping(uint256 => NewFacilityOrder) s_facilityOrderWeights;
    mapping(uint256 => address) s_requestIds;
    mapping(uint256 => uint256) requestToOrderId;
    mapping(address => uint256[]) userOrders; // delete this when deploying new

    IAssetManager public assetManager;

    uint256 public facilityTime;
    uint256 public speedupPriceTokenId;
    uint256 public speedupPrice;
    uint256 public speedupTime;

    uint256 public maxOrders;

    address public feeWallet;
    uint256 public feePercentage;  // denominator is 10000
    uint256 public feeTokenId;     // same as fixedPriceTokenIds[0]
    uint256 public feeTokenAmount; // calculated based on feePercentage and fixedPriceTokenAmounts[0]

    uint256[] public fixedPriceTokenIds;
    uint256[] public fixedPriceTokenAmounts;

    uint256[] public biomodTokenIds;
    uint256[] public biomodPriceAmounts;
    uint256[] public facilityTokenIds;
    uint256[] public facilityProbabilityWeights;

    address public vrfCoordinator;
    mapping(uint256 => uint256) public vrfRequests; // map requestId -> facility orderId

    address public moderator;

    address public pixt;
    address beneficiary;
    uint public pixtSpeedupSplitBps;
    uint public pixtSpeedupCost;

    /* Events */
    event FacilityOrderPlaced(address indexed user, uint256 indexed orderId);
    event SpeedUpConstruction(address indexed user, uint256 indexed orderId, uint256 _numSpeedups);
    event RequestClaimFacility(address indexed user, uint256 indexed orderId);
    event ReceiveFacility(address indexed user, uint256 orderId, uint256 facilityTokenId);

    /* Modifiers */
    modifier onlyGov() {
        if (msg.sender != owner() || msg.sender != moderator) revert OnlyGovCanCall();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != vrfCoordinator) revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        _;
    }

    function initialize(
        InitializeParams memory _initParams
    ) public initializer {
        __Ownable_init();

        if (_initParams._biomodTokenIds.length != _initParams._biomodPriceAmounts.length) {
            revert BiomodTokenIdsAndPriceLengthsAreDifferent();
        }
        if (_initParams._facilityTokenIds.length != _initParams._facilityProbabilityWeights.length) {
            revert FacilityTokenIdsAndWeightsLengthsAreDifferent();
        }
        if (_initParams._biomodTokenIds.length != _initParams._facilityTokenIds.length) {
            revert BiomodTokensAndFacilityTokensLengthsAreDifferent();
        }

        assetManager = IAssetManager(_initParams._assetManager);
        feeWallet = _initParams._feeWallet;
        facilityTime = _initParams._facilityTime;
        speedupPriceTokenId = _initParams._speedupPriceTokenId;
        speedupPrice = _initParams._speedupPrice;
        speedupTime = _initParams._speedupTime;
        maxOrders = _initParams._maxOrders;
        fixedPriceTokenIds = _initParams._fixedPriceTokenIds;
        fixedPriceTokenAmounts = _initParams._fixedPriceTokenAmounts;
        biomodTokenIds = _initParams._biomodTokenIds;
        biomodPriceAmounts = _initParams._biomodPriceAmounts;
        facilityTokenIds = _initParams._facilityTokenIds;
        facilityProbabilityWeights = _initParams._facilityProbabilityWeights;
        vrfCoordinator = _initParams._vrfCoordinator;

        feeTokenId = fixedPriceTokenIds[0];
        feeTokenAmount = _calculateFee(feePercentage, fixedPriceTokenAmounts[0]);

        moderator = msg.sender;
    }

    function _createNewOrder(address _user) internal returns(uint _orderId) {
        uint256 orderId = nextOrderId;
        nextOrderId++;

        s_facilityOrders[_user].push(Order({
            orderId: orderId,
            orderAmount: 1,
            createdAt: block.timestamp,
            speedUpDeductedAmount: 0,
            totalCompletionTime: facilityTime
        }));
        return orderId;
    }

    /// @inheritdoc IFacilityStore
    function placeFacilityOrder(
        uint256[] calldata _additionalBiomodAmounts
    ) override external {
        if (_additionalBiomodAmounts.length != biomodTokenIds.length) {
            revert AdditionalBiomodsWrongLength(_additionalBiomodAmounts.length, biomodTokenIds.length);
        }
        if (userOpenOrdersAmount(msg.sender) >= maxOrders) {
            revert MaxOpenOrdersReached();
        }
        uint orderId = _createNewOrder(msg.sender);
        uint256[] memory totalBiomodAmounts = biomodPriceAmounts;

        for(uint256 i=0; i<biomodTokenIds.length; i++) {
            totalBiomodAmounts[i] += _additionalBiomodAmounts[i];
            s_facilityOrderWeights[orderId].totalFacilityProbabilityWeights.push(facilityProbabilityWeights[i] * (1+ _additionalBiomodAmounts[i]));
        }

        assetManager.trustedBatchBurn(msg.sender, fixedPriceTokenIds, fixedPriceTokenAmounts);
        assetManager.trustedBatchBurn(msg.sender, biomodTokenIds, totalBiomodAmounts);
        // mint fee to feeWallet
        assetManager.trustedMint(feeWallet, feeTokenId, feeTokenAmount);
        emit FacilityOrderPlaced(msg.sender, orderId);
    }

    /// @inheritdoc ITrader
    function speedUpOrder(uint _numSpeedUps, uint _orderId) external override {
        Order[] storage orders = s_facilityOrders[msg.sender];
        if (orders.length == 0) revert NoOrders(msg.sender);
        if (_numSpeedUps == 0) revert InvalidSpeedupAmount();
        for (uint256 orderIndex; orderIndex < orders.length; orderIndex++) {
            if (orders[orderIndex].orderId == _orderId) {
                if (isFinished(orders[orderIndex])) revert NoPossibleSpeedUps();
                orders[orderIndex].speedUpDeductedAmount += speedupTime * _numSpeedUps;
                orders[orderIndex].totalCompletionTime = int(facilityTime) - int(orders[orderIndex].speedUpDeductedAmount) > 0 ? facilityTime - orders[orderIndex].speedUpDeductedAmount : 0;

                emit SpeedUpConstruction(msg.sender, orders[orderIndex].orderId, _numSpeedUps);
                assetManager.trustedBurn(msg.sender, speedupPriceTokenId, _numSpeedUps * speedupPrice);
                return;
            }
        }
        revert InvalidOrderId(_orderId);
    }

    function IXTSpeedUpOrder(uint _numSpeedUps, uint _orderId) external override{
        require(pixt != address (0), "IXT address not set");
        Order[] storage orders = s_facilityOrders[msg.sender];
        if (orders.length == 0) revert NoOrders(msg.sender);
        if (_numSpeedUps == 0) revert InvalidSpeedupAmount();
        for (uint256 orderIndex; orderIndex < orders.length; orderIndex++) {
            if (orders[orderIndex].orderId == _orderId) {
                if (isFinished(orders[orderIndex])) revert NoPossibleSpeedUps();
                orders[orderIndex].speedUpDeductedAmount += speedupTime * _numSpeedUps;
                orders[orderIndex].totalCompletionTime = int(facilityTime) - int(orders[orderIndex].speedUpDeductedAmount) > 0 ? facilityTime - orders[orderIndex].speedUpDeductedAmount : 0;

                require(IERC20(pixt).transferFrom(msg.sender, address(this), pixtSpeedupCost * _numSpeedUps), "Transfer of funds failed");
                Burnable(pixt).burn((pixtSpeedupCost * _numSpeedUps * pixtSpeedupSplitBps) / 10000);
                emit SpeedUpConstruction(msg.sender, orders[orderIndex].orderId, _numSpeedUps);
                return;
            }
        }
        revert InvalidOrderId(_orderId);
    }

    function setIXTSpeedUpParams(address _pixt, address _beneficiary, uint _pixtSpeedupSplitBps, uint _pixtSpeedupCost) external override onlyOwner{
        pixt = _pixt;
        beneficiary = _beneficiary;
        pixtSpeedupSplitBps = _pixtSpeedupSplitBps;
        pixtSpeedupCost = _pixtSpeedupCost;
    }

    function _requestOrder(uint _orderId) internal {
        uint reqId = VRFManager(vrfCoordinator).getRandomNumber(1);
        s_requestIds[reqId] = msg.sender;
        requestToOrderId[reqId] = _orderId;
    }

    function userOpenOrdersAmount(address _user) view public returns(uint256) {
        uint256 openOrdersCount = 0;
        Order[] storage orders = s_facilityOrders[_user];
        for(uint256 i=0; i<orders.length; i++) {
            if (block.timestamp > orders[i].createdAt + orders[i].totalCompletionTime) {
                openOrdersCount++;
            }
        }
        return openOrdersCount;
    }

    /// @inheritdoc ITrader
    function claimOrder(uint _orderId) external override {
        Order[] storage orders = s_facilityOrders[msg.sender];
        if (orders.length == 0) revert NoOrders(msg.sender);
        for(uint256 i=0; i < orders.length; i++) {
            if (orders[i].orderId == _orderId){
                if ((orders[i].createdAt + orders[i].totalCompletionTime) < block.timestamp) {
                    _requestOrder(_orderId);
                    _removeOrder(i);
                    emit RequestClaimFacility(msg.sender, _orderId);
                    return;
                }
                else revert OrderIsNotFinished();
            }
        }
        revert InvalidOrderId(_orderId);
    }

    /// @inheritdoc ITrader
    function claimBatchOrder() external override {
        Order[] storage orders = s_facilityOrders[msg.sender];
        if (orders.length == 0) revert NoOrders(msg.sender);
        for(uint i=orders.length; i > 0; i--) {
            if ((orders[i-1].createdAt + orders[i-1].totalCompletionTime) < block.timestamp) {
                _requestOrder(orders[i-1].orderId);
                emit RequestClaimFacility(msg.sender, orders[i-1].orderId);
                _removeOrder(i-1);
            }
        }
    }

    function _removeOrder(uint _index) internal {
        if (_index < s_facilityOrders[msg.sender].length -1)
            s_facilityOrders[msg.sender][_index] = s_facilityOrders[msg.sender][s_facilityOrders[msg.sender].length-1];
        s_facilityOrders[msg.sender].pop();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external virtual onlyOracle {
        address player = s_requestIds[requestId];
        uint orderId = requestToOrderId[requestId];
        delete requestToOrderId[requestId];
        delete s_requestIds[requestId];

        uint256 facilityIndex = _draw(randomWords[0], s_facilityOrderWeights[orderId].totalFacilityProbabilityWeights);

        assetManager.trustedMint(player, facilityTokenIds[facilityIndex], 1);
        emit ReceiveFacility(player,orderId, facilityTokenIds[facilityIndex]);
    }

    /* Check if order is finished and claimable */
    function isFinished(Order memory order) internal returns(bool _isFinished){
        _isFinished = (order.createdAt + order.totalCompletionTime) < block.timestamp;
    }

    /* Math functions */
    function _calculateFee(uint256 bpsFee, uint256 amount) internal pure returns (uint256) {
        return (amount * bpsFee) / 10000;
    }

    function _draw(uint256 _sample, uint256[] storage _weights) view internal returns (uint256 resultIndex) {
        uint uniformSample = _sample % _sumArray(_weights);
        uint256 sum = 0;

        for(uint256 i=0; i<_weights.length; i++) {
            sum += _weights[i];
            if (uniformSample < sum) {
                return i;
            }
        }
    }

    function _sumArray(uint256[] storage _array) internal view returns (uint256 _sum){
        for (uint256 i; i < _array.length; i++) {
            _sum += _array[i];
        }
    }

    /* Get functions */
    /// @inheritdoc IFacilityStore
    function getFacilityFixedTokensPrice() override external view returns (uint[] memory _tokenIds, uint[] memory _tokenAmounts) {
        return(fixedPriceTokenIds, fixedPriceTokenAmounts);
    }
    /// @inheritdoc IFacilityStore
    function getFacilityBiomodTokensPrice() override external view returns (uint[] memory _tokenIds, uint[] memory _tokenAmounts) {
        return(biomodTokenIds, biomodPriceAmounts);
    }

    /// @inheritdoc ITrader
    function getOrders(address _player) external view returns (Order[] memory){
        return s_facilityOrders[_player];
    }

    /* Set functions */
    function setAssetManager(address _assetManager) external onlyGov() {
        assetManager = IAssetManager(_assetManager);
    }

    function setFacilityTime(uint256 _facilityTime) external onlyGov() {
        facilityTime = _facilityTime;
    }

    function setSpeedupParameters(
        uint256 _speedupPriceTokenId,
        uint256 _speedupPrice,
        uint256 _speedupTime
    ) external onlyGov() {
        speedupPriceTokenId = _speedupPriceTokenId;
        speedupPrice = _speedupPrice;
        speedupTime = _speedupTime;
    }

    function setMaxOrders(uint256 _maxOrders) external onlyGov() {
        maxOrders = _maxOrders;
    }

    /// @inheritdoc IFacilityStore
    function getMaxOrders() external view override returns(uint256 _maxOrders){
        _maxOrders = maxOrders;
    }

    function setFeeWallet(address _feeWallet) external onlyGov() {
        feeWallet = _feeWallet;
    }

    /**
    * @dev feeTokenAmount will be recalculated based on new fee percentage
    */
    function setFeePercentage(uint256 _feePercentage) external onlyGov() {
        feePercentage = _feePercentage;
        feeTokenAmount = _calculateFee(feePercentage, fixedPriceTokenAmounts[0]);
    }

    /**
    * @dev first parameter is used always as fee token, feeTokenId and feeTokenAmount will be recalculated
    */
    function setFixedPriceTokenIds(
        uint256[] memory _fixedPriceTokenIds,
        uint256[] memory _fixedPriceTokenAmounts
    ) external onlyGov() {
        fixedPriceTokenIds = _fixedPriceTokenIds;
        fixedPriceTokenAmounts = _fixedPriceTokenAmounts;

        feeTokenId = fixedPriceTokenIds[0];
        feeTokenAmount = _calculateFee(feePercentage, fixedPriceTokenAmounts[0]);
    }

    function setBiomodTokenPrices(
        uint256[] memory _biomodTokenIds,
        uint256[] memory _biomodPriceAmounts
    ) external onlyGov() {
        if (_biomodTokenIds.length != _biomodPriceAmounts.length) {
            revert BiomodTokenIdsAndPriceLengthsAreDifferent();
        }

        biomodTokenIds = _biomodTokenIds;
        biomodPriceAmounts = _biomodPriceAmounts;
    }

    function setFacilityTokenIdsAndWeights(
        uint256[] memory _facilityTokenIds,
        uint256[] memory _facilityProbabilityWeights
    ) external onlyGov() {

        if (_facilityTokenIds.length != _facilityProbabilityWeights.length) {
            revert FacilityTokenIdsAndWeightsLengthsAreDifferent();
        }
        if (_facilityTokenIds.length != biomodTokenIds.length) {
            revert BiomodTokensAndFacilityTokensLengthsAreDifferent();
        }

        facilityTokenIds = _facilityTokenIds;
        facilityProbabilityWeights = _facilityProbabilityWeights;
    }

    function setVrfCoordinator(address _vrfCoordinator) external onlyGov() {
        vrfCoordinator = _vrfCoordinator;
    }

    function setModerator(address _moderator) external onlyGov() {
        moderator = _moderator;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract responsible for minting rewards and burning payment in the context of the mission control
interface IAssetManager {
    enum AssetIds {
        UNUSED_0, // 0, unused
        GoldBadge, //1
        SilverBadge, //2
        BronzeBadge, // 3
        GenesisDrone, //4
        PiercerDrone, // 5
        YSpaceShare, //6
        Waste, //7
        AstroCredit, // 8
        Blueprint, // 9
        BioModOutlier, // 10
        BioModCommon, //11
        BioModUncommon, // 12
        BioModRare, // 13
        BioModLegendary, // 14
        LootCrate, // 15
        TicketRegular, // 16
        TicketPremium, //17
        TicketGold, // 18
        FacilityOutlier, // 19
        FacilityCommon, // 20
        FacilityUncommon, // 21
        FacilityRare, //22
        FacilityLegendary, // 23,
        Energy, // 24
        LuckyCatShare, // 25,
        GravityGradeShare, // 26
        NetEmpireShare, //27
        NewLandsShare, // 28
        HaveBlueShare, //29
        GlobalWasteSystemsShare, // 30
        EternaLabShare // 31
    }

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens
     * @param _amount Number of tokens to mint
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens
     * @param _amounts Number of tokens to mint
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenId Id of to-be-burnt tokens
     * @param _amount Number of tokens to burn
     */
    function trustedBurn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenIds Ids of to-be-burnt tokens
     * @param _amounts Number of tokens to burn
     */
    function trustedBatchBurn(
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/ITrader.sol";

interface IFacilityStore is ITrader {
    /**
    * @notice Struct containing weights for single order.
    * @param totalFacilityProbabilityWeights weights depending on biomods placed for order.
    */
    struct NewFacilityOrder {
        uint256[] totalFacilityProbabilityWeights;
    }

    /**
    * @notice Place an order for a facility
    * @param _additionalTokensAmounts Amounts of additional Bio-mods to be expended of each type
    */
    function placeFacilityOrder(uint[] calldata _additionalTokensAmounts) external;

    /**
    * @notice Used to fetch the part of facility price paid in tokens which are not biomods
    * @return _tokenIds Ids of tokens to be paid
    * @return _tokenAmounts Amounts of tokens to be paid
    */
    function getFacilityFixedTokensPrice() external view returns (uint[] memory _tokenIds, uint[] memory _tokenAmounts);

    /**
    * @notice Used to fetch the facility price paid in biomod tokens
    * @return _biomodTokenIds Ids of tokens to be paid
    * @return _biomodTokenAmounts Amounts of tokens to be paid
    */
    function getFacilityBiomodTokensPrice() external view returns (uint[] memory _biomodTokenIds, uint[] memory _biomodTokenAmounts);

    function getMaxOrders() external view returns(uint256 _maxOrders);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/// @title Generic interface for burning.
interface Burnable {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IRNGConsumer {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

contract VRFManager is VRFConsumerBaseV2 {
    struct Params {
        uint64 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }
    VRFCoordinatorV2Interface COORDINATOR;

    mapping(uint256 => address) s_requestIds;
    mapping(address => bool) isConsumer;
    mapping(address => Params) consumerParams;

    address s_owner;

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
    modifier onlyConsumer() {
        require(isConsumer[msg.sender]);
        _;
    }

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
    }

    function getRandomNumber(uint32 numWords) external onlyConsumer returns (uint256 requestId) {
        Params memory params = consumerParams[msg.sender];
        requestId = COORDINATOR.requestRandomWords(
            params.keyHash,
            params.subscriptionId,
            params.requestConfirmations,
            params.callbackGasLimit,
            numWords
        );
        s_requestIds[requestId] = msg.sender;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address rngConsumer = s_requestIds[requestId];
        IRNGConsumer(rngConsumer).fulfillRandomWords(requestId, randomWords);
    }

    function setConsumer(
        address _consumer,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) external onlyOwner {
        isConsumer[_consumer] = true;
        consumerParams[_consumer] = Params({
            subscriptionId: _subscriptionId,
            keyHash: _keyHash,
            callbackGasLimit: _callbackGasLimit,
            requestConfirmations: _requestConfirmations,
            numWords: _numWords
        });
    }
}