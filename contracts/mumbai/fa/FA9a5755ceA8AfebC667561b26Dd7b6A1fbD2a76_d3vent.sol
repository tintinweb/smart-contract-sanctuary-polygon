// todos and questions of what to do

    // should we allow multiple organisers?
    // should we allow an event wallet address so funds can be withdrawn to a non organiser address e.g. a multisig wallet?

    // setting up a voting mechanism where joiners can vote to call the event failed in some way 
    // and so prevent the organiser withdrawal, and can claim back their funds
    // a period up to which a joiner can unjoin and get a refund. after a certain point it's too late
    // this should be expressed as a period before event start time. prevet organiser simply bringing the event forward and 
    // being able rug pull / be sure prevent dirty tricks. e.g. make sure unjoining can't be shortened below a certain period
    // need proof of personhood otherwise susceptible sybil attack from both sides

    // add support for worldcoin plus another wallet

    // access control to allow end user owner only. trustless or also admins. are there any organisational admins?

    // should created events be immutable or setters for most things so they can be changed. what should be ammendable.
    // if changes allowed, should have 1 setter function with all changeable settings, or setter for each
    // organiser might reasonablely need ot change a event date or change a URI.
    // change: organiser, multiple organisers, event name, uri, datetime, price capacity
    // allow set different address as organiser at create time or able to change after
    // create event: consider capacity of zero is unlimited or throw error?
    // being able to change the event date does present possibilities of gaming the system and if allowed there should be restrictions
    // if organiser change change dates, joiners should be allowed to unjoin and get their funds back.
    // workflow questions: should newly created even have eventActive as param or always true/false
    // should there be a way to cancel an event - how should that be represented
    // should we have a cancelled / finished status

    // create event organiser always msg.sender? setOrgnaiser function to change?
    // should event have a closed/finished dateTime?
    // should joiner address always be msg.sender or allow to join another address?
    
    // don't think there's any need to zero out joiner balances after organiser withdrawal, but could add a flag for added safety
    // would be too gassy iterating through a large number of joiners
    // 
    
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";

