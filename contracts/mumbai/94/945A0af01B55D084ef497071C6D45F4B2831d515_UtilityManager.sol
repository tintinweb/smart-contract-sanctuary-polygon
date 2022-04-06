/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract UtilityManager{

    struct Schema {
        uint256 stakedAmount;
        uint256 claimedAmount;
        uint256 unclaimedAmount;
        uint256 totalValueLocked;
        uint256 annualPercentageRate;
        uint256 weight;
        uint256 pendingRewards;
    }

    struct CombinedSchema {
        uint256 stakedAmount;
        uint256 claimedAmount;
        uint256 unclaimedAmount;
        uint256 totalValueLocked;
        uint256 pendingRewards;
    }

    mapping(uint256 => Schema) public details;

    /*  NOTE : 
        Using _id=0 for Fossil token and _id=1 for LP token
        Using _operation=1 for add and _operation=0 for subtract
    */

    // Returns entire details of particular token
    function getSpecificTokenDetails(uint256 _id) external view returns(Schema memory){
        return details[_id];
    } 

    // Returns entire details of combined token
    function getCombinedTokenDetails() external view returns(CombinedSchema memory){
        CombinedSchema memory combinedSchema;
        combinedSchema.stakedAmount = details[0].stakedAmount + details[1].stakedAmount;
        combinedSchema.claimedAmount = details[0].claimedAmount;
        combinedSchema.unclaimedAmount = details[0].unclaimedAmount;
        combinedSchema.totalValueLocked = details[0].totalValueLocked + details[1].totalValueLocked;
        combinedSchema.pendingRewards = details[0].pendingRewards;
        return combinedSchema;
    } 

    // updates staked amount
    function updateStakedAmount(uint256 _id, uint256 _amount) external {
        details[_id].stakedAmount += _amount;
    }

    // updates claimed amount
    function updateClaimedAmount(uint256 _amount) external {
        details[0].claimedAmount += _amount;
        details[1].claimedAmount += _amount;
    }

    // updates unclaimed amount
    function updateUnclaimedAmount(uint256 _amount, uint256 _operation) external {
        // 1 means add and 0 means remove
        if(_operation == 1){
            details[0].unclaimedAmount += _amount;
            details[1].unclaimedAmount += _amount;
        }
        else{
            details[0].unclaimedAmount -= _amount;
            details[1].unclaimedAmount -= _amount;
        }
    }

    // updates total value locked for specific token
    function updateTotalValueLockedAmount(uint256 _id, uint256 _amount, uint256 _operation) external {
        // 1 means add and 0 means remove
        if(_operation == 1)
            details[_id].totalValueLocked += _amount;
        else
            details[_id].totalValueLocked -= _amount;
    }

    // updates APR
    function updateAPR(uint256 _id, uint256 _amount) external {
        details[_id].annualPercentageRate += _amount;
    }

    // updates weight
    function updateWeight(uint256 _id, uint256 _weight) external {
        details[_id].weight = _weight;
    }

    // updates pendingRewards
    function updatePendingRewards(uint256 _amount, uint256 _operation) external {
        if(_operation == 1){
            details[0].pendingRewards += _amount;
            details[1].pendingRewards += _amount;
        }
        else{
            details[0].pendingRewards -= _amount;
            details[1].pendingRewards -= _amount;
        }
    }

}