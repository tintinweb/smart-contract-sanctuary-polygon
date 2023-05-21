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
    event LogTransferOwnershipBStart(address indexed caller);
    event LogTransferOwnershipBEnd(bool success);
    event LogDelegateCallAStart(address indexed caller);
    event LogDelegateCallAEnd(bool success);
    event LogTransferOwnershipBackBStart(address indexed caller);
    event LogTransferOwnershipBackBEnd(bool success);

    constructor(address _smartContractB, address _smartContractA) {
        smartContractB = _smartContractB;
        smartContractA = _smartContractA;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only owner can call this function");
        
        // Prepare the call to `transferOwnership(address)` on `smartContractB`
        bytes memory data = abi.encodeWithSignature("transferOwnership(address)", address(this));
        
        // Emit the event before transferring ownership
        emit LogTransferOwnershipBStart(msg.sender);
        // Transfer the ownership of `smartContractB` to `SmartContractC`
        (bool success,) = smartContractB.call(data);
        // Emit the event after transferring ownership
        emit LogTransferOwnershipBEnd(success);
        require(success, "Failed to transfer ownership of SmartContractB");

        // Make a delegatecall to `smartContractA` to transfer its ownership
        // Emit the event before the delegate call
        emit LogDelegateCallAStart(msg.sender);
        (success,) = smartContractA.delegatecall(data);
        // Emit the event after the delegate call
        emit LogDelegateCallAEnd(success);
        require(success, "Delegatecall has failed");

        // Prepare the call to `transferOwnership(address)` on `smartContractB`
        data = abi.encodeWithSignature("transferOwnership(address)", owner);

        // Transfer the ownership of `smartContractB` back to the original owner
        // Emit the event before transferring ownership back
        emit LogTransferOwnershipBackBStart(msg.sender);
        (success,) = smartContractB.call(data);
        // Emit the event after transferring ownership back
        emit LogTransferOwnershipBackBEnd(success);
        require(success, "Failed to transfer ownership of SmartContractB back to the original owner");
    }
}