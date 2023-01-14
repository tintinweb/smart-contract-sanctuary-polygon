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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Counters.sol";

contract Names {
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    event NameChanged(address indexed who, string newName);
    event counterIncreased(address indexed who);
    event counterResetted(address indexed who);

    uint private refill;
    string private name;

    constructor(uint _refill, string memory _name) {
        refill = _refill;
        name = _name;
    }

    function changeName(string memory _newName) public payable {
        require(msg.value >= refill, "NOT ENOUGH!"); // 0.01
        name = _newName;
        emit NameChanged(msg.sender, _newName);
    }

    function increaseCounter() public {
        counter.increment();
        emit counterIncreased(msg.sender);
    }

    function resetCounter() public {
        counter.reset();
        emit counterResetted(msg.sender);
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getCounter() public view returns (uint) {
        return counter.current();
    }

    function getRefill() public view returns (uint) {
        return refill;
    }
}