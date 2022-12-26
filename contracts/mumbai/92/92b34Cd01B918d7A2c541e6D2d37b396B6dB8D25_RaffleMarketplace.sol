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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

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
pragma solidity ^0.8.8;

import "./LibraryStruct.sol";

interface IRaffleMarketplace{
    function updateWinners(uint256 raffleId, address payable[] memory winners) external;
   function updateCurrentOngoingStage(uint256 id, RaffleLibrary.StageType stageType) external;
   function updateTicketsSold(uint256 id, RaffleLibrary.StageType stageType,uint256 ticketsSold,address rafflePlayer) external;
    function updateRaffleState(uint256 id, RaffleLibrary.RaffleState  state) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library RaffleLibrary {
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

    enum RaffleCategory {
        COLLECTIBLE,
        HOME_IMPROVEMENT,
        
        FASHION,
        FOOD_AND_BEVERAGES,
        HEALTH_AND_BEAUTY,
        JEWELLERY,
        MISCELLANEOUS,
        REALTY,
        SPORTS,
        TECH,
        VEHICLES
    }

    // The countries which are supported for delivering/collecting the prize
    enum PrizeCollectionCountry {
        UKRAINE,
        UK
    }

    // Prize structure for a raffle - A raffle can have multiple prizes
    struct RafflePrize {
      
        string prizeTitle;
        PrizeCollectionCountry country;
        uint256 prizeAmount;
    }

    // Information about charity if a hoster wants to donate some revenue amount to charity via charity's wallet address
    struct CharityInformation {
        string charityName;
        address payable charityAddress;
        uint256 percentToDonate;
    }

    // Main Raffle Structure
    struct Raffle {
        uint256 id; // Raffle No
        bool isVerifiedByMarketplace; // has that raffle been verified by the marketplace so that it can be opened
        address raffleAddress; // address of the raffle contract deployed
        RaffleCategory category; // raffle category
        string title; // title/main prize of raffle can be written here
        string description;
        uint256 raffleDuration; // how long will the raffle go on once starts
        uint256 threshold;  // if we sold x number of tickers, then the raffle ends even tho if its before the end duration
        string[] images; // ipfs uploaded uris of images of main raffle prize
        CharityInformation charityInfo; // information about charity
        address payable[] winners; // winners of the raffle
        // country from where the prize is to be collected / delivery where the prize can be delivered
        RaffleState raffleState; // state of the raffle, init as not_initialized
       
    }

    struct Players {
        uint256 ticketPrice;
        address player;
    }

    function _shuffle(Players[] memory players) internal view returns(address[] memory) {
        address[] memory shuffledPlayers =  new address [](players.length);
    for (uint256 i = 0; i < players.length; i++) {
        uint256 n = uint256(keccak256(abi.encodePacked(block.timestamp))) % (players.length - i) + i;
        shuffledPlayers[i]=players[n].player;
    }
    return shuffledPlayers;
    }

    


    
}

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
error Raffle__NotEnoughTicketsAvailable();
error Raffle__OnlyMarketplaceOwnerAllowed();
error Raffle__RaffleNotOpen(RaffleLibrary.RaffleState raffleState);
error Raffle__RaffleNotFinished();

contract RaffleContract is VRFConsumerBaseV2, KeeperCompatibleInterface {
    // interface of marketplace contract to update the winners
    IRaffleMarketplace raffleMarketplace;

    // mapping with stageType to stages in a raffle
    mapping(uint256 => RaffleLibrary.RaffleStage) raffleStages;
    // array of raffle stages
    RaffleLibrary.RaffleStage[] raffleStagesArray;

    // players struct to track which player bought which ticket at what price, needed to send the money back if the lottery is reverted

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
    RaffleLibrary.Players[] private s_players;
    // state of raffle - OPEN,CALCULATIN
    RaffleLibrary.RaffleState private s_raffleState;
    // current stage in which the raffle is in - SALE,PRESALE etc. converted to uint
    uint256 private currentStage;

    address marketplaceOwner;

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

    RaffleLibrary.RafflePrize[] private prizes;

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
        address _marketplceOwner,
        RaffleLibrary.RafflePrize[] memory _prizes,
        RaffleLibrary.RaffleStage[] memory _stages,
        address vrfCoordinatorV2,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        raffleId = _raffleId;
        durationOfRaffle = block.timestamp + _durationOfRaffle;
        threshold = _threshold;
        raffleOwner = _raffleOwner;
        _addPrizeInStorage(_prizes);
        _addStageInStorage(_stages);
        noOfWinnersToPick = uint32(prizes.length);
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = 2500000;
        raffleMarketplace = IRaffleMarketplace(msg.sender);
        // once a raffle contract is deployed, the state is OPEN
        s_raffleState = RaffleLibrary.RaffleState.OPEN;
        marketplaceOwner = _marketplceOwner;
    }

