// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../system/HSystemChecker.sol';
import '../../../common/Multicall.sol';
import '../ITreasury.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import './RaffleTicket.sol';

/// @dev Raffle contract
contract Raffle is VRFConsumerBaseV2, HSystemChecker, Multicall {
    address public _treasuryContractAddress;
    ITreasury _treasury;

    address public _vrfCoordinatorAddress;
    VRFCoordinatorV2Interface _vrfCoordinator;

    struct RaffleEventStruct {
        uint256 randomNumber; // VRF generated random number
        uint64 ticketPrice; // Ticket Price $MILK in gwei
        uint48 startTimestamp; // UNIX timestamp of Raffle starting time
        uint48 endTimestamp; // UNIX timestamp of Raffle ending time
        uint32 maxTicketCount; // Maximum ticket count per Raffle, if 0, then unlimited
        uint16 maxWinnerCount; // Max count of winners
        uint32[] winTicketIds; // 1-D array of win ticketIDs
        address ticketAddress;
    }

    // ---------- Raffle Structure Example -------------
    //
    // Raffle Event#1
    //
    // entryId  buyer   firstTicketId   lastTicketId
    // entry#1  Zara    1               100          Zara buy 100 tickets
    // entry#2  Simon   101             200          Simon buy 100 tickets
    // entry#3  Mick    201             250          Mick buy 50 tickets
    // entry#4  Judy    251             300          Judy buy 50 tickets
    // entry#5  Zara    301             350          Zara again buy 50 tickets
    //

    /// @dev Mapping raffleEventId => RaffleEventStruct
    mapping(uint256 => RaffleEventStruct) public _raffleTracking;

    /// @dev Mapping vrfRequestId => raffleId
    mapping(uint256 => uint256) public _vrfRequestIdToRaffleId;

    /// @dev Raffle Event Counter
    uint256 public _raffleEventCounter = 1;

    /** VRF v2 variables */

    /// @dev Ref: https://docs.chain.link/docs/chainlink-vrf/
    /// @dev Your subscription ID. Based on the given explanation above, the one i created has the id: 654
    uint64 public _subscriptionId = 654;

    /// @dev The gas lane to use, which specifies the maximum gas price to bump to.
    /// @dev For a list of available gas lanes on each network,
    /// @dev see https://docs.chain.link/docs/vrf-contracts/#configurations
    /// @dev Mumbai keyHash for gas settings
    bytes32 public _keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    /// @dev Depends on the number of requested values that you want sent to the
    /// @dev fulfillRandomWords() function. Storing each word (32 bytes) costs about
    /// @dev 20,000 gas, so 100,000 is a safe default for this example contract. Test
    /// @dev and adjust this limit based on the network that you select, the size of
    /// @dev the request, and the processing of the callback request in the fulfillRandomWords()
    /// @dev function.
    uint32 public _callbackGasLimit = 100000;

    /// @dev How many confirmations the Chainlink node should wait before responding
    /// @dev The default is 3, but you can set this higher.
    uint16 public _requestConfirmations = 3;

    /// @notice Emitted when Raffle Event created
    /// @param raffleId - Identifier of Raffle newly created
    /// @param ticketPrice - Ticket price, $MILK in gwei
    /// @param startTimestamp - UNIX timestamp in seconds of starting time of Raffle
    /// @param endTimestamp - UNIX timestamp in seconds of ending time of Raffle
    /// @param maxTicketCount - Maximum count of tickets
    /// @param maxWinnerCount - Maximum count of winners
    /// @param ticketAddress - Address of RaffleTicket Contract
    event LogCreateRaffleEvent(
        uint256 raffleId,
        uint64 ticketPrice,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint32 maxTicketCount,
        uint16 maxWinnerCount,
        address ticketAddress
    );

    /// @notice Emitted when Raffle Event modified
    /// @param raffleId - Identifier of Raffle to be modified
    /// @param ticketPrice - Ticket price, $MILK in gwei
    /// @param startTimestamp - UNIX timestamp in seconds of starting time of Raffle
    /// @param endTimestamp - UNIX timestamp in seconds of ending time of Raffle
    /// @param maxTicketCount - Maximum count of tickets
    /// @param maxWinnerCount - Maximum count of winners
    /// @param ticketAddress - Address of RaffleTicket Contract
    event LogEditRaffleEvent(
        uint256 raffleId,
        uint64 ticketPrice,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint32 maxTicketCount,
        uint16 maxWinnerCount,
        address ticketAddress
    );

    /// @notice Emitted when Raffle Event removed
    /// @param raffleId - Identifier of Raffle
    event LogRemoveRaffleEvent(uint256 raffleId);

    /// @notice Emitted when Raffle finished and pick winners
    /// @param raffleId - Identifier of Raffle
    /// @param winners - winning ticketIDs of current Raffle in array
    event LogPickWinners(uint256 raffleId, uint32[] winners);

    /// @notice Emitted when user buy ticket of current Raffle
    /// @param buyer - Address of buyer
    /// @param raffleId - Identifier of Raffle
    /// @param startingTicketId - Starting id of bought tickets
    /// @param endingTicketId - Ending id of bought tickets
    event LogBuyTicket(
        address buyer,
        uint256 raffleId,
        uint256 startingTicketId,
        uint256 endingTicketId
    );

    /// @notice Emitted when user burns tickets from an old raffle
    /// @param owner - Address of owner
    /// @param raffleId - Identifier of Raffle
    /// @param ticketIds - Ticket ids to burn
    event LogBurnTickets(address owner, uint256 raffleId, uint256[] ticketIds);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Item Factory contract address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    /// @notice Emitted when set VRF Settings
    /// @param subscriptionId - Subscription Id of chainlink VRF
    /// @param keyHash - KeyHash for gas lane to use
    /// @param gasLimit - Callback gas limit - reasonable default - 100000
    /// @param requestConfirmations - MAX request confirmations - default is 3
    event LogSetVRFSettings(
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 gasLimit,
        uint16 requestConfirmations
    );

    /// @notice Emitted when issue VRF random number request
    /// @param raffleId - Raffle Id to be set random number
    /// @param requestId - VRF random number request id
    event LogRequestRandomNumber(uint256 raffleId, uint256 requestId);

    /// @notice Emitted when received random number
    /// @param requestId - VRF random number request id
    /// @param randomNumber - VRF generated random number
    event LogReceivedRandomNumber(uint256 requestId, uint256 randomNumber);

    constructor(
        address systemCheckerContractAddress,
        address treasuryContractAddress,
        address vrfCoordinatorAddress
    ) HSystemChecker(systemCheckerContractAddress) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        _vrfCoordinatorAddress = vrfCoordinatorAddress;
        _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);

        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(_treasuryContractAddress);
    }

    /// @notice Check if Raffle on current Id exists
    /// @param raffleId - Identifier of Raffle
    modifier raffleExists(uint256 raffleId) {
        require(_raffleTracking[raffleId].maxWinnerCount > 0, "RT 400 - Raffle doesn't exist");
        _;
    }

    /// @notice Check if Raffle has no ticket entries
    /// @param raffleId - Identifier of Raffle
    modifier raffleHasNoTickets(uint256 raffleId) {
        require(
            RaffleTicket(_raffleTracking[raffleId].ticketAddress).totalMinted() == 0,
            'RT 403 - Raffle has ticket record'
        );
        _;
    }

    /// @notice Check if Raffle timestamp is valid
    /// @param startTimestamp - UNIX timestamp of Raffle's starting
    /// @param endTimestamp - UNIX timestamp of Raffle's ending
    modifier checkRaffleTimestampValid(uint48 startTimestamp, uint48 endTimestamp) {
        require(startTimestamp < endTimestamp, 'RT 401 - Invalid timestamp');
        _;
    }

    /// @notice Check if Raffle's maxWinnerCount is valid
    /// @param maxWinnerCount - Raffle's maxWinnerCount should not be 0
    modifier checkRaffleMaxWinnerCount(uint16 maxWinnerCount) {
        require(maxWinnerCount > 0, 'RT 402 - maxWinnerCount cannot be 0');
        _;
    }

    /// @notice Create Raffle Event
    /// @param ticketPrice - Price of ticket $MILK in gwei
    /// @param startTimestamp - UNIX timestamp in seconds of starting time of Raffle
    /// @param endTimestamp - UNIX timestamp in seconds of ending time of Raffle
    /// @param maxTicketCount - Maximum count of tickets to be sold. if 0, then no limit
    /// @param maxWinnerCount - Maximum count of winners
    /// @param ticketAddress - Address of RaffleTicket Contract
    function createRaffleEvent(
        uint64 ticketPrice,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint32 maxTicketCount,
        uint16 maxWinnerCount,
        address ticketAddress
    )
        external
        checkRaffleTimestampValid(startTimestamp, endTimestamp)
        checkRaffleMaxWinnerCount(maxWinnerCount)
        onlyRole(ADMIN_ROLE)
    {
        uint256 raffleId = _raffleEventCounter;
        _raffleTracking[raffleId] = RaffleEventStruct(
            0, // random number 0 as default
            ticketPrice,
            startTimestamp,
            endTimestamp,
            maxTicketCount,
            maxWinnerCount,
            new uint32[](0), // winTicketIds
            ticketAddress
        );

        // emit LogCrateRaffleEvent
        emit LogCreateRaffleEvent(
            raffleId,
            ticketPrice,
            startTimestamp,
            endTimestamp,
            maxTicketCount,
            maxWinnerCount,
            ticketAddress
        );

        unchecked {
            raffleId++;
        }

        // inc raffle event counter
        _raffleEventCounter = raffleId;
    }

    /// @notice Create Raffle Event
    /// @param raffleId - Identifier of Raffle to edit
    /// @param ticketPrice - Price of ticket $MILK in gwei
    /// @param startTimestamp - UNIX timestamp in seconds of starting time of Raffle
    /// @param endTimestamp - UNIX timestamp in seconds of ending time of Raffle
    /// @param maxTicketCount - Maximum count of tickets to be issued
    /// @param maxWinnerCount - Maximum count of winners
    function editRaffleEvent(
        uint256 raffleId,
        uint64 ticketPrice,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint32 maxTicketCount,
        uint16 maxWinnerCount,
        address ticketAddress
    )
        external
        raffleExists(raffleId)
        checkRaffleTimestampValid(startTimestamp, endTimestamp)
        checkRaffleMaxWinnerCount(maxWinnerCount)
        onlyRole(ADMIN_ROLE)
    {
        // edit raffle event data
        _raffleTracking[raffleId] = RaffleEventStruct(
            0, // random number 0 as default
            ticketPrice,
            startTimestamp,
            endTimestamp,
            maxTicketCount,
            maxWinnerCount,
            new uint32[](0), // winTicketIds
            ticketAddress
        );

        // emit LogEditRaffleEvent
        emit LogEditRaffleEvent(
            raffleId,
            ticketPrice,
            startTimestamp,
            endTimestamp,
            maxTicketCount,
            maxWinnerCount,
            ticketAddress
        );
    }

    /// @notice Remove Raffle of current raffleId
    /// @param raffleId - Identifier of Raffle
    function removeRaffleEvent(uint256 raffleId)
        external
        raffleExists(raffleId)
        raffleHasNoTickets(raffleId)
        onlyRole(ADMIN_ROLE)
    {
        // delete raffle tracking record
        delete _raffleTracking[raffleId];

        // emit LogRemoveRaffleEvent
        emit LogRemoveRaffleEvent(raffleId);
    }

    /// @notice Create request random number to Chainlink VRF
    /// @param raffleId - Identifier of Raffle
    function requestRandomNumber(uint256 raffleId) external onlyRole(ADMIN_ROLE) {
        RaffleEventStruct memory raffle = getRaffleEvent(raffleId);

        // check if Raffle already finished
        require(raffle.endTimestamp < block.timestamp, 'RT 404 - Raffle not yet finished');
        // check if random number is 0
        require(raffle.randomNumber == 0, 'RT 405 - Random number already generated');

        // get VRF request Id
        uint256 requestId = _requestRandomWords();

        _vrfRequestIdToRaffleId[requestId] = raffleId;

        // emit LogRequestRandomNumber
        emit LogRequestRandomNumber(raffleId, requestId);
    }

    /// @notice Pick win ticket Ids
    /// @param raffleId - Identifier of Raffle
    function pickWinners(uint256 raffleId) external onlyRole(ADMIN_ROLE) {
        RaffleEventStruct memory raffle = getRaffleEvent(raffleId);
        uint256 blockTimestamp = block.timestamp;

        // check Raffle is finished
        require(raffle.endTimestamp < blockTimestamp, 'RT 404 - Raffle not yet finished');
        // check random number for current raffle generated
        require(raffle.randomNumber > 0, 'RT 406 - Random Number not generated');
        // check winners already selected
        require(raffle.winTicketIds.length == 0, 'RT 407 - Winners already selected');

        RaffleTicket tickets = RaffleTicket(raffle.ticketAddress);
        // index of last ticket
        uint32 totalMinted = uint32(tickets.totalMinted());

        // check any ticket bought
        require(totalMinted > 0, 'RT 408 - No Raffle tickets sold');

        // ticket Id in raffle.sol starts at 0
        // safe as totalMinted > 0 checked above. No risk of underflow
        uint32 lastTicketId = totalMinted - 1;

        // winners length = Min(totalTicketCount, maxWinnerCount)
        uint32 winnersLength = raffle.maxWinnerCount;
        if (winnersLength > totalMinted) {
            winnersLength = totalMinted;
        }

        // array to track win Ticket Ids
        uint32[] memory winTicketIds = new uint32[](winnersLength);

        // array to track swapped ticket Ids, 1:1 match with winTicketId
        // original ticket array [1,2,3,4,5]
        // randNumber   ticket array    winTicketId     replacedTicketId
        // 3            [1,2,[5],4,[3]] [3]             [5]
        // 2            [1,[4],5,[2],3] [3,2]           [5,4]
        // 3            [1,4,[5],2,3]   [3,2,5]         [5,4,5]
        // 2            [1,[4],5,2,3]   [3,2,5,4]       [5,4,5,4]
        // 1            [[1],4,5,2,3]   [3,2,5,4,1]     [5,4,5,4,1]
        uint32[] memory replacedTicketIds = new uint32[](winnersLength);

        // randNumber
        uint256 randHash = raffle.randomNumber;
        uint32 randNumber;

        // last real id, ticketIds are replacing continuously
        uint32 lastRealId;

        // Picking Ticket logic
        // 1. generate randNumber with range [0, lastTicketIdx]  - this will be picked ticket's index
        // 2. store ticketIds[randNumber] as win ticket
        // 3. swap ticketIds[randomNumber] with ticketIds[lastTicketIdx]
        // 4. dec lastTicketIdx to make sure picked tickets not attend in next loop
        // 5. loop from #1 to #4 for winnersLength

        // Updated Picking Ticket logic
        // Description: main logic is same as above, except not creating total ticket array,
        // instead, track only replaced tickets array
        // 1. generate randNumber with range [1, lastTicketId]
        // 2. add randNumber to winTicketIds initially
        // 3. add lastTicketId to replacedTicketIds initially
        // 4. find the lastTicketId in prev winTicketIds and replace lastTicketId with swapped id
        // 5. find the randomNumber in prev winTicketIds and replace with swapped randNumber
        // 6. loop from #1 to #5 fro winnersLength

        // example data:
        // original array [1,2,3,4,5,6,7,8,9,10]
        // randNumber:  swapped ticketIds       winTicketIds        replacedTicketIds
        // rand#3       [1,2,10,4,5,6,7,8,9,3]  [3]                 [10]    // pos#3 swapped with ticket#10
        // rand#8       [1,2,10,4,5,6,7,9,8,3]  [3,8]               [10,9]  // pos#8 swapped with ticket#9
        // rand#3       [1,2,9,4,5,6,7,10,8,3]  [3,8,10]            [9,10,3] // pos#3 swapped with ticket#9
        // rand#6       [1,2,9,4,5,7,6,10,8,3]  [3,8,10,6]          [9,10,3,7] // pos#6 swapped with ticket#7
        // rand#3       [1,2,7,4,5,9,6,10,8,3]  [3,8,10,6,9]        [7,10,3,9,8] // pos#3 swapped with ticket7

        for (uint16 i; i < winnersLength; ) {
            // generate rand number from vrf random as seed
            // random range [0, lastTicketId]
            // ticketId starts from 0
            if (i > 0) {
                randHash >>= 2;

                if (randHash == 0) {
                    randHash = uint256(keccak256(abi.encodePacked(raffle.randomNumber, i)));
                }
            }

            randNumber = uint32(randHash % (lastTicketId + 1));

            // initially assign randNumber to winTicketId[i]
            winTicketIds[i] = randNumber;

            // initially assign the replacedTicketIds[i] with lastTicketId to track swapped ticket
            // if winTicketIds contain lastTicketId, this means lastTicketId already swapped,
            // then, retrieve and assign the swapped ticket Id to replacedTicketIds[i]
            lastRealId = lastTicketId;
            for (uint16 k; k < i; ) {
                if (lastTicketId == winTicketIds[k]) {
                    lastRealId = replacedTicketIds[k];
                    break;
                }
                unchecked {
                    k++;
                }
            }
            replacedTicketIds[i] = lastRealId;

            // check if winTicketIds contain this randNumber, this means tickets[randNumber] already swapped
            // then retrieved the swapped ticketId relevant to randNumber, and assign to winTicketIds
            // tickets[randNumber] point to tickets[lastTicketId]
            // this case no need to check replacedTicketIds[i], it do not attend in further process
            for (uint16 j; j < i; ) {
                if (randNumber == winTicketIds[j]) {
                    winTicketIds[i] = replacedTicketIds[j];
                    replacedTicketIds[j] = lastRealId;
                    break;
                }
                unchecked {
                    j++;
                }
            }

            unchecked {
                // remove ticketIds[lastTicketIdx] from next loop
                lastTicketId--;
                i++;
            }
        }

        // store picked winTicketIds
        _raffleTracking[raffleId].winTicketIds = winTicketIds;

        emit LogPickWinners(raffleId, winTicketIds);
    }

    /// @notice Buy Ticket for relevant Raffle
    /// @param buyer - Address of buyer
    /// @param raffleId - Identifier of Raffle
    /// @param ticketAmount - ticket amount to buy
    function buyTicket(
        address buyer,
        uint256 raffleId,
        uint256 ticketAmount
    ) external isUser(buyer) onlyRole(GAME_ROLE) {
        RaffleEventStruct memory raffle = getRaffleEvent(raffleId);
        RaffleTicket tickets = RaffleTicket(raffle.ticketAddress);
        uint256 totalMinted = tickets.totalMinted();

        require(ticketAmount < 1001, 'RT 410 - Max mint is 1000');

        // check raffle is in running
        require(
            block.timestamp > raffle.startTimestamp && block.timestamp < raffle.endTimestamp,
            'RT 409 - Raffle is not running'
        );

        // check ticket is available
        // if Raffle maxTicketCount == 0 then no limit in ticket amount
        require(
            raffle.maxTicketCount == 0 || totalMinted + ticketAmount <= raffle.maxTicketCount,
            'RT 410 - Insufficient tickets left'
        );

        // burn $MILK for ticket
        // $MILK is in gwei, should multiply total amount with 1 gwei
        _treasury.burn(buyer, raffle.ticketPrice * ticketAmount * 1 gwei);

        // mint ticketToken
        tickets.mint(buyer, ticketAmount);

        emit LogBuyTicket(buyer, raffleId, totalMinted, (totalMinted + ticketAmount) - 1);
    }

    /// @notice Burn tickets from an old raffle
    /// @param owner - Address of owner
    /// @param raffleId - Identifier of Raffle
    /// @param ticketIds - Ticket ids to burn
    function burnTickets(
        address owner,
        uint256 raffleId,
        uint256[] calldata ticketIds
    ) public isUser(owner) onlyRole(GAME_ROLE) {
        // check Raffle is finished
        require(ticketIds.length < 101, 'RT 406 - Max burn is 100 per transaction');

        RaffleEventStruct memory raffle = getRaffleEvent(raffleId);
        RaffleTicket tickets = RaffleTicket(raffle.ticketAddress);

        // check Raffle is finished
        require(raffle.endTimestamp < block.timestamp, 'RT 404 - Raffle not yet finished');

        // check ownership of tokens
        for (uint8 i; i < ticketIds.length; ) {
            uint256 ticketId = ticketIds[i];
            require(tickets.ownerOf(ticketId) == owner, 'RT 405 - Invalid owner');
            unchecked {
                i++;
            }
        }

        tickets.batchBurn(ticketIds);

        emit LogBurnTickets(owner, raffleId, ticketIds);
    }

    /** SETTERS */

    /// @notice Push new address for the Treasury Contract
    /// @param treasuryContractAddress - Address of the Item Factory
    function setTreasuryContractAddress(address treasuryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _treasuryContractAddress = treasuryContractAddress;
        _treasury = ITreasury(_treasuryContractAddress);
        emit LogSetTreasuryContractAddress(treasuryContractAddress);
    }

    /// @notice Set VRF Settings
    /// @dev Ref: https://docs.chain.link/docs/get-a-random-number/
    /// @param subscriptionId - Subscription Id of Chainlink VRF
    /// @param keyHash - KeyHash for gas lane to use
    /// @param gasLimit - Callback gas limit, reasonable default is 100000
    /// @param requestConfirmations - MAX request confirmations, default is 3
    function setVRFSettings(
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 gasLimit,
        uint16 requestConfirmations
    ) external onlyRole(ADMIN_ROLE) {
        require(subscriptionId > 0, 'RT 411 - VRF subscription Id cannot be 0');
        require(gasLimit > 0, 'RT 413 - VRF gasLimit cannot be 0');
        require(requestConfirmations > 0, 'RT 414 - VRF requestConfirmations cannot be 0');

        _subscriptionId = subscriptionId;
        _keyHash = keyHash;
        _callbackGasLimit = gasLimit;
        _requestConfirmations = requestConfirmations;

        emit LogSetVRFSettings(subscriptionId, keyHash, gasLimit, requestConfirmations);
    }

    /** GETTERS */
    /// @notice Get Raffle winners of current Raffle Id
    /// @param raffleId - Identifier of Raffle
    /// @return winTicketIds - Array of winning ticketIds
    function getRaffleWinners(uint256 raffleId)
        external
        view
        returns (uint32[] memory winTicketIds)
    {
        RaffleEventStruct memory raffle = getRaffleEvent(raffleId);

        // check winners already picked
        require(raffle.winTicketIds.length > 0, 'RT 415 - No winners selected');

        winTicketIds = raffle.winTicketIds;
    }

    /// @notice Get owner of ticket id
    /// @param raffleId - Identifier of Raffle
    /// @param ticketId - Ticket token Id
    /// @return buyerAddress - Address of token owner
    function getTicketOwner(uint256 raffleId, uint256 ticketId)
        external
        view
        raffleExists(raffleId)
        returns (address)
    {
        RaffleEventStruct memory raffle = getRaffleEvent(raffleId);
        RaffleTicket tickets = RaffleTicket(raffle.ticketAddress);
        return tickets.ownerOf(ticketId);
    }

    /// @notice Get Raffle Ticket Ids owned by User
    /// @param owner - Address of owner
    /// @param raffleId - Identifier of Raffle
    /// @return ticketIds - Ticket tokenId array of current Raffle owned by user
    function getRaffleTicketsOwnedByUser(address owner, uint256 raffleId)
        external
        view
        raffleExists(raffleId)
        returns (uint256[] memory ticketIds)
    {
        RaffleEventStruct memory raffle = _raffleTracking[raffleId];

        RaffleTicket tickets = RaffleTicket(raffle.ticketAddress);
        ticketIds = tickets.tokensOfOwner(owner);
    }

    /// @notice Get Raffle info
    /// @param raffleId - Identifier of Raffle
    /// @return raffle - Raffle info in RaffleEventStruct of current raffleId
    function getRaffleEvent(uint256 raffleId)
        public
        view
        raffleExists(raffleId)
        returns (RaffleEventStruct memory raffle)
    {
        raffle = _raffleTracking[raffleId];
    }

    /** Internal Functions */

    /// @notice Create request for VRF random number
    /// @dev https://docs.chain.link/docs/get-a-random-number/
    /// @return requestId - request id which generated from Chainlink VRF
    function _requestRandomWords() internal onlyRole(ADMIN_ROLE) returns (uint256) {
        // request random words
        return
            _vrfCoordinator.requestRandomWords(
                _keyHash,
                _subscriptionId,
                _requestConfirmations,
                _callbackGasLimit,
                1 // default to 1 as Raffle only need 1 random per 1 event
            );
    }

    /// @notice Callback function of VRF fulfill Random Words
    /// @dev https://docs.chain.link/docs/get-a-random-number/
    /// @dev every raffle needs only one random number as seed
    /// @param requestId - VRF request Id
    /// @param randomWords - VRF generated random numbers
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        // retrieve raffleId which requested this random number
        uint256 raffleId = _vrfRequestIdToRaffleId[requestId];

        // update random number of current Raffle with VRF generation
        _raffleTracking[raffleId].randomNumber = randomWords[0];

        // emit event
        emit LogReceivedRandomNumber(requestId, randomWords[0]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISystemChecker.sol';
import './RolesAndKeys.sol';

contract HSystemChecker is RolesAndKeys {
    ISystemChecker _systemChecker;
    address public _systemCheckerContractAddress;

    constructor(address systemCheckerContractAddress) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }

    /// @notice Check if an address is a registered user or not
    /// @dev Triggers a require in systemChecker
    modifier isUser(address user) {
        _systemChecker.isUser(user);
        _;
    }

    /// @notice Check that the msg.sender has the desired role
    /// @dev Triggers a require in systemChecker
    modifier onlyRole(bytes32 role) {
        require(_systemChecker.hasRole(role, _msgSender()), 'SC: Invalid transaction source');
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /**
     * @dev mostly lifted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    /**
     * @inheritdoc IMulticall
     * @dev does a basic multicall to any function on this contract
     */
    function multicall(bytes[] calldata data, bool revertOnFail)
        external
        payable
        override
        returns (bytes[] memory returning)
    {
        returning = new bytes[](data.length);
        bool success;
        bytes memory result;
        for (uint256 i = 0; i < data.length; i++) {
            (success, result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
            returning[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function mint(address owner, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
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

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../system/HSystemChecker.sol';
import '../../../common/Multicall.sol';

contract RaffleTicket is HSystemChecker, Multicall, ERC721A, ERC721AQueryable {
    string public _baseTokenURI;

    constructor(
        address systemCheckerContractAddress,
        string memory description,
        string memory symbol,
        string memory uri
    ) HSystemChecker(systemCheckerContractAddress) ERC721A(description, symbol) {
        _baseTokenURI = uri;
    }

    /// @notice Mint Raffle Ticket token
    /// @param buyer - Address of buyer
    /// @param tokenAmount - Amount of token to buy
    function mint(address buyer, uint256 tokenAmount)
        external
        isUser(buyer)
        onlyRole(CONTRACT_ROLE)
    {
        _safeMint(buyer, tokenAmount);
    }

    /// @notice Burn Raffle Ticket token
    /// @param tokenId - tokenId to be burn
    function burn(uint256 tokenId) external onlyRole(CONTRACT_ROLE) {
        _burn(tokenId, false);
    }

    /// @param tokenIds - tokenIds to be burn
    function batchBurn(uint256[] calldata tokenIds) external onlyRole(CONTRACT_ROLE) {
        for (uint256 i; i < tokenIds.length; ) {
            _burn(tokenIds[i], false);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set baseURI
    /// @param baseURI URI of the pet image server
    function setBaseURI(string memory baseURI) external onlyRole(ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    /** Getters */

    /// @notice Get uri of tokens
    /// @return string Uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Get total minted token amount
    /// @return totalMinted - Amount of token minted
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemChecker {
    function createNewRole(bytes32 role) external;

    function hasRole(bytes32 role, address account) external returns (bool);

    function hasPermission(bytes32 role, address account) external;

    function isUser(address user) external;

    function getSafeAddress(bytes32 key) external returns (address);

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract RolesAndKeys is Context {
    // ROLES
    bytes32 constant MASTER_ROLE = keccak256('MASTER_ROLE');
    bytes32 constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 constant GAME_ROLE = keccak256('GAME_ROLE');
    bytes32 constant CONTRACT_ROLE = keccak256('CONTRACT_ROLE');
    bytes32 constant TREASURY_ROLE = keccak256('TREASURY_ROLE');

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256('MARKETPLACE');
    bytes32 constant SYSTEM_KEY_BYTES = keccak256('SYSTEM');
    bytes32 constant QUEST_KEY_BYTES = keccak256('QUEST');
    bytes32 constant BATTLE_KEY_BYTES = keccak256('BATTLE');
    bytes32 constant HOUSE_KEY_BYTES = keccak256('HOUSE');
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256('QUEST_GUILD');

    // COMMON
    bytes32 public constant PET_BYTES =
        0x5065740000000000000000000000000000000000000000000000000000000000;
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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail)
        external
        payable
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *   - `extraData` = `0`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *   - `extraData` = `<Extra data when token was burned>`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     *   - `extraData` = `<Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}