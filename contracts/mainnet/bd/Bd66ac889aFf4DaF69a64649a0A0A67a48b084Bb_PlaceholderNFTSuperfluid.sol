// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IConstantOutflowNFT} from "../../interfaces/superfluid/IConstantOutflowNFT.sol";

contract PlaceholderNFTSuperfluid is IConstantOutflowNFT {
    function onCreate(address, address) external override {}

    function onUpdate(address, address) external override {}

    function onDelete(address, address) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Placeholder for superfluid's new implementation for NFTs.
interface IConstantOutflowNFT {
    /**************************************************************************
     * Write Functions
     *************************************************************************/

    /// @notice The onCreate function is called when a new flow is created.
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onCreate(address flowSender, address flowReceiver) external;

    /// @notice The onUpdate function is called when a flow is updated.
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onUpdate(address flowSender, address flowReceiver) external;

    /// @notice The onDelete function is called when a flow is deleted.
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onDelete(address flowSender, address flowReceiver) external;
}