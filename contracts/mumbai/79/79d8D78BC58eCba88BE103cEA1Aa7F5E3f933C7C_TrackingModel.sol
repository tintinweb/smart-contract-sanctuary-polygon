// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TrackingModel {
    address public owner;
    string[] public trackingChain;

    constructor()  {
        owner = msg.sender;
    }

    struct tracking {
        address trackingCreator;
        string contractContentId;
        string productId;
    }

    mapping(string => tracking) private TrackingModelList;

    function addTrackingBlock(string memory _productId, string memory _contractContentId, address _creatorAddress) public {
        tracking storage newTracking = TrackingModelList[_productId];
        newTracking.contractContentId = _contractContentId;
        newTracking.trackingCreator = _creatorAddress;
    }

    function getTrackingBlock(string memory _productId) public view returns (tracking memory)  {
        return TrackingModelList[_productId];
    }
}