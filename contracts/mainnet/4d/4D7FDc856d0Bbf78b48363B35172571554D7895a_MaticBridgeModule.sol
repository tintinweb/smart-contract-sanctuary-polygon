// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/***
 * @dev A receiver on the Polygon (or Mumbai) network of a message sent over the
 * "Fx-Portal" (a PoS bridge run by the Polygon team) must implement this interface
 * See https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal
 */
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

contract MaticBridgeModule is IFxMessageProcessor {
    address public immutable fxChild;

    address public factory = 0x0000000000FFe8B47B3e2130213B802212439497;

    bytes public callResult;

    bool public executed;

    /// @param _fxChild Address of the `FxChild` (Bridge) contract on Polygon/Mumbai
    constructor(address _fxChild) {
        require(_fxChild != address(0), "FX_CHILD_ZERO_ADDRESS");
        fxChild = _fxChild;
    }

    function processMessageFromRoot(
        uint256, // stateId (Polygon PoS Bridge state sync ID, unused)
        address, //rootMessageSender
        bytes calldata data
    ) external override {
        executed = true;
        (bool success, bytes memory result) = factory.call(data);

        callResult = result;

        require(success, "Deployment failed");
    }
}