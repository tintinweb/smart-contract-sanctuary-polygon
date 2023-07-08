// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWrapper {
    function doCCTrx(
        uint32 _bridgeSelector,
        uint32 _srcChainID,
        uint32 _destChainID,
        bytes calldata _payload,
        uint256 _bridgeFee
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWrapper} from "../interfaces/IWrapper.sol";

contract SourceChainMock {
    IWrapper public immutable wrapper;
    address public immutable destinationChainContract;

    event AcknowledgementReceived(bool ack, bytes returnData);

    constructor(IWrapper _wrapper, address _destinationChainContract) {
        wrapper = _wrapper;
        destinationChainContract = _destinationChainContract;
    }

    function storeOnRemote(uint8 _num) external payable {
        bytes memory payload = abi.encode(
            false, //initial acknowledgment
            abi.encodeWithSignature("store(uint8)", _num), //contract calldata
            destinationChainContract, //contract address on destination chain which is to be called
            address(this) //callback address
        );
        wrapper.doCCTrx{value: msg.value}(0, 80001, 43113, payload, msg.value);
    }

    function callbackHandler(bytes calldata _payload) external {
        (bool ack, , , , bytes memory returnData) = abi.decode(
            _payload,
            (bool, bytes, address, address, bytes)
        );
        emit AcknowledgementReceived(ack, returnData);
    }
}