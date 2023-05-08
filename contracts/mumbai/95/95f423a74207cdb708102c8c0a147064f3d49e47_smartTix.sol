/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/SmartTix.sol

pragma solidity ^0.8.17;

interface TicketContract {
    function setBaseURI(string memory _newBaseURI) external;

    function setDate(uint _year, uint _month, uint _day) external;

    function setVenue(string memory _venue) external;

    function setPrice(uint _price) external;

    function setMaxSupply(uint _maxSupply) external;

    function setMaxAllocationPerUser(uint _maxAllocation) external;

    function setSalePhase(bool _phase) external;

    function ownerMint(uint _amount) external;

    function mint(uint _amount) external payable;

    function withdrawFunds() external;
}

contract smartTix is Ownable {
    uint public numberOfEvents;

    struct eventData {
        uint id;
        string showName;
        string venue;
        string description;
        string imageUrl;
        uint year;
        uint month;
        uint day;
        uint price;
        uint numberOfTickets;
        uint purchaseLimit;
        bool isSaleEnabled;
        address eventAddress;
        address owner;
    }

    eventData[] private allEvents;

    mapping(address => uint) public numberOfEventsPerDeployer;
    mapping(address => mapping(uint => uint)) public numberOfTicketsPurchased;

    function showAllevents() external view returns (eventData[] memory) {
        eventData[] memory events = new eventData[](numberOfEvents);
        for (uint i = 0; i < numberOfEvents; i++) {
            eventData storage eventItem = allEvents[i];
            events[i] = eventItem;
        }
        return events;
    }

    function showEventsPerDeployer(
        address _deployer
    ) external view returns (eventData[] memory) {
        eventData[] memory deployerEvents = new eventData[](
            numberOfEventsPerDeployer[_deployer]
        );
        for (uint i = 0; i < numberOfEvents; i++) {
            if (allEvents[i].owner == _deployer) {
                eventData storage eventItem = allEvents[i];
                deployerEvents[i] = eventItem;
            }
        }
        return deployerEvents;
    }

    function showTickets(
        address _user
    ) external view returns (eventData[] memory) {
        uint ticketsPurchased = 0;
        for (uint i = 0; i < numberOfEvents; i++) {
            if (numberOfTicketsPurchased[_user][i] != 0) ticketsPurchased++;
        }
        eventData[] memory events = new eventData[](ticketsPurchased);
        for (uint i = 0; i < numberOfEvents; i++) {
            if (numberOfTicketsPurchased[_user][i] != 0) {
                eventData storage eventItem = allEvents[i];
                events[i] = eventItem;
            }
        }
        return events;
    }

    function createEvent(
        string memory _showName,
        string memory _venue,
        string memory _description,
        string memory _imageUrl,
        uint _year,
        uint _month,
        uint _day,
        uint _price,
        uint _numberOfTickets,
        uint _purchaseLimit,
        address _eventAddress
    ) external {
        eventData memory newEvent = eventData(
            numberOfEvents,
            _showName,
            _venue,
            _description,
            _imageUrl,
            _year,
            _month,
            _day,
            _price,
            _numberOfTickets,
            _purchaseLimit,
            false,
            _eventAddress,
            msg.sender
        );

        allEvents.push(newEvent);
        numberOfEventsPerDeployer[msg.sender]++;
        numberOfEvents++;
    }

    function changeURI(
        uint _id,
        string memory _newURI,
        string memory _newImageUrl
    ) external {
        require(
            allEvents[_id].owner == msg.sender,
            "only the owner can make changes"
        );
        eventData storage _eventData = allEvents[_id];
        _eventData.imageUrl = _newImageUrl;
        TicketContract(allEvents[_id].eventAddress).setBaseURI(_newURI);
    }

    function changeDate(uint _id, uint _year, uint _month, uint _day) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).setDate(
            _year,
            _month,
            _day
        );
        eventData storage _eventData = allEvents[_id];
        _eventData.year = _year;
        _eventData.month = _month;
        _eventData.day = _day;
    }

    function changeVenue(uint _id, string memory _newVenue) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).setVenue(_newVenue);
        eventData storage _eventData = allEvents[_id];
        _eventData.venue = _newVenue;
    }

    function changeDescription(
        uint _id,
        string memory _newDescription
    ) external {
        require(allEvents[_id].owner == msg.sender);
        eventData storage _eventData = allEvents[_id];
        _eventData.description = _newDescription;
    }

    function changePrice(uint _id, uint _newPrice) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).setPrice(_newPrice);
        eventData storage _eventData = allEvents[_id];
        _eventData.price = _newPrice;
    }

    function changeSupply(uint _id, uint _newSupply) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).setMaxSupply(_newSupply);
        eventData storage _eventData = allEvents[_id];
        _eventData.numberOfTickets = _newSupply;
    }

    function changeAllocationPerUser(uint _id, uint _newAllocation) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).setMaxAllocationPerUser(
            _newAllocation
        );
        eventData storage _eventData = allEvents[_id];
        _eventData.purchaseLimit = _newAllocation;
    }

    function changeSalePhase(uint _id, bool _phase) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).setSalePhase(_phase);
        eventData storage _eventData = allEvents[_id];
        _eventData.isSaleEnabled = _phase;
    }

    function ownerMint(uint _id, uint _amount) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).ownerMint(_amount);
        numberOfTicketsPurchased[msg.sender][_id] += _amount;
    }

    function buyTicket(uint _id, uint _amount) external payable {
        require(msg.sender == tx.origin);
        TicketContract(allEvents[_id].eventAddress).mint{value: msg.value}(
            _amount
        );
        numberOfTicketsPurchased[msg.sender][_id] += _amount;
    }

    function withdrawFunds(uint _id) external {
        require(allEvents[_id].owner == msg.sender);
        TicketContract(allEvents[_id].eventAddress).withdrawFunds();
    }
}