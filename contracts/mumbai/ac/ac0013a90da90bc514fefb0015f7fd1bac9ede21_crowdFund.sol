/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract crowdFund{
    uint id = 0;
    struct donation{
        uint fund_id;
        uint amount;
        uint amount_got;
        address aggregator;
        string title;
        string url;
        string details;
        string category;
        address[] givers;
        uint[] amount_given;
        uint256[] timestamp;
    }
    donation[] public donations;

    function setDonations(string memory _title, string memory _url, string memory _details, address _address, uint _amount, string memory _category) public {
        donation memory Donation;
        Donation.fund_id = id;
        Donation.amount = _amount;
        Donation.amount_got = 0;
        Donation.aggregator = _address;
        Donation.title = _title;
        Donation.url = _url;
        Donation.category = _category;
        Donation.details = _details;
        donations.push(Donation);
        id+=1;
    }

    function getDonations(uint _index) public view returns (string memory title, string memory url, string memory details, uint amount,uint amount_got) {
        donation storage Donation = donations[_index];
        return (Donation.title, Donation.url, Donation.details , Donation.amount, Donation.amount_got);
    }

    function sendBal(uint _index) public payable {
        donation storage Donation = donations[_index];
        payable(Donation.aggregator).transfer(msg.value);
        Donation.amount_got+=msg.value;
        Donation.givers.push(msg.sender);
        Donation.amount_given.push(msg.value);
        Donation.timestamp.push(block.timestamp);
    }

    function getTransactions(uint _index) public view returns(address[] memory givers, uint[] memory amount_given, uint256[] memory timestamp){
        donation storage Donation = donations[_index];
        return (Donation.givers, Donation.amount_given, Donation.timestamp);
    }

    function getAllDonations() public view returns(donation[] memory){
        return donations;
    }
}