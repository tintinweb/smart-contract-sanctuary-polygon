/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

/**
 *Submitted for verification at polygonscan.com on 2023-03-28
 */

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

contract CrowdFundingStorage {
    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool)) public isPartcipate;

    modifier judgeParticipate(uint campaignId) {
        require(isPartcipate[campaignId][msg.sender] == false);
        _;
    }
}

contract CrowdFunding is CrowdFundingStorage {
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function newCampaign(
        address payable receiver,
        uint goal
    ) external isOwner returns (uint campaignId) {
        campaignId = numCampaigns++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(
        uint campaignId
    ) external payable judgeParticipate(campaignId) {
        Campaign storage c = campaigns[campaignId];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignId].push(Funder({addr: msg.sender, amount: msg.value}));

        isPartcipate[campaignId][msg.sender] = true;
    }

    function getTotalAmount(
        uint campaignId
    ) external view returns (uint amount) {
        Campaign storage c = campaigns[campaignId];
        amount = c.totalAmount;
    }

    function withdraw(uint campaignId) external returns (bool reached) {
        Campaign storage c = campaigns[campaignId];

        if (c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}