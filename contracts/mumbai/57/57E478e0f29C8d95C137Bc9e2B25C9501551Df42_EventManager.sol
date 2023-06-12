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