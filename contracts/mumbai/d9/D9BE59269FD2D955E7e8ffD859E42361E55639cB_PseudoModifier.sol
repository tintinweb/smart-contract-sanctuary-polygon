// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title PseudoModifier
 * @author Lucien Akchoté
 *
 * @notice Implements the (currently) unsupported functionality of using modifiers in libraries
 * @dev see https://github.com/ethereum/solidity/issues/12807
 */
library PseudoModifier {
    using Counters for Counters.Counter;

    /**
     * @notice Check address `expected` is equal to address `actual`
     *
     * @param expected The expected address
     * @param actual The actual address
     */
    function addressEq(address expected, address actual) external pure {
        if (expected != actual) revert Errors.Unauthorized();
    }

    /**
     * @dev Check if the index requested exist in counter
     *
     * @param index The id to verify existence for
     * @param counter The counter that holds enumeration
     */
    function isNotOutOfBounds(uint256 index, Counters.Counter storage counter) external view {
        if (index > counter.current() || index == 0) revert Errors.OutOfBounds();
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Errors
 * @author Lucien Akchoté
 *
 * @notice Regroup all the different errors used throughout AmpliFrens
 * @dev Use custom errors to save gas
 */
library Errors {
    /// @dev Generic errors
    error Unauthorized();
    error OutOfBounds();
    error NotImplemented();
    error AddressNull();

    /// @dev Profile errors
    error NoProfileWithAddress();
    error NoProfileWithSocialHandle();
    error EmptyUsername();
    error UsernameExist();
    error NotBlacklisted();

    /// @dev Contribution errors
    error AlreadyVoted();
    error NotAuthorOrAdmin();
    error NotAuthor();

    /// @dev NFT errors
    error MaxSupplyReached();
    error AlreadyOwnNft();

    /// @dev SBT errors
    error MintingIntervalNotMet();
}