    // Enter the raffle
    //TODO: fix error here
    function enterRaffle() external payable isRaffleOpen {
        // we check if the total tickets of current stage are sold
        /* For example, there are 100 tickets in PRESALE stage and all 100 are sold, then we automatically move to SALE stage whose ticket price is higher*/
        updateCurrentStage();
        RaffleLibrary.RaffleStage storage curStage = raffleStages[currentStage];
        // if money sent is less than the ticket price, revert
        if (msg.value < curStage.ticketPrice) {
            revert Raffle__NotEnougEthEntered();
        }
        // calculate how much tickets did the user bought
        // for example, if the ticket price is 10 MATIC and the user sent 100 MATIC, then the tickets bought = 10
        // more the tickets bought, more is the chance of winning the raffle
        uint256 ticketsBought = msg.value / curStage.ticketPrice;

        if (ticketsBought > (curStage.ticketsAvailable - curStage.ticketsSold)) {
            revert Raffle__NotEnoughTicketsAvailable();
        }
        curStage.ticketsSold += ticketsBought;
        for (uint256 i = 0; i < ticketsBought; i++) {
            s_players.push(RaffleLibrary.Players(curStage.ticketPrice, msg.sender));
        }
        for (uint256 i = 0; i < raffleStagesArray.length; i++) {
            if (raffleStagesArray[i].stageType == curStage.stageType) {
                raffleStagesArray[i].ticketsSold += ticketsBought;
            }
        }
        // TODO: uncomment this after tests
        raffleMarketplace.updateTicketsSold(raffleId, curStage.stageType, ticketsBought,msg.sender);
        updateCurrentStage(); //TODO: Not working, need to fix this, critical 
        emit RaffleEntered(msg.sender);
    }

    //TODO: fix this major bug!!!!
    // //internal function used to update the current stage to  next stage
    function updateCurrentStage() internal {
        uint256 nextStageType;
        if (raffleStages[currentStage].ticketsSold == raffleStages[currentStage].ticketsAvailable) {

            for (uint256 i = 0; i < raffleStagesArray.length; i++) {
             
                if (
                    uint256(raffleStagesArray[i].stageType) > currentStage &&
                    raffleStagesArray[i].ticketsAvailable != 0
                ) { 
                  
                    nextStageType = uint256(raffleStagesArray[i].stageType);
                    currentStage = nextStageType;
                    
                    raffleMarketplace.updateCurrentOngoingStage(
                        raffleId,
                        RaffleLibrary.StageType(currentStage)
                    );
                }
            }
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
        bool isOpen = (s_raffleState == RaffleLibrary.RaffleState.OPEN);
        bool isTimeFinished = (block.timestamp > durationOfRaffle);
        bool hasThreshold = isThresholdPassed();
        bool hasPlayers = (s_players.length > 0);
        upkeepNeeded = (isOpen && isTimeFinished && hasPlayers && hasThreshold);
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

        s_raffleState = RaffleLibrary.RaffleState.CALCULATING;
        // TODO: uncomment below after test
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
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        address[] memory temp = RaffleLibrary._shuffle(s_players);
        address payable[] memory winners = new address payable[](noOfWinnersToPick);
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 randomIndex = randomWords[i] % s_players.length;
            winners[i] = (payable(temp[randomIndex]));
        }
        s_recentWinners = winners;
        // update the winners in the marketplace contract
        raffleMarketplace.updateWinners(raffleId, winners);
        s_raffleState = RaffleLibrary.RaffleState.FINISHED;
        raffleMarketplace.updateRaffleState(raffleId, s_raffleState);

        emit WinnersPicked(winners);
    }

