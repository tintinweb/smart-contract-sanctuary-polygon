/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundMe{

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;

    constructor(){
        i_owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == i_owner,"You can't execute this funtion as you are not owner.");
        _;
    }

    function addFund() public payable{
        // require(msg.value >= 1e18 ,"Send value >= 1");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        bool sendSuccess = payable (msg.sender).send(address(this).balance);
        require(sendSuccess,"Send Failed...");
    }
}