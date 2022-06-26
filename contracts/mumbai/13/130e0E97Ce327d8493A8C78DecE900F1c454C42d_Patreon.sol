/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/Patreon.sol


pragma solidity ^0.8.0;


/** 
 * @title Patreon
 * @dev Implements a decentralized version of patreon
 */
contract Patreon {

    using Counters for Counters.Counter;
    Counters.Counter private _creatorIds;

    struct Tier {
        bool published;
        string title;
        uint256 price;
        string image;
        string benefits;
        string description;
    }
    struct Creator {
        bool launched;
        address creatorAddress;

        //  Basics Fields
        string profilePhoto;
        string coverPhoto;
        string name;
        string isAreCreating;
        string about;
        
        // Tier Fields
        Tier[] tiers;
    }
    
    mapping(uint256 => address) private creatorIds;
    mapping(address => Creator) private creators;
    mapping(address => bool) private started;

    function getCreatorCount() public view returns (uint count) {
       return _creatorIds.current();
    }

    function launch() public returns (bool success){
        require(creators[msg.sender].launched == false, "Page is launched");
        creators[msg.sender].creatorAddress = msg.sender;
        creators[msg.sender].launched  = true;
        if(!started[msg.sender]){
            creatorIds[_creatorIds.current()] = msg.sender;
            started[msg.sender] = true;
            _creatorIds.increment();
        }

        return true;
    }

    function takeDown() public returns (bool success){
        require(creators[msg.sender].launched  == true, "Page is not launched");
        creators[msg.sender].launched  = false;
        return true;
    }

    function fillBasics(string memory _profilePhoto, string memory _coverPhoto, string memory _name, string memory _isAreCreating, string memory _about) public returns (bool success){
        creators[msg.sender].profilePhoto = _profilePhoto;
        creators[msg.sender].coverPhoto = _coverPhoto;
        creators[msg.sender].name = _name;
        creators[msg.sender].isAreCreating = _isAreCreating;
        creators[msg.sender].about = _about;
        return true;
    }

    function getCreator(address _creatorId) public view returns (Creator memory _creator) {
       return creators[_creatorId];
    }

    function getCreator(uint256 _creatorId) public view returns (Creator memory _creator) {
       return creators[creatorIds[_creatorId]];
    }
}