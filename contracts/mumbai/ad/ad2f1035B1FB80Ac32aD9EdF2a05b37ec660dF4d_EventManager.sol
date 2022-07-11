pragma solidity ^0.8.0;

contract EventManager {

    struct Event {
        bytes cid;
        uint16 ticketsTotal;
        uint256 endDate;
    }

    uint256 constant public fee = 10 ** 17;

    mapping(address => Event[]) public events;
    address payable public owner;

    event EventCreated(address eventCreator, uint256 index);

    constructor() {
        owner = payable(msg.sender);
    }

    function withdraw() public {
        require(msg.sender == owner, "only owner could withdraw");
        owner.transfer(address(this).balance);
    }

    function createEvent(bytes calldata cid, uint16 ticketsTotal, uint256 endDate) public payable {
        require(msg.value >= fee, "too small fee");
        Event memory newEvent;
        newEvent.cid = cid;
        newEvent.ticketsTotal = ticketsTotal;
        newEvent.endDate = endDate;
        events[msg.sender].push(newEvent);

        emit EventCreated(msg.sender, endDate);
    }
}