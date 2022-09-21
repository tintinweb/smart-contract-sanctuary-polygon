/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.7;

/**
 * @title UnifarmStorage
 * @author Himanshu Singh
 * @dev Store & retrieve value for a user in a variable
 */
contract UnifarmStorage {

    uint256 userCount;
    uint256 totalSum;
    mapping(address => uint256) private userSum;
    mapping(address => bool) public userExist;


    /**
     * @dev Stores and sum up the values for a user 
     * @param num value to store
     */

    function store(uint256 num) public {
        if(userExist[msg.sender]){
            userSum[msg.sender] += num;
            totalSum +=num;
        }
        else{
             userSum[msg.sender] = num;
             totalSum+=num;
             userExist[msg.sender]=true;
        }
    }

    /**
     * @notice This method returns Sum of All Values Entered By The User
     * @return uint256 sum of values for the user running this function
     */
    function retrieveUserSum(address user) public view returns (uint256){
        require(user != address(0), "Invalid address ( 0x00 )");
        return userSum[user];
    }

     /**
     * @notice This method returns Sum of All Values Entered By All Users
     * @return uint256 sum of values for all the user running this function
     */
    function retrieveAllUserSum() public view returns (uint256){
        return totalSum;
    }
}