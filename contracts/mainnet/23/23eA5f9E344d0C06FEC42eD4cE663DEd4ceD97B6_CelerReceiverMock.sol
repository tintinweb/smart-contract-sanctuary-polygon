// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

contract CelerReceiverMock {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    event Receive (
        address sender,
        uint64 chainId,
        bytes message
    );

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address
    ) external payable returns (ExecutionStatus) {
        emit Receive(_sender, _srcChainId, _message);
        return ExecutionStatus.Success;
    }
}