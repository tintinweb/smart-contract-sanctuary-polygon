/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartContractC {
    address public owner;
    address public smartContractB;
    address public smartContractA;

    // Define events for debugging
    event LogDelegateCallAStart(address indexed caller);
    event LogDelegateCallAEnd(bool success, bytes returnData);

    constructor(address _smartContractB, address _smartContractA) {
        smartContractB = _smartContractB;
        smartContractA = _smartContractA;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only owner can call this function");

        // Prepare the call to `transferOwnership(address)` on `smartContractA`
        bytes memory data = abi.encodeWithSignature("transferOwnership(address)", newOwner);

        // Make a delegatecall to `smartContractA` to transfer its ownership
        // Emit the event before the delegate call
        emit LogDelegateCallAStart(msg.sender);
        (bool success, bytes memory returnData) = smartContractA.delegatecall(data);
        // Emit the event after the delegate call
        emit LogDelegateCallAEnd(success, returnData);
        require(success, string(returnData)); // revert with the returned error message on failure
    }
}