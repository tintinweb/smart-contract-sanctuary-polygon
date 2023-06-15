/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract fundApp {
    uint256 public voteCount = 0;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier requireOwner(){
        require(msg.sender == owner, "Not permitted to call a method");
        _;
    }   

    function doTransaction() requireOwner public {
        voteCount +=1 ;
    }

    function showCount() public view returns(uint256) {
        return voteCount ;
    }


}