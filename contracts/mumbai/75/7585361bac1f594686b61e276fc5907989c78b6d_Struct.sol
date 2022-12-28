/**
 *Submitted for verification at polygonscan.com on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

contract Struct {

    uint256 number;

    function setNumber(uint256 _number) external {
        number = _number;
    }

    function getNumber() public view returns (uint256)  {
       return number;
    }
}