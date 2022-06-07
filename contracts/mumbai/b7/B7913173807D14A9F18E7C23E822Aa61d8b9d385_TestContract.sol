// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    event TestEvent(bytes32[3] fixedArray);

    bytes32[3] public array;

    function emitEvent() external {
        array[0] = keccak256(bytes("1"));
        array[1] = keccak256(bytes("2"));
        array[2] = keccak256(bytes("3"));

        emit TestEvent(array);
    }
}