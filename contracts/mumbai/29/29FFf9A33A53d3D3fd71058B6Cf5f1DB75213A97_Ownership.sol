/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Ownership {
    address public owner;
    bytes32 public title;

    constructor (
        string memory _title
    ) {
        owner = msg.sender;
        title = bytes32(bytes(_title));
    }

    function getTitle() external view returns(string memory){
        return string(abi.encodePacked(title));
    }
}