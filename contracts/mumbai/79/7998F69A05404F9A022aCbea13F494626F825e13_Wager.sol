//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract EventManager {
    struct Event {
        string eventId;
        string eventName;
        uint outcomeCount;
        bool resultDeclared;
        bool bettingStarted;
        bool bettingEnded;
    }

    struct EventResult {
        string eventId;
        EventOutcome outcome;
        bool declared;
    }

    enum EventOutcome { Win, Draw, Lose }

    mapping(string => Event) public events;
    mapping(string => EventResult) public eventResults;
    uint public eventCount;
    address public owner;

    event EventCreated(string indexed eventId, string eventName, uint outcomeCount);
    event ResultDeclared(string indexed eventId, EventOutcome outcome);
    event BettingStarted(string indexed eventId);
    event BettingEnded(string indexed eventId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function generateEventId() internal view returns (string memory) {
        bytes32 random = keccak256(abi.encodePacked(block.timestamp, block.difficulty));
        bytes memory bytesArray = new bytes(32);

        for (uint i = 0; i < 32; i++) {
            bytesArray[i] = random[i];
        }

        return string(bytesArray);
    }

    function createEvent(string memory _eventName, uint _outcomeCount) external onlyOwner returns (Event memory) {
        require(_outcomeCount == 2 || _outcomeCount == 3, "Outcome count must be 2 or 3");
//        require(bytes(_eventId).length > 0, "Event ID must not be empty");

        string memory _eventId = generateEventId();
        eventCount++;
        Event memory newEvent = Event(_eventId, _eventName, _outcomeCount, false, false, false);
        events[_eventId] = newEvent;

        emit EventCreated(_eventId, _eventName, _outcomeCount);
        return newEvent;
    }

    function getOutcomeCount(string memory _eventId) public view returns (uint) {
        return events[_eventId].outcomeCount;
    }

    function startBetting(string memory _eventId) external onlyOwner {
        require(events[_eventId].outcomeCount > 0, "Invalid event");
        require(!events[_eventId].bettingStarted, "Betting already started");

        events[_eventId].bettingStarted = true;
        emit BettingStarted(_eventId);
    }

    function endBetting(string memory _eventId) external onlyOwner {
        require(events[_eventId].outcomeCount > 0, "Invalid event");
        require(events[_eventId].bettingStarted, "Betting not yet started");
        require(!events[_eventId].bettingEnded, "Betting already ended");

        events[_eventId].bettingEnded = true;
        emit BettingEnded(_eventId);
    }

    function declareResult(string memory _eventId) external onlyOwner {
        require(events[_eventId].outcomeCount > 0, "Invalid event");
        require(!eventResults[_eventId].declared, "Result already declared");

        uint outcomeCount = events[_eventId].outcomeCount;
        require(outcomeCount == 2 || outcomeCount == 3, "Invalid outcome");

        EventOutcome outcome = getRandomOutcome(outcomeCount);

        eventResults[_eventId] = EventResult(_eventId, outcome, true);
        events[_eventId].resultDeclared = true;

        emit ResultDeclared(_eventId, outcome);
    }

    function getRandomOutcome(uint outcomeCount) internal view returns (EventOutcome) {
        bytes32 seed = bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))));
        uint256 randomValue = uint256(seed) % outcomeCount;

        if (outcomeCount == 2) {
            return randomValue == 0 ? EventOutcome.Win : EventOutcome.Lose;
        } else if (outcomeCount == 3) {
            if (randomValue == 0) {
                return EventOutcome.Win;
            } else if (randomValue == 1) {
                return EventOutcome.Draw;
            } else {
                return EventOutcome.Lose;
            }
        } else {
            revert("Invalid outcome count");
        }
    }

    function checkEventResult(string memory _eventId) public view returns (EventOutcome) {
        require(eventResults[_eventId].declared, "Result not yet declared");

        return eventResults[_eventId].outcome;
    }

    function eventExists(string memory _eventId) public view returns (bool) {
        return bytes(events[_eventId].eventId).length > 0;
    }

    function hasBettingStarted(string memory _eventId) public view returns (bool) {
        return events[_eventId].bettingStarted;
    }

    function hasBettingEnded(string memory _eventId) public view returns (bool) {
        return events[_eventId].bettingEnded;
    }

    function hasResultDeclared(string memory _eventId) public view returns (bool) {
        return eventResults[_eventId].declared;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./EventManager.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Wager {
    struct Bet {
        address bettor;
        string eventId;
        EventOutcome outcome;
        uint256 amount;
    }

    enum EventOutcome {Win, Draw, Lose}

    mapping(address => mapping(string => Bet[])) private bets;
    mapping(string => mapping(EventOutcome => uint256)) private betPools;
    mapping(address => mapping(string => mapping(EventOutcome => uint256))) private bettorPools;

    address public tokenAddress;
    address public eventManagerAddress;
    bool public bettingPaused;
    address public owner;
    uint256 public balance;
    uint256 public devFeePercentage;

    EventManager private eventManager;
    IERC20 private token;

    event BetPlaced(address indexed bettor, string indexed eventId, EventOutcome outcome, uint256 amount);
    event BettingPaused();
    event BettingStarted();
    event TokenAddressChanged(address newTokenAddress);
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    event DevFeePercentageUpdated(uint256 newDevFeePercentage);

    modifier eventExists(string memory _eventId) {
        require(eventManager.eventExists(_eventId), "Invalid event");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier bettingNotPaused() {
        require(!bettingPaused, "Betting is paused");
        _;
    }

    constructor(address _tokenAddress, address _eventManagerAddress, uint256 _devFeePercentage) {
        tokenAddress = _tokenAddress;
        eventManagerAddress = _eventManagerAddress;
        owner = msg.sender;
        bettingPaused = false;
        devFeePercentage = _devFeePercentage;

        eventManager = EventManager(eventManagerAddress);
        token = IERC20(tokenAddress);
    }

    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function changeTokenAddress(address _newTokenAddress) external onlyOwner {
        tokenAddress = _newTokenAddress;
        token = IERC20(tokenAddress);

        emit TokenAddressChanged(_newTokenAddress);
    }

    function placeBet(string memory _eventId, uint256 _outcome, uint256 _amount) external eventExists(_eventId) bettingNotPaused {
        require(_amount > 0, "Amount must be greater than zero");

        require(!bettingPaused, "Betting is paused");

        require(eventManager.hasBettingStarted(_eventId), "Betting has not started for this event");

        require(!eventManager.hasBettingEnded(_eventId), "Betting has ended for this event");

        uint256 outcomeCount = eventManager.getOutcomeCount(_eventId);
        require(_outcome < outcomeCount, "Invalid bet outcome");

        require(token.approve(address(this), _amount), "Token approval failed");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Bet memory newBet = Bet(msg.sender, _eventId, EventOutcome(_outcome), _amount);
        bets[msg.sender][_eventId].push(newBet);

        updateBetPools(_eventId, EventOutcome(_outcome), _amount);

        emit BetPlaced(msg.sender, _eventId, EventOutcome(_outcome), _amount);
    }


    function updateBetPools(string memory _eventId, EventOutcome _outcome, uint256 _amount) private {
        betPools[_eventId][_outcome] += _amount;
        bettorPools[msg.sender][_eventId][_outcome] += _amount;
    }

    function getBets(address _bettor, string memory _eventId) external view returns (Bet[] memory) {
        return bets[_bettor][_eventId];
    }

    function getTotalBetPool(string memory _eventId, EventOutcome _outcome) public view returns (uint256) {
        return betPools[_eventId][_outcome];
    }

    function getBettorPoolPercentage(string memory _eventId, address _bettor, EventOutcome _outcome) public view returns (uint256) {
        uint256 bettorPool = bettorPools[_bettor][_eventId][_outcome];
        uint256 totalPool = betPools[_eventId][_outcome];

        if (totalPool == 0) {
            return 0;
        }

        return (bettorPool * 100) / totalPool;
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function pauseBetting() external onlyOwner {
        bettingPaused = true;
        emit BettingPaused();
    }

    function startBetting() external onlyOwner {
        bettingPaused = false;
        emit BettingStarted();
    }

    function withdraw(uint amount, address payable recipient) external onlyOwner {
        require(amount <= balance, "Insufficient funds");
        recipient.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, recipient, amount);
    }

    function transferTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        IERC20 _token = IERC20(_tokenAddress);
        uint256 balance_ = _token.balanceOf(address(this));
        require(_amount <= balance_, "Insufficient token balance");
        require(_token.transfer(_recipient, _amount), "Token transfer failed");
        emit TransferSent(msg.sender, _recipient, _amount);
    }

    function updateDevFeePercentage(uint256 _newDevFeePercentage) external onlyOwner {
        require(_newDevFeePercentage >= 0 && _newDevFeePercentage <= 100, "Invalid dev fee percentage");

        devFeePercentage = _newDevFeePercentage;
        emit DevFeePercentageUpdated(_newDevFeePercentage);
    }
}