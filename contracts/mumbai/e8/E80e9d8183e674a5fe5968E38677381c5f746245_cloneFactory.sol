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
import "@openzeppelin/contracts/utils/Counters.sol";
pragma solidity ^0.8.0;

contract cloneFactory {
    using Counters for Counters.Counter;
    Counters.Counter private _collectionIds;
    event CreateCloneCollection(uint256 collectionIds, address clone);
    function createClone(address logicContractAddress)
        public
        returns (address result)
    {
        bytes20 addressBytes = bytes20(logicContractAddress);
        assembly {
            let clone := mload(0x40) // Jump to the end of the currently allocated memory- 0x40 is the free memory pointer. It allows us to add own code

            /*
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
                   
        */
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            ) // store 32 bytes (0x3d602...) to memory starting at the position clone

            /*
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe
            |        20 bytes                       |    20 bytes address                   |
        */
            mstore(add(clone, 0x14), addressBytes) // add the address at the location clone + 20 bytes. 0x14 is hexadecimal and is 20 in decimal

            /*
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
             |        20 bytes                       |    20 bytes address                   |  15 bytes                     |
        */
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            ) // add the rest of the code at position 40 bytes (0x28 = 40)

            /* 
            create a new contract
            send 0 Ether
            the code starts at the position clone
            the code is 55 bytes long (0x37 = 55)
        */
            result := create(0, clone, 0x37)
        }
    }
    function createCloneCollection(address collectionContractAddress)
        public
        returns (address result)
    {
        _collectionIds.increment();
        address cloneCollection = createClone(collectionContractAddress);
        emit CreateCloneCollection(_collectionIds.current(), cloneCollection);
        return cloneCollection;
    }
}