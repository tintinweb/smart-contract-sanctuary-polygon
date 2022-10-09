// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./LibraryStruct.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // we inherit from the interfaces just to make sure that we implement those functions
import "./IRaffleMarketplace.sol";

/*
    TODO:
    register the contract with chainlink keepers
    send prizes to the winners - need to discuss this
    send the money collected to the hoster - need to discuss this
    if the threshold is not passed, revert the lottery and send the tickets money back to the players
   

 */

error Raffle__NotEnougEthEntered();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 state, uint256 balance, uint256 playersLength);
error Raffle__OnlyHosterAllowed();

contract RaffleContract is VRFConsumerBaseV2, KeeperCompatibleInterface {
   

    // interface of marketplace contract to update the winners
    IRaffleMarketplace raffleMarketplace;

    // mapping with stageType to stages in a raffle
    mapping(uint256 => Stage.RaffleStage) raffleStages;
    // array of raffle stages
    Stage.RaffleStage[] raffleStagesArray;

    // players struct to track which player bought which ticket at what price, needed to send the money back if the lottery is reverted
    struct Players {
        uint256 ticketPrice;
        address player;
    }

    // raffle id in the marketplace contract
    uint256 raffleId;
    // how long should the raffle go on
    uint256 durationOfRaffle;
    // minimum amount of money collected from selling the tickets to say that the raffle is successfull
    uint256 threshold;
    // hoster of raffle
    address payable raffleOwner;
    // no of winners to pick, equal to the number of prizes available
    uint32 noOfWinnersToPick;
    // array of players entered in the raffle
    Players[] private s_players;
    // state of raffle - OPEN,CALCULATIN
    Stage.RaffleState private s_raffleState;
    // current stage in which the raffle is in - SALE,PRESALE etc. converted to uint
    uint256 private currentStage;

    // Chainlink variables

    // vrfCoordinatorV2 contract which we use to reques the random number
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    // minimum gas we are willing to pay
    bytes32 private immutable i_gasLane;
    // our contract subscription id
    uint64 private immutable i_subscriptionId;
    // how much confirmations should the chainlink node wait before sending the response
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    // how much gas should chainlink node use while calling fulfillRandomWords of our contract
    uint32 private immutable i_callbackGasLimit;
    // array of winners picked after the raffle is completed
    address[] private s_recentWinners;

    //events
    event RaffleEntered(address indexed player);
    // event emitted when we request a random number
    event RequestedRaffleWinner(uint256 indexed reqId);
    // event emitted when a player enters a raffle
    event WinnersPicked(address payable[] indexed winners);

    constructor(
        uint256 _raffleId,
        uint256 _durationOfRaffle,
        uint256 _threshold,
        address payable _raffleOwner,
        uint32 _noOfWinnersToPick,
        Stage.RaffleStage[] memory _stages,
        address vrfCoordinatorV2,uint64 subscriptionId
        
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        raffleId = _raffleId;
        durationOfRaffle = _durationOfRaffle;
        threshold = _threshold;
        raffleOwner = _raffleOwner;
        noOfWinnersToPick = _noOfWinnersToPick;
        _addStageInStorage(_stages);

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit =100000;
        raffleMarketplace = IRaffleMarketplace(msg.sender);
        // once a raffle contract is deployed, the state is OPEN
        s_raffleState = Stage.RaffleState.OPEN;
    }

    // Enter the raffle
    //TODO: update tickets sold in raffle stages array
    function enterRaffle() external payable isRaffleOpen {
        // we check if the total tickets of current stage are sold
        /* For example, there are 100 tickets in PRESALE stage and all 100 are sold, then we automatically move to SALE stage whose ticket price is higher*/
        if (raffleStages[currentStage].ticketsSold == raffleStages[currentStage].ticketsAvailable) {
            updateCurrentStage();
        }

        Stage.RaffleStage storage curStage = raffleStages[currentStage];
        // if money sent is less than the ticket price, revert
        if (msg.value < curStage.ticketPrice) {
            revert Raffle__NotEnougEthEntered();
        }
        // calculate how much tickets did the user bought
        // for example, if the ticket price is 10 MATIC and the user sent 100 MATIC, then the tickets bought = 10
        // more the tickets bought, more is the chance of winning the raffle
        uint256 ticketsBought = msg.value / curStage.ticketPrice;
        curStage.ticketsSold += ticketsBought;
        for (uint256 i = 0; i < ticketsBought; i++) {
            s_players.push(Players(curStage.ticketPrice, msg.sender));
        }
        raffleMarketplace.updateTicketsSold(raffleId,curStage.stageType,curStage.ticketsSold);
        emit RaffleEntered(msg.sender);
    }

    // //internal function used to update the current stage to  next stage
    function updateCurrentStage() internal {
        uint256 nextStageType = currentStage + 1;
        if (
            uint256(raffleStages[nextStageType].stageType) == nextStageType &&
            raffleStages[nextStageType].ticketsAvailable != 0
        ) {
            currentStage = currentStage + 1;
             raffleMarketplace.updateCurrentOngoingStage(raffleId,Stage.StageType(currentStage));
        }

       
    }

    /* This func is called by chainlink keeper node to check if we can perform upkeep or not
    If the result is true, then we pick a random number:
    1. The time interval of raffle should end
    2. The threshold should pass
    3. Our subscription is funded with link
    4. The lottery should be in OPEN state
    */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData */
        )
    {
        bool isOpen = (s_raffleState == Stage.RaffleState.OPEN);
        bool isTimeFinished = (block.timestamp > durationOfRaffle);
        bool hasBalance = (address(this).balance >= threshold);
        bool hasThreshold = isThresholdPassed();
        bool hasPlayers = (s_players.length > 0);
        upkeepNeeded = (isOpen && isTimeFinished && hasPlayers && hasBalance && hasThreshold);
    }

    // to pick a random winner
    // get a random numbber and do something with it
    // chainlink vrf is a 2 tx process, its intentional as having it in 2 txs is better than having in 1tx, to prevent the manipulation

    // This function just requests for a random number, some other func will return the random no
    function performUpkeep(
        bytes memory /*performUpkeep */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                uint256(s_raffleState),
                address(this).balance,
                s_players.length
            );
        }

        s_raffleState = Stage.RaffleState.CALCULATING;
        raffleMarketplace.updateRaffleState(raffleId,s_raffleState);
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane or key hash - the maximum number of gas in wei you are willing to spend for random number,
            i_subscriptionId, // the id of the subscription of chainlink vrf,
            REQUEST_CONFIRMATIONS, // requestConfirmations - How many confirmations the chhainlink node should wait before sending the response
            i_callbackGasLimit, // callbackGasLimit - how many gas should the chainlink node use to call fulfill random words of our contract
            noOfWinnersToPick // noOfWinnersToPick - how many random numbers  to pick
        );
        emit RequestedRaffleWinner(requestId);
    }

    // returns the random number, this func is called by chainlink vrf
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override {
        address payable[] memory winners = new address payable[](noOfWinnersToPick);
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 randomIndex = randomWords[i] % s_players.length;
            winners[i] = (payable(s_players[randomIndex].player));
        }
        s_recentWinners = winners;
        // update the winners in the marketplace contract
        raffleMarketplace.updateWinners(raffleId, winners);
        s_raffleState = Stage.RaffleState.FINISHED;
        raffleMarketplace.updateRaffleState(raffleId,s_raffleState);
        emit WinnersPicked(winners);
    }

    // function to revert the lottery if its not successfull
    function revertLottery() external onlyHoster{
        require(s_raffleState==Stage.RaffleState.OPEN);
        for (uint256 i = 0; i < s_players.length; i++) {
            payable(s_players[i].player).transfer(s_players[i].ticketPrice);
        }
        s_raffleState = Stage.RaffleState.REVERTED;
        raffleMarketplace.updateRaffleState(raffleId,s_raffleState);
    }

    function _addStageInStorage(Stage.RaffleStage[] memory _stages) internal {
        for (uint256 i = 0; i < _stages.length; i++) {
            raffleStages[uint256(_stages[i].stageType)] = (
                Stage.RaffleStage(
                    _stages[i].stageType,
                    _stages[i].ticketsAvailable,
                    _stages[i].ticketPrice,
                    0
                )
            );
            raffleStagesArray.push(Stage.RaffleStage(
                    _stages[i].stageType,
                    _stages[i].ticketsAvailable,
                    _stages[i].ticketPrice,
                    0
                ));
        }

        currentStage = uint256(_stages[0].stageType);
    }

    function getRaffleId() public view returns (uint256){
        return raffleId;
    }

    function getEntraceFee() public view returns (uint256) {
        return raffleStages[currentStage].ticketPrice;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index].player;
    }

    function getRecentWinners() public view returns (address[] memory) {
        return s_recentWinners;
    }

    function getCurrentStage() public view returns (Stage.RaffleStage memory) {
        return raffleStages[currentStage];
    }

    function getStages() public view returns(Stage.RaffleStage[] memory) {
        return raffleStagesArray;
    }

    function getStageInformation(uint256 stageType) public view returns(Stage.RaffleStage memory){
        return raffleStages[stageType];
    } 
    // TODO: doesnt work fix this
    function totalTicketsSold() public view returns(uint256) {
        uint256 count = 0;
        for (uint32 i = 0; i < raffleStagesArray.length; i++) {
            count += raffleStagesArray[i].ticketsSold;
        }
        return count;
    }
    function totalTickets() public view returns(uint256) {
        uint256 count = 0;
        for (uint32 i = 0; i < raffleStagesArray.length; i++) {
            count += raffleStagesArray[i].ticketsAvailable;
        }
        return count;
    }
    function ticketsSoldByStage(uint256 stageType) public view returns(uint256) {
        return raffleStages[stageType].ticketsSold;
    }

    // TODO: doesnt work fix this
    function getCurrentThresholdValue() public view returns (uint256) {
       return (totalTicketsSold() /totalTickets() )*100;
    }

    function isThresholdPassed() public view returns (bool) {
        bool isThreshold = (getCurrentThresholdValue()>=threshold);
        return isThreshold;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }



    modifier isRaffleOpen() {
        if (s_raffleState != Stage.RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        _;
    }

    modifier onlyHoster() {
        if(msg.sender!=raffleOwner){
            revert Raffle__OnlyHosterAllowed();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Stage {
    struct RaffleStage {
        StageType stageType;
        uint256 ticketsAvailable;
        uint256 ticketPrice;
        uint256 ticketsSold;
    }

    enum StageType{
            PRESALE,SALE,PREMIUM
    }

     enum RaffleState {
        NOT_INITIALIZED,
        OPEN,
        CALCULATING,
        FINISHED,
        REVERTED
    }
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
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./LibraryStruct.sol";

interface IRaffleMarketplace{
    function updateWinners(uint256 raffleId, address payable[] memory winners) external;
   function updateCurrentOngoingStage(uint256 id, Stage.StageType stageType) external;
   function updateTicketsSold(uint256 id, Stage.StageType stageType,uint256 ticketsSold) external ;
    function updateRaffleState(uint256 id, Stage.RaffleState  state) external;
}

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