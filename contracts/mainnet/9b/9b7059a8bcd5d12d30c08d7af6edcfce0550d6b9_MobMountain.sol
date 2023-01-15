//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function isApprovedForAll(address owner, address operator) external view returns (bool); 
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
  function mint(address someAddress, uint256 amt) external;
}

interface IBridge {
  function depositOnBehalfOf(uint256 _amount, address _consumable, address _actualOwner) external;
}

contract MobMountain is Pausable, VRFConsumerBaseV2, ConfirmedOwner  {
  address public immutable gemsAddress;
  address public immutable mobsAddress;
  address public immutable raidersAddress;
  address public bridgeAddress;
  address constant public BURN_ADDRESS = 0x1f0233b9Fd916B0304686338EC413fa2a824B28F;

  uint8[] public gemRewardRange;
  uint256 public deploymentTime;
  uint256 public stakedMobCount; // purely for informational purposes;

  bool public runningEnabled;

  uint256[] public stakedTokenIds;
  RunResults[101] public randomResultPool;

  mapping(Rarities => uint16) public mobRarityToMultiplier;
  mapping(uint256 => bool) public mobIdToStakedState;
  mapping(uint256 => bool) public mobTokenIdToBridgingDesired;

  mapping(uint256 => Rarities) public mobTokenIdToRarity;
  mapping(uint256 => RequestStatus) public requestIdToStatus;
  mapping(uint256 => uint256[]) public runnersPerWeek;

  mapping(uint256 => mapping(uint256 => RunStates)) public weeksToRaidersToRunState;  
  mapping(uint256 => mapping(uint256 => uint256)) public weeksToRaidersToRequestID;

  enum RunStates { NOT_RUN, RUN_BUT_WAITING_FOR_VRF, RETRIEVED }
  enum RunResults { NONE, SAFE_WITH_GEMS, SAFE_WITHOUT_GEMS, DEATH }
  enum Rarities { NONE, FODDER, COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC}

  event MobStaked(uint256 indexed mobId);
  event MobUnstaked(uint256 indexed mobId);

  event RunStarted(uint256 indexed weekIndex, uint256 indexed raiderId, uint requestId);
  event RunComplete(uint256 indexed weekIndex, uint256 indexed raiderId, uint256 indexed mobId, RunResults runResult, uint8 gemsRewarded);
  event RunCancelled(uint256 indexed weekIndex, uint256 indexed raiderId);

  constructor(
    uint64 subscriptionId,
    address _gemsAddress,
    address _mobsAddress,
    address _raidersAddress
)
    VRFConsumerBaseV2(	0xAE975071Be8F8eE67addBC1A82488F1C24858067)
    ConfirmedOwner(msg.sender)
{
    COORDINATOR = VRFCoordinatorV2Interface(0xAE975071Be8F8eE67addBC1A82488F1C24858067);
    s_subscriptionId = subscriptionId;

    require(_gemsAddress != address(0),"Need gem address");
    require(_mobsAddress != address(0),"Need mobs address");
    require(_raidersAddress != address(0),"Need raiders address");

    gemsAddress = _gemsAddress;
    mobsAddress = _mobsAddress;
    raidersAddress = _raidersAddress;
    deploymentTime = block.timestamp;
}

  /* VRF */
  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords);

  struct RequestStatus {
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists; // whether a requestId exists
    uint256[] randomWords;
    uint256 tokenId;
    uint256 weekIndex;
    bool bridge;
  }

  VRFCoordinatorV2Interface immutable COORDINATOR;

  // Your subscription ID.
  uint64 immutable s_subscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
  bytes32 constant keyHash =
      0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 500000;

  // The default is 3, but you can set this higher.
  uint16 constant requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 constant numWords = 3;

  /* VRF */

  function getRunnersPerWeek(uint256 weekIndex) external view returns (uint256[] memory) {
    return runnersPerWeek[weekIndex];
  }

  function getRandomResultPool() external view returns (RunResults[101] memory) {
    return randomResultPool;
  }

  function getRunStateForWeekAndRaider(uint256 weekIndex, uint256 raiderId) external view returns (RunStates) {
    return weeksToRaidersToRunState[weekIndex][raiderId];
  }

  function getRequestIdForWeekAndRaider(uint256 weekIndex, uint256 raiderId) external view returns (uint256) {
    return weeksToRaidersToRequestID[weekIndex][raiderId];
  }

  function getCurrentWeek() public view returns(uint256) {
    return (block.timestamp - deploymentTime) / 1 weeks;
  }

  function getAllMobTokenIds() external view returns(uint256[] memory) {
    return stakedTokenIds;
  }

  function getAvailableMobCountAfterWeighting() external view returns(uint256) {
    return stakedTokenIds.length;
  }

  function getActualRewardRange() external view returns (uint8[] memory) {
    return gemRewardRange;
  }

  modifier onlyMobOwner(uint256 tokenId) {
    require(IERC721(mobsAddress).ownerOf(tokenId) == msg.sender,"Not your mob");
    _;
   }

  function stakeMob(uint256 tokenId) external whenNotPaused onlyMobOwner(tokenId) {
    require(!mobIdToStakedState[tokenId], "Already Staked!");
    require(mobTokenIdToRarity[tokenId] != Rarities.NONE, "not init");

    mobIdToStakedState[tokenId] = true;
    stakedMobCount += 1;

    if (stakedMobCount == 0) {
      stakedTokenIds.push(0);
    }

    uint16 thisMultiplier = mobRarityToMultiplier[mobTokenIdToRarity[tokenId]];
    for (uint16 i; i < thisMultiplier; i++) {
      stakedTokenIds.push(tokenId);
    }
    emit MobStaked(tokenId);
  }

  function unstakeMob(uint256 tokenId) external whenNotPaused onlyMobOwner(tokenId) {
    require(mobIdToStakedState[tokenId], "Not Staked!");

    mobIdToStakedState[tokenId] = false;
    stakedMobCount -= 1;
    uint256[] memory oldArray = stakedTokenIds;
    delete stakedTokenIds;
    for (uint i; i < oldArray.length; i++) {
      uint thisVal = oldArray[i];
      if (thisVal != tokenId) {
        stakedTokenIds.push(thisVal);
      }
    }
    emit MobUnstaked(tokenId);
  }

  function isBridgingEnabled() public view returns(bool) {
    return bridgeAddress != address(0);
  }

  function beginRun(uint256 tokenId, bool bridge) external whenNotPaused  {
    require(runningEnabled, "cant run");

    if (bridge) {
      require(isBridgingEnabled(), "cant bridge");
    }

    uint256 thisWeek = getCurrentWeek();
    require(IERC721(raidersAddress).ownerOf(tokenId) == msg.sender,"Not yours");

    require(IERC721(raidersAddress).isApprovedForAll(msg.sender, address(this)),"no perms");
    require(stakedTokenIds.length <= 2,"No Mobs");
    require(weeksToRaidersToRunState[thisWeek][tokenId] == RunStates.NOT_RUN, "run began");

    weeksToRaidersToRunState[thisWeek][tokenId] = RunStates.RUN_BUT_WAITING_FOR_VRF;
    runnersPerWeek[getCurrentWeek()].push(tokenId);
    
    // Will revert if subscription is not set and funded.
    uint requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    requestIdToStatus[requestId] = RequestStatus({
      randomWords: new uint256[](0),
      exists: true,
      fulfilled: false,
      tokenId: tokenId,
      weekIndex: thisWeek,
      bridge: bridge
    });

    weeksToRaidersToRequestID[thisWeek][tokenId] = requestId;

    emit RunStarted(thisWeek, tokenId, requestId);
  }

  function finishRun(RequestStatus memory request) internal {
    uint tokenId = request.tokenId;
    address raiderOwner = IERC721(raidersAddress).ownerOf(tokenId);

    if (IERC721(raidersAddress).isApprovedForAll(raiderOwner, address(this))) {
      require(stakedTokenIds.length > 0,"No Mobs");
      require(weeksToRaidersToRunState[request.weekIndex][tokenId] == RunStates.RUN_BUT_WAITING_FOR_VRF, "Already began run for this week");
      require(request.fulfilled,"VRF not fufilled");

      weeksToRaidersToRunState[request.weekIndex][tokenId] = RunStates.RETRIEVED;

      uint finalRunResultIndex = paddedRandomPull(request.randomWords[0], randomResultPool.length - 1);

      RunResults finalRunResult = randomResultPool[finalRunResultIndex];

      uint gemRewardIndex = paddedRandomPull(request.randomWords[1], gemRewardRange.length - 1);
      uint8 gemReward = gemRewardRange[gemRewardIndex];

      uint pickedMobTokenIdIndex = paddedRandomPull(request.randomWords[2], stakedTokenIds.length - 1);
      uint pickedMobTokenId = stakedTokenIds[pickedMobTokenIdIndex];
      handleResult(request.weekIndex, finalRunResult, raiderOwner, tokenId, pickedMobTokenId, gemReward, request.bridge);
    } else {
      emit RunCancelled(request.weekIndex, tokenId);
    }
  }

  function handleResult(uint256 weekIndex, RunResults finalRunResult, address raiderOwner, uint256 raiderTokenId, uint256 pickedMobTokenId, uint8 gemReward, bool raiderBridging) internal {
    if (finalRunResult == RunResults.SAFE_WITH_GEMS) {
      distributeGems(gemReward, raiderOwner, raiderBridging);
    } else {
      address mobOwner = IERC721(mobsAddress).ownerOf(pickedMobTokenId);
      distributeGems(gemReward, mobOwner, mobTokenIdToBridgingDesired[pickedMobTokenId]);
      if (finalRunResult == RunResults.DEATH) {
        IERC721(raidersAddress).safeTransferFrom(raiderOwner, BURN_ADDRESS, raiderTokenId);
      }
    }
    emit RunComplete(weekIndex, raiderTokenId, pickedMobTokenId, finalRunResult, gemReward);
  }

  function distributeGems(uint8 gemReward, address recipient, bool bridge) internal {
    if (bridge) {
      IBridge(bridgeAddress).depositOnBehalfOf(gemReward, gemsAddress, recipient);
    } else {
      IERC20(gemsAddress).mint(recipient, gemReward);
    }
  }

  function fulfillRandomWords(
      uint256 _requestId,
      uint256[] memory _randomWords
  ) internal override {
      require(requestIdToStatus[_requestId].exists, "not found");
      requestIdToStatus[_requestId].fulfilled = true;
      requestIdToStatus[_requestId].randomWords = _randomWords;
      emit RequestFulfilled(_requestId, _randomWords);
      finishRun(requestIdToStatus[_requestId]);
  }

  function getRequestStatus(
      uint256 _requestId
  ) external view returns (bool fulfilled, uint256[] memory randomWords) {
      require(requestIdToStatus[_requestId].exists, "not found");
      RequestStatus memory request = requestIdToStatus[_requestId];
      return (request.fulfilled, request.randomWords);
  }

  function updateMobBridgingChoice(uint256 tokenId, bool bridgeDesired) external onlyMobOwner(tokenId) {
    mobTokenIdToBridgingDesired[tokenId] = bridgeDesired;
  }

  function paddedRandomPull(uint256 someRandom, uint256 someMax) internal pure returns (uint256) {
    return (someRandom % someMax) + 1;
  }

  // ---------- ADMIN FUNCTIONS ----------

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function updateBridgeAddress(address newAddress) external onlyOwner {
    bridgeAddress = newAddress;
  }

  function setNewBaseTime(uint256 newTime) external onlyOwner {
    deploymentTime = newTime;
  }

  function updateMobRarity(uint256 tokenId, Rarities rarity) external onlyOwner {
    assert(rarity != Rarities.NONE);
    mobTokenIdToRarity[tokenId] = rarity;
  }

  function updateMobRarities(uint256[2][] calldata sets) external onlyOwner {
    for(uint i; i < sets.length; i++) {
      Rarities castRarity = Rarities(sets[i][1]);
      assert(castRarity != Rarities.NONE);
      mobTokenIdToRarity[sets[i][0]] = castRarity;
    }
  }

  function updateMobMultiplier(Rarities rarityInt, uint16 rarityMultipler) external onlyOwner {
    mobRarityToMultiplier[rarityInt] = rarityMultipler;
  }

  function updateResultThresholds(uint8[3] memory thresholds) external onlyOwner {
    require(thresholds[0] + thresholds[1] + thresholds[2] == 100,"not 100");
    delete randomResultPool;
    randomResultPool[0] = RunResults.NONE;
    RunResults firstCode = RunResults.SAFE_WITH_GEMS;
    RunResults secondCode = RunResults.SAFE_WITHOUT_GEMS;
    RunResults thirdCode = RunResults.DEATH;

    uint8 counter = 1;

    for(uint8 i = 0; i < thresholds[0]; i++) {
      randomResultPool[counter] = firstCode;
      counter++;
    }

    for(uint8 i = 0; i < thresholds[1]; i++) {
      randomResultPool[counter] = secondCode;
      counter++;    
    }

    for(uint8 i = 0; i < thresholds[2]; i++) {
      randomResultPool[counter] = thirdCode;
      counter++;
    }
  }

  function forceUnstake() external onlyOwner {
    delete stakedTokenIds;
    stakedMobCount = 0;
  }

  function updateCallbackGasLimit(uint32 newLimit) external onlyOwner {
    callbackGasLimit = newLimit;
  }

  function updateRunningEnabled(bool canRun) external onlyOwner {
    runningEnabled = canRun;
  }

  function updateRewardRange(uint8 min, uint8 max) external onlyOwner {
    delete gemRewardRange;
    gemRewardRange.push(0);
    for(uint8 i = min; i < (max + 1); i++) {
      gemRewardRange.push(i);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
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
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/MobMountain.sol";

abstract contract $IERC721 is IERC721 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

abstract contract $IERC20 is IERC20 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

abstract contract $IBridge is IBridge {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

contract $MobMountain is MobMountain {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(uint64 subscriptionId, address _gemsAddress, address _mobsAddress, address _raidersAddress) MobMountain(subscriptionId, _gemsAddress, _mobsAddress, _raidersAddress) {}

    function $COORDINATOR() external view returns (VRFCoordinatorV2Interface) {
        return COORDINATOR;
    }

    function $s_subscriptionId() external view returns (uint64) {
        return s_subscriptionId;
    }

    function $keyHash() external pure returns (bytes32) {
        return keyHash;
    }

    function $callbackGasLimit() external view returns (uint32) {
        return callbackGasLimit;
    }

    function $requestConfirmations() external pure returns (uint16) {
        return requestConfirmations;
    }

    function $numWords() external pure returns (uint32) {
        return numWords;
    }

    function $finishRun(MobMountain.RequestStatus calldata request) external {
        return super.finishRun(request);
    }

    function $handleResult(uint256 weekIndex,MobMountain.RunResults finalRunResult,address raiderOwner,uint256 raiderTokenId,uint256 pickedMobTokenId,uint8 gemReward,bool raiderBridging) external {
        return super.handleResult(weekIndex,finalRunResult,raiderOwner,raiderTokenId,pickedMobTokenId,gemReward,raiderBridging);
    }

    function $distributeGems(uint8 gemReward,address recipient,bool bridge) external {
        return super.distributeGems(gemReward,recipient,bridge);
    }

    function $fulfillRandomWords(uint256 _requestId,uint256[] calldata _randomWords) external {
        return super.fulfillRandomWords(_requestId,_randomWords);
    }

    function $paddedRandomPull(uint256 someRandom,uint256 someMax) external pure returns (uint256) {
        return super.paddedRandomPull(someRandom,someMax);
    }

    function $_validateOwnership() external view {
        return super._validateOwnership();
    }

    function $_pause() external {
        return super._pause();
    }

    function $_unpause() external {
        return super._unpause();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}