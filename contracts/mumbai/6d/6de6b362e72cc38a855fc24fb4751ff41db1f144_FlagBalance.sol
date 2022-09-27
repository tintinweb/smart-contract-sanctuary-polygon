/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract FlagBalance {

    mapping(address => uint256) numbers;

    function SetFlagBalance(uint _num) public {
    numbers[msg.sender] = _num;
  }

    function getFlagBalance(address _myaddress) public view returns (uint) {
        return numbers[_myaddress];
    }
}