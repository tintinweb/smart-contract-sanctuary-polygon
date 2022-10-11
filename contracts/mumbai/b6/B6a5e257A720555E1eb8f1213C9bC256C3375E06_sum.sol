/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract sum
{
    uint256 x;
    uint256 y;
     
    mapping(address=>uint256) alpha; 

    function ry(address _x, uint256 _y) external
    {
        alpha[_x] = _y;
    }

    function get() external view returns(uint256)
    {
        return alpha[msg.sender];
    }

}