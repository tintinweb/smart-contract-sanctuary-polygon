// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Event {
    uint256 start;
    uint256 end;
    address creator;
    bytes eventId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Structs.sol";
import "./utils/HashUtils.sol";

contract Test {
    using HashUtils for Event;

    function hash(
        uint256 start,
        uint256 end,
        address creator,
        bytes calldata eventId
    ) public pure returns (bytes32 digest) {
        Event memory event_ = Event({
            start: start,
            end: end,
            creator: creator,
            eventId: eventId
        });

        return event_.hash();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/Structs.sol";

library HashUtils {
    function hash(Event memory event_) internal pure returns (bytes32 digest) {
        return
            keccak256(
                abi.encodePacked(
                    event_.start,
                    event_.end,
                    event_.creator,
                    event_.eventId
                )
            );
    }
}