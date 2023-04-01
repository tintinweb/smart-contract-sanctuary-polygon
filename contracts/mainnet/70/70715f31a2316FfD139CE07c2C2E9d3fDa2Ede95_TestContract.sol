//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract TestContract {
    function normalTypes(uint256 quantity, bool ok, address ayylmao, bytes32 b) payable external returns (uint256, bool, address, bytes32) {
        return (quantity, ok, ayylmao, b);
    }

    function arrayTypes(uint256[] calldata quantity, bool[] calldata ok, address[] calldata ayylmao, bytes32[] calldata b) payable external returns (uint256[] calldata, bool[] calldata, address[]calldata, bytes32[] calldata) {
        return (quantity, ok, ayylmao, b);
    }
}