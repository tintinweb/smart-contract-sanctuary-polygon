// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

/// @notice FxChild contract to be deployed on Polygon.
contract FxChild {
    event MessageReceived(
        uint256 stateId,
        address rootMessageSender,
        bytes data
    );

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external {
        emit MessageReceived(stateId, rootMessageSender, data);
    }
}