    // function to revert the lottery if its not successfull
    function revertLottery() external onlyHoster onlyMarketplaceOwner {
        require(s_raffleState == RaffleLibrary.RaffleState.OPEN);
        for (uint256 i = 0; i < s_players.length; i++) {
            payable(s_players[i].player).transfer(s_players[i].ticketPrice);
        }
        s_raffleState = RaffleLibrary.RaffleState.REVERTED;
        raffleMarketplace.updateRaffleState(raffleId, s_raffleState);
    }

    function distributePrizes() public onlyMarketplaceOwner {
        if (s_raffleState != RaffleLibrary.RaffleState.FINISHED) {
            revert Raffle__RaffleNotFinished();
        }
        uint256 count = 0;
        for (uint256 i = 0; i < prizes.length; i++) {
            if (prizes[i].prizeAmount != 0 && count < s_recentWinners.length) {
                (bool sent, ) = payable(s_recentWinners[count]).call{value: prizes[i].prizeAmount}(
                    ""
                );
                count++;
                require(sent);
            }
        }
    }

    function _addStageInStorage(RaffleLibrary.RaffleStage[] memory _stages) internal {
        for (uint256 i = 0; i < _stages.length; i++) {
            raffleStages[uint256(_stages[i].stageType)] = (
                RaffleLibrary.RaffleStage(
                    _stages[i].stageType,
                    _stages[i].ticketsAvailable,
                    _stages[i].ticketPrice,
                    0
                )
            );

            raffleStagesArray.push(
                RaffleLibrary.RaffleStage(
                    _stages[i].stageType,
                    _stages[i].ticketsAvailable,
                    _stages[i].ticketPrice,
                    0
                )
            );
        }

        currentStage = uint256(_stages[0].stageType);
    }

    function _addPrizeInStorage(RaffleLibrary.RafflePrize[] memory _prizes) internal {
        for (uint256 i = 0; i < _prizes.length; i++) {
            prizes.push(
                RaffleLibrary.RafflePrize(

                    _prizes[i].prizeTitle,
                    _prizes[i].country,
                    _prizes[i].prizeAmount
                )
            );
        }
    }

    function _sendFundsToMarketplace() external onlyMarketplaceOwner {
        (bool sent, ) = address(raffleMarketplace).call{value: address(this).balance}("");
        require(sent);
    }

    function getRaffleId() public view returns (uint256) {
        return raffleId;
    }

    function getPlayers() public view returns (RaffleLibrary.Players[] memory) {
        return s_players;
    }

