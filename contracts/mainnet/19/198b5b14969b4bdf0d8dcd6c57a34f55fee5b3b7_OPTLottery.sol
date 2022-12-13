/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface VRFCoordinatorV2Interface {
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  function createSubscription() external returns (uint64 subId);

  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  function addConsumer(uint64 subId, address consumer) external;

  function removeConsumer(uint64 subId, address consumer) external;

  function cancelSubscription(uint64 subId, address to) external;

  function pendingRequestExists(uint64 subId) external view returns (bool);
}


abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

contract OPTLottery is Ownable, VRFConsumerBaseV2 {
  using SafeMath for uint256;

  bytes32 public immutable keyHash;
  uint64 public immutable s_subscriptionId;

  VRFCoordinatorV2Interface public immutable COORDINATOR;

  constructor(uint64 subId) VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067) {
    COORDINATOR = VRFCoordinatorV2Interface(0xAE975071Be8F8eE67addBC1A82488F1C24858067);
    keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
    s_subscriptionId = subId;
  } 

  struct requestStatus {
    uint256 jackpotID;
    bool exists;
    bool fulfilled;
  }

  uint32 callbackGasLimit = 1000000; //prev 100000
  uint16 requestConfirmations = 3;
  uint32 numWords = 1;

  mapping(uint256 => requestStatus) private requestMapping;

  function rollJackpot(uint256 jackpotID) external onlyOwner {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    require(inputJackpot.started == true, "Jackpot didnt start");
    require(inputJackpot.endingTime <= block.timestamp, "Jackpot timer didnt end");
    require(inputJackpot.paidOut == false, "Jackpot already paid out");
    require(inputJackpot.totalTickets >= 2, "Too little tickets");

    uint32 winners = JackpotMapping[jackpotID].winners;
    numWords = winners;

    uint256 requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    requestMapping[requestId].jackpotID = jackpotID;
    requestMapping[requestId].exists = true;
    requestMapping[requestId].fulfilled = false;

    JackpotMapping[jackpotID].ended = true;

  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    require(requestMapping[requestId].exists == true, "Request not found.");
    require(requestMapping[requestId].fulfilled == false, "Request already fulfilled.");

    uint256 jackpotID = requestMapping[requestId].jackpotID;

    uint256 ticketAmount = JackpotMapping[jackpotID].totalTickets;

    uint256 winners = JackpotMapping[jackpotID].winners;

    uint256 potSize = calculatePotAmount(jackpotID);

    uint256 contractFee = (potSize * forContract).div(percentRate);

    uint256 devFee = (potSize * forDev).div(percentRate);

    uint256 burnFee = (potSize * forBurn).div(percentRate);

    uint256 totalFee = (contractFee + devFee + burnFee);

    IBEP20(OPT3).transfer(OPTFundContract, contractFee);
    IBEP20(OPT3).transfer(devWallet, devFee);
    IBEP20(OPT3).transfer(DEAD, burnFee);

    uint256 potAfterFees = potSize.sub(totalFee);

    uint256 payoutPerWinner = potAfterFees.div(winners);

    require(payoutPerWinner * winners <= calculatePotAmount(jackpotID), "Payout per winner bigger than pot amount");
    
    for(uint i=0; i < winners; i++) {
      uint256 ticket = (randomWords[i] % ticketAmount) + 1;
      address winner = ticketToAddr[jackpotID][ticket];
      jackpotWinners[jackpotID].push(winner);
      IBEP20(OPT3).transfer(winner, payoutPerWinner);
    }

    requestMapping[requestId].fulfilled = true;

    JackpotMapping[jackpotID].paidOut = true;

    emit JackpotRolled(jackpotID, jackpotWinners[jackpotID]);
  }

  ///////////////////////////

  struct JackpotStruct {
    uint32 winners;
    uint256 startingTime;
    uint256 endingTime;
    bool exists;
    bool started;
    bool ended;
    bool paidOut;
    uint256 currentTicket;
    uint256 totalTickets;
    address[] participants;
  }

  uint256 oneTicket = 100 * 10**18;

  uint256 currentJackpotID = 0;

  uint256 forContract = 1000;
  uint256 forDev = 200;
  uint256 forBurn = 200;
  uint256 percentRate = 10000;

  address OPT3 = 0xCf630283E8Ff2e30C29093bC8aa58CADD8613039;
  address constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address constant ZERO = 0x0000000000000000000000000000000000000000;
  address OPTFundContract = 0xED187d5a8c6F5Ec720CbEeEcF76efe3A0916BB97;

  mapping(uint256 => JackpotStruct) private JackpotMapping; // Lottery ID => Lottery Struct

  mapping(address => mapping(uint256 => uint256[])) private ownedTickets; // Address => Lottery ID => Array of Tickets

  mapping(uint256 => mapping(uint256 => address)) private ticketToAddr; // Lottery ID => Ticket Number => Address

  mapping(address => mapping(uint256 => uint256)) private howMuchInvested; // Address => Lottery ID => total invested amount

  mapping(uint256 => address[]) public jackpotWinners; // Lottery ID => List of winners

  address public devWallet = 0xD7Ced3bD37D3Db19eBe50dfCA6e3ae001D0561d0;

  function changeDevWallet(address _new) external onlyOwner {
    require(_new != address(0), "Input address is address zero.");
    devWallet = _new;

    emit devWalletChanged(_new);
  }

  function changeContractFee(uint256 _new) external onlyOwner {
    require(_new <= 5000, "Contract fee too big.");
    forContract = _new;
  }

  function changeDevFee(uint256 _new) external onlyOwner {
    require(_new <= 2000, "Dev fee too big.");
    forDev = _new;
  }

  function changeBurnFee(uint256 _new) external onlyOwner {
    require(_new <= 2000, "Burn fee too big.");
    forBurn = _new;
  }

  function changeNumWords(uint32 _new) external onlyOwner {
    require(_new >= 1 && _new <= 50, "Wrong numwords input");
    numWords = _new;
  }

  function changeTicketPrice(uint256 _new) external onlyOwner { // INPUT IN RAW NUMBER
    oneTicket = (_new * 10**18);
  }

  
  function searchParticipantsFor(address _address, uint256 jackpotID) internal view returns (bool) {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];

    address[] memory addresses = inputJackpot.participants;

    for(uint i = 0; i < addresses.length; i++) {
      if(addresses[i] == _address) {
        return true;
      }
    }

      return false;
    }

  function createNewJackpot(uint32 winners) external onlyOwner {
    require(winners >= 1 && winners <= 50, "Wrong winners input.");

    uint256 id = currentJackpotID + 1;
    currentJackpotID++;

    JackpotMapping[id].winners = winners;
    JackpotMapping[id].startingTime = 0;
    JackpotMapping[id].endingTime = 0;
    JackpotMapping[id].exists = true;
    JackpotMapping[id].started = false;
    JackpotMapping[id].ended = false;
    JackpotMapping[id].paidOut = false;
    JackpotMapping[id].currentTicket = 0;
    JackpotMapping[id].totalTickets = 0;

    numWords = winners;

    emit JackpotCreated(id, winners);
  }

  function startJackpot(uint256 jackpotID, uint256 duration) external onlyOwner {
    require(duration >= 86400 && duration <= 2630000, "Wrong duration input."); // MIN 1 DAY, MAX 1 MONTH
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    require(inputJackpot.exists == true, "Jackpot doesnt exist");
    require(inputJackpot.started == false, "Jackpot already started");
    require(inputJackpot.ended == false, "Jackpot already ended");
    require(inputJackpot.paidOut == false, "Jackpot already paid out");

    JackpotMapping[jackpotID].startingTime = block.timestamp;
    JackpotMapping[jackpotID].endingTime = block.timestamp + duration;
    JackpotMapping[jackpotID].started = true;

    emit JackpotStarted(jackpotID, duration);
  }

  function manuallyCloseJackpot(uint256 jackpotID) external onlyOwner {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    require(inputJackpot.exists == true, "Jackpot doesnt exist");
    require(inputJackpot.started == true, "Jackpot didnt start");
    require(inputJackpot.ended == false, "Jackpot already ended");
    require(inputJackpot.paidOut == false, "Jackpot already paid out");

    JackpotMapping[jackpotID].ended = true;
  }

  function manuallyOpenJackpot(uint256 jackpotID) external onlyOwner {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    require(inputJackpot.exists == true, "Jackpot doesnt exist");
    require(inputJackpot.started == true, "Jackpot didnt start");
    require(inputJackpot.ended == true, "Jackpot already ended");
    require(inputJackpot.paidOut == false, "Jackpot already paid out");

    JackpotMapping[jackpotID].ended = false;
  }

  function manuallyChangeJackpotEndTime(uint256 jackpotID, uint256 newTimestamp) external onlyOwner {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    require(inputJackpot.exists == true, "Jackpot doesnt exist");
    require(inputJackpot.started == true, "Jackpot didnt start");
    require(inputJackpot.paidOut == false, "Jackpot already paid out");

    JackpotMapping[jackpotID].endingTime = newTimestamp;
  }

  function cancelJackpot(uint256 jackpotID) external onlyOwner {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    require(inputJackpot.exists == true, "Jackpot doesnt exist");
    require(inputJackpot.started == true, "Jackpot didnt start");
    require(inputJackpot.paidOut == false, "Jackpot already paid out");

    JackpotMapping[jackpotID].ended = true;
    JackpotMapping[jackpotID].paidOut = true;

    address[] memory addresses = inputJackpot.participants;

    for(uint i=0; i < addresses.length; i++) {
      uint256 amountToRefund = howMuchInvested[addresses[i]][jackpotID];
      howMuchInvested[addresses[i]][jackpotID] = 0;
      IBEP20(OPT3).transfer(addresses[i], amountToRefund);
    }

  }

  function changeCallbackLimit(uint32 _new) external onlyOwner {
    require(_new >= 100000, "Callback too low");
    callbackGasLimit = _new;
  }

  function changeOPT3Address(address _new) external onlyOwner {
    require(_new != address(0), "Address zero.");
    OPT3 = _new;
  }

  function changeOPTFundAddress(address _new) external onlyOwner {
    require(_new != address(0), "Address zero.");
    OPTFundContract = _new;
  }

  //////////// PUBLIC FUNCTIONS /////////////

  function enterJackpot(uint256 jackpotID, uint256 ticketAmount) external {
    require(ticketAmount >= 1 && ticketAmount <= 100, "You need to get atleast 1 ticket and less than 100 tickets.");

    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];

    require(inputJackpot.exists == true, "Jackpot doesnt exist");
    require(inputJackpot.started == true, "Jackpot didnt start");
    require(inputJackpot.ended == false, "Jackpot already ended");
    require(inputJackpot.endingTime >= block.timestamp, "Jackpot is over");

    uint256 amountNeededToBuy = ticketAmount * oneTicket;

    IBEP20(OPT3).transferFrom(msg.sender, address(this), amountNeededToBuy);

    if(!searchParticipantsFor(msg.sender, jackpotID)) {
      JackpotMapping[jackpotID].participants.push(msg.sender);
    }

    for(uint i=0; i < ticketAmount; i++) {
      uint256 currentTicket = JackpotMapping[jackpotID].currentTicket;
      uint256 nextTicket = currentTicket + 1;
      ownedTickets[msg.sender][jackpotID].push(nextTicket);
      ticketToAddr[jackpotID][nextTicket] = msg.sender;
      howMuchInvested[msg.sender][jackpotID] = howMuchInvested[msg.sender][jackpotID] + oneTicket;
      JackpotMapping[jackpotID].currentTicket = JackpotMapping[jackpotID].currentTicket + 1;
      JackpotMapping[jackpotID].totalTickets = JackpotMapping[jackpotID].totalTickets + 1;
    }

    emit enteredJackpot(jackpotID, msg.sender, ticketAmount);
  }

  //////// EVENTS ///////////

  event devWalletChanged(address addr);

  event JackpotCreated(uint256 id, uint256 winners);

  event JackpotStarted(uint256 id, uint256 duration);

  event enteredJackpot(uint256 id, address who, uint256 tickets);

  event JackpotRolled(uint256 id, address[] winners);

  ////////////////////////// VIEW FUNCTIONS //////

  function calculatePotAmount(uint256 jackpotID) public view returns (uint256) {
    JackpotStruct memory inputJackpot = JackpotMapping[jackpotID];
    uint256 totalTickets = inputJackpot.totalTickets;
    uint256 finalAmount = totalTickets * oneTicket;
    return finalAmount;
  }

  function calculatePotAfterTaxes(uint256 jackpotID) public view returns (uint256) {

    uint256 potSize = calculatePotAmount(jackpotID);

    uint256 contractFee = (potSize * forContract).div(percentRate);

    uint256 devFee = (potSize * forDev).div(percentRate);

    uint256 burnFee = (potSize * forBurn).div(percentRate);

    uint256 totalFee = (contractFee + devFee + burnFee);

    uint256 potAfterTax = potSize.sub(totalFee);

    return potAfterTax;
  }

  function checkWinners(uint256 jackpotID) public view returns (address[] memory) {
    return jackpotWinners[jackpotID];
  }

  function checkCurrentJackpotID() public view returns (uint256) {
    return currentJackpotID;
  }

  function checkTicketPrice() public view returns (uint256) {
    return oneTicket;
  }

  function checkTotalTickets(uint256 jackpotID) public view returns (uint256) {
    return JackpotMapping[jackpotID].totalTickets;
  }

  function checkUserOwnedTickets(address user, uint256 jackpotID) public view returns (uint256) {
    return ownedTickets[user][jackpotID].length;
  }

  function checkJackpotStarted(uint256 jackpotID) public view returns (bool) {
    return JackpotMapping[jackpotID].started;
  }

  function checkJackpotEnded(uint256 jackpotID) public view returns (bool) {
    return JackpotMapping[jackpotID].ended;
  }

  function checkJackpotEndingTime(uint256 jackpotID) public view returns (uint256) {
    return JackpotMapping[jackpotID].endingTime;
  }

  function checkJackpotStartingTime(uint256 jackpotID) public view returns (uint256) {
    return JackpotMapping[jackpotID].startingTime;
  }

  function checkWinnersAmount(uint256 jackpotID) public view returns (uint32) {
    return JackpotMapping[jackpotID].winners;
  }
  
  
}