/**
 *Submitted for verification at polygonscan.com on 2023-05-28
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

// File: contracts/Race.sol


pragma solidity ^0.8.17;


contract Race{

    using Counters for Counters.Counter;
    enum State{idle,started,completed} 

    struct RaceData{
        address raceOwner;
        uint256 id;
        mapping (address=>uint256) Players;//players state
        State raceState;
    }

    Counters.Counter private _raceIDs;
    mapping(uint256 => RaceData) private  Races;

    function createRace() public returns(uint256) {
        uint256 newRaceID = _raceIDs.current();
        Races[newRaceID].id=newRaceID;
        Races[newRaceID].raceState=State.idle;
        Races[newRaceID].raceOwner=msg.sender;
        addPlayer(newRaceID, msg.sender);
        _raceIDs.increment();
        return newRaceID;
    }

    function addPlayer(uint256 raceID,address playerAddress) public {
        require(Races[raceID].raceState==State.idle,"the race has already started");
        require(msg.sender==playerAddress,"caller is not the player address");
        Races[raceID].Players[playerAddress]=1;//entered the race
    }

    function removePlayer(uint256 raceID,address playerAddress) public {
        require(Races[raceID].Players[msg.sender]>0,"you are not one of the players");
        require(msg.sender==playerAddress,"caller is not the player address");
        if(Races[raceID].raceState==State.idle || Races[raceID].raceState==State.started){
            Races[raceID].Players[playerAddress]=0;//left the race
        }
        else{
            Races[raceID].Players[playerAddress]=2;//entered and finished the race
        }
    }

    function getRaceState(uint256 raceID) public view returns (State){
        return Races[raceID].raceState;
    }

    function startRace(uint256 raceID)public{
        require(msg.sender==Races[raceID].raceOwner,"you are not the creater of the race");
        Races[raceID].raceState=State.started;
    }

    function endRace(uint256 raceID)public{
        require(Races[raceID].Players[msg.sender]>0,"you are not one of the players");
        Races[raceID].raceState=State.completed;
    }

    function hasPlayerCompletedRace(address playerAddress,uint256 raceID) public view returns(bool){
        if(Races[raceID].raceState==State.completed){
            if(Races[raceID].Players[playerAddress]==2){
                return true;//race has ended and player actually did complete the race
            }
        }
        return false;
    }

    function getPlayerStatus(address playerAddress,uint raceID)public view returns(uint256){
        return Races[raceID].Players[playerAddress];
    }
}