// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./ISatellite.sol";

contract Satellite is ISatellite {
    uint16 internal immutable masterChainId;
    address internal immutable masterChainAddress;
    uint256 internal immutable thisChainId;

    ILayerZeroEndpoint internal immutable endpoint;

    uint256 internal counter;

    constructor(uint16 _masterChainId, address _masterChainAddress, uint16 _thisChainId, address _endpoint) {
        masterChainId = _masterChainId;
        masterChainAddress = _masterChainAddress;
        thisChainId = _thisChainId;
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function modifyCounter(
        uint8 action, // see libraries/helpers.sol/ModifyAction
        uint256 num
    ) external payable override {
        // TODO: What does params do?
        bytes memory params;
        // TODO: Calculate how much msg.value needs to be on any chain to cover reflection on master chain
        endpoint.send{value:msg.value}(
            masterChainId,
            abi.encodePacked(masterChainAddress),
            abi.encode(uint16(0), action, num),
            payable(msg.sender),
            address(0),
            params
        );
    }
}