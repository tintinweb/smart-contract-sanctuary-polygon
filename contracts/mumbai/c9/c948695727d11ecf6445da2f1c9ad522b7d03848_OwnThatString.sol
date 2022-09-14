/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract OwnThatString {
    address ownerAdd;
    address creator;
    string currentString;
    uint currMax = 0;
    constructor () {
        creator = msg.sender;
        currentString = "initial";
    }
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
    function setMessage(string memory data) public payable{
        require((strlen(data) < 61), "Max 60 Characters Allowed!");
        require(msg.value > currMax,"Send More Than MaxBid Wei");
        ownerAdd = msg.sender;
        currMax = msg.value;
        currentString = data;
    }
    function getCurrentMessage() public view returns (string memory) {
        return currentString;
    }
    function getCurrentMaxBid()public view returns(uint){
        return currMax;
    }
    function getCurrentBidOwner() public view returns(address){
        return ownerAdd;
    }
}