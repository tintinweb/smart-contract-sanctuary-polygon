/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract fundApp {
    uint256 public voteCount = 0;
    mapping (address => uint256) public addressToAmountFunded;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // function fund() public payable {
    //     require(msg.value>100, "Empty value to send");
    //     addressToAmountFunded[msg.sender] += msg.value;
    // }

    modifier requireOwner(){
        require(msg.sender == owner);
        _;
    }   

    // function withdraw() payable requireOwner public {
    //     payable(msg.sender).transfer(address(this).balance);
    // }

    function doTransaction() requireOwner public {
        voteCount +=1 ;
    }

    function showCount() public view returns(uint256) {
        return voteCount ;
    }


}