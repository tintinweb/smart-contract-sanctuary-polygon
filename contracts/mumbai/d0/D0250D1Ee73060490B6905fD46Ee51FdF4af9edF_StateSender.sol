// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStateSender.sol";

contract StateSender is IStateSender {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;

    event StateSynced(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    /**
     *
     * @notice Generates sync state event based on receiver and data.
     * Anyone can call this method to emit an event. Receiver on Polygon should add check based on sender.
     *
     * @param receiver Receiver address on Polygon chain
     * @param data Data to send on Polygon chain
     *
     */
    function syncState(address receiver, bytes calldata data) external {
        // check receiver
        require(receiver != address(0), "INVALID_RECEIVER");
        // check data length
        require(data.length <= MAX_LENGTH, "EXCEEDS_MAX_LENGTH");

        // State sync id will start with 1
        emit StateSynced(++counter, msg.sender, receiver, data);
    }
}