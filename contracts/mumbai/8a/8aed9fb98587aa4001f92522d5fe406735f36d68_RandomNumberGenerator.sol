// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/utils/Counters.sol";


contract RandomNumberGenerator {

    uint private nonce = 0;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 private randomnumber;
    uint256 private lotnum = 1; 
    mapping (uint256=>uint256) lotResult;
    event LotStart(uint256 indexed requestId);
    event LotEnd(uint256 indexed requestId, uint256 indexed result);

    function setLotNum(uint256 num) public {
       lotnum = num;
    }

    function lotStart(uint32 num) public returns (uint256 requestId) {

        uint256 id;
        for(uint i = 0; i < num ; i++)
        {
            id = _tokenIds.current();
            requestId = id;
            randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, id))) % lotnum +1;
            _tokenIds.increment();
        }
        lotResult[requestId] = randomnumber;
        emit LotStart(requestId);
        emit LotEnd(requestId,randomnumber);
    }

    function getlotResult(uint256 requestId) public view returns (uint256) {
        return lotResult[requestId];
    }


}

// SPDX-License-Identifier: MIT
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