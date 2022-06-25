// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "../interfaces/IFxMessageProcessor.sol";

/***
 * @title MsgRelayer
 * @dev It is assumed to run on the Polygon (or Mumbai) network.
 * It receives message from Mainnet/Goerli, decodes them and
 * emit them.
 */
contract MsgRelayer is IFxMessageProcessor {
    event MsgRelayed(uint256 num1, uint256 num2);

    // solhint-disable var-name-mixedcase

    /// @notice Address of the `FxChild` contract on the Polygon/Mumbai network
    /// @dev `FxChild` is the contract of the "Fx-Portal" on the Polygon/Mumbai
    address public immutable FX_CHILD;

    /// @notice Address of the MsgSender on the mainnet/Goerli
    /// @dev It sends messages over the PoS bridge to this contract
    address public immutable MSG_SENDER;

    // solhint-enable var-name-mixedcase

    /// @param _msgSender Address of the MsgSender on the mainnet/Goerli
    /// @param _fxChild Address of the `FxChild` (Bridge) contract on Polygon/Mumbai
    constructor(address _msgSender, address _fxChild) {
        require(_fxChild != address(0) && _msgSender != address(0), "AMR:E01");

        FX_CHILD = _fxChild;
        MSG_SENDER = _msgSender;
    }

    function processMessageFromRoot(
        uint256, // stateId (Polygon PoS Bridge state sync ID, unused)
        address rootMessageSender,
        bytes calldata content
    ) external override {
        require(msg.sender == FX_CHILD, "AMR:INVALID_CALLER");
        require(rootMessageSender == MSG_SENDER, "AMR:INVALID_SENDER");

        (uint256 num1, uint256 num2) = abi.decode(content, (uint256, uint256));

        emit MsgRelayed(num1, num2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***
 * @dev A receiver on the Polygon (or Mumbai) network of a message sent over the
 * "Fx-Portal" must implement this interface.
 * The "Fx-Portal" is the PoS bridge run by the Polygon team.
 * See https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal
 */
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}