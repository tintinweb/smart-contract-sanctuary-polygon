/**
 *Submitted for verification at polygonscan.com on 2022-11-04
*/

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: contracts/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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

    function burn(
        uint256 _amount
    )
        external;
}
// File: contracts/IceLottery.sol


 
pragma solidity >=0.8.7;




contract IceLottery is VRFConsumerBaseV2{
    
    mapping(uint => mapping(uint => address)) public tickets;
    uint public ticketCount;
    mapping(address => bool) public testPlayers;
    address public manager; 
    address public manager2; 
    address public burningAddress;
    bool isBurnDefined;
    uint public ticketPrice;
    address public lotteryToken;
    uint8 public winnersShare;
    uint8 public costAndDevShare;
    uint8 public burningShare;
    enum state {Open, PickingWinner, Closed, Suspended}
    state public lotteryState;
    uint public currentLotteryId;
    uint public currentLotteryOpenedTS;
    uint public currentLotteryOpenedBlockNumber;
    bool public closeFlag;
    bool public isTestMode;

	//VRF config
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd; //polygon 500gwei keyhash (configurable)
    uint16 requestConfirmations = 5;
    uint32 callbackGasLimit = 1000000;
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067; //hardcoded for polygon

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => uint256) public lotteryRequestIds;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    event TicketBought(
        uint indexed lotteryId,
        address indexed buyer,
        uint256 ticketCount,
        uint256 timestamp
    );

    event LotteryOpened(
        uint indexed lotteryId,
        uint256 timeStamp
    );
    
    event PrizeDistributed(
        uint indexed lotteryId,
        uint ticketCount,
        uint prize,
        address prizeToken,
        uint winnersAmount,
        uint devAmount,
        uint burnedAmount,
        uint startTime,
        uint endTime
    );
    
    constructor(uint _ticketPrice, address _lotteryToken, uint8 _winnersShare, uint8 _costAndDevShare, uint8 _burningShare, bool _isBurnDefined, uint64 _s_subscriptionId)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        manager = msg.sender;
        currentLotteryId = 0;
        lotteryState = state.Closed;
        changeConfig(_ticketPrice, _lotteryToken, _isBurnDefined, address(0), _winnersShare, _costAndDevShare, _burningShare);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator); //hardcoded for Mumbai
        s_subscriptionId = _s_subscriptionId;
    }    
    
    modifier onlyManager {
        require(msg.sender == manager || msg.sender == manager2);
        _;
    }

    function changeManagers(address _newManager, address _newManager2) external onlyManager{
        manager = _newManager;
        manager2 = _newManager2;
    }

    function changeConfig(uint _ticketPrice, address _lotteryToken, bool _isBurnDefined, address _burningAddress, uint8 _winnersShare, uint8 _costAndDevShare, uint8 _burningShare) public onlyManager{
        require(lotteryState == state.Closed);
        require(_winnersShare + _costAndDevShare + _burningShare == 100, "Share sum must be 100");
        require(_ticketPrice < 100000000000000000000000001, "Ticket price can't be over 100m"); //to prevent overflow
        ticketPrice = _ticketPrice;
        lotteryToken = _lotteryToken;
        isBurnDefined = _isBurnDefined;
        burningAddress = _burningAddress;
        winnersShare = _winnersShare;
        costAndDevShare = _costAndDevShare;
        burningShare = _burningShare;
    }

    function addTestPlayers(address[] calldata _testPlayers) external onlyManager{
        for(uint i = 0; i < _testPlayers.length; i++)
            testPlayers[_testPlayers[i]] = true;
    }
    
    function removeTestPlayers(address[] calldata _testPlayers) external onlyManager{
        for(uint i = 0; i < _testPlayers.length; i++)
            testPlayers[_testPlayers[i]] = false;
    }

    function closeLottery() external onlyManager{
        require(lotteryState != state.Closed);
        closeFlag = true;
    }

    function openLotteryExt() external onlyManager{
        require(lotteryState == state.Closed || lotteryState == state.Suspended);
        closeFlag = false;
        openLottery();
    }

    function toggleTestMode() external onlyManager{
        isTestMode = !isTestMode;
    }
    
    function suspendLottery() external onlyManager{
        lotteryState = state.Suspended;
    }
    
    function buyTicket(uint256 _ticketCount) external{
        require(lotteryState == state.Open);
        if(isTestMode)
            require(testPlayers[msg.sender], "Only testers can join the lottery at this stage");
        require(_ticketCount <= 1000, "You can't buy more then 1k ticket at once"); //To prevent overflow
        uint totalPrice = _ticketCount * ticketPrice;
        IERC20 tokenERC20 = IERC20(lotteryToken);
        require(tokenERC20.balanceOf(msg.sender) >= totalPrice, "Not enough balance");
        require(tokenERC20.allowance(msg.sender,address(this)) >= totalPrice, "Contract should be approved first");
        tokenERC20.transferFrom(msg.sender, address(this), totalPrice);
        emit TicketBought(currentLotteryId, msg.sender, _ticketCount, block.timestamp);
        uint prevCount = ticketCount;
        ticketCount += _ticketCount;
        unchecked{
            while(prevCount < ticketCount)
            {
                    tickets[currentLotteryId][prevCount] = msg.sender;
                    prevCount++;
            }
        }
    }
    
    function pickWinner() external onlyManager{
        require(lotteryState != state.Closed, "Lottery is not active");
        require(ticketCount >= 3, "Atleast 3 tickets needs to be purchased for the drawing");
        lotteryState = state.PickingWinner;

        requestRandomWords();
    }
    
    // calls Chainlink VRF to get a big random number
    function requestRandomWords() private returns(uint requestId){
       requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        lotteryRequestIds[currentLotteryId] = requestId;
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, 1);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override{
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }    

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function distributePrize() external onlyManager {
        address winner;
        // computing a random index of the array
        uint randomNumber = s_requests[lotteryRequestIds[currentLotteryId]].randomWords[0];
        uint index = randomNumber % ticketCount;
    
        winner = tickets[currentLotteryId][index]; // this is the winner
        IERC20 tokenERC20 = IERC20(lotteryToken);
        uint prizePot = tokenERC20.balanceOf(address(this));
        uint winnersShareAmount = prizePot * winnersShare / 100;
        uint costAndDevShareAmount = prizePot * costAndDevShare / 100;
        uint burningShareAmount = prizePot * burningShare / 100;
        tokenERC20.transfer(winner, winnersShareAmount);
        tokenERC20.transfer(manager, costAndDevShareAmount);
        if(isBurnDefined)
            tokenERC20.burn(burningShareAmount);
        else
            tokenERC20.transfer(burningAddress, burningShareAmount);

        emit PrizeDistributed(currentLotteryId, ticketCount, prizePot, lotteryToken, winnersShareAmount, costAndDevShareAmount, burningShareAmount, currentLotteryOpenedTS, block.timestamp);
        
        //resetting the lottery for the next round
        resetLottery();
    }

    function resetLottery() private{
        require (lotteryState == state.PickingWinner);
        ticketCount = 0;
        currentLotteryId++;
        if(closeFlag)
            lotteryState = state.Closed;
        else
            openLottery();
    }

    function openLottery() private{
        if(lotteryState == state.Closed || lotteryState == state.PickingWinner)
        {
            currentLotteryOpenedTS = block.timestamp;
            currentLotteryOpenedBlockNumber = block.number;
            emit LotteryOpened(currentLotteryId, block.timestamp);
        }
        lotteryState = state.Open;
    }

    function changeVrfGasLimit(uint32 _callbackGasLimit) external onlyManager{
        callbackGasLimit = _callbackGasLimit;
    }

    function changeChainlinkSubscriptionId(uint64 _s_subscriptionId) external onlyManager{
        s_subscriptionId = _s_subscriptionId;
    }
    
    function changeChainlinkKeyHash(bytes32 _keyHash) external onlyManager{
        keyHash = _keyHash;
    }
}