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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// import "hardhat/console.sol";

error Error__CreateRaffle();
error Error__EnterRaffle();
error Error__UpkeepNotTrue();
error Error__RafflePaymentFailed();
error Error__NotOwner();
error Error__ZeroAmount();
contract Deffle is VRFConsumerBaseV2, AutomationCompatibleInterface{

    enum RaffleState{
        Open,
        Calculating,
        Closed
    }

    struct Raffle{
        bytes32 raffleData;
        uint256 entranceFee;
        uint256 deadline;
        bytes passCode;
        uint8 maxTickets;
        address payable[] participants;
        address payable owner;
        RaffleState raffleState;
        uint256 raffleBalance;
        address payable raffleWinner;
    }

    //a mapping of id to Raffles
    mapping(uint256 => Raffle) public idToRaffle;
    //an array of all ids
    uint8[] idList;

    uint8 id;
    address payable public owner;
    uint256 public immutable creationFee;
    uint256 public immutable feePercent;
    uint256 public deffleEarnings;

    //creating an instatnce of vrfCoordinator
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    //chainlink variables
    bytes32 public i_gasLane;
    uint64 public i_subscriptionId;
    uint32 public i_callbackGasLimit;

    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    //keep track of raffle requesting randomness
    uint256 currentId;


    event Deffle__RaffleCreated(uint raffleId, address indexed raffleOwner);
    event Deffle__EnterRaffle(uint raffleId, address indexed participant, uint8 indexed totalParticipants);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event Deffle__WinnerPicked(uint raffleId, address indexed raffleWinner, uint indexed raffleEarnings);
    event Deffle__EarningsWithdrawn(uint indexed _deffleEarnings);
    constructor(address vrfCoordinatorV2,
        uint256 _creationFee,
        bytes32 gasLane, //keyhash 
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 _feePercent
    )
    VRFConsumerBaseV2(vrfCoordinatorV2)
    {
        owner = payable(msg.sender);
        creationFee = _creationFee;
        feePercent = _feePercent;
        //chainlinkstuff
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId ;
        i_callbackGasLimit = callbackGasLimit;
    }
    

    function createRaffle(bytes32 _raffleData,
    uint256 _entranceFee,
    uint256 _deadline,
    uint8 _maxTickets,
    bytes memory _passCode ) external payable{
        if(msg.value < creationFee ||
            _deadline < block.timestamp ||
            _maxTickets <= 1 ||
            _entranceFee <= 0){
            revert Error__CreateRaffle();
        }

        //update deffle earnings/creation fee balance
        deffleEarnings += msg.value;

        //Update the mapping with inputted data
        id = id + 1;
        idToRaffle[id].raffleData = _raffleData;
        idToRaffle[id].entranceFee = _entranceFee;
        idToRaffle[id].deadline = _deadline;
        idToRaffle[id].maxTickets = _maxTickets;
        idToRaffle[id].owner = payable(msg.sender);
        idToRaffle[id].raffleState= RaffleState.Open;
        idToRaffle[id].passCode= _passCode;

        //update idlist array
        idList.push(id);

        emit Deffle__RaffleCreated(id, msg.sender); 
        
    }

    function enterRaffle(uint256 raffleId, bytes memory _passCode) external payable{

        if((raffleId == 0) ||
        (idToRaffle[raffleId].raffleState != RaffleState.Open)||
        (msg.value < idToRaffle[raffleId].entranceFee)||
        (idToRaffle[raffleId].deadline < block.timestamp)||
        (idToRaffle[raffleId].participants.length == idToRaffle[raffleId].maxTickets)||
        (keccak256(idToRaffle[raffleId].passCode)  != keccak256(_passCode))||
        (idList.length < raffleId)||
        (msg.sender == idToRaffle[raffleId].owner)
        ){
            revert Error__EnterRaffle();
        }

        
        //update the array of participants
        idToRaffle[raffleId].participants.push(payable(msg.sender));
        idToRaffle[raffleId].raffleBalance += msg.value;

        //get total participants
        uint8 totalParticipants  = getNumberOfPlayers(raffleId);
        //emit enter raffle event
        emit Deffle__EnterRaffle(raffleId, msg.sender, totalParticipants);
    }

    function checkUpkeep(bytes memory /*checkdata */)
    public view override returns(
        bool upkeepNeeded,
        bytes memory performData 
    ){
        upkeepNeeded = false;
        uint8 sureId;
        for (uint256 i = 0; i < getIdList().length && !upkeepNeeded; i++) {
            bool isOpen = RaffleState.Open == getRaffleState(i+1);
            bool timePassed = block.timestamp > getDeadline(i+1);
            bool hasBalance  = getRaffleBalance(i+1) > 0;
            bool hasPlayers = getNumberOfPlayers(i+1) > 0;
            if (isOpen && timePassed && hasBalance && hasPlayers) {
                upkeepNeeded = true;
                sureId = uint8(i+1);
            }
        }
        return (upkeepNeeded, abi.encode(sureId));
    }

    function performUpkeep(bytes calldata /* performData*/ ) external override {

        (bool upkeepNeeded, bytes memory idInBytes) = checkUpkeep("0x");
        if(!upkeepNeeded){
            revert Error__UpkeepNotTrue();
        }

        currentId = abi.decode(idInBytes,(uint8));

        idToRaffle[currentId].raffleState = RaffleState.Calculating;
        //request random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS, 
            i_callbackGasLimit, 
            NUM_WORDS);
        emit RequestedRaffleWinner(requestId);
        
    }

    function fulfillRandomWords(
        uint256, /*request id*/
        uint256[] memory randomWords
    ) internal override{


        uint256 indexOfWinner = randomWords[0] % idToRaffle[currentId].participants.length;
        address payable _raffleWinner =  idToRaffle[currentId].participants[indexOfWinner];
        uint _raffleBalance = idToRaffle[currentId].raffleBalance;

        //update state variables
        idToRaffle[currentId].raffleWinner = _raffleWinner;
        idToRaffle[currentId].raffleState = RaffleState.Closed;
        idToRaffle[currentId].raffleBalance = 0;
        //calculate how much to pay winner;
        //calculate how much goes to owner of raffle
        (uint winnersPay, uint ownersPay) = getPaymentAmount(_raffleBalance, feePercent);
        //Pay winners and owner
        (bool success, ) = _raffleWinner.call{value: winnersPay}("");
        (bool success2, ) = idToRaffle[currentId].owner.call{value: ownersPay}("");
        //check
        if(!success && !success2){
            revert Error__RafflePaymentFailed();
        }
        emit Deffle__WinnerPicked(currentId, _raffleWinner, _raffleBalance);
        
    }


    function withdrawDeffleEarnings() external {
        if(msg.sender != owner){
            revert Error__NotOwner();
        }
        if(deffleEarnings == 0){
            revert Error__ZeroAmount();
        }

        uint _deffleEarnings = deffleEarnings;
        deffleEarnings = 0;
        
        (bool success, ) = owner.call{value: _deffleEarnings}("");
        //check
        if(!success){
            revert Error__RafflePaymentFailed();
        }
        emit Deffle__EarningsWithdrawn(_deffleEarnings);

    }

    /** Getter Functions */

    function getRaffleState(uint raffleId) public view returns (RaffleState) {
        return idToRaffle[raffleId].raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRaffleWinner(uint raffleId) public view returns (address) {
        return idToRaffle[raffleId].raffleWinner;
    }

    function getPlayers(uint raffleId) public view returns (address payable[] memory) {
        address payable[] storage tempArray = idToRaffle[raffleId].participants;
        return tempArray;
    }

    function getDeadline(uint raffleId) public view returns (uint256) {
        return idToRaffle[raffleId].deadline;
    }


    function getEntranceFee(uint raffleId) public view returns (uint256) {
        return idToRaffle[raffleId].entranceFee;
    }

    function getNumberOfPlayers(uint raffleId) public view returns (uint8) {
        return uint8(idToRaffle[raffleId].participants.length);
    }

    function getMaxPlayers(uint raffleId) public view returns (uint8) {
        return idToRaffle[raffleId].maxTickets;
    }
    function getRaffleBalance(uint raffleId) public view returns (uint) {
        return idToRaffle[raffleId].raffleBalance;
    }
    function getIdList() public view returns (uint8[] memory) {
        return idList;
    }
    function getRaffleOwner(uint raffleId) public view returns (address) {
        return idToRaffle[raffleId].owner;
    }
    //Pure Functions
    function getPaymentAmount(uint _balance, uint _feePercent) pure public returns(uint pay, uint charge){
        uint totalAmount = (_balance * (100 + _feePercent)/100);
        charge = totalAmount - _balance;
        pay = _balance - charge; 
    } 
    
}