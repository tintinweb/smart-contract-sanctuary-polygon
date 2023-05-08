/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserPoints {
    struct ActivityData {
        uint256[] activityIds; //
        uint256[] points;
        uint256[] cids;   //
        uint256[] timestamps;
        bytes32[] transactionHashes;
    }
    mapping(address => ActivityData) userActivityData;

    function addActivityData(uint256 _activityId, uint256 _points, uint256 _cid) public {
        ActivityData storage activityData = userActivityData[msg.sender];
        activityData.activityIds.push(_activityId);
        activityData.points.push(_points);
        activityData.cids.push(_cid);
        activityData.timestamps.push(block.timestamp);
        activityData.transactionHashes.push(blockhash(block.number -1));
    }
    
    function getUserActivityData() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bytes32[] memory) {
        ActivityData storage activityData = userActivityData[msg.sender];
        return (activityData.activityIds, activityData.points, activityData.cids, activityData.timestamps, activityData.transactionHashes);
    }
}