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
pragma solidity ^0.8.7;

import "./library/utilities.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract collection {
    using Counters for Counters.Counter;
    Counters.Counter private _collectionIds;
    address public backend_address;
    mapping(uint256 => utilities.COLLECTION) public collectionIdtoCOLLECTION;
    event SetCollection(bytes, uint256, address);

    event CreateCollection(uint256, address);

    constructor(address _backend_address) {
        backend_address = _backend_address;
    }
    /**
     * @dev Throws if called by any account other than the dev.
     */
    modifier OnlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }
    /**
     * @dev set back end address
     */
    function setBackendAddress(address _backend_address) public OnlyDev {
        backend_address = _backend_address;
    }
    /**
     * @dev create collection on blockchain
     * @param _owner set owner to collection
     */
    function createCollection(address _owner) public OnlyDev {
        _collectionIds.increment();

        collectionIdtoCOLLECTION[_collectionIds.current()] = utilities
            .COLLECTION(_collectionIds.current(), _owner);
        emit CreateCollection(_collectionIds.current(), _owner);
    }
    /**
     * @dev get collection on blockchain
     * @param collectionId use collection id to get collection
     */
    function getCollection(uint256 collectionId)
        public
        view
        returns (utilities.COLLECTION memory)
    {
        return collectionIdtoCOLLECTION[collectionId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library utilities {
    struct COLLECTION {
        uint256 collectionId;
        address collectionOwner;
    }
    struct Order {
        address maker;
        address taker;
        uint256 price;
        uint256 listing_time;
        uint256 expiration_time;
        uint256 NFTId;
        uint256 amount;
        uint256 nonce;
        address payment_token;
    }
      
}