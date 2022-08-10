// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2022 BDE Technologies LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./token/vrf/VRFCoordinatorV2Interface.sol";
import "./token/vrf/VRFConsumerBaseV2.sol";

interface IP {
    function mint(uint256 countMint, address sender) external;
}

interface IPolygods {
    function name() external view returns (string calldata);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function activeListing(uint256 _tokenId) external view returns (Ask calldata);
}

struct Ask {
    bool hasAsk;
    uint256 tokenId;
    address seller;
    int256 valueInWei;
}

struct Stake {
    address owner;
    uint256 rewardRate;
    uint256 timestamp;
    bool hasPendingRoll;
}

struct PendingRoll {
    address owner;
    uint256 tokenId;
}

/** 
 * smatthewenglish
 */  
contract PolyDice is VRFConsumerBaseV2 {
  
    address public _polygods;
    address public _p;

    uint256 public _baslineReward;

    VRFCoordinatorV2Interface COORDINATOR;

    event RandomRequest(uint256 number);
    event RandomResult(uint256 number);

    /// release the hold once we know the result of the random number, if applicable
    mapping(uint256 => PendingRoll) private requestContainer;

   /** 
    * 0x0000000000000000000000000000000000000000 (owner) :
    * 
    *       - 1 (tokenId) : 
    *               - 03.28.2022 (timstamp)
    *               - 1 _p per day
    *
    *       - 2 (tokenId) : 
    *               - 03.29.2022 (timstamp)
    *               - 2 _p per day
    *
    *       - 3 (tokenId) : 
    *               - 03.26.2022 (timstamp)
    *               - 1 _p per day
    */
    mapping(address => mapping(uint256 => Stake)) public _ownerTokenStake;

    constructor(
        address polygods_,
        address p_,
        address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        
        _polygods = polygods_;
        _p = p_;

        _baslineReward = 1;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

   /**
    */
    function setRewardToken(address p_) public {
        _p = p_;
    }
  
   /** 
    */
    function setRewardRate(uint256 baslineReward_) public {
        _baslineReward = baslineReward_;
    }

   /**
    */
    function stake(uint256 tokenId) public {

        address sender = msg.sender;
        _checkForOwner(sender, tokenId);
        _checkForListing(tokenId);

        uint256 rewardRate = _baslineReward;
        uint256 timestamp = block.timestamp;
        bool hasPendingRoll = false;

        Stake memory instance = Stake(sender, rewardRate, timestamp, hasPendingRoll);

        /* * */

        _ownerTokenStake[sender][tokenId] = instance;
    }

    function unstake(uint256 tokenId) public {

        address sender = msg.sender;
        _checkForOwner(sender, tokenId);
        _checkForListing(tokenId);

        Stake memory instance = _ownerTokenStake[sender][tokenId];

        require(instance.owner == sender, "PolyDice: invalid sender");
        require(!instance.hasPendingRoll, "PolyDice: invalid operation");

        uint256 rewardRate = instance.rewardRate;

        uint256 duration = _getDuration(instance.timestamp);
        require(duration > 0, "PolyDice: invalid duration");

        uint256 reward = duration * rewardRate;
        IP(_p).mint(reward, sender);        
    }

    function roll(uint256 tokenId) public {

        address owner = msg.sender;
        _checkForOwner(owner, tokenId);
        _checkForListing(tokenId);

        Stake memory instance = _ownerTokenStake[owner][tokenId];
        require(!instance.hasPendingRoll, "PolyDice: invalid operation");
        
        uint256 duration = _getDuration(instance.timestamp);
        require(duration >= 1, "PolyDice: one roll per epoch");

        bool hasPendingRoll = true;
        _ownerTokenStake[owner][tokenId] = Stake(instance.owner, instance.rewardRate, instance.timestamp, hasPendingRoll);

        //requestId - A unique identifier of the request. Can be used to match
        //a request to a response in fulfillRandomWords.
        uint64 s_subscriptionId = 97;
        uint32 numWords = 1;
        uint16 requestConfirmations = 200; //Maximum Confirmations

        bytes32 keyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8; //polygon mainnet (1000 gwei)

        uint32 callbackGasLimit = 300000; 
        uint256 s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestContainer[s_requestId] = PendingRoll(owner, tokenId);

        emit RandomRequest(s_requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        
        PendingRoll memory pendingRoll = requestContainer[requestId];

        address owner = pendingRoll.owner;
        uint256 tokenId = pendingRoll.tokenId;
        bool hasPendingRoll = false;

        // transform the result to a number between 1 and 100 inclusively
        uint256 result = (randomWords[0] % 100) + 1;
        if (result >= 50){

            uint256 rewardRate = _baslineReward;
            uint256 timestamp = block.timestamp;
            
            Stake memory instance = Stake(owner, rewardRate, timestamp, hasPendingRoll);

            _ownerTokenStake[owner][tokenId] = instance;

        } else {

            Stake memory instance = _ownerTokenStake[owner][tokenId];
            uint256 timestamp = instance.timestamp;
            uint256 rewardRate00 = instance.rewardRate;
            uint256 rewardRate01 = rewardRate00 * 2;

            _ownerTokenStake[owner][tokenId] = Stake(owner, rewardRate01, timestamp, hasPendingRoll);

        }
        delete requestContainer[requestId];

        emit RandomResult(result);
    }

   /** 
    */
    function _getDuration(uint256 timestamp) view private returns (uint256) {
        uint256 timestamp00 = timestamp;
        uint256 timestamp01 = block.timestamp;
        uint256 duration = (timestamp01 - timestamp00) / (60 * 60 * 24);
        return duration;
    }

   /** 
    */
    function _checkForOwner(address sender, uint256 tokenId) view private {
        bool value = IPolygods(_polygods).ownerOf(tokenId) == sender;
        require(value, "PolyDice: invalid sender");
    }

   /** 
    */
    function _checkForListing(uint256 tokenId) view private {
        Ask memory ask = IPolygods(_polygods).activeListing(tokenId);
        bool hasAsk = ask.hasAsk;
        require(!hasAsk, "PolyDice: cancel listing to continue");
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
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

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.x;

/**
 * 03B
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