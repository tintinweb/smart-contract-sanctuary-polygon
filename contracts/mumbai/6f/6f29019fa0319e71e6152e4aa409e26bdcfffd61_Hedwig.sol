/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/Hedwig.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Hedwig {
    using Counters for Counters.Counter;
    Counters.Counter public sessionID;
    
    struct Session {
        uint256 G;
        address from;
        address to;
        uint256 key1;
        uint256 key2;
    }
    mapping(uint256 => Session) public sessions;
    mapping(address => uint256[]) public addressToSessionIDs;

    uint constant mod = 10**16;
    
    event SessionStart(address from, address to, uint256 sessionID);

    modifier onlyOwners(uint256 _sessionID){
        require(msg.sender == sessions[_sessionID].from || msg.sender == sessions[_sessionID].to, "You are not associated with this session");
        _;
    }

    function startSession(address to) external returns(uint256 id){
        uint256 _sessionID = sessionID.current();
        uint256 _G = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, to))) % mod;

        sessions[_sessionID] = Session(
            _G,
            msg.sender,
            to,
            0,
            0
        );
        addressToSessionIDs[msg.sender].push();
        addressToSessionIDs[to].push();
        sessionID.increment();
        emit SessionStart(msg.sender, to, _sessionID);
        return _sessionID;
    }

    function getKey(uint256 _sessionID, uint256 seed) external view returns(uint256 key){
        return (sessions[_sessionID].G * seed) % mod;
    }

    function initiateConnection(uint256 _sessionID, uint256 key) external onlyOwners(_sessionID){
        require(sessions[_sessionID].key1 == 0 || sessions[_sessionID].key2 == 0, "Keys are initialized");
        if (sessions[_sessionID].from == msg.sender){
            sessions[_sessionID].key1 = key;
        } else {
            sessions[_sessionID].key2 = key;
        }

    }

    function connect(uint256 _sessionID, uint256 seed) external view returns(uint256 key){
        require(sessions[_sessionID].key1 != 0 && sessions[_sessionID].key2 != 0, "Both keys should be added first.");
        if (sessions[_sessionID].from == msg.sender){
            return (sessions[_sessionID].key2 * seed) % mod;
        } else {
            return (sessions[_sessionID].key1 * seed) % mod;
        }
    }

    function getSessions() external view returns(uint256[] memory _sessions){
        return addressToSessionIDs[msg.sender];
    }
}