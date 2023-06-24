// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract WhiteList {
    
    mapping (address=>bool) public whitelist;
    uint256 public capacity;
    constructor(uint256 _capacity) {
        capacity=_capacity;
    }
   
    uint256 public count=0;
    function addToWhiteList() public {
        require(count<capacity,'Whitelist Full');
        require(whitelist[msg.sender]==false,'already added');


        whitelist[msg.sender]=true;
        count++;


    }

}