    function getEntraceFee() external view returns (uint256) {
        return raffleStages[currentStage].ticketPrice;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinners() external view returns (address[] memory) {
        return s_recentWinners;
    }

    function getCurrentStage() external view returns (RaffleLibrary.RaffleStage memory) {
        return raffleStages[currentStage];
    }

    function getStages() external view returns (RaffleLibrary.RaffleStage[] memory) {
        return raffleStagesArray;
    }

    function getStageInformation(uint256 stageType)
        external
        view
        returns (RaffleLibrary.RaffleStage memory)
    {
        return raffleStages[stageType];
    }

    function getCurrentState() external view returns (RaffleLibrary.RaffleState) {
        return s_raffleState;
    }

    function totalTicketsSold() public view returns (uint256) {
        uint256 count = 0;
        for (uint32 i = 0; i < raffleStagesArray.length; i++) {
            count += raffleStagesArray[i].ticketsSold;
        }
        return count;
    }

    function totalTickets() public view returns (uint256) {
        uint256 count = 0;
        for (uint32 i = 0; i < raffleStagesArray.length; i++) {
            count += raffleStagesArray[i].ticketsAvailable;
        }
        return count;
    }

    function ticketsSoldByStage(uint256 stageType) external view returns (uint256) {
        return raffleStages[stageType].ticketsSold;
    }

    function getCurrentThresholdValue() public view returns (uint256) {
        return (totalTicketsSold() * 100) / totalTickets();
    }

    function isThresholdPassed() public view returns (bool) {
        bool isThreshold = (getCurrentThresholdValue() >= threshold);
        return isThreshold;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    modifier isRaffleOpen() {
        if (s_raffleState != RaffleLibrary.RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        _;
    }

    modifier onlyHoster() {
        _onlyHoster();
        _;
    }

    function _onlyHoster() internal view {
        if (msg.sender != raffleOwner) {
            revert Raffle__OnlyHosterAllowed();
        }
    }

    modifier onlyMarketplaceOwner() {
        _onlyMarketplaceOwner();
        _;
    }

    function _onlyMarketplaceOwner() internal view {
        if (msg.sender != marketplaceOwner) {
            revert Raffle__OnlyMarketplaceOwnerAllowed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


// The raffle contract where people will directly interact to enter / win a raffle
import "./Raffle.sol";
// A Library to contain RaffleStage struct in both the contracts
import "./LibraryStruct.sol";

import "./RegisterUpkeep.sol";
import "./VRFSubscribe.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// It means throw an error when the raffle does not exist
error RaffleMarketplace__InvalidTickerId();
// It means throw an error when the raffle has not been deployed as in created yet
error RaffleMarketplace__RaffleNotCreated(uint256 id);
// It means only the hoster of raffle can access specific functions
error RaffleMarketplace__OnlyHosterAllowed(address caller, address hoster);
error RaffleMarketplace__OnlyOwnerAllowed();
error RaffleMarketplace__PrizeDoesNotExist(uint256 raffleId, uint256 prizeId);
error RaffleMarketplace__PrizeAlreadyExist(uint256 raffleId, uint256 prizeId);
error RaffleMarketplace__StageAlreadyExist(uint256 raffleId, RaffleLibrary.StageType stageType);
// error RaffleMarketplace__StageDoesNotExist(uint256 raffleId,Stage.StageType stageType);

error RaffleMarketplace__StageDoesNotExist(uint256 raffleId, RaffleLibrary.StageType stageType);
error RaffleMarketplace__RaffleNotVerified();
error RaffleMarketplace__RaffleVerified();

// error RaffleMarketplace__PrizeDoesNotExist(uint256 raffleId, uint256 prizeId);

contract RaffleMarketplace is  VRFV2SubscriptionManager,RaffleRegisterUpkeep {
    /*
        1. Create raffle
        2. Cancel raffle (to be done before the winner is picked, and send the money back to the people)

        */


    event RaffleCreated(
        uint256 indexed raffleTicker,
        address  hoster,
        RaffleLibrary.Raffle  raffle,
        RaffleLibrary.RaffleStage[] stages,
        RaffleLibrary.RafflePrize[] prizes,
        RaffleLibrary.StageType ongoingStage
    );
    event RaffleVerified(uint256 indexed raffleTicker, address indexed deployedRaffle);
    event RaffleStageAdded(uint256 indexed raffleTicker, RaffleLibrary.RaffleStage  stage);
    event RaffleWinnersPicked(uint256 indexed raffleTicker, address payable[]  winners);
    event RaffleStateUpdated(uint256 indexed raffleTicker, RaffleLibrary.RaffleState indexed state);
    event RaffleStageTicketPriceUpdated(
        uint256 indexed raffleTicker,
        RaffleLibrary.StageType indexed stageType,
        uint256 indexed price
    );
    event RaffleStageTicketAvailabilityUpdated(
        uint256 indexed raffleTicker,
        RaffleLibrary.StageType indexed stageType,
        uint256 indexed availability
    );
    event RaffleTicketBought(
        uint256 indexed raffleTicker,
        RaffleLibrary.StageType indexed stageType,
        uint256 indexed ticketsBought,
        address  rafflePlayer
    );
    event RaffleStageUpdated(uint256 indexed raffleTicker,RaffleLibrary.StageType indexed currentStage);

    // To keep track of the raffles
    uint256 raffleTicker;
    

    // Different raffle categories, entered by frontend
    
    // Chainlink VRF

   
    

    //Chainlink Keepers

   

    constructor(address vrfCoordinator,address linkTokenAddress,address registrar) VRFV2SubscriptionManager(vrfCoordinator, linkTokenAddress) RaffleRegisterUpkeep(linkTokenAddress,registrar) {
        // initializes raffleTicker to 1
        raffleTicker = 1;
        owner = msg.sender;
    }

    // mapping of raffle identifer to raffles created
    mapping(uint256 => RaffleLibrary.Raffle) _raffles;
    // mapping of raffle identifer to raffles hosters
    mapping(uint256 => address) _raffleHosterAddress;
    // mapping of raffle identifer to raffle prizes
    mapping(uint256 => RaffleLibrary.RafflePrize[]) _raffleToRafflePrizes;
    // mapping of raffle identifer to raffle stages
    mapping(uint256 => RaffleLibrary.RaffleStage[]) _raffleToRaffleStages;
    // mapping of raffle identifer to ongoing stages
    mapping(uint256 => RaffleLibrary.StageType) _raffleToOngoingStages;

    // creates a raffle
    // TODO: emit createdRaffle event
    function createRaffle(
        RaffleLibrary.RaffleCategory _category,
        string memory title,
        string memory description,
        uint256 raffleDuration,
        uint256 threshold,
        string[] memory images,
        RaffleLibrary.RafflePrize[] memory prizes,
        RaffleLibrary.CharityInformation memory charityInfo,
        RaffleLibrary.RaffleStage[] memory stages
        
    ) external {
        // adds raffle to the mapping
        address payable[] memory winners = new address payable[](prizes.length);
        RaffleLibrary.Raffle memory raffleStruct = RaffleLibrary.Raffle(
            raffleTicker,
            false,
            address(0),
            _category,
            title,
            description,
            raffleDuration,
            threshold,
            images,
            charityInfo,
            winners,
        
            RaffleLibrary.RaffleState.NOT_INITIALIZED
        );
        
        _raffles[raffleTicker] = raffleStruct;

        // adds stages to the mapping by raffle id
        _addStageInStorage(stages);
        // adds prizes to the mapping by raffle id
        
        _addPrizeInStorage(prizes);
        // adds hoster of the raffle to mapping by raffle id
        _raffleHosterAddress[raffleTicker] = msg.sender;


        //TODO: fix this, the stage doesnt work if the stage is not 0 initially
        _raffleToOngoingStages[raffleTicker] = stages[0].stageType;

        emit RaffleCreated(
            raffleTicker,
            msg.sender,
            _raffles[raffleTicker],
            _raffleToRaffleStages[raffleTicker],
            _raffleToRafflePrizes[raffleTicker],
            _raffleToOngoingStages[raffleTicker]
        );
        // increments raffle id for next raffle
        raffleTicker++;
    }

    // A User only enters the raffle details, once the owner of marketplace verifies that it is genuine, then the raffle starts and is open for entries
    /*
     TODO:
     update the depployed with correct args
     */

    // once a raffle is created, marketplace owner verifies it and starts the raffle by deploying the raffle contract
    function verifyRaffle(uint256 id) external invalidTickerId(id) doesRaffleExists(id) onlyOwner {
        uint32 gasLimit = 5000000;
        uint96 amount =5 ether;
        bytes memory data = new bytes(0);
        // get the raffle of that id
        RaffleLibrary.Raffle storage raffleStruct = _raffles[id];
        // verify the raffle
        _raffles[id].isVerifiedByMarketplace = true;
        raffleStruct.raffleState = RaffleLibrary.RaffleState.OPEN;

        // deploy the raffle contract
        RaffleContract raffle = new RaffleContract(
            id,
            raffleStruct.raffleDuration,
            raffleStruct.threshold,
            payable(_raffleHosterAddress[id]),
            owner,
            _raffleToRafflePrizes[id],
            _raffleToRaffleStages[id],
            address(COORDINATOR),
            s_subscriptionId
        );

        //update the deployed address in the raffle struct

        _raffles[id].raffleAddress = address(raffle);
        //  _raffles[id].raffleState = RaffleLibrary.RaffleState.OPEN;
        emit RaffleStateUpdated(id, _raffles[id].raffleState);
      
        addConsumer(_raffles[id].raffleAddress);
        registerAndPredictID(_raffles[id].title,data,_raffles[id].raffleAddress,gasLimit,owner,data,amount,110);

        // emit a raffle verified event
        emit RaffleVerified(id, address(raffle));
    }

    // function to add new stages to a raffle - can only be called before the marketplace owner verifies and starts the raffle
    /*
    TODO: add modifier to check if the raffle is not verified before allowing to add a stage
    
    */
    function addStage(
        uint256 raffleId,
        RaffleLibrary.StageType stageType,
        uint256 ticketsAvailable,
        uint256 ticketPrice
    )
        external
        invalidTickerId(raffleId)
        onlyRaffleHoster(raffleId)
        isRaffleNotVerified(raffleId)
        raffleStageNotExists(raffleId, stageType)
    {
        // gets the next stage id

        RaffleLibrary.RaffleStage memory stage = RaffleLibrary.RaffleStage(
            stageType,
            ticketsAvailable,
            ticketPrice,
            0
        );
        _raffleToRaffleStages[raffleId].push(stage);
        emit RaffleStageAdded(raffleId, stage);
    }


    // function to modify the ticket price of a particular stage - can only be called before the owner verifies the raffle
    // TODO: add modifier to check if the raffle is only in created state not openeed
    function modifyStagePrice(
        uint256 raffleId,
        RaffleLibrary.StageType stageType,
        uint256 ticketAmount
    )
        external
        invalidTickerId(raffleId)
        onlyRaffleHoster(raffleId)
        isRaffleNotVerified(raffleId)
        doesRaffleExists(raffleId)
        raffleStageExists(raffleId, stageType)
    {
        RaffleLibrary.RaffleStage[] storage stages = _raffleToRaffleStages[raffleId];
        for (uint256 i = 0; i < stages.length; i++) {
            if (stages[i].stageType == stageType) {
                stages[i].ticketPrice = ticketAmount;
            }
        }
        emit RaffleStageTicketPriceUpdated(raffleId, stageType, ticketAmount);
    }

    // function to modify the number of tickets available in the stage- can only be called before the owner verifies the raffle
    function modifyStageTickets(
        uint256 raffleId,
        RaffleLibrary.StageType stageType,
        uint256 ticketsAvailable
    )
        external
        invalidTickerId(raffleId)
        onlyRaffleHoster(raffleId)
        doesRaffleExists(raffleId)
        isRaffleNotVerified(raffleId)
        raffleStageExists(raffleId, stageType)
    {
        RaffleLibrary.RaffleStage[] storage stages = _raffleToRaffleStages[raffleId];
        for (uint256 i = 0; i < stages.length; i++) {
            if (stages[i].stageType == stageType) {
                stages[i].ticketsAvailable = ticketsAvailable;
            }
        }
        emit RaffleStageTicketAvailabilityUpdated(raffleId, stageType, ticketsAvailable);
    }

   

   
    

    // internal function to add stage passed in memory as storage
    function _addStageInStorage(RaffleLibrary.RaffleStage[] memory _stages) internal {
        for (uint256 i = 0; i < _stages.length; i++) {
            _raffleToRaffleStages[raffleTicker].push(
                RaffleLibrary.RaffleStage(
                    _stages[i].stageType,
                    _stages[i].ticketsAvailable,
                    _stages[i].ticketPrice,
                    0
                )
            );
        }
    }

    // internal function to add prize passed in memory as storage
    function _addPrizeInStorage(RaffleLibrary.RafflePrize[] memory _prizes) internal {
        for (uint256 i = 0; i < _prizes.length; i++) {
            _raffleToRafflePrizes[raffleTicker].push(
                RaffleLibrary.RafflePrize(_prizes[i].prizeTitle, _prizes[i].country, _prizes[i].prizeAmount)
            );
        }
    }

   

    // function to be called by the raffle contract to update the winners of a raffle
    function updateWinners(uint256 id, address payable[] memory winners)
        external
        onlyRaffleContract(id)
    {
        _raffles[id].winners = winners;
        emit RaffleWinnersPicked(id, winners);
    }

    function updateRaffleState(uint256 id, RaffleLibrary.RaffleState state)
        external
        onlyRaffleContract(id)
    {
        _raffles[id].raffleState = state;
        emit RaffleStateUpdated(id, state);
    }

    function updateTicketsSold(
        uint256 id,
        RaffleLibrary.StageType stageType,
        uint256 ticketsBought, address rafflePlayer

    ) external onlyRaffleContract(id) {
        for (uint256 i = 0; i < _raffleToRaffleStages[id].length; i++) {
            if (_raffleToRaffleStages[id][i].stageType == stageType) {
                _raffleToRaffleStages[id][i].ticketsSold = _raffleToRaffleStages[id][i].ticketsSold + ticketsBought;
                emit RaffleTicketBought(
                    id,
                    _raffleToRaffleStages[id][i].stageType,
                 ticketsBought,
                    rafflePlayer
                );
            }
        }
    }

    function updateCurrentOngoingStage(uint256 id, RaffleLibrary.StageType stageType)
        external
        onlyRaffleContract(id)
    {
        _raffleToOngoingStages[id] = stageType;
        emit RaffleStageUpdated(id,stageType);
    }

    // returns next ticker of the raffle to be created
    function getNextTickerId() external view returns (uint256) {
        return raffleTicker;
    }

    // returns all the information of the raffle using raffle id / ticker
    function getRaffleById(uint256 id)
        external
        view
        invalidTickerId(id)
        doesRaffleExists(id)
        returns (
            RaffleLibrary.Raffle memory,
            RaffleLibrary.RafflePrize[] memory,
            RaffleLibrary.RaffleStage[] memory
        )
    {
        return (_raffles[id], _raffleToRafflePrizes[id], _raffleToRaffleStages[id]);
    }

    // returns the address of hoster and the raffle info using id

    // returns only the hoster of a raffle by id
    function getRaffleHosterById(uint256 id)
        external
        view
        invalidTickerId(id)
        doesRaffleExists(id)
        returns (address)
    {
        return _raffleHosterAddress[id];
    }

    
  

    // returns stage information of the raffle
    function getRaffleStagesById(uint256 id)
        public
        view
        invalidTickerId(id)
        doesRaffleExists(id)
        returns (RaffleLibrary.RaffleStage[] memory)
    {
        return _raffleToRaffleStages[id];
    }

    function getParticularRaffleStage(uint256 id, RaffleLibrary.StageType stageType)
        external
        view
        invalidTickerId(id)
        raffleStageExists(id, stageType)
        returns (RaffleLibrary.RaffleStage memory)
    {
        RaffleLibrary.RaffleStage[] memory stage = getRaffleStagesById(id);
        for (uint256 i = 0; i < stage.length; i++) {
            if (stage[i].stageType == stageType) {
                return stage[i];
            }
        }
    }

    function getOngoingRaffleStage(uint256 id) public view returns (RaffleLibrary.StageType) {
        return _raffleToOngoingStages[id];
    }

    // returns address of the deployed raffle contract
    function getRaffleAddress(uint256 id)
        external
        view
        invalidTickerId(id)
        doesRaffleExists(id)
        returns (address)
    {
        return _raffles[id].raffleAddress;
    }

    function getRaffleVerificationInfo(uint256 id)
        external
        view
        invalidTickerId(id)
        doesRaffleExists(id)
        returns (bool)
    {
        return _raffles[id].isVerifiedByMarketplace;
    }

    // checks if the raffle is deployed
    function _doesRaffleExists (uint256 id) view private  {
        if (_raffles[id].id == 0) {
            revert RaffleMarketplace__RaffleNotCreated(id);
        }
        
    }

     modifier doesRaffleExists(uint256 id){
         _doesRaffleExists(id);
         _;
     }

    // checks that the entered id is not <=0
    function _invalidTickerId(uint256 _id) pure internal {
        if (_id <= 0) {
            revert RaffleMarketplace__InvalidTickerId();
        }
        
    }

    modifier  invalidTickerId(uint256 _id){
        _invalidTickerId(_id);
        _;
    }

    // checks that only the raffle hoster can call the function
    function _onlyRaffleHoster(uint256 _id) internal view {
        if (msg.sender != _raffleHosterAddress[_id]) {
            revert RaffleMarketplace__OnlyHosterAllowed(msg.sender, _raffleHosterAddress[_id]);
        }
        
    }

    modifier onlyRaffleHoster(uint256 _id){
        _onlyRaffleHoster(_id);
        _;
    }

    // checks if a particular stage exists
    function _raffleStageExists(uint256 raffleId, RaffleLibrary.StageType stageType) view internal {
        if (!doesRaffleStageExists(raffleId, stageType)) {
            revert RaffleMarketplace__StageDoesNotExist(raffleId, stageType);
        }
        
    }

    modifier raffleStageExists(uint256 raffleId, RaffleLibrary.StageType stageType){
        _raffleStageExists(raffleId,stageType);
        _;
    }

    // checks if a particular stage does not exists
    function _raffleStageNotExists(uint256 raffleId,RaffleLibrary.StageType stageType) view  internal {
        if (doesRaffleStageExists(raffleId, stageType)) {
            revert RaffleMarketplace__StageAlreadyExist(raffleId, stageType);
        }

    
    }

    modifier  raffleStageNotExists(uint256 raffleId,RaffleLibrary.StageType stageType){
        _raffleStageNotExists(raffleId, stageType);
        _;
    }



    function _onlyRaffleContract(uint256 id)  view internal {
        require(
            (msg.sender == _raffles[id].raffleAddress) && (_raffles[id].raffleAddress != address(0))
        );
        
    }

    modifier onlyRaffleContract(uint256 id){
        _onlyRaffleContract(id);
        _;
    }

    // same function to see if stage exists or not
    function doesRaffleStageExists(uint256 raffleId, RaffleLibrary.StageType stageType)
        public
        view
        returns (bool)
    {
        RaffleLibrary.RaffleStage[] memory stage = getRaffleStagesById(raffleId);

        bool stageExists;
        for (uint256 i = 0; i < stage.length; i++) {
            if (stage[i].stageType == stageType) {
                stageExists = true;
            }
        }
        return stageExists;
    }

   
    
    // to check if the raffle is verified
    function _isRaffleVerified(uint256 id) view private {
        if (!_raffles[id].isVerifiedByMarketplace) {
            revert RaffleMarketplace__RaffleNotVerified();
        }
        
    }

    modifier isRaffleVerified(uint256 id){
        _isRaffleVerified(id);
        _;
    }

    //to check if the raffle is not verified
    function _isRaffleNotVerified(uint256 id) view private {
        if (_raffles[id].isVerifiedByMarketplace) {
            revert RaffleMarketplace__RaffleVerified();
        }
        
    }

    modifier isRaffleNotVerified(uint256 id) {
        _isRaffleNotVerified(id);
_;
    }

   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// UpkeepIDConsumerExample.sol imports functions from both ./AutomationRegistryInterface1_2.sol and
// ./interfaces/LinkTokenInterface.sol

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
* THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
* THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
* DO NOT USE THIS CODE IN PRODUCTION.
*/

interface KeeperRegistrarInterface {
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source,
    address sender
  ) external;
}

contract RaffleRegisterUpkeep {
  LinkTokenInterface public immutable i_link;
  address public immutable registrar;
  
  bytes4 registerSig = KeeperRegistrarInterface.register.selector;

  constructor(
    address _link,
    address _registrar
 
  ) {
    i_link = LinkTokenInterface(_link);
    registrar = _registrar;

  }

  function registerAndPredictID(
    string memory name,
    bytes memory encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes memory checkData,
    uint96 amount,
    uint8 source
  ) public {
    
    bytes memory payload = abi.encode(
      name,
      encryptedEmail,
      upkeepContract,
      gasLimit,
      adminAddress,
      checkData,
      amount,
      source,
      address(this)
    );
    
    i_link.transferAndCall(registrar, amount, bytes.concat(registerSig, payload));
 
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';


contract VRFV2SubscriptionManager   {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator ;
    address owner;

    // Goerli LINK token contract. For other networks, see
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address link_token_contract ;

    

    

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.


    // Storage parameters
    
    
    uint64 public s_subscriptionId;
    

    constructor(address _vrfCoordinator, address linkToken)  {
        vrfCoordinator = _vrfCoordinator;
        link_token_contract = linkToken;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        owner=msg.sender;
        
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
    }

    // Assumes the subscription is funded sufficiently.
    
    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() internal onlyOwner  {
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) public onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    }

    function addConsumer(address consumerAddress) public onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    function getSubscription() external view returns(uint256){
        return s_subscriptionId;
    }

    function _onlyOwner() view internal{
        require(msg.sender==owner);
        
          
    }
    modifier onlyOwner(){
        _onlyOwner();
        _;
    }
    
}