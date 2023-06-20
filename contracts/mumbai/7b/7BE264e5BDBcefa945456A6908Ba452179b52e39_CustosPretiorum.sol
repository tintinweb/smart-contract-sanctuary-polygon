// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

/// @notice FxChild contract to be deployed on Polygon.
contract CustosPretiorum {
    // --- Global Variables ---

    address public messageSender;

    // --- Events ---

    event MessageReceived(
        bytes data
    );

    // --- Errors ---

    error SenderNotAuthorized();

    // --- Logic ---

    constructor(address _messageSender) {
        messageSender = _messageSender;
    }

    function processMessageFromRoot(uint256, address rootMessageSender, bytes calldata data) external {
        if (rootMessageSender != messageSender) {
            revert SenderNotAuthorized();
        }
        
        emit MessageReceived(data);
    }
}