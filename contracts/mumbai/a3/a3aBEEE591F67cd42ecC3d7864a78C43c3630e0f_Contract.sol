/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

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

// File: contracts/Contract.sol


pragma solidity ^0.8.13;



contract Contract {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();
    enum State{
        started,
        ended,
        notStarted
    }
    struct Poll {
        uint PollID;
        address creator;
        string[] parties;
        uint[] votes;
        State c_state;
        uint duration;
    }
    mapping (uint =>uint) internal timings;


    /// @dev used to store different polls
    Poll[] internal polls;

    /// @dev The WorldID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The WorldID group ID (1)
    uint256 internal immutable groupId = 1;

    /// @dev I dont know wheter to change this or signal for voting in different polls? 
    uint256 internal immutable actionId;

    event Voted(string confirmation); 
    event PollStarted(uint indexed id);
    event PollCreated(uint indexed id, uint indexed duration);

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;


    /// @param _worldId The WorldID instance that will verify the proofs
    constructor(IWorldID _worldId,string memory _actionId) {
        worldId = _worldId;
        actionId=abi.encodePacked(_actionId).hashToField();
    }

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
        uint _partyIndx
    ) public {
        // first, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

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
        nullifierHashes[nullifierHash] = true;
        // your logic here, make sure to emit some kind of event afterwards!
        require(polls.length>_pollID,"Given poll id does not exist");
        require(block.timestamp<=timings[_pollID],"The poll has ended");
        require(polls[_pollID].c_state==State.started,"The poll has not been started yet!");
        polls[_pollID].votes[_partyIndx]++;
        emit Voted("Your response has been recorded");
    }
    function addPoll(uint _duration,string[] memory _parties)  public {
        Poll memory new_poll;
        new_poll.PollID=polls.length+1;
        new_poll.creator=msg.sender;
        new_poll.parties=_parties;
        new_poll.c_state=State.notStarted;
        new_poll.duration=_duration;
        new_poll.votes=new uint[](_parties.length);
        polls.push(new_poll);
        emit PollCreated(new_poll.PollID, new_poll.duration);
    }
    
function startPoll(uint _pollID) public {
    require(polls.length>_pollID,"Given poll id does not exist");
    require(msg.sender==polls[_pollID].creator,"You do not have the permission to start the poll!");
    require(polls[_pollID].c_state==State.notStarted,"The poll was started before");
    timings[_pollID]=block.timestamp+polls[_pollID].duration*1 minutes;
    polls[_pollID].c_state=State.started;
    emit PollStarted(_pollID);
}

// function vote(uint _pollID,uint _partyIndx) public{
//     require(polls.length>_pollID,"Given poll id does not exist");
//     require(block.timestamp<=timings[_pollID],"The poll has ended");
//     require(polls[_pollID].c_state==State.started,"The poll has not been started yet!");
//     polls[_pollID].votes[_partyIndx]++;
// }

function showResult(uint _pollID) public returns (uint[]memory){
    require(polls.length>_pollID,"Given poll id does not exist");
    require(block.timestamp>timings[_pollID],"The poll has not ended yet");
    polls[_pollID].c_state=State.ended;
    return polls[_pollID].votes;
}
}