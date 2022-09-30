// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/UnorderedKeySetLib.sol";
import "./interfaces/IEverRoseEvent.sol";

contract EverRoseEvent is Ownable, IEverRoseEvent {

    uint256 private constant DEFAULT_EVENT_PRICE = 0;  // 0€ in cents
    uint256 private constant DEFAULT_MAX_TICKETS = 100;
    uint256 private constant DEFAULT_MAX_TICKETS_PER_MINT = 1;

    using UnorderedKeySetLib for UnorderedKeySetLib.Set;
    UnorderedKeySetLib.Set everRoseEventKeys;

    mapping(bytes32 => everRoseEventStruct) everRoseEvents;

    function add(bytes32 key, everRoseEventStruct memory everRoseEvent) public onlyOwner {
        everRoseEventKeys.insert(key);
        // Note that this will fail automatically if the key already exists.
        everRoseEventStruct storage evt = everRoseEvents[key];
        evt.key = key;
        evt.ticketPrice = (everRoseEvent.ticketPrice != 0) ? everRoseEvent.ticketPrice : DEFAULT_EVENT_PRICE;
        evt.startDate = everRoseEvent.startDate;
        evt.endDate = everRoseEvent.endDate;
        evt.startSaleDate = everRoseEvent.startSaleDate;
        evt.endSaleDate = everRoseEvent.endSaleDate;
        evt.maxTickets = (everRoseEvent.maxTickets != 0) ? everRoseEvent.maxTickets : DEFAULT_MAX_TICKETS;
        evt.maxTicketsPerMint = (everRoseEvent.maxTicketsPerMint != 0) ? everRoseEvent.maxTicketsPerMint : DEFAULT_MAX_TICKETS_PER_MINT;
        evt.isPublic = everRoseEvent.isPublic;
        evt.name = everRoseEvent.name;
        evt.description = everRoseEvent.description;
        evt.location = everRoseEvent.location;
        evt.organizer = everRoseEvent.organizer;
        evt.uri = everRoseEvent.uri;

        emit LogNewEvent(msg.sender, key, evt);
    }

    function update(bytes32 key, everRoseEventStruct memory everRoseEvent) public onlyOwner {
        require(everRoseEventKeys.exists(key), "bad key");
        IEverRoseEvent.everRoseEventStruct storage evt = everRoseEvents[key];
        evt.name = (bytes(everRoseEvent.name).length > 0) ? everRoseEvent.name : evt.name;
        evt.description = (bytes(everRoseEvent.description).length > 0) ? everRoseEvent.description : evt.description;
        evt.location = (bytes(everRoseEvent.location).length > 0) ? everRoseEvent.location : evt.location;
        evt.organizer = (bytes(everRoseEvent.organizer).length > 0) ? everRoseEvent.organizer : evt.organizer;
        evt.uri = (bytes(everRoseEvent.uri).length > 0) ? everRoseEvent.uri : evt.uri;
        evt.startDate = (everRoseEvent.startDate != 0) ? everRoseEvent.startDate : evt.startDate;
        evt.endDate = (everRoseEvent.endDate != 0) ? everRoseEvent.endDate : evt.endDate;
        evt.startSaleDate = (everRoseEvent.startSaleDate != 0) ? everRoseEvent.startSaleDate : evt.startSaleDate;
        evt.endSaleDate = (everRoseEvent.endSaleDate != 0) ? everRoseEvent.endSaleDate : evt.endSaleDate;
        evt.ticketPrice = (everRoseEvent.ticketPrice != 0) ? everRoseEvent.ticketPrice : evt.ticketPrice;
        evt.maxTickets = (everRoseEvent.maxTickets != 0) ? everRoseEvent.maxTickets : evt.maxTickets;
        evt.maxTicketsPerMint = (everRoseEvent.maxTicketsPerMint != 0) ? everRoseEvent.maxTicketsPerMint : evt.maxTicketsPerMint;
        evt.isPublic = (everRoseEvent.isPublic == true ) ? true : false;

        emit LogUpdateEvent(msg.sender, key, evt);
    }

    function remove(bytes32 key) public onlyOwner {
        everRoseEventKeys.remove(key);
        // Note that this will fail automatically if the key doesn't exist
        delete everRoseEvents[key];
        emit LogRemEvent(msg.sender, key);
    }

    function get(bytes32 key) public view returns (everRoseEventStruct memory) {
        require(everRoseEventKeys.exists(key), "bad key");
        return everRoseEvents[key];
    }

    function exist(bytes32 key) public view returns (bool){
        return everRoseEventKeys.exists(key);
    }

    function count() public view returns (uint256) {
        return everRoseEventKeys.count();
    }

    function getAtIndex(uint index) public view returns (bytes32 key) {
        return everRoseEventKeys.keyAtIndex(index);
    }

    function all() public view returns (everRoseEventStruct[] memory) {
        everRoseEventStruct[] memory ret = new everRoseEventStruct[](count());
        for (uint i = 0; i < count(); i++) {
            ret[i] = get(getAtIndex(i));
        }
        return ret;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnorderedKeySetLib {

    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
        bytes32 keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IEverRoseEvent {

    struct everRoseEventStruct {
        bytes32 key;
        uint256 ticketPrice;
        uint256 startSaleDate;
        uint256 endSaleDate;
        uint256 startDate;
        uint256 endDate;
        uint256 maxTickets;
        uint256 maxTicketsPerMint;
        bool isPublic;
        string name;
        string description;
        string location;
        string organizer;
        string uri;
    }

    event LogNewEvent(address sender, bytes32 key, everRoseEventStruct everRoseEvent);
    event LogUpdateEvent(address sender, bytes32 key, everRoseEventStruct everRoseEvent);
    event LogRemEvent(address sender, bytes32 key);

    function add(bytes32 key, everRoseEventStruct memory everRoseEvent) external;

    function update(bytes32 key, everRoseEventStruct memory everRoseEvent) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns(everRoseEventStruct memory everRoseEvent);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns(uint256);

    function getAtIndex(uint index) external view returns(bytes32 key);

    function all() external view returns (everRoseEventStruct[] memory everRoseEvents);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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