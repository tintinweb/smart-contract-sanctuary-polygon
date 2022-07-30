/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Campaign{
    address payable[] owner;
    address payable contractOwner;
    mapping(address=>uint) public mapped;
    event CampaignEvent(address indexed owner,uint indexed amountLeft,uint indexed timestamp);
    function CreateCampaign(uint amount) public{
        owner.push(payable(msg.sender));
        mapped[msg.sender]=amount;
        emit CampaignEvent(msg.sender,amount,block.timestamp);
    }
    function donate(address payable CO,uint amount) public payable{
        require(mapped[CO]>0,"Required amount fullfilled");
        mapped[CO]-=amount;
        emit CampaignEvent(msg.sender,mapped[CO],block.timestamp);
    }
}