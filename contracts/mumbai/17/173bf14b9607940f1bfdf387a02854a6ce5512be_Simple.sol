// SPDX-License-Identifier: UNLICENSED
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
        record[msg.sender] += 0;

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function send() public {
        // record[msg.sender] += 0;

        (bool callSuccess, ) = payable(msg.sender).call{value: 1 ether}("");
        require(callSuccess, "Call failed");
    }
}