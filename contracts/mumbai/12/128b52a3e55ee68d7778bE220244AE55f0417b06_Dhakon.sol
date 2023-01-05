/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol

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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol

pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol

pragma solidity ^0.8.0;


/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/AutomationBase.sol

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

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol

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

// File: @chainlink/contracts/src/v0.8/AutomationCompatible.sol

pragma solidity ^0.8.0;


abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: contracts/Dhakon.sol

// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.11;


contract Dhakon is VRFV2WrapperConsumerBase, AutomationCompatibleInterface {
    address owner;

    uint immutable public ticketPrice;
    uint8 public roundDays;
    uint16 immutable public commissionPct;

    address[] public players;
    mapping(address => bool) checkPlayers;

    struct Ticket {
        uint32 num;
        uint time;
        address player;
    }

    Ticket[] public tickets;
    mapping(uint32 => address) public playerTickets;   // ticket number => player's address

    struct Winner {
        uint16 round;
        uint32 ticket;
        address player;
        uint randRequestId;         // Randomness requestId
        uint wonAt;
        uint paidAt;
    }

    Winner[] public winners;
    
    bool public isPickingWinner;
    bool public isPayingWinner;
    bool public isPaused;  // not accepting players when paused
    
    uint16 public currentRound = 0;
    uint public roundEndsAt;

    uint32 public callbackGasLimit;
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    uint public lastRequestId;

    event NewPlayerEntered(uint32 indexed ticket, address indexed player);
    event RoundStarted(uint16 indexed round, uint8 nDays, uint endsAt);
    event WinnerChosen(uint32 indexed ticket, address player);
    event WinnerPaid(uint32 indexed ticket, address player, uint paidAt);

    constructor(
        address _linkAddress, 
        address _wrapperAddress,
        uint32 _callbackGasLimit, 
        uint _ticketPrice,
        uint8 _roundDays,
        uint16 _commissionPct
    )
    VRFV2WrapperConsumerBase(
        _linkAddress,              // LINK token address 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        _wrapperAddress            // Mumbai VRF wrapper 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693
    ) {
        callbackGasLimit = _callbackGasLimit;

        owner = msg.sender;
        ticketPrice = _ticketPrice;
        roundDays = _roundDays;
        commissionPct = _commissionPct;
    }

    function checkUpkeep(bytes calldata checkData) external view override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (keccak256(checkData) == keccak256(hex'01')) {
            upkeepNeeded = tickets.length > 0 && winners.length <= currentRound && roundEndsAt <= block.timestamp;
            performData = checkData;
            
        } else if (keccak256(checkData) == keccak256(hex'02')) {
            upkeepNeeded = winners.length > currentRound;
            performData = checkData;
        }
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        if (keccak256(performData) == keccak256(hex'01')) {
            assert(winners.length <= currentRound && roundEndsAt <= block.timestamp);
            require(!isPickingWinner);
            pickWinner();

        } else if (keccak256(performData) == keccak256(hex'02')) {
            assert(winners.length > currentRound);
            payWinner();
        }
    }

    function getRandomNumber() internal virtual {
        uint requestId = requestRandomness(callbackGasLimit, REQUEST_CONFIRMATIONS, 1);    
        lastRequestId = requestId;
    }

    function fulfillRandomWords(uint requestId, uint256[] memory randomness) internal override {
        require(requestId == lastRequestId, "Invalid request");
        require(randomness[0] != 0, "Problem in getting randomness");

        uint index = randomness[0] % tickets.length;
        uint32 ticketNum = tickets[index].num;
        Winner memory winner = Winner({
            round: currentRound + 1,
            ticket: ticketNum, 
            player: playerTickets[ticketNum],
            randRequestId: requestId,
            wonAt: block.timestamp,
            paidAt: 0
        });

        winners.push(winner);
        emit WinnerChosen({
            ticket: winner.ticket, 
            player: winner.player
        });

        isPickingWinner = false;
    }

    function getWinners(uint32 limit) public view returns(Winner[] memory) {
        require(limit > 0, "Limit should be greater than 0");

        Winner[] memory lastWinners = new Winner[](limit);
        if (winners.length == 0) {
            return lastWinners;
        }

        uint8 idx1 = 1;
        uint idx2 = winners.length;

        while(idx1 <= limit && idx2 > 0) {
            lastWinners[idx1-1] = winners[idx2-1];
            idx1++; idx2--;
        }

        return lastWinners;
    }

    function getNumOfWinners() public view returns(uint) {
        return winners.length;
    }

    function getWinnerByRound(uint16 _round) public view returns (Winner memory) {
        if (_round == 0) {
            _round = currentRound + 1;
        }
        require(_round <= winners.length, "There is no such round");
        return winners[_round-1];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers(uint8 limit) public view returns(address[] memory) {
        require(limit > 0, "Limit should be greater than 0");

        address[] memory lastPlayers = new address[](limit);
        if (players.length == 0) {
            return lastPlayers;
        }
        
        uint8 idx1 = 1;
        uint idx2 = players.length;

        while(idx1 <= limit && idx2 > 0) {
            lastPlayers[idx1-1] = players[idx2-1];
            idx1++; idx2--;
        }

        return lastPlayers;
    }

    function getNumOfPlayers() public view returns (uint) {
        return players.length;
    }

    function getTickets(uint8 limit) public view returns(Ticket[] memory) {
        require(limit > 0, "Limit should be greater than 0");

        Ticket[] memory lastTickets = new Ticket[](limit);
        if (tickets.length == 0) {
            return lastTickets;
        }
        
        uint8 idx1 = 1;
        uint idx2 = tickets.length;

        while(idx1 <= limit && idx2 > 0) {
            lastTickets[idx1-1] = tickets[idx2-1];
            idx1++; idx2--;
        }

        return lastTickets;
    }

    function getNumOfTickets() public view returns(uint) {
        return tickets.length;
    }

    function addPlayer(address _address) internal {
        if (checkPlayers[_address] != true) {  // only add if player's address not yet exist
            checkPlayers[_address] = true;
            players.push(_address);
        }
    }

    function newTicket(address player) internal view returns (Ticket memory) {
        uint32 ticketNum = uint32(uint256(keccak256(abi.encodePacked(owner, block.timestamp))));
        return Ticket({
            num: ticketNum,
            time: block.timestamp,
            player: player
        });
    }

    function enter() public payable {
        require(!isPaused, "The round is not in playing mode");
        require(msg.value >= ticketPrice, "Value is below Ticket Price");

        // save new ticket entering the round
        address player = msg.sender;
        Ticket memory ticket = newTicket(player);
        tickets.push(ticket);
        playerTickets[ticket.num] = player;

        addPlayer(player);
        emit NewPlayerEntered({
            ticket: ticket.num, 
            player: ticket.player
        });

        // start the round when first ticket is added
        if (tickets.length == 1) {
            roundEndsAt = block.timestamp + (roundDays * 1 days);
            emit RoundStarted({
                round: currentRound + 1,
                nDays: roundDays,
                endsAt: roundEndsAt
            });
        }
    }

    function pickWinner() public {
        require(!isPickingWinner);
        require(roundEndsAt <= block.timestamp, "The round has not ended yet");
        require(tickets.length > 0, "There is no tickets yet");        
        require(winners.length <= currentRound, "The winner has been determined");

        isPickingWinner = true;
        isPaused = true;
        
        getRandomNumber();
    }

    function payWinner() public {
        require(!isPayingWinner);
        require(winners.length > currentRound, "The winner has not been determined");  

        isPayingWinner = true;
        uint balance = address(this).balance;
        require(balance > 0, "The pot is empty");

        uint32 ticketNum = winners[currentRound].ticket;
        address payable player = payable(playerTickets[ticketNum]);
        address payable holder = payable(owner);
        uint paidAt = block.timestamp;
        winners[currentRound].paidAt = paidAt;
        currentRound++;

        uint commissionAmt = commissionPct * balance / 10000;
        uint playerPrize = balance - commissionAmt;

        player.transfer(playerPrize);
        holder.transfer(commissionAmt);

        isPayingWinner = false;
        emit WinnerPaid({
            ticket: ticketNum, 
            player: player, 
            paidAt: paidAt
        });
        
        // reset the state of the contract for new round
        resetRound();
    }

    function resetRound() internal {        
        for(uint i=0; i < players.length; i++) {
            delete checkPlayers[players[i]]; 
        }
        delete players;

        for(uint i=0; i < tickets.length; i++) {
            delete playerTickets[tickets[i].num];
        }
        delete tickets;

        isPaused = false;
    }

    function withdrawLINKToken() external onlyOwner {
        uint balance = LINK.balanceOf(address(this));
        require(balance > 0, "LINK Balance is 0");
        
        LINK.transfer(owner, balance);
    }

    function setRoundDays(uint8 _roundDays) external onlyOwner {
        roundDays = _roundDays;
    }

    function setRoundEndsAt(uint _timestamp) external onlyOwner {
        roundEndsAt = _timestamp;
    }

    function setIsPickingWinner(bool _val) external onlyOwner {
        isPickingWinner = _val;
    }

    function setIsPayingWinner(bool _val) external onlyOwner {
        isPayingWinner = _val;
    }

    function setIsPaused(bool _val) external onlyOwner {
        isPaused = _val;
    }

    function setCallbackGasLimit(uint32 _val) external onlyOwner {
        callbackGasLimit = _val;
    }

    function isOwner(address _address) public view returns(bool) {
        return (_address == owner);
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}