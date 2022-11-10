/**
 *Submitted for verification at polygonscan.com on 2022-11-09
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

// File: contracts/Bote.sol


pragma solidity ^0.8.7;



contract Bote{
    using Counters for Counters.Counter;
    Counters.Counter private _pollId;

    enum State{
        started,
        ended,
        notStarted
    }
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
    Poll[] public polls;
    Poll[] public votedPolls;
    function vote(uint _pollID,string memory _partyName) external {
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        require(block.timestamp<=timings[_pollID],"The poll has ended");
        require(polls[_pollID].c_state==State.started,"The poll has not been started yet!");
        bool hasParty=false;
        uint indParty;
        for(uint i=0;i<polls[_pollID].parties.length;i++){
            if(keccak256(abi.encodePacked(polls[_pollID].parties[i]))==keccak256(abi.encodePacked(_partyName))){
                hasParty=true;
                indParty=i;
            }
        }
        require(hasParty,"There is no such party");
        bytes32 new_hash=keccak256(abi.encodePacked(msg.sender,_pollID));
        require(!nullifierHashes[new_hash],"You have already voted");
        nullifierHashes[new_hash]=true;
        polls[_pollID].votes[indParty]++;
        emit Voted("Your response has been recorded");
    }

    function addPoll(uint _duration,string[] memory _parties)  public {
        _pollId.increment();
        uint[] memory _votes=new uint[](_parties.length);
        Poll memory new_poll;
        new_poll.PollID=_pollId.current();
        new_poll.creator=msg.sender;
        new_poll.parties=_parties;
        new_poll.c_state=State.notStarted;
        new_poll.duration=_duration;
        new_poll.votes=_votes;
        polls.push(new_poll);
        emit PollCreated(new_poll.PollID, new_poll.duration);
    }
    function startPoll(uint _pollID) public {
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        require(msg.sender==polls[_pollID].creator,"You do not have the permission to start the poll!");
        require(polls[_pollID].c_state==State.notStarted,"The poll was started before");
        timings[_pollID]=block.timestamp+polls[_pollID].duration*1 minutes;
        polls[_pollID].c_state=State.started;
        votedPolls.push(polls[_pollID]);
        emit PollStarted(_pollID);
    }
    function Announce(uint _pollID) public returns (uint[]memory){
        require(_pollId.current()>=_pollID,"Given poll id does not exist");
        require(block.timestamp>timings[_pollID],"The poll has not ended yet");
        polls[_pollID].c_state=State.ended;
        emit ResultAnnounced(polls[_pollID].votes);
        return polls[_pollID].votes;
    }
    function getState(uint _pollID) public view returns(State){
        return polls[_pollID].c_state;
    }

    function getParties(uint pollID) public view returns(string[] memory){
        require(pollID<=_pollId.current(),"The given poll ID does not exist");
        return polls[pollID].parties;
    }
    function getVotes(uint pollID) public view returns (uint[] memory){
        require(pollID<=_pollId.current(),"The given poll ID does not exist");
        return polls[pollID].votes;
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