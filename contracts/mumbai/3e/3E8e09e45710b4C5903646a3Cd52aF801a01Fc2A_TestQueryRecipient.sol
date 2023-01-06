/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract TestQueryRecipient {
    mapping(uint256 => address) public addresses;
    address crossChainResult;

    event CrossChainMessage(uint32 origin, bytes32 sender, address result);

    constructor() {
        addresses[1] = msg.sender;
        addresses[2] = address(this);
    }

    function getAddress(uint256 id) external view returns(address) {
        return addresses[id];
    }

    function setAddress(uint256 id, address addr) external {
        addresses[id] = addr;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external { // onlyTrustedContract(_origin, _sender)
        (address result) = abi.decode(_message, (address));
        crossChainResult = result;
        emit CrossChainMessage(_origin, _sender, result);
    }
}