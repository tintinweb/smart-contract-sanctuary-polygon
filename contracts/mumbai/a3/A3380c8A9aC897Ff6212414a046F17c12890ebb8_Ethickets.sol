/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/Ethickets.sol

pragma solidity ^0.8.9;
contract Ethickets is Ownable {

    struct Event {
        uint id;
        address owner;
        string name;
        string description;
        uint dateTime;
        string location;
        string imgUrl;
        mapping(uint => Ticket) tickets;
        mapping(address => bool) verifiers;
    }

    struct BasicEventInfo {
        uint id;
        address owner;
        string name;
        string description;
        uint dateTime;
        string location;
        string imgUrl;
    }

    struct Ticket {
        uint id;
        address owner;
        uint price;
        bool isForSale;
        bool isLockedIn;
    }

    uint private eventIdCounter = 0;


    mapping(uint => uint) public eventTicketIdCounters;
    mapping(uint => Event) public events;

    constructor(){}

    function createEvent(string memory _name, string memory _description, uint _dateTime, string memory _location, string memory _imgUrl) public returns(uint eventId){

        eventId = eventIdCounter++;
        Event storage newEvent = events[eventId];

        newEvent.id = eventId;
        newEvent.owner = msg.sender;
        newEvent.name = _name;
        newEvent.description = _description;
        newEvent.dateTime = _dateTime;
        newEvent.location = _location;
        newEvent.imgUrl = _imgUrl;
        newEvent.verifiers[msg.sender] = true;

        return eventId;
    }

    function addTicketsToEvent(uint _eventId, uint _amount, uint _price) public {
        Event storage existingEvent = events[_eventId];
        require(existingEvent.owner == msg.sender, "Caller is not event owner");
        mapping(uint => Ticket) storage eventTickets = existingEvent.tickets;
        uint eventTicketIdCounter = eventTicketIdCounters[_eventId];
        for(uint i = 0; i < _amount; i++){
            Ticket storage ticket = eventTickets[i];
            ticket.id = eventTicketIdCounter++;
            ticket.owner = msg.sender;
            ticket.price = _price;
            ticket.isForSale = true;
            ticket.isLockedIn = false;
        }
        eventTicketIdCounters[_eventId] = eventTicketIdCounter;
    }

    function getEventTickets(uint _eventId) public view returns(Ticket[] memory){
        Event storage existingEvent = events[_eventId];
        uint eventTicketIdCounter = eventTicketIdCounters[_eventId];
        Ticket[] memory eventTickets = new Ticket[](eventTicketIdCounter);
        for(uint i = 0; i < eventTicketIdCounter; i++){
            eventTickets[i] = existingEvent.tickets[i];
        }
        return eventTickets;
    }

    function getTicketData(uint _eventId, uint _ticketId) public view returns(Ticket memory){
        return events[_eventId].tickets[_ticketId];
    }

    function lockInTicket(uint _eventId, uint _ticketId) public {
        Ticket storage ticket = events[_eventId].tickets[_ticketId];
        require(ticket.owner == msg.sender, "Caller is not ticket owner");
        ticket.isLockedIn = true;
    }

    function transferTicket(uint _eventId, uint _ticketId, address _to) public {
        Ticket storage ticket = events[_eventId].tickets[_ticketId];
        require(ticket.owner == msg.sender, "Caller is not ticket owner");
        require(!ticket.isLockedIn, "Cannot transfer locked in ticket.");
        ticket.owner = _to;
    }

    function editTicketData(uint _eventId, uint _ticketId,bool _isForSale, uint _price) public {
        Ticket storage ticket = events[_eventId].tickets[_ticketId];
        require(ticket.owner == msg.sender, "Caller is not ticket owner");
        require(!ticket.isLockedIn, "Cannot edit locked in ticket.");
        ticket.isForSale = _isForSale;
        ticket.price = _price;
    }

    function buyTicket(uint _eventId, uint _ticketId) public payable {
        Ticket storage ticket = events[_eventId].tickets[_ticketId];
        require(!ticket.isLockedIn, "Cannot buy locked in ticket.");
        require(ticket.isForSale, "Ticket is not for sale");
        require(msg.value == ticket.price, "Incorrect amount sent");

        ticket.owner = msg.sender;
        ticket.isForSale = false;
        (bool sent, bytes memory data) = payable(ticket.owner).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function getEvents() public view returns(BasicEventInfo[] memory){
        BasicEventInfo[] memory allEvents = new BasicEventInfo[](eventIdCounter);
        for(uint i = 0; i < eventIdCounter; i++){
            Event storage _event = events[i];
            allEvents[i] = BasicEventInfo(_event.id, _event.owner, _event.name, _event.description, _event.dateTime,
                _event.location, _event.imgUrl);
        }
        return allEvents;
    }

    function getEventsByOwner(address _owner) public view returns(BasicEventInfo[] memory){
        uint eventsCountForAddress = getEventsCountForAddress(_owner);
        BasicEventInfo[] memory addressEvents = new BasicEventInfo[](eventsCountForAddress);

        for(uint i = 0; i < eventsCountForAddress; i++){
            Event storage _event = events[i];
            if(_event.owner == _owner){
                addressEvents[i] = BasicEventInfo(_event.id, _event.owner, _event.name, _event.description, _event.dateTime,
                    _event.location, _event.imgUrl);
            }
        }
        return addressEvents;
    }

    function getEventsCountForAddress(address _owner) public view returns (uint){
        uint counter = 0;
        for(uint i = 0; i < eventIdCounter; i++){
            Event storage _event = events[i];
            if(_event.owner == _owner){
                counter++;
            }
        }
        return counter;
    }

    function setVerifier(uint _eventId, address _verifier, bool _canVerify) public onlyOwner {
        events[_eventId].verifiers[_verifier] = _canVerify;
    }

    function canVerify(uint _eventId, address _verifier) public view returns(bool) {
        return events[_eventId].verifiers[_verifier];
    }

    function editEventData(uint _eventId, string memory _name, string memory _description, uint _dateTime, string memory _location, string memory _imgUrl) public {
        Event storage newEvent = events[_eventId];
        newEvent.name = _name;
        newEvent.description = _description;
        newEvent.dateTime = _dateTime;
        newEvent.location = _location;
        newEvent.imgUrl = _imgUrl;
    }
}