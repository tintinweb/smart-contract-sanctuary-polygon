/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/interfaces/IWorldID.sol

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

// File: contracts/helpers/ByteHasher.sol


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

// File: contracts/Bote.sol


pragma solidity ^0.8.10;





contract Bote {
    using ByteHasher for bytes;
    using Counters for Counters.Counter;
    Counters.Counter private _pollId;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The WorldID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The application's action ID
    uint256 internal immutable actionId;

    /// @dev The WorldID group ID (1)
    uint256 internal immutable groupId = 1;
    enum State{
        started,
        ended,
        notStarted
    }

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(bytes32 => bool) internal nullifierHashes;
    mapping (uint =>uint) internal timings;
    event ResultAnnounced(uint[] indexed result);
    event Voted(string confirmation); 
    event PollStarted(uint indexed id);
    event PollCreated(uint indexed id, uint indexed duration);
    struct Poll {
        uint PollID;
        address creator;
        string[] parties;
        uint[] votes;
        State c_state;
        uint duration;
    }
    Poll[] internal polls;

    /// @param _worldId The WorldID instance that will verify the proofs
    /// @param _actionId The action ID for your application
    constructor(IWorldID _worldId, string memory _actionId) {
        worldId = _worldId;
        actionId = abi.encodePacked(_actionId).hashToField();
    }

    // Polling functions 

    function addPoll(uint _duration,string[] memory _parties)  external {
        Poll memory new_poll;
        _pollId.increment();
        new_poll.PollID=_pollId.current();
        new_poll.creator=msg.sender;
        new_poll.parties=_parties;
        new_poll.c_state=State.notStarted;
        new_poll.duration=_duration;
        new_poll.votes=new uint[](_parties.length);
        polls.push(new_poll);
        emit PollCreated(new_poll.PollID, new_poll.duration);
    }
    function startPoll(uint _pollID) public {
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        require(msg.sender==polls[_pollID-1].creator,"You do not have the permission to start the poll!");
        require(polls[_pollID-1].c_state==State.notStarted,"The poll was started before");
        timings[_pollID-1]=block.timestamp+polls[_pollID-1].duration*1 minutes;
        polls[_pollID-1].c_state=State.started;
        emit PollStarted(_pollID);
    }
    


    // Main voting function 

    /// @param input User's input, used as the signal. Could be something else! (see README)
    /// @param root The of the Merkle tree, returned by the SDK.
    /// @param nullifierHash The nullifier for this proof, preventing double signaling, returned by the SDK.
    /// @param proof The zero knowledge proof that demostrates the claimer is registered with World ID, returned by the SDK.
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function vote(
        address input,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        uint _pollID,
        string memory _partyName
    ) public {
        // first, we make sure this person hasn't done this before
        bytes32 new_hash=keccak256(abi.encodePacked(nullifierHash,_pollID));
        if (nullifierHashes[new_hash]) revert InvalidNullifier();

        // then, we verify they're registered with WorldID, and the input they've provided is correct
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(input).hashToField(),
            nullifierHash,
            actionId,
            proof
        );

        // finally, we record they've done this, so they can't do it again (proof of uniqueness)
        nullifierHashes[new_hash] = true;

        // your logic here, make sure to emit some kind of event afterwards!
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        require(polls[_pollID-1].c_state==State.started,"The poll has not been started yet!");
        require(block.timestamp<=timings[_pollID-1],"The poll has ended");
        //if(polls[_pollID])
        bool hasParty=false;
        uint indParty;
        for(uint i=0;i<polls[_pollID-1].parties.length;i++){
            if(keccak256(abi.encodePacked(polls[_pollID-1].parties[i]))==keccak256(abi.encodePacked(_partyName))){
                hasParty=true;
                indParty=i;
            }
        }
        require(hasParty,"There is no such party");
        polls[_pollID-1].votes[indParty]++;
        emit Voted("Your response has been recorded");
    }

    //getter functions 
    function showResult(uint _pollID) public returns (uint[]memory){
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        require(block.timestamp>timings[_pollID-1],"The poll has not ended yet");
        polls[_pollID-1].c_state=State.ended;
        emit ResultAnnounced(polls[_pollID-1].votes);
        return polls[_pollID-1].votes;
    }
    function getState(uint _pollID) public view returns(State){
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        return polls[_pollID-1].c_state;
    }

    function getParties(uint pollID) public view returns(string[] memory){
        require(pollID<=_pollId.current(),"The given poll ID does not exist");
        return polls[pollID-1].parties;
    }

    function myPolls() public view returns (Poll[] memory){
        uint count=0;
        for(uint i=0;i<polls.length;i++){
            if(polls[i].creator==msg.sender){
                count++;
            }
        }
        Poll[] memory m_polls=new Poll[](count);
        uint j=0;
        for(uint i=0;i<polls.length;i++){
            if(polls[i].creator==msg.sender){
                m_polls[j]=polls[i];
                j++;
            }
        }
        return m_polls;
    }
}