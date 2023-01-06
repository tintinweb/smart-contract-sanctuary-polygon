// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatible directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatible as KeeperCompatible} from "./AutomationCompatible.sol";
import {AutomationBase as KeeperBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

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

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

import "../Shared/ILucky3ZooRuleV1Shared.sol";

interface ILucky3ZooRuleV1 is ILucky3ZooRuleV1Shared {
    
    function getBlankCode() external pure returns(uint);

    function verifyResult(LuckyNumber memory a,uint8[3] memory b) external pure returns(bool);

    function verifyFormat(uint8[] memory numberArr) external view returns(bool);

    function formatObject(uint8[] memory numberArr) external pure returns(LuckyNumber memory);

    function getModeMultiple(GameMode mode) external view returns(uint16);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

interface IReferralPool {
    function bindReferrer(address _invitee, address _referrer) external;
    function getReferrer(address account) external view returns (address);
}

//SPDX-License-Identifier:MIT

/***

$$\      $$\   $$\  $$$$$$\  $$\   $$\ $$\     $$\ $$$$$$$$\  $$$$$$\   $$$$$$\  
$$ |     $$ |  $$ |$$  __$$\ $$ | $$  |\$$\   $$  |\____$$  |$$  __$$\ $$  __$$\ 
$$ |     $$ |  $$ |$$ /  \__|$$ |$$  /  \$$\ $$  /     $$  / $$ /  $$ |$$ /  $$ |
$$ |     $$ |  $$ |$$ |      $$$$$  /    \$$$$  /     $$  /  $$ |  $$ |$$ |  $$ |
$$ |     $$ |  $$ |$$ |      $$  $$<      \$$  /     $$  /   $$ |  $$ |$$ |  $$ |
$$ |     $$ |  $$ |$$ |  $$\ $$ |\$$\      $$ |     $$  /    $$ |  $$ |$$ |  $$ |
$$$$$$$$\\$$$$$$  |\$$$$$$  |$$ | \$$\     $$ |    $$$$$$$$\  $$$$$$  | $$$$$$  |
\________|\______/  \______/ \__|  \__|    \__|    \________| \______/  \______/ 
                                                                                 
***/

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./Interface/ILucky3ZooRuleV1.sol";
import "./Interface/IReferralPool.sol";
import "./Shared/ILucky3ZooRuleV1Shared.sol";
import "./Shared/Common.sol";

contract Lucky3Zoo is ILucky3ZooRuleV1Shared,KeeperCompatibleInterface,VRFConsumerBaseV2,Ownable,ReentrancyGuard{

    // INTERFACE OBJECT
    VRFCoordinatorV2Interface ICOORDINATOR;
    ILucky3ZooRuleV1 ILUCKY3ZOORULEV1;
    IReferralPool IREFERRALPOOL;

    //INTERNAL TYPE
    //Configure game fees
    struct GameFee{
        uint singleBetCost;
        uint8 fundFeeRate;
        uint8 winnerFeeRate;
        uint8 level1RewardRate;
        uint8 level2RewardRate;
    }

    //Game result
    struct OpenResult{
        uint8 n1;
        uint8 n2;
        uint8 n3;
    }

    //Game status
    enum GameStatus{
        available,
        pending,
        paused,
        closed
    }

    // CHAINLINK CONFIG (polygon)
    uint32 public vrfCallbackGasLimit=500000;
    uint8 public vrfRequestConfirmations=3;
    uint64 public vrfSubscriptionId=538;
    address private _vrfCoordinator=0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    address private _vrfLinkContract=0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    bytes32 private _vrfKeyHash=0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
    uint private _vrfRequestId;

    // PUBLIC STATE
    address public fundAddress=0xF8b1e47341D4A535bebE2722177E51a86Bf9d052;
    // Game rules contract address
    address public ruleContract;
    // Default referrer
    address public defaultReferrer=0xd8A337eC5a8c9f4837e08Aa776B58C6C1a94D62B;

    address public luckyToken;

    GameStatus public gameStatus;
    GameFee public gameFeeConfig;
    // Total bonuses paid out
    uint public totalBonusPaid;
    // Current round
    uint public currentRound;
    
    // Interval time per round
    uint public roundIntervalTime=3 minutes;
    // Maximum query rounds
    uint public maxQueryRound=500; 
    // Initial fund pool, withdrawable
    // The administrator can only withdraw the initial fund pool, and no one can withdraw other funds in the contract.
    uint public initFundPool=0;

    //Minimum tax threshold
    uint public minTaxThreshold=10 ether;

    // Maximum withdrawable bonus ratio
    uint8 public maxBonusWithdrawalRatio=50;

    //Whether to reward native token
    bool public isRewardToken=false;

    //Reward token multiple
    uint16 public rewardTokenMultiple=10;

    // PRIVATE STATE
    bool private _allowContract=true;
    uint private _lastRequestTime;

    // Mapping from round id to round results
    mapping(uint=>uint8[3]) private _gameResult;
    // Mapping from user address to round list
    mapping(address=>uint[]) private _userBetRound;
    // Mapping from round id to user betting results
    mapping(uint=>mapping(address=>LuckyNumber[])) private _betData;
    // Mapping from round id to user bonus withdrawal status
    mapping(uint=>mapping(address=>bool)) private _bonusWithdrawalStatus;
    mapping(address=>uint) private _userPaidBonus;
    mapping(address=>bool) private _blockAddress; 

    event BetEvt(address indexed user, uint indexed round,uint8[][] numberArray);
    event RoundResultEvt(uint indexed round,uint8[3] result);
    //event WithdrawBonusEvt(address indexed user,uint round,uint amount);
    event WithdrawAllBonusEvt(address indexed user,uint amount);
    event TransferBonusEvt(address indexed from,address indexed to,uint value,int8 level);
    
    constructor(address ruleContractAddress,address referralContractAddress) VRFConsumerBaseV2(_vrfCoordinator){
        ICOORDINATOR=VRFCoordinatorV2Interface(_vrfCoordinator);
        ruleContract=ruleContractAddress;
        ILUCKY3ZOORULEV1=ILucky3ZooRuleV1(ruleContractAddress);
        IREFERRALPOOL=IReferralPool(referralContractAddress);
        _lastRequestTime=block.timestamp;

        // Configure Game Fees
        gameFeeConfig.singleBetCost=2*10**17;
        gameFeeConfig.fundFeeRate=18;
        gameFeeConfig.winnerFeeRate=15;
        gameFeeConfig.level1RewardRate=5;
        gameFeeConfig.level2RewardRate=2;
    }

    modifier gameActive(){
        require(gameStatus==GameStatus.available || gameStatus==GameStatus.paused,"Game unavailable");
        _;
    }

    modifier checkSender(){
        if(!_allowContract){
            require(msg.sender==tx.origin,"Contract access is not allowed");
        }

        require(_blockAddress[msg.sender]==false && _blockAddress[tx.origin]==false,"Access is blocked");
        _;
    }

    //////////////////////////////////
    //Chainlink VRF Start
    function requestRandomWords() internal{
        _vrfRequestId=ICOORDINATOR.requestRandomWords(
            _vrfKeyHash,
            vrfSubscriptionId,
            vrfRequestConfirmations,
            vrfCallbackGasLimit,
            1
        );
    }

    function fulfillRandomWords(uint requestId,uint[] memory randomWords) internal override{
        if(_vrfRequestId==requestId){
            if(gameStatus==GameStatus.pending){
                uint randomNumber=randomWords[0];
                _lastRequestTime=block.timestamp;
                currentRound++;
                uint8[6] memory result=calculate(randomNumber);
                _gameResult[currentRound][0]=result[1];
                _gameResult[currentRound][1]=result[3];
                _gameResult[currentRound][2]=result[5];
                gameStatus=GameStatus.paused;

                emit RoundResultEvt(currentRound,_gameResult[currentRound]);
            }
        }
    }

    //Chainlink VRF End
    //////////////////////////////////
    //Chainlink Keepers Start
    //////////////////////////////////

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        if(gameStatus==GameStatus.available &&
          _lastRequestTime+roundIntervalTime <= block.timestamp){
            upkeepNeeded=true;
        }
        else{
            upkeepNeeded=false;
        }
        
        return(upkeepNeeded,'');
    }

    function performUpkeep(bytes calldata) external override{
        if(gameStatus==GameStatus.available && 
        _lastRequestTime+roundIntervalTime <= block.timestamp){
            gameStatus=GameStatus.pending;
            requestRandomWords();
        }
    }

    //Chainlink Keepers End
    //////////////////////////////////

    /**
     * @dev Calculate game result based on random number
     */
    function calculate(uint randomNumber) private view returns(uint8[6] memory){
        uint8[6] memory results;
        uint8 limit=6;
        uint8[6] memory numberMap=[3,4,5,0,1,2];

        if(randomNumber==0){
            randomNumber=uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,blockhash(block.number-1))));
        }
        
        uint8 t;
        uint8 temp;
        for(uint8 i=0;i<6;i++){
            t=uint8(randomNumber%(limit-i)+i);
            temp=numberMap[i];
            numberMap[i]=numberMap[t];
            numberMap[t]=temp;
            results[i]=numberMap[i];
        }

        return results;
    }

    /**
     * @dev Return user betting data
     */
    function getUserBettedNumber(address user,uint round) public view returns(LuckyNumber[] memory numbers){
        LuckyNumber[] memory luckyNumber=_betData[round][user];
        return luckyNumber;
    }

    /**
     * @dev Get game results
     */
    function getGameResult(uint round) public view returns(uint8[3] memory){
        return _gameResult[round];
    }

    /**
     * @dev Get the top n game results
     */
    function getGameResultList(uint top) public view returns(OpenResult[] memory){
        if(top>currentRound){
            top=currentRound;
        }

        OpenResult[] memory resultList=new OpenResult[](top);

        for(uint i=0;i<top;i++){
            uint8[3] memory result=getGameResult(currentRound-i);
            resultList[i]=OpenResult({n1:result[0],n2:result[1],n3:result[2]});
        }

        return resultList;
    }

    function getLastRoundEndTime() public view returns(uint){
        return _lastRequestTime;
    }

    function getEstimateNextRoundTime() public view returns(uint){
        return _lastRequestTime+roundIntervalTime;
    }
    
    /**
     * @dev Game betting
     *
     * - `numberArray` [[2,3,4,1,0],[1,2,3,1,1]]
     * - `referrer` referrer address or zero address
     */
    function batchBetting(uint8[][] calldata numberArray,address referrer) payable public gameActive checkSender{
        require(numberArray.length>0,"Incorrect format");
        uint multiple=0;

        for(uint8 i=0;i<numberArray.length;i++){
            require(ILUCKY3ZOORULEV1.verifyFormat(numberArray[i])==true,"Incorrect format");
            LuckyNumber memory betNumber=ILUCKY3ZOORULEV1.formatObject(numberArray[i]);
            
            multiple+=betNumber.x;
        }

        uint totalFee=multiple*gameFeeConfig.singleBetCost;
        require(msg.value>=totalFee,"Insufficient fee");

        address sender=msg.sender;

        if(_betData[currentRound+1][sender].length==0){
            _userBetRound[sender].push(currentRound+1);
        }

        if((referrer==address(0) || referrer==sender) && defaultReferrer!=address(0)){
            referrer=defaultReferrer;
        }

        address level1Ref=IREFERRALPOOL.getReferrer(sender);
        address level2Ref=address(0);

        if(level1Ref==address(0) && referrer!=address(0)){
            IREFERRALPOOL.bindReferrer(sender,referrer);
            level1Ref=referrer;
        }

        for(uint8 i=0;i<numberArray.length;i++){
            LuckyNumber memory betNumber=ILUCKY3ZOORULEV1.formatObject(numberArray[i]);
            _betData[currentRound+1][sender].push(betNumber);
        }

        if(level1Ref!=address(0) && level1Ref!=sender){
            if(gameFeeConfig.level1RewardRate>0){
                uint bonus=totalFee*gameFeeConfig.level1RewardRate/100;
                payable(level1Ref).transfer(bonus);
                emit TransferBonusEvt(sender,level1Ref,bonus,1);
            }

            level2Ref=IREFERRALPOOL.getReferrer(level1Ref);

            if(gameFeeConfig.level2RewardRate>0){
                uint bonus=totalFee*gameFeeConfig.level2RewardRate/100;
                if(level2Ref!=address(0) &&  level2Ref!=sender){
                    payable(level2Ref).transfer(bonus);
                    emit TransferBonusEvt(sender,level2Ref,bonus,2);
                }
                else if(defaultReferrer!=address(0)){
                    payable(defaultReferrer).transfer(bonus);
                }
            }
        }

        if(fundAddress!=address(0) && gameFeeConfig.fundFeeRate>0){
            payable(fundAddress).transfer(totalFee*gameFeeConfig.fundFeeRate/100);
        }

        if(gameStatus==GameStatus.paused){
            gameStatus=GameStatus.available;
            _lastRequestTime=block.timestamp;
        }

        //reward token
        uint rewardTokenQty=totalFee*rewardTokenMultiple;
        if(isRewardToken && luckyToken!=address(0) && IERC20(luckyToken).balanceOf(address(this))>=rewardTokenQty){
            TransferHelper.safeTransfer(luckyToken,sender,rewardTokenQty);
        }

        emit BetEvt(sender,currentRound+1,numberArray);
    }

    /**
     * @dev Get the bonuses that the user has already withdrawn
     */
    function getPaidBonus(address user) public view returns(uint){
        return _userPaidBonus[user];
    }

    /**
     * @dev Returns the list of rounds the user has bet on.
     */
    function queryUserBettedRound(address user,uint cursor,uint size) public view returns(uint[] memory list,bool[] memory result){
        uint[] memory roundList=_userBetRound[user];
        
        if(roundList.length==0){
            return (list,result);
        }

        uint querySize=size;
        if(querySize>(roundList.length-cursor)){
            querySize=roundList.length-cursor;
        }

        list=new uint[](querySize);
        result=new bool[](querySize);
        uint j=0;
        uint k=roundList.length-cursor;
        for(uint i=k;i>k-querySize;i--){
            list[j]=roundList[i-1];
            result[j]=verifyRoundResult_(user,list[j]);
            j++;
        }

        return (list,result);
    }

    function getUserRoundStatus(address user,uint round) public view returns(uint8 status,uint bonus){
        LuckyNumber[] memory luckyNumber=_betData[round][user];
        if(luckyNumber.length==0) return (0,0);

        bonus=queryBonus(user,round);

        status=bonus>0?2:1;
    }

    function verifyRoundResult_(address user,uint round) private view returns(bool){
        if(round==currentRound+1){
            return false;
        }

        LuckyNumber[] memory userBetData=_betData[round][user];
        uint8[3] memory result=_gameResult[round];
        
        for(uint i=0;i<userBetData.length;i++){
            if(ILUCKY3ZOORULEV1.verifyResult(userBetData[i],result)){
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Query for all undrawn bonuses
     */
    function queryAllUnPaidBonus(address user) public view returns(uint){
        uint[] memory roundList=_userBetRound[user];
        if(roundList.length==0) return 0;

        uint querySize=roundList.length;
        if(querySize>maxQueryRound){
            querySize=maxQueryRound;
        }

        uint bonus=0;

        for(uint i=roundList.length;i>roundList.length-querySize;i--){
            bonus+=queryUnPaidBonus(user,roundList[i-1]);
            
        }

        return bonus;
    }

    /**
     * @dev Query bonus
     */
    function queryBonus(address user,uint round) public view returns(uint){
        if(round==currentRound+1 || _gameResult[round].length==0){
            return 0;
        }
        
        uint8[3] memory roundResult=_gameResult[round];
        LuckyNumber[] memory userBetData=_betData[round][user];

        uint bonus=0;      
        for(uint i=0;i<userBetData.length;i++){

            if(ILUCKY3ZOORULEV1.verifyResult(userBetData[i],roundResult)){
                uint16 multiple=ILUCKY3ZOORULEV1.getModeMultiple(userBetData[i].mode);
                bonus+= gameFeeConfig.singleBetCost*userBetData[i].x*multiple/10;
            }
            
        }

        return bonus;
    }
    

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    /**
     * @dev Query for undrawn bonuses
     */
    function queryUnPaidBonus(address user,uint round) public view returns(uint){
        if(_bonusWithdrawalStatus[round][user]==true){
            return 0;
        }

        return queryBonus(user,round);
    }

    /**
     * @dev Withdraw all bonuses
     */
    function withdrawAllBonus() public nonReentrant checkSender{
        address winner=msg.sender;
        uint balance=getBalance();
        uint[] memory roundList=_userBetRound[winner];
        require(roundList.length>0,"Your bonus is not enough");

        uint querySize=roundList.length;
        if(querySize>maxQueryRound){
            querySize=maxQueryRound;
        }

        uint bonus=0;

        for(uint i=roundList.length;i>roundList.length-querySize;i--){
            bonus+=queryUnPaidBonus(winner,roundList[i-1]);
            _bonusWithdrawalStatus[roundList[i-1]][winner]=true;
        }

        require(bonus>0,"Your bonus is not enough");
        require(balance>=bonus,"Insufficient bonuses available");
        totalBonusPaid+=bonus;

        if(maxBonusWithdrawalRatio>0){
            uint maxBonus=(balance*maxBonusWithdrawalRatio)/100;
            bonus=bonus<maxBonus?bonus:maxBonus;
        }

        //Check if you need to pay taxes
        if(bonus>=minTaxThreshold && gameFeeConfig.winnerFeeRate>0 && fundAddress!=address(0)){
            uint fee=(bonus*gameFeeConfig.winnerFeeRate)/100;
            payable(fundAddress).transfer(fee);
            
            if(bonus-fee >0){
                payable(winner).transfer(bonus-fee);
            }
        }
        else{
            payable(winner).transfer(bonus);
        }

        emit WithdrawAllBonusEvt(winner,bonus);
    }

    /**========================================================================================================**/
    /**The basic settings of the contract, when the game runs stably, the management authority will be destroyed**/
    /**========================================================================================================**/

    /**
     * @dev Deposit initial funds
     */
    function depositInitFundPool() payable public{
        require(msg.value>0,"Deposit amount is 0");
        initFundPool+=msg.value;
    }

    /**
     * @dev Withdraw initial funds
     */
    function withdrawalInitFundPool(address to,uint amount) public onlyOwner{
        require(initFundPool>0,"InitFundPool balance is 0");
        require(amount<=initFundPool,"Withdrawal amount exceeds limit");
        initFundPool-=amount;
        payable(to).transfer(amount);
    }

    /**
     * @dev Withdraw LKY token
     */
    function withdrawLuckyToken(address to,uint amount) public onlyOwner{
        TransferHelper.safeTransfer(luckyToken,to,amount);
    }

    /**
     * @dev Controls the game state, usually closing the game when threatened
     */
    function setGameStatus(GameStatus status) external onlyOwner{
        gameStatus=status;
    }

    /**
     * @dev VRF Settings
     */
    function setVrfGasLimitAndConfirmations(uint32 gasLimit,uint8 confirmations,uint64 subscriptionId) external onlyOwner{
        vrfCallbackGasLimit=gasLimit;
        vrfRequestConfirmations=confirmations;
        vrfSubscriptionId=subscriptionId;
    }

    /**
     * @dev Adjust rates based on community consensus
     */
    function setFee(GameFee calldata feeConfig) external onlyOwner{
        gameFeeConfig=feeConfig;
    }

    /**
     * @dev Set the interval between each round
     */
    function setIntervalTime(uint time) external onlyOwner{
        roundIntervalTime=time;
    }

    /**
     * @dev Set the maximum number of rounds for query, exceeding this value will not be queried
     */
    function setQueryMaxRound(uint maxRound) external onlyOwner{
        maxQueryRound=maxRound;
    }

    /**
     * @dev Set the maximum bonus ratio for a single withdrawal
     */
    function setMaxBounsRate(uint8 rate) external onlyOwner{
        maxBonusWithdrawalRatio=rate;
    }

    /**
     * @dev Control contract access
     */
    function setAllowContract(bool isAllow) external onlyOwner{
        _allowContract=isAllow;
    }

    /**
     * @dev Set fund address
     */
    function setFundAddress(address addr) external onlyOwner{
        fundAddress=addr;
    }

    /**
     * @dev Set default referrer address
     */
    function setDefaultReferrerAddress(address addr) external onlyOwner{
        defaultReferrer=addr;
    }

    /**
     * @dev Configure reward native token
     */
    function setLuckyTokenConfig(address token,bool isReward,uint16 rewardMultiple) external onlyOwner{
        luckyToken=token;
        isRewardToken=isReward;
        rewardTokenMultiple=rewardMultiple;
    }

    /**
     * @dev Block malicious users
     */
    function addBlockUser(address user) external onlyOwner{
        require(_blockAddress[user]==false,"");
        _blockAddress[user]=true;
    }

    /**
     * @dev Unblock
     */
    function removeBlockUser(address user) external onlyOwner{
        require(_blockAddress[user]==true,"");
        delete _blockAddress[user];
    }

    receive() external payable {}
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

interface ILucky3ZooRuleV1Shared {
    struct LuckyNumber{
        uint8 n1;
        uint8 n2;
        uint8 n3;
        uint8 x;
        GameMode mode;
    }

    enum GameMode{
        Strict,
        Any,
        AnyTwo,
        AnyOne,
        X1,
        X2,
        X3
    }

}