// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IWildeventReceiver} from "../interfaces/IWildeventReceiver.sol";

contract PlaytestSchemaVerifier is IWildeventReceiver {
    event PlaytestCompleted(
        uint256 started, uint16 durationMinutes, uint16[] wildfileMinutesWatched, uint32[] wildfileIds
    );

    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external {
        (uint256 started, uint16 durationMinutes, uint16[] memory wildfileMinutesWatched) =
            abi.decode(data, (uint256, uint16, uint16[]));
        emit PlaytestCompleted(started, durationMinutes, wildfileMinutesWatched, wildfileIds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWildeventReceiver {
    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external;
}