contract d3vent {
    event CreatedEvent(uint indexed eventId, uint indexed eventDate, string indexed eventName);
    event Withdrawal(uint indexed eventId, address indexed organiser, uint balance);
    event JoinableSet(uint indexed eventId, bool isJoinable);
    event NewOrganiser(uint indexed eventId, address newOrganiser);
    event AdminAdded(address indexed newAdmin, address indexed addedBy);
    event AdminDeleted(address indexed deletedAdmin, address indexed deletedBy);
    event WorldcoinAddressChanged(address indexed newAddress, address indexed changedBy);
    event UserVerified(address indexed user);

    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();
 
    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    address private worldcoin;  //note: this is immutable in Worlcoin's example contract
    
    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(uint256 => bool) internal nullifierHashes;

    
    uint eventIds;
    uint immutable withdrawalBuffer;
    uint adminsCount;
    

    struct event_ {
        address organiser;
        uint id;
        string name;
        string uri;
        uint dateTime;
        uint price;
        uint128 capacity;
        uint128 numJoined;      
        bool isJoinable;
        uint withdrawalDate;
    }

    event_[] events;

    mapping(address => bool) isVerified; // user address => bool
    mapping(uint => mapping(address => bool)) isJoined;    // eventId => user address => isJoined
    mapping(uint => mapping(address => uint)) joinerBalances;   // eventId => user address => balance
    mapping(uint => uint) eventBalances;    // eventId => event balance
    mapping(address => bool) isAdmin;   // admin address to bool
    

    constructor (uint _withdrawalBuffer, IWorldID _worldId) {
        isAdmin[msg.sender] = true;
        adminsCount = 1;
        worldId = _worldId;
        withdrawalBuffer = _withdrawalBuffer;
    }


    function kill() external onlyAdmins {
        selfdestruct(payable(msg.sender));
    }


    function setWorldcoinAddress(address _addr) external onlyAdmins {
        require(_addr != address(0), "invalid address 0");
        worldcoin = _addr;
        emit WorldcoinAddressChanged(_addr, msg.sender);
    }

    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further details)
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demostrates the claimer is registered with World ID (returned by the JS widget).
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function verifyAndExecute(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        // First, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );

        // We now record the user has done this, so they can't do it again (proof of uniqueness)
        nullifierHashes[nullifierHash] = true;

        // Finally, execute your logic here, for example issue a token, NFT, etc...
        // Make sure to emit some kind of event afterwards!
        isVerified[signal] = true;
        emit UserVerified(signal);
    }



    modifier onlyOrganiser (uint _id) {
        require(msg.sender == events[_id].organiser, "only organiser");
        _;
    }


    modifier onlyAdmins {
        require(isAdmin[msg.sender], "only admins");
        _;
    }


    function addAdmin(address _newAdmin) external onlyAdmins {
        ++adminsCount;
        isAdmin[_newAdmin] = true;
        emit AdminAdded(_newAdmin, msg.sender);
    }


    function deleteAdmin(address _newAdmin) external onlyAdmins {
        require(adminsCount > 1, "can't delete last admin");
        --adminsCount;
        isAdmin[_newAdmin] = false;
    }


    // test parameters: "test event name","https://livepeer.org/123",1662994265,1000,1000000,false
    function createEvent(
        //string calldata _eventName,
        string calldata _name,
        string calldata _uri,
        uint _dateTime,
        uint _price,
        uint128 _capacity,
        bool _isJoinable
        ) external {              // public to allow internal calls for testing

        // sanity checks
        require(_dateTime > block.timestamp, "date/time in past");

        event_ memory newEvent;
        
        newEvent.organiser = msg.sender;
        newEvent.id = eventIds++;
        newEvent.name = _name;
        newEvent.uri = _uri;
        newEvent.dateTime = _dateTime;
        newEvent.price = _price;
        newEvent.capacity = _capacity;
        newEvent.isJoinable = _isJoinable;
    
        events.push(newEvent);
        emit CreatedEvent(newEvent.id, newEvent.dateTime, newEvent.name);
    }


    function setOrganiser(uint _id, address _newOrganiser) external onlyOrganiser(_id) {
        // sanity checks
        require(_newOrganiser != address(0), "invalid: zero address");
        require(_id <= eventIds, "invalid event id");
        events[_id].organiser = _newOrganiser;
        emit NewOrganiser(_id, _newOrganiser);
    }


    function setEventIsJoinable(uint _id, bool _isJoinable) external onlyOrganiser(_id) {
        require(! events[_id].isJoinable, "already joinable");
        events[_id].isJoinable = _isJoinable;
        emit JoinableSet(_id, _isJoinable);
    }

    // @dev needs proof of personhood
    // support superfluid payments? how would that affect logic
    // 
    function joinEvent(uint _id) external payable {
        require(_id <= eventIds, "invalid event id");
        require(events[_id].isJoinable, "cant join at this time");
        require(msg.value == events[_id].price, "send event price");
        require(! isJoined[_id][msg.sender], "already joined");

        ++events[_id].numJoined;
        isJoined[_id][msg.sender] = true;
        eventBalances[_id] = msg.value;
    }
    

    // @dev anyone can view all event details    
    function getEvent(uint _id) external view returns (event_ memory) {
        require(_id <= eventIds, "invalid event id");
        return events[_id];
    }

    
    //@dev event organiser can withdraw event balance
    function organiserWithdrawal(uint _id) external onlyOrganiser(_id) {
        require(block.timestamp >= events[_id].withdrawalDate + withdrawalBuffer, "withdrawal not allowed yet");
        
        uint _balance = eventBalances[_id];
        eventBalances[_id] = 0;
        (bool success, ) = msg.sender.call{value: _balance}("");
        require(success, "withdrawal failed");
        emit Withdrawal(_id, msg.sender, _balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}