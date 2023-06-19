// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./constants.sol";

struct File {
    uint fileNumber;
    address customer;
}

struct Covenant {
    File file;
    uint expiration;
}

contract Agent {
    using Counters for Counters.Counter;

    Counters.Counter private version;
    Covenant public covenant;

    function isCovenantLegallyEnded() public view returns (bool) {
        return covenant.expiration >= block.timestamp;
    }

    function isCovenantAdministrativelyEnded() public view returns (bool) {
        return covenant.expiration == 0;
    }

    function isCustomerInvoking() public view returns (bool) {
        return msg.sender == covenant.file.customer;
    }

    function versionNumber() public view returns (uint256) {
        return version.current();
    }

    function _begin(Covenant calldata _covenant) internal {
        // In caller functions check for isCovenantAdministrativelyEnded()
        // double-invocation breaks store logic
        version.increment();
        covenant = _covenant;
    }

    function begin(Covenant calldata _covenant) public {
        require(isCovenantAdministrativelyEnded(), "Contract not ended yet");
        _begin(_covenant);
    }

    function safeBegin(Covenant calldata _covenant) public {
        require(_covenant.expiration > block.timestamp, "Contract expiration is set to a past date");
        if (!isCovenantAdministrativelyEnded()) {
            endExpired();
        }

        _begin(_covenant);
    }

    function _end() internal {
        // double-invocation breaks store logic
        require(!isCovenantAdministrativelyEnded(), "Contract is already ended");
        covenant.expiration = 0;
    }

    function end() public {
        if (isCovenantLegallyEnded()) {
            endExpired();
        } else {
            endMy();
        }
    }

    function endExpired() public {
        require(!isCovenantLegallyEnded(), "Contract not expired yet");
        _end();
    }

    function endMy() public {
        require(isCustomerInvoking(), "Only current tenant can end the contract this way");
        _end();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

uint256 constant COUNT = 1000;

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