/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Simple {
    mapping(address => uint256) record;

    function fundContract() public payable {
        record[msg.sender] += msg.value;
    }

    function getRecord(address _add) public view returns (uint256) {
        return record[_add];
    }

    function withdraw() public {
        uint256 amount = record[msg.sender];
        record[msg.sender] = 0;

        (bool callSuccess, ) = payable(msg.sender).call{value: amount}("");
        require(callSuccess, "Call failed");
    }

    function send() public {
        record[msg.sender] -= 1;

        (bool callSuccess, ) = payable(msg.sender).call{value: 1 ether}("");
        require(callSuccess, "Call failed");
    }
}