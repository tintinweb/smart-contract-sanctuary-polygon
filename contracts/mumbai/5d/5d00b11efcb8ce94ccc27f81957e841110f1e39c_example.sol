/**
 *Submitted for verification at polygonscan.com on 2022-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract example{
    uint data;
    function updateData(uint _data) external {
        data = _data;
    }
    function readData() external view returns(uint){
        return data;
    }
}