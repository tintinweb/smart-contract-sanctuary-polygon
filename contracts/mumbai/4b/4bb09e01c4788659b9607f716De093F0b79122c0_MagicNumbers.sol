/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

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

// File: contracts/recent/MagicNumbers.sol


pragma solidity ^0.8.9;




contract MagicNumbers is VRFConsumerBaseV2, AutomationCompatibleInterface{
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 1000000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    // uint32 constant NUM_WORDS = 1;
    uint32 constant NUM_WORDS = 20;

    uint256[] private s_randomWords;
    uint256 private s_requestId;
    address s_owner;
    address payable s_opVault;

    event ReturnedRandomness(uint256 indexed requestId);

    constructor(uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash, uint256 ticketPrice, 
        uint256 numberCeiling, address payable opVault
    ) VRFConsumerBaseV2(vrfCoordinator) {
        require(numberCeiling < 256, "Ceiling should be less than 256");
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_opVault = opVault;
        s_interval = 900; //15 minutes in Unix timestamp
        s_subscriptionId = subscriptionId;
        s_ticketPrice = ticketPrice;
        s_numberCeiling = numberCeiling;
        s_lastTimeStamp = block.timestamp;
        s_ticketCap = 10;
        s_lotteryCounter++;
        s_currentLottery = Lottery({
            lotteryId: s_lotteryCounter,
            selectedNumbers: new uint8[](0),
            resultsAnnounced: false
        });
        emit LotteryCreated(s_currentLottery.lotteryId);
        populatePrizeTable();
    }

    //TOP-LEVEL MODIFIERS / FUNCTIONS / VARIABLES

    receive() external payable {

    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function getContractValue()  external view onlyOwner returns(uint) {
        return address(this).balance;
    }


    //VRF LOGIC

    function requestRandomWords() internal onlyOwner returns (uint256 requestId){
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        return s_requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        // triggerLottery(s_randomWords[0]);
        triggerLotteryX(s_randomWords);
        delete currentLotteryTicketsId;
        s_lotteryCounter++;
        s_currentLottery = Lottery({
            lotteryId: s_lotteryCounter,
            selectedNumbers: new uint8[](0),
            resultsAnnounced: false
        });
        emit LotteryCreated(s_currentLottery.lotteryId);
        emit ReturnedRandomness(requestId);
    }

    // TICKETING AND GAME LOGIC

    uint256 public s_ticketPrice; 
    Lottery public s_currentLottery;
    uint256[] private currentLotteryTicketsId;
    mapping(uint256 => Lottery) public s_lotteries;
    mapping (address => Ticket[]) public s_tickets;
    mapping(uint256 => Ticket) public ticketsIndex;
    uint256 s_numberCeiling;
    uint256 private s_ticketCounter = 0;
    uint256 private s_lotteryCounter = 0;
    uint256 public s_ticketCap;
    uint8 public constant SELECTED_NUMBERS_UPPER_LIMIT_LOTTERY = 20;
    uint8 public constant SELECTED_NUMBERS_UPPER_LIMIT_USER = 10;
    //[hits or right guesses][selected numbers count] 
    uint32[11][11] private s_prizeTable;

    struct Lottery {
        uint256 lotteryId;
        uint8[] selectedNumbers;
        bool resultsAnnounced;
    }

    struct Ticket {
        uint256 ticketId;
        bool isItRedeemed;
        uint256 lotteryId;
        uint8[] selectedNumbers;
        address owner;
    }

    event TicketsBought(uint256[] ticketsId);
    event TicketCapModified(uint256 ticketCap);
    event TicketPriceModified(uint256 ticketPrice);
    event LotteryCreated(uint256 indexed lotteryId);
    event PrizeClaimed(uint256 indexed ticketId, uint256 prize);
    event LotteryTriggered(uint256 indexed lotteryId, uint8[] selectedNumbers);

    modifier ticketClaimabilityChecker(uint256 ticketId) {
        if(ticketsIndex[ticketId].owner != msg.sender) {
            revert("Ticket prize should be claimed by the owner of the ticket");
        }
        uint256 lotteryId = ticketsIndex[ticketId].lotteryId;
        if(s_lotteries[lotteryId].resultsAnnounced == false) {
            revert("The lottery results have not been announced.");
        }

        if(ticketsIndex[ticketId].isItRedeemed == true) {
            revert("Ticket has already been redeemed");
        }
        _;
    }

    modifier checkLotteryResultsAnnounced(uint256 ticketId) {
        require(ticketId <= s_ticketCounter, "The ticket has not been created.");
        uint256 lotteryId = ticketsIndex[ticketId].lotteryId;
        if(s_lotteries[lotteryId].resultsAnnounced == false) {
            revert("The lottery results have not been announced.");
        }
        _;
    }

    modifier ceilingCheck(uint8[] calldata selectedNumbers) {
        for(uint256 i = 0; i < selectedNumbers.length; i++) {
            require(selectedNumbers[i] <= s_numberCeiling, "Numbers must not exceed the ceiling");
        }
        _;
    }

    modifier uniqueArrayCheck(uint8[] calldata selectedNumbers) {
        uint length = selectedNumbers.length;
        bool[] memory encountered = new bool[](length);
        for(uint i = 0; i < length; i++) {
            for(uint j = i + 1; j < length; j++) {
                if(selectedNumbers[i] == selectedNumbers[j]) {
                    revert("Values should be unique");
                }
            }
        }
        _;
    }

    function modifyTicketsCap(uint256 ticketCap)  external onlyOwner  {
        s_ticketCap = ticketCap;
        emit TicketCapModified(s_ticketCap);
    }

    function modifyTicketPrice(uint256 newPrice)  external onlyOwner {
        s_ticketPrice = newPrice;
        emit TicketPriceModified(s_ticketPrice);
    }

    function getTicketsBought() external view returns(Ticket[] memory) {
        Ticket[] memory ticketsMemory = s_tickets[msg.sender];
        return ticketsMemory;
    }

    function getTicket(uint256 ticketId) external view returns(Ticket memory) {
        Ticket memory ticketMemory = ticketsIndex[ticketId];
        return ticketMemory;
    }

    function claimPrize(uint256 ticketId) ticketClaimabilityChecker(ticketId) external virtual {
        (uint256 m, uint256 prizeInEth) = calculatePrize(ticketId);
        if(m == 0 || prizeInEth == 0) {
            revert("There are no claimable prize");
        }
        // This code block is intended as a failsafe and should ideally never be triggered ;)
        if(address(this).balance < prizeInEth) {
        prizeInEth = address(this).balance;
        }
        ticketsIndex[ticketId].isItRedeemed = true;
        payable (msg.sender).transfer(prizeInEth);
        emit PrizeClaimed(ticketId, prizeInEth);
    }

    function buyTicket(uint32 numTickets, uint8[] calldata selectedNumbers) 
        external 
        payable 
        virtual
        ceilingCheck(selectedNumbers) 
        uniqueArrayCheck(selectedNumbers)
    {
        require(msg.value >= s_ticketPrice * numTickets, "Insufficient Ether sent");
        require(numTickets < s_ticketCap, "Tickets bought must not exceed the max amount or cap");
        require(selectedNumbers.length <= SELECTED_NUMBERS_UPPER_LIMIT_USER, "Selected numbers must be equal or less than 10");
        require(s_currentLottery.resultsAnnounced == false, "The lottery should not be concluded");
        require(s_currentLottery.selectedNumbers.length == 0, "The lottery should not be concluded");

        

        uint256[] memory ticketsIds = new uint256[](numTickets);
        uint8[] memory selectedNumbersFixed = selectedNumbers;
        
        for(uint256 i = 0; i < numTickets; i++) {
            s_ticketCounter += 1;
            Ticket memory ticket = Ticket({
                ticketId: s_ticketCounter,
                isItRedeemed: false,
                lotteryId: s_currentLottery.lotteryId,
                selectedNumbers: selectedNumbersFixed,
                owner: msg.sender
            });
            s_tickets[msg.sender].push(ticket);
            currentLotteryTicketsId.push(ticket.ticketId);
            ticketsIds[i] = s_ticketCounter;
            ticketsIndex[s_ticketCounter] = ticket;
        } 
        uint operationsCoverage = msg.value * 2 / 100;
        s_opVault.transfer(operationsCoverage);       
        emit TicketsBought(ticketsIds);
    }

    function calculatePrize(uint256 ticketId) 
        public 
        view 
        virtual 
        checkLotteryResultsAnnounced(ticketId) 
        returns(uint32, uint256) 
    {
        uint selectedNumbersCount = ticketsIndex[ticketId].selectedNumbers.length;
        uint8 count = calculateRightGuesses(ticketId);
        uint32 multiplier = s_prizeTable[count][selectedNumbersCount];
        uint256 prizeInEth = s_ticketPrice  * uint256(multiplier);
        return (multiplier, prizeInEth);
    }

    function getSelectedNumbers() public view returns(uint8[] memory) {
        require(s_lotteryCounter > 1, "There are no previous results yet");
        return s_lotteries[s_lotteryCounter - 1].selectedNumbers;

    }

    function calculateRightGuesses(uint256 ticketId) 
        public 
        view 
        virtual 
        checkLotteryResultsAnnounced(ticketId) 
        returns(uint8) 
    {
        uint8[] memory selectedNumbersUser = ticketsIndex[ticketId].selectedNumbers;
        uint8[] memory selectedNumbersLottery = s_lotteries[ticketsIndex[ticketId].lotteryId].selectedNumbers;
        bool[80] memory set;

        for(uint8 i = 0; i < selectedNumbersUser.length; i++) {
            set[selectedNumbersUser[i]] = true;
        }

        uint8 rightGuesses = 0;
        for(uint8 i = 0; i < selectedNumbersLottery.length; i++) {
            if(set[selectedNumbersLottery[i]]) {
                rightGuesses++;
            }
        }

        return rightGuesses;
    }

    function triggerLotteryX(uint256[] memory randomWords) internal virtual {
        uint8[] memory transitSelectedNumbers = new uint8[](20);
        bool repeated;
        //Lucky number 7 is arbitrary
        uint256 helperUint = 7777;
        uint256 helperCount = 0;
        for(uint256 i = 0; i < SELECTED_NUMBERS_UPPER_LIMIT_LOTTERY; i++) {
            helperCount++;
            uint256 number;
            number = (uint256(keccak256(abi.encodePacked(randomWords[i], i, block.timestamp, block.prevrandao ))) % s_numberCeiling) + 1;
            if(repeated) {
                helperUint + i;
                uint256 helper = uint256(keccak256(abi.encodePacked(block.timestamp, helperUint, block.prevrandao, helperCount)));
                number = (uint256(keccak256(abi.encodePacked(randomWords[i], i, block.timestamp, block.prevrandao, helper ))) % s_numberCeiling) + 1;
            }
            uint8 numberCast = uint8(number);
            if(!isNumberSelected(numberCast, transitSelectedNumbers)) {
                transitSelectedNumbers[i] = uint8(number);
                repeated = false;
            } else {
                repeated = true;
                i--;
            }
        }
        setLottery(transitSelectedNumbers, true);
        s_lotteries[s_currentLottery.lotteryId] = s_currentLottery;
        emit LotteryTriggered(s_currentLottery.lotteryId, transitSelectedNumbers);

    }

    // function triggerLottery(uint256 randomWord) internal virtual {
    //     uint8[] memory transitSelectedNumbers = new uint8[](20);
    //     bool repeated;
    //     //Lucky number 7 is arbitrary.
    //     uint256 helperUint = 7777;
    //     uint256 helperCount = 0;
    //     for(uint256 i = 0; i < SELECTED_NUMBERS_UPPER_LIMIT_LOTTERY; i++) {
    //         helperCount++;
    //         uint256 number;
    //         number = (uint256(keccak256(abi.encodePacked(randomWord, i, block.timestamp, block.prevrandao ))) % s_numberCeiling) + 1;
    //         if(repeated) {
    //             helperUint + i;
    //             uint256 helper = uint256(keccak256(abi.encodePacked(block.timestamp, helperUint, block.prevrandao, helperCount)));
    //             number = (uint256(keccak256(abi.encodePacked(randomWord, i, block.timestamp, block.prevrandao, helper ))) % s_numberCeiling) + 1;
    //         } 
    //         uint8 numberCast = uint8(number);
    //         if(!isNumberSelected(numberCast, transitSelectedNumbers)) {
    //             transitSelectedNumbers[i] = uint8(number);
    //             repeated = false;
    //         } else {
    //             repeated = true;
    //             i--;
    //         }
    //     }
    //     setLottery(transitSelectedNumbers, true);
    //     s_lotteries[s_currentLottery.lotteryId] = s_currentLottery;
    //     emit LotteryTriggered(s_currentLottery.lotteryId, transitSelectedNumbers);
    // }

    function setLottery(uint8[] memory selectedNumbers, bool result) internal virtual {
        s_currentLottery.selectedNumbers = selectedNumbers;
        s_currentLottery.resultsAnnounced = result;
    }

    function isNumberSelected(uint8 number, uint8[] memory transitSelectedNumbers) internal pure returns(bool) {
        for(uint i = 0; i < transitSelectedNumbers.length; i++) {
            if(transitSelectedNumbers[i] == number) {
                return true;
            }
        }

        return false;
    }

    function populatePrizeTable() private {
        s_prizeTable[1][1] = 3;
        s_prizeTable[1][2] = 1;

        s_prizeTable[2][2] = 6;
        s_prizeTable[2][3] = 3;
        s_prizeTable[2][4] = 1;
        s_prizeTable[2][5] = 1;

        s_prizeTable[3][3] = 25;
        s_prizeTable[3][4] = 5;
        s_prizeTable[3][5] = 2;
        s_prizeTable[3][6] = 1;
        s_prizeTable[3][7] = 1;

        s_prizeTable[4][4] = 120;
        s_prizeTable[4][5] = 10;
        s_prizeTable[4][6] = 8;
        s_prizeTable[4][7] = 4;
        s_prizeTable[4][8] = 2;
        s_prizeTable[4][9] = 1;
        s_prizeTable[4][10] = 1;

        s_prizeTable[5][5] = 380;
        s_prizeTable[5][6] = 55;
        s_prizeTable[5][7] = 20;
        s_prizeTable[5][8] = 10;
        s_prizeTable[5][9] = 5;
        s_prizeTable[5][10] = 2;

        s_prizeTable[6][6] = 2000;
        s_prizeTable[6][7] = 150;
        s_prizeTable[6][8] = 50;
        s_prizeTable[6][9] = 30;
        s_prizeTable[6][10] = 20;

        s_prizeTable[7][7] = 5000;
        s_prizeTable[7][8] = 1000;
        s_prizeTable[7][9] = 200;
        s_prizeTable[7][10] = 50;

        s_prizeTable[8][8] = 20000;
        s_prizeTable[8][9] = 4000;
        s_prizeTable[8][10] = 500;

        s_prizeTable[9][9] = 50000;
        s_prizeTable[9][10] = 10000;

        s_prizeTable[10][10] = 100000;
    }

    //AUTOMATION LOGIC
    uint256 public s_interval;
    uint256 public s_lastTimeStamp;

    event ChangeInterval(uint256 interval);

    function changeInterval(uint256 interval) external onlyOwner {
        s_interval = interval;
    }

    function checkUpkeep(bytes calldata)
        external 
        view 
        override 
        returns(bool upkeepNeeded, bytes memory)
    {
        bool lotteryTicketsCheck = currentLotteryTicketsId.length > 0;
        bool timestampCheck = (block.timestamp - s_lastTimeStamp) > s_interval;
        upkeepNeeded = lotteryTicketsCheck && timestampCheck;
        return (upkeepNeeded,abi.encode("0x"));
    }

    function performUpkeep(bytes calldata) 
        external 
        override 
    {

        bool lotteryTicketsCheck = currentLotteryTicketsId.length > 0;
        bool timestampCheck = (block.timestamp - s_lastTimeStamp) > s_interval;
        bool upkeepNeeded = lotteryTicketsCheck && timestampCheck;

        if(upkeepNeeded) {
            s_lastTimeStamp = block.timestamp;
            requestRandomWords();
        } else {
            revert("Not ready to trigger a lottery");
        }
    }
}