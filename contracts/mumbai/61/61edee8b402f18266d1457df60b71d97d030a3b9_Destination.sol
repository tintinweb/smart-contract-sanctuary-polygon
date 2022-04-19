// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";

/// @dev to be deployed in POLYGON MUMBAI (Destination Chain)

contract Destination is ILayerZeroReceiver {
    ILayerZeroEndpoint public immutable endpoint;

    string public latestMessage;

    constructor(address _endpoint) {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external override {
        latestMessage = abi.decode(_payload, (string));
        endpoint.send(
            10001,
            _srcAddress,
            abi.encode(_nonce),
            payable(address(this)),
            address(0x0),
            bytes("")
        );
